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
MULLE_FETCH_SOURCE_SH="included"


#
# prints each key=value on a line so that its greppable
# TODO: Doesn't do escaping yet
#
fetch::source::r_parse_options()
{
   log_entry "fetch::source::r_parse_options" "$@"

   local sourceoptions="$1"

   local key
   local value

   local lines

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

      r_add_line "${lines}" "${key}=${value}"
      lines="${RVAL}"
   done

   RVAL="${lines}"
}


fetch::source::get_option()
{
   local sourceoptions="$1"
   local key="$2"

   sed -n "s/^${key}="'\(.*\)/\1/p' <<< "${sourceoptions}"
}


fetch::source::r_get_plugin_function()
{
   log_entry "fetch::source::r_get_plugin_function" "$@"

   local sourcetype="$1"
   local opname="$2"

   [ -z "$1" -o -z "$2" ] && _internal_fail "parameter is empty"

   local operation
   local funcname

   funcname="${opname//-/_}"

   fetch::plugin::load "${sourcetype}"

   operation="fetch::plugin::${sourcetype}::${funcname}_project"
   if ! shell_is_function "${operation}"
   then
      _log_verbose "Operation \"${opname}\" is not provided by \"${sourcetype}\" \
(function \"$operation\" is missing)"
      RVAL=
      return 1
   fi
   RVAL="${operation}"
}


fetch::source::validate_file_url()
{
   log_entry "fetch::source::validate_file_url" "$@"

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


fetch::source::check_file_url()
{
   log_entry "fetch::source::check_file_url" "$@"

   local url="$1"

   if ! fetch::source::validate_file_url "${url}"
   then
      log_error "\"${url}\" does not exist (${PWD#"${MULLE_USER_PWD}/"})"
      return 1
   fi

   return 0
}


fetch::source::r_search_local_exists_directory()
{
   log_entry "fetch::source::r_search_local_exists_directory" "$@"

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


fetch::source::r_search_local()
{
   log_entry "fetch::source::r_search_local" "$@"

   local directory="$1"
   local repo="$2"
   shift 2

   local name="$1"
   local branch="$2"
   local extension="$3"
   local need_extension="$4"

   RVAL=

   log_setting "directory      : ${directory}"
   log_setting "repo           : ${repo}"

   log_verbose "Looking for local repo \"${repo}\" in \"${directory#"${MULLE_USER_PWD}/"}\""

   local inhibit

   inhibit="${directory}/.mulle/etc/fetch/no-search"
   if [ -f "${inhibit}" ]
   then
      log_fluff "\"${directory}\" inhibited by \"${inhibit}\""
      return 1
   fi

   if [ ! -z "${branch}" ]
   then
      if fetch::source::r_search_local_exists_directory "${directory}" \
                                                        "${repo}.${branch}${extension}"
      then
         return 0
      fi
   fi

   # this search part can often be avoided if repo is foo.git and extension
   # is also .git
   if [ "${repo%.*}${extension}" != "${repo}" ]
   then
      if fetch::source::r_search_local_exists_directory "${directory}" \
                                                        "${repo}${extension}"
      then
         return 0
      fi
   fi

   if [ "${need_extension}" != 'YES' ]
   then
      if fetch::source::r_search_local_exists_directory "${directory}" "${repo}"
      then
         return 0
      fi
   fi

   return 1
}


fetch::source::r_search_local_in_searchpath()
{
   log_entry "fetch::source::r_search_local_in_searchpath [${MULLE_FETCH_SEARCH_PATH}]" "$@"

   local name="$1"
   local branch="$2"
   local extension="$3"
   local required="$4"
   local url="$5"

   local found
   local directory
   local realdir

   [ -z "${url}" ] && _internal_fail "empty url"

   log_debug "MULLE_FETCH_SEARCH_PATH is \"${MULLE_FETCH_SEARCH_PATH}\""

   if fetch::source::validate_file_url "${url}"
   then
      log_fluff "Local \"${url}\" matches"
      RVAL="${url#*:/}"
      return 0
   fi

   # short-cut to avoid mulle-domain call
   [ -z "${MULLE_FETCH_SEARCH_PATH}" ] && return 1

   local repo

   repo="`rexekutor "${MULLE_DOMAIN:-mulle-domain}" nameguess "${url}" `"
   if [ -z "${repo}" ]
   then
      return 1
   fi

   local curdir

   .foreachpath directory in ${MULLE_FETCH_SEARCH_PATH}
   .do
      if [ -z "${directory}" ]
      then
         .continue
      fi

      if [ ! -d "${directory}" ]
      then
         log_debug "Local path \"${directory}\" does not exist: skipping"
         .continue
      fi

      r_realpath "${directory}"
      realdir="${RVAL}"

      curdir="${curdir:-`pwd -P`}"
      if [ "${realdir}" = "${curdir}" ]
      then
         _log_warning "Search path mistakenly contains \"${directory}\", which is \
the current directory: skipping"
         .continue
      fi

      if fetch::source::r_search_local "${realdir}" "${repo}" "$@"
      then
         return 0
      fi
   .done

   return 1
}

#
# move actual operation to the proper scm plugin like maybe git.sh
#
fetch::source::operation()
{
   log_entry "fetch::source::operation" "$@"

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

   fetch::source::r_get_plugin_function "${sourcetype}" "${opname}"
   operation="${RVAL}"
   if [ -z "${operation}" ]
   then
      return 111
   fi

   local parsed_sourceoptions

   fetch::source::r_parse_options "${sourceoptions}"
   parsed_sourceoptions="${RVAL}"

   "${operation}" "${unused}" \
                  "${name}" \
                  "${url}" \
                  "${branch}" \
                  "${tag}" \
                  "${sourcetype}" \
                  "${parsed_sourceoptions}" \
                  "${dstdir}"
}


fetch::source::prepare_filesystem_for_fetch()
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


fetch::source::guess_project()
{
   log_entry "fetch::source::guess_project" "$@"

   local url="$3"             # URL of the clone

   r_url_get_path "${url}"
   r_basename "${RVAL}"
   printf "%s\n" "${RVAL}"
}


fetch::source::download()
{
   log_entry "fetch::source::download" "$@"

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
         fetch::source::check_file_url "${url}"  || return 1
         url="${url:7}"
         curlit='NO'
      ;;

      *:*)
      ;;

      *)
         if fetch::source::check_file_url "${url}"
         then
            curlit='NO'
         fi
      ;;
   esac

   if [ "${curlit}" = 'YES' ]
   then
      fetch::curl::download "${url}" "${download}" "${sourceoptions}" \
         || fail "failed to download \"${url}\""
   else
      if [ "${url}" != "${download}" ]
      then
         case "${MULLE_UNAME}" in
            mingw)
               log_fluff "Copying local archive \"${download}\" to \"${url}\""
               exekutor cp -Rp "${url}" "${download}" || exit 1
            ;;

            *)
               log_fluff "Symlinking local archive \"${download}\" to \"${url}\""
               exekutor ln -s "${url}" "${download}" || exit 1
            ;;
         esac
      fi
   fi

   if ! fetch::curl::validate_download "${download}" "${sourceoptions}"
   then
      remove_file_if_present "${download}"
      fail "Can't download archive from \"${url}\""
   fi
}


fetch::source::url_exists()
{
   log_entry "fetch::source::url_exists" "$@"

   local url="$1"

   #
   # local urls don't need to be curled
   #
   case "${url}" in
      file://*)
         fetch::source::validate_file_url "${url}"
         return $?
      ;;

      *:*)
      ;;

      *)
         if fetch::source::validate_file_url "${url}"
         then
            return 0
         fi
      ;;
   esac

   [ -z "${MULLE_FETCH_CURL_SH}" ] && \
      . "${MULLE_FETCH_LIBEXEC_DIR}/mulle-fetch-curl.sh"

   fetch::curl::curl_exists "${url}"
}


:
