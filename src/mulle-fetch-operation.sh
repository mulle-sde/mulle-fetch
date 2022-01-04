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
MULLE_FETCH_OPERATION_SH="included"


fetch::operation::usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} operation [option] <command>

   Currently the only command is "list".

Options:
   -s <scm>  : specify SCM to query operations off

EOF

   exit 1
}


fetch::operation::log_action()
{
   local action="$1" ; shift

   local unused="$1"
   local name="$2"            # name of the clone
   local url="$3"             # URL of the clone
   local branch="$4"          # branch of the clone
   local tag="$5"             # tag to checkout of the clone
   local sourcetype="$6"      # source to use for this clone
   local sourceoptions="$7"   # options to use on source
   local dstdir="$8"          # dstdir of this clone (absolute or relative to $PWD)

   local proposition
   local info

   info=" "

   case "${action}" in
      fetch)
         [ -z "${url}" ]    && internal_fail "parameter: url is empty"
         [ -z "${dstdir}" ] && internal_fail "parameter: dstdir is empty"

         proposition=" into "
         if [ -L "${url}" ]
         then
            info=" symlinked "
         fi
      ;;

      search-local|guess|exists)
         [ -z "${url}" ]      && internal_fail "parameter: url is empty"
         info=" of "
         proposition=" at "
      ;;

      *)
         [ -z "${dstdir}" ]   && internal_fail "parameter: dstdir is empty"
         [ ! -d "${dstdir}" ] && fail "Directory ${C_RESET_BOLD}${dstdir}${C_ERROR_TEXT} does not exist"
         proposition=" in "
      ;;
   esac

   log_fluff "Perform ${action}${info}${url}${proposition}${dstdir} ..."
}


#
###
#
fetch::operation::can_symlink_it()
{
   log_entry "fetch::operation::can_symlink_it" "$@"

   local directory="$1"

   directory="${directory#file://}"

   #
   # DEFAULT is no
   #
   if [ "${OPTION_SYMLINK}" != 'YES' ]
   then
      log_verbose "Not allowed to symlink it. (Use --symlink to allow).
Within mulle-sde:
${C_RESET_BOLD}  mulle-sde env set MULLE_SOURCETREE_SYMLINK YES
"
      return 1
   fi

   case "${MULLE_UNAME}" in
      minwgw)
         log_verbose "Can't symlink it, because symlinking is unavailable on \
this platform"
         return 1
      ;;
   esac

   if [ ! -d "${directory}" ]
   then
      log_verbose "\"${directory#${MULLE_USER_PWD}/}\" is not a directory, can not symlink"
      return 1
   fi

   if [ -e "${directory}/.mulle/etc/fetch/no-symlink" ]
   then
      log_verbose "Symlinking disabled by \"${directory#${MULLE_USER_PWD}/}/.mulle/etc/fetch/no-symlink\""
      return 1
   fi

   #
   # lazy load this as we need it now
   #
   if [ -z "${MULLE_FETCH_GIT_SH}" ]
   then
      # shellcheck source=src/mulle-fetch-git.sh
      . "${MULLE_FETCH_LIBEXEC_DIR}/mulle-fetch-git.sh" || exit 1
   fi

   if fetch::git::is_repository "${directory}"
   then
       # if bare repo, we can only clone anyway
      if fetch::git::is_bare_repository "${directory}"
      then
         log_verbose "${directory#${MULLE_USER_PWD}/} is a bare git repository. So no symlinking"
         return 1
      fi
   else
      log_info "${directory#${MULLE_USER_PWD}/} is not a git repository. Can only symlink."
   fi

  return 0
}


fetch::operation::type_of_local_item()
{
   log_entry "fetch::operation::type_of_local_item" "$@"

   local url="$1"

   if [ -d "${url}/.git" ]
   then
      RVAL="git"
      return
   fi

   if [ -d "${url}/.svn" ]
   then
      RVAL="svn"
      return
   fi

   case "${url}" in
      *.tar|*.tgz|*.tar.gz)
         RVAL="tar"
         return
      ;;

      *.zip)
         RVAL="zip"
         return
      ;;
   esac

   RVAL=
   return 1
}


fetch::operation::get_local_item()
{
   log_entry "fetch::operation::get_local_item" "$@"

   local unused="$1"
   local name="$2"            # name of the clone
   local url="$3"             # URL of the clone
   local branch="$4"          # branch of the clone
   local tag="$5"             # tag to checkout of the clone
   local sourcetype="$6"      # source to use for this clone
   local sourceoptions="$7"   # options to use on source
   local dstdir="$8"          # dstdir of this clone (absolute or relative to $PWD)

   if [ -z "${MULLE_FETCH_SEARCH_PATH}" ]
   then
      log_fluff "Not searching local filesystem because MULLE_FETCH_SEARCH_PATH \
is empty (use --local-search-path to set)"
      return
   fi

   local operation

   fetch::source::r_get_plugin_function "${sourcetype}" "search-local"
   operation="${RVAL}"

   if [ ! -z "${operation}" ]
   then
      exekutor "${operation}" "$@"
   else
      log_fluff "Not searching locals because source \"${sourcetype}\" does \
not support \"${operation}\""
   fi
}


# MEMO: github cannot do "git archive"
fetch::operation::_operation()
{
   log_entry "fetch::operation::_operation" "$@"

   local unused="$1"
   local name="$2"            # name of the clone
   local url="$3"             # URL of the clone
   local branch="$4"          # branch of the clone
   local tag="$5"             # tag to checkout of the clone
   local sourcetype="$6"      # source to use for this clone
   local sourceoptions="$7"   # options to use on source
   local dstdir="$8"          # dstdir of this clone (absolute or relative to $PWD)

   [ $# -eq 8 ] || internal_fail "parameters imcomplete"

   local found
   local rval
   local localtype

   case "${url}" in
      #
      # don't move up using url
      #
      *'/../'*|'../'*|*'/..'|'..')
         if [ "${sourcetype}" != "symlink" ]
         then
            internal_fail "Faulty url \"${url}\" should have been caught before"
         fi
      ;;

      '/'*|file:*)
         if fetch::operation::can_symlink_it "${url}"
         then
            sourcetype="symlink"
         fi
      ;;

      *)
         found="`fetch::operation::get_local_item "$@"`"
         if [ ! -z "${found}" ]
         then
            fetch::operation::type_of_local_item "${found}"
            localtype="${RVAL}"

            case "${localtype}" in
               "")
                  if fetch::operation::can_symlink_it "${found}"
                  then
                     url="${found}"
                     sourcetype="symlink"
                  fi
               ;;

               git|svn)
                  log_fluff "Found local ${localtype} item \"${found}\""
                  url="${found}"
                  sourcetype="${localtype}"
                  if fetch::operation::can_symlink_it "${url}"
                  then
                     sourcetype="symlink"
                     log_fluff "Using symlink to local item \"${found}\""
                     r_symlink_relpath "${found}" "${ROOT_DIR}"
                     url="${RVAL}"
                  fi
               ;;

               tar|zip)
                  log_fluff "Found local ${localtype} item \"${found}\""
                  if [ "${sourcetype}" = "${localtype}" ]
                  then
                     url="${found}"
                  fi
               ;;
            esac
         fi
      ;;
   esac

   fetch::source::operation "fetch" \
                            "${unused}" \
                            "${name}" \
                            "${url}" \
                            "${branch}" \
                            "${tag}" \
                            "${sourcetype}" \
                            "${sourceoptions}" \
                            "${dstdir}"

   rval="$?"
   case $rval in
      0)
      ;;

      111)
         log_fail "Source \"${sourcetype}\" is unknown"
      ;;

      *)
         rmdir_safer "${dstdir}"  # remove partial or wrong clone/unpack
         return $rval
      ;;
   esac

   if [ "${sourcetype}" = "symlink" -a "${OPTION_SYMLINK_RETURNS_4}" = 'YES' ]
   then
      return 4
   fi

   return 0
}


fetch::operation::do()
{
   log_entry "fetch::operation::do" "$@"

   local opname="$1" ; shift

   [ -z "${opname}" ] && internal_fail "operation is empty"

   fetch::operation::log_action "${opname}" "$@"

#   local unused="$1"
   local name="$2"             # name of the clone
#   local url="$3"             # URL of the clone
#   local branch="$4"          # branch of the clone
#   local tag="$5"              # tag to checkout of the clone
   local sourcetype="$6"       # source to use for this clone
#   local sourceoptions="$7"   # options to use on source
#   local dstdir="$8"          # dstdir of this clone (absolute or relative to $PWD)

   [ -z "${sourcetype}" ] && internal_fail "source is empty"

   local rval

   case "${opname}" in
      'fetch')
         fetch::operation::_operation "$@"
         rval=$?

         log_debug "fetch::operation::do \"${opname}\": \"${sourcetype}\" \
returns with ${rval}"

         return "${rval}"
      ;;
   esac

   fetch::source::operation "${opname}" "$@"
   rval=$?

   case $rval in
      0)
      ;;

      111)
         log_error "\"${sourcetype}\" does not support \"${opname}\""
      ;;

      *)
         case "${opname}" in
            'search-local'|'exists')
               log_fluff "\"${sourcetype}\": ${opname} failed for \"${name:-${url}}\""
            ;;

            *)
               log_error "\"${sourcetype}\": ${opname} failed for \"${name:-${url}}\""
            ;;
         esac
      ;;
   esac

   log_debug "fetch::operation::do \"${opname}\": \"${sourcetype}\" returns with ${rval}"
   return "${rval}"
}


fetch::operation::_list()
{
   log_entry "fetch::operation::_list" "$@"

   local sourcetype="$1"
   local operations="$2"

   local opname
   local operation
   local funcname

   .foreachline opname in ${operations}
   .do
      funcname="${opname//-/_}"
      operation="fetch::plugin::${sourcetype}::${funcname}_project"
      if shell_is_function "${operation}"
      then
         printf "%s\n" "${opname}"
      fi
   .done
}


fetch::operation::list()
{
   log_entry "fetch::operation::list" "$@"

   log_info "Operations"

   fetch::operation::_list "$1" "\
checkout
fetch
search-local
set-url
status
update
upgrade"
}



fetch::commands::operation_main()
{
   log_entry "fetch::commands::operation_main" "$@"

   local OPTION_SCM="git"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            fetch::operation::usage
         ;;

         -s|--source|--scm)
            [ $# -eq 1 ] && fail "Missing argument to \"$1\""
            shift

            OPTION_SCM="$1"
         ;;

         -*)
            fetch::operation::usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ $# -eq 0 ] && fetch::operation::usage

   local cmd="$1"
   shift

   case "${cmd}" in
      list)
         [ $# -ne 0 ] && fetch::operation::usage "superflous parameters"

         # shellcheck source=mulle-fetch-plugin.sh
         . "${MULLE_FETCH_LIBEXEC_DIR}/mulle-fetch-plugin.sh" || \
            fail "failed to load ${MULLE_FETCH_LIBEXEC_DIR}/mulle-fetch-plugin.sh"

         fetch::plugin::load_all "scm"
         fetch::operation::list "${OPTION_SCM}" "scm"
      ;;

      "")
         fetch::operation::usage
      ;;

      *)
         fetch::operation::usage "Unknown command \"$1\""
      ;;
   esac
}
