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

r_find_best_directory()
{
   local directory="$1"

   local count
   local filenames

   filenames="`ls -1A "${directory}" 2> /dev/null`"
   if [ -z "${filenames}" ]
   then
      RVAL="${directory}"
      return
   fi

   count="`printf "%s\n" "${filenames}" | wc -l`"
   if [ "${count}" -ne 1 ]
   then
      RVAL="${directory}"
      return
   fi

   #
   # Only one file here. Is it another directory ?
   # If yes enter the rabbit hole
   #
   local next

   next="${directory}/${filenames}"
   if [ -d "${next}" ]
   then
      r_find_best_directory "${next}"
      next="${RVAL}"
   fi

   RVAL="${next}"
}


tar_remove_extension()
{
   local ext="$1"

   if [ ! -z "${ext}" ]
   then
      case "${MULLE_UNAME}" in
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
      if [ "${noclobber}" = 'NO' ]
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
   [ ! -e "${dstdir}" ] || internal_fail "destination must not exist"

   toremove="${tmpdir}"

   src="${tmpdir}/${archivename}"
   if [ ! -d "${src}" ]
   then
      src="${tmpdir}/${name}"
      if [ ! -d "${src}" ]
      then
         r_find_best_directory "${tmpdir}"
         src="${RVAL}"
         if [ "${src}" = "${tmpdir}" ]
         then
            toremove=""
         fi
      fi
   fi

   log_debug "Moving \"${src}\" to \"${dstdir}\""
#   log_trace "src: `ls -lR "${src}" `"

   exekutor mv "${src}" "${dstdir}"

   if [ ! -z "${toremove}" ]
   then
      rmdir_safer "${toremove}"
   fi
}


r_archive_search_local()
{
   log_entry "r_archive_search_local" "$@"

   local directory="$1"
   local name="$2"
   local filename="$3"

   [ $# -ne 3 ] && internal_fail "fail"

   local found

   found="${directory}/${name}-${filename}"
   log_fluff "Looking for archive \"${found}\""
   if [ -f "${found}" ]
   then
      log_fluff "Found \"${name}\" in \"${directory}\" as \"${found}\""

      RVAL="${found}"
      return 0
   fi

   found="${directory}/${filename}"
   log_fluff "Looking for archive \"${found}\""
   if [ -f "${found}" ]
   then
      log_fluff "Found \"${name}\" in \"${directory}\" as \"${found}\""

      RVAL="${found}"
      return 0
   fi

   RVAL=""
   return 1
}


archive_search_local()
{
   log_entry "archive_search_local" "$@"

#   local unused="$1"
   local name="$2"
   local url="$3"
#   local branch="$3"

   local filename
   r_basename "${url}"
   filename="${RVAL}"

   local found
   local directory

   set -f ; IFS=':'
   for directory in ${MULLE_FETCH_SEARCH_PATH}
   do
      set +f; IFS="${DEFAULT_IFS}"

      if [ -z "${directory}" ]
      then
         continue
      fi

      r_archive_search_local "${directory}" "${name}" "${filename}" || exit 1
      found="${RVAL}"
      if [ ! -z "${found}" ]
      then
         r_absolutepath "${found}"
         found="${RVAL}"
         echo "file://${found}"
         return 0
      fi
   done

   set +f; IFS="${DEFAULT_IFS}"

   return 1
}


archive_guess_name_from_url()
{
   log_entry "archive_guess_name_from_url" "$@"

   local url="$1"             # URL of the clone
   local ext="$2"

   local urlpath
   local archivename
   local tmp

   urlpath="`url_get_path "${url}"`"

   case "${urlpath}" in
      */tarball/*|*/zipball/*)
         r_dirname "${urlpath}"
         r_dirname "${RVAL}"
         r_basename "${RVAL}"
         printf "%s\n" "${RVAL}"
         return
      ;;
   esac

   #
   # remove version info or such
   # these "hacks" should move into some kind of plugin scheme
   #
   case "${url}" in
      *github.com/*)
         r_dirname "${urlpath}"
         r_dirname "${RVAL}"
         r_basename "${RVAL}"
         printf "%s\n" "${RVAL}"
         return
      ;;

      *gitlab.com/*)
         tmp="${urlpath#*gitlab.com/}" # remove scheme and host
         tmp="${tmp#*/}" # remove org or user
         printf "%s\n" "${tmp%%/*}" # grab that entry
         return
      ;;
   esac

   # remove .tar (or .zip et friends)
   archivename="`extensionless_basename "${urlpath}"`"
   case "${archivename}" in
      *${ext})
         r_extensionless_basename "${archivename}"
         archivename="${RVAL}"
      ;;
   esac

   local name

   # remove version info if present
   sed 's/[-]*[0-9]*\.[0-9]*\.[0-9]*[-]*//' <<< "${archivename}"
}


:
