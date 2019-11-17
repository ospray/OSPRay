## ======================================================================== ##
## Copyright 2009-2019 Intel Corporation                                    ##
##                                                                          ##
## Licensed under the Apache License, Version 2.0 (the "License");          ##
## you may not use this file except in compliance with the License.         ##
## You may obtain a copy of the License at                                  ##
##                                                                          ##
##     http://www.apache.org/licenses/LICENSE-2.0                           ##
##                                                                          ##
## Unless required by applicable law or agreed to in writing, software      ##
## distributed under the License is distributed on an "AS IS" BASIS,        ##
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. ##
## See the License for the specific language governing permissions and      ##
## limitations under the License.                                           ##
## ======================================================================== ##

include(CMakeFindDependencyMacro)

## Macro for printing CMake variables ##
macro(print var)
  message("${var} = ${${var}}")
endmacro()

## Get a list of subdirectories (single level) under a given directory
macro(get_subdirectories result curdir)
  file(GLOB children RELATIVE ${curdir} ${curdir}/*)
  set(dirlist "")
  foreach(child ${children})
    if(IS_DIRECTORY ${curdir}/${child})
      list(APPEND dirlist ${child})
    endif()
  endforeach()
  set(${result} ${dirlist})
endmacro()

## Setup CMAKE_BUILD_TYPE to have a default + cycle between options in UI
macro(ospray_configure_build_type)
  set(CONFIGURATION_TYPES "Debug;Release;RelWithDebInfo")
  if (WIN32)
    if (NOT OSPRAY_DEFAULT_CMAKE_CONFIGURATION_TYPES_SET)
      set(CMAKE_CONFIGURATION_TYPES "${CONFIGURATION_TYPES}"
          CACHE STRING "List of generated configurations." FORCE)
      set(OSPRAY_DEFAULT_CMAKE_CONFIGURATION_TYPES_SET ON
          CACHE INTERNAL "Default CMake configuration types set.")
    endif()
  else()
    if(NOT CMAKE_BUILD_TYPE)
      set(CMAKE_BUILD_TYPE "Release" CACHE STRING "Choose the build type." FORCE)
    endif()
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS ${CONFIGURATION_TYPES})
  endif()
endmacro()

# workaround link issues to Embree ISPC exports
# ISPC only adds the ISA suffix during name mangling (and dynamic dispatch
# code) when compiling for multiple targets. Thus, when only one OSPRay ISA is
# selected, but Embree was compiled for multiple ISAs, we need to add a
# second, different, supported dummy target.
macro(ospray_fix_ispc_target_list)
  list(LENGTH OSPRAY_ISPC_TARGET_LIST NUM_TARGETS)
  if (NUM_TARGETS EQUAL 1)
    if (EMBREE_ISA_SUPPORTS_SSE2)
      list(APPEND OSPRAY_ISPC_TARGET_LIST sse2)
    elseif (EMBREE_ISA_SUPPORTS_SSE4 AND
            NOT OSPRAY_ISPC_TARGET_LIST STREQUAL "sse4")
      list(APPEND OSPRAY_ISPC_TARGET_LIST sse4)
    elseif (EMBREE_ISA_SUPPORTS_AVX AND
            NOT OSPRAY_ISPC_TARGET_LIST STREQUAL "avx")
      list(APPEND OSPRAY_ISPC_TARGET_LIST avx)
    elseif (EMBREE_ISA_SUPPORTS_AVX2 AND
            NOT OSPRAY_ISPC_TARGET_LIST STREQUAL "avx2")
      list(APPEND OSPRAY_ISPC_TARGET_LIST avx2)
    elseif (EMBREE_ISA_SUPPORTS_AVX512KNL AND
            NOT OSPRAY_ISPC_TARGET_LIST STREQUAL "avx512knl-i32x16")
      list(APPEND OSPRAY_ISPC_TARGET_LIST avx512knl-i32x16)
    elseif (EMBREE_ISA_SUPPORTS_AVX512SKX AND
            NOT OSPRAY_ISPC_TARGET_LIST STREQUAL "avx512skx-i32x16")
      list(APPEND OSPRAY_ISPC_TARGET_LIST avx512skx-i32x16)
    endif()
  endif()
endmacro()

## Macro configure ISA targets for ispc ##
macro(ospray_configure_ispc_isa)

  set(OSPRAY_BUILD_ISA "ALL" CACHE STRING
      "Target ISA (SSE4, AVX, AVX2, AVX512KNL, AVX512SKX, or ALL)")
  string(TOUPPER ${OSPRAY_BUILD_ISA} OSPRAY_BUILD_ISA)

  if(EMBREE_ISA_SUPPORTS_SSE4)
    set(OSPRAY_SUPPORTED_ISAS ${OSPRAY_SUPPORTED_ISAS} SSE4)
  endif()
  if(EMBREE_ISA_SUPPORTS_AVX)
    set(OSPRAY_SUPPORTED_ISAS ${OSPRAY_SUPPORTED_ISAS} AVX)
  endif()
  if(EMBREE_ISA_SUPPORTS_AVX2)
    set(OSPRAY_SUPPORTED_ISAS ${OSPRAY_SUPPORTED_ISAS} AVX2)
  endif()
  if(EMBREE_ISA_SUPPORTS_AVX512KNL)
    set(OSPRAY_SUPPORTED_ISAS ${OSPRAY_SUPPORTED_ISAS} AVX512KNL)
  endif()
  if(EMBREE_ISA_SUPPORTS_AVX512SKX)
    set(OSPRAY_SUPPORTED_ISAS ${OSPRAY_SUPPORTED_ISAS} AVX512SKX)
  endif()

  set_property(CACHE OSPRAY_BUILD_ISA PROPERTY STRINGS
               ALL ${OSPRAY_SUPPORTED_ISAS})

  unset(OSPRAY_ISPC_TARGET_LIST)
  if (OSPRAY_BUILD_ISA STREQUAL "ALL")

    if(EMBREE_ISA_SUPPORTS_SSE4)
      set(OSPRAY_ISPC_TARGET_LIST ${OSPRAY_ISPC_TARGET_LIST} sse4)
      message(STATUS "OSPRay SSE4 ISA target enabled.")
    endif()
    if(EMBREE_ISA_SUPPORTS_AVX)
      set(OSPRAY_ISPC_TARGET_LIST ${OSPRAY_ISPC_TARGET_LIST} avx)
      message(STATUS "OSPRay AVX ISA target enabled.")
    endif()
    if(EMBREE_ISA_SUPPORTS_AVX2)
      set(OSPRAY_ISPC_TARGET_LIST ${OSPRAY_ISPC_TARGET_LIST} avx2)
      message(STATUS "OSPRay AVX2 ISA target enabled.")
    endif()
    if(EMBREE_ISA_SUPPORTS_AVX512KNL)
      set(OSPRAY_ISPC_TARGET_LIST ${OSPRAY_ISPC_TARGET_LIST} avx512knl-i32x16)
      message(STATUS "OSPRay AVX512KNL ISA target enabled.")
    endif()
    if(EMBREE_ISA_SUPPORTS_AVX512SKX)
      set(OSPRAY_ISPC_TARGET_LIST ${OSPRAY_ISPC_TARGET_LIST} avx512skx-i32x16)
      message(STATUS "OSPRay AVX512SKX ISA target enabled.")
    endif()

  elseif (OSPRAY_BUILD_ISA STREQUAL "AVX512SKX")

    if(NOT EMBREE_ISA_SUPPORTS_AVX512SKX)
      message(FATAL_ERROR "Your Embree build does not support AVX512SKX!")
    endif()
    set(OSPRAY_ISPC_TARGET_LIST avx512skx-i32x16)

  elseif (OSPRAY_BUILD_ISA STREQUAL "AVX512KNL")

    if(NOT EMBREE_ISA_SUPPORTS_AVX512KNL)
      message(FATAL_ERROR "Your Embree build does not support AVX512KNL!")
    endif()
    set(OSPRAY_ISPC_TARGET_LIST avx512knl-i32x16)

  elseif (OSPRAY_BUILD_ISA STREQUAL "AVX2")

    if(NOT EMBREE_ISA_SUPPORTS_AVX2)
      message(FATAL_ERROR "Your Embree build does not support AVX2!")
    endif()
    set(OSPRAY_ISPC_TARGET_LIST avx2)

  elseif (OSPRAY_BUILD_ISA STREQUAL "AVX")

    if(NOT EMBREE_ISA_SUPPORTS_AVX)
      message(FATAL_ERROR "Your Embree build does not support AVX!")
    endif()
    set(OSPRAY_ISPC_TARGET_LIST avx)

  elseif (OSPRAY_BUILD_ISA STREQUAL "SSE4")

    if(NOT EMBREE_ISA_SUPPORTS_SSE4)
      message(FATAL_ERROR "Your Embree build does not support SSE4!")
    endif()
    set(OSPRAY_ISPC_TARGET_LIST sse4)

  else()
    message(ERROR "Invalid OSPRAY_BUILD_ISA value. "
                  "Please select one of ${OSPRAY_SUPPORTED_ISAS}, or ALL.")
  endif()

  ospray_fix_ispc_target_list()
endmacro()

## Target creation macros ##

macro(ospray_install_library name component)
  install(TARGETS ${name}
    EXPORT ospray_Exports
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
      COMPONENT ${component}
      NAMELINK_SKIP
    # on Windows put the dlls into bin
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
      COMPONENT ${component}
    # ... and the import lib into the devel package
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
      COMPONENT devel
  )

  install(EXPORT ospray_Exports
    DESTINATION ${OSPRAY_CMAKECONFIG_DIR}
    NAMESPACE ospray::
    COMPONENT devel
  )

  # Install the namelink in the devel component. This command also includes the
  # RUNTIME and ARCHIVE components a second time to prevent an "install TARGETS
  # given no ARCHIVE DESTINATION for static library target" error. Installing
  # these components twice doesn't hurt anything.
  install(TARGETS ${name}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
      COMPONENT devel
      NAMELINK_ONLY
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
      COMPONENT ${component}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
      COMPONENT devel
  )
endmacro()

## Compiler configuration macros ##

macro(ospray_configure_compiler)
  if (WIN32)
    set(OSPRAY_PLATFORM_WIN  1)
    set(OSPRAY_PLATFORM_UNIX 0)
  else()
    set(OSPRAY_PLATFORM_WIN  0)
    set(OSPRAY_PLATFORM_UNIX 1)
  endif()

  # unhide compiler to make it easier for users to see what they are using
  mark_as_advanced(CLEAR CMAKE_CXX_COMPILER)

  option(OSPRAY_STRICT_BUILD "Build with additional warning flags" ON)
  mark_as_advanced(OSPRAY_STRICT_BUILD)

  option(OSPRAY_WARN_AS_ERRORS "Treat warnings as errors" OFF)
  mark_as_advanced(OSPRAY_WARN_AS_ERRORS)

  set(OSPRAY_COMPILER_ICC   FALSE)
  set(OSPRAY_COMPILER_GCC   FALSE)
  set(OSPRAY_COMPILER_CLANG FALSE)
  set(OSPRAY_COMPILER_MSVC  FALSE)

  if ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Intel")
    set(OSPRAY_COMPILER_ICC TRUE)
    if(WIN32) # icc on Windows behaves like msvc
      include(msvc)
    else()
      include(icc)
    endif()
  elseif ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU")
    set(OSPRAY_COMPILER_GCC TRUE)
    include(gcc)
  elseif ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang" OR
          "${CMAKE_CXX_COMPILER_ID}" STREQUAL "AppleClang")
    set(OSPRAY_COMPILER_CLANG TRUE)
    include(clang)
  elseif ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "MSVC")
    set(OSPRAY_COMPILER_MSVC TRUE)
    include(msvc)
  else()
    message(FATAL_ERROR
            "Unsupported compiler specified: '${CMAKE_CXX_COMPILER_ID}'")
  endif()

  set(CMAKE_CXX_FLAGS_DEBUG "-DDEBUG ${CMAKE_CXX_FLAGS_DEBUG}")

  if (WIN32)
    # increase stack to 8MB (the default size of 1MB is too small for our apps)
    # note: linker options are independent of compiler (icc or MSVC)
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} /STACK:8388608")
  endif()
endmacro()

macro(ospray_disable_compiler_warnings)
  if (NOT OSPRAY_COMPILER_MSVC)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -w")
  endif()
endmacro()

## Embree functions/macros ##

function(ospray_check_embree_feature FEATURE DESCRIPTION)
  set(FEATURE EMBREE_${FEATURE})
  if(NOT ${ARGN})
    if (${FEATURE})
      message(FATAL_ERROR "OSPRay requires Embree to be compiled "
              "without ${DESCRIPTION} (${FEATURE}=OFF).")
    endif()
  else()
    if (NOT ${FEATURE})
      message(FATAL_ERROR "OSPRay requires Embree to be compiled "
              "with support for ${DESCRIPTION} (${FEATURE}=ON).")
    endif()
  endif()
endfunction()

function(ospray_verify_embree_features)
  ospray_check_embree_feature(ISPC_SUPPORT ISPC)
  ospray_check_embree_feature(FILTER_FUNCTION "intersection filter")
  ospray_check_embree_feature(GEOMETRY_TRIANGLE "triangle geometries")
  ospray_check_embree_feature(GEOMETRY_CURVE "spline curve geometries")
  ospray_check_embree_feature(GEOMETRY_USER "user geometries")
  ospray_check_embree_feature(RAY_PACKETS "ray packets")
  ospray_check_embree_feature(BACKFACE_CULLING "backface culling" OFF)
endfunction()

macro(ospray_create_embree_target)
  if (NOT TARGET embree)
    add_library(embree INTERFACE) # NOTE(jda) - Cannot be IMPORTED due to CMake
                                  #             issues found on Ubuntu.

    target_include_directories(embree
    INTERFACE
      $<BUILD_INTERFACE:${EMBREE_INCLUDE_DIRS}>
    )

    target_link_libraries(embree
    INTERFACE
      $<BUILD_INTERFACE:${EMBREE_LIBRARIES}>
    )
  endif()
endmacro()

macro(ospray_find_embree EMBREE_VERSION_REQUIRED)
  find_dependency(embree ${EMBREE_VERSION_REQUIRED})
  if(NOT DEFINED EMBREE_INCLUDE_DIRS)
    message(FATAL_ERROR
            "We did not find Embree installed on your system. OSPRay requires"
            " an Embree installation >= v${EMBREE_VERSION_REQUIRED}, please"
            " download and extract Embree (or compile Embree from source), then"
            " set the 'embree_DIR' variable to the installation (or build)"
            " directory.")
  else()
    message(STATUS "Found Embree v${EMBREE_VERSION}: ${EMBREE_LIBRARY}")
  endif()

  if (EMBREE_STATIC_LIB)
    # use import target to include full static lib chain
    set(EMBREE_LIBRARY embree)
  endif()
  set(EMBREE_LIBRARIES ${EMBREE_LIBRARY})

  if ("${EMBREE_VERSION}" STREQUAL "3.6.0")
    message(FATAL_ERROR "Embree v3.6.0 is incompatible with OSPRay.")
  endif()
endmacro()

macro(ospray_determine_embree_isa_support)
  if (EMBREE_MAX_ISA STREQUAL "DEFAULT" OR
      EMBREE_MAX_ISA STREQUAL "NONE")
    set(EMBREE_ISA_SUPPORTS_SSE2      ${EMBREE_ISA_SSE2})
    set(EMBREE_ISA_SUPPORTS_SSE4      ${EMBREE_ISA_SSE42})
    set(EMBREE_ISA_SUPPORTS_AVX       ${EMBREE_ISA_AVX})
    set(EMBREE_ISA_SUPPORTS_AVX2      ${EMBREE_ISA_AVX2})
    set(EMBREE_ISA_SUPPORTS_AVX512KNL ${EMBREE_ISA_AVX512KNL})
    set(EMBREE_ISA_SUPPORTS_AVX512SKX ${EMBREE_ISA_AVX512SKX})
  else()
    set(EMBREE_ISA_SUPPORTS_SSE2      FALSE)
    set(EMBREE_ISA_SUPPORTS_SSE4      FALSE)
    set(EMBREE_ISA_SUPPORTS_AVX       FALSE)
    set(EMBREE_ISA_SUPPORTS_AVX2      FALSE)
    set(EMBREE_ISA_SUPPORTS_AVX512KNL FALSE)
    set(EMBREE_ISA_SUPPORTS_AVX512SKX FALSE)

    if (EMBREE_MAX_ISA STREQUAL "SSE2")
      set(EMBREE_ISA_SUPPORTS_SSE2 TRUE)
    elseif (EMBREE_MAX_ISA MATCHES "SSE4\\.[12]$")
      set(EMBREE_ISA_SUPPORTS_SSE2 TRUE)
      set(EMBREE_ISA_SUPPORTS_SSE4 TRUE)
    elseif (EMBREE_MAX_ISA STREQUAL "AVX")
      set(EMBREE_ISA_SUPPORTS_SSE2 TRUE)
      set(EMBREE_ISA_SUPPORTS_SSE4 TRUE)
      set(EMBREE_ISA_SUPPORTS_AVX  TRUE)
    elseif (EMBREE_MAX_ISA STREQUAL "AVX2")
      set(EMBREE_ISA_SUPPORTS_SSE2 TRUE)
      set(EMBREE_ISA_SUPPORTS_SSE4 TRUE)
      set(EMBREE_ISA_SUPPORTS_AVX  TRUE)
      set(EMBREE_ISA_SUPPORTS_AVX2 TRUE)
    elseif (EMBREE_MAX_ISA STREQUAL "AVX512KNL")
      set(EMBREE_ISA_SUPPORTS_SSE2      TRUE)
      set(EMBREE_ISA_SUPPORTS_SSE4      TRUE)
      set(EMBREE_ISA_SUPPORTS_AVX       TRUE)
      set(EMBREE_ISA_SUPPORTS_AVX2      TRUE)
      set(EMBREE_ISA_SUPPORTS_AVX512KNL TRUE)
    elseif (EMBREE_MAX_ISA STREQUAL "AVX512SKX")
      set(EMBREE_ISA_SUPPORTS_SSE2      TRUE)
      set(EMBREE_ISA_SUPPORTS_SSE4      TRUE)
      set(EMBREE_ISA_SUPPORTS_AVX       TRUE)
      set(EMBREE_ISA_SUPPORTS_AVX2      TRUE)
      set(EMBREE_ISA_SUPPORTS_AVX512KNL TRUE)
      set(EMBREE_ISA_SUPPORTS_AVX512SKX TRUE)
    endif()
  endif()

  if (NOT (EMBREE_ISA_SUPPORTS_SSE4
           OR EMBREE_ISA_SUPPORTS_AVX
           OR EMBREE_ISA_SUPPORTS_AVX2
           OR EMBREE_ISA_SUPPORTS_AVX512KNL
           OR EMBREE_ISA_SUPPORTS_AVX512SKX))
      message(FATAL_ERROR
              "Your Embree build needs to support at least one ISA >= SSE4.1!")
  endif()
endmacro()
