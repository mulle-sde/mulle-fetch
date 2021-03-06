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
MULLE_FETCH_SOURCE_SH="included"


#
# prints each key=value on a line so that its greppable
# TODO: Doesn't do escaping yet
#
parse_sourceoptions()
{
   log_entry "parse_sourceoptions" "$@"

   local sourceoptions="$1"

   local key
   local value

   while [ ! -z "${sourceoptions}" ]
   do
      # ignore single comma
      case "${sourceoptions}" in
         ,*)
            sourceoptions="${sourceoptions#,}"
            continue
         ;;
      esac

      key="`sed -n 's/^\([a-zA-Z_][a-zA-Z0-9_]*\)=.*/\1/p' <<< "${sourceoptions}"`"
      if [ -z "${key}" ]
      then
         fail "Unparsable sourceoption \"${sourceoptions}\""
         exit 1
      fi
      sourceoptions="${sourceoptions#${key}=}"

      value="`sed -n 's/\([^,]*\),.*/\1/p' <<< "${sourceoptions}"`"
      if [ -z "${value}" ]
      then
         value="${sourceoptions}"
         sourceoptions=""
      else
         sourceoptions="${sourceoptions#${value},}"
      fi

      printf "%s\n" "${key}=${value}"
   done
}


get_sourceoption()
{
   local sourceoptions="$1"
   local key="$2"

   sed -n "s/^${key}="'\(.*\)/\1/p' <<< "${sourceoptions}"
}


r_get_source_function()
{
   log_entry "r_get_source_function" "$@"

   local sourcetype="$1"
   local opname="$2"

   [ -z "$1" -o -z "$2" ] && internal_fail "parameter is empty"

   local operation
   local funcname

   funcname="${opname//-/_}"
   operation="${sourcetype}_${funcname}_project"
   if [ "`type -t "${operation}"`" != "function" ]
   then
      log_verbose "Operation \"${opname}\" is not provided by \"${sourcetype}\" \
(function \"$operation\" is missing)"
      RVAL=
      return 1
   fi
   RVAL="${operation}"
}


source_validate_file_url()
{
   log_entry "source_validate_file_url" "$@"

   local url="$1"

   case "${url}" in
      /*)
      ;;

      file://*)
         url="${url:7}"
      ;;

      *)
         return 1
      ;;
   esac

   log_fluff "Looking for \"${url}\" in filesystem"

   [ -e "${url}" ]
}


source_check_file_url()
{
   log_entry "source_check_file_url" "$@"

   local url="$1"

   if ! source_validate_file_url "${url}"
   then
      log_error "\"${url}\" does not exist ($PWD)"
      return 1
   fi

   return 0
}


r_source_search_local_test_directory()
{
   log_entry "r_source_search_local_test_directory" "$@"

   local directory="$1"
   local name="$2"

   local dirpath

   r_filepath_concat "${directory}" "${name}"
   dirpath="${RVAL}"

   RVAL=""
   log_fluff "Looking for local \"${dirpath}\""

   if [ -d "${dirpath}" ]
   then
      log_fluff "Found \"${name}\" in \"${directory}\""
      RVAL="${dirpath}"
      return 0
   fi

   return 1
}


r_source_search_local()
{
   log_entry "r_source_search_local" "$@"

   local directory="$1"; shift
   local url="$1"; shift

   local name="$1"
   local branch="$2"
   local extension="$3"
   local need_extension="$4"

   local found

   if [ "${MULLE_FLAG_LOG_SETTINGS}" = 'YES' ]
   then
      log_trace2 "directory      : ${directory}"
      log_trace2 "url            : ${url}"
      log_trace2 "branch         : ${branch}"
      log_trace2 "name           : ${name}"
      log_trace2 "extension      : ${extension}"
      log_trace2 "need_extension : ${need_extension}"
   fi

   RVAL=
   if source_validate_file_url "${url}"
   then
      log_fluff "Local \"${url}\" matches"
      RVAL="${url:7}"
      return 0
   fi

   local inhibit

   inhibit="${directory}/.mulle/etc/fetch/no-search"
   if [ -f "${inhibit}" ]
   then
      log_fluff "\"${directory}\" inhibited by \"${inhibit}\""
      return 1
   fi

   if [ ! -z "${branch}" ]
   then
      if r_source_search_local_test_directory "${directory}" "${name}.${branch}${extension}"
      then
         return 0
      fi
   fi

   if r_source_search_local_test_directory "${directory}" "${name}${extension}"
   then
      return 0
   fi

   if [ "${need_extension}" != 'YES' ]
   then
      if r_source_search_local_test_directory "${directory}" "${name}"
      then
         return 0
      fi
   fi

   log_debug "Found nothing locally for \"${name}\""
   return 1
}


r_source_search_local_path()
{
   log_entry "r_source_search_local_path [${MULLE_FETCH_SEARCH_PATH}]" "$@"

   local name="$1"
   local branch="$2"
   local extension="$3"
   local required="$4"
   local url="$5"

   local found
   local directory
   local realdir
   local curdir

   [ -z "${name}" ] && internal_fail "empty name"

   log_debug "MULLE_FETCH_SEARCH_PATH is \"${MULLE_FETCH_SEARCH_PATH}\""

   curdir="`pwd -P`"
   set -f ; IFS=':'
   for directory in ${MULLE_FETCH_SEARCH_PATH}
   do
      set +o noglob; IFS="${DEFAULT_IFS}"

      if [ -z "${directory}" ]
      then
         continue
      fi

      if [ ! -d "${directory}" ]
      then
         log_debug "Local path \"${directory}\" does not exist, continuing"
         continue
      fi

      realdir="`realpath "${directory}"`"
      if [ "${realdir}" = "${curdir}" ]
      then
         fail "Search path mistakenly contains \"${directory}\", which is \
the current directory"
      fi


      if r_source_search_local "${realdir}" "${url}" "$@"
      then
         return 0
      fi
   done

   set +o noglob; IFS="${DEFAULT_IFS}"

   return 1
}


source_operation()
{
   log_entry "source_operation" "$@"

   local opname="$1" ; shift

   local unused="$1"
   local name="$2"            # name of the clone
   local url="$3"             # URL of the clone
   local branch="$4"          # branch of the clone
   local tag="$5"             # tag to checkout of the clone
   local sourcetype="$6"      # source to use for this clone
   local sourceoptions="$7"   # options to use on source
   local dstdir="$8"          # dstdir of this clone (absolute or relative to $PWD)

   local operation

   r_get_source_function "${sourcetype}" "${opname}"
   operation="${RVAL}"
   if [ -z "${operation}" ]
   then
      return 111
   fi

   local parsed_sourceoptions

   parsed_sourceoptions="`parse_sourceoptions "${sourceoptions}" `" || exit 1

   "${operation}" "${unused}" \
                  "${name}" \
                  "${url}" \
                  "${branch}" \
                  "${tag}" \
                  "${sourcetype}" \
                  "${parsed_sourceoptions}" \
                  "${dstdir}"
}


source_prepare_filesystem_for_fetch()
{
   log_entry "source_prepare_for_fetch" "$@"

   if [ -e "${dstdir}" ]
   then
      if [ "${MULLE_FLAG_MAGNUM_FORCE}" != 'NO' ]
      then
         fail "\"${dstdir}\" already exists"
      fi
      rmdir_safer "${dstdir}" || exit 1
   fi

   r_mkdir_parent_if_missing "${dstdir}"
}


source_guess_project()
{
   log_entry "source_guess_project" "$@"

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


source_download()
{
   log_entry "source_download" "$@"

   local url="$1"
   local download="$2"
   local sourceoptions="$3"

   local options

   [ -z "${MULLE_FETCH_CURL_SH}" ] && \
      . "${MULLE_FETCH_LIBEXEC_DIR}/mulle-fetch-curl.sh"

   #
   # local urls don't need to be curled
   #
   local curlit

   curlit='YES'
   case "${url}" in
      file://*)
         source_check_file_url "${url}"  || return 1
         url="${url:7}"
         curlit='NO'
      ;;

      *:*)
      ;;

      *)
         if source_check_file_url "${url}"
         then
            curlit='NO'
         fi
      ;;
   esac

   if [ "${curlit}" = 'YES' ]
   then
      curl_download "${url}" "${download}" "${sourceoptions}" \
         || fail "failed to download \"${url}\""
   else
      if [ "${url}" != "${download}" ]
      then
         case "${MULLE_UNAME}" in
            mingw)
               log_fluff "Copying local archive \"${download}\" to \"${url}\""
               exekutor cp -rA "${url}" "${download}" || exit 1
            ;;

            *)
               log_fluff "Symlinking local archive \"${download}\" to \"${url}\""
               exekutor ln -s "${url}" "${download}" || exit 1
            ;;
         esac
      fi
   fi

   if ! curl_validate_download "${download}" "${sourceoptions}"
   then
      remove_file_if_present "${download}"
      fail "Can't download archive from \"${url}\""
   fi
}



source_url_exists()
{
   log_entry "source_url_exists" "$@"

   local url="$1"

   #
   # local urls don't need to be curled
   #
   case "${url}" in
      file://*)
         source_validate_file_url "${url}"
         return $?
      ;;

      *:*)
      ;;

      *)
         if source_validate_file_url "${url}"
         then
            return 0
         fi
      ;;
   esac

   [ -z "${MULLE_FETCH_CURL_SH}" ] && \
      . "${MULLE_FETCH_LIBEXEC_DIR}/mulle-fetch-curl.sh"

   curl_exists "${url}"
}


:
