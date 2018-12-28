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
#   POSSIBILITY OF SUCH DAMAGE.
#

MULLE_FETCH_FETCH_SH="included"

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
# sourcetype="$6"        # source to use for this clone
# sourceoptions="$7" # sourceoptions
# dstdir="$8"        # dstdir of this clone (absolute or relative to $PWD)
#

show_plugins()
{
   if [ -z "$MULLE_FETCH_PLUGIN_SH" ]
   then
      # shellcheck source=mulle-fetch-plugin.sh
      . "${MULLE_FETCH_LIBEXEC_DIR}/mulle-fetch-plugin.sh" || \
         fail "failed to load ${MULLE_FETCH_LIBEXEC_DIR}/mulle-fetch-plugin.sh"
   fi

   local  plugins

   plugins="`fetch_plugin_all_names`"
   if [ ! -z "${plugins}" ]
   then
      (
         echo
         echo "Available source types are:"
         echo "${plugins}" | sed 's/^/   /'
      )
   fi
}


fetch_fetch_usage()
{
   cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} fetch [options] <url> <directory>

   Specify the url to fetch and the directory to fetch into.
   By default the url is assumed to reference a git repository.

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
   --refresh              : refresh mirrored repositories and cached archives
   --symlink-returns-2    : if a repository was symlinked return with code 2
   --symlink              : allow symlinks to be create
EOF

   show_plugins >&2
   exit 1
}


fetch_guess_usage()
{
   cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} guess [options] <url>

   Guess the resulting name of the project specified by the URL.

      ${MULLE_EXECUTABLE_NAME} guess https://foo.com/bla.git?version=last

   returns "bla"

Options:
   -s <scm>         : source type, either a repository or archive format (git)
EOF

   show_plugins >&2

   exit 1
}


fetch_set_url_usage()
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

   show_plugins >&2

   exit 1
}


fetch_other_usage()
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

   show_plugins >&2

   exit 1
}


fetch_operation_usage()
{
   cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} operation [options]

   List the operations for the specified repository or archive format. The
   default lists operations available for git.

Options:
   -s <scm>   : repository or archive format (default git)
EOF

   show_plugins >&2

   exit 1
}


fetch_search_local_usage()
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

   show_plugins >&2

   exit 1
}


fetch_status_usage()
{
   cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} status [options]

   Show status of the specified repository.

Options:
   -s <scm>         : repository or archive format (default git)
   -o <options>     : specify options for the scm (see documentation)
EOF

   show_plugins >&2

   exit 1
}


#
# In general fetch is interacted via arguments.
# There are only a few environment variables, which are assumed to be
# fairly constant and supply optional caching information
#
fetch_common_main()
{
   log_entry "fetch_common_main" "$@"

   local ROOT_DIR

   ROOT_DIR="`pwd -P`"

   local OPTION_BRANCH
   local OPTION_TAG
   local OPTION_SCM="git"
   local OPTION_URL
   local OPTION_SYMLINK="DEFAULT"
   local OPTION_REFRESH="DEFAULT"
   local OPTION_ABSOLUTE_SYMLINK='NO'
   local OPTION_SYMLINK_RETURNS_2='NO'

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
   . "${MULLE_FETCH_LIBEXEC_DIR}/mulle-fetch-source.sh" || fail "failed to load ${MULLE_FETCH_LIBEXEC_DIR}/mulle-fetch-source.sh"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            ${USAGE}
         ;;

         --refresh)
            OPTION_REFRESH='YES'
         ;;

         --no-refresh)
            OPTION_REFRESH='NO'
         ;;

         --symlink)
            OPTION_SYMLINK='YES'
         ;;

         --no-symlinks)
            OPTION_ABSOLUTE_SYMLINK='NO'
         ;;

         --absolute-symlinks)
            OPTION_SYMLINK='YES'
            OPTION_ABSOLUTE_SYMLINK='YES'
         ;;

         --no-absolute-symlinks)
            OPTION_ABSOLUTE_SYMLINK='NO'
         ;;

         -2|--symlink-returns-2)
            OPTION_SYMLINK='YES'
            OPTION_SYMLINK_RETURNS_2='YES'
         ;;

         --cache-dir)
            [ $# -eq 1 ] && fail "Missing argument to \"$1\""
            shift

            MULLE_FETCH_ARCHIVE_DIR="$1"
         ;;

         --github)
            [ $# -eq 1 ] && fail "Missing argument to \"$1\""
            shift

            OPTION_GITHUB="$1"
         ;;

         --mirror-dir)
            [ $# -eq 1 ] && fail "Missing argument to \"$1\""
            shift

            MULLE_FETCH_MIRROR_DIR="$1"
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
   . "${MULLE_FETCH_LIBEXEC_DIR}/mulle-fetch-plugin.sh" || fail "failed to load ${MULLE_FETCH_LIBEXEC_DIR}/mulle-fetch-source.sh"

   fetch_plugin_load "symlink"  # brauchen wir immer
   fetch_plugin_load "${OPTION_SCM}"

   [ -z "${DEFAULT_IFS}" ] && internal_fail "IFS fail"

   local directory
   local name
   local url
   local cmd

   if [ ! -z "${OPTION_GITHUB}" ]
   then
      case "${OPTION_SCM}" in
         git)
            case "${url}" in
               *://*)
               ;;

               *)
                  url="https://github.com/${OPTION_GITHUB}/${url}.git"
               ;;
            esac
         ;;

         tar)
            url="https://github.com/${OPTION_GITHUB}/${url}/archive/${OPTION_TAG:-latest}.tar.gz"
         ;;

         zip)
            url="https://github.com/${OPTION_GITHUB}/${url}/archive/${OPTION_TAG:-latest}.zip"
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
         fetch|set-url)
            [ $# -lt 2 ] && log_error "Missing argument to \"${COMMAND}\"" && ${USAGE}
            [ $# -gt 2 ] && log_error "superflous arguments \"$*\" to \"${COMMAND}\"" && ${USAGE}

            url="$1"
            directory="$2"
         ;;

         search-local|guess)
            [ $# -eq 0 ] && log_error "Missing argument to \"${COMMAND}\"" && ${USAGE}
            [ $# -ne 1 ] && log_error "superflous arguments \"$*\" to \"${COMMAND}\"" && ${USAGE}
            url="$1"
         ;;

         *)
            [ $# -eq 0 ] && log_error "Missing argument to \"${COMMAND}\"" && ${USAGE}
            [ $# -ne 1 ] && log_error "superflous arguments \"$*\" to \"${COMMAND}\"" && ${USAGE}
            directory="$1"
         ;;
      esac
   else
      # uniform scheme, when URL is passed
      # doen't check superflous  or absent arguments

      url="${OPTION_URL}"
      directory="$1"
   fi

   name="$(basename -- "${directory}")"

   fetch_do_operation "${COMMAND}" "unused" \
                                   "${name}" \
                                   "${url}" \
                                   "${OPTION_BRANCH}" \
                                   "${OPTION_TAG}" \
                                   "${OPTION_SCM}" \
                                   "${OPTION_OPTIONS}" \
                                   "${directory}"
}


fetch_fetch_main()
{
   log_entry "fetch_fetch_main" "$@"

   USAGE="fetch_fetch_usage"
   COMMAND="fetch"
   fetch_common_main "$@"
}


fetch_checkout_main()
{
   log_entry "fetch_checkout_main" "$@"

   USAGE="fetch_other_usage"
   COMMAND="checkout"
   fetch_common_main "$@"
}


fetch_operation_main()
{
   log_entry "fetch_operation_main" "$@"

   USAGE="fetch_operation_usage"
   COMMAND="operation"
   fetch_common_main "$@"
}


fetch_guess_main()
{
   log_entry "fetch_guess_main" "$@"

   USAGE="fetch_guess_usage"
   COMMAND="guess"
   fetch_common_main "$@"
}


fetch_search_local_main()
{
   log_entry "fetch_search_local_main" "$@"

   USAGE="fetch_search_local_usage"
   COMMAND="search-local"
   fetch_common_main "$@"
}


fetch_set_url_main()
{
   log_entry "fetch_set_url_main" "$@"

   USAGE="fetch_set_url_usage"
   COMMAND="set-url"
   fetch_common_main "$@"
}


fetch_status_main()
{
   log_entry "fetch_status_main" "$@"

   USAGE="status_usage"
   COMMAND="status"
   fetch_common_main "$@"
}


fetch_update_main()
{
   log_entry "fetch_update_main" "$@"

   USAGE="fetch_other_usage"
   COMMAND="update"
   fetch_common_main "$@"
}


fetch_upgrade_main()
{
   log_entry "upgrade_main" "$@"

   USAGE="fetch_other_usage"
   COMMAND="upgrade"
   fetch_common_main "$@"
}


fetch_commands_initialize()
{
   log_entry "fetch_commands_initialize"

   if [ -z "${MULLE_FETCH_OPERATION_SH}" ]
   then
      # shellcheck source=mulle-fetch-operation.sh
      . "${MULLE_FETCH_LIBEXEC_DIR}/mulle-fetch-operation.sh" || exit 1
   fi

   if [ -z "${MULLE_BASHFUNCTIONS_SH}" ]
   then
      [ -z "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}" ] && internal_fail "MULLE_BASHFUNCTIONS_LIBEXEC_DIR is empty"

      # shellcheck source=../../mulle-bashfunctions/src/mulle-bashfunctions.sh
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-bashfunctions.sh" || exit 1
   fi
}


fetch_commands_initialize

:
