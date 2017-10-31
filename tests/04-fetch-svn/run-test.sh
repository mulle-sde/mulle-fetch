#! /usr/bin/env bash

[ "${TRACE}" = "YES" ] && set -x


run_mulle_fetch()
{
   log_fluff "####################################"
   log_fluff ${MULLE_FETCH} ${MULLE_FETCH_FLAGS} "$@"
   log_fluff "####################################"

   exekutor ${MULLE_FETCH} ${MULLE_FETCH_FLAGS} "$@"
}


expect_version()
{
   local dstdir="$1"
   local branch="$2"
   local expected="$3"

   local version
   local version

   case "${branch}" in
      trunk|"")
         dstdir="${dstdir}/trunk"
      ;;

      *)
         dstdir="${dstdir}/branches/${branch}"
      ;;
   esac

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

   local directory
   local dstdir
   local repo

   directory="`make_tmp_directory`" || exit 1
   directory="${directory:-/tmp/exekutor}"

   dstdir="${directory}/dstdir"

   repo="https://github.com/mulle-nat/mulle-fetch-svn-test.git"

   #
   # svn in mulle-fetch is fairly powerless
   #
   run_mulle_fetch ${MULLE_FETCH_FLAGS} fetch -s svn "${repo}" "${dstdir}" || exit 1
   # i goofed up the git import somehow, 2.0.0 is correct
   expect_version "${dstdir}" "trunk" "2.0.0"
   rmdir_safer "${dstdir}"
   log_verbose "----- #1 PASSED -----"

   run_mulle_fetch ${MULLE_FETCH_FLAGS} fetch -t r1 -s svn "${repo}" "${dstdir}" || exit 1
   expect_version "${dstdir}" "trunk" "1.0.0"
   rmdir_safer "${dstdir}"
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

