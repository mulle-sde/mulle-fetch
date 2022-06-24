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
MULLE_FETCH_PLUGIN_SYMLINK_SH="included"


###
### PLUGIN API
###

fetch::plugin::symlink::fetch_project()
{
#   local unused="$1"
   local name="$2"           # name of the clone
   local url="$3"            # URL of the clone
   local branch="$4"         # branch of the clone
   local tag="$5"            # tag to checkout of the clone
#   local sourcetype="$6"    # source to use for this clone
#   local sourceoptions="$7" # options to use on source
   local dstdir="$8"         # dstdir of this clone (absolute or relative to $PWD)

   fetch::source::prepare_filesystem_for_fetch "${dstdir}"

   url="${url#file://}"

   case "${MULLE_UNAME}" in 
      mingw)
         mkdir_if_missing "${dstdir}"

         # mingw can't symlink but we want the local repository and not the remote
         # so... copy it. Tricky though, if we are a subdirectory of url (like test)
         if ! (cd "${url}" ; exekutor tar cf - \
                                          --exclude='./stash' \
                                          --exclude='./kitchen' \
                                          --exclude='./[Bb]uild' \
                                          --exclude='./addiction' \
                                          --exclude='./test*' \
                                          --exclude='./mulle/var' \
                                          . ) | ( cd "${dstdir}" ; tar xf - )
         then
            return 1
         fi
      ;;
      *)
         if ! exekutor create_symlink "${url}" "${dstdir}" "${OPTION_ABSOLUTE_SYMLINK:-NO}"
         then
            return 1
         fi
      ;;
   esac

   log_info "Symlinked ${C_MAGENTA}${C_BOLD}${name}${C_INFO} to ${C_RESET_BOLD}${url}${C_INFO}"

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
may have been ignored, because the repository is symlinked."
      # this can be often more confusing so just issue onv erbosr
      _log_verbose "If you want to checkout this ${branchlabel} you may want to:
   ${C_RESET}(cd ${dstdir}; git checkout ${OPTION_TOOL_OPTIONS} \"${branch}\" )${C_WARNING}"
   fi
}


fetch::plugin::symlink::search_local_project()
{
   log_entry "fetch::plugin::symlink::search_local_project [${MULLE_FETCH_SEARCH_PATH}]" "$@"

#   local unused="$1"
   local name="$2"            # name of the clone
   local url="$3"             # URL of the clone
   local branch="$4"          # branch of the clone
#   local tag="$5"             # tag to checkout of the clone
#   local sourcetype="$6"      # source to use for this clone
#   local sourceoptions="$7"   # options to use on source
#   local dstdir="$8"     # dstdir of this clone (absolute or relative to $PWD)


   local filename
   local found

   #
   # the URL can be used to find a local repository
   #
   case "${url}" in
      file://*)
         r_simplified_absolutepath "${url:7}"
         r_dirname "${RVAL}"  # remove name from url
         filename="${RVAL}"

         if fetch::source::r_search_local "${filename}" "${name}" "${branch}" "" "NO"
         then
            log_fluff "Found via URL \"${url}\""
            printf "%s\n" "${RVAL}"
            return
         fi
         log_warning "Not found via URL \"${url}\""
      ;;
   esac

   if fetch::source::r_search_local_in_searchpath "${name}" "${branch}" "" 'YES' "${url}"
   then
      printf "%s\n" "${RVAL}"
   fi
}


fetch::plugin::symlink::exists_project()
{
   log_entry "fetch::plugin::symlink::exists_project" "$@"

   local url="$3"             # URL of the clone

   fetch::source::validate_file_url "${url}"
}


fetch::plugin::symlink::guess_project()
{
   log_entry "fetch::plugin::symlink::guess_project" "$@"

   fetch::source::guess_project "$@"
}

