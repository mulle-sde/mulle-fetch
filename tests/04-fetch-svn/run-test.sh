#! /usr/bin/env bash

[ "${TRACE}" = "YES" ] && set -x



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
   _options_mini_main "$@"


   # getting a local svn running is tedious
   local repo

   repo="https://github.com/mulle-nat/mulle-fetch-svn-test"

   local dstdir

   dstdir="`make_tmp_directory`"  || exit 1
   dstdir="${dstdir:-/tmp/exekutor_dstdir}"

   #
   # svn in mulle-fetch is fairly powerless
   # but branches should work...
   #
   exekutor ${MULLE_FETCH} fetch -s svn "${repo}" "${dstdir}" || exit 1

   # i goofed up the git import somehow, 2.0.0 is correct
   expect_version "${dstdir}" "trunk" "2.0.0"
   rmdir_safer "${dstdir}"
   log_info "----- ALL PASSED -----"

   rmdir_safer "${dstdir}"
}



init()
{
   MULLE_BASHFUNCTIONS_LIBEXEC_DIR="`mulle-bashfunctions-env library-path`" || exit 1

   . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-bashfunctions.sh" || exit 1

   MULLE_FETCH="${MULLE_FETCH:-${PWD}/../../mulle-fetch}"
}



init "$@"
main "$@"

