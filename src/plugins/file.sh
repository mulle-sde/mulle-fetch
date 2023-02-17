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
MULLE_FETCH_PLUGIN_FILE_SH='included'


#
# What we do is
# a) download the file using curl
# b) move it into place
#
fetch::plugin::file::download()
{
   log_entry "fetch::plugin::file::download" "$@"

   local download="$1"  # where we expect the file to be
   local url="$2"
   local sourceoptions="$3"

   fetch::source::download "${url}" "${download}" "${sourceoptions}"

   if [ ! -f "${download}" ] 
   then
      if [ ! -e "${download}" ] 
      then
         _internal_fail "expected file \"${download}\" is missing"
      else
         _internal_fail "expected file \"${download}\" is not a file"
      fi
   fi
}


###
### PLUGIN API
###

fetch::plugin::file::fetch_project()
{
   log_entry "fetch::plugin::file::fetch_project" "$@"

   [ $# -lt 8 ] && _internal_fail "parameters missing"

   local unused="$1"
   local name="$2"            # name of the clone
   local url="$3"             # URL of the clone
   local branch="$4"          # branch of the clone
   local tag="$5"             # tag to checkout of the clone
   local sourcetype="$6"      # source to use for this clone
   local sourceoptions="$7"   # options to use on source
   local destination="$8"     # destination of file (absolute or relative to $PWD)

   _log_info "Fetching ${C_MAGENTA}${C_BOLD}${name}${C_INFO} from \
${C_RESET_BOLD}${url}${C_INFO}."

   local dstdir

   r_dirname "${destination}"
   dstdir="${RVAL}"

   mkdir_if_missing "${dstdir}" || return 1

   local download

   r_basename "${destination}"
   download="${RVAL}"
   (
      exekutor cd "${dstdir}" &&
      fetch::source::download "${url}" "${download}" "${sourceoptions}"
   ) || return 1
}


fetch::plugin::file::exists_project()
{
   log_entry "fetch::plugin::file::exists_project" "$@"

   local url="$3"             # URL of the clone

   fetch::source::validate_file_url "${url}"
}


fetch::plugin::file::guess_project()
{
   log_entry "fetch::plugin::file::guess_project" "$@"

   local url="$3"             # URL of the clone

   include "fetch::url"

   r_url_get_path "${url}"
   r_basename "${RVAL}"
   printf "%s\n" "${RVAL}"
}

:
