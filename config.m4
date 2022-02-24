PHP_ARG_WITH(couchbase, whether to enable Couchbase support,
[  --with-couchbase   Include Couchbase support])

if test "$PHP_COUCHBASE" != "no"; then
  AC_PATH_PROG(CMAKE, cmake, no)

  if ! test -x "${CMAKE}"; then
    AC_MSG_ERROR(Please install cmake to build couchbase extension)
  fi

COUCHBASE_FILES=" \
    src/php_couchbase.c \
"

  PHP_NEW_EXTENSION(couchbase, ${COUCHBASE_FILES}, $ext_shared,, -DZEND_ENABLE_STATIC_TSRMLS_CACHE=1)
  PHP_ADD_EXTENSION_DEP(couchbase, json)
fi
