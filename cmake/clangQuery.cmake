set(static_analysis_root ${CMAKE_CURRENT_LIST_DIR}/static_analysis_checkers CACHE PATH "")
set(cmake_current_directory ${CMAKE_CURRENT_LIST_DIR} CACHE PATH "")
set(DEFAULT_CLANG_QUERY clang-query CACHE STRING "")
set(DEFAULT_CHECKER_DIRECTORY ${static_analysis_root} CACHE PATH "")
set(CLANG_QUERY_PYTHON_WRAPPER ${CMAKE_BINARY_DIR}/share/clang-query-wrapper.py CACHE FILEPATH "")
configure_file(${cmake_current_directory}/clang-query-wrapper.py.in ${CLANG_QUERY_PYTHON_WRAPPER})
macro(integrate_clang_query TARGET)
  if(LAMMPS_ENABLE_STATIC_ANALYSIS)
  if(TARGET check_global)
  else()
    add_custom_target(check_global)
  endif()
  set(CMAKE_EXPORT_COMPILE_COMMANDS On)
  STRING(REPLACE "/" "_" TARGET_NAME check_${TARGET})
  if(TARGET ${TARGET_NAME})
  else()
  add_custom_target(${TARGET_NAME})
  add_dependencies(check_global ${TARGET_NAME})
  endif()
  MESSAGE(STATUS "Made static analysis target ${TARGET_NAME}")
  get_target_property(TARGET_DEFINITIONS ${TARGET} COMPILE_DEFINITIONS)
  get_target_property(TARGET_FLAGS ${TARGET} COMPILE_FLAGS)
  get_target_property(TARGET_SOURCES ${TARGET} SOURCES)
  get_directory_property(DIRECTORY_DEFINITIONS DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} COMPILE_DEFINITIONS)
  set(FULL_DEFINITIONS ${DIRECTORY_DEFINITIONS})
  IF(TARGET_DEFINITIONS)
    SET(FULL_DEFINITIONS ${FULL_DEFINITIONS} ${TARGET_DEFINITIONS})
  ENDIF()
  IF(TARGET_FLAGS)
    SET(FULL_FLAGS ${FULL_FLAGS} ${TARGET_FLAGS})
  ENDIF()
  foreach(TARGET_SOURCE_IN IN LISTS TARGET_SOURCES)
    get_source_file_property(FILE_LANGUAGE ${TARGET_SOURCE_IN} LANGUAGE)
    if(FILE_LANGUAGE MATCHES "Fortran")
    else()
      get_filename_component(TARGET_FINAL_NAME ${TARGET_SOURCE_IN} NAME)
      get_filename_component(ABSOLUTE_SOURCE_FILE ${TARGET_SOURCE_IN} ABSOLUTE)
      STRING(REPLACE "/" "_" TARGET_SOURCE ${TARGET_SOURCE_IN})
      add_custom_target(
        check_${TARGET_FINAL_NAME}
        COMMAND python ${CLANG_QUERY_PYTHON_WRAPPER} -I/usr/tce/packages/mvapich2/mvapich2-2.2-intel-18.0.1/include -p=${CMAKE_CURRENT_BINARY_DIR} ${CMAKE_CXX_FLAGS} ${FULL_DEFINITIONS} ${FULL_FLAGS} ${ABSOLUTE_SOURCE_FILE}
        VERBATIM
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
        COMMENT "Executing clang-query against ${TARGET_FINAL_NAME}"
      )
      add_dependencies(${TARGET_NAME} check_${TARGET_FINAL_NAME})
    endif()
  endforeach()
  endif()
endmacro()


