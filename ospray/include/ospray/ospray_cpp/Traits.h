// Copyright 2009-2021 Intel Corporation
// SPDX-License-Identifier: Apache-2.0

#pragma once

// ospray
#include "ospray/ospray.h"

namespace ospray {

// Infer (compile time) OSP_DATA_TYPE from input type /////////////////////////

template <typename T>
struct OSPTypeFor
{
  static constexpr OSPDataType value = OSP_UNKNOWN;
};

#define OSPTYPEFOR_SPECIALIZATION(type, osp_type)                              \
  template <>                                                                  \
  struct OSPTypeFor<type>                                                      \
  {                                                                            \
    static constexpr OSPDataType value = osp_type;                             \
  };

OSPTYPEFOR_SPECIALIZATION(void *, OSP_VOID_PTR);
OSPTYPEFOR_SPECIALIZATION(char *, OSP_STRING);
OSPTYPEFOR_SPECIALIZATION(const char *, OSP_STRING);
OSPTYPEFOR_SPECIALIZATION(const char[], OSP_STRING);
OSPTYPEFOR_SPECIALIZATION(bool, OSP_BOOL);
OSPTYPEFOR_SPECIALIZATION(char, OSP_CHAR);
OSPTYPEFOR_SPECIALIZATION(unsigned char, OSP_UCHAR);
OSPTYPEFOR_SPECIALIZATION(short, OSP_SHORT);
OSPTYPEFOR_SPECIALIZATION(unsigned short, OSP_USHORT);
OSPTYPEFOR_SPECIALIZATION(int, OSP_INT);
OSPTYPEFOR_SPECIALIZATION(unsigned int, OSP_UINT);
OSPTYPEFOR_SPECIALIZATION(long, OSP_LONG);
OSPTYPEFOR_SPECIALIZATION(unsigned long, OSP_ULONG);
OSPTYPEFOR_SPECIALIZATION(long long, OSP_LONG);
OSPTYPEFOR_SPECIALIZATION(unsigned long long, OSP_ULONG);
OSPTYPEFOR_SPECIALIZATION(float, OSP_FLOAT);
OSPTYPEFOR_SPECIALIZATION(double, OSP_DOUBLE);

OSPTYPEFOR_SPECIALIZATION(OSPObject, OSP_OBJECT);
OSPTYPEFOR_SPECIALIZATION(OSPCamera, OSP_CAMERA);
OSPTYPEFOR_SPECIALIZATION(OSPData, OSP_DATA);
OSPTYPEFOR_SPECIALIZATION(OSPFrameBuffer, OSP_FRAMEBUFFER);
OSPTYPEFOR_SPECIALIZATION(OSPFuture, OSP_FUTURE);
OSPTYPEFOR_SPECIALIZATION(OSPGeometricModel, OSP_GEOMETRIC_MODEL);
OSPTYPEFOR_SPECIALIZATION(OSPGeometry, OSP_GEOMETRY);
OSPTYPEFOR_SPECIALIZATION(OSPGroup, OSP_GROUP);
OSPTYPEFOR_SPECIALIZATION(OSPImageOperation, OSP_IMAGE_OPERATION);
OSPTYPEFOR_SPECIALIZATION(OSPInstance, OSP_INSTANCE);
OSPTYPEFOR_SPECIALIZATION(OSPLight, OSP_LIGHT);
OSPTYPEFOR_SPECIALIZATION(OSPMaterial, OSP_MATERIAL);
OSPTYPEFOR_SPECIALIZATION(OSPRenderer, OSP_RENDERER);
OSPTYPEFOR_SPECIALIZATION(OSPTexture, OSP_TEXTURE);
OSPTYPEFOR_SPECIALIZATION(OSPTransferFunction, OSP_TRANSFER_FUNCTION);
OSPTYPEFOR_SPECIALIZATION(OSPVolume, OSP_VOLUME);
OSPTYPEFOR_SPECIALIZATION(OSPVolumetricModel, OSP_VOLUMETRIC_MODEL);
OSPTYPEFOR_SPECIALIZATION(OSPWorld, OSP_WORLD);

OSPTYPEFOR_SPECIALIZATION(OSPLogLevel, OSP_INT);
OSPTYPEFOR_SPECIALIZATION(OSPDeviceProperty, OSP_INT);
OSPTYPEFOR_SPECIALIZATION(OSPDataType, OSP_INT);
OSPTYPEFOR_SPECIALIZATION(OSPTextureFormat, OSP_INT);
OSPTYPEFOR_SPECIALIZATION(OSPTextureFilter, OSP_INT);
OSPTYPEFOR_SPECIALIZATION(OSPError, OSP_INT);
OSPTYPEFOR_SPECIALIZATION(OSPFrameBufferFormat, OSP_INT);
OSPTYPEFOR_SPECIALIZATION(OSPFrameBufferChannel, OSP_INT);
OSPTYPEFOR_SPECIALIZATION(OSPSyncEvent, OSP_INT);
OSPTYPEFOR_SPECIALIZATION(OSPUnstructuredCellType, OSP_UCHAR);
OSPTYPEFOR_SPECIALIZATION(OSPStereoMode, OSP_UCHAR);
OSPTYPEFOR_SPECIALIZATION(OSPCurveType, OSP_UCHAR);
OSPTYPEFOR_SPECIALIZATION(OSPCurveBasis, OSP_UCHAR);
OSPTYPEFOR_SPECIALIZATION(OSPAMRMethod, OSP_UCHAR);
OSPTYPEFOR_SPECIALIZATION(OSPSubdivisionMode, OSP_UCHAR);
OSPTYPEFOR_SPECIALIZATION(OSPPixelFilterTypes, OSP_UCHAR);
OSPTYPEFOR_SPECIALIZATION(OSPIntensityQuantity, OSP_UCHAR);

#define OSPTYPEFOR_DEFINITION(type)                                            \
  constexpr OSPDataType OSPTypeFor<type>::value

// Infer element type from OSP_* vec types input type /////////////////////////

template <OSPDataType TYPE>
struct OSPVecElementOf
{
  using type = void;
};

#define OSPVECELEMENTOF_SPECIALIZATION(osp_type, out_type)                     \
  template <>                                                                  \
  struct OSPVecElementOf<osp_type>                                             \
  {                                                                            \
    using type = out_type;                                                     \
  };

OSPVECELEMENTOF_SPECIALIZATION(OSP_UCHAR, unsigned char);
OSPVECELEMENTOF_SPECIALIZATION(OSP_INT, int32_t);
OSPVECELEMENTOF_SPECIALIZATION(OSP_UINT, uint32_t);
OSPVECELEMENTOF_SPECIALIZATION(OSP_LONG, int64_t);
OSPVECELEMENTOF_SPECIALIZATION(OSP_ULONG, uint64_t);
OSPVECELEMENTOF_SPECIALIZATION(OSP_FLOAT, float);
OSPVECELEMENTOF_SPECIALIZATION(OSP_VEC2UC, unsigned char);
OSPVECELEMENTOF_SPECIALIZATION(OSP_VEC3UC, unsigned char);
OSPVECELEMENTOF_SPECIALIZATION(OSP_VEC4UC, unsigned char);
OSPVECELEMENTOF_SPECIALIZATION(OSP_VEC2C, char);
OSPVECELEMENTOF_SPECIALIZATION(OSP_VEC3C, char);
OSPVECELEMENTOF_SPECIALIZATION(OSP_VEC4C, char);
OSPVECELEMENTOF_SPECIALIZATION(OSP_VEC2S, short);
OSPVECELEMENTOF_SPECIALIZATION(OSP_VEC3S, short);
OSPVECELEMENTOF_SPECIALIZATION(OSP_VEC4S, short);
OSPVECELEMENTOF_SPECIALIZATION(OSP_VEC2US, unsigned short);
OSPVECELEMENTOF_SPECIALIZATION(OSP_VEC3US, unsigned short);
OSPVECELEMENTOF_SPECIALIZATION(OSP_VEC4US, unsigned short);
OSPVECELEMENTOF_SPECIALIZATION(OSP_VEC2I, int32_t);
OSPVECELEMENTOF_SPECIALIZATION(OSP_VEC3I, int32_t);
OSPVECELEMENTOF_SPECIALIZATION(OSP_VEC4I, int32_t);
OSPVECELEMENTOF_SPECIALIZATION(OSP_VEC2UI, uint32_t);
OSPVECELEMENTOF_SPECIALIZATION(OSP_VEC3UI, uint32_t);
OSPVECELEMENTOF_SPECIALIZATION(OSP_VEC4UI, uint32_t);
OSPVECELEMENTOF_SPECIALIZATION(OSP_VEC2L, int64_t);
OSPVECELEMENTOF_SPECIALIZATION(OSP_VEC3L, int64_t);
OSPVECELEMENTOF_SPECIALIZATION(OSP_VEC4L, int64_t);
OSPVECELEMENTOF_SPECIALIZATION(OSP_VEC2UL, uint64_t);
OSPVECELEMENTOF_SPECIALIZATION(OSP_VEC3UL, uint64_t);
OSPVECELEMENTOF_SPECIALIZATION(OSP_VEC4UL, uint64_t);
OSPVECELEMENTOF_SPECIALIZATION(OSP_VEC2F, float);
OSPVECELEMENTOF_SPECIALIZATION(OSP_VEC3F, float);
OSPVECELEMENTOF_SPECIALIZATION(OSP_VEC4F, float);
OSPVECELEMENTOF_SPECIALIZATION(OSP_VEC2D, double);
OSPVECELEMENTOF_SPECIALIZATION(OSP_VEC3D, double);
OSPVECELEMENTOF_SPECIALIZATION(OSP_VEC4D, double);
OSPVECELEMENTOF_SPECIALIZATION(OSP_BOX1I, int32_t);
OSPVECELEMENTOF_SPECIALIZATION(OSP_BOX2I, int32_t);
OSPVECELEMENTOF_SPECIALIZATION(OSP_BOX3I, int32_t);
OSPVECELEMENTOF_SPECIALIZATION(OSP_BOX4I, int32_t);
OSPVECELEMENTOF_SPECIALIZATION(OSP_BOX1F, float);
OSPVECELEMENTOF_SPECIALIZATION(OSP_BOX2F, float);
OSPVECELEMENTOF_SPECIALIZATION(OSP_BOX3F, float);
OSPVECELEMENTOF_SPECIALIZATION(OSP_BOX4F, float);

// Infer OSPDataType dimensionality ///////////////////////////////////////////

template <OSPDataType TYPE>
struct OSPDimensionalityOf
{
  static constexpr int value = 1;
};

#define OSPDIMENSIONALITYOF_SPECIALIZATION(osp_type, out_value)                \
  template <>                                                                  \
  struct OSPDimensionalityOf<osp_type>                                         \
  {                                                                            \
    static constexpr int value = out_value;                                    \
  };

OSPDIMENSIONALITYOF_SPECIALIZATION(OSP_VEC2UC, 2);
OSPDIMENSIONALITYOF_SPECIALIZATION(OSP_VEC3UC, 3);
OSPDIMENSIONALITYOF_SPECIALIZATION(OSP_VEC4UC, 4);
OSPDIMENSIONALITYOF_SPECIALIZATION(OSP_VEC2C, 2);
OSPDIMENSIONALITYOF_SPECIALIZATION(OSP_VEC3C, 3);
OSPDIMENSIONALITYOF_SPECIALIZATION(OSP_VEC4C, 4);
OSPDIMENSIONALITYOF_SPECIALIZATION(OSP_VEC2S, 2);
OSPDIMENSIONALITYOF_SPECIALIZATION(OSP_VEC3S, 3);
OSPDIMENSIONALITYOF_SPECIALIZATION(OSP_VEC4S, 4);
OSPDIMENSIONALITYOF_SPECIALIZATION(OSP_VEC2US, 2);
OSPDIMENSIONALITYOF_SPECIALIZATION(OSP_VEC3US, 3);
OSPDIMENSIONALITYOF_SPECIALIZATION(OSP_VEC4US, 4);
OSPDIMENSIONALITYOF_SPECIALIZATION(OSP_VEC2I, 2);
OSPDIMENSIONALITYOF_SPECIALIZATION(OSP_VEC3I, 3);
OSPDIMENSIONALITYOF_SPECIALIZATION(OSP_VEC4I, 4);
OSPDIMENSIONALITYOF_SPECIALIZATION(OSP_VEC2UI, 2);
OSPDIMENSIONALITYOF_SPECIALIZATION(OSP_VEC3UI, 3);
OSPDIMENSIONALITYOF_SPECIALIZATION(OSP_VEC4UI, 4);
OSPDIMENSIONALITYOF_SPECIALIZATION(OSP_VEC2L, 2);
OSPDIMENSIONALITYOF_SPECIALIZATION(OSP_VEC3L, 3);
OSPDIMENSIONALITYOF_SPECIALIZATION(OSP_VEC4L, 4);
OSPDIMENSIONALITYOF_SPECIALIZATION(OSP_VEC2UL, 2);
OSPDIMENSIONALITYOF_SPECIALIZATION(OSP_VEC3UL, 3);
OSPDIMENSIONALITYOF_SPECIALIZATION(OSP_VEC4UL, 4);
OSPDIMENSIONALITYOF_SPECIALIZATION(OSP_VEC2H, 2);
OSPDIMENSIONALITYOF_SPECIALIZATION(OSP_VEC3H, 3);
OSPDIMENSIONALITYOF_SPECIALIZATION(OSP_VEC4H, 4);
OSPDIMENSIONALITYOF_SPECIALIZATION(OSP_VEC2F, 2);
OSPDIMENSIONALITYOF_SPECIALIZATION(OSP_VEC3F, 3);
OSPDIMENSIONALITYOF_SPECIALIZATION(OSP_VEC4F, 4);
OSPDIMENSIONALITYOF_SPECIALIZATION(OSP_VEC2D, 2);
OSPDIMENSIONALITYOF_SPECIALIZATION(OSP_VEC3D, 3);
OSPDIMENSIONALITYOF_SPECIALIZATION(OSP_VEC4D, 4);
OSPDIMENSIONALITYOF_SPECIALIZATION(OSP_BOX1I, 1);
OSPDIMENSIONALITYOF_SPECIALIZATION(OSP_BOX2I, 2);
OSPDIMENSIONALITYOF_SPECIALIZATION(OSP_BOX3I, 3);
OSPDIMENSIONALITYOF_SPECIALIZATION(OSP_BOX4I, 4);
OSPDIMENSIONALITYOF_SPECIALIZATION(OSP_BOX1F, 1);
OSPDIMENSIONALITYOF_SPECIALIZATION(OSP_BOX2F, 2);
OSPDIMENSIONALITYOF_SPECIALIZATION(OSP_BOX3F, 3);
OSPDIMENSIONALITYOF_SPECIALIZATION(OSP_BOX4F, 4);

#define OSPDIMENSIONALITYOF_DEFINITION(type)                                   \
  constexpr int OSPDimensionalityOf<type>::value

} // namespace ospray
