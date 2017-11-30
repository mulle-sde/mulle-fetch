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


fetch_log_action()
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

   case "${action}" in
      fetch|clone)
         [ -z "${url}" ]    && internal_fail "parameter: url is empty"
         [ -z "${dstdir}" ] && internal_fail "parameter: dstdir is empty"

         proposition=" into "
         if [ -L "${url}" ]
         then
            info=" symlinked "
         else
            info=" "
         fi
      ;;

      search-local|guess)
         [ -z "${url}" ]      && internal_fail "parameter: url is empty"
         proposition=" "
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
can_symlink_it()
{
   log_entry "can_symlink_it" "$@"

   local directory="$1"

   if [ ! -d "${directory}" ]
   then
      return 1
   fi

   if [ "${OPTION_SYMLINK}" != "YES" ]
   then
      log_fluff "Not allowed to symlink it. (Use --symlink to allow)"
      return 1
   fi

   case "${UNAME}" in
      minwgw)
         log_fluff "Can't symlink it, because symlinking is unavailable on this platform"
         return 1
      ;;
   esac

   if git_is_repository "${directory}"
   then
       # if bare repo, we can only clone anyway
      if git_is_bare_repository "${directory}"
      then
         log_verbose "${directory} is a bare git repository. So no symlinking"
         return 1
      fi
   else
      log_info "${directory} is not a git repository (yet ?)
So symlinking is the only way to go."
   fi

  return 0
}


fetch_get_local_item()
{
   log_entry "fetch_get_local_item" "$@"

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
      log_fluff "Not searching local filesystem because --local-search-path not specified"
      return
   fi

   local operation

   operation="`get_source_function "${sourcetype}" "search-local"`"

   if [ ! -z "${operation}" ]
   then
      "${operation}" "$@"
   else
      log_fluff "Not searching locals because source \"${sourcetype}\" does not support \"${operation}\""
   fi
}


_fetch_operation()
{
   log_entry "_fetch_operation" "$@"

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

   case "${url}" in
      /*)
         if can_symlink_it "${url}"
         then
            sourcetype="symlink"
         fi
      ;;

      #
      # don't move up using url
      #
      */\.\./*|\.\./*|*/\.\.|\.\.)
         internal_fail "Faulty url \"${url}\" should have been caught before"
      ;;

      *)
         found="`fetch_get_local_item "$@"`"

         if [ ! -z "${found}" ]
         then
            log_verbose "Using local item \"${found}\""
            url="${found}"

            case "${sourcetype}" in
               "git")
                  if can_symlink_it "${url}"
                  then
                     sourcetype="symlink"
                     log_verbose "Using symlink to local item \"${found}\""
                     url="`symlink_relpath "${url}" "${ROOT_DIR}"`"
                  fi
               ;;
            esac
         fi
      ;;
   esac

   source_operation "clone" \
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

   if [ "${sourcetype}" = "symlink" -a "${OPTION_SYMLINK_RETURNS_2}" = "YES" ]
   then
      return 2
   fi

   return 0
}


fetch_do_operation()
{
   log_entry "fetch_do_operation" "$@"

   local opname="$1" ; shift

   [ -z "${opname}" ] && internal_fail "operation is empty"

   fetch_log_action "${opname}" "$@"

#   local unused="$1"
   local name="$2"            # name of the clone
#   local url="$3"             # URL of the clone
#   local branch="$4"          # branch of the clone
#   local tag="$5"             # tag to checkout of the clone
   local sourcetype="$6"      # source to use for this clone
#   local sourceoptions="$7"   # options to use on source
#   local dstdir="$8"     # dstdir of this clone (absolute or relative to $PWD)

   [ -z "${sourcetype}" ] && internal_fail "source is empty"

   local rval

   case "${opname}" in
      "fetch"|"clone")
         _fetch_operation "$@"
         rval="$?"

         log_debug "fetch_do_operation \"${opname}\": \"${sourcetype}\" returns with ${rval}"

         return "${rval}"
      ;;
   esac

   source_operation "${opname}" "$@"
   rval="$?"

   case $rval in
      0)
      ;;

      111)
         log_error "\"${sourcetype}\" does not support \"${opname}\""
      ;;

      *)
         log_error "\"${sourcetype}\": ${opname} failed for \"${name:-${url}}\""
      ;;
   esac

   log_debug "fetch_do_operation \"${opname}\": \"${sourcetype}\" returns with ${rval}"
   return "${rval}"
}

:
