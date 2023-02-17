#! /usr/bin/env bash
#
#   Copyright (c) 2023 Nat! - Mulle kybernetiK
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
MULLE_FETCH_PLUGIN_CLIB_SH='included'


###
### Plugin API
###

fetch::plugin::clib::fetch_project()
{
   log_entry "fetch::plugin::clib::fetch_project" "$@"

#   local unused="$1"
   local name="$2"             # name of the clone
   local url="$3"              # URL of the clone
#   local branch="$4"          # branch of the clone
   local tag="$5"              # tag to checkout of the clone
#   local sourcetype="$6"      # source to use for this clone
#   local sourceoptions="$7"   # options to use on source
   local dstdir="$8"           # destination of file (absolute or relative to $PWD)

   _log_info "Fetching ${C_MAGENTA}${C_BOLD}${name}${C_INFO} from \
${C_RESET_BOLD}${url}${C_INFO}."

   fetch::plugin::clib::checkout_project "$@"
   return $?
}


fetch::plugin::clib::checkout_project()
{
   log_entry "fetch::plugin::clib::checkout_project" "$@"

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

   [ -z "${dstdir}" ] && _internal_fail "dstdir is empty"

   if [ ! -z "${tag}" -o ! -z "${branch}" ]
   then
      _log_warning "Branch ${C_RESET_BOLD}${branch}${C_WARNING} and \
tag ${C_RESET_BOLD}${tag}${C_WARNING} information of \
${C_MAGENTA}${C_BOLD}${name}${C_WARNING} ignored by clib"
   fi

   r_dirname "${dstdir}"
   exekutor clib ${OPTION_TOOL_FLAGS} install --out "${RVAL}" ${name} >&2
}


#  aka fetch
fetch::plugin::clib::update_project()
{
   log_entry "fetch::plugin::clib::update_project" "$@"

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

   return 0
}


#  aka pull
fetch::plugin::clib::upgrade_project()
{
   log_entry "fetch::plugin::clib::upgrade_project" "$@"

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

   log_info "Updating ${C_MAGENTA}${C_BOLD}${dstdir}${C_INFO} ..."

   r_dirname "${dstdir}"
   exekutor clib ${OPTION_TOOL_FLAGS} update --out "${RVAL}" ${name} >&2
}



fetch::plugin::clib::status_project()
{
   log_entry "fetch::plugin::clib::status_project" "$@"

   [ $# -lt 8 ] && _internal_fail "parameters missing"

   return 0
}


fetch::plugin::clib::set_url_project()
{
   log_entry "fetch::plugin::clib::set_url_project" "$@"

   return 1
}


fetch::plugin::clib::search_local_project()
{
   log_entry "fetch::plugin::clib::search_local_project [${MULLE_FETCH_SEARCH_PATH}]" "$@"

#   local unused="$1"
   local name="$2"
   local url="$3"
   local branch="$4"
#   local tag="$5"
#   local sourcetype="$6"
#   local sourceoptions="$7"
#   local dstdir="$8"

   if fetch::source::r_search_local_in_searchpath "${name}" "${branch}" "" 'NO' "${url}"
   then
      echo ${RVAL}
      return 0
   fi

   return 1
}


fetch::plugin::clib::exists_project()
{
   log_entry "fetch::plugin::clib::exists_project" "$@"

   fetch::source::url_exists "${url}"
}


fetch::plugin::clib::guess_project()
{
   log_entry "fetch::plugin::clib::guess_project" "$@"

   local url="$3"      # URL of the clone

   include "fetch::url"

   r_url_get_path "${url}"
   r_extensionless_basename "${RVAL}"
   printf "%s\n" "${RVAL}"
}


fetch::plugin::clib::initialize()
{
   log_entry "fetch::plugin::clib::initialize"

   fetch::plugin::load_if_needed "symlink"
}


fetch::plugin::clib::initialize

:
