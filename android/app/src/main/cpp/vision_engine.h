#pragma once
#include <cstdint>

// ── DS-1 Vision Engine — Public C API ────────────────────────────────────────
// All functions are safe to call from multiple threads EXCEPT init / shutdown.
// Every function that can fail returns an int:
//   0   = success
//  -1   = frame/condition rejected (waves, no horizon, no stars)
//  -2   = GPU / OpenCL not available
//  -3   = engine not initialised (call init_vision_engine first)
//  -4   = invalid argument (null pointer, bad dimensions)
// ─────────────────────────────────────────────────────────────────────────────

#ifdef __cplusplus
extern "C" {
#endif

#define DS1_MAX_STARS 50

/// Initialise the vision engine.
/// Must be called once before any other function.
///
/// @param image_width      Expected frame width  (pixels)
/// @param image_height     Expected frame height (pixels)
/// @param focal_length_mm  Effective focal length in mm (from calibration)
/// @param sensor_width_mm  Physical sensor width  in mm (from calibration)
/// @return  0  success
///         -2  OpenCL / GPU not available on this device
///         -4  invalid dimensions (≤ 0)
int init_vision_engine(int    image_width,
                       int    image_height,
                       double focal_length_mm,
                       double sensor_width_mm);

/// Detect star centroids in one grayscale or RGB-888 frame.
///
/// @param pixels       Raw frame bytes.  RGB-888: width*height*3 bytes.
/// @param width        Frame width  (must match value passed to init)
/// @param height       Frame height (must match value passed to init)
/// @param out_star_x   Caller-allocated array of at least DS1_MAX_STARS doubles
/// @param out_star_y   Caller-allocated array of at least DS1_MAX_STARS doubles
/// @return  N ≥ 0   number of stars written into out_star_x / out_star_y
///         -1       frame rejected (horizon too low, fog, overexposed)
///         -3       engine not initialised
///         -4       null pointer argument
int detect_stars(const uint8_t* pixels,
                 int            width,
                 int            height,
                 double*        out_star_x,
                 double*        out_star_y);

/// Detect the horizon line in one frame.
///
/// @param pixels           Raw RGB-888 frame bytes
/// @param width            Frame width
/// @param height           Frame height
/// @param out_angle_deg    Horizon tilt angle in degrees (0 = level)
/// @param out_offset_px    Signed pixel offset from frame centre (+ = above)
/// @return  0   horizon detected reliably
///         -1   rejected: no horizon found, or wave variance > 10 %
///         -3   engine not initialised
///         -4   null pointer
int detect_horizon(const uint8_t* pixels,
                   int            width,
                   int            height,
                   double*        out_angle_deg,
                   double*        out_offset_px);

/// Returns the quality score (0–100) computed during the last detect_stars()
/// call.  Combines star count, brightness distribution, and frame sharpness.
/// Returns 0.0 if engine is not initialised or no frame has been processed.
double get_last_processing_confidence(void);

/// Release all native resources.  Safe to call even if init failed.
void shutdown_vision_engine(void);

#ifdef __cplusplus
}
#endif
