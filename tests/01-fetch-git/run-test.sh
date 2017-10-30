#! /usr/bin/env bash

[ "${TRACE}" = "YES" ] && set -x


_setup_demo_repo()
{
   git init

   redirect_exekutor version echo "1.0.0"
   exekutor git add version
   exekutor git commit -m "inital version 1.0.0 (tagged)"
   exekutor git tag "1.0.0"

   redirect_exekutor version echo "2.0.0"
   exekutor git commit -m "version 2.0.0 (tagged)" version
   exekutor git tag "2.0.0"

   exekutor git checkout -b patch master

   redirect_exekutor version echo "2.0.1"
   exekutor git commit -m "version 2.0.1 (tagged)" version
   exekutor git tag "2.0.1"

   exekutor git checkout master

   redirect_exekutor version echo "3.0.0"
   exekutor git commit -m "version 3.0.0 (tagged)" version
   exekutor git tag "3.0.0"

   redirect_exekutor version echo "3.1.0"
   exekutor git commit -m "version 3.1.0 (tagged)" version
   exekutor git tag "3.1.0"
}


setup_demo_repo()
{
   (
      set -e
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
   _options_mini_main "$@"

   local repo

   repo="`make_tmp_directory`" || exit 1
   repo="${repo:-/tmp/exekutor_repo}"

   setup_demo_repo "${repo:-/tmp/exekutor}" || exit 1

   local dstdir

   dstdir="`make_tmp_directory`"  || exit 1
   dstdir="${dstdir:-/tmp/exekutor_dstdir}"

   exekutor ${MULLE_FETCH} fetch "${repo}" "${dstdir}" || exit 1
   expect_version "${dstdir}" "3.1.0"
   rmdir_safer "${dstdir}"
   log_verbose "----- #1 PASSED -----"

   exekutor ${MULLE_FETCH} fetch -b master "${repo}" "${dstdir}" || exit 1
   expect_version "${dstdir}" "3.1.0"
   rmdir_safer "${dstdir}"
   log_verbose "----- #2 PASSED -----"

   exekutor ${MULLE_FETCH} fetch -t 3.0.0 -b master "${repo}" "${dstdir}" || exit 1
   expect_version "${dstdir}" "3.0.0"
   rmdir_safer "${dstdir}"
   log_verbose "----- #3 PASSED -----"

   exekutor ${MULLE_FETCH} fetch -b patch "${repo}" "${dstdir}" || exit 1
   expect_version "${dstdir}" "2.0.1"
   rmdir_safer "${dstdir}"
   log_verbose "----- #4 PASSED -----"

   exekutor ${MULLE_FETCH} fetch -t 2.0.0 -b patch "${repo}" "${dstdir}" || exit 1
   expect_version "${dstdir}" "2.0.0"
   rmdir_safer "${dstdir}"
   log_verbose "----- #5 PASSED -----"

   if exekutor ${MULLE_FETCH} -ld -t fetch -b release "${repo}" "${dstdir}"
   then
      exekutor fail "unexpected success fetching unknown branch release"
   fi
   log_verbose "----- #6 PASSED -----"

   if exekutor ${MULLE_FETCH} fetch -t 2.0.2 -b patch "${repo}" "${dstdir}"
   then
      exekutor fail "unexpected success fetching unknown tag 2.0.2"
   fi
   log_verbose "----- #7 PASSED -----"

   if exekutor ${MULLE_FETCH} fetch -t 3.0.0 -b patch "${repo}" "${dstdir}"
   then
      exekutor fail "unexpected success fetching tag 3.0.0 on patch branch"
   fi
   log_verbose "----- #8 PASSED -----"

   if exekutor ${MULLE_FETCH} fetch -t 2.0.1 "${repo}" "${dstdir}"
   then
      exekutor fail "unexpected success fetching tag 2.0.1 on default branch"
   fi
   log_verbose "----- #9 PASSED -----"
   log_info "----- ALL PASSED -----"

   rmdir_safer "${dstdir}"
   rmdir_safer "${repo}"
}



init()
{
   MULLE_BASHFUNCTIONS_LIBEXEC_DIR="`mulle-bashfunctions-env library-path`" || exit 1

   . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-bashfunctions.sh" || exit 1

   MULLE_FETCH="${MULLE_FETCH:-${PWD}/../../mulle-fetch}"
}



init "$@"
main "$@"

