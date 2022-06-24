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
fetch::plugin::svn::fetch_project()
{
   [ $# -lt 8 ] && _internal_fail "parameters missing"

   local unused="$1"
   local name="$2"
   local url="$3"
   local branch="$4"
   local tag="$5"
   local sourcetype="$6"
   local sourceoptions="$7"
   local dstdir="$8"

   shift 8

   _log_info "Fetching ${C_MAGENTA}${C_BOLD}${name}${C_INFO} from \
${C_RESET_BOLD}${url}${C_INFO}."

   fetch::source::prepare_filesystem_for_fetch "${dstdir}"

   local options

   if [ ! -z "${sourceoptions}" ]
   then
      options="`fetch::source::get_option "${sourceoptions}" "clone"`"
   fi

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


fetch::plugin::svn::update_project()
{
   [ $# -lt 8 ] && _internal_fail "parameters missing"

   local unused="$1"
   local name="$2"
   local url="$3"
   local branch="$4"
   local tag="$5"
   local sourcetype="$6"
   local sourceoptions="$7"
   local dstdir="$8"

   shift 8

   local options

   if [ ! -z "${sourceoptions}" ]
   then
      options="`fetch::source::get_option "${sourceoptions}" "update"`"
   fi

   [ ! -z "${dstdir}" ] || _internal_fail "dstdir is empty"

   log_info "SVN updating ${C_MAGENTA}${C_BOLD}${dstdir}${C_INFO} ..."

   if [ ! -z "$branch" ]
   then
      r_concat "-r ${branch}" "${options}"
      options="${RVAL}"
   else
      if [ ! -z "$tag" ]
      then
         r_concat "-r ${tag}" "${options}"
         options="${RVAL}"
      fi
   fi

   (
      exekutor cd "${dstdir}" ;
      exekutor svn ${OPTION_TOOL_FLAGS} update ${options} ${OPTION_TOOL_OPTIONS}  >&2
   ) || fail "svn update of \"${dstdir}\" failed"
}


fetch::plugin::svn::status_project()
{
   [ $# -lt 8 ] && _internal_fail "parameters missing"

   local unused="$1"
   local name="$2"
   local url="$3"
   local branch="$4"
   local tag="$5"
   local sourcetype="$6"
   local sourceoptions="$7"
   local dstdir="$8"

   shift 8

   local options

   if [ ! -z "${sourceoptions}" ]
   then
      options="`fetch::source::get_option "${sourceoptions}" "status"`"
   fi

   [ ! -z "${dstdir}" ] || _internal_fail "dstdir is empty"

   (
      exekutor cd "${dstdir}" ;
      exekutor svn status ${options} ${sourceoptions} "$@" ${OPTION_TOOL_OPTIONS}  >&2
   ) || fail "svn update of \"${dstdir}\" failed"
}


fetch::plugin::svn::search_local_project()
{
   log_entry "fetch::plugin::svn::search_local_project [${MULLE_FETCH_SEARCH_PATH}]" "$@"

#   local unused="$1"
   local name="$2"
   local url="$3"
   local branch="$4"

   if fetch::source::r_search_local_in_searchpath "${name}" "${branch}" ".svn" 'YES' "${url}"
   then
      printf "%s\n" "${RVAL}"
   fi
}


fetch::plugin::svn::exists_project()
{
   log_entry "fetch::plugin::svn::exists_project" "$@"

   local url="$3"             # URL of the clone

   fetch::source::url_exists "${url}"
}


fetch::plugin::svn::guess_project()
{
   log_entry "fetch::plugin::svn::guess_project" "$@"

   local url="$3"             # URL of the clone

   if [ -z "${MULLE_FETCH_URL_SH}" ]
   then
      # shellcheck source=src/mulle-fetch-archive.sh
      . "${MULLE_FETCH_LIBEXEC_DIR}/mulle-fetch-url.sh" || exit 1
   fi

   r_url_get_path "${url}"
   r_extensionless_basename "${RVAL}"
   printf "%s\n" "${RVAL}"
}

