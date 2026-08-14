cmake_minimum_required(VERSION 3.25)

project(
    MMEExtensions
    VERSION 0.1.0
    DESCRIPTION "Native lifecycle bridge for MME Extensions"
    LANGUAGES CXX
)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# This native bridge targets desktop Skyrim SE/AE, not Skyrim VR.
set(ENABLE_SKYRIM_SE ON CACHE BOOL "" FORCE)
set(ENABLE_SKYRIM_AE ON CACHE BOOL "" FORCE)
set(ENABLE_SKYRIM_VR OFF CACHE BOOL "" FORCE)
set(BUILD_TESTS OFF CACHE BOOL "" FORCE)

# Build the pinned local CommonLibSSE-NG checkout and expose its plugin helper.
add_subdirectory(extern/CommonLibSSE-NG EXCLUDE_FROM_ALL)
include(extern/CommonLibSSE-NG/cmake/CommonLibSSE.cmake)

# A fixed compatible runtime avoids requiring Address Library.
add_commonlibsse_plugin(
    MMEExtensions
    NAME "MMEExtensions"
    AUTHOR "MMEAlert contributors"
    VERSION ${PROJECT_VERSION}
    COMPATIBLE_RUNTIMES 1.6.1170.0
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
