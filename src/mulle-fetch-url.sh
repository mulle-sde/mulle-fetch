#! /usr/bin/env bash
#
#   Copyright (c) 2015-2017 Nat! - Mulle kybernetiK
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
MULLE_FETCH_URL_SH="included"


# Following regex is based on https://tools.ietf.org/html/rfc3986#appendix-B with
# additional sub-expressions to split authority into userinfo, host and port
#
readonly URI_REGEX='^(([^:/?#]+):)?(//((([^:/?#]+)@)?([^:/?#]+)(:([0-9]+))?))?(/([^?#]*))(\?([^#]*))?(#(.*))?'
#                    ↑↑            ↑  ↑↑↑            ↑         ↑ ↑            ↑ ↑        ↑  ↑        ↑ ↑
#                    |2 scheme     |  ||6 userinfo   7 host    | 9 port       | 11 rpath |  13 query | 15 fragment
#                    1 scheme:     |  |5 userinfo@             8 :…           10 path    12 ?…       14 #…
#                                  |  4 authority
#                                  3 //…


url_remove_query()
{
   sed 's/^\([^?]*\)?.*/\1/'
}


url_remove_fragment()
{
   sed 's/^\([^#]*\)#.*/\1/'
}


url_get_path()
{
   log_entry "url_get_path" "$@"

   case "$*" in
      *://*|/*)
         [[ "$*" =~ $URI_REGEX ]] && printf "%s\n" "${BASH_REMATCH[10]}"
      ;;

      *:*)
         printf "%s\n" "$*" | \
            sed 's/^[^:]*:\(.*\)/\1/' | \
            url_remove_query | \
            url_remove_fragment
      ;;

      *)
         printf "%s\n" "$*" | \
            url_remove_query | \
            url_remove_fragment
      ;;
   esac
}


url_typeguess()
{
   log_entry "url_typeguess" "$@"

   local urlpath
   local compressed

   if [ -z "${MULLE_PATH_INCLUDED_SH}" ]
   then
      # shellcheck source=../mulle-bashfunctions/src/mulle-path.sh
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-path.sh"   || fail "${failmsg}"
   fi

   urlpath="`url_get_path "$*"`"
   tarcompressed='NO'

   # this works for gitlist
   case "${urlpath}" in
      */tarball/*)
         echo "tar"
         return
      ;;

      */zipball/*)
         echo "zip"
         return
      ;;
   esac

   if [ -d "$*" ]
   then
      echo "local"
      return
   fi

   while :
   do
      r_path_extension "${urlpath}"
      ext="${RVAL}"
      case "${ext}" in
         "gz"|"xz"|"bz2"|"bz")
            # remove known compression suffixes handled by tar
            tarcompressed='YES'
         ;;

         "tgz"|"tar")
            echo "tar"
            return
         ;;

         "git"|"svn"|"zip")
            if [ "${tarcompressed}" = 'YES' ]
            then
               return 1
            fi

            printf "%s\n" "$ext"
            return
         ;;

         *)
            case "$1" in
               *:*)
                  echo "git"
                  return 0
               ;;

               "")
                  return 1
               ;;

               */*|~*|.*)
                  echo "local"
                  return 0
               ;;

               *)
                  echo "none"
                  return
               ;;
            esac
         ;;
      esac
      r_extensionless_basename "${urlpath}"
      urlpath="${RVAL}"
   done
}


fetch_typeguess_usage()
{
   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} typeguess <url>

   Guess the plugin name responsible for the URL. If in doubt it returns
   nothing.

      ${MULLE_USAGE_NAME} typeguess https://foo.com/bla.git?version=last

   returns "git"
EOF
   exit 1
}


fetch_typeguess_main()
{
   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            fetch_typeguess_usage
         ;;

         -*)
            log_error "${MULLE_EXECUTABLE_FAIL_PREFIX}: Unknown option \"$1\""
            ${USAGE}
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   local url

   [ $# -eq 0 ] && log_error "missing argument to \"typeguess\"" && fetch_typeguess_usage
   [ $# -ne 1 ] && log_error "superflous arguments \"$*\" to \"typeguess\"" && fetch_typeguess_usage

   url="$1"
   [ -z "${url}" ] && fail "empty url"

   url_typeguess "${url}" || :
}

