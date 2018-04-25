#
# Copyright (c) 2016, NVIDIA CORPORATION. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#  * Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#  * Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#  * Neither the name of NVIDIA CORPORATION nor the names of its
#    contributors may be used to endorse or promote products derived
#    from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS ``AS IS'' AND ANY
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
# OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#


# Adjust the library search path based on the bit-ness of the build.  
# (i.e. 64: bin64, lib64; 32: bin, lib).  
# Note that on Mac, the OptiX library is a universal binary, so we
# only need to look in lib and not lib64 for 64 bit builds.
if(CMAKE_SIZEOF_VOID_P EQUAL 8 AND NOT APPLE)
  set(bit_dest "64")
else()
  set(bit_dest "")
endif()


set( YAML_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../" CACHE PATH "Path to OptiX installed location.")

macro(YAML_find_api_library name version)
  find_library(${name}_LIBRARY
    NAMES ${name}.${version} ${name}
    PATHS "${YAML_DIR}/yaml/lib${bit_dest}" "/usr/local/lib"
    NO_DEFAULT_PATH
    )
  find_library(${name}_LIBRARY
    NAMES ${name}.${version} ${name}
    )
endmacro()

YAML_find_api_library(yaml-cpp 1)

# Include
find_path(yaml-cpp_INCLUDE
  NAMES yaml-cpp
  PATHS "${YAML_DIR}/yaml/include" "/usr/local/include"
  NO_DEFAULT_PATH
  )

# Check to make sure we found what we were looking for
function(YAML_report_error error_message required)
  if(OptiX_FIND_REQUIRED AND required)
    message(FATAL_ERROR "${error_message}")
  else()
    if(NOT OptiX_FIND_QUIETLY)
      message(STATUS "${error_message}")
    endif(NOT OptiX_FIND_QUIETLY)
  endif()
endfunction()

if(NOT yaml-cpp_LIBRARY)
  YAML_report_error("YAML library not found.  Please locate before proceeding, and set YAML_DIR." TRUE)
endif()
if(NOT yaml-cpp_INCLUDE)
  YAML_report_error("YAML headers (yaml.h and friends) not found.  Please locate before proceeding." TRUE)
endif()

# Macro for setting up dummy targets
function(Yaml_add_imported_library name lib_location dll_lib dependent_libs)
  set(CMAKE_IMPORT_FILE_VERSION 1)

  # Create imported target
  add_library(${name} SHARED IMPORTED)

  # Import target "optix" for configuration "Debug"
  if(WIN32)
    set_target_properties(${name} PROPERTIES
      IMPORTED_IMPLIB "${lib_location}"
      IMPORTED_LINK_INTERFACE_LIBRARIES "${dependent_libs}"
      )
  elseif(UNIX)
    set_target_properties(${name} PROPERTIES
      #IMPORTED_LINK_INTERFACE_LIBRARIES "glu32;opengl32"
      IMPORTED_LOCATION "${lib_location}"
      # We don't have versioned filenames for now, and it may not even matter.
      #IMPORTED_SONAME "${yaml_soname}"
      IMPORTED_LINK_INTERFACE_LIBRARIES "${dependent_libs}"
      )
  else()
    # Unknown system, but at least try and provide the minimum required
    # information.
    set_target_properties(${name} PROPERTIES
      IMPORTED_LOCATION "${lib_location}"
      IMPORTED_LINK_INTERFACE_LIBRARIES "${dependent_libs}"
      )
  endif()

  # Commands beyond this point should not need to know the version.
  set(CMAKE_IMPORT_FILE_VERSION)
endfunction()

# Sets up a dummy target
Yaml_add_imported_library(yaml-cpp "${yaml-cpp_LIBRARY}" "" "")
