// ======================================================================== //
// Copyright 2009-2019 Intel Corporation                                    //
//                                                                          //
// Licensed under the Apache License, Version 2.0 (the "License");          //
// you may not use this file except in compliance with the License.         //
// You may obtain a copy of the License at                                  //
//                                                                          //
//     http://www.apache.org/licenses/LICENSE-2.0                           //
//                                                                          //
// Unless required by applicable law or agreed to in writing, software      //
// distributed under the License is distributed on an "AS IS" BASIS,        //
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. //
// See the License for the specific language governing permissions and      //
// limitations under the License.                                           //
// ======================================================================== //

#include "common.h"
#include "sysinfo.h"
#include "library.h"

// std
#include <time.h>
#ifdef _WIN32
#  ifndef WIN32_LEAN_AND_MEAN
#    define WIN32_LEAN_AND_MEAN
#  endif
#  include <windows.h> // for GetSystemTime
#else
#  include <sys/time.h>
#  include <sys/times.h>
#  include <dlfcn.h>
#endif

namespace ospcommon {

  /*! return system time in seconds */
  double getSysTime() {
#ifdef _WIN32
    SYSTEMTIME tp; GetSystemTime(&tp);
    return double(tp.wSecond) + double(tp.wMilliseconds) / 1E3;
#else
    struct timeval tp; gettimeofday(&tp,nullptr);
    return double(tp.tv_sec) + double(tp.tv_usec)/1E6;
#endif
  }

  void removeArgs(int &ac, const char **&av, int where, int howMany)
  {
    for (int i=where+howMany;i<ac;i++)
      av[i-howMany] = av[i];
    ac -= howMany;
  }

  void doAssertion(const char *file, int line, const char *expr, const char *expl)
  {
    if (expl)
      fprintf(stderr,"%s:%i: Assertion failed: \"%s\":\nAdditional Info: %s\n",
              file, line, expr, expl);
    else
      fprintf(stderr,"%s:%i: Assertion failed: \"%s\".\n", file, line, expr);
    abort();
  }

  void loadLibrary(const std::string& name, bool anchor)
  {
    LibraryRepository::getInstance()->add(name, anchor);
  }

  void loadDefaultLibrary()
  {
    LibraryRepository::getInstance()->addDefaultLibrary();
  }

  void *getSymbol(const std::string& name)
  {
    return LibraryRepository::getInstance()->getSymbol(name);
  }
  std::string getSymbolsLibrary(const std::string& name)
  {
    return LibraryRepository::getInstance()->getSymbolsLibrary(name);
  }
  void *getLibrary(const std::string& name)
  {
    return LibraryRepository::getInstance()->getLibrary(name);
  }

} // ::ospcommon

