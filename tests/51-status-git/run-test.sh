#! /usr/bin/env bash

[ "${TRACE}" = "YES" ] && set -x


run_mulle_fetch()
{
   log_fluff "####################################"
   log_fluff ${MULLE_FETCH} ${MULLE_FETCH_FLAGS} "$@"
   log_fluff "####################################"

   exekutor ${MULLE_FETCH} ${MULLE_FETCH_FLAGS} "$@"
}


_setup_demo_repo()
{
   git init

   redirect_exekutor version echo "1.0.0"
   exekutor git add version
   exekutor git commit -m "inital version 1.0.0 (tagged)"
   exekutor git tag "1.0.0"
}


setup_demo_repo()
{
   (
      set -e
      mkdir_if_missing "$1" &&
      exekutor cd "$1" && _setup_demo_repo
      set +e
   )
}


main()
{
   MULLE_FETCH_FLAGS="$@"

   _options_mini_main "$@"

   local directory
   local repo

   directory="`make_tmp_directory`" || exit 1
   directory="${directory:-/tmp/exekutor}"

   repo="${directory}/repo"

   setup_demo_repo "${repo}"

   run_mulle_fetch status "${repo}" || exit 1
   log_verbose "----- #1 PASSED -----"

   log_info "----- ALL PASSED -----"

   rmdir_safer "${directory}"
}



init()
{
   MULLE_BASHFUNCTIONS_LIBEXEC_DIR="`mulle-bashfunctions-env library-path`" || exit 1

   . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-bashfunctions.sh" || exit 1

   MULLE_FETCH="${MULLE_FETCH:-${PWD}/../../mulle-fetch}"
}



init "$@"
main "$@"

