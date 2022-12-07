# shellcheck shell=bash
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


fetch::curl::validate_shasum256()
{
   log_entry "fetch::curl::validate_shasum256" "$@"

   local filename="$1"
   local expected="$2"

   case "${MULLE_UNAME}" in
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

   checksum="`${shasum} -a 256 "${filename}" | awk '{ print $1 }'`" || exit 1
   if [ "${expected}" != "${checksum}" ]
   then
      log_error "${filename} sha256 is ${checksum}, not ${expected} as expected"
      return 1
   fi
   log_fluff "shasum did validate \"${filename}\""
}


fetch::curl::validate_download()
{
   log_entry "fetch::curl::validate_download" "$@"

   local filename="$1"
   local sourceoptions="$2"

   local checksum
   local expected

   if [ ! -z "${sourceoptions}" ]
   then
      expected="`fetch::source::get_option "${sourceoptions}" "shasum256"`"
      if [ -z "${expected}" ]
      then
         return
      fi

      fetch::curl::validate_shasum256 "${filename}" "${expected}"
   fi
}


fetch::curl::wget_download()
{
   log_entry "fetch::curl::wget_download" "$@"

   local url="$1"
   local download="$2"
   local sourceoptions="$3"

   WGET="${WGET:-`command -v wget`}"
   if [ -z "${WGET}" ]
   then
      fail "Neither \"curl\" nor \"wget\" are installed. Can not fetch anything."
   fi

   local options

   if [ ! -z "${sourceoptions}" ]
   then
      options="`fetch::source::get_option "${sourceoptions}" "wget"`"
   fi

   local defaultflags

   defaultflags="-nv"
   if [ "${MULLE_FLAG_LOG_VERBOSE}" = 'YES' ]
   then
      defaultflags=""
   fi

   exekutor ${WGET} ${OPTION_WGET_FLAGS:-${defaultflags}} \
               -O "${download:--}" \
               ${options} \
               "${url}" || fail "failed to download \"${url}\""
}


fetch::curl::wget_exists()
{
   log_entry "fetch::curl::wget_exists" "$@"

   local url="$1"
   local download="$2"

   WGET="${WGET:-`command -v wget`}"
   if [ -z "${WGET}" ]
   then
      fail "Neither \"curl\" nor \"wget\" are installed. Can not fetch anything."
   fi

   local defaultflags

   defaultflags="-nv"
   if [ "${MULLE_FLAG_LOG_VERBOSE}" = 'YES' ]
   then
      defaultflags=""
   fi

   exekutor ${WGET} --spider "${url}" 2>/dev/null
}


fetch::curl::download()
{
   log_entry "fetch::curl::download" "$@"

   local url="$1"
   local download="$2"
   local sourceoptions="$3"

   log_verbose "Downloading ${C_MAGENTA}${C_BOLD}${url}${C_INFO} ..."

   CURL="${CURL:-`command -v curl`}"
   if [ -z "${CURL}" ]
   then
      fetch::curl::wget_download "$1" "$2" "$3"
      return $?
   fi

   local options

   if [ ! -z "${sourceoptions}" ]
   then
      options="`fetch::source::get_option "${sourceoptions}" "curl"`"
   fi

   local defaultflags

   defaultflags="-fsSL"
   if [ "${MULLE_FLAG_LOG_VERBOSE}" = 'YES' ]
   then
      defaultflags="-fSL"
   fi

   if [ ! -z "${download}" ]
   then
      exekutor ${CURL} ${OPTION_CURL_FLAGS:-${defaultflags}} \
                  -o "${download}" \
                  -L \
                  ${options} \
                  "${url}" || fail "failed to download \"${url}\""
   else
      exekutor ${CURL} ${OPTION_CURL_FLAGS:-${defaultflags}} \
                  -O \
                  -L \
                  ${options} \
                  "${url}" || fail "failed to download \"${url}\""
   fi
}


# https://stackoverflow.com/questions/12199059/how-to-check-if-an-url-exists-with-the-shell-and-probably-curl#
fetch::curl::curl_exists()
{
   log_entry "fetch::curl::curl_exists" "$@"

   local url="$1"

   log_verbose "Checking ${C_MAGENTA}${C_BOLD}${url}${C_INFO} ..."

   CURL="${CURL:-`command -v curl`}"
   if [ -z "${CURL}" ]
   then
      fetch::curl::wget_exists "$@"
      return $?
   fi

   local defaultflags

   defaultflags="-fsSL"
   if [ "${MULLE_FLAG_LOG_VERBOSE}" = 'YES' ]
   then
      defaultflags="-fSL"
   fi

   exekutor ${CURL} ${OPTION_CURL_FLAGS:-${defaultflags}} \
               --output /dev/null -r 0-0 "${url}"
}



:
