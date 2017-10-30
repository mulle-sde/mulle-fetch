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
MULLE_FETCH_PLUGIN_GIT_SH="included"



#
# global variable __GIT_MIRROR_URLS__ used to avoid refetching
# repos in one setting
#
_git_get_mirror_url()
{
   log_entry "_git_get_mirror_url" "$@"

   local url="$1"; shift
   local options="$2" ; shift

   local name
   local fork
   local result

   result="`fork_and_name_from_url "${url}"`"
   fork="`echo "${result}" | head -1`"
   name="`echo "${result}" | tail -1`"

   local mirrordir

   mkdir_if_missing "${OPTION_GIT_MIRROR_DIR}/${fork}"
   mirrordir="${OPTION_GIT_MIRROR_DIR}/${fork}/${name}" # try to keep it global

   local match

   # use global unused

   if [ ! -z "${OPTION_UPTODATE_MIRRORS_FILE}" ]
   then
      log_debug "Mirror URLS: `cat "${OPTION_UPTODATE_MIRRORS_FILE}" 2>/dev/null`"

      match="`fgrep -s -x "${mirrordir}" "${OPTION_UPTODATE_MIRRORS_FILE}" 2>/dev/null`"
      if [ ! -z "${match}" ]
      then
         log_fluff "Repository \"${mirrordir}\" already up-to-date"
         echo "${mirrordir}"
         return 0
      fi
   fi

   if [ ! -d "${mirrordir}" ]
   then
      log_verbose "Set up git-mirror \"${mirrordir}\""
      if ! exekutor git ${OPTION_GITFLAGS} clone --mirror ${options} ${OPTION_GITOPTIONS} -- "${url}" "${mirrordir}" >&2
      then
         log_error "git clone of \"${url}\" into \"${mirrordir}\" failed"
         return 1
      fi
   else
      # refetch

      if [ "${OPTION_ALLOW_REFRESH_GIT_MIRROR}" = "YES" ]
      then
      (
         log_verbose "Refreshing git-mirror \"${mirrordir}\""
         cd "${mirrordir}";
         if ! exekutor git ${OPTION_GITFLAGS} fetch >&2
         then
            log_warning "git fetch from \"${url}\" failed, using old state"
         fi
      )
      fi
   fi

   # for embedded we are otherwise too early
   if [ ! -z "${OPTION_UPTODATE_MIRRORS_FILE}" ]
   then
      redirect_append_exekutor "${OPTION_UPTODATE_MIRRORS_FILE}" echo "${mirrordir}"
   fi
   echo "${mirrordir}"
}


__git_check_file_url()
{
   local url="$1"

   if ! git_is_repository "${url}"
   then
      if [ -e "${url}" ]
      then
         log_error "\"${url}\" is not a git repository ($PWD)."
         if [ -d "${url}" ]
         then
            log_warning "Hint: You may want to symlink it."
         fi
      else
         log_error "\"${url}\" does not exist ($PWD)"
      fi
      return 1
   fi
}


__git_clone()
{
   log_entry "__git_clone" "$@"

   [ $# -lt 8 ] && internal_fail "parameters missing"

#   local unused="$1"
#   local name="$2"
   local url="$3"
   local branch="$4"
   local tag="$5"
#   local sourcetype="$6"
   local sourceoptions="$7"
   local dstdir="$8"

   [ ! -z "${url}" ]    || internal_fail "url is empty"
   [ ! -z "${dstdir}" ] || internal_fail "dstdir is empty"

   [ -e "${dstdir}" ]   && internal_fail "${dstdir} already exists"

   local options
   local dstdir
   local options
   local mirroroptions

   dstdir="${dstdir}"
   options="`get_sourceoption "${sourceoptions}" "fetch"`"
   mirroroptions="${options}"

   if [ ! -z "${branch}" ]
   then
      log_info "Cloning branch ${C_RESET_BOLD}$branch${C_INFO} of ${C_MAGENTA}${C_BOLD}${url}${C_INFO} into \"${dstdir}\" ..."
      options="`concat "${options}" "-b ${branch}"`"
   else
      log_info "Cloning ${C_MAGENTA}${C_BOLD}${url}${C_INFO} into \"${dstdir}\" ..."
   fi

   options="`concat "${options}" "--single-branch"`"

   local originalurl

   #
   # "remote urls" go through mirror
   # local urls get checked ahead for better error messages
   #
   case "${url}" in
      file:*)
         if ! __git_check_file_url "${url}"
         then
            return 1
         fi
      ;;

      *:*)
         if [ ! -z "${OPTION_GIT_MIRROR_DIR}" ]
         then
            originalurl="${url}"
            url="`_git_get_mirror_url "${url}" "${mirroroptions}"`" || return 1
            options="`concat "--origin mirror" "${options}"`"
         fi
      ;;

      *)
         if ! __git_check_file_url "${url}"
         then
            return 1
         fi
      ;;
   esac

#
# callers responsibility
#
#   local parent
#
#    parent="`dirname -- "${dstdir}"`"
#   mkdir_if_missing "${parent}"

   if [ "${dstdir}" = "${url}" ]
   then
      # since we know that stash dir does not exist, this
      # message is a bit less confusing
      log_error "Clone source \"${url}\" does not exist."
      return 1
   fi

   #
   # to actually pull a minimal set clone --single-branch is not good
   # because it fetches the tags, which in turn pull in most of the refs
   # regardless
   #
   local rval

   if : # [ -z "${tag}" ]
   then
      mkdir_if_missing "${dstdir}" &&
      (
         branch="${branch:-master}" # local to shell

         exekutor cd "${dstdir}"
         exekutor git init &&
         exekutor git remote add origin "${url}" &&
         exekutor git fetch --no-tags "origin" "${branch}" &&
         exekutor git checkout -b "${branch}" "origin/${branch}"
      )
      rval="$?"
   else
      exekutor git ${OPTION_GITFLAGS} "clone" ${options} ${OPTION_GITOPTIONS} -- "${url}" "${dstdir}"  >&2
      rval="$?"
   fi

   if [ "$rval" -ne 0 ]
   then
      rmdir_safer "${dstdir}"
      log_error "git clone of \"${url}\" into \"${dstdir}\" failed"
      return 1
   fi

   if [ ! -z "${originalurl}" ]
   then
      git_unset_default_remote "${dstdir}"
      git_add_remote "${dstdir}" "origin" "${originalurl}"

      #
      # too expensive for me, because it must fetch now to
      # get the origin branch. Funnily enough it works fine
      # even without it..
      #
      if read_yes_no_config_setting "git_set_default_remote"
      then
         git_set_default_remote "${dstdir}" "origin" "${branch}"
      fi
   fi
}


_git_clone()
{
   local url="$1"
   local dstdir="$2"
   local branch="$3"

##   local unused="$1"
##   local name="$2"
#   local url="$3"
#   local branch="$4"
##   local tag="$5"
##   local sourcetype="$6"
#   local sourceoptions="$7"
#   local dstdir="$8"

   __git_clone "n/a" \
               "n/a" \
               "${url}" \
               "${branch}" \
               "n/a" \
               "git" \
               "" \
               "${dstdir}"
}

_get_fetch_remote()
{
   local url="$1"
   local remote

   remote="origin"

   # "remote urls" going through cache will be refreshed here
   case "${url}" in
      file:*|/*|~*|.*)
      ;;

      *:*)
         if [ ! -z "${OPTION_GIT_MIRROR_DIR}" ]
         then

            _git_get_mirror_url "${url}" > /dev/null || return 1
            remote="mirror"
         fi
      ;;
   esac

   echo "${remote}"
}


###
### Plugin API
###

git_clone_project()
{
   log_entry "git_clone_project" "$@"

   if ! __git_clone "$@"
   then
      return 1
   fi

   if [ ! -z "${tag}" ]
   then
      git_checkout_project "$@"
   fi
}


git_checkout_project()
{
   log_entry "git_checkout_project" "$@"

   [ $# -lt 8 ] && internal_fail "parameters missing"

   local unused="$1" ; shift
   local name="$1"; shift
   local url="$1"; shift
   local branch="$1"; shift
   local tag="$1"; shift
   local sourcetype="$1"; shift
   local sourceoptions="$1"; shift
   local dstdir="$1"; shift

   [ -z "${dstdir}" ] && internal_fail "dstdir is empty"
   [ -z "${tag}" ]    && internal_fail "tag is empty"

   local options

   options="`get_sourceoption "${sourceoptions}" "checkout"`"

#   local branch

   branch="`git_get_branch "${dstdir}"`"

   if [ "${branch}" != "${tag}" ]
   then
      log_info "Checking out version ${C_RESET_BOLD}${tag}${C_INFO} of ${C_MAGENTA}${C_BOLD}${dstdir}${C_INFO} ..."

      if ! git_has_fetched_tags "${dstdir}"
      then
         (
            exekutor cd "${dstdir}" &&
            exekutor git ${OPTION_GITFLAGS} fetch --tags
         ) || return 1
      fi

      if ! git_branch_contains_tag "${dstdir}" "${branch}" "${tag}"
      then
         log_error "tag ${tag} is not on branch ${branch}"
         return 1
      fi

      (
         exekutor cd "${dstdir}" &&
         exekutor git ${OPTION_GITFLAGS} checkout ${options} "${tag}"  >&2
      ) || return 1

      if [ $? -ne 0 ]
      then
         log_error "Checkout failed, moving ${C_CYAN}${C_BOLD}${dstdir}${C_ERROR} to ${C_CYAN}${C_BOLD}${dstdir}.failed${C_ERROR}"
         log_error "You need to fix this manually and then move it back."

         rmdir_safer "${dstdir}.failed"
         exekutor mv "${dstdir}" "${dstdir}.failed"  >&2
         return 1
      fi
   else
      log_fluff "Already on proper branch \"${branch}\""
   fi
}

#  aka fetch
git_update_project()
{
   log_entry "git_update_project" "$@"

   [ $# -lt 8 ] && internal_fail "parameters missing"

   local unused="$1" ; shift
   local name="$1"; shift
   local url="$1"; shift
   local branch="$1"; shift
   local tag="$1"; shift
   local sourcetype="$1"; shift
   local sourceoptions="$1"; shift
   local dstdir="$1"; shift

   local options
   local remote

   options="`get_sourceoption "${sourceoptions}" "update"`"
   remote="`_get_fetch_remote "${url}"`" || internal_fail "can't figure out remote"

   log_info "Fetching ${C_MAGENTA}${C_BOLD}${dstdir}${C_INFO} ..."

   (
      exekutor cd "${dstdir}" &&
      exekutor git ${OPTION_GITFLAGS} fetch "$@" ${options} ${OPTION_GITOPTIONS} "${remote}" >&2
   ) || fail "git fetch of \"${dstdir}\" failed"
}


#  aka pull
git_upgrade_project()
{
   log_entry "git_upgrade_project" "$@"

   [ $# -lt 8 ] && internal_fail "parameters missing"

   local unused="$1" ; shift
   local name="$1"; shift
   local url="$1"; shift
   local branch="$1"; shift
   local tag="$1"; shift
   local sourcetype="$1"; shift
   local sourceoptions="$1"; shift
   local dstdir="$1"; shift

   local options
   local remote

   options="`get_sourceoption "${sourceoptions}" "upgrade"`"
   remote="`_get_fetch_remote "${url}"`" || internal_fail "can't figure out remote"

   log_info "Pulling ${C_MAGENTA}${C_BOLD}${dstdir}${C_INFO} ..."

   (
      exekutor cd "${dstdir}" &&
      exekutor git ${OPTION_GITFLAGS} pull "$@" ${sourceoptions} ${OPTION_GITOPTIONS} "${remote}" >&2
   ) || fail "git pull of \"${dstdir}\" failed"

   if [ ! -z "${tag}" ]
   then
      git_checkout "$@"  >&2
   fi
}


git_status_project()
{
   log_entry "git_status_project" "$@"

   [ $# -lt 8 ] && internal_fail "parameters missing"

   local unused="$1" ; shift
   local name="$1"; shift
   local url="$1"; shift
   local branch="$1"; shift
   local tag="$1"; shift
   local sourcetype="$1"; shift
   local sourceoptions="$1"; shift
   local dstdir="$1"; shift

   log_info "Status ${C_MAGENTA}${C_BOLD}${dstdir}${C_INFO} ..."

   local options

   options="`get_sourceoption "${sourceoptions}" "status"`"

   (
      exekutor cd "${dstdir}" &&
      exekutor git ${OPTION_GITFLAGS} status "$@" ${options} ${OPTION_GITOPTIONS} >&2
   ) || fail "git status of \"${dstdir}\" failed"
}


git_set_url_project()
{
   log_entry "git_set_url_project" "$@"

   local dstdir="$1"
   local remote="$2"
   local url="$3"

   (
      cd "${dstdir}" &&
      git remote set-url "${remote}" "${url}"  >&2 &&
      git fetch "${remote}"  >&2  # prefetch to get new branches
   ) || exit 1
}


git_search_local_project()
{
   log_entry "git_search_local_project [${LOCAL_PATH}]" "$@"

   local url="$1"
   local name="$2"
   local branch="$3"

   source_search_local_path "${name}" "${branch}" ".git" "NO"
}


git_plugin_initialize()
{
   log_entry "git_plugin_initialize"

   if [ -z "${MULLE_FETCH_GIT_SH}" ]
   then
      . mulle-fetch-git.sh || exit 1
   fi
}


git_plugin_initialize

:
