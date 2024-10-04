# shellcheck shell=bash
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
#   POSSIBILITY OF SUCH DAMAGE.
#

MULLE_FETCH_COMMANDS_SH='included'

#
# ## NOTE ##
#
# There is a canonical argument passing scheme, which gets passed to and
# forwarded by most function
#
# unused="$1"        # unused
# name="$2"          # name of the clone
# url="$3"           # URL of the clone
# branch="$4"        # branch of the clone
# tag="$5"           # tag to checkout of the clone
# sourcetype="$6"    # source to use for this clone
# sourceoptions="$7" # sourceoptions
# dstdir="$8"        # dstdir of this clone (absolute or relative to $PWD)
#

fetch::commands::show_plugins()
{
   local type="${1:-scm}"

   if [ -z "$MULLE_FETCH_PLUGIN_SH" ]
   then
      # shellcheck source=mulle-fetch-plugin.sh
      . "${MULLE_FETCH_LIBEXEC_DIR}/mulle-fetch-plugin.sh" || \
         fail "failed to load ${MULLE_FETCH_LIBEXEC_DIR}/mulle-fetch-plugin.sh"
   fi

   local  plugins

   plugins="`fetch::plugin::all_names "${type}" `"
   if [ ! -z "${plugins}" ]
   then
      (
         echo
         echo "Available ${type} types are:"
         printf "%s\n" "${plugins}" | sed 's/^/   /'
      )
   fi
}


fetch::commands::convenient_fetch_usage()
{
   cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} [cfetch] <url>

   You only specify the url to fetch. mulle-fetch will try to figure out from
   the URL what the name of the destination directory should be and what
   kind of repository it is downloading.

   For more options, say you want to specify the destination, use the fetch
   command instead.

      ${MULLE_EXECUTABLE_NAME} fetch help

EOF

   fetch::commands::show_plugins >&2
   exit 1
}


fetch::commands::fetch_usage()
{
   cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} fetch [options] <url> <directory>

   Specify the url to fetch and the directory to fetch into. By default the
   url is assumed to reference a git repository. If this is not the case use
   the '-s' option.

      ${MULLE_EXECUTABLE_NAME} fetch -b release https://is.gd/3a8oq2 /tmp/my-c11

Options:
   -b <branch>      : the branch to fetch
   -l <dir:dir:...> : local search path for repositories
   -o <options>     : specify options for the scm (see documentation)
   -s <scm>         : source type, either a repository or archive format (git)
   -t <tag>         : tag to checkout

   --absolute-symlinks    : create absolute symlinks instead of relative ones
   --cache-dir <dir>      : directory to cache archives
   --mirror-dir <dir>     : directory to mirror repositories (git)
   --recursive            : fetch git recursively (does nothing for other scms)
   --refresh              : refresh mirrored repositories and cached archives
   --symlink-returns-4    : if a repository was symlinked return with code 4
   --symlink              : allow symlinks to be created
   --no-symlink           : forbid symlinks to be created

EOF

   fetch::commands::show_plugins >&2
   exit 1
}


fetch::commands::exists_usage()
{
   cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} exists [options] <url>

   Check if URL exists. URL can be a file, in which case the answer is fairly
   definitive. If URL is a internet page, it checks for 404 or so (don't
   expect too much)

      ${MULLE_EXECUTABLE_NAME} exists https://foo.com/bla.git

   Returns status code 0 on success, and something else otherwise.

Options:
   -s <scm> : source type, either a repository or archive format (git)
EOF

   fetch::commands::show_plugins >&2

   exit 1
}


fetch::commands::set_url_usage()
{
   cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} set-url [options] <url> <directory>

   Specify a different origin url for a repository.

      ${MULLE_EXECUTABLE_NAME} set-url https://is.gd/3a8oq2 /tmp/my-c11

Options:
   -s <scm>         : source type, either a repository or archive format (git)
   -o <options>     : specify options for the scm (see documentation)
EOF

   fetch::commands::show_plugins >&2

   exit 1
}


fetch::commands::other_usage()
{
   cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} ${COMMAND} [options] <url> <directory>

   Specify the url to fetch. By default this is assumed to be a git repository.
   Use --scm to choose another supported source type.

Options:
   -b <branch>      : the branch to fetch
   -s <scm>         : repository or archive format (default git)
   -o <options>     : specify options for the scm (see documentation)
   -t <tag>         : tag to checkout
EOF

   fetch::commands::show_plugins >&2

   exit 1
}


fetch::commands::operation_usage()
{
   cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} operation [options]

   List the operations for the specified repository or archive format. The
   default lists operations available for git.

Options:
   -s <scm>   : repository or archive format (default git)
EOF

   fetch::commands::show_plugins >&2

   exit 1
}


fetch::commands::search_local_usage()
{
   cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} search-local [options] <name>

   Find a repository in the local search path, which is defined by
   MULLE_FETCH_SEARCH_PATH.

Options:
   -l <dir:dir:...> : local search path for repositories
   -s <scm>         : repository or archive format (default git)
   -u <url>         : file URL to look for
   -o <options>     : specify options for the scm (see documentation)
EOF

   fetch::commands::show_plugins >&2

   exit 1
}


fetch::commands::status_usage()
{
   cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} status [options]

   Show status of the specified repository.

Options:
   -s <scm>         : repository or archive format (default git)
   -o <options>     : specify options for the scm (see documentation)
EOF

   fetch::commands::show_plugins >&2

   exit 1
}


#
# In general fetch is interacted via arguments.
# There are only a few environment variables, which are assumed to be
# fairly constant and supply optional caching information
#
fetch::commands::common()
{
   log_entry "fetch::commands::common" "$@"

   local ROOT_DIR

   ROOT_DIR="`pwd -P`"

   local OPTION_BRANCH
   local OPTION_TAG
   local OPTION_SCM="git"
   local OPTION_URL
   local OPTION_SYMLINK="DEFAULT"
   local OPTION_REFRESH="DEFAULT"
   local OPTION_ABSOLUTE_SYMLINK='NO'
   local OPTION_HARDLINK='NO'
   local OPTION_SYMLINK_RETURNS_4='NO'
   local OPTION_WRITE_PROTECT='NO'
   local OPTION_OPTIONS
   local OPTION_TOOL_FLAGS
   local OPTION_TOOL_OPTIONS

#
# there are not local but can be set by the environment
#
#   local MULLE_FETCH_SEARCH_PATH
#   local MULLE_FETCH_ARCHIVE_DIR
#   local MULLE_FETCH_MIRROR_DIR

   # need this for usage now

   # shellcheck source=mulle-fetch-source.sh
   include "mulle-fetch::source"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            ${USAGE}
         ;;

         --git|--tar|--file)
            OPTION_SCM="${1:2}"
         ;;

         --recursive)
            GIT_FETCH_FLAGS=--recursive
         ;;

         --refresh)
            OPTION_REFRESH='YES'
         ;;

         --no-refresh)
            OPTION_REFRESH='NO'
         ;;

         --symlink|--symlinks)
            OPTION_SYMLINK='YES'
         ;;

         --hardlink)
            OPTION_HARDLINK='YES'
         ;;

         --no-symlink|--no-symlinks)
            OPTION_ABSOLUTE_SYMLINK='NO'
         ;;

         --absolute-symlinks)
            OPTION_SYMLINK='YES'
            OPTION_ABSOLUTE_SYMLINK='YES'
         ;;

         --no-absolute-symlinks)
            OPTION_ABSOLUTE_SYMLINK='NO'
         ;;

         # -2 was the old way
         -2|-4|--symlink-returns-4|--symlink-returns-2)
            OPTION_SYMLINK='YES'
            OPTION_SYMLINK_RETURNS_4='YES'
         ;;

         --cache-dir)
            [ $# -eq 1 ] && fail "Missing argument to \"$1\""
            shift

            MULLE_FETCH_ARCHIVE_DIR="$1"
         ;;

         --github|--github-user)
            [ $# -eq 1 ] && fail "Missing argument to \"$1\""
            shift

            OPTION_GITHUB_USER="$1"
         ;;

         --mirror-dir)
            [ $# -eq 1 ] && fail "Missing argument to \"$1\""
            shift

            MULLE_FETCH_MIRROR_DIR="$1"
         ;;

         --write-protect)
            OPTION_WRITE_PROTECT='YES'
         ;;

         #
         # more common flags
         #
         -b|--branch)
            [ $# -eq 1 ] && fail "Missing argument to \"$1\""
            shift

            OPTION_BRANCH="$1"
         ;;

         -l|--search-path|--locals-search-path)
            [ $# -eq 1 ] && fail "Missing argument to \"$1\""
            shift

            MULLE_FETCH_SEARCH_PATH="$1"
         ;;

         -o|--options)
            [ $# -eq 1 ] && fail "Missing argument to \"$1\""
            shift

            OPTION_OPTIONS="$1"
         ;;

         -s|--source|--scm)
            [ $# -eq 1 ] && fail "Missing argument to \"$1\""
            shift

            OPTION_SCM="$1"
         ;;

         -t|--tag)
            [ $# -eq 1 ] && fail "Missing argument to \"$1\""
            shift

            OPTION_TAG="$1"
         ;;

         -u|--url)
            [ $# -eq 1 ] && fail "Missing argument to \"$1\""
            shift

            OPTION_URL="$1"
         ;;

         #
         # ugly hackish options
         #
         --curl-flags)
            [ $# -eq 1 ] && fail "Missing argument to \"$1\""
            shift

            OPTION_CURL_FLAGS="$1"
         ;;


         --tool-flags)
            [ $# -eq 1 ] && fail "Missing argument to \"$1\""
            shift

            OPTION_TOOL_FLAGS="$1"
         ;;

         --tool-options)
            [ $# -eq 1 ] && fail "Missing argument to \"$1\""
            shift

            OPTION_TOOL_OPTIONS="$1"
         ;;

         -*)
            log_error "${MULLE_EXECUTABLE_FAIL_PREFIX}: Unknown fetch option $1"
            ${USAGE}
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   # shellcheck source=mulle-fetch-plugin.sh
   include "mulle-fetch::plugin"

   fetch::plugin::load "symlink"        # brauchen wir immer
   fetch::plugin::load "${OPTION_SCM}"

   [ -z "${DEFAULT_IFS}" ] && _internal_fail "IFS fail"

   local directory
   local name
   local url
   local cmd
   local repo

   # this is old code that should die
   if [ ! -z "${OPTION_GITHUB_USER}" ]
   then
      case "${url}" in
         *://*)
         ;;

         *)
            repo="${url}"
            url="https://github.com/${OPTION_GITHUB_USER}"
            case "${OPTION_SCM}" in
               git)
                  url="${url}/${repo}.git"
               ;;

               tar)
                  url="${url}/${repo}/archive/${OPTION_TAG:-latest}.tar.gz"
               ;;

               zip)
                  url="${url}/${repo}/archive/${OPTION_TAG:-latest}.zip"
               ;;
            esac
         ;;
      esac
      log_fluff "Modified URL \"${url}\""
   fi

   #
   # ugliness ensues, but having a uniform way of
   #
   if [ -z "${OPTION_URL}" ]
   then
      case "${COMMAND}" in
         fetch)
            [ $# -lt 1 ] && log_error "Missing argument to \"${COMMAND}\"" && ${USAGE}
            [ $# -gt 2 ] && log_error "superfluous arguments \"$*\" to \"${COMMAND}\"" && ${USAGE}

            url="$1"
            directory="$2"

            if [ -z "${directory}" ]
            then
               r_extensionless_basename "${url}"
               directory="${RVAL}"
            fi
         ;;

         set-url)
            [ $# -lt 2 ] && log_error "Missing argument to \"${COMMAND}\"" && ${USAGE}
            [ $# -gt 2 ] && log_error "superfluous arguments \"$*\" to \"${COMMAND}\"" && ${USAGE}

            url="$1"
            directory="$2"
         ;;

         search-local|exists)
            [ $# -eq 0 ] && log_error "Missing argument to \"${COMMAND}\"" && ${USAGE}
            [ $# -ne 1 ] && log_error "superfluous arguments \"$*\" to \"${COMMAND}\"" && ${USAGE}
            url="$1"
         ;;

         *)
            [ $# -eq 0 ] && log_error "Missing argument to \"${COMMAND}\"" && ${USAGE}
            [ $# -ne 1 ] && log_error "superfluous arguments \"$*\" to \"${COMMAND}\"" && ${USAGE}
            directory="$1"
         ;;
      esac
   else
      # uniform scheme, when URL is passed
      # don't check superfluous or absent arguments

      url="${OPTION_URL}"
      directory="$1"
   fi

   r_basename "${directory}"
   name="${RVAL}"

   case "${COMMAND}" in
      fetch)
         if [ "${OPTION_WRITE_PROTECT}" = 'YES' ] && [ -d "${directory}" ]
         then
            log_fluff "Unprotecting possibly write protected files"
            exekutor find "${directory}" -type f -exec chmod ug+w {} \;
         fi
      ;;
   esac

   local rval

   fetch::operation::do "${COMMAND}" "unused" \
                                     "${name}" \
                                     "${url}" \
                                     "${OPTION_BRANCH}" \
                                     "${OPTION_TAG}" \
                                     "${OPTION_SCM}" \
                                     "${OPTION_OPTIONS}" \
                                     "${directory}"
   rval=$?

   if [ $rval -eq 0 ]
   then
      case "${COMMAND}" in
         fetch)
            if [ "${OPTION_WRITE_PROTECT}" = 'YES' ] && [ -d "${directory}" ]
            then
               log_fluff "Write protecting fetched files"
               exekutor find "${directory}" -type f -exec chmod ugo-w {} \;
            fi
         ;;
      esac
   fi

   return $rval
}


fetch::commands::checkout_main()
{
   log_entry "fetch::commands::checkout_main" "$@"

   USAGE="fetch_checkout_usage"
   COMMAND="checkout"
   fetch::commands::common "$@"
}

fetch::commands::exists_main()
{
   log_entry "fetch::commands::exists_main" "$@"

   USAGE="fetch::commands::exists_usage"
   COMMAND="exists"
   fetch::commands::common "$@"
}


fetch::commands::fetch_main()
{
   log_entry "fetch::commands::fetch_main" "$@"

   USAGE="fetch::commands::fetch_usage"
   COMMAND="fetch"
   fetch::commands::common "$@"
}


fetch::commands::operation_main()
{
   log_entry "fetch::commands::operation_main" "$@"

   USAGE="fetch::commands::operation_usage"
   COMMAND="operation"
   fetch::commands::common "$@"
}


fetch::commands::search_local_main()
{
   log_entry "fetch::commands::search_local_main" "$@"

   USAGE="fetch::commands::search_local_usage"
   COMMAND="search-local"

   log_fluff "MULLE_FETCH_SEARCH_PATH: ${MULLE_FETCH_SEARCH_PATH}"
   fetch::commands::common "$@"
}


fetch::commands::set_url_main()
{
   log_entry "fetch::commands::set_url_main" "$@"

   USAGE="fetch::commands::set_url_usage"
   COMMAND="set-url"
   fetch::commands::common "$@"
}


fetch::commands::status_main()
{
   log_entry "fetch::commands::status_main" "$@"

   USAGE="status_usage"
   COMMAND="status"
   fetch::commands::common "$@"
}


fetch::commands::update_main()
{
   log_entry "fetch::commands::update_main" "$@"

   USAGE="fetch::commands::other_usage"
   COMMAND="update"
   fetch::commands::common "$@"
}


fetch::commands::upgrade_main()
{
   log_entry "fetch::commands::upgrade_main" "$@"

   USAGE="fetch::commands::other_usage"
   COMMAND="upgrade"
   fetch::commands::common "$@"
}


fetch::commands::convenient_craftinfo_fetch()
{
   log_entry "fetch::commands::convenient_craftinfo_fetch" "$@"

   local name="$1"

   local rval=1

   local urls

   urls="${CRAFTINFO_REPOS:-https://github.com/craftinfo}"

   local url

   IFS='|'; shell_disable_glob
   for url in ${urls}
   do
      r_basename "${url}"
      user="${RVAL}"

      # TODO: use mulle-fetch/github code for proper json fetch
      # use mulle-domain to figure out how to get repo list
      if rexekutor "${CURL:-curl}" -fsSL "https://raw.githubusercontent.com/${user}/${name}-craftinfo/master/url"
      then
         rval=0
         break
      fi
   done
   IFS="${DEFAULT_IFS}"; shell_enable_glob

   return $rval
}


fetch::commands::convenient_fetch_main()
{
   log_entry "fetch::commands::convenient_fetch_main" "$@"

   local OPTION_DIRECTORY=
   local OPTION_PRINT='YES'

   USAGE="fetch::commands::convenient_fetch_usage"
   COMMAND="fetch"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h|--help|help)
            fetch::commands::convenient_fetch_usage
         ;;

         -d)
            [ $# -eq 1 ] && fetch::commands::convenient_fetch_usage "Missing argument to \"$1\""
            shift

            OPTION_DIRECTORY="$1"
         ;;

         --print)
            OPTION_PRINT='YES'
         ;;

         --no-print)
            OPTION_PRINT='NO'
         ;;

         -*)
            fetch::commands::convenient_fetch_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac
      shift
   done

   [ $# -lt 1 -o $# -gt 2 ] && fetch::commands::convenient_fetch_usage

   local url
   local directory="${OPTION_DIRECTORY}"

   url="$1"
   if [ $# -eq 2 ]
   then
      directory="$2"
   fi

   local user
   local project
   local domain
   local s

   case "${url}" in
      craftinfo:*)
         url="`fetch::commands::convenient_craftinfo_fetch "${url#craftinfo:}" `"
         if [ $? -ne 0 ]
         then
            fail "No craftinfo found for \"${url#craftinfo:}\""
         fi
      ;;

      *://*|*@*:*)
         # plain URLs keep as is
      ;;


      *:*)
         s="`rexekutor mulle-domain parse-url "${url}" \
             | rexekutor mulle-domain compose -`"

         log_verbose "Transformed \"${url}\" into \"${s}\" with mulle-domain"
         url="${s}"
      ;;

      */*)
         r_extended_identifier "${url%%/*}"
         user="${RVAL}"

         r_extended_identifier "${url##*/}"
         project="${RVAL}"

         if [ "${url#*:}" = "${user}/${project}" ]
         then
            url="https://github.com/${user}/${project}.git"
            log_verbose "Expanded ${user}/${project} into ${url}"
         fi
      ;;

      *)
         if [ ! -z "${OPTION_GITHUB_USER}" ]
         then
            r_extended_identifier "${url}"
            project="${RVAL}"

            if [ "${url}" = "${project}" ]
            then
               url="https://github.com/${OPTION_GITHUB_USER}/${project}.git"
               log_verbose "Expanded ${OPTION_GITHUB_USER}/${project} into ${url}"
            fi
         fi
      ;;
   esac

   local guessed_scheme
   local guessed_domain
   local guessed_repo
   local guessed_user
   local guessed_branch
   local guessed_scm
   local guessed_tag

   local text
   local rc

   text="`rexekutor "${MULLE_DOMAIN:-mulle-domain}" \
         ${MULLE_TECHNICAL_FLAGS} \
         ${MULLE_DOMAIN_FLAGS} \
       parse-url \
         --prefix "guessed_" \
         "${url}" `"

   case $? in
      0|4)
         eval "${text}"
      ;;
   esac

   if [ -z "${guessed_scm}" ]
   then
      fail "Couldn't figure out what kind of repository \"${url}\" is."
   fi

   if [ -z "${directory}" ]
   then
      case "${guessed_scm}" in
         file)
            r_basename "${guessed_repo}"
            directory="${RVAL}"
         ;;

         *)
            case "${guessed_tag}" in
               ${GIT_DEFAULT_BRANCH:-master}|master|main|trunk|release)
                  directory="${guessed_repo}"
               ;;

               *)
                  r_concat "${guessed_repo}" "${guessed_tag}" "-"
                  directory="${RVAL}"
               ;;
            esac
         ;;
      esac
   fi

   fetch::commands::common --scm "${guessed_scm}" "${url}" "${directory}"

   # print where something has been unpacked so that a script can run with it
   if [ "${OPTION_PRINT}" = 'YES' ]
   then
      printf "%s\n" "${directory}"
   fi
}



fetch::commands::initialize()
{
   log_entry "fetch::commands::initialize"

   include "fetch::operation"
}


fetch::commands::initialize

:
