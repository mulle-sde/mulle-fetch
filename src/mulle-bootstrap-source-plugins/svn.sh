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
MULLE_BOOTSTRAP_SOURCE_PLUGIN_SVN_SH="included"


###
### PLUGIN API
###

svn_clone_project()
{
   [ $# -lt 8 ] && internal_fail "parameters missing"

   local reposdir="$1" ; shift
   local name="$1"; shift
   local url="$1"; shift
   local branch="$1"; shift
   local tag="$1"; shift
   local source="$1"; shift
   local sourceoptions="$1"; shift
   local stashdir="$1"; shift

   local options

   options="`get_sourceoption "${sourceoptions}" "clone"`"

   if [ ! -z "${branch}" ]
   then
      log_info "SVN checkout ${C_RESET_BOLD}${branch}${C_INFO} of ${C_MAGENTA}${C_BOLD}${url}${C_INFO} ..."
      options="`concat "${options}" "-r ${branch}"`"
   else
      if [ ! -z "${tag}" ]
      then
         log_info "SVN checkout ${C_RESET_BOLD}${tag}${C_INFO} of ${C_MAGENTA}${C_BOLD}${url}${C_INFO} ..."
         options="`concat "${options}" "-r ${tag}"`"
      else
         log_info "SVN checkout ${C_MAGENTA}${C_BOLD}${url}${C_INFO} ..."
      fi
   fi

   if ! exekutor svn ${SVNFLAGS} checkout ${options} "$@" ${SVNOPTIONS} "${url}" "${stashdir}"  >&2
   then
      log_error "svn clone of \"${url}\" into \"${stashdir}\" failed"
      return 1
   fi
}

svn_update_project()
{
   [ $# -lt 8 ] && internal_fail "parameters missing"

   local reposdir="$1" ; shift
   local name="$1"; shift
   local url="$1"; shift
   local branch="$1"; shift
   local tag="$1"; shift
   local source="$1"; shift
   local sourceoptions="$1"; shift
   local stashdir="$1"; shift

   local options

   options="`get_sourceoption "${sourceoptions}" "update"`"

   [ ! -z "${stashdir}" ] || internal_fail "stashdir is empty"

   log_info "SVN updating ${C_MAGENTA}${C_BOLD}${stashdir}${C_INFO} ..."

   if [ ! -z "$branch" ]
   then
      options="`concat "-r ${branch}" "${options}"`"
   else
      if [ ! -z "$tag" ]
      then
         options="`concat "-r ${tag}" "${options}"`"
      fi
   fi

   (
      exekutor cd "${stashdir}" ;
      exekutor svn ${SVNFLAGS} update ${options} ${SVNOPTIONS}  >&2
   ) || fail "svn update of \"${stashdir}\" failed"
}


svn_status_project()
{
   [ $# -lt 8 ] && internal_fail "parameters missing"

   local reposdir="$1" ; shift
   local name="$1"; shift
   local url="$1"; shift
   local branch="$1"; shift
   local tag="$1"; shift
   local source="$1"; shift
   local sourceoptions="$1"; shift
   local stashdir="$1"; shift

   local options

   options="`get_sourceoption "${sourceoptions}" "status"`"

   [ ! -z "${stashdir}" ] || internal_fail "stashdir is empty"

   (
      exekutor cd "${stashdir}" ;
      exekutor svn status ${options} ${sourceoptions} "$@" ${SVNOPTIONS}  >&2
   ) || fail "svn update of \"${stashdir}\" failed"
}


svn_search_local_project()
{
   log_entry "git_search_local_project [${LOCAL_PATH}]" "$@"

   local url="$1"
   local name="$2"
   local branch="$3"

   source_search_local_path "${name}" "${branch}" ".svn" "YES"
}
