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
MULLE_FETCH_CURL_SH="included"


curl_validate_shasum256()
{
   log_entry "curl_validate_shasum256" "$@"

   local filename="$1"
   local expected="$2"

   case "${UNAME}" in
      mingw)
         log_fluff "mingw does not support shasum" # or does it ?
         return
      ;;
   esac

   local shasum

   shasum="${SHASUM}"
   if [ -z "${shasum}" ]
   then
      shasum="`command -v shasum`"
   fi

   [ -z "${shasum}" ] && fail "shasum is not in PATH"

   local checksum

   checksum="`${shasum} -a 256 -p "${filename}" | awk '{ print $1 }'`"
   if [ "${expected}" != "${checksum}" ]
   then
      log_error "${filename} sha256 is ${checksum}, not ${expected} as expected"
      return 1
   fi
   log_fluff "shasum did validate \"${filename}\""
}


curl_validate_download()
{
   log_entry "curl_validate_download" "$@"

   local filename="$1"
   local sourceoptions="$2"

   local checksum
   local expected

   expected="`get_sourceoption "$sourceoptions" "shasum256"`"
   if [ -z "${expected}" ]
   then
      return
   fi

   curl_validate_shasum256 "${filename}" "${expected}"
}


curl_download()
{
   log_entry "curl_download" "$@"

   local url="$1"
   local download="$2"
   local sourceoptions="$3"

   local options

   log_info "Downloading ${C_MAGENTA}${C_BOLD}${url}${C_INFO} ..."

   options="`get_sourceoption "${sourceoptions}" "curl"`"
   exekutor curl ${OPTION_CURL_FLAGS} \
               -o "${download}" \
               -O -L \
               ${options} \
               "${url}" || fail "failed to download \"${url}\""
}



: