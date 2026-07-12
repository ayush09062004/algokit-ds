cmake_minimum_required(VERSION 3.16)
project(algokit_ds LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
endif()

# Speed up rebuilds within the same session/container if ccache is available.
find_program(CCACHE_PROGRAM ccache)
if(CCACHE_PROGRAM)
    set(CMAKE_CXX_COMPILER_LAUNCHER ${CCACHE_PROGRAM})
endif()

find_package(SWIG 4.0 REQUIRED)
include(UseSWIG)

# Find the Python interpreter and the extension-module development target.
find_package(Python3 REQUIRED COMPONENTS Interpreter Development.Module)

# ---------------------------------------------------------------------------
# Generated Python package
# ---------------------------------------------------------------------------
set(SWIG_OUT_DIR ${CMAKE_SOURCE_DIR}/python/algokit_ds/_swig)

file(MAKE_DIRECTORY ${SWIG_OUT_DIR})
file(WRITE ${SWIG_OUT_DIR}/__init__.py "")

set(CMAKE_SWIG_OUTDIR ${SWIG_OUT_DIR})
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${SWIG_OUT_DIR})
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${SWIG_OUT_DIR})

include_directories(${Python3_INCLUDE_DIRS})

# ---------------------------------------------------------------------------
# SWIG interface files
# ---------------------------------------------------------------------------
set(ALGOKIT_MODULES
    vector
    deque
    stack
    queue
    set
    multiset
    unordered_set
    unordered_multiset
    map
    multimap
    unordered_map
)

# A tiny static "sink" target that exists only to own a precompiled header.
# Every module below reuses it via target_precompile_headers(... REUSE_FROM),
# so the STL headers common to all 11 SWIG modules (<vector>, <map>,
# <string>, ...) are parsed once instead of 11 times.
add_library(algokit_pch OBJECT ${CMAKE_SOURCE_DIR}/cmake/pch_dummy.cpp)
set_target_properties(algokit_pch PROPERTIES POSITION_INDEPENDENT_CODE ON)
target_include_directories(algokit_pch PRIVATE ${Python3_INCLUDE_DIRS})
target_precompile_headers(algokit_pch PRIVATE
    <vector>
    <deque>
    <stack>
    <queue>
    <set>
    <unordered_set>
    <map>
    <unordered_map>
    <string>
)

foreach(mod ${ALGOKIT_MODULES})
    set(interface_file ${CMAKE_SOURCE_DIR}/swig/${mod}.i)

    set_property(SOURCE ${interface_file} PROPERTY CPLUSPLUS ON)

    swig_add_library(${mod}
        TYPE MODULE
        LANGUAGE python
        SOURCES ${interface_file}
    )

    set_property(TARGET ${mod}
        PROPERTY SWIG_USE_TARGET_INCLUDE_DIRECTORIES TRUE
    )

    target_include_directories(${mod}
        PRIVATE
            ${Python3_INCLUDE_DIRS}
    )

    target_precompile_headers(${mod} REUSE_FROM algokit_pch)

    # Correct target for Python extension modules.
    target_link_libraries(${mod}
        PRIVATE
            Python3::Module
    )

    set_target_properties(${mod}
        PROPERTIES
            LIBRARY_OUTPUT_DIRECTORY ${SWIG_OUT_DIR}
            RUNTIME_OUTPUT_DIRECTORY ${SWIG_OUT_DIR}
    )
endforeach()