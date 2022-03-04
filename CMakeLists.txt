cmake_minimum_required(VERSION 3.20)
project(php_client LANGUAGES CXX)

find_program(PHP_CONFIG_EXECUTABLE php-config)
message(STATUS "PHP_CONFIG: ${PHP_CONFIG_EXECUTABLE}")

macro(_php_config_invoke _varname _regexp)
    set(_php_config_invoke_result)
    execute_process(
            COMMAND ${PHP_CONFIG_EXECUTABLE} --includes ${ARGN}
            OUTPUT_VARIABLE _php_config_invoke_result
            RESULT_VARIABLE _php_config_failed
            OUTPUT_STRIP_TRAILING_WHITESPACE)

    if (_php_config_failed)
        set(${_varname} "" CACHE INTERNAL "")
    else()
        string(REGEX REPLACE "[\r\n]" " " _php_config_invoke_result "${_php_config_invoke_result}")
        if (NOT ${_regexp} STREQUAL "")
            string(REGEX REPLACE "${_regexp}" " " _php_config_invoke_result "${_php_config_invoke_result}")
        endif()

        separate_arguments(_php_config_invoke_result)
        set(${_varname} ${_php_config_invoke_result})
    endif()
endmacro()

_php_config_invoke(PHP_INCLUDE_DIRS "-I" "--includes")
message(STATUS "PHP_INCLUDE_DIRS: ${PHP_INCLUDE_DIRS}")

set(COUCHBASE_CXX_CLIENT_BUILD_TESTS OFF)
add_subdirectory(deps/couchbase-cxx-client)

add_executable(couchbase couchbase.cxx)
target_include_directories(couchbase PRIVATE BEFORE SYSTEM ${PHP_INCLUDE_DIRS})
target_link_libraries(couchbase PRIVATE couchbase_cxx_client)
