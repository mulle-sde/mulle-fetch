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


zip_clone_project()
{
   log_entry "zip_clone_project" "$@"

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
   local download
   local archivename

   download="`basename --  "${url}"`"
   archivename="`extension_less_basename "${download}"`"


   #
   # local urls don't need to be curled
   #
   local curlit

   curlit="NO"
   case "${url}" in
      file:*)
         ! source_check_file_url "${url}" && return $?
      ;;

      *:*)
         curlit="YES"
      ;;

      *)
         ! source_check_file_url "${url}" && return $?
      ;;
   esac

   rmdir_safer "${name}.tmp"
   tmpdir="`exekutor mktemp -d "${name}.XXXXXXXX"`" || exit 1
   (
      exekutor cd "${tmpdir}" || return 1

      if [ "${curlit}" = "YES" ]
      then
         log_info "Downloading ${C_MAGENTA}${C_BOLD}${url}${C_INFO} ..."

         exekutor curl -O -L ${options} ${CURLOPTIONS} "${url}" || fail "failed to download \"${url}\""
      else
         if [ "${url}" != "${download}" ]
         then
            case "${UNAME}" in
               mingw)
                  exekutor cp "${url}" "${download}"
               ;;

               *)
                  exekutor ln -s "${url}" "${download}"
               ;;
            esac
         fi
      fi

      validate_download "${download}" "${sourceoptions}" || return 1

      log_verbose "Extracting ${C_MAGENTA}${C_BOLD}${download}${C_INFO} ..."

      exekutor unzip -q "${download}" >&2 || return 1
      exekutor rm "${download}"
   ) || return 1

   archive_move_stuff "${tmpdir}" "${dstdir}" "${archivename}" "${name}"
}


zip_search_local_project()
{
   log_entry "zip_clone_project" "$@"

   archive_search_local "$@"
}
