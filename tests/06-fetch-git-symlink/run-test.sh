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


expect_version()
{
   local dstdir="$1"
   local expected="$2"

   local version

   version="`exekutor cat "${dstdir}/version"`"
   if exekutor [ "${version}" != "${expected}" ]
   then
      exekutor fail "Expected to find version \"${expected}\" but got \"${version}\""
   fi
}


main()
{
   MULLE_FETCH_FLAGS="$@"

   _options_mini_main "$@"

   case "${UNAME}" in
      mingw)
         log_warning "Symlinks don't work on mingw. Test skipped"
         exit 0
      ;;
   esac

   local directory
   local dstdir
   local repo
   local rval

   directory="`make_tmp_directory`" || exit 1
   directory="${directory:-/tmp/exekutor}"

   repo="${directory}/repo"
   dstdir="${directory}/dstdir"

   setup_demo_repo "${repo}" || exit 1

   run_mulle_fetch fetch -2 -l "${directory}" "${repo}" "${dstdir}"
   rval=$?
   case "${rval}" in
      0)
         [ ! -e "${dstdir}" ] && fail "Failed to create dstdir"
         [ ! -L "${dstdir}" ] && fail "Failed to create a symlink"
         fail "wrong return code (0 instead of 2)"
      ;;

      2)
         [ ! -L "${dstdir}" ] && fail "failed to create the proper symlink"
      ;;

      *)
         fail "Failed with return code $rval"
         exit 1
      ;;
   esac

   expect_version "${dstdir}" "1.0.0"
   remove_file_if_present "${dstdir}"

   log_verbose "----- #1 PASSED -----"

   run_mulle_fetch fetch --symlinks "${repo}" "${dstdir}"
   case $? in
      0)
         [ ! -L "${dstdir}" ] && fail "failed to create the proper symlink"
      ;;

      2)
         fail "returned a 2 where it should not have"
      ;;

      *)
         exit 1
      ;;
   esac
   log_verbose "----- #2 PASSED -----"

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

