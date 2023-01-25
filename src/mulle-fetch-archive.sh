# shellcheck shell=bash
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

fetch::archive::r_find_best_directory()
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
      fetch::archive::r_find_best_directory "${next}"
      next="${RVAL}"
   fi

   RVAL="${next}"
}


fetch::archive::tar_remove_extension()
{
   local ext="$1"

   if [ ! -z "${ext}" ]
   then
      case "${MULLE_UNAME}" in
         'darwin'|*'bsd'|'dragonfly')
            echo "-s/\.$1\$//"
         ;;

         'linux'|'mingw'|'msys')
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
fetch::archive::archive_files()
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
         exekutor "${TAR:-tar}" -c ${taroptions} -f - -T -
   ) || exit 1
}



fetch::archive::unarchive_files()
{
   local dstdir="$1"
   local noclobber="$2"

   [ -d "${dstdir}" ] || fail "${dstdir} does not exist"

   (
      exekutor cd "${dstdir}" ;
      if [ "${noclobber}" = 'NO' ]
      then
         exekutor "${TAR:-tar}" -x ${TARFLAGS} -f -
      else
         exekutor "${TAR:-tar}" -x ${TARFLAGS} -k -f -
      fi
      :  # ignore trashy tar rval
   )  2> /dev/null
}


fetch::archive::move_stuff()
{
   log_entry "fetch::archive::move_stuff" "$@"

   local tmpdir="$1"
   local dstdir="$2"
   local archivename="$3"
   local name="$4"

   local src
   local toremove
   [ ! -e "${dstdir}" ] || _internal_fail "destination must not exist"

   toremove="${tmpdir}"

   src="${tmpdir}/${archivename}"
   if [ ! -d "${src}" ]
   then
      src="${tmpdir}/${name}"
      if [ ! -d "${src}" ]
      then
         fetch::archive::r_find_best_directory "${tmpdir}"
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


fetch::archive::r_search_local()
{
   log_entry "fetch::archive::r_search_local" "$@"

   local directory="$1"
   local name="$2"
   local filename="$3"

   [ $# -ne 3 ] && _internal_fail "fail"

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


fetch::archive::search_local()
{
   log_entry "fetch::archive::search_local" "$@"

#   local unused="$1"
   local name="$2"
   local url="$3"
#   local branch="$3"

   local filename

   r_basename "${url}"
   filename="${RVAL}"

   local found
   local directory

   .foreachpath directory in ${MULLE_FETCH_SEARCH_PATH}
   .do
      if [ -z "${directory}" ]
      then
         .continue
      fi

      fetch::archive::r_search_local "${directory}" "${name}" "${filename}" || exit 1
      found="${RVAL}"

      if [ ! -z "${found}" ]
      then
         r_absolutepath "${found}"
         found="${RVAL}"
         echo "file://${found}"
         return 0
      fi
   .done

   return 1
}

:
