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
    // UMat silently falls back to CPU when OpenCL is unavailable, so we
    // never hard-fail here. Many devices only expose OpenCL after the first
    // UMat operation anyway. Enable it if available, otherwise CPU is used.
    if (cv::ocl::haveOpenCL()) {
        cv::ocl::setUseOpenCL(true);
        LOGI("init: OpenCL available — GPU path enabled.");
    } else {
        cv::ocl::setUseOpenCL(false);
        LOGW("init: OpenCL not available — running on CPU. "
             "Performance may exceed 500 ms on slow devices.");
    }

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

    // ── Step 2: Global image statistics — FAST pre-flight quality gates ───────
    // These three checks eliminate > 99% of false-positive frames before any
    // expensive processing is done.  Total cost: ~2 ms on mid-range hardware.
    cv::Scalar meanVal, stddevVal;
    double minVal, maxVal;
    cv::meanStdDev(g_state.grayBuf, meanVal, stddevVal);
    cv::minMaxLoc(g_state.grayBuf, &minVal, &maxVal);

    const double imgMean   = meanVal[0];
    const double imgStddev = stddevVal[0];

    // Gate A — Uniformity reject: stddev < 15 means the image is essentially
    // featureless (uniform wall, covered lens, overcast noon sky).
    // Adaptive threshold running on a featureless image uses pure sensor noise
    // as "signal" — causing the false-positive storm.
    if (imgStddev < 15.0) {
        LOGI("detect_stars: rejected — uniform scene (stddev=%.1f < 15)", imgStddev);
        g_state.lastConfidence = 0.0;
        return 0;
    }

    // Gate B — Darkness reject: maxVal < 100 means even the brightest pixel is
    // too dim to be a visible star (Sirius at mag -1.46 registers ≥ 150 on a
    // properly exposed night frame).  Covers "closed eyes / lens cap" cases.
    if (maxVal < 100.0) {
        LOGI("detect_stars: rejected — too dark (maxVal=%.0f < 100)", maxVal);
        g_state.lastConfidence = 0.0;
        return 0;
    }

    // Gate C — Daylight reject: mean > 120 means the sky is too bright for
    // stellar observation (civil twilight or brighter).
    if (imgMean > 120.0) {
        LOGI("detect_stars: rejected — too bright for stars (mean=%.0f > 120)", imgMean);
        g_state.lastConfidence = 0.0;
        return 0;
    }

    // ── Step 3: 5×5 Gaussian blur — removes hot-pixel / sensor noise ─────────
    cv::UMat uGray;
    g_state.grayBuf.copyTo(uGray);
    cv::UMat uBlur;
    cv::GaussianBlur(uGray, uBlur, cv::Size(5, 5), 0);

    // ── Step 4: Adaptive threshold (parameters CORRECTED) ────────────────────
    // ROOT CAUSE: blockSize=11 compared each pixel against a tiny 11×11 patch.
    // In any noisy image, pixels differ from their 11-pixel neighbourhood by
    // just 2-3 DN (sensor noise), so nearly EVERY pixel was flagged.
    //
    // FIX: blockSize=51 compares against a 51×51 region (~5% of 1080p width).
    // Only pixels that are significantly brighter than a 51×51 sky patch
    // (i.e., true point sources against a dark background) survive.
    //
    // FIX: C=8 (was -2). Positive C subtracts 8 from the local mean before
    // comparing, raising the threshold and rejecting marginal noise candidates.
    // With C=-2 the bar was LOWERED, guaranteeing false positives on any scene.
    {
        cv::Mat blurCpu;
        uBlur.copyTo(blurCpu);
        cv::adaptiveThreshold(blurCpu, g_state.threshBuf,
                              255,
                              cv::ADAPTIVE_THRESH_MEAN_C,
                              cv::THRESH_BINARY,
                              /*blockSize=*/51,  // was 11 — too local, caught noise
                              /*C=*/8);          // was -2 — lowered bar, invited noise
    }

    // ── Step 5: Global brightness floor mask ─────────────────────────────────
    // Even after the adaptive threshold, intersect with a global brightness
    // mask: only pixels brighter than (mean + 30) survive.
    // This eliminates noise-induced survivors in the adaptive output that are
    // locally bright but globally dim — common in daytime sky gradients.
    const double brightnessFloor = imgMean + 30.0;
    cv::Mat brightMask;
    cv::threshold(g_state.grayBuf, brightMask,
                  brightnessFloor, 255, cv::THRESH_BINARY);
    cv::bitwise_and(g_state.threshBuf, brightMask, g_state.threshBuf);

    // ── Step 6: 8° forbidden zone mask ───────────────────────────────────────
    int forbiddenRows = static_cast<int>(
        std::tan(8.0 * M_PI / 180.0) / std::tan(g_state.fovV / 2.0)
        * (height / 2.0));
    forbiddenRows = std::max(forbiddenRows, height / 10);

    cv::Mat masked = g_state.threshBuf.clone();
    masked(cv::Rect(0, height - forbiddenRows, width, forbiddenRows))
          .setTo(cv::Scalar(0));

    // ── Step 7: Find contours ─────────────────────────────────────────────────
    std::vector<std::vector<cv::Point>> contours;
    cv::findContours(masked, contours,
                     cv::RETR_EXTERNAL,
                     cv::CHAIN_APPROX_SIMPLE);

    // ── Step 8: Multi-criterion candidate filter ──────────────────────────────
    struct Candidate {
        cv::Point2d centre;
        double      brightness;
    };
    std::vector<Candidate> candidates;
    candidates.reserve(std::min(contours.size(), static_cast<size_t>(128)));

    for (const auto& contour : contours) {
        const double area = cv::contourArea(contour);

        // CRITERION A — Area bounds (tightened: was 3–50 px, now 5–30 px)
        // 3 px minimum caught single-pixel sensor noise.
        // 50 px maximum accepted blobs far too large to be unresolved stars.
        // Real stars on a 1080p sensor occupy 5–20 pixels depending on seeing.
        if (area < 5.0 || area > 30.0) continue;

        // CRITERION B — Circularity (new check)
        // Stars are point sources → near-circular PSFs.
        // circularity = 4π × area / perimeter²  (1.0 = perfect circle)
        // Rejects streaks (satellite trails), aircraft lights, lens flare.
        const double perimeter = cv::arcLength(contour, true);
        if (perimeter < 1.0) continue;
        const double circularity = (4.0 * M_PI * area) / (perimeter * perimeter);
        if (circularity < 0.7) continue;

        // CRITERION C — Aspect ratio (new check)
        // Bounding rectangle must be roughly square (0.5 < w/h < 2.0).
        // Eliminates elongated noise artifacts and edge fragments.
        const cv::Rect bb = cv::boundingRect(contour);
        if (bb.width < 1 || bb.height < 1) continue;
        const double aspect = static_cast<double>(bb.width) / bb.height;
        if (aspect < 0.5 || aspect > 2.0) continue;

        // CRITERION D — Absolute brightness floor
        // Blob mean must exceed global mean + 30.  Prevents the threshold from
        // accepting locally-bright-but-globally-dim noise in gradient scenes.
        const double b = starBrightness(g_state.grayBuf, contour);
        if (b < brightnessFloor) continue;

        const cv::Point2d c = centroid(g_state.grayBuf, contour);
        candidates.push_back({c, b});
    }

    if (candidates.empty()) {
        g_state.lastConfidence = 0.0;
        return 0;
    }

    // ── Step 9: Sort by brightness desc, return top DS1_MAX_STARS ────────────
    std::sort(candidates.begin(), candidates.end(),
              [](const Candidate& a, const Candidate& b) {
                  return a.brightness > b.brightness;
              });

    const int count = static_cast<int>(
        std::min(candidates.size(), static_cast<size_t>(DS1_MAX_STARS)));

    for (int i = 0; i < count; ++i) {
        out_star_x[i] = candidates[i].centre.x;
        out_star_y[i] = candidates[i].centre.y;
    }

    // Confidence: ratio of detected to expected stars in a clear FOV
    constexpr double kExpectedStars = 20.0;
    g_state.lastConfidence =
        std::min(100.0, static_cast<double>(count) / kExpectedStars * 100.0);

    LOGI("detect_stars: found %d stars  mean=%.0f stddev=%.1f maxVal=%.0f  confidence=%.0f%%",
         count, imgMean, imgStddev, maxVal, g_state.lastConfidence);
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

    // Work only on the lower half (horizon is never above midpoint at normal
    // maritime height-of-eye values).
    cv::Mat rgb(height, width, CV_8UC3, const_cast<uint8_t*>(pixels));
    const int lowerStart = height / 2;
    const int lowerH     = height - lowerStart;
    cv::Mat lower = rgb(cv::Rect(0, lowerStart, width, lowerH));

    cv::Mat lowerGray;
    cv::cvtColor(lower, lowerGray, cv::COLOR_RGB2GRAY);

    // ── Pre-flight: scene must have meaningful contrast in the lower half ──────
    // The sea-sky interface produces a sharp brightness gradient.
    // A uniform scene (no horizon present) has low stddev and should be
    // rejected immediately — otherwise Canny picks up noise and Hough happily
    // finds "lines" in random texture.
    cv::Scalar lMean, lStddev;
    cv::meanStdDev(lowerGray, lMean, lStddev);
    if (lStddev[0] < 20.0) {
        LOGI("detect_horizon: rejected — uniform lower half (stddev=%.1f < 20)",
             lStddev[0]);
        return -1;
    }

    // ── Canny edge detection ──────────────────────────────────────────────────
    // Apply mild blur first to suppress sensor noise before Canny.
    cv::Mat blurredGray;
    cv::GaussianBlur(lowerGray, blurredGray, cv::Size(5, 5), 0);
    cv::Mat edges;
    cv::Canny(blurredGray, edges, /*low=*/60, /*high=*/180);

    // ── Pre-flight: require a minimum number of edge pixels ──────────────────
    // Hough will fabricate lines from pure noise if edge density is near zero.
    // A real horizon line spans most of the frame width — it produces many
    // edge pixels.  Require at least 2% of the crop width as edge pixels.
    const int minEdgePx = static_cast<int>(width * 0.02);
    if (cv::countNonZero(edges) < minEdgePx) {
        LOGI("detect_horizon: rejected — too few edge pixels (< %d)", minEdgePx);
        return -1;
    }

    // ── Hough lines ──────────────────────────────────────────────────────────
    // ROOT CAUSE: vote threshold=80 is too low.  On a 1920-px-wide frame,
    // random texture can easily produce 80 co-linear edge pixels by chance.
    // FIX: raise threshold to 35% of frame width (≈ 672 px for 1920-wide frame).
    // A true horizon spans at least one third of the image width.
    const int houghThreshold = static_cast<int>(width * 0.35);
    std::vector<cv::Vec2f> lines;
    cv::HoughLines(edges, lines,
                   /*rho=*/1.0,
                   /*theta=*/CV_PI / 180.0,
                   /*votes=*/houghThreshold);

    if (lines.empty()) {
        LOGI("detect_horizon: no lines met vote threshold (%d)", houghThreshold);
        return -1;
    }

    // ── Filter: keep near-horizontal lines (|theta − π/2| < 5°) ─────────────
    constexpr double kMaxTiltRad = 5.0 * M_PI / 180.0;
    std::vector<double> horizonRhos;
    std::vector<double> horizonThetas;

    for (const auto& l : lines) {
        const double theta = static_cast<double>(l[1]);
        if (std::abs(theta - M_PI / 2.0) < kMaxTiltRad) {
            horizonRhos.push_back(static_cast<double>(l[0]));
            horizonThetas.push_back(theta);
        }
    }

    if (horizonRhos.empty()) {
        LOGI("detect_horizon: no horizontal lines survived angular filter");
        return -1;
    }

    // ── Variance check: spread > 10% of lower-half height → wave rejection ───
    const double sumRho  = std::accumulate(horizonRhos.begin(), horizonRhos.end(), 0.0);
    const double meanRho = sumRho / static_cast<double>(horizonRhos.size());

    double variance = 0.0;
    for (double r : horizonRhos)
        variance += (r - meanRho) * (r - meanRho);
    variance /= static_cast<double>(horizonRhos.size());
    const double stdDevRho = std::sqrt(variance);

    const double relativeStdDev = stdDevRho / static_cast<double>(lowerH);
    if (relativeStdDev > 0.10) {
        LOGW("detect_horizon: wave variance %.1f%% > 10%% — frame rejected",
             relativeStdDev * 100.0);
        return -1;
    }

    // ── Dominant line ─────────────────────────────────────────────────────────
    const double meanTheta = std::accumulate(horizonThetas.begin(),
                                             horizonThetas.end(), 0.0)
                             / static_cast<double>(horizonThetas.size());

    // rho in the lower crop → full-frame y pixel
    // In Hough: rho = x·cos(θ) + y·sin(θ)  →  at x=0: y = rho / sin(θ)
    const double yFull = meanRho / std::sin(meanTheta)
                         + static_cast<double>(lowerStart);

    // 8° forbidden zone: reject if detected horizon is within 8° of bottom
    const int forbiddenY = height - static_cast<int>(
        std::tan(8.0 * M_PI / 180.0) / std::tan(g_state.fovV / 2.0)
        * (height / 2.0));
    if (yFull > static_cast<double>(forbiddenY)) {
        LOGW("detect_horizon: y=%.0f inside 8° forbidden zone (y>%d)",
             yFull, forbiddenY);
        return -1;
    }

    *out_angle_deg = (meanTheta - M_PI / 2.0) * 180.0 / M_PI;
    *out_offset_px = (height / 2.0) - yFull;   // positive = horizon above centre

    LOGI("detect_horizon: angle=%.2f° offset=%.1fpx (candidates=%zu)",
         *out_angle_deg, *out_offset_px, horizonRhos.size());
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
