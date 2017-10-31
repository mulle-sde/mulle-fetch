#! /usr/bin/env bash
#
#   Copyright (c) 2015-2017 Nat! - Mulle kybernetiK
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
MULLE_FETCH_ARCHIVE_SH="included"

find_single_directory_in_directory()
{
   local count
   local filename

   filename="`ls -1 "${tmpdir}"`"

   count="`echo "$filename}" | wc -l`"
   if [ $count -ne 1 ]
   then
      return
   fi

   echo "${tmpdir}/${filename}"
}


tar_remove_extension()
{
   local ext="$1"

   if [ ! -z "${ext}" ]
   then
      case "${UNAME}" in
         darwin|freebsd)
            echo "-s/\.$1\$//"
         ;;

         linux|mingw*)
            echo "--transform s/\.$1\$//"
         ;;

         *)
            echo "--transform /\.$1\$//"
         ;;
      esac
   fi
}


#
# dstdir need not exist
# srcdir must exist
# ext can be empty
# noclobber can be empty=NO,NO or YES
#
_archive_files()
{
   local srcdir="$1"
   local ext="$2"
   local taroptions="$3"

   (
      exekutor cd "${srcdir}" ;
      if [ -z "${ext}" ]
      then
         exekutor find . \( -type f -a ! -name "*.*" \) -print
      else
         exekutor find . \( -type f -a -name "*.${ext}" \) -print
      fi |
         exekutor tar -c ${taroptions} -f - -T -
   ) || exit 1
}



_unarchive_files()
{
   local dstdir="$1"
   local noclobber="$2"

   [ -d "${dstdir}" ] || fail "${dstdir} does not exist"

   (
      exekutor cd "${dstdir}" ;
      if [ "${noclobber}" = "NO" ]
      then
         exekutor tar -x ${TARFLAGS} -f -
      else
         exekutor tar -x ${TARFLAGS} -k -f -
      fi
      :  # ignore trashy tar rval
   )  2> /dev/null
}


archive_move_stuff()
{
   log_entry "archive_move_stuff" "$@"

   local tmpdir="$1"
   local dstdir="$2"
   local archivename="$3"
   local name="$4"

   local src
   local toremove

   toremove="${tmpdir}"

   src="${tmpdir}/${archivename}"
   if [ ! -d "${src}" ]
   then
      src="${tmpdir}/${name}"
      if [ ! -d "${src}" ]
      then
         src="`find_single_directory_in_directory "${tmpdir}"`"
         if [ -z "${src}" ]
         then
            src="${tmpdir}"
            toremove=""
         fi
      fi
   fi

   exekutor mv "${src}" "${dstdir}"

   if [ ! -z "${toremove}" ]
   then
      rmdir_safer "${toremove}"
   fi
}


_archive_search_local()
{
   log_entry "_archive_search_local" "$@"

   local directory="$1"
   local name="$2"
   local filename="$3"

   [ $# -ne 3 ] && internal_fail "fail"

   local found

   found="${directory}/${name}-${filename}"
   log_fluff "Looking for \"${found}\""
   if [ -f "${found}" ]
   then
      log_fluff "Found \"${name}\" in \"${directory}\" as \"${found}\""

      echo "${found}"
      return
   fi

   found="${directory}/${filename}"
   log_fluff "Looking for \"${found}\""
   if [ -f "${found}" ]
   then
      log_fluff "Found \"${name}\" in \"${directory}\" as \"${found}\""

      echo "${found}"
      return
   fi
}


archive_search_local()
{
   log_entry "archive_search_local" "$@"

   local url="$1"
   local name="$2"
#   local branch="$3"

   local filename

   filename="`basename -- "${url}"`"

   local found
   local directory

   IFS=":"
   for directory in ${OPTION_SEARCH_PATH}
   do
      IFS="${DEFAULT_IFS}"

      found="`_archive_search_local "${directory}" "${name}" "${filename}"`" || exit 1
      if [ ! -z "${found}" ]
      then
         found="`absolutepath "${found}"`"
         echo "file:///${found}"
         return 0
      fi
   done

   IFS="${DEFAULT_IFS}"
   return 1
}


validate_shasum256()
{
   log_entry "validate_shasum256" "$@"

   local filename="$1"
   local expected="$2"

   case "${UNAME}" in
      mingw)
         log_fluff "mingw does not support shasum" # or does it ?
         return
      ;;
   esac


   local checksum

   checksum="`shasum -a 256 -p "${filename}" | awk '{ print $1 }'`"
   if [ "${expected}" != "${checksum}" ]
   then
      log_error "${filename} sha256 is ${checksum}, not ${expected} as expected"
      return 1
   fi
   log_fluff "shasum256 did validate \"${filename}\""
}


validate_download()
{
   log_entry "validate_download" "$@"

   local filename="$1"
   local sourceoptions="$2"

   local checksum
   local expected

   expected="`get_sourceoption "$sourceoptions" "shasum256"`"
   if [ -z "${expected}" ]
   then
      return
   fi

   validate_shasum256 "${filename}" "${expected}"
}

:
