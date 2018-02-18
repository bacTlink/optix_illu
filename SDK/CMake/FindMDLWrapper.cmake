#
# Copyright (c) 2017 NVIDIA CORPORATION.  All rights reserved.
#
# NVIDIA Corporation and its licensors retain all intellectual property and proprietary
# rights in and to this software, related documentation and any modifications thereto.
# Any use, reproduction, disclosure or distribution of this software and related
# documentation without an express license agreement from NVIDIA Corporation is strictly
# prohibited.
#
# TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, THIS SOFTWARE IS PROVIDED *AS IS*
# AND NVIDIA AND ITS SUPPLIERS DISCLAIM ALL WARRANTIES, EITHER EXPRESS OR IMPLIED,
# INCLUDING, BUT NOT LIMITED TO, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
# PARTICULAR PURPOSE.  IN NO EVENT SHALL NVIDIA OR ITS SUPPLIERS BE LIABLE FOR ANY
# SPECIAL, INCIDENTAL, INDIRECT, OR CONSEQUENTIAL DAMAGES WHATSOEVER (INCLUDING, WITHOUT
# LIMITATION, DAMAGES FOR LOSS OF BUSINESS PROFITS, BUSINESS INTERRUPTION, LOSS OF
# BUSINESS INFORMATION, OR ANY OTHER PECUNIARY LOSS) ARISING OUT OF THE USE OF OR
# INABILITY TO USE THIS SOFTWARE, EVEN IF NVIDIA HAS BEEN ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGES.
#

# Locate the MDL-Wrapper inside the support folder

find_library(mdl_wrapper_LIBRARY
  NAMES mdl_wrapper
  PATHS ${CMAKE_CURRENT_SOURCE_DIR}/support/mdl_wrapper/lib
  NO_DEFAULT_PATH
  )

find_path(mdl_wrapper_INCLUDE_DIR
  NAMES mdl_wrapper.h
  PATHS ${CMAKE_CURRENT_SOURCE_DIR}/support/mdl_wrapper/include
  NO_DEFAULT_PATH
  )

if( mdl_wrapper_LIBRARY AND
    mdl_wrapper_INCLUDE_DIR
    )
  set(mdl_wrapper_FOUND TRUE)

  add_library(mdl_wrapper UNKNOWN IMPORTED)
  set_property(TARGET mdl_wrapper PROPERTY IMPORTED_LOCATION "${mdl_wrapper_LIBRARY}")
endif()
