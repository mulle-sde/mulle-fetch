#! /usr/bin/env bash
#
#   Copyright (c) 2017 Nat! - Mulle kybernetiK
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
MULLE_FETCH_PLUGIN_COPY_SH='included'


###
### PLUGIN API
###
fetch::plugin::copy::copy_project()
{
   log_entry "fetch::plugin::copy::copy_project" "$@"

   local srcdir="$1"         # URL of the clone
   local dstdir="$2"         # dstdir of this clone (absolute or relative to $PWD)

   mkdir_if_missing "${dstdir}"

   local escaped_dstdir
   local relative_dstdir

   r_simplified_absolutepath "${srcdir}"
   srcdir="${RVAL}"

   r_simplified_absolutepath "${dstdir}"
   dstdir="${RVAL}"

   r_relative_path_between "${dstdir}" "${srcdir}"
   relative_dstdir="${RVAL}"

   case "${relative_dstdir}" in
      '.')
         fail "Copy would clobber origin"
      ;;
   esac

   r_escaped_grep_pattern "${relative_dstdir}"
   escaped_dstdir="${RVAL}"

   (
      rexekutor cd "${srcdir}" || fail "\"${srcdir#${MULLE_USER_PWD}/}\" is missing or inaccessible"
      log_info "PWD=$PWD"
      rexekutor mulle-match list --gitignore-only \
      | rexekutor grep -v -E "^${escaped_dstdir}/" \
      | rexekutor tar -cf - -T -
   ) \
   | \
   (
      rexekutor cd "${dstdir}"  || fail "\"${dstdir#${MULLE_USER_PWD}/}\" is missing or inaccessible"
      exekutor tar -xf -
   )

#   # mingw could not copy, but we want the local repository and not
#   # the remote so... copy it. Tricky though, if we are a subdirectory
#   # of url (like test). with the -h option, we make sure that copys
#   # are resolved.
#   # Well windows can do copys..., mingw can also sort of but then
#   # the tar can't ...
#   (cd "${url}" ; exekutor tar -chf  - \
#                                    --exclude='./stash' \
#                                    --exclude='./node_modules' \
#                                    --exclude='./kitchen' \
#                                    --exclude='./[Bb]uild' \
#                                    --exclude='./addiction' \
#                                    --exclude='./test*' \
#                                    --exclude='./mulle/var' \
#                                    . ) | ( cd "${dstdir}" ; tar xf - )
}


fetch::plugin::copy::fetch_project()
{
   log_entry "fetch::plugin::copy::fetch_project" "$@"

#   local unused="$1"
   local name="$2"           # name of the clone
   local url="$3"            # URL of the clone
   local branch="$4"         # branch of the clone
   local tag="$5"            # tag to checkout of the clone
   local sourcetype="$6"     # source to use for this clone
   local sourceoptions="$7"  # options to use on source
   local dstdir="$8"         # dstdir of this clone (absolute or relative to $PWD)

   fetch::source::prepare_filesystem_for_fetch "${dstdir}"

   url="${url#file://}"

   case "${url}" in
      *://*)
         fail "Copy needs local filepath not \"${url}\""
      ;;
   esac

   if ! fetch::plugin::copy::copy_project "${url}" "${dstdir}"
   then
      return 1
   fi

   log_info "Copied ${C_MAGENTA}${C_BOLD}${name}${C_INFO} from ${C_RESET_BOLD}${url}${C_INFO}"

   local branchlabel

   branchlabel="branch"
   if [ -z "${branch}" -a ! -z "${tag}" ]
   then
      branchlabel="tag"
      branch="${tag}"
   fi

   if [ "${branch}" != "${GIT_DEFAULT_BRANCH:-master}" -a "${branch}" != "latest" -a ! -z "${branch}" ]
   then
      _log_warning "warning: The intended ${branchlabel} ${C_RESET_BOLD}${branch}${C_WARNING} \
may have been ignored, because the repository is copied."
      # this can be often more confusing so just issue onv erbosr
      _log_verbose "If you want to checkout this ${branchlabel} you may want to:
   ${C_RESET}(cd ${dstdir}; git checkout ${OPTION_TOOL_OPTIONS} \"${branch}\" )${C_WARNING}"
   fi
}


fetch::plugin::copy::search_local_project()
{
   log_entry "fetch::plugin::copy::search_local_project [${MULLE_FETCH_SEARCH_PATH}]" "$@"

   fetch::plugin::load_if_needed "symlink"

   fetch::plugin::symlink::search_local_project "$@"
}


fetch::plugin::copy::exists_project()
{
   log_entry "fetch::plugin::copy::exists_project" "$@"

   local url="$3"             # URL of the clone

   fetch::source::validate_file_url "${url}"
}


fetch::plugin::copy::guess_project()
{
   log_entry "fetch::plugin::copy::guess_project" "$@"

   fetch::source::guess_project "$@"
}

