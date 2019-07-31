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

#include "library.h"
#include "FileName.h"
#include "sysinfo.h"

// std
#ifdef _WIN32
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <windows.h>
#else
#include <dlfcn.h>
#include <sys/times.h>
#endif

extern "C" {
/* Export a symbol to ask the dynamic loader about in order to locate this
 * library at runtime. */
OSPCOMMON_INTERFACE int _ospray_anchor()
{
  return 0;
}
}

namespace {

  std::string library_location()
  {
#if defined(_WIN32) && !defined(__CYGWIN__)
    MEMORY_BASIC_INFORMATION mbi;
    VirtualQuery(&_ospray_anchor, &mbi, sizeof(mbi));
    char pathBuf[16384];
    if (!GetModuleFileNameA(
            static_cast<HMODULE>(mbi.AllocationBase), pathBuf, sizeof(pathBuf)))
      return std::string();

    std::string path = std::string(pathBuf);
    path.resize(path.rfind('\\') + 1);
#else
    const char *anchor = "_ospray_anchor";
    void *handle       = dlsym(RTLD_DEFAULT, anchor);
    if (!handle)
      return std::string();

    Dl_info di;
    int ret = dladdr(handle, &di);
    if (!ret || !di.dli_saddr || !di.dli_fname)
      return std::string();

    std::string path = std::string(di.dli_fname);
    path.resize(path.rfind('/') + 1);
#endif

    return path;
  }

}  // namespace

namespace ospcommon {

  Library::Library(const std::string &name, bool anchor) : libraryName(name)
  {
    std::string file = name;
    std::string errorMsg;
    std::string libLocation = anchor ? library_location() : std::string();
#ifdef _WIN32
    std::string fullName = libLocation + file + ".dll";
    lib                  = LoadLibrary(fullName.c_str());
    if (lib == nullptr) {
      DWORD err = GetLastError();
      LPTSTR lpMsgBuf;
      FormatMessage(FORMAT_MESSAGE_ALLOCATE_BUFFER |
                        FORMAT_MESSAGE_FROM_SYSTEM |
                        FORMAT_MESSAGE_IGNORE_INSERTS,
                    NULL,
                    err,
                    MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
                    (LPTSTR)&lpMsgBuf,
                    0,
                    NULL);

      errorMsg = lpMsgBuf;

      LocalFree(lpMsgBuf);
    }
#else
#if defined(__MACOSX__) || defined(__APPLE__)
    std::string fullName = libLocation + "lib" + file + ".dylib";
#else
    std::string fullName = libLocation + "lib" + file + ".so";
#endif
    lib                  = dlopen(fullName.c_str(), RTLD_NOW | RTLD_GLOBAL);
    if (lib == nullptr) {
      errorMsg = dlerror();  // remember original error
      // retry with SOVERSION in case symlinks are missing
      std::string soversion(TOSTRING(OSPRAY_SOVERSION));
#if defined(__MACOSX__) || defined(__APPLE__)
      fullName = "lib" + file + "." + soversion + ".dylib";
#else
      fullName += "." + soversion;
#endif
      lib      = dlopen(fullName.c_str(), RTLD_NOW | RTLD_GLOBAL);
    }
#endif
  }

  Library::Library(void *const _lib)
      : libraryName("<pre-loaded>"), lib(_lib), freeLibOnDelete(false)
  {
  }

  Library::~Library()
  {
    if (freeLibOnDelete && lib) {
#ifdef _WIN32
      FreeLibrary((HMODULE)lib);
#else
      dlclose(lib);
#endif
    }
  }

  void *Library::getSymbol(const std::string &sym) const
  {
#ifdef _WIN32
    return GetProcAddress((HMODULE)lib, sym.c_str());
#else
    return dlsym(lib, sym.c_str());
#endif
  }

  std::unique_ptr<LibraryRepository> LibraryRepository::instance;

  LibraryRepository *LibraryRepository::getInstance()
  {
    if (instance.get() == nullptr)
      instance = std::unique_ptr<LibraryRepository>(new LibraryRepository);

    return instance.get();
  }

  void LibraryRepository::cleanupInstance()
  {
    LibraryRepository::instance.reset();
  }

  LibraryRepository::~LibraryRepository()
  {
    for (auto &l : repo)
      delete l.second;
    repo.clear();
  }

  void LibraryRepository::add(const std::string &name, bool anchor)
  {
    if (libraryExists(name))
      return;  // lib already loaded.

    repo[name] = new Library(name, anchor);
  }

  void *LibraryRepository::getSymbol(const std::string &name) const
  {
    void *sym = nullptr;
    for (auto lib = repo.cbegin(); sym == nullptr && lib != repo.end(); ++lib)
      sym = lib->second->getSymbol(name);

    return sym;
  }
  std::string LibraryRepository::getSymbolsLibrary(const std::string &name) const
  {
    void *sym = nullptr;
    std::string rlib = "";
    for (auto lib = repo.cbegin(); sym == nullptr && lib != repo.end(); ++lib)
    {
      sym = lib->second->getSymbol(name);
      rlib = lib->first;
    }

    if (sym)
      return rlib;
    return "";
  }

  void LibraryRepository::addDefaultLibrary()
  {
    // already populate the repo with "virtual" libs, representing the default
    // OSPRay core lib
#ifdef _WIN32
    // look in exe (i.e. when OSPRay is linked statically into the application)
    repo["exedefault"] = new Library(GetModuleHandle(0));

    // look in ospray.dll (i.e. when linked dynamically)
#if 0
    // we cannot get a function from ospray.dll, because this would create a
    // cyclic dependency between ospray.dll and ospray_common.dll

    // only works when ospray_common is linked statically into ospray
    const void * functionInOSPRayDLL = ospcommon::getSymbol;
    // get handle to current dll via a known function
    MEMORY_BASIC_INFORMATION mbi;
    VirtualQuery(functionInOSPRayDLL, &mbi, sizeof(mbi));
    repo["dlldefault"] = new Library(mbi.AllocationBase);
#else
    repo["ospray"] = new Library(std::string("ospray"));
#endif
#else
    repo["ospray"] = new Library(RTLD_DEFAULT);
#endif
  }

  bool LibraryRepository::libraryExists(const std::string &name) const
  {
    return repo.find(name) != repo.end();
  }
  void* LibraryRepository::getLibrary(const std::string &name) const
  {
    auto lib = repo.find(name);
    if (lib != repo.end())
      return lib->second;
    return nullptr;
  }

}  // namespace ospcommon
