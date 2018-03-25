file(GLOB_RECURSE py_srcs ${CMAKE_CURRENT_SOURCE_DIR}/*.py)

function (cp_py_file source)
  string( REGEX REPLACE "${CMAKE_CURRENT_SOURCE_DIR}/(.*)" "\\1" filename ${source} ) 
  configure_file(${source} ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/../tools/${filename} COPYONLY)
endfunction()

foreach(source ${py_srcs})
  cp_py_file(${source})
endforeach(source)
