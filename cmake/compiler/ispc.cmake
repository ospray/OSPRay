## Copyright 2009-2021 Intel Corporation
## SPDX-License-Identifier: Apache-2.0

# ISPC versions to look for, in decending order (newest first)
set(ISPC_VERSION_WORKING "1.15.0" "1.14.1")
list(GET ISPC_VERSION_WORKING -1 ISPC_VERSION_REQUIRED)

if (NOT ISPC_EXECUTABLE)
  # try sibling folder as hint for path of ISPC
  if (APPLE)
    set(ISPC_DIR_SUFFIX "osx" "Darwin")
  elseif(WIN32)
    set(ISPC_DIR_SUFFIX "windows" "win32")
    if (MSVC_VERSION LESS 1900)
      message(WARNING "MSVC 12 2013 is not supported anymore.")
    else()
      list(APPEND ISPC_DIR_SUFFIX "windows-vs2015")
    endif()
  else()
    set(ISPC_DIR_SUFFIX "linux" "Linux")
  endif()
  foreach(v "" "v")
   foreach(ver ${ISPC_VERSION_WORKING})
    foreach(suffix ${ISPC_DIR_SUFFIX})
     foreach(d "" "/bin")
      list(APPEND ISPC_DIR_HINT ${PROJECT_SOURCE_DIR}/../ispc-${v}${ver}-${suffix}${d})
     endforeach()
    endforeach()
   endforeach()
  endforeach()

  find_program(ISPC_EXECUTABLE ispc HINTS ${ISPC_DIR_HINT} DOC "Path to the ISPC executable.")
  if (NOT ISPC_EXECUTABLE)
    message("********************************************")
    message("Could not find ISPC (looked in PATH and ${ISPC_DIR_HINT})")
    message("")
    message("This version of OSPRay expects you to have a binary install of ISPC minimum version ${ISPC_VERSION_REQUIRED}, and expects it to be found in 'PATH' or in the sibling directory to where the OSPRay source are located. Please go to https://ispc.github.io/downloads.html, select the binary release for your particular platform, and unpack it to ${PROJECT_SOURCE_DIR}/../")
    message("")
    message("If you insist on using your own custom install of ISPC, please make sure that the 'ISPC_EXECUTABLE' variable is properly set in CMake.")
    message("********************************************")
    message(FATAL_ERROR "Could not find ISPC. Exiting.")
  else()
    message(STATUS "Found Intel Implicit SPMD Program Compiler (ISPC): ${ISPC_EXECUTABLE}")
  endif()
endif()

if(NOT ISPC_VERSION)
  execute_process(COMMAND ${ISPC_EXECUTABLE} --version OUTPUT_VARIABLE ISPC_OUTPUT)
  string(REGEX MATCH " ([0-9]+[.][0-9]+[.][0-9]+)(dev|knl|rc[0-9])? " DUMMY "${ISPC_OUTPUT}")
  set(ISPC_VERSION ${CMAKE_MATCH_1})

  if (ISPC_VERSION VERSION_LESS ISPC_VERSION_REQUIRED)
    message(FATAL_ERROR "Need at least version ${ISPC_VERSION_REQUIRED} of Intel Implicit SPMD Compiler (ISPC).")
  endif()

  set(ISPC_VERSION ${ISPC_VERSION} CACHE STRING "ISPC Version")
  mark_as_advanced(ISPC_VERSION)
  mark_as_advanced(ISPC_EXECUTABLE)
endif()

message(STATUS "Found ISPC v${ISPC_VERSION}: ${ISPC_EXECUTABLE}")
list(FIND ISPC_VERSION_WORKING ${ISPC_VERSION} ISPC_VERSION_TESTED)
if (ISPC_VERSION_TESTED EQUAL -1)
  message(WARNING "Using untested version ${ISPC_VERSION} of Intel Implicit SPMD Compiler (ISPC), proceed at own risk. Supported versions are ${ISPC_VERSION_WORKING}.")
endif()

set(OSPRAY_ISPC_ADDRESSING 32 CACHE STRING "32 vs 64 bit addressing in ispc")
set_property(CACHE OSPRAY_ISPC_ADDRESSING PROPERTY STRINGS 32 64)
mark_as_advanced(OSPRAY_ISPC_ADDRESSING)

if (NOT (OSPRAY_ISPC_ADDRESSING STREQUAL "32" OR
         OSPRAY_ISPC_ADDRESSING STREQUAL "64"))
  message(FATAL_ERROR "OSPRAY_ISPC_ADDRESSSING must be set to either '32' or '64'!")
endif()

get_filename_component(ISPC_DIR ${ISPC_EXECUTABLE} PATH)

# ##################################################################
# Macro to specify global-scope ISPC include directories
# ##################################################################

set(ISPC_INCLUDE_DIR "")
macro (ispc_include_directories)
  set(ISPC_INCLUDE_DIR ${ISPC_INCLUDE_DIR} ${ARGN})
endmacro ()

# ##################################################################
# Macro to specify global-scope ISPC definitions
# ##################################################################

set(ISPC_DEFINITIONS "")
macro (ispc_add_definitions)
  set(ISPC_DEFINITIONS ${ISPC_DEFINITIONS} ${ARGN})
endmacro ()

# ##################################################################
# Macro to compile ISPC source into an object file for linking
# ##################################################################

macro (ispc_compile)
  set(ISPC_ADDITIONAL_ARGS "")
  if (OSPRAY_STRICT_BUILD)
    list(APPEND ISPC_ADDITIONAL_ARGS --wno-perf)
  else()
    list(APPEND ISPC_ADDITIONAL_ARGS --woff)
  endif()

  set(ISPC_TARGETS ${OSPRAY_ISPC_TARGET_LIST})

  set(ISPC_TARGET_EXT ${CMAKE_CXX_OUTPUT_EXTENSION})
  string(REPLACE ";" "," ISPC_TARGET_ARGS "${ISPC_TARGETS}")

  if (CMAKE_SIZEOF_VOID_P EQUAL 8)
    set(ISPC_ARCHITECTURE "x86-64")
  else()
    set(ISPC_ARCHITECTURE "x86")
  endif()

  set(ISPC_TARGET_DIR ${CMAKE_CURRENT_BINARY_DIR})
  include_directories(${CMAKE_CURRENT_BINARY_DIR})

  if(ISPC_INCLUDE_DIR)
    string(REPLACE ";" ";-I;" ISPC_INCLUDE_DIR_PARMS "${ISPC_INCLUDE_DIR}")
    set(ISPC_INCLUDE_DIR_PARMS "-I" ${ISPC_INCLUDE_DIR_PARMS})
  endif()

  #CAUTION: -O0/1 -g with ispc seg faults
  set(ISPC_FLAGS_DEBUG "-g" CACHE STRING "ISPC Debug flags")
  mark_as_advanced(ISPC_FLAGS_DEBUG)
  set(ISPC_FLAGS_RELEASE "-O3" CACHE STRING "ISPC Release flags")
  mark_as_advanced(ISPC_FLAGS_RELEASE)
  set(ISPC_FLAGS_RELWITHDEBINFO "-O2 -g" CACHE STRING "ISPC Release with Debug symbols flags")
  mark_as_advanced(ISPC_FLAGS_RELWITHDEBINFO)
  set(ISPC_OPT_FLAGS
    $<IF:$<CONFIG:Debug>,${ISPC_FLAGS_DEBUG},
    $<IF:$<CONFIG:Release>,${ISPC_FLAGS_RELEASE},
    ${ISPC_FLAGS_RELWITHDEBINFO}>>
  )
  string(REPLACE ";" "" ISPC_OPT_FLAGS "${ISPC_OPT_FLAGS}")
  string(REPLACE " " "$<SEMICOLON>" ISPC_OPT_FLAGS "${ISPC_OPT_FLAGS}")

  if (NOT WIN32)
    list(APPEND ISPC_ADDITIONAL_ARGS --pic)
  endif()

  if (NOT OSPRAY_DEBUG_BUILD)
    list(APPEND ISPC_ADDITIONAL_ARGS --opt=disable-assertions)
  endif()

  foreach(src ${ARGN})
    get_filename_component(fname ${src} NAME_WE)
    get_filename_component(dir ${src} PATH)

    set(input ${src})
    if ("${dir}" MATCHES "^/") # absolute unix-style path to input
      set(outdir "${ISPC_TARGET_DIR}/rebased${dir}")
    elseif ("${dir}" MATCHES "^[A-Z]:") # absolute DOS-style path to input
      string(REGEX REPLACE "^[A-Z]:" "${ISPC_TARGET_DIR}/rebased/" outdir "${dir}")
    else() # relative path to input
      set(outdir "${ISPC_TARGET_DIR}/local_${OSPRAY_ISPC_TARGET_NAME}_${dir}")
      set(input ${CMAKE_CURRENT_SOURCE_DIR}/${src})
    endif()

    set(deps "")
    if (EXISTS ${outdir}/${fname}.dev.idep)
      file(READ ${outdir}/${fname}.dev.idep contents)
      string(REPLACE " " ";"     contents "${contents}")
      string(REPLACE ";" "\\\\;" contents "${contents}")
      string(REPLACE "\n" ";"    contents "${contents}")
      foreach(dep ${contents})
        if (EXISTS ${dep})
          set(deps ${deps} ${dep})
        endif (EXISTS ${dep})
      endforeach(dep ${contents})
    endif ()

    set(results "${outdir}/${fname}.dev${ISPC_TARGET_EXT}")
    # if we have multiple targets add additional object files
    list(LENGTH ISPC_TARGETS NUM_TARGETS)
    if (NUM_TARGETS GREATER 1)
      foreach(target ${ISPC_TARGETS})
        string(REPLACE "-i32x16" "" target ${target}) # strip avx512(knl|skx)-i32x16
        set(results ${results} "${outdir}/${fname}.dev_${target}${ISPC_TARGET_EXT}")
      endforeach()
    endif()

    add_custom_command(
      OUTPUT ${results} ${ISPC_TARGET_DIR}/${dir}/${fname}_ispc.h
      COMMAND ${CMAKE_COMMAND} -E make_directory ${outdir}
      COMMAND ${CMAKE_COMMAND} -E make_directory ${ISPC_TARGET_DIR}/${dir}/
      COMMAND ${ISPC_EXECUTABLE}
      ${ISPC_DEFINITIONS}
      -I ${CMAKE_CURRENT_SOURCE_DIR}
      ${ISPC_INCLUDE_DIR_PARMS}
      --arch=${ISPC_ARCHITECTURE}
      --addressing=${OSPRAY_ISPC_ADDRESSING}
      ${ISPC_OPT_FLAGS}
      --target=${ISPC_TARGET_ARGS}
      --opt=fast-math
      ${ISPC_ADDITIONAL_ARGS}
      -h ${ISPC_TARGET_DIR}/${dir}/${fname}_ispc.h
      -MMM  ${outdir}/${fname}.dev.idep
      -o ${outdir}/${fname}.dev${ISPC_TARGET_EXT}
      ${input}
      DEPENDS ${input} ${deps}
      COMMENT "Building ISPC object ${outdir}/${fname}.dev${ISPC_TARGET_EXT}"
      COMMAND_EXPAND_LISTS
    )

    list(APPEND ISPC_OBJECTS ${results})
  endforeach()
endmacro()

# ##################################################################
# Macro to add both C/C++ and ISPC sources to a given target
# ##################################################################

function(ispc_target_add_sources name)
  ## Split-out C/C++ from ISPC files ##

  set(ISPC_SOURCES "")
  set(OTHER_SOURCES "")

  foreach(src ${ARGN})
    get_filename_component(ext ${src} EXT)
    if (ext STREQUAL ".ispc")
      set(ISPC_SOURCES ${ISPC_SOURCES} ${src})
    else()
      set(OTHER_SOURCES ${OTHER_SOURCES} ${src})
    endif()
  endforeach()

  ## Get existing target definitions and include dirs ##

  # NOTE(jda) - This needs work: BUILD_INTERFACE vs. INSTALL_INTERFACE isn't
  #             handled automatically.

  #get_property(TARGET_DEFINITIONS TARGET ${name} PROPERTY COMPILE_DEFINITIONS)
  #get_property(TARGET_INCLUDES TARGET ${name} PROPERTY INCLUDE_DIRECTORIES)

  #set(ISPC_DEFINITIONS ${TARGET_DEFINITIONS})
  #set(ISPC_INCLUDE_DIR ${TARGET_INCLUDES})

  ## Compile ISPC files ##

  ispc_compile(${ISPC_SOURCES})

  ## Set final sources on target ##

  get_property(TARGET_SOURCES TARGET ${name} PROPERTY SOURCES)
  list(APPEND TARGET_SOURCES ${ISPC_OBJECTS} ${OTHER_SOURCES})
  set_target_properties(${name} PROPERTIES SOURCES "${TARGET_SOURCES}")
endfunction()
