#! /usr/bin/env bash
#
#   Copyright (c) 2021 Nat! - Mulle kybernetiK
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
MULLE_FETCH_GITHUB_SH="included"

fetch_github_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} github [options] <user> <repo> <command> [arguments]

   Access information from a repository <repo> belonging to a user <user>
   (or organization) on GitHub.
   It uses the public GitHub API only, so you don't need an access token.
   But the GitHub is limited to 60 requests per hours for unauthenticated
   users!

   The currently available commands are:

   tags-json                    : get list of all (up to 1600) github tags
   list-tags                    : get a list of all tag names
   get-commit-for-tag <tag>     : get the commit for a certain tag
   get-tags-for-commit <sha>    : get list of tags for a certain commit
   get-tag-aliases  <tag>       : get tags that share the same commit as tag

Examples:
   ${MULLE_USAGE_NAME} github mulle-c mulle-allocator get-tag-aliases latest

Options:
   -h                           : this help
   --github-token <token>       : sets MULLE_FETCH_GITHUB_TOKEN
   --per-page <value>           : sets MULLE_FETCH_GITHUB_PER_PAGE
   --max-pages <value>          : sets MULLE_FETCH_GITHUB_MAX_PAGES

Environment:
   MULLE_FETCH_GITHUB_TOKEN     : github access token to use
   MULLE_FETCH_GITHUB_MAX_PAGES : max pages to fetch (20)
   MULLE_FETCH_GITHUB_PER_PAGE  : number of entries per page up to 100 (100)
EOF

   exit 1
}


fetch_github_main()
{
   log_entry "fetch_github_main" "$@"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            fetch_github_usage
         ;;

         --token|--github-token)
            [ $# -eq 1 ] && fail "Missing argument to \"$1\""
            shift

            MULLE_FETCH_GITHUB_TOKEN="$1"
         ;;

         --per-page)
            [ $# -eq 1 ] && fail "Missing argument to \"$1\""
            shift

            MULLE_FETCH_GITHUB_PER_PAGE="$1"
            [ "${MULLE_FETCH_GITHUB_PER_PAGE}" -lt 1 ] && fail "Invalid number of entries"
            if [ "${MULLE_FETCH_GITHUB_PER_PAGE}" -gt 100 ]
            then
               log_warning "More than 100 entries per page is unlikely to work"
            fi
         ;;

         --max-pages)
            [ $# -eq 1 ] && fail "Missing argument to \"$1\""
            shift

            MULLE_FETCH_GITHUB_MAX_PAGES="$1"
            [ "${MULLE_FETCH_GITHUB_MAX_PAGES}" -lt 1 ] && fail "Invalid number of pages"
         ;;

         -*)
            fetch_github_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ $# -lt 3 ] && fetch_github_usage

   local user="$1"
   shift
   local repo="$1"
   shift
   local cmd="$1"
   shift

   case "${cmd}" in
      'tags-json')
         r_github_tags_json "${user}" "${repo}" || exit 1
         echo "${RVAL}"
      ;;

      'list-tags')
         github_tags "${user}" "${repo}"
      ;;

      'get-commit-for-tag')
         github_get_commit_for_tag "${user}" "${repo}"
      ;;

      'get-tags-for-commit')
         github_tags_for_commit "${user}" "${repo}"
      ;;

      'get-tag-aliases')
         github_get_tag_aliases "${user}" "${repo}"
      ;;

      *)
         fetch_github_usage "Unknown command \"${cmd}\""
      ;;
   esac
}


github_initialize()
{
   if [ -z "${MULLE_FETCH_PLUGIN_SH}" ]
   then
      # shellcheck source=mulle-fetch-plugin.sh
      . "${MULLE_FETCH_LIBEXEC_DIR}/mulle-fetch-plugin.sh" || exit 1
   fi

   fetch_plugin_load "github" "domain"
}

github_initialize

:
