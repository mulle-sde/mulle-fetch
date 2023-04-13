#! /usr/bin/env bash
#
#   Copyright (c) 2023 Nat! - Mulle kybernetiK
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
MULLE_FETCH_PLUGIN_CLIB_SH='included'


###
### Plugin API
###

fetch::plugin::clib::fetch_project()
{
   log_entry "fetch::plugin::clib::fetch_project" "$@"

#   local unused="$1"
   local name="$2"             # name of the clone
   local url="$3"              # URL of the clone
#   local branch="$4"          # branch of the clone
   local tag="$5"              # tag to checkout of the clone
#   local sourcetype="$6"      # source to use for this clone
#   local sourceoptions="$7"   # options to use on source
   local dstdir="$8"           # destination of file (absolute or relative to $PWD)

   _log_info "Fetching ${C_MAGENTA}${C_BOLD}${name}${C_INFO} from \
${C_RESET_BOLD}${url}${C_INFO}."

   fetch::plugin::clib::checkout_project "$@"
   return $?
}


fetch::plugin::clib::checkout_project()
{
   log_entry "fetch::plugin::clib::checkout_project" "$@"

   [ $# -lt 8 ] && _internal_fail "parameters missing"

   local unused="$1"
   local name="$2"
   local url="$3"
   local branch="$4"
   local tag="$5"
   local sourcetype="$6"
   local sourceoptions="$7"
   local dstdir="$8"

   shift 8

   [ -z "${dstdir}" ] && _internal_fail "dstdir is empty"

   if [ ! -z "${tag}" ]
   then
      _log_warning "Tag ${C_RESET_BOLD}${tag}${C_WARNING} information of \
${C_MAGENTA}${C_BOLD}${name}${C_WARNING} ignored by clib"
   fi

   if ! CLIB="`${CLIB:-command -v clib}`"
   then
      fail "clib is not installed"
   fi

   local user_repo
   local rval

   user_repo="${url#clib:}"
   if [ ! -z "${branch}" ]
   then
      user_repo="${user_repo%@*}"
      user_repo="${user_repo}@${branch}"
   fi

   r_dirname "${dstdir}"
   exekutor ${CLIB} ${OPTION_TOOL_FLAGS} install --out "${RVAL}" "${user_repo}" >&2
   rval=$?
   log_debug "clib returns with: $rval"

   if [ $rval -ne 0 ]
   then
      fail "${CLIB} could not checkout \"${user_repo}\""
   fi
   return 0
}


#  aka fetch
fetch::plugin::clib::update_project()
{
   log_entry "fetch::plugin::clib::update_project" "$@"

   [ $# -lt 8 ] && _internal_fail "parameters missing"

   local unused="$1"
   local name="$2"
   local url="$3"
   local branch="$4"
   local tag="$5"
   local sourcetype="$6"
   local sourceoptions="$7"
   local dstdir="$8"

   shift 8

   return 0
}


#  aka pull
fetch::plugin::clib::upgrade_project()
{
   log_entry "fetch::plugin::clib::upgrade_project" "$@"

   [ $# -lt 8 ] && _internal_fail "parameters missing"

   local unused="$1"
   local name="$2"
   local url="$3"
   local branch="$4"
   local tag="$5"
   local sourcetype="$6"
   local sourceoptions="$7"
   local dstdir="$8"

   shift 8

   log_info "Updating ${C_MAGENTA}${C_BOLD}${dstdir}${C_INFO} ..."

   local user_repo

   user_repo="${url#clib:}"

   r_dirname "${dstdir}"

   if ! CLIB="`${CLIB:-command -v clib}`"
   then
      fail "clib is not installed"
   fi

   exekutor "${CLIB}" ${OPTION_TOOL_FLAGS} update --out "${RVAL}" ${user_repo} >&2
}



fetch::plugin::clib::status_project()
{
   log_entry "fetch::plugin::clib::status_project" "$@"

   [ $# -lt 8 ] && _internal_fail "parameters missing"

   return 0
}


fetch::plugin::clib::set_url_project()
{
   log_entry "fetch::plugin::clib::set_url_project" "$@"

   return 1
}


fetch::plugin::clib::search_local_project()
{
   log_entry "fetch::plugin::clib::search_local_project [${MULLE_FETCH_SEARCH_PATH}]" "$@"

#   local unused="$1"
   local name="$2"
   local url="$3"
#   local branch="$4"
#   local tag="$5"
#   local sourcetype="$6"
#   local sourceoptions="$7"
#   local dstdir="$8"

   # remove branch info
   url="${url%@*}"
   if fetch::source::r_search_local_in_searchpath "${name}" "" "" 'NO' "${url}"
   then
      if [ -f "${RVAL}/clib.json" ]
      then
         printf "%s\n" "${RVAL}"
         return 0
      fi
   fi

   log_verbose "No clib.json found in \"${RVAL}\""
   return 1
}


fetch::plugin::clib::exists_project()
{
   log_entry "fetch::plugin::clib::exists_project" "$@"

   fetch::source::url_exists "${url}"
}


fetch::plugin::clib::guess_project()
{
   log_entry "fetch::plugin::clib::guess_project" "$@"

   local url="$3"      # URL of the clone

   include "fetch::url"

   r_url_get_path "${url}"
   r_extensionless_basename "${RVAL}"
   printf "%s\n" "${RVAL}"
}


fetch::plugin::clib::r_get_clib_json_repo_jq()
{
   log_entry "fetch::plugin::clib::r_get_clib_json_repo_jq" "$@"

   local clib_json="$1"

   RVAL="`\
   rexekutor "${JQ}" .repo "${clib_json}" \
   | sed -e 's/^[[:space:]]*"\(.*\)"/\1/' \
         -e 's/\\"/"/g' `"
}




#
# this oughta be more true JSON parsing, being able to parse any valid
# clib
#
fetch::plugin::clib::get_clib_json_files_jq()
{
   log_entry "fetch::plugin::clib::get_clib_json_files_jq" "$@"

   local clib_json="$1"

   rexekutor "${JQ}" .src "${clib_json}" \
   | sed -e '1d; $d' \
         -e 's/^[[:space:]]*"\(.*\)"/\1/' \
         -e 's/\\"/"/g'
}




#
# this may only parse a subset of clib.json, which is "pretty"
#
fetch::plugin::clib::r_get_clib_json_repo_sh()
{
   log_entry "fetch::plugin::clib::r_get_clib_json_repo_sh" "$@"

   local clib_json="$1"

   local line
   local repo

   while IFS=$'\n' read line
   do
      case "${line}" in
         *\"repo\"*\:*)
            RVAL="${RVAL#*:}"
            r_trim_whitespace "${RVAL%,}"
            RVAL="${RVAL#\"}"
            RVAL="${RVAL%\"}"
            r_unescaped_doublequotes "${RVAL}"
            return 0
         ;;
   esac
   done < "${clib_json}"

   RVAL=""
   return 1
}


#
# this may only parse a subset of clib.json, which is "pretty"
#
fetch::plugin::clib::get_clib_json_files_sh()
{
   log_entry "fetch::plugin::clib::get_clib_json_files_sh" "$@"

   local clib_json="$1"

   local line
   local collect
   local repo

   while IFS=$'\n' read line
   do
      case "${line}" in
         *\"src\"*\:*)
            collect='YES'
         ;;

         *\]*)
            collect='NO'
         ;;

         *)
            if [ "${collect}" != 'YES' ]
            then
               continue
            fi

            r_trim_whitespace "${line%,}"
            RVAL="${RVAL#\"}"
            RVAL="${RVAL%\"}"
            r_unescaped_doublequotes "${RVAL}"
            printf "%s\n" "${RVAL}"
         ;;
      esac
   done < "${clib_json}"

   RVAL="${repo}"
}


fetch::plugin::clib::symlink_or_copy()
{
   log_entry "fetch::plugin::clib::symlink_or_copy" "$@"

   local action="$1"
   local url="$2"
   local dstdir="$3"
   local absolute_symlink="${4:-}"
   local hardlink="${5:-}"
   local writeprotect="${6:-}"

   r_absolutepath "${url}"
   url="${RVAL}"

   local clib_json

   r_filepath_concat "${url}" "clib.json"
   clib_json="${RVAL}"

   local files

   JQ="${JQ:-`command -v jq`}"
   if [ ! -z "${JQ}" ]
   then
      fetch::plugin::clib::r_get_clib_json_repo_jq "${clib_json}"
      repo="${RVAL}"
      files="`fetch::plugin::clib::get_clib_json_files_sh "${clib_json}" `"
   else
      fetch::plugin::clib::r_get_clib_json_repo_sh "${clib_json}"
      repo="${RVAL}"
      files="`fetch::plugin::clib::get_clib_json_files_jq "${clib_json}" `"
   fi

   if [ -z "${repo}" ]
   then
      fail "Could not figure out repo from \"${clib_json#${MULLE_USER_PWD}/}\""
   fi

   if [ -z "${files}" ]
   then
      fail "No src files found in \"${clib_json#${MULLE_USER_PWD}/}\""
   fi

   local reponame

   r_basename "${repo}"
   reponame="${RVAL}"

   #
   # the "trick" is that clib flattens the source and stores them
   # in a per-repository subdirectory
   #
   local dstfile
   local srcfile
   local filename
   local linksrc
   local linkdst
   local directory

   r_absolutepath "${dstdir}"
   directory="${RVAL}"

   mkdir_if_missing "${directory}"
   exekutor chmod -R ug+w "${directory}"

   if [ "${action}" != "copy" -a "${hardlink}" = 'YES' ]
   then
      local devsrc
      local devdst

      devsrc="`file_devicenumber "${url}"`"
      devdst="`file_devicenumber "${directory}"`"

      if [ "${devdst}" != "${devsrc}" ]
      then
         log_warning "Can not use hardlinks for cross device links (${url#${MULLE_USER_PWD}/} -> ${directory#${MULLE_USER_PWD}/})"
         action="copy"
      fi
   fi

   if [ "${hardlink}" = 'YES' -a "${MULLE_SDE_SANDBOX_RUNNING}" = 'YES' ]
   then
      log_warning "Can not use hardlinks inside the sandbox (because of sandbox bugs)"
      action="copy"
   fi

   local cmd
   local cmdflags
   local verb

   if [ "${action}" = "copy" ]
   then
      cmd="cp"
      cmdflags=""
      verb="Copy"
   else
      cmd="ln"
      if [ "${hardlink}" = 'YES' ]
      then
         case "${MULLE_UNAME}" in
            linux)
               cmdflags="-f -L"
            ;;

            *)
               cmdflags="-f"
            ;;
         esac
         verb="Hard-link"
         absolute_symlink='YES'
      else
         cmdflags="-f -s"
         verb="Symlink"
      fi
   fi

   log_info "${verb}ing ${C_MAGENTA}${C_BOLD}${reponame}${C_INFO} source files to ${C_RESET_BOLD}${directory#${MULLE_USER_PWD}/}"
   # for hard symlinks we need to be in directory
   (
      .foreachline filename in ${files}
      .do
         r_basename "${filename}"
         linkdst="${RVAL}"
         r_filepath_concat "${directory}" "${linkdst}"
         dstfile="${RVAL}"

         r_filepath_concat "${url}" "${filename}"
         srcfile="${RVAL}"

         log_setting "srcfile: \"${srcfile}\""
         log_setting "dstfile: \"${dstfile}\""

         linksrc="${srcfile}"
         if [ "${action}" = "copy" -o "${absolute_symlink}" = 'YES' ]
         then
            # is already absolute
            :
         else
            r_relative_path_between "${srcfile}" "${directory}"
            linksrc="${RVAL}"
         fi

#         echo "${linksrc}   device: " `stat -c "%d" "${linksrc}"`
#         echo "${directory} device: " `stat -c "%d" "${directory}"`
         exekutor "${cmd}" ${cmdflags} "${linksrc}" "${dstfile}" || exit 1

         if [ "${writeprotect}" = 'YES' ]
         then
            exekutor chmod ugo-w "${dstfile}"
         fi
      .done
   )
}



fetch::plugin::clib::initialize()
{
   log_entry "fetch::plugin::clib::initialize"

   fetch::plugin::load_if_needed "symlink"
}


fetch::plugin::clib::initialize

:
