#! /usr/bin/env bash
#
#   Copyright (c) 2020 Nat! - Mulle kybernetiK
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
MULLE_FETCH_PLUGIN_DOMAIN_GITHUB_SH="included"


github_url_get_user_repo()
{
   log_entry "github_url_get_user_repo" "$@"

   local url="$1"

   local s

   s="${url#*//}"       # remove scheme if any
   s="${s#*/}"          # remove domain

   _user="${s%%/*}"     # get user

   s="${s#${_user}/}"   # get repo
   _repo="${s%%/*}"
}


#
# list all tags
#
github_get_tags()
{
   log_entry "github_get_tags" "$@"

   local user="$1"
   local repo="$2"

   if [ -z "${MULLE_FETCH_CURL_SH}" ]
   then
      # shellcheck source=mulle-fetch-curl.sh
      . "${MULLE_FETCH_LIBEXEC_DIR}/mulle-fetch-curl.sh" || \
         fail "failed to load ${MULLE_FETCH_LIBEXEC_DIR}/mulle-fetch-curl.sh"
   fi

   local url

   url="https://api.github.com/repos/${user}/${repo}/tags"

   exekutor curl_download "${url}" | sed -n -e 's/^.*"name": "\(.*\)".*$/\1/p'
}


#
# compose an URL from user repository name (repo), username (user)
# possibly a version (tag) and the desired SCM (git or tar usually)
#
r_domain_github_compose()
{
   log_entry "r_domain_github_compose" "$@"

   local repo="$1"
   local user="$2"
   local tag="$3"
   local scm="$4"

   [ -z "${user}" ] && fail "User is required for github URL"
   [ -z "${repo}" ] && fail "Repo is required for github URL"

   # could use API to get the URL, but laziness...
   case "${scm}" in
      git)
         r_concat "https://github.com/${user}/${repo}.git" "${tag}" '##'
      ;;

      tar)
         RVAL="https://github.com/${user}/${repo}/archive/${tag:-latest}.tar.gz"
      ;;

      zip)
         RVAL="https://github.com/${user}/${repo}/archive/${tag:-latest}.zip"
      ;;

      *)
         fail "Unsupported scm ${scm} for github"
      ;;
   esac
}


#
# for a given github URL for a desired scm (git/tar/zip) determine
# the proper archive name that matches the "filter" expression
# Use is_tags_filter and tags_filter to do the heavy work.
#
# github_get_tags will fetch all available tags from github via JSON API
# (could use git as well, coming to think of it)
#
r_domain_github_filter()
{
   log_entry "r_domain_github_filter" "$@"

   local url="$1"
   local filter="$2"
   local scm="$3"

   local _user
   local _repo

   github_url_get_user_repo "${url}"
   if [ -z "${_repo}" -o -z "${_user}" ]
   then
      fail "Failed to extract user/repo information from github URL \"${url}\""
   fi

   local tags
   local tag

   if is_tags_filter "${filter}"
   then
      tags="`github_get_tags "${_user}" "${_repo}" `" || exit 1
      tag="`tags_filter "${tags}" "${filter}" `" || exit 1
   else
      tag="${filter}"
   fi

   r_domain_github_compose "${_repo}" "${_user}" "${tag}" "${scm}"
}


