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
MULLE_FETCH_PLUGIN_SYMLINK_SH="included"


###
### PLUGIN API
###

symlink_clone_project()
{
#   local unused="$1"
#   local name="$2"         # name of the clone
   local url="$3"           # URL of the clone
   local branch="$4"        # branch of the clone
   local tag="$5"           # tag to checkout of the clone
#   local sourcetype="$6"          # source to use for this clone
#   local sourceoptions="$7"   # options to use on source
   local dstdir="$8"      # dstdir of this clone (absolute or relative to $PWD)

   if ! exekutor create_symlink "${url}" "${dstdir}" "${OPTION_ABSOLUTE_SYMLINKS:-NO}"
   then
      return 1
   fi

   local branchlabel

   branchlabel="branch"
   if [ -z "${branch}" -a ! -z "${tag}" ]
   then
      branchlabel="tag"
      branch="${tag}"
   fi

   if [ "${branch}" != "master" -a ! -z "${branch}" ]
   then
      log_warning "The intended ${branchlabel} ${C_RESET_BOLD}${branch}${C_WARNING_TEXT} \
will be ignored, because the repository is symlinked.
If you want to checkout this ${branchlabel} do:
   ${C_RESET}(cd ${dstdir}; git checkout ${OPTION_TOOL_OPTIONS} \"${branch}\" )${C_WARNING}"
   fi
}


symlink_search_local_project()
{
   log_entry "symlink_search_local_project [${OPTION_SEARCH_PATH}]" "$@"

   local url="$1"
   local name="$2"
   local branch="$3"

   source_search_local_path "${name}" "${branch}" "" "YES"
}



symlink_guess_project()
{
   log_entry "symlink_guess_project" "$@"

   local url="$3"             # URL of the clone

   if [ -z "${MULLE_FETCH_URL_SH}" ]
   then
      # shellcheck source=src/mulle-fetch-archive.sh
      . "${MULLE_FETCH_LIBEXEC_DIR}/mulle-fetch-url.sh" || exit 1
   fi

   local urlpath

   urlpath="`url_get_path "${url}"`"
   basename -- "${urlpath}"
}
