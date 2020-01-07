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
MULLE_FETCH_PLUGIN_DOMAIN_MULLE_KYBERNETIK_SH="included"


r_domain_mulle_kybernetik_compose()
{
   log_entry "r_domain_mulle_kybernetik_compose" "$@"

   local repo="$1"
   local user="$2"
   local tag="$3"
   local scm="$4"

   [ -z "${repo}" ] && fail "Repo is required for mulle-kybernetik URL"

   case "${scm}" in
      git)
         r_concat "https://mulle-kybernetik.com/software/git/${repo}" "${tag}" '##'
      ;;

      tar)
         [ -z "${tag}" ]  && fail "Tag is required for mulle-kybernetik tar URL"
         RVAL="https://mulle-kybernetik.com/software/git/${repo}/tarball/${tag}"
      ;;

      zip)
         [ -z "${tag}" ]  && fail "Tag is required for mulle-kybernetik zip URL"
         RVAL="https://mulle-kybernetik.com/software/git/${repo}/zipball/${tag}"
      ;;

      *)
         fail "Unsupported scm ${scm} for mulle-kybernetik"
      ;;
   esac
}
