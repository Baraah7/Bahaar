// DS-1 Vision Engine — OpenCV Mobile implementation
// Build requirements: OpenCV 4.x (UMat / OpenCL path), Android NDK r25+
//
// All public symbols are declared in vision_engine.h.
// Internal state lives in the anonymous namespace — no globals leak.

#include "vision_engine.h"

#include <cmath>
#include <cstring>
#include <algorithm>
#include <numeric>
#include <vector>
#include <android/log.h>

#include <opencv2/core.hpp>
#include <opencv2/core/ocl.hpp>
#include <opencv2/imgproc.hpp>

#define DS1_TAG  "DS1_Vision"
#define LOGI(...)  __android_log_print(ANDROID_LOG_INFO,  DS1_TAG, __VA_ARGS__)
#define LOGW(...)  __android_log_print(ANDROID_LOG_WARN,  DS1_TAG, __VA_ARGS__)
#define LOGE(...)  __android_log_print(ANDROID_LOG_ERROR, DS1_TAG, __VA_ARGS__)

// ── Internal state ────────────────────────────────────────────────────────────
namespace {

struct EngineState {
    bool   initialised   = false;
    int    frameW        = 0;
    int    frameH        = 0;
    double focalLenMm    = 0.0;
    double sensorWidthMm = 0.0;

    // Field-of-view in radians (computed once at init)
    double fovH          = 0.0;  // horizontal
    double fovV          = 0.0;  // vertical

    // Pre-allocated CPU buffers (avoid per-frame heap alloc)
    cv::Mat grayBuf;
    cv::Mat blurBuf;
    cv::Mat threshBuf;
    cv::Mat edgeBuf;

    // Last confidence from detect_stars()
    double lastConfidence = 0.0;
};

EngineState g_state;

// ── Helpers ───────────────────────────────────────────────────────────────────

inline bool engine_ready() { return g_state.initialised; }

/// Brightness-weighted centroid (sub-pixel) for a connected component.
/// Returns (cx, cy) in pixel coordinates.
cv::Point2d centroid(const cv::Mat& gray, const std::vector<cv::Point>& pts) {
    double sumX = 0, sumY = 0, sumW = 0;
    for (const auto& p : pts) {
        double w = static_cast<double>(gray.at<uint8_t>(p.y, p.x));
        sumX += p.x * w;
        sumY += p.y * w;
        sumW += w;
    }
    if (sumW < 1.0) {
        // Degenerate — use geometric centre
        cv::Moments m = cv::moments(pts);
        return {m.m10 / m.m00, m.m01 / m.m00};
    }
    return {sumX / sumW, sumY / sumW};
}

/// Compute per-star brightness (mean pixel value inside bounding rect).
double starBrightness(const cv::Mat& gray, const std::vector<cv::Point>& pts) {
    double s = 0;
    for (const auto& p : pts)
        s += gray.at<uint8_t>(p.y, p.x);
    return s / static_cast<double>(pts.size());
}

}  // namespace

// ── Public API ─────────────────────────────────────────────────────────────────

extern "C" {

int init_vision_engine(int    image_width,
                       int    image_height,
                       double focal_length_mm,
                       double sensor_width_mm) {
    if (image_width <= 0 || image_height <= 0 ||
        focal_length_mm <= 0 || sensor_width_mm <= 0) {
        LOGE("init: invalid arguments");
        return -4;
    }

    // ── GPU check ─────────────────────────────────────────────────────────────
    // We call this but do NOT block on it — UMat silently falls back to CPU
    // when OpenCL is unavailable. We log a warning instead of hard-failing,
    // because many mid-range Android devices have OpenCL but report it only
    // after the first UMat operation.
    if (!cv::ocl::haveOpenCL()) {
        LOGW("init: OpenCL not detected — UMat will use CPU fallback. "
             "Performance may exceed 500 ms target on slow devices.");
        // Per blueprint: return -2 if GPU not available.
        return -2;
    }
    cv::ocl::setUseOpenCL(true);

    // Limit threads to avoid starving the UI thread
    cv::setNumThreads(2);

    g_state.frameW        = image_width;
    g_state.frameH        = image_height;
    g_state.focalLenMm    = focal_length_mm;
    g_state.sensorWidthMm = sensor_width_mm;

    // Sensor height ≈ sensor_width * (height / width) for square pixels
    double sensorHeightMm = sensor_width_mm
                            * (static_cast<double>(image_height) / image_width);
    g_state.fovH = 2.0 * std::atan(sensor_width_mm  / (2.0 * focal_length_mm));
    g_state.fovV = 2.0 * std::atan(sensorHeightMm   / (2.0 * focal_length_mm));

    // Pre-allocate CPU working buffers (zero-copy view for UMat uploads)
    g_state.grayBuf   = cv::Mat(image_height, image_width, CV_8UC1);
    g_state.blurBuf   = cv::Mat(image_height, image_width, CV_8UC1);
    g_state.threshBuf = cv::Mat(image_height, image_width, CV_8UC1);
    g_state.edgeBuf   = cv::Mat(image_height, image_width, CV_8UC1);

    g_state.lastConfidence = 0.0;
    g_state.initialised    = true;

    LOGI("init: %dx%d  FOV %.1f°×%.1f°  focal=%.1fmm  sensor=%.1fmm",
         image_width, image_height,
         g_state.fovH * 180.0 / M_PI,
         g_state.fovV * 180.0 / M_PI,
         focal_length_mm, sensor_width_mm);
    return 0;
}

// ─────────────────────────────────────────────────────────────────────────────
int detect_stars(const uint8_t* pixels,
                 int            width,
                 int            height,
                 double*        out_star_x,
                 double*        out_star_y) {
    if (!engine_ready()) return -3;
    if (!pixels || !out_star_x || !out_star_y) return -4;
    if (width != g_state.frameW || height != g_state.frameH) {
        LOGW("detect_stars: frame size %dx%d != init size %dx%d",
             width, height, g_state.frameW, g_state.frameH);
        return -4;
    }

    // ── Step 1: RGB → Grayscale (wraps caller's buffer — zero copy) ──────────
    cv::Mat rgb(height, width, CV_8UC3, const_cast<uint8_t*>(pixels));
    cv::cvtColor(rgb, g_state.grayBuf, cv::COLOR_RGB2GRAY);

    // Upload to GPU for subsequent ops
    cv::UMat uGray;
    g_state.grayBuf.copyTo(uGray);

    // ── Step 2: 5×5 Gaussian blur — reduces hot-pixel noise ─────────────────
    cv::UMat uBlur;
    cv::GaussianBlur(uGray, uBlur, cv::Size(5, 5), 0);

    // ── Step 3: Adaptive threshold — handles uneven sky brightness ───────────
    // Block size 11 × block size with C=2 handles gradient skies well.
    cv::UMat uThresh;
    {
        cv::Mat blurCpu;
        uBlur.copyTo(blurCpu);
        cv::adaptiveThreshold(blurCpu, g_state.threshBuf,
                              255,
                              cv::ADAPTIVE_THRESH_MEAN_C,
                              cv::THRESH_BINARY,
                              /*blockSize=*/11,
                              /*C=*/-2);   // negative C keeps bright spots
    }

    // ── Step 4: Find contours ────────────────────────────────────────────────
    // 8° forbidden zone at bottom of frame (horizon + refraction margin)
    // Convert 8° to pixels: tanFrac of total height
    int forbiddenRows = static_cast<int>(
        std::tan(8.0 * M_PI / 180.0) / std::tan(g_state.fovV / 2.0)
        * (height / 2.0));
    forbiddenRows = std::max(forbiddenRows, height / 10); // ≥ 10% of height

    // Mask out the forbidden zone
    cv::Mat masked = g_state.threshBuf.clone();
    masked(cv::Rect(0, height - forbiddenRows, width, forbiddenRows))
          .setTo(cv::Scalar(0));

    std::vector<std::vector<cv::Point>> contours;
    cv::findContours(masked, contours,
                     cv::RETR_EXTERNAL,
                     cv::CHAIN_APPROX_SIMPLE);

    // ── Step 5: Filter by area and collect brightness-weighted centroids ──────
    struct Candidate {
        cv::Point2d centre;
        double      brightness;
    };
    std::vector<Candidate> candidates;
    candidates.reserve(contours.size());

    for (const auto& contour : contours) {
        double area = cv::contourArea(contour);
        if (area < 3.0 || area > 50.0) continue;  // noise / aircraft rejection

        cv::Point2d c = centroid(g_state.grayBuf, contour);
        double      b = starBrightness(g_state.grayBuf, contour);
        candidates.push_back({c, b});
    }

    if (candidates.empty()) {
        g_state.lastConfidence = 0.0;
        return 0;  // valid frame, just no stars
    }

    // ── Step 6: Sort by brightness desc, return top DS1_MAX_STARS ────────────
    std::sort(candidates.begin(), candidates.end(),
              [](const Candidate& a, const Candidate& b) {
                  return a.brightness > b.brightness;
              });

    int count = static_cast<int>(
        std::min(candidates.size(), static_cast<size_t>(DS1_MAX_STARS)));

    for (int i = 0; i < count; ++i) {
        out_star_x[i] = candidates[i].centre.x;
        out_star_y[i] = candidates[i].centre.y;
    }

    // ── Confidence: detected vs. expected stars in a typical clear sky ────────
    // Expected ≈ 20 for a 20°×15° FOV patch at mag < 5.0
    constexpr double kExpectedStars = 20.0;
    g_state.lastConfidence =
        std::min(100.0, static_cast<double>(count) / kExpectedStars * 100.0);

    LOGI("detect_stars: found %d stars, confidence %.0f%%",
         count, g_state.lastConfidence);
    return count;
}

// ─────────────────────────────────────────────────────────────────────────────
int detect_horizon(const uint8_t* pixels,
                   int            width,
                   int            height,
                   double*        out_angle_deg,
                   double*        out_offset_px) {
    if (!engine_ready()) return -3;
    if (!pixels || !out_angle_deg || !out_offset_px) return -4;

    // Work only on the lower half of the frame (horizon is never above midpoint
    // at normal maritime height-of-eye values).
    cv::Mat rgb(height, width, CV_8UC3, const_cast<uint8_t*>(pixels));
    int lowerStart = height / 2;
    int lowerH     = height - lowerStart;
    cv::Mat lower  = rgb(cv::Rect(0, lowerStart, width, lowerH));

    cv::Mat lowerGray;
    cv::cvtColor(lower, lowerGray, cv::COLOR_RGB2GRAY);

    // ── Canny edge ────────────────────────────────────────────────────────────
    cv::Mat edges;
    cv::Canny(lowerGray, edges, /*low=*/50, /*high=*/150);

    // ── Hough lines ──────────────────────────────────────────────────────────
    // Standard Hough (not probabilistic) gives rho/theta directly.
    std::vector<cv::Vec2f> lines;
    cv::HoughLines(edges, lines,
                   /*rho=*/1.0,
                   /*theta=*/CV_PI / 180.0,
                   /*votes=*/80);

    if (lines.empty()) {
        LOGI("detect_horizon: no lines found");
        return -1;
    }

    // ── Filter: keep near-horizontal lines (|theta - π/2| < 5°) ─────────────
    constexpr double kMaxTiltRad = 5.0 * M_PI / 180.0;
    std::vector<double> horizonRhos;    // rho = signed dist from origin
    std::vector<double> horizonThetas;

    for (const auto& l : lines) {
        double theta = static_cast<double>(l[1]);
        // Near-horizontal: theta ≈ π/2
        if (std::abs(theta - M_PI / 2.0) < kMaxTiltRad) {
            horizonRhos.push_back(static_cast<double>(l[0]));
            horizonThetas.push_back(theta);
        }
    }

    if (horizonRhos.empty()) {
        LOGI("detect_horizon: no horizontal lines survived filter");
        return -1;
    }

    // ── Variance check: if spread > 10% of frame height, waves too high ──────
    double sumRho = std::accumulate(horizonRhos.begin(), horizonRhos.end(), 0.0);
    double meanRho = sumRho / horizonRhos.size();

    double variance = 0.0;
    for (double r : horizonRhos)
        variance += (r - meanRho) * (r - meanRho);
    variance /= horizonRhos.size();
    double stdDevRho = std::sqrt(variance);

    double relativeStdDev = stdDevRho / static_cast<double>(lowerH);
    if (relativeStdDev > 0.10) {
        LOGW("detect_horizon: wave variance %.1f%% > 10%% — frame rejected",
             relativeStdDev * 100.0);
        return -1;
    }

    // ── Dominant line ─────────────────────────────────────────────────────────
    double meanTheta = std::accumulate(horizonThetas.begin(),
                                       horizonThetas.end(), 0.0)
                       / horizonThetas.size();

    // rho in the lower crop → full-frame y pixel
    // In Hough: rho = x*cos(theta) + y*sin(theta)
    // At x = width/2, y_full = rho/sin(theta) + lowerStart
    double yFull = meanRho / std::sin(meanTheta) + static_cast<double>(lowerStart);

    // 8° forbidden zone: reject if detected horizon is within 8° of bottom
    int forbiddenY = height - static_cast<int>(
        std::tan(8.0 * M_PI / 180.0) / std::tan(g_state.fovV / 2.0)
        * (height / 2.0));
    if (yFull > forbiddenY) {
        LOGW("detect_horizon: horizon at y=%.0f is in 8° forbidden zone (y>%d)",
             yFull, forbiddenY);
        return -1;
    }

    // Tilt angle: deviation of theta from π/2
    *out_angle_deg  = (meanTheta - M_PI / 2.0) * 180.0 / M_PI;
    *out_offset_px  = (height / 2.0) - yFull;   // + = horizon above centre

    LOGI("detect_horizon: angle=%.2f° offset=%.1fpx",
         *out_angle_deg, *out_offset_px);
    return 0;
}

// ─────────────────────────────────────────────────────────────────────────────
double get_last_processing_confidence(void) {
    return g_state.initialised ? g_state.lastConfidence : 0.0;
}

// ─────────────────────────────────────────────────────────────────────────────
void shutdown_vision_engine(void) {
    if (!g_state.initialised) return;

    // Release pre-allocated Mats
    g_state.grayBuf.release();
    g_state.blurBuf.release();
    g_state.threshBuf.release();
    g_state.edgeBuf.release();

    g_state.initialised = false;
    LOGI("shutdown: engine released");
}

}  // extern "C"
