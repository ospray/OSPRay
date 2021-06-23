## Copyright 2009-2021 Intel Corporation
## SPDX-License-Identifier: Apache-2.0

##############################################################
# Global configuration options
##############################################################

include(GNUInstallDirs)
include(CMakeDependentOption)

set(OSPRAY_CMAKECONFIG_DIR
    "${CMAKE_INSTALL_LIBDIR}/cmake/ospray-${OSPRAY_VERSION}")

set(RKCOMMON_VERSION_REQUIRED 1.6.1)
set(EMBREE_VERSION_REQUIRED 3.12.0)
set(OPENVKL_VERSION_REQUIRED 0.13.0)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR})
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR})
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR})

ospray_configure_compiler()

###########################################################
# OSPRay's dependencies
###########################################################

# rkcommon
find_package(rkcommon ${RKCOMMON_VERSION_REQUIRED} REQUIRED)
get_target_property(RKCOMMON_INCLUDE_DIRS rkcommon::rkcommon
  INTERFACE_INCLUDE_DIRECTORIES)

# Embree
ospray_find_embree(${EMBREE_VERSION_REQUIRED})
ospray_verify_embree_features()
ospray_determine_embree_isa_support()

# Open VKL
ospray_find_openvkl(${OPENVKL_VERSION_REQUIRED})

# OpenImageDenoise
if (OSPRAY_MODULE_DENOISER)
  find_package(OpenImageDenoise 1.2.3 REQUIRED)
endif()

###########################################################
# OSPRay specific build options and configuration selection
###########################################################

# Configure OSPRay ISA last after we've detected what we got w/ Embree
ospray_configure_ispc_isa()

option(OSPRAY_ENABLE_APPS "Enable the 'apps' subtree in the build." ON)
option(OSPRAY_ENABLE_MODULES "Enable the 'modules' subtree in the build." ON)
option(OSPRAY_ENABLE_TARGET_CLANGFORMAT
       "Enable 'format' target, requires clang-format too")
mark_as_advanced(OSPRAY_ENABLE_TARGET_CLANGFORMAT)

#####################################################################
# Binary package options, before any install() invocation/definition
#####################################################################

option(OSPRAY_ZIP_MODE "Use tarball/zip CPack generator instead of RPM" ON)
mark_as_advanced(OSPRAY_ZIP_MODE)

option(OSPRAY_INSTALL_DEPENDENCIES
       "Install OSPRay dependencies in binary packages and install")
mark_as_advanced(OSPRAY_INSTALL_DEPENDENCIES)
