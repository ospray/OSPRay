## Copyright 2009-2021 Intel Corporation
## SPDX-License-Identifier: Apache-2.0

## Global settings ##

cmake_minimum_required(VERSION 3.1)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/dependencies)

if(NOT CMAKE_INSTALL_PREFIX)
  set(CMAKE_INSTALL_PREFIX
      "${CMAKE_BINARY_DIR}/install"
      CACHE STRING "Final install location." FORCE)
endif()

if (NOT DEPENDENCIES_BUILD_TYPE)
  set(DEPENDENCIES_BUILD_TYPE Release)
endif()

## Establish project ##

project(OSPRay_superbuild)

if(CMAKE_SIZEOF_VOID_P EQUAL 4)
  message(FATAL_ERROR "OSPRay can only be built on 64-bit platforms. This
  problem most commonly happens on Windows, where the right solution is to
  switch to a 64-bit generator: retry running CMake with '-G \"Visual
  Studio 15 2017 Win64\"'")
else()
  message(STATUS "Proceeding with a 64-bit generator. (${CMAKE_SIZEOF_VOID_P})")
endif()

if (POLICY CMP0114)
  # allow old CMake behavior: NO_DEPENDS for ExternalProject_Add_StepTargets
  cmake_policy(SET CMP0114 OLD) # 3.19
endif ()

include(ExternalProject)
include(GNUInstallDirs)
include(ProcessorCount)
include(CMakeDependentOption)

## Superbuild options ##

ProcessorCount(PROCESSOR_COUNT)

if(NOT PROCESSOR_COUNT EQUAL 0)
  set(BUILD_JOBS ${PROCESSOR_COUNT} CACHE STRING "Number of build jobs '-j <n>'")
else()
  set(BUILD_JOBS 4 CACHE STRING "Number of build jobs '-j <n>'")
endif()

option(ALWAYS_REBUILD "Force every project to always be rebuilt?" OFF)

option(DOWNLOAD_ISPC "Download ISPC or use the one found in ${PATH}?" ON)
set(ISPC_VERSION "1.15.0" CACHE STRING "Which version of ISCP to download?")
if (ISPC_VERSION STREQUAL "1.15.0")
  if (APPLE)
    set(ISPC_HASH "eb736abb5ed197504113aa88e5ea04ca13f47add87a96b386be95b14776b2048")
  elseif (WIN32)
    set(ISPC_HASH "76a10ba670b5163c22dfd354d003535fd0cf0cfd1287aed8724e6cca0f2105b7")
  else()
    set(ISPC_HASH "b67f50ab16b38d29e28b0a2dbb9733fd6fc1276cb5a5be0cac78e356941f881f")
  endif()
endif()

set(RKCOMMON_VERSION "1.6.1" CACHE STRING "Which version of rkcommon to build?")
if (RKCOMMON_VERSION STREQUAL "1.6.1")
  set(RKCOMMON_HASH "96b1f2fe5f6699fef6499c997c7bc7900d4a602ae6257e977c42e20a713e4615")
endif()

option(DOWNLOAD_TBB "Download TBB or use the only found in the system environment?" ON)
set(TBB_VERSION "2021.2.0" CACHE STRING "Which version of TBB to download?")
if (TBB_VERSION STREQUAL "2021.2.0")
  if (APPLE)
    set(TBB_HASH "ed6545190b747af9585ab8eedd5c8ccdf7cef304b6caa8db25803389fb24ec62")
  elseif (WIN32)
    set(TBB_HASH "9be37b1cb604a5905db0a15b2b893d85579fd0b2f1024859e1f75e96d7331a02")
  else()
    set(TBB_HASH "bcaa0aa7c0d2851a730cb0f64ad120f06a7b63811c8cc49e51ea8e1579f51b05")
  endif()
endif()

option(BUILD_EMBREE_FROM_SOURCE "Build Embree or use pre-built version?" ON)
set(EMBREE_VERSION "3.13.0" CACHE STRING "Which version of Embree to build?")
if (EMBREE_VERSION STREQUAL "3.13.0")
  if (BUILD_EMBREE_FROM_SOURCE)
    set(EMBREE_HASH "9850b9cb79cc7d06c734475e0df36484457d4fcb9cbf09c9975cda07647a86b4")
  else()
    if (APPLE)
      set(EMBREE_HASH "bd10cefae71c6ddea664d923a7b7a4d9f931c101d08ca03a542636f3513e159d")
    elseif (WIN32)
      set(EMBREE_HASH "3677cbb589edc4a1608ab66ed7c5e31ba2b24f7e4e133d553a551cfc198eb052")
    else()
      set(EMBREE_HASH "22ff3fff6ba9f29dff7e8134a9e9434a7ea4497d259051ece7bec34391d4f0b7")
    endif()
  endif()
endif()

set(OPENVKL_VERSION "devel" CACHE STRING "Which version of OpenVKL to build?")
if (OPENVKL_VERSION STREQUAL "0.13.0")
  set(OPENVKL_HASH "441c7a9d817ed40aae00b33b4926c2c42a95ffbfc294d922cd78728e2b4fb31d")
endif()

option(BUILD_OIDN "Build OpenImageDenoise as a part of the superbuild." OFF)
option(BUILD_OIDN_FROM_SOURCE "Build OpenImageDenoise or use pre-built version?" OFF)
set(OIDN_VERSION "1.4.0" CACHE STRING "Which version of OpenImageDenoise to build?")
if (OIDN_VERSION STREQUAL "1.4.0")
  if (APPLE)
    set(OIDN_HASH "0bbab6ac504fbde2d3b9c247e7a88dc7134f93e64ccaa7f441c6c8e00a0231d5")
  elseif (WIN32)
    set(OIDN_HASH "52fc7205a09227fc6468eb8fe7f6b8a58cc69c085f8d96088a3e9422ca4dbe32")
  else()
    set(OIDN_HASH "27ea8ec7fddf23a4a27a37fcffa184723d628809451b717bb8a8cb6e289e2f2e")
  endif()
endif()

option(BUILD_GLFW "Build glfw for OSPRay examples or use one in existing environment?" ON)

option(BUILD_DEPENDENCIES_ONLY "Don't build OSPRay itself, only its dependencies" OFF)
option(BUILD_OSPRAY_CI_EXTRAS "Enable OSPRay's extra compiler checks." OFF)

option(BUILD_OSPRAY_APPS "Enable building OSPRay apps" ON)
option(BUILD_OSPRAY_MODULE_MPI "Enable building module_mpi" OFF)

option(INSTALL_IN_SEPARATE_DIRECTORIES
  "Install libraries into their own directories under CMAKE_INSTALL_PREFIX"
  ON
)

option(INSTALL_DEPENDENCIES "Install OSPRay dependencies" ON)

## Setup top-level variables ##

set(installDir ${CMAKE_INSTALL_PREFIX})

get_filename_component(INSTALL_DIR_ABSOLUTE
  ${installDir} ABSOLUTE BASE_DIR ${CMAKE_CURRENT_BINARY_DIR})

if (${CMAKE_VERSION} VERSION_GREATER 3.11.4)
  set(PARALLEL_JOBS_OPTS -j ${BUILD_JOBS})
endif()

## Build dependencies ##
set(DEFAULT_BUILD_COMMAND ${CMAKE_COMMAND} --build . --config ${DEPENDENCIES_BUILD_TYPE} ${PARALLEL_JOBS_OPTS})

if (DOWNLOAD_ISPC)
  include(dep_ispc)
endif()

if (DOWNLOAD_TBB)
  include(dep_tbb)
endif()

include(dep_rkcommon)
include(dep_embree)
include(dep_openvkl)

if (BUILD_GLFW)
  include(dep_glfw)
endif()

if (BUILD_OIDN)
  include(dep_oidn)
endif()

include(dep_glm)

## Build main projects ##
set(DEFAULT_BUILD_COMMAND ${CMAKE_COMMAND} --build . --config $<CONFIG> ${PARALLEL_JOBS_OPTS})

if (BUILD_OSPRAY_MODULE_MPI)
  set(OSPRAY_ENABLE_MODULES ON)
  set(OSPRAY_MODULE_MPI ON)
endif()

if (NOT BUILD_DEPENDENCIES_ONLY)
  include(build_ospray.cmake)
endif()
