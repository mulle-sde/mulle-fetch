#! /usr/bin/env bash
#
#   Copyright (c) 2017 Nat! - Mulle kybernetiK
#   All rights reserved.
#
#   Redistribution and use in source and binary forms, with or without
#   modification, are permitted provided that the following conditions are met:
#
#   Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
#   Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
#   Neither the name of Mulle kybernetiK nor the names of its contributors
#   may be used to endorse or promote products derived from this software
#   without specific prior written permission.
#
#   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
#   AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
#   IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
#   ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
#   LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
#   CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
#   SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
#   INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
#   CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
#   ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
#
MULLE_FETCH_PLUGIN_TAR_SH="included"

_archive_test()
{
   log_entry "_archive_test" "$@"

   local archive="$1"

   log_fluff "Testing ${C_MAGENTA}${C_BOLD}${archive}${C_INFO} ..."

   case "${archive}" in
      *.zip)
         redirect_exekutor /dev/null unzip -t "${archive}" || return 1
         return 0   # can't test more easily here
      ;;
   esac

   local tarcommand

   tarcommand="tf"

   case "${UNAME}" in
      darwin)
         # don't need it
      ;;

      *)
         case "${url}" in
            *.gz)
               tarcommand="tfz"
            ;;

            *.bz2)
               tarcommand="tfj"
            ;;

            *.x)
               tarcommand="tfJ"
            ;;
         esac
      ;;
   esac


   redirect_exekutor /dev/null tar ${OPTION_TOOL_FLAGS} ${tarcommand} ${OPTION_TOOL_OPTIONS} ${options} "${archive}" || return 1
}


_tar_unpack()
{
   log_entry "_tar_unpack" "$@"

   local archive="$1"
   local sourceoptions="$2"

   log_verbose "Extracting ${C_MAGENTA}${C_BOLD}${archive}${C_INFO} ..."

   local tarcommand

   tarcommand="xf"

   case "${UNAME}" in
      darwin)
         # don't need it
      ;;

      *)
         case "${url}" in
            *.gz)
               tarcommand="xfz"
            ;;

            *.bz2)
               tarcommand="xfj"
            ;;

            *.x)
               tarcommand="xfJ"
            ;;
         esac
      ;;
   esac

   local options

   options="`get_sourceoption "${sourceoptions}" "tar"`"

   exekutor tar ${OPTION_TOOL_FLAGS} ${tarcommand} ${OPTION_TOOL_OPTIONS} ${options} "${archive}" || return 1
}


archive_cache_grab()
{
   log_entry "archive_cache_grab" "$@"

   local url="$1"
   local download="$2"

   [ -z "${url}" ]      && internal_fail "url is empty"
   [ -z "${download}" ] && internal_fail "download is empty"

   if [ -z "${OPTION_CACHE_DIR}" ]
   then
      log_fluff "Caching not active"
      return 2
   fi

   local archive_cache
   local cachable_path
   local cached_archive
   local filename
   local directory

   # fix for github
   case "${url}" in
      *github.com*/archive/*)
         directory="`dirname -- "${url}"`" # remove 3.9.2
         directory="`dirname -- "${directory}"`" # remove archives
         filename="`basename -- "${directory}"`-${download}"
      ;;

      *)
         filename="${download}"
      ;;
   esac

   cachable_path="${OPTION_CACHE_DIR}/${filename}"

   if [ "${OPTION_REFRESH}" != "YES" ]
   then
      if [ -f "${cachable_path}" ]
      then
         cached_archive="${cachable_path}"
      fi

      if [ ! -z "${cached_archive}" ]
      then
         log_info "Using cached \"${cached_archive}\" for ${C_MAGENTA}${C_BOLD}${url}${C_INFO} ..."
         # we are in a tmp dir
         cachable_path=""

         if ! _archive_test "${cached_archive}" || \
            ! validate_download "${cached_archive}" "${sourceoptions}"
         then
            remove_file_if_present "${cached_archive}"
            cached_archive=""
         else
            exekutor ln -s "${cached_archive}" "${download}" || fail "failed to symlink \"${cached_archive}\""
            return 0
         fi
      fi
   fi

   echo "${cached_archive}"
   echo "${cachable_path}"
   echo "${OPTION_CACHE_DIR}"

   return 1
}


#
# What we do is
# a) download the package using curl
# b) optionally copy it into a cache for next time
# c) create a temporary directory, extract into it
# d) move it into place
#
_tar_download()
{
   log_entry "_tar_download" "$@"

   local download="$1"  # where we expect the file to be
   local url="$2"
   local sourceoptions="$3"

   local results

   results="`archive_cache_grab "${url}" "${download}"`"
   if [ $? -eq 0 ]
   then
      return 0
   fi

   local archive_cache
   local cachable_path
   local cached_archive

   cached_archive="`echo "${results}" | sed -n '1p'`"
   cachable_path="`echo "${results}"  | sed -n '2p'`"
   archive_cache="`echo "${results}"  | sed -n '3p'`"

   #
   # local urls don't need to be curled
   #
   local curlit

   curlit="NO"
   case "${url}" in
      file:*)
         url="`source_check_file_url "${url}"`"
         [ $? -eq 0 ] || return 1
      ;;

      *:*)
         curlit="YES"
      ;;

      *)
         url="`source_check_file_url "${url}"`"
         [ $? -eq 0 ] || return 1
      ;;
   esac

   if [ -z "${cached_archive}" ]
   then
      archive_download "${url}" "${download}" "${curlit}" "${sourceoptions}"
   fi

   [ -f "${download}" ] || internal_fail "expected file \"${download}\" is mising"

   if [ -z "${cached_archive}" -a ! -z "${cachable_path}" ]
   then
      log_verbose "Caching \"${url}\" as \"${cachable_path}\" ..."
      mkdir_if_missing "${archive_cache}" || fail "failed to create archive cache \"${archive_cache}\""
      exekutor cp "${download}" "${cachable_path}" || fail "failed to copy \"${download}\" to \"${cachable_path}\""
   fi
}

###
### PLUGIN API
###

tar_clone_project()
{
   log_entry "tar_clone_project" "$@"

   [ $# -lt 8 ] && internal_fail "parameters missing"

   local unused="$1"
   local name="$2"            # name of the clone
   local url="$3"             # URL of the clone
   local branch="$4"          # branch of the clone
   local tag="$5"             # tag to checkout of the clone
   local sourcetype="$6"          # source to use for this clone
   local sourceoptions="$7"   # options to use on source
   local dstdir="$8"          # dstdir of this clone (absolute or relative to $PWD)

   local tmpdir
   local archive
   local download
   local options
   local archivename
   local directory

   # fixup github
   download="`basename -- "${url}"`"
   archive="${download}"

   # remove .tar (or .zip et friends)
   archivename="`extensionless_basename "${download}"`"
   case "${archivename}" in
      *.tar)
         archivename="`extensionless_basename "${archivename}"`"
      ;;
   esac

   rmdir_safer "${name}.tmp"
   tmpdir="`exekutor mktemp -d "${name}.XXXXXXXX"`" || return 1
   (
      exekutor cd "${tmpdir}" || return 1

      _tar_download "${download}" "${url}" "${sourceoptions}" || return 1

      _tar_unpack "${download}" "${sourceoptions}" || return 1
      exekutor rm "${download}" || return 1
   ) || return 1

   archive_move_stuff "${tmpdir}" "${dstdir}" "${archivename}" "${name}"
}


tar_search_local_project()
{
   log_entry "tar_search_local_project" "$@"

   archive_search_local "$@"
}


tar_guess_project()
{
   log_entry "tar_guess_project" "$@"

   local url="$3"             # URL of the clone

   archive_guess_name_from_url "${url}" ".tar"
}


tar_plugin_initialize()
{
   log_entry "tar_plugin_initialize"

   if [ -z "${MULLE_FETCH_ARCHIVE_SH}" ]
   then
      # shellcheck source=src/mulle-fetch-archive.sh
      . "${MULLE_FETCH_LIBEXEC_DIR}/mulle-fetch-archive.sh" || exit 1
   fi
}

tar_plugin_initialize

:
