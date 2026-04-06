cmake_minimum_required(VERSION 3.22)
project(ds1_vision VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# ── OpenCV Mobile ─────────────────────────────────────────────────────────────
# Place the OpenCV Android SDK at android/opencv/  and set OPENCV_ANDROID_SDK
# in your local.properties:
#   opencvSdk=/path/to/OpenCV-android-sdk
# Then gradle passes it through as -DOPENCV_DIR=...
#
# If OPENCV_DIR is not set (CI / first clone) we emit a clear fatal error
# instead of producing a broken .so.
if(NOT DEFINED OPENCV_DIR)
    message(FATAL_ERROR
        "DS1: OPENCV_DIR is not set.\n"
        "Download the OpenCV Android SDK from https://opencv.org/releases/ "
        "and add  opencvSdk=/absolute/path/to/OpenCV-android-sdk  "
        "to android/local.properties, then re-sync.\n"
        "CMake variable: -DOPENCV_DIR=<path>/sdk/native/jni")
endif()

find_package(OpenCV REQUIRED
    PATHS "${OPENCV_DIR}"
    NO_DEFAULT_PATH
    COMPONENTS core imgproc)

# ── Shared library ────────────────────────────────────────────────────────────
add_library(ds1_vision SHARED
    vision_engine.cpp)

target_include_directories(ds1_vision PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${OpenCV_INCLUDE_DIRS})

# Android system libraries
find_library(log-lib    log)
find_library(android-lib android)

target_link_libraries(ds1_vision
    ${OpenCV_LIBS}
    ${log-lib}
    ${android-lib})

# ── Compiler options ──────────────────────────────────────────────────────────
target_compile_options(ds1_vision PRIVATE
    -O3
    -ffast-math
    -Wall
    -Wextra
    -Wno-unused-parameter)

# Strip debug symbols from release builds to reduce .so size
if(CMAKE_BUILD_TYPE STREQUAL "Release")
    target_link_options(ds1_vision PRIVATE -s)
endif()

# ── ABI filter (set in build.gradle.kts, mirrored here for IDE) ──────────────
# Supported: arm64-v8a (primary), armeabi-v7a (legacy)
# x86 / x86_64 are emulator-only; OpenCL path may not work there.
message(STATUS "DS1 building for ABI: ${ANDROID_ABI}")
