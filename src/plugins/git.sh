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
MULLE_FETCH_PLUGIN_SCM_GIT_SH="included"


r_git_get_mirror_url()
{
   log_entry "r_git_get_mirror_url" "$@"

   local url="$1"; shift
   local options="$2" ; shift

   local _name
   local _fork

   __fork_and_name_from_url "${url}"

   local mirrordir

   mkdir_if_missing "${MULLE_FETCH_MIRROR_DIR}/${_fork}"
   mirrordir="${MULLE_FETCH_MIRROR_DIR}/${_fork}/${_name}" # try to keep it global

   local match

   if [ ! -d "${mirrordir}" ]
   then
      log_verbose "Set up git-mirror \"${mirrordir}\""
      if ! exekutor git ${OPTION_TOOL_FLAGS} clone --mirror ${options} ${OPTION_TOOL_OPTIONS} -- "${url}" "${mirrordir}" >&2
      then
         log_error "git clone of \"${url}\" into \"${mirrordir}\" failed"
         RVAL=
         return 1
      fi
   else
      case "${OPTION_REFRESH}" in
         YES|DEFAULT)
         (
            log_verbose "Refreshing git-mirror \"${mirrordir}\""
            rexekutor cd "${mirrordir}";
            if ! exekutor git ${OPTION_TOOL_FLAGS} fetch >&2
            then
               log_warning "git fetch from \"${url}\" failed, using old state"
            fi
         )
         ;;
      esac
   fi

   RVAL="${mirrordir}"
}


_r_git_check_file_url()
{
   local url="$1"

   case "${url}" in
      "file://"*)
         url="${url:7}"
      ;;
   esac

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
         log_error "Repository \"${url}\" does not exist ($PWD)"
      fi
      RVAL=
      return 1
   fi

   RVAL="${url}"
   return 0
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

   local dstdir
   local options
   local mirroroptions

   dstdir="${dstdir}"
   if [ ! -z "${sourceoptions}" ]
   then
      options="`get_sourceoption "${sourceoptions}" "fetch"`"
   fi
   mirroroptions="${options}"

   if [ ! -z "${branch}" ]
   then
      log_info "Cloning branch ${C_RESET_BOLD}$branch${C_INFO} of \
${C_MAGENTA}${C_BOLD}${url}${C_INFO} into \"${dstdir}\" ..."
      r_concat "${options}" "-b ${branch}"
      options="${RVAL}"
   else
      log_info "Cloning ${C_MAGENTA}${C_BOLD}${url}${C_INFO} into \"${dstdir}\" ..."
   fi

   # MEMO: options are unused currently!!
   r_concat "${options}" "--single-branch"
   options="${RVAL}"

   local originalurl

   #
   # "remote urls" go through mirror
   # local urls get checked ahead for better error messages
   #
   case "${url}" in
      file:*)
         _r_git_check_file_url "${url}" || return 1
         url="${RVAL}"
      ;;

      *:*)
         if [ ! -z "${MULLE_FETCH_MIRROR_DIR}" ]
         then
            originalurl="${url}"
            r_git_get_mirror_url "${url}" "${mirroroptions}" || return 1
            url="${RVAL}"

            r_concat "--origin mirror" "${options}"
            options="${RVAL}"
         fi
      ;;

      *)
         _r_git_check_file_url "${url}" || return 1
         url="${RVAL}"
      ;;
   esac

   if [ "${dstdir}" = "${url}" ]
   then
      log_error "Clone source \"${url}\" is same as destination."
      return 1
   fi

   #
   # To actually pull a minimal set, clone --single-branch is not good,
   # because it fetches the tags, which in turn pull in most of the refs
   # regardless
   #
   local rval

   local GIT_QUIET="-q"

   if [ "${MULLE_FLAG_LOG_FLUFF}" = 'YES' ]
   then
      GIT_QUIET=""
   fi

#   if : # [ -z "${tag}" ]
#   then
      mkdir_if_missing "${dstdir}" &&
      (
         exekutor cd "${dstdir}"
         exekutor git init ${GIT_QUIET} &&
         exekutor git remote add origin "${url}" || exit 1

         if [ -z "${branch}" ]
         then
            local branches

            branches="`exekutor git ls-remote --heads origin | sed -e 's|.*/||'`" || exit 1
            if [ ! -z "${branches}" ]
            then
               local name
               local names

               names="${GIT_DEFAULT_BRANCH}:master:main:trunk:release"

               #
               # expansion into separated names by IFS only happens from
               # a variable ? bash WTF
               #
               IFS=":"; set -f
               for name in ${names}
               do
                  if [ ! -z "${name}" ]
                  then
                     if grep -s -q -x "${name}" <<< "${branches}"
                     then
                        branch="${name}"
                        break
                     fi
                  fi
               done
               IFS="${DEFAULT_IFS}"; set +f

               if [ -z "${branch}" ]
               then
                  branch="`head -1 <<< "${branches}"`"
                  log_info "Guessed branch \"${branch}\" as default branch for \"${url}\""
               fi
            else
               branch="${GIT_DEFAULT_BRANCH:-master}"
            fi
         fi

         # TODO: could use --shallow here probably
         exekutor git fetch ${GIT_QUIET} --no-tags "origin" "${branch}" &&
         exekutor git checkout ${GIT_QUIET} -b "${branch}" "origin/${branch}"
      ) >&2
      rval="$?"
#   else
#      exekutor git ${OPTION_TOOL_FLAGS} "clone" ${options} ${OPTION_TOOL_OPTIONS} \
#                                       -- "${url}" "${dstdir}"  >&2
#      rval="$?"
#   fi

   if [ "$rval" -ne 0 ]
   then
      rmdir_safer "${dstdir}"
      log_error "git clone of \"${url}\" into \"${dstdir}\" failed"
      return 1
   fi

   if [ ! -z "${originalurl}" ]
   then
      git_unset_default_remote "${dstdir}"
      if git_has_remote "${dstdir}" "origin"
      then
         git_remove_remote "${dstdir}" "origin"
      fi
      git_add_remote "${dstdir}" "origin" "${originalurl}"

      #
      # too expensive for me, because it must fetch now to
      # get the origin branch. Funnily enough git works fine
      # even without it..
      #
      if [ "${MULLE_FETCH_SET_GIT_DEFAULT_REMOTE}" = 'YES' ]
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
         if [ ! -z "${MULLE_FETCH_MIRROR_DIR}" ]
         then
            r_git_get_mirror_url "${url}" || return 1
            remote="mirror"
         fi
      ;;
   esac

   printf "%s\n" "${remote}"
}


###
### Plugin API
###

git_fetch_project()
{
   log_entry "git_fetch_project" "$@"

#   local unused="$1"
   local name="$2"
   local url="$3"

   log_info "Fetching ${C_MAGENTA}${C_BOLD}${name}${C_INFO} from \
${C_RESET_BOLD}${url}${C_INFO}."

   source_prepare_filesystem_for_fetch "${dstdir}"

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

   [ -z "${dstdir}" ]                    && internal_fail "dstdir is empty"
   [ -z "${tag}" -a -z "${branch}" ]     && internal_fail "tag and branch are empty"

   local options

   if [ ! -z "${sourceoptions}" ]
   then
      options="`get_sourceoption "${sourceoptions}" "checkout"`"
   fi

#   local branch
   local curr_branch
   local need_fetch

   need_fetch='NO'
   curr_branch="`git_get_branch "${dstdir}"`"

   if [ -z "${tag}" ]
   then
      if [ "${curr_branch}" != "${branch}" ]
      then
         need_fetch='YES'
      fi
      log_info "Checking out branch ${C_RESET_BOLD}${branch}${C_INFO} of \
${C_MAGENTA}${C_BOLD}${name}${C_INFO} ..."
   else
      if [ ! -z "${branch}" ]
      then
         log_warning "Branch ${C_RESET_BOLD}${branch}${C_WARNING} of \
${C_MAGENTA}${C_BOLD}${name}${C_WARNING} ignored as tag \
${C_RESET_BOLD}${tag}${C_WARNING} is set"
      fi

      if ! git_has_tag "${dstdir}" "${tag}"
      then
         need_fetch='YES'
      fi
      log_info "Checking out tag ${C_RESET_BOLD}${tag}${C_INFO} of \
${C_MAGENTA}${C_BOLD}${name}${C_INFO} ..."
   fi

   if [ "${need_fetch}" = 'YES' ]
   then
      (
         exekutor cd "${dstdir}" &&
         exekutor git ${OPTION_TOOL_FLAGS} fetch --all --tags
      ) || return 1
   fi

   (
      exekutor cd "${dstdir}" &&
      exekutor git ${OPTION_TOOL_FLAGS} checkout ${options} "${tag:-${branch}}" >&2
   ) || return 1

   if [ $? -ne 0 ]
   then
      log_error "Checkout failed, moving ${C_CYAN}${C_BOLD}${dstdir}${C_ERROR} \
to ${C_CYAN}${C_BOLD}${dstdir}.failed${C_ERROR}"
      log_error "You need to fix this manually and then move it back."

      rmdir_safer "${dstdir}.failed"
      exekutor mv "${dstdir}" "${dstdir}.failed"  >&2
      return 1
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

   if [ ! -z "${sourceoptions}" ]
   then
      options="`get_sourceoption "${sourceoptions}" "update" `"
   fi
   remote="`_get_fetch_remote "${url}"`" || internal_fail "can't figure out remote"

   log_info "Fetching ${C_MAGENTA}${C_BOLD}${dstdir#${PWD}/}${C_INFO} ..."

   (
      exekutor cd "${dstdir}" &&
      exekutor git ${OPTION_TOOL_FLAGS} fetch "$@" ${options} ${OPTION_TOOL_OPTIONS} "${remote}" >&2
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

   if [ ! -z "${sourceoptions}" ]
   then
      options="`get_sourceoption "${sourceoptions}" "upgrade"`"
   fi
   remote="`_get_fetch_remote "${url}"`" || internal_fail "can't figure out remote"

   log_info "Pulling ${C_MAGENTA}${C_BOLD}${dstdir}${C_INFO} ..."

   (
      exekutor cd "${dstdir}" &&
      exekutor git ${OPTION_TOOL_FLAGS} pull "$@" ${sourceoptions} ${OPTION_TOOL_OPTIONS} \
                                           "${remote}" >&2
   ) || fail "git pull of \"${dstdir}\" failed"

   if [ ! -z "${tag}" ]
   then
      git_checkout "$@" >&2
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

   if [ ! -z "${sourceoptions}" ]
   then
      options="`get_sourceoption "${sourceoptions}" "status"`"
   fi
   (
      exekutor cd "${dstdir}" &&
      exekutor git ${OPTION_TOOL_FLAGS} status "$@" ${options} ${OPTION_TOOL_OPTIONS} >&2
   ) || fail "git status of \"${dstdir}\" failed"
}


git_set_url_project()
{
   log_entry "git_set_url_project" "$@"

#   local unused="$1"
   local name="$2"
   local url="$3"
#   local branch="$4"
#   local tag="$5"
#   local sourcetype="$6"
#   local sourceoptions="$7"
   local dstdir="$8"

   local remote

   remote="`git_get_default_remote "${dstdir}"`" || exit 1

   (
      cd "${dstdir}" &&
      git remote set-url "${remote}" "${url}" >&2 &&
      git fetch "${remote}" >&2  # prefetch to get new branches
   ) || exit 1
}


git_search_local_project()
{
   log_entry "git_search_local_project [${MULLE_FETCH_SEARCH_PATH}]" "$@"

#   local unused="$1"
   local name="$2"
   local url="$3"
   local branch="$4"
#   local tag="$5"
#   local sourcetype="$6"
#   local sourceoptions="$7"
#   local dstdir="$8"

   if r_source_search_local_path "${name}" "${branch}" ".git" 'NO' "${url}"
   then
      echo ${RVAL}
      return 0
   fi

   return 1
}


git_exists_project()
{
   log_entry "git_exists_project" "$@"

   local url="$3"             # URL of the clone

   case "${url}" in
      file://*)
         source_validate_file_url "${url}"
         return $?
      ;;

      *:*)
      ;;

      *)
         if source_validate_file_url "${url}"
         then
            return 0
         fi
      ;;
   esac

   git_is_valid_remote_url "${url}"
}


git_guess_project()
{
   log_entry "git_guess_project" "$@"

   local url="$3"      # URL of the clone

   if [ -z "${MULLE_FETCH_URL_SH}" ]
   then
      # shellcheck source=src/mulle-fetch-archive.sh
      . "${MULLE_FETCH_LIBEXEC_DIR}/mulle-fetch-url.sh" || exit 1
   fi

   r_url_get_path "${url}"
   r_extensionless_basename "${RVAL}"
   printf "%s\n" "${RVAL}"
}


git_plugin_initialize()
{
   log_entry "git_plugin_initialize"

   if [ -z "${MULLE_FETCH_GIT_SH}" ]
   then
      # shellcheck source=src/mulle-fetch-git.sh
      . "${MULLE_FETCH_LIBEXEC_DIR}/mulle-fetch-git.sh" || exit 1
   fi

   if [ -z "${MULLE_FETCH_PLUGIN_SH}" ]
   then
      # shellcheck source=src/mulle-fetch-plugin.sh
      . "${MULLE_FETCH_LIBEXEC_DIR}/mulle-fetch-plugin.sh" || exit 1
   fi

   fetch_plugin_load_if_needed "symlink"
}


git_plugin_initialize

:
