#! /usr/bin/env bash
#
#   Copyright (c) 2015-2018 Nat! - Mulle kybernetiK
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
MULLE_FETCH_PLUGIN_SH="included"


fetch_plugin_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} plugin [options] <command>

   Currently the only command is "list", which lists the installed plugins for
   various source code management (scm) types (e.g. git or tar).

EOF

   exit 1
}


fetch_plugin_all_names()
{
   log_entry "fetch_plugin_all_names" "$@"

   local upcase
   local plugindefine
   local pluginpath
   local name

   [ -z "${DEFAULT_IFS}" ] && internal_fail "DEFAULT_IFS not set"
   [ -z "${MULLE_FETCH_LIBEXEC_DIR}" ] && internal_fail "MULLE_FETCH_LIBEXEC_DIR not set"

   shopt -s nullglob
   IFS=$'\n'; set +f #sic
   for pluginpath in `ls -1 "${MULLE_FETCH_LIBEXEC_DIR}"/plugins/*.sh`
   do
      IFS="${DEFAULT_IFS}"

      name="`basename -- "${pluginpath}" .sh`"

      # don't load xcodebuild on non macos platforms
      case "${MULLE_UNAME}" in
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

      printf "%s\n" "${name}"
   done
   shopt -u nullglob

   IFS="${DEFAULT_IFS}"
}


fetch_plugin_load_if_needed()
{
   log_entry "fetch_plugin_load_if_needed" "$@"

   local name="$1"

   local variable

   r_uppercase "${name}"
   variable="_MULLE_FETCH_PLUGIN_LOADED_${RVAL}"

   if [ "${!variable}" = 'YES' ]
   then
      return 0
   fi

   # shellcheck source=plugins/scm/symlink.sh
   . "${MULLE_FETCH_LIBEXEC_DIR}/plugins/${name}.sh" || exit 1

   eval "${variable}='YES'"

   return 0
}


fetch_plugin_load_if_present()
{
   log_entry "fetch_plugin_load_if_present" "$@"

   local name="$1"

   [ -z "${name}" ] && return 127 # don't warn though, it's boring

   local variable

   r_uppercase "${name}"
   variable="_MULLE_FETCH_PLUGIN_LOADED_${RVAL}"

   if [ "${!variable}" = 'YES' ]
   then
      return 0
   fi

   if [ ! -f "${MULLE_FETCH_LIBEXEC_DIR}/plugins/${name}.sh" ]
   then
      log_verbose "Type \"${name}\" is not supported (no plugin found)"
      return 1
   fi

   # shellcheck source=plugins/scm/symlink.sh
   . "${MULLE_FETCH_LIBEXEC_DIR}/plugins/${name}.sh"

   eval "${variable}='YES'"

   return 0
}



fetch_plugin_load()
{
   log_entry "fetch_plugin_load" "$@"

   local name="$1"

   [ -z "${name}" ] && fail "Empty SCM name"

   if ! fetch_plugin_load_if_present "${name}"
   then
      fail "Type \"${name}\" is not supported (no plugin found)"
   fi
}


fetch_plugin_list()
{
   log_entry "fetch_plugin_list"

   local pluginpath

   [ -z "${DEFAULT_IFS}" ] && internal_fail "DEFAULT_IFS not set"
   [ -z "${MULLE_FETCH_LIBEXEC_DIR}" ] && internal_fail "MULLE_FETCH_LIBEXEC_DIR not set"

   log_info "Plugins"

   IFS=$'\n'
   for pluginpath in `ls -1 "${MULLE_FETCH_LIBEXEC_DIR}"/plugins/*.sh`
   do
      basename -- "${pluginpath}" .sh
   done
   IFS="${DEFAULT_IFS}"
}


fetch_plugin_load_all()
{
   log_entry "fetch_plugin_load_all"

   local name

   [ -z "${DEFAULT_IFS}" ] && internal_fail "DEFAULT_IFS not set"
   [ -z "${MULLE_FETCH_LIBEXEC_DIR}" ] && internal_fail "MULLE_FETCH_LIBEXEC_DIR not set"

   log_fluff "Loading plugins..."

   local names

   names="`fetch_plugin_all_names`"

   IFS=$'\n'; set -f
   for name in ${names}
   do
      IFS="${DEFAULT_IFS}"; set +f

      fetch_plugin_load_if_present "${name}"
   done

   IFS="${DEFAULT_IFS}"; set +f
}


fetch_plugin_main()
{
   log_entry "fetch_plugin_main" "$@"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            fetch_plugin_usage
         ;;

         -*)
            fetch_plugin_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ $# -ne 1 ] && fetch_plugin_usage

   local cmd="$1"

   case "${cmd}" in
      list)
         fetch_plugin_list
      ;;

      "")
         fetch_plugin_usage
      ;;

      *)
         fetch_plugin_usage "Unknown command \"$1\""
      ;;
   esac
}
