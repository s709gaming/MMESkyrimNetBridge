cmake_minimum_required(VERSION 3.25)

project(
    MMEAlertTest
    VERSION 0.1.0
    DESCRIPTION "Minimal CommonLibSSE-NG load test for MMEAlert"
    LANGUAGES CXX
)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# This first native test targets desktop Skyrim SE/AE, not Skyrim VR.
set(ENABLE_SKYRIM_SE ON CACHE BOOL "" FORCE)
set(ENABLE_SKYRIM_AE ON CACHE BOOL "" FORCE)
set(ENABLE_SKYRIM_VR OFF CACHE BOOL "" FORCE)
set(BUILD_TESTS OFF CACHE BOOL "" FORCE)

# Build the pinned local CommonLibSSE-NG checkout and expose its plugin helper.
add_subdirectory(extern/CommonLibSSE-NG EXCLUDE_FROM_ALL)
include(extern/CommonLibSSE-NG/cmake/CommonLibSSE.cmake)

# A fixed compatible runtime avoids requiring Address Library for this log-only test.
add_commonlibsse_plugin(
    MMEAlertTest
    NAME "MMEAlertTest"
    AUTHOR "MMEAlert contributors"
    VERSION ${PROJECT_VERSION}
    COMPATIBLE_RUNTIMES 1.6.1170.0
    SOURCES src/Plugin.cpp
)

target_compile_features(MMEAlertTest PRIVATE cxx_std_23)
target_precompile_headers(MMEAlertTest PRIVATE include/PCH.h)

if(MSVC)
    target_compile_options(MMEAlertTest PRIVATE /permissive- /W4 /WX)
endif()

# Put the finished DLL directly in a Skyrim/Vortex-compatible folder tree.
set_target_properties(
    MMEAlertTest
    PROPERTIES
        OUTPUT_NAME "MMEAlertTest"
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/package/SKSE/Plugins"
)
