// Copyright 2009-2020 Intel Corporation
// SPDX-License-Identifier: Apache-2.0

#pragma once

// ospray
#include "ospray/ospray_cpp.h"
// ospcommon
#include "ospcommon/memory/IntrusivePtr.h"
#include "ospcommon/utility/ParameterizedObject.h"

#include "ospray/ospray_testing/ospray_testing_export.h"

namespace ospray {
namespace testing {
namespace detail {

using namespace ospcommon;
using namespace ospcommon::math;

struct Builder : public memory::RefCountedObject,
                 public utility::ParameterizedObject
{
  virtual ~Builder() = default;

  virtual void commit();

  virtual cpp::Group buildGroup() const = 0;
  virtual cpp::World buildWorld() const;
  virtual cpp::World buildWorld(
      const std::vector<cpp::Instance> &instances) const;

 protected:
  cpp::TransferFunction makeTransferFunction(const vec2f &valueRange) const;

  cpp::GeometricModel makeGroundPlane(float planeExtent) const;

  // Data //

  std::string rendererType{"scivis"};
  std::string tfColorMap{"jet"};
  std::string tfOpacityMap{"linear"};

  bool addPlane{true};

  unsigned int randomSeed{0};
};

} // namespace detail
} // namespace testing
} // namespace ospray

#define OSP_REGISTER_TESTING_BUILDER(InternalClassName, Name)                  \
  extern "C" OSPRAY_TESTING_EXPORT ospray::testing::detail::Builder            \
      *ospray_create_testing_builder__##Name()                                 \
  {                                                                            \
    return new InternalClassName;                                              \
  }                                                                            \
  /* Extra declaration to avoid "extra ;" pedantic warnings */                 \
  ospray::testing::detail::Builder *ospray_create_testing_builder__##Name()
