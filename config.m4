PHP_ARG_WITH(couchbase, whether to enable Couchbase support,
[  --with-couchbase   Include Couchbase support])


AC_SUBST(PHP_COUCHBASE)

if test "$PHP_COUCHBASE" != "no"; then
  PHP_REQUIRE_CXX
  AC_PATH_PROG(CMAKE, cmake, no)
  if ! test -x "${CMAKE}"; then
    AC_MSG_ERROR(Please install cmake to build couchbase extension)
  fi
  COUCHBASE_CMAKE_C_FLAGS="$CFLAGS"
  COUCHBASE_CMAKE_CXX_FLAGS="$CXXFLAGS"
  COUCHBASE_CMAKE_STATIC_LINKER_FLAGS="$LDFLAGS"
  COUCHBASE_CMAKE_INCLUDE_PATH=""
  m4_foreach([inc], m4_split([$INCLUDES]), [ echo inc ])

  PHP_SUBST([CMAKE])
  PHP_SUBST([COUCHBASE_CMAKE_C_FLAGS])
  PHP_SUBST([COUCHBASE_CMAKE_CXX_FLAGS])
  PHP_SUBST([COUCHBASE_CMAKE_INCLUDE_PATH])
  PHP_SUBST([COUCHBASE_CMAKE_STATIC_LINKER_FLAGS])

COUCHBASE_FILES=" \
    src/php_couchbase.cxx \
"
  PHP_NEW_EXTENSION(couchbase, ${COUCHBASE_FILES}, $ext_shared)
  PHP_ADD_EXTENSION_DEP(couchbase, json)
fi

PHP_ADD_MAKEFILE_FRAGMENT

AC_CONFIG_COMMANDS_POST([
  echo "
Build configuration:
  CMAKE                               : $CMAKE
  COUCHBASE_CMAKE_C_FLAGS             : $COUCHBASE_CMAKE_C_FLAGS            
  COUCHBASE_CMAKE_CXX_FLAGS           : $COUCHBASE_CMAKE_CXX_FLAGS          
  COUCHBASE_CMAKE_INCLUDE_PATH        : $COUCHBASE_CMAKE_INCLUDE_PATH          
  COUCHBASE_CMAKE_STATIC_LINKER_FLAGS : $COUCHBASE_CMAKE_STATIC_LINKER_FLAGS

"
])
