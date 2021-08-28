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
MULLE_FETCH_PLUGIN_SCM_TAR_SH="included"


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

   case "${MULLE_UNAME}" in
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

   case "${MULLE_UNAME}" in
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

   if [ ! -z "${sourceoptions}" ]
   then
      options="`get_sourceoption "${sourceoptions}" "tar"`"
   fi

   exekutor tar ${OPTION_TOOL_FLAGS} ${tarcommand} ${OPTION_TOOL_OPTIONS} ${options} "${archive}" || return 1
}


#
# returns in
#
#  _cached_archive
#  _cachable_path
#  _archive_cache
#
archive_cache_grab()
{
   log_entry "archive_cache_grab" "$@"

   local url="$1"
   local download="$2"
   local sourceoptions="$3"

   [ -z "${url}" ]      && internal_fail "url is empty"
   [ -z "${download}" ] && internal_fail "download is empty"

   _cachable_path=""
   _cached_archive=""
   _archive_cache=""

   if [ -z "${MULLE_FETCH_ARCHIVE_DIR}" ]
   then
      log_fluff "Caching not active as MULLE_FETCH_ARCHIVE_DIR is empty"
      return 4
   fi

   local filename
   local directory

   # fix for github
   case "${url}" in
      *github.com*/archive/*)
         r_dirname "${url}"  # remove 3.9.2
         r_dirname "${RVAL}" # remove archives
         directory="${RVAL}"

         r_basename "${directory}"
         filename="${RVAL}-${download}"
      ;;

      *)
         filename="${download}"
      ;;
   esac

   # tar and zip can share a cache due to file extension
   _archive_cache="${MULLE_FETCH_ARCHIVE_DIR}"
   _cachable_path="${_archive_cache}/${filename}"

   #
   # if refresh is yes, ignore cache
   # default is to use the cache
   #
   case "${OPTION_REFRESH}" in
      "")
         internal_fail "illegal OPTION_REFRESH value"
      ;;

      DEFAULT|NO)
         if [ -f "${_cachable_path}" ]
         then
            _cached_archive="${_cachable_path}"
         fi

         if [ ! -z "${_cached_archive}" ]
         then
            log_info "Using cached \"${_cached_archive/#${HOME}/~}\" for ${C_MAGENTA}${C_BOLD}${url}${C_INFO} ..."
            # we are in a tmp dir
            _cachable_path=""

            if [ -z "${MULLE_FETCH_CURL_SH}" ]
            then
               # shellcheck source=src/mulle-fetch-archive.sh
               . "${MULLE_FETCH_LIBEXEC_DIR}/mulle-fetch-curl.sh" || exit 1
            fi

            if ! _archive_test "${_cached_archive}" || \
               ! curl_validate_download "${_cached_archive}" "${sourceoptions}"
            then
               remove_file_if_present "${_cached_archive}"
               _cached_archive=""
            else
               exekutor ln -s "${_cached_archive}" "${download}" || fail "failed to symlink \"${_cached_archive}\""
               return 0
            fi
         fi
      ;;
   esac

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

   local url="$1"
   local download="$2"  # where we expect the file to be
   local sourceoptions="$3"

   local _cachable_path
   local _cached_archive
   local _archive_cache

   if archive_cache_grab  "${url}" "${download}" "${sourceoptions}"
   then
      return 0
   fi

   if [ -z "${_cached_archive}" ]
   then
      source_download "${url}" "${download}" "${sourceoptions}"
   fi

   [ -e "${download}" ] || internal_fail "expected file \"${download}\" is missing"

   if [ -z "${_cached_archive}" -a ! -z "${_cachable_path}" ]
   then
      log_verbose "Caching \"${url}\" as \"${_cachable_path}\" ..."
      mkdir_if_missing "${_archive_cache}" || fail "failed to create archive cache \"${_archive_cache}\""
      exekutor cp "${download}" "${_cachable_path}" || fail "failed to copy \"${download}\" to \"${_cachable_path}\""
   else
      log_fluff "Not caching the archive"
   fi
}


###
### PLUGIN API
###

tar_fetch_project()
{
   log_entry "tar_fetch_project" "$@"

   [ $# -lt 8 ] && internal_fail "parameters missing"

   local unused="$1"
   local name="$2"            # name of the clone
   local url="$3"             # URL of the clone
   local branch="$4"          # branch of the clone
   local tag="$5"             # tag to checkout of the clone
   local sourcetype="$6"      # source to use for this clone
   local sourceoptions="$7"   # options to use on source
   local dstdir="$8"          # dstdir of this clone (absolute or relative to $PWD)

   log_info "Fetching ${C_MAGENTA}${C_BOLD}${name}${C_INFO} from \
${C_RESET_BOLD}${url}${C_INFO}."

   source_prepare_filesystem_for_fetch "${dstdir}"

   local tmpdir
   local archive
   local download
   local options
   local archivename
   local directory

   # fixup github
   r_basename "${url}"
   download="${RVAL}"
   archive="${download}"

   # remove .tar (or .zip et friends)
   r_extensionless_basename "${download}"
   archivename="${RVAL}"
   case "${archivename}" in
      *.tar)
         r_extensionless_basename "${archivename}"
         archivename="${RVAL}"
      ;;
   esac

   r_make_tmp_directory || exit 1
   tmpdir="${RVAL}"
   (
      exekutor cd "${tmpdir}" || return 1

      _tar_download "${url}" "${download}" "${sourceoptions}" || return 1

      _tar_unpack "${download}" "${sourceoptions}" || return 1
      exekutor rm "${download}" || return 1
   ) || return 1

   archive_move_stuff "${tmpdir}" "${dstdir}" "${archivename}" "${name}"
}


tar_search_local_project()
{
   log_entry "tar_search_local_project" "$@"

#   local unused="$1"
   local name="$2"
   local url="$3"
   local branch="$4"
#   local tag="$5"
#   local sourcetype="$6"
#   local sourceoptions="$7"
#   local dstdir="$8"

   #  look for a git repo of same name (or a local project)
   if r_source_search_local_in_searchpath "${name}" "${branch}" ".git" 'NO' "${url}"
   then
      printf "%s\n" "${RVAL}"
      return
   fi

   archive_search_local "$@"
}


tar_exists_project()
{
   log_entry "tar_exists_project" "$@"

   local url="$3"             # URL of the clone

   source_url_exists "${url}"
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
