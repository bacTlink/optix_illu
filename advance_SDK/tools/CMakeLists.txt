function (cp_py_file filename)
  configure_file(${filename} ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/../tools/${filename} COPYONLY)
endfunction()

cp_py_file(gen_ppm_data.py)
