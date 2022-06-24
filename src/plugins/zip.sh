#! /usr/bin/env bash
#
#   Copyright (c) 2015 Nat! - Mulle kybernetiK
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
MULLE_FETCH_PLUGIN_ZIP_SH="included"


fetch::plugin::zip::fetch_project()
{
   log_entry "fetch::plugin::zip::fetch_project" "$@"

   [ $# -lt 8 ] && _internal_fail "parameters missing"

   local unused="$1"
   local name="$2"            # name of the clone
   local url="$3"             # URL of the clone
   local branch="$4"          # branch of the clone
   local tag="$5"             # tag to checkout of the clone
   local sourcetype="$6"      # source to use for this clone
   local sourceoptions="$7"   # options to use on source
   local dstdir="$8"          # dstdir of this clone (absolute or relative to $PWD)

   log_info "Fetching ${C_MAGENTA}${C_BOLD}${name}${C_INFO} from ${C_RESET_BOLD}${url}${C_INFO}."

   fetch::source::prepare_filesystem_for_fetch "${dstdir}"

   local tmpdir
   local download
   local archivename

   download="`basename --  "${url}"`"
   r_extensionless_basename "${download}"
   archivename="${RVAL}"

   r_make_tmp_directory || exit 1
   tmpdir="${RVAL}"
   (
      exekutor cd "${tmpdir}" || return 1

      fetch::source::download "${url}" "${download}" "${sourceoptions}" "${curlit}"
      log_verbose "Extracting ${C_MAGENTA}${C_BOLD}${download}${C_INFO} ..."

      exekutor unzip -q ${OPTION_TOOL_FLAGS} "${download}" || return 1
      exekutor rm "${download}"
   ) || return 1

   fetch::archive::move_stuff "${tmpdir}" "${dstdir}" "${archivename}" "${name}"
}


fetch::plugin::zip::search_local_project()
{
   log_entry "fetch::plugin::zip::search_local_project" "$@"

   fetch::archive::search_local "$@"
}


fetch::plugin::zip::exists_project()
{
   log_entry "fetch::plugin::zip::exists_project" "$@"

   local url="$3"             # URL of the clone

   fetch::source::url_exists "${url}"
}


fetch::plugin::zip::guess_project()
{
   log_entry "fetch::plugin::zip::guess_project" "$@"

   local url="$3"             # URL of the clone

   rexekutor "${MULLE_DOMAIN:-mulle-domain}" nameguess "${url}"
}


fetch::plugin::zip::initialize()
{
   log_entry "fetch::plugin::zip::initialize"

   if [ -z "${MULLE_FETCH_ARCHIVE_SH}" ]
   then
      # shellcheck source=src/mulle-fetch-archive.sh
      . "${MULLE_FETCH_LIBEXEC_DIR}/mulle-fetch-archive.sh" || exit 1
   fi
}


fetch::plugin::zip::initialize

:
