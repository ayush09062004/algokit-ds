cmake_minimum_required(VERSION 3.16)
project(algokit_ds CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Release)
endif()

find_package(SWIG 4.0 REQUIRED)
include(UseSWIG)

find_package(Python3 REQUIRED COMPONENTS Interpreter Development)

# ---------------------------------------------------------------------------
# All generated files (the .py wrappers AND the compiled .so extensions)
# are placed directly inside python/algokit_ds/_swig/, so the generated
# package is self-contained and importable without any extra path hacks.
# ---------------------------------------------------------------------------
set(SWIG_OUT_DIR ${CMAKE_SOURCE_DIR}/python/algokit_ds/_swig)
file(MAKE_DIRECTORY ${SWIG_OUT_DIR})
file(WRITE ${SWIG_OUT_DIR}/__init__.py "")

set(CMAKE_SWIG_OUTDIR ${SWIG_OUT_DIR})
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${SWIG_OUT_DIR})
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${SWIG_OUT_DIR})

include_directories(${Python3_INCLUDE_DIRS})

set_property(SOURCE ${CMAKE_SOURCE_DIR}/swig/vector.i             PROPERTY CPLUSPLUS ON)
set_property(SOURCE ${CMAKE_SOURCE_DIR}/swig/deque.i              PROPERTY CPLUSPLUS ON)
set_property(SOURCE ${CMAKE_SOURCE_DIR}/swig/stack.i              PROPERTY CPLUSPLUS ON)
set_property(SOURCE ${CMAKE_SOURCE_DIR}/swig/queue.i              PROPERTY CPLUSPLUS ON)
set_property(SOURCE ${CMAKE_SOURCE_DIR}/swig/set.i                PROPERTY CPLUSPLUS ON)
set_property(SOURCE ${CMAKE_SOURCE_DIR}/swig/multiset.i           PROPERTY CPLUSPLUS ON)
set_property(SOURCE ${CMAKE_SOURCE_DIR}/swig/unordered_set.i      PROPERTY CPLUSPLUS ON)
set_property(SOURCE ${CMAKE_SOURCE_DIR}/swig/unordered_multiset.i PROPERTY CPLUSPLUS ON)
set_property(SOURCE ${CMAKE_SOURCE_DIR}/swig/map.i                PROPERTY CPLUSPLUS ON)
set_property(SOURCE ${CMAKE_SOURCE_DIR}/swig/multimap.i           PROPERTY CPLUSPLUS ON)
set_property(SOURCE ${CMAKE_SOURCE_DIR}/swig/unordered_map.i      PROPERTY CPLUSPLUS ON)

# name -> module. Adding a new wrapped container is: add one line here,
# plus the matching swig/<name>.i file with its %template instantiations.
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

foreach(mod ${ALGOKIT_MODULES})
  swig_add_library(${mod}
    TYPE MODULE
    LANGUAGE python
    SOURCES ${CMAKE_SOURCE_DIR}/swig/${mod}.i
  )
  set_property(TARGET ${mod} PROPERTY SWIG_USE_TARGET_INCLUDE_DIRECTORIES TRUE)
  target_include_directories(${mod} PRIVATE ${Python3_INCLUDE_DIRS})
  target_link_libraries(${mod} PRIVATE ${Python3_LIBRARIES})
  set_target_properties(${mod} PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY ${SWIG_OUT_DIR}
    RUNTIME_OUTPUT_DIRECTORY ${SWIG_OUT_DIR}
  )
endforeach()
