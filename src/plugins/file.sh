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
MULLE_FETCH_PLUGIN_FILE_SH="included"


#
# What we do is
# a) download the file using curl
# b) move it into place
#
_file_download()
{
   log_entry "_file_download" "$@"

   local download="$1"  # where we expect the file to be
   local url="$2"
   local sourceoptions="$3"

   source_download "${url}" "${download}" "${sourceoptions}"

   [ -f "${download}" ] || internal_fail "expected file \"${download}\" is mising"
}


###
### PLUGIN API
###

file_fetch_project()
{
   log_entry "file_fetch_project" "$@"

   [ $# -lt 8 ] && internal_fail "parameters missing"

   local unused="$1"
   local name="$2"            # name of the clone
   local url="$3"             # URL of the clone
   local branch="$4"          # branch of the clone
   local tag="$5"             # tag to checkout of the clone
   local sourcetype="$6"      # source to use for this clone
   local sourceoptions="$7"   # options to use on source
   local destination="$8"     # destination of file (absolute or relative to $PWD)

   log_info "Fetching ${C_MAGENTA}${C_BOLD}${name}${C_INFO} from \
${C_RESET_BOLD}${url}${C_INFO}."

   local dstdir

   r_fast_dirname "${destination}"
   dstdir="${RVAL}"

   mkdir_if_missing "${dstdir}" || return 1

   local download

   r_fast_basename "${destination}"
   download="${RVAL}"
   (
      exekutor cd "${dstdir}" &&
      source_download "${url}" "${download}" "${sourceoptions}"
   ) || return 1
}



file_guess_project()
{
   log_entry "file_guess_project" "$@"

   local url="$3"             # URL of the clone

   local urlpath

   urlpath="`url_get_path "${url}"`"

   basename -- "${urlpath}"
}

:
