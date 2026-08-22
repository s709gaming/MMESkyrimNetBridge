cmake_minimum_required(VERSION 3.25)

project(
    MMEExtensions
    VERSION 0.4.0
    DESCRIPTION "Native lifecycle bridge for MME Extensions"
    LANGUAGES CXX
)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Universal builds remain the release default. Presets may turn off the
# desktop ABIs to produce a VR-only validation/development build.
option(ENABLE_SKYRIM_SE "Enable Skyrim SE support" ON)
option(ENABLE_SKYRIM_AE "Enable Skyrim AE support" ON)
option(ENABLE_SKYRIM_VR "Enable Skyrim VR support" ON)
set(BUILD_TESTS OFF CACHE BOOL "" FORCE)

# Build the pinned local CommonLibSSE-NG checkout and expose its plugin helper.
add_subdirectory(extern/CommonLibSSE-NG EXCLUDE_FROM_ALL)
include(extern/CommonLibSSE-NG/cmake/CommonLibSSE.cmake)

# Address Library-based NG builds can support SE, AE, and VR in one DLL, while
# the VR preset below proves that no desktop-only compile dependency leaked in.
add_commonlibsse_plugin(
    MMEExtensions
    NAME "MMEExtensions"
    AUTHOR "MMEAlert contributors"
    VERSION ${PROJECT_VERSION}
    USE_ADDRESS_LIBRARY
    SOURCES src/Plugin.cpp
)

target_compile_features(MMEExtensions PRIVATE cxx_std_23)
target_precompile_headers(MMEExtensions PRIVATE include/PCH.h)

if(MSVC)
    target_compile_options(MMEExtensions PRIVATE /permissive- /W4 /WX)
endif()

# Put the finished DLL directly in a Skyrim/Vortex-compatible folder tree.
set_target_properties(
    MMEExtensions
    PROPERTIES
        OUTPUT_NAME "MMEExtensions"
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/package/SKSE/Plugins"
)
