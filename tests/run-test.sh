#! /bin/sh

[ "${TRACE}" = "YES" ] && set -x


TEST_DIR="`dirname "$0"`"
PROJECT_DIR="`( cd "${TEST_DIR}/.." ; pwd -P)`"

PATH="${PROJECT_DIR}:$PATH"
export PATH


main()
{
   _options_mini_main "$@"

   MULLE_FETCH="`which mulle-fetch`" || exit 1

   local i

   log_verbose "mulle-fetch: `mulle-fetch version` (`mulle-fetch library-path`)"

   for i in "${TEST_DIR}"/*
   do
      if [ -x "$i/run-test.sh" ]
      then
         log_verbose "------------------------------------------"
         log_info    "$i:"
         log_verbose "------------------------------------------"
         ( cd "$i" && ./run-test.sh "$@" ) || exit 1
      fi
   done
}



init()
{
   MULLE_BASHFUNCTIONS_LIBEXEC_DIR="`mulle-bashfunctions-env library-path`" || exit 1

   . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-bashfunctions.sh" || exit 1
}


init "$@"
main "$@"

