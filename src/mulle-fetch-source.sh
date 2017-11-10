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

      echo "${key}=${value}"
   done
}


get_sourceoption()
{
   local sourceoptions="$1"
   local key="$2"

   sed -n "s/^${key}="'\(.*\)/\1/p' <<< "${sourceoptions}"
}


get_source_function()
{
   log_entry "get_source_function" "$@"

   local sourcetype="$1"
   local opname="$2"

   [ -z "$1" -o -z "$2" ] && internal_fail "parameter is empty"

   local operation
   local funcname="$2"

   funcname="${opname//-/_}"
   operation="${sourcetype}_${funcname}_project"
   if [ "`type -t "${operation}"`" = "function" ]
   then
      echo "${operation}"
   else
      log_fluff "Function \"${opname}\" is not provided by \"${sourcetype}\" (function \"$operation\" is missing)"
   fi
}


source_check_file_url()
{
   local url="$1"

   case "${url}" in
      file://*)
         url="${url:7}"
      ;;
   esac

   if [ ! -e "${url}" ]
   then
      log_error "\"${url}\" does not exist ($PWD)"
      return 1
   fi
   echo "${url}"
}


source_search_local()
{
   log_entry "source_search_local" "$@"

   local name="$1"
   local branch="$2"
   local extension="$3"
   local need_extension="$4"
   local directory="$5"

   local found

   if [ "${MULLE_FLAG_LOG_LOCALS}" = "YES" ]
   then
      log_trace "Checking local path \"${directory}\""
   fi

   if [ ! -z "${branch}" ]
   then
      found="${directory}/${name}.${branch}${extension}"
      log_fluff "Looking for \"${found}\""

      if [ -d "${found}" ]
      then
         log_fluff "Found \"${name}.${branch}${extension}\" in \"${directory}\""

         echo "${found}"
         return
      fi
   fi

   found="${directory}/${name}${extension}"
   log_fluff "Looking for \"${found}\""
   if [ -d "${found}" ]
   then
      log_fluff "Found \"${name}${extension}\" in \"${directory}\""

      echo "${found}"
      return
   fi

   if [ "${need_extension}" != "YES" ]
   then
      found="${directory}/${name}"
      log_fluff "Looking for \"${found}\""
      if [ -d "${found}" ]
      then
         log_fluff "Found \"${name}\" in \"${directory}\""

         echo "${found}"
         return
      fi
   fi
}


source_search_local_path()
{
   log_entry "source_search_local_path [${OPTION_SEARCH_PATH}]" "$@"

   local name="$1"
   local branch="$2"
   local extension="$3"
   local required="$4"

   local found
   local directory
   local realdir
   local curdir

   [ -z "${name}" ] && internal_fail "empty name"

   if [ "${MULLE_FLAG_LOG_LOCAL}" = "YES" -a -z "${OPTION_SEARCH_PATH}" ]
   then
      log_trace "OPTION_SEARCH_PATH is empty"
   fi

   curdir="`pwd -P`"
   IFS=":"
   for directory in ${OPTION_SEARCH_PATH}
   do
      IFS="${DEFAULT_IFS}"

      if [ ! -d "${directory}" ]
      then
         if [ "${MULLE_FLAG_LOG_LOCALS}" = "YES" ]
         then
            log_trace2 "Local path \"${realdir}\" does not exist"
         fi
         continue
      fi

      realdir="`realpath "${directory}"`"
      if [ "${realdir}" = "${curdir}" ]
      then
         fail "Search path mistakenly contains \"${directory}\", which is the current directory"
      fi

      found="`source_search_local "$@" "${realdir}"`"
      if [ ! -z "${found}" ]
      then
         echo "${found}"
         return
      fi
   done

   IFS="${DEFAULT_IFS}"
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
   local sourcetype="$6"          # source to use for this clone
   local sourceoptions="$7"   # options to use on source
   local dstdir="$8"        # dstdir of this clone (absolute or relative to $PWD)

   local operation

   operation="`get_source_function "${sourcetype}" "${opname}"`"
   if [ -z "${operation}" ]
   then
      return 111
   fi

   local parsed_sourceoptions

   parsed_sourceoptions="`parse_sourceoptions "${sourceoptions}"`" || exit 1

   "${operation}" "${unused}" \
                  "${name}" \
                  "${url}" \
                  "${branch}" \
                  "${tag}" \
                  "${sourcetype}" \
                  "${parsed_sourceoptions}" \
                  "${dstdir}"
}

source_all_plugin_names()
{
   log_entry "source_all_plugin_names"

   local upcase
   local plugindefine
   local pluginpath
   local name

   [ -z "${DEFAULT_IFS}" ] && internal_fail "DEFAULT_IFS not set"
   [ -z "${MULLE_FETCH_LIBEXEC_DIR}" ] && internal_fail "MULLE_FETCH_LIBEXEC_DIR not set"

   IFS="
"
   for pluginpath in `ls -1 "${MULLE_FETCH_LIBEXEC_DIR}/plugins/"*.sh`
   do
      IFS="${DEFAULT_IFS}"

      name="`basename -- "${pluginpath}" .sh`"

      # don't load xcodebuild on non macos platforms
      case "${UNAME}" in
         darwin)
         ;;

         *)
            case "${name}" in
               xcodebuild)
                  continue
               ;;
            esac
         ;;
      esac

      echo "${name}"
   done

   IFS="${DEFAULT_IFS}"
}


_source_list_supported_operations()
{
   local sourcetype="$1"
   local operations="$2"

   local opname
   local operation

   for opname in ${operations}
   do
      funcname="${opname//-/_}"
      operation="${sourcetype}_${funcname}_project"
      if [ "`type -t "${operation}"`" = "function" ]
      then
         echo "${opname}"
      fi
   done
}


source_known_operations()
{
   echo "\
checkout
clone
search-local
set-url
status
update
upgrade"
}


source_list_supported_operations()
{
   _source_list_supported_operations "$1" "`source_known_operations`"
}


source_list_plugins()
{
   log_entry "source_list_plugins"

   local upcase
   local plugindefine
   local pluginpath
   local name

   [ -z "${DEFAULT_IFS}" ] && internal_fail "DEFAULT_IFS not set"
   [ -z "${MULLE_FETCH_LIBEXEC_DIR}" ] && internal_fail "MULLE_FETCH_LIBEXEC_DIR not set"

   log_fluff "List source plugins..."

   IFS="
"
   for pluginpath in `ls -1 "${MULLE_FETCH_LIBEXEC_DIR}/plugins/"*.sh`
   do
      basename -- "${pluginpath}" .sh
   done

   IFS="${DEFAULT_IFS}"
}


source_load_plugins()
{
   log_entry "source_load_plugins"

   local upcase
   local plugindefine
   local pluginpath
   local name

   [ -z "${DEFAULT_IFS}" ] && internal_fail "DEFAULT_IFS not set"
   [ -z "${MULLE_FETCH_LIBEXEC_DIR}" ] && internal_fail "MULLE_FETCH_LIBEXEC_DIR not set"

   log_fluff "Loading source plugins..."

   IFS="
"
   for pluginpath in `ls -1 "${MULLE_FETCH_LIBEXEC_DIR}/plugins/"*.sh`
   do
      IFS="${DEFAULT_IFS}"

      name="`basename -- "${pluginpath}" .sh`"
      upcase="`tr 'a-z' 'A-Z' <<< "${name}"`"
      plugindefine="MULLE_FETCH_PLUGIN_${upcase}_SH"

      if [ -z "`eval echo \$\{${plugindefine}\}`" ]
      then
         # shellcheck source=plugins/symlink.sh
         . "${pluginpath}"

         if [ "`type -t "${name}_clone_project"`" != "function" ]
         then
            fail "Source plugin \"${pluginpath}\" has no \"${name}_clone_project\" function"
         fi

         log_fluff "Source plugin \"${name}\" loaded"
      fi
   done

   IFS="${DEFAULT_IFS}"
}

: