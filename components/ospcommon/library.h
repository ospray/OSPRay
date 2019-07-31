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

#pragma once

#include "common.h"
// std
#include <map>
#include <memory>
#include <string>

namespace ospcommon {

  class OSPCOMMON_INTERFACE Library
  {
    public:
      /* opens a shared library */
      Library(const std::string& name, bool anchor = true);
      ~Library();

      /* returns address of a symbol from the library */
      void* getSymbol(const std::string& sym) const;

    private:
      Library(void* const lib);
      std::string libraryName;
      void *lib;
      bool freeLibOnDelete{true};
      friend class LibraryRepository;
  };

  class OSPCOMMON_INTERFACE LibraryRepository
  {
    public:
      static LibraryRepository* getInstance();
      static void cleanupInstance();

      ~LibraryRepository();

      /* add a library to the repo */
      void add(const std::string& name, bool anchor = true);

      /* returns address of a symbol from any library in the repo */
      void* getSymbol(const std::string& sym) const;

      /* returns name of a library in the repo that holds a symbol */
      std::string getSymbolsLibrary(const std::string& sym) const;

      /* add the default library to the repo */
      void addDefaultLibrary();

      bool libraryExists(const std::string &name) const;
      void* getLibrary(const std::string &name) const;

    private:
      static std::unique_ptr<LibraryRepository> instance;
      LibraryRepository() = default;
      std::map<std::string, Library*> repo;
  };
}

