#! /usr/bin/env bash
#
#   Copyright (c) 2015 Nat! - Mulle kybernetiK
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
MULLE_FETCH_GIT_SH="included"

#
# prefer origin over others, probably could be smarter
# by passing in the desired branch and figuring more
# stuff out
#
git_get_default_remote()
{
   local i
   local match

   match=""
   IFS=$'\n'
   for i in `( cd "$1" ; git remote)`
   do
      case "$i" in
         origin)
            match="$i"
            break
         ;;

         *)
            if [ -z "${match}" ]
            then
               match="$i"
            fi
         ;;
      esac
   done

   IFS="${DEFAULT_IFS}"

   printf "%s\n" "$match"
}


git_add_remote()
{
   local repository="$1"
   local remote="$2"
   local url="$3"

   [ -z "${repository}" -o -z "${remote}" -o -z "${url}" ] && internal_fail "empty parameter"
   [ ! -d "${repository}" ] && internal_fail "directory does not exist"
   [ -z "${GIT}" ] && "git is not in PATH"

   (
      rexekutor cd "${repository}" &&
      exekutor "${GIT}" remote add "${remote}" "${url}"
   )
}


git_has_remote()
{
   local repository="$1"
   local remote="$2"

   [ -z "${repository}" -o -z "${remote}" ] && internal_fail "empty parameter"
   [ ! -d "${repository}" ] && internal_fail "directory does not exist"
   [ -z "${GIT}" ] && "git is not in PATH"

   (
      local remotes
      rexekutor cd "${repository}" &&
      rexekutor fgrep -q -x -e "${remote}" <<< "`rexekutor git remote`"
   )
}


git_remove_remote()
{
   local repository="$1"
   local remote="$2"

   [ -z "${repository}" -o -z "${remote}" ] && internal_fail "empty parameter"
   [ ! -d "${repository}" ] && internal_fail "directory does not exist"
   [ -z "${GIT}" ] && "git is not in PATH"

   (
      rexekutor cd "${repository}" &&
      exekutor "${GIT}" remote remove "${remote}"
   )
}


git_set_url()
{
   local repository="$1"
   local remote="$2"
   local url="$3"

   [ -z "${repository}" -o -z "${remote}" -o -z "${url}" ] && internal_fail "empty parameter"
   [ ! -d "${repository}" ] && internal_fail "directory does not exist"
   [ -z "${GIT}" ] && "git is not in PATH"

   (
      rexekutor cd "${repository}" &&
      exekutor "${GIT}" remote set-url "${remote}" "${url}"
   )
}


git_unset_default_remote()
{
   local repository="$1"

   [ -z "${repository}" ] && internal_fail "empty parameter"
   [ ! -d "${repository}" ] && internal_fail "directory does not exist"
   [ -z "${GIT}" ] && "git is not in PATH"

   (
      rexekutor cd "${repository}" &&
      exekutor "${GIT}" branch --unset-upstream
   )
}


git_set_default_remote()
{
   local repository="$1"
   local remote="$2"
   local url="$3"

   [ -z "${repository}" -o -z "${remote}" -o -z "${url}" ] && internal_fail "empty parameter"
   [ ! -d "${repository}" ] && internal_fail "directory does not exist"
   [ -z "${GIT}" ] && "git is not in PATH"

   local repository="$1"
   local remote="$2"
   local branch="$3"

   (
      rexekutor cd "${repository}" &&
      exekutor "${GIT}" fetch "${remote}" &&
      exekutor "${GIT}" branch --set-upstream-to "${remote}/${branch}"
   )
}


git_has_branch()
{
   local repository="$1"
   local branch="$2"

   [ -z "${repository}" -o -z "${branch}" ] && internal_fail "empty parameter"
   [ ! -d "${repository}" ] && internal_fail "directory does not exist"
   [ -z "${GIT}" ] && "git is not in PATH"

   (
      rexekutor cd "${repository}" &&
      rexekutor "${GIT}" branch | cut -c3- | fgrep -q -s -x -e "$2" > /dev/null
   )
}


git_has_fetched_tags()
{
   [ -z "$1" ] && internal_fail "empty parameter"
   [ ! -d "$1" ] && internal_fail "directory does not exist"
   [ -z "${GIT}" ] && "git is not in PATH"

   (
      local tags

      rexekutor cd "$1" &&
      tags="`rexekutor git show-ref --tags | head -1`" &&
      [ ! -z "${tags}" ]
   )
}


git_has_tag()
{
   [ -z "$1" -o -z "$2" ] && internal_fail "empty parameter"
   [ ! -d "$1" ] && internal_fail "directory does not exist"
   [ -z "${GIT}" ] && "git is not in PATH"

   (
      rexekutor cd "$1" &&
      rexekutor "${GIT}" tag -l | fgrep -s -x -e "$2" > /dev/null
   )
}


git_branch_contains_tag()
{
   [ -z "$1" -o -z "$2" -o -z "$3" ] && internal_fail "empty parameter"
   [ ! -d "$1" ] && internal_fail "directory does not exist"
   [ -z "${GIT}" ] && "git is not in PATH"

   (
      rexekutor cd "$1" &&
      rexekutor "${GIT}" branch --contains "$3"| cut -c3- | fgrep -s -x -e "$2" > /dev/null
   )

}


git_get_branch()
{
   [ -z "$1" ] && internal_fail "empty parameter"
   [ ! -d "$1" ] && internal_fail "directory does not exist"
   [ -z "${GIT}" ] && "git is not in PATH"

   (
      rexekutor cd "$1" &&
      rexekutor "${GIT}" rev-parse --abbrev-ref HEAD 2> /dev/null
   )
}


append_dir_to_gitignore_if_needed()
{
   local directory=$1

   [ -z "${directory}" ] && internal_fail "empty directory"

   case "${directory}" in
      "${REPOS_DIR}/"*)
         return 0
      ;;
   esac

   # strip slashes
   case "${directory}" in
      /*/)
         directory="`printf "%s\n" "$1" | sed 's/.$//' | sed 's/^.//'`"
      ;;

      /*)
         directory="`printf "%s\n" "$1" | sed 's/^.//'`"
      ;;

      */)
         directory="`echo "/$1" | sed 's/.$//'`"
      ;;

      *)
         directory="$1"
      ;;
   esac

   #
   # prepend \n because it is safer, in case .gitignore has no trailing
   # LF which it often seems to not have
   # fgrep is bugged on at least OS X 10.x, so can't use -e chaining
   if [ -f ".gitignore" ]
   then
      local pattern0
      local pattern1
      local pattern2
      local pattern3


      # variations with leadinf and trailing slashes
      pattern0="${directory}"
      pattern1="${pattern0}/"
      pattern2="/${pattern0}"
      pattern3="/${pattern0}/"

      if fgrep -q -s -x -e "${pattern0}" .gitignore ||
         fgrep -q -s -x -e "${pattern1}" .gitignore ||
         fgrep -q -s -x -e "${pattern2}" .gitignore ||
         fgrep -q -s -x -e "${pattern3}" .gitignore
      then
         return
      fi
   fi

   local line
   local lf
   local terminator

   line="/${directory}"
   terminator="`rexekutor tail -c 1 ".gitignore" 2> /dev/null | tr '\012' '|'`"

   if [ "${terminator}" != "|" ]
   then
      line="${lf}/${directory}"
   fi

   log_info "Adding \"/${directory}\" to \".gitignore\""
   redirect_append_exekutor .gitignore printf "%s\n" "${line}" || fail "Couldn\'t append to .gitignore"
}


fork_and_name_from_url()
{
   local url="$1"

   local name
   local hack
   local fork

   hack="`LC_ALL=C sed -e 's|^[^:]*:|:|' <<< "${url}"`"
   name="`basename -- "${hack}"`"
   fork="`dirname -- "${hack}"`"
   fork="`basename -- "${fork}"`"

   case "${hack}" in
      /*/*|:[^/]*/*|://*/*/*)
      ;;

      *)
         fork="__other__"
      ;;
   esac

   printf "%s\n" "${fork}" | LC_ALL=C sed -e 's|^:||'
   printf "%s\n" "${name}"
}

#
# its important for mulle-sourcetree that git_is_repository and
# git_is_bare_repository do not actually need a git installed
#
git_is_repository()
{
   [ -z "$1" ] && internal_fail "empty parameter"

   [ -d "${1}/.git" ] || [ -d  "${1}/refs" -a -f "${1}/HEAD" ]
}


# https://stackoverflow.com/questions/9610131/how-to-check-the-validity-of-a-remote-git-repository-url
git_is_valid_remote_url()
{
   [ -z "$1" ] && internal_fail "empty parameter"

   GIT_ASKPASS=/bin/true git ls-remote "$1" > /dev/null 2>&1
}


git_is_bare_repository()
{
   local is_bare

   if [ -z "${GIT}" ]
   then
      # literal tab character in sed command
      egrep -q -s '^[    ]*bare\ =\ true$' "$1/.git/config"
      return $?
   fi

   # if bare repo, we can only clone anyway
   is_bare="$(
               rexekutor cd "$1" &&
               rexekutor "${GIT}" rev-parse --is-bare-repository 2> /dev/null
             )"
   if [ -z "${is_bare}" ]
   then
      [ ! -x "$1" ]    && internal_fail "Given wrong or protected directory \"$1\" (${PWD})"
      [ -d "$1/.git" ] && internal_fail "Given non git directory \"$1\" (${PWD})"
      return 1
   fi

   [ "${is_bare}" = "true" ]
}


git_initialize()
{
   log_entry "git_initialize"

   GIT="${GIT:-`command -v "git"`}"

   if [ -z "${MULLE_FETCH_SOURCE_SH}" ]
   then
      # shellcheck source=mulle-fetch-source.sh
      . "${MULLE_FETCH_LIBEXEC_DIR}/mulle-fetch-source.sh" || exit 1
   fi

   # this is an actual GIT variable
   if [ -z "${GIT_TERMINAL_PROMPT}" ]
   then
      GIT_TERMINAL_PROMPT="0"
   fi
   export GIT_TERMINAL_PROMPT
}


git_initialize

:
