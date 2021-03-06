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

   Currently the only command is "list".

Options:
   --scm    : list SCM plugins (default)
   --domain : list domain plugins

EOF

   exit 1
}


fetch_plugin_all_names()
{
   log_entry "fetch_plugin_all_names" "$@"

   local type="${1:-scm}"

   local upcase
   local plugindefine
   local pluginpath
   local name

   [ -z "${DEFAULT_IFS}" ] && internal_fail "DEFAULT_IFS not set"
   [ -z "${MULLE_FETCH_LIBEXEC_DIR}" ] && internal_fail "MULLE_FETCH_LIBEXEC_DIR not set"

   IFS=$'\n'
   for pluginpath in `ls -1 "${MULLE_FETCH_LIBEXEC_DIR}/plugins/${type}"/*.sh`
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

   IFS="${DEFAULT_IFS}"
}


fetch_plugin_load_if_present()
{
   log_entry "fetch_plugin_load_if_present" "$@"

   local name="$1"
   local type="${2:-scm}"

   if [ ! -f "${MULLE_FETCH_LIBEXEC_DIR}/plugins/${type}/${name}.sh" ]
   then
      log_verbose "${type} \"${name}\" is not supported (no plugin found)"
      return 1
   fi

   # shellcheck source=plugins/symlink.sh
   . "${MULLE_FETCH_LIBEXEC_DIR}/plugins/${type}/${name}.sh"
   return 0
}



fetch_plugin_load()
{
   log_entry "fetch_plugin_load" "$@"

   local name="$1"
   local type="${2:-scm}"

   if ! fetch_plugin_load_if_present "${name}" "${type}"
   then
      fail "${type} \"${name}\" is not supported (no plugin found)"
   fi
}


fetch_plugin_list()
{
   log_entry "fetch_plugin_list"

   local type="${1:-scm}"

   local upcase
   local plugindefine
   local pluginpath
   local name

   [ -z "${DEFAULT_IFS}" ] && internal_fail "DEFAULT_IFS not set"
   [ -z "${MULLE_FETCH_LIBEXEC_DIR}" ] && internal_fail "MULLE_FETCH_LIBEXEC_DIR not set"

   log_info "Plugins"

   IFS=$'\n'
   for pluginpath in `ls -1 "${MULLE_FETCH_LIBEXEC_DIR}/plugins/${type}"/*.sh`
   do
      basename -- "${pluginpath}" .sh
   done

   IFS="${DEFAULT_IFS}"
}


fetch_plugin_load_all()
{
   log_entry "fetch_plugin_load_all"

   local type="${1:-scm}"

   local upcase
   local plugindefine
   local pluginpath
   local name

   [ -z "${DEFAULT_IFS}" ] && internal_fail "DEFAULT_IFS not set"
   [ -z "${MULLE_FETCH_LIBEXEC_DIR}" ] && internal_fail "MULLE_FETCH_LIBEXEC_DIR not set"

   log_fluff "Loading ${type} plugins..."

   IFS=$'\n'
   for pluginpath in `ls -1 "${MULLE_FETCH_LIBEXEC_DIR}/plugins/${type}"/*.sh`
   do
      IFS="${DEFAULT_IFS}"

      name="`basename -- "${pluginpath}" .sh`"

      r_identifier "${type}_${name}"
      r_uppercase "${RVAL}"
      plugindefine="MULLE_FETCH_PLUGIN_${RVAL}_SH"

      if [ -z "${!plugindefine}" ]
      then
         # shellcheck source=plugins/symlink.sh
         . "${pluginpath}"

         case "${type}" in
            'scm')
               if [ "`type -t "${name}_fetch_project"`" != "function" ]
               then
                  fail "${type} plugin \"${pluginpath}\" has no \"${name}_fetch_project\" function"
               fi
            ;;
         esac
         log_fluff "${type} plugin \"${name}\" loaded"
      fi
   done

   IFS="${DEFAULT_IFS}"
}


fetch_plugin_main()
{
   log_entry "fetch_plugin_main" "$@"

   local type=""


   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            fetch_plugin_usage
         ;;

         --scm)
            type="scm"
         ;;

         --domain)
            type="domain"
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

   [ $# -eq 0 ] && fetch_plugin_usage

   local cmd="$1"
   shift

   case "${cmd}" in
      list)
         [ $# -ne 0 ] && fetch_plugin_usage "superflous parameters"
         fetch_plugin_list "${type}"
      ;;

      "")
         fetch_plugin_usage
      ;;

      *)
         fetch_plugin_usage "Unknown command \"$1\""
      ;;
   esac
}
