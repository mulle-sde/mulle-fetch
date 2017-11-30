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
MULLE_FETCH_PLUGIN_SVN_SH="included"


###
### PLUGIN API
###

#
# if svn wants to use MULLE_FETCH_MIRROR_DIR, it should
# make a svn subdirectory
#
svn_clone_project()
{
   [ $# -lt 8 ] && internal_fail "parameters missing"

   local unused="$1" ; shift
   local name="$1"; shift
   local url="$1"; shift
   local branch="$1"; shift
   local tag="$1"; shift
   local sourcetype="$1"; shift
   local sourceoptions="$1"; shift
   local dstdir="$1"; shift

   source_prepare_filesystem_for_fetch "${dstdir}"

   local options

   options="`get_sourceoption "${sourceoptions}" "clone"`"

   if [ ! -z "${tag}" ]
   then
      log_info "SVN checkout revision ${C_RESET_BOLD}${tag}${C_INFO} of ${C_MAGENTA}${C_BOLD}${url}${C_INFO} ..."
      options="`concat "${options}" "-r ${tag}"`"
   else
      log_info "SVN checkout ${C_MAGENTA}${C_BOLD}${url}${C_INFO} ..."
   fi

   options="`concat "-q" "${options}"`"

   if ! exekutor svn ${OPTION_TOOL_FLAGS} checkout ${options} "$@" ${OPTION_TOOL_OPTIONS} "${url}" "${dstdir}"  >&2
   then
      log_error "svn clone of \"${url}\" into \"${dstdir}\" failed"
      return 1
   fi
}


svn_update_project()
{
   [ $# -lt 8 ] && internal_fail "parameters missing"

   local unused="$1" ; shift
   local name="$1"; shift
   local url="$1"; shift
   local branch="$1"; shift
   local tag="$1"; shift
   local sourcetype="$1"; shift
   local sourceoptions="$1"; shift
   local dstdir="$1"; shift

   local options

   options="`get_sourceoption "${sourceoptions}" "update"`"

   [ ! -z "${dstdir}" ] || internal_fail "dstdir is empty"

   log_info "SVN updating ${C_MAGENTA}${C_BOLD}${dstdir}${C_INFO} ..."

   if [ ! -z "$branch" ]
   then
      options="`concat "-r ${branch}" "${options}"`"
   else
      if [ ! -z "$tag" ]
      then
         options="`concat "-r ${tag}" "${options}"`"
      fi
   fi

   (
      exekutor cd "${dstdir}" ;
      exekutor svn ${OPTION_TOOL_FLAGS} update ${options} ${OPTION_TOOL_OPTIONS}  >&2
   ) || fail "svn update of \"${dstdir}\" failed"
}


svn_status_project()
{
   [ $# -lt 8 ] && internal_fail "parameters missing"

   local unused="$1" ; shift
   local name="$1"; shift
   local url="$1"; shift
   local branch="$1"; shift
   local tag="$1"; shift
   local sourcetype="$1"; shift
   local sourceoptions="$1"; shift
   local dstdir="$1"; shift

   local options

   options="`get_sourceoption "${sourceoptions}" "status"`"

   [ ! -z "${dstdir}" ] || internal_fail "dstdir is empty"

   (
      exekutor cd "${dstdir}" ;
      exekutor svn status ${options} ${sourceoptions} "$@" ${OPTION_TOOL_OPTIONS}  >&2
   ) || fail "svn update of \"${dstdir}\" failed"
}


svn_search_local_project()
{
   log_entry "git_search_local_project [${MULLE_FETCH_SEARCH_PATH}]" "$@"

   local url="$1"
   local name="$2"
   local branch="$3"

   source_search_local_path "${name}" "${branch}" ".svn" "YES"
}


svn_guess_project()
{
   log_entry "svn_guess_project" "$@"

   local url="$3"             # URL of the clone

   if [ -z "${MULLE_FETCH_URL_SH}" ]
   then
      # shellcheck source=src/mulle-fetch-archive.sh
      . "${MULLE_FETCH_LIBEXEC_DIR}/mulle-fetch-url.sh" || exit 1
   fi

   local urlpath
   local archivename
   local name

   urlpath="`url_get_path "${url}"`"

   name="`basename -- "${urlpath}"`"
   name="`extensionless_basename "${name}"`"

   echo "${name}"
}

