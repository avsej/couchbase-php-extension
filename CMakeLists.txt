cmake_minimum_required(VERSION 3.17)
project(couchbase C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_C_STANDARD 99)

add_subdirectory(deps/couchbase-cxx-client)

get_filename_component(PHP_SRC_PATH "~/code/php/php-src" ABSOLUTE)

include_directories(
  "${PHP_SRC_PATH}"
  "${PHP_SRC_PATH}/main"
  "${PHP_SRC_PATH}/Zend"
  "${PHP_SRC_PATH}/TSRM"
  "${PHP_SRC_PATH}/ext"
  "${PHP_SRC_PATH}/sapi"
  "${PROJECT_SOURCE_DIR}")

if(NOT EXT_GIT_REVISION)
  find_program(GIT git)
  if(GIT)
    execute_process(
      COMMAND git rev-parse HEAD
      WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
      OUTPUT_STRIP_TRAILING_WHITESPACE
      OUTPUT_VARIABLE EXT_GIT_REVISION)
  else()
    set(EXT_GIT_REVISION "unknown")
  endif()
endif()
configure_file(${PROJECT_SOURCE_DIR}/cmake/ext_build_version.hxx.in
               ${PROJECT_BINARY_DIR}/generated/ext_build_version.hxx @ONLY)
file(
  GENERATE
  OUTPUT ${PROJECT_BINARY_DIR}/generated/ext_build_info.hxx
  CONTENT
    "
#pragma once
constexpr auto RUBY_LIBRARY = \"${RUBY_LIBRARY}\";
constexpr auto RUBY_INCLUDE_DIR = \"${RUBY_INCLUDE_DIR}\";
")

file(GLOB SOURCE_FILES ${PROJECT_SOURCE_DIR}/src/bindings/*.cxx)
add_library(couchbase STATIC ${SOURCE_FILES})
target_include_directories(couchbase PRIVATE ${PROJECT_BINARY_DIR}/generated)
target_link_libraries(couchbase PRIVATE project_options project_warnings couchbase_cxx_client)
