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
MULLE_FETCH_FILTER_SH="included"


show_domain_plugins()
{
   if [ -z "$MULLE_FETCH_PLUGIN_SH" ]
   then
      # shellcheck source=mulle-fetch-plugin.sh
      . "${MULLE_FETCH_LIBEXEC_DIR}/mulle-fetch-plugin.sh" || \
         fail "failed to load ${MULLE_FETCH_LIBEXEC_DIR}/mulle-fetch-plugin.sh"
   fi

   local  plugins

   plugins="`fetch_plugin_all_names "domain" `"
   if [ ! -z "${plugins}" ]
   then
      (
         echo
         echo "Available domain types are:"
         printf "%s\n" "${plugins}" | sed 's/^/   /'
      )
   fi
}



fetch_filter_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} filter [options] <filter> <url>

   Use the filter expression <filter> to determine the correct tag to use for
   fetching a dependency from <url>. This is a plugin based mechanism, that
   currently only supports github.com.

   You provide an url
   like https://github.com/mulle-c/mulle-c11/archive/3.1.0.tar.gz and a filter
   like '>= 3.1.0 AND < 4.0.0' and this command will locate the best available
   URL on the host, which is
   https://github.com/mulle-c/mulle-c11/archive/3.1.4.tar.gz at time of writing,
   since this is the newest version that fits the requirement.

Options:
   --scm <name>  : specify an SCM like tar, zip, (git)

EOF

   show_domain_plugins >&2
   exit 1
}


fetch_compose_url_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} compose-url [options] <domain> [repo]

   Create a dependency URL for a plugin domain and you generally will also
   need to specify a repository name at least.

   Example:
      ${MULLE_USAGE_NAME} compose-url --user mulle-c github mulle-allocator
   gives
      https://github.com/mulle-c/mulle-allocator/archive/latest.tar.gz

Options:
   --scm <name>  : specify an SCM like tar, zip, git (tar)
   --tag <tag>   : specify a version tag (latest)
   --user <user> : specify the owner, may be required (mulle-nat)

EOF
   show_domain_plugins >&2

   exit 1
}


tags_grep_versions()
{
   sed -n -e '/^[0-9]*\.[0-9]*\.[0-9]*/p' \
          -e 's/^.*[a-zA-Z_-]\([0-9]*\.[0-9]*\.[0-9]*\)$/\1/p'
}


#
# sort them in numeric order so 10.1.2, 9.1.0, 9.22.0, 9.3.0
# becomes 10.1.2, 9.22.0, 9.3.0, 9.1.0 when sorting reverse (sortflags="r")
# or 9.1.0, 9.3.0, 9.22.0, 10.1.2 with the default sort
#
versions_sort()
{
   local sortflags="$1"

   sort -u -t. -k "1,1n${sortflags}" -k "2,2n${sortflags}" -k "3,3n${sortflags}"
}


#
# Plop our version in, sort and pick the ones after ours
#
versions_find_next()
{
   local versions="$1"
   local version="$2"
   local sortflags="$3"

   #
   # If ours is not in there yet, plob it in
   #
   if ! fgrep -q -s -x "${version}" <<< "${versions}"
   then
      r_add_line "${versions}" "${version}"
      versions="${RVAL}"
   fi

   # Now sort again and pick the one after ours
   versions="`versions_sort ${sortflags} <<< "${versions}" `"

   r_escaped_sed_pattern "${version}"

   # delete all lines up to pattern, then implicitly print and quit
   # sed -e "0,/^${RVAL}\$/d" -e '{q;}' <<< "${versions}"

   # want a list of applicable versions
   sed -e "0,/^${RVAL}\$/d" <<< "${versions}"
}


#
# will filter versions according to operation and version
# the result will be sorted in ascending order
#
versions_operation()
{
   local versions="$1"
   local operation="$2"
   local version="$3"

   case "${operation}" in
      '>=')
         fgrep -x "${version}" <<< "${versions}"
         versions_find_next "${versions}" "${version}"
      ;;

      '>')
         versions_find_next "${versions}" "${version}"
      ;;

      '<=')
         versions_find_next "${versions}" "${version}" "r" | versions_sort
         fgrep -x "${version}" <<< "${versions}"
      ;;

      '<')
         versions_find_next "${versions}" "${version}" "r" | versions_sort
      ;;

      '==')
         fgrep -x "${version}" <<< "${versions}"
      ;;

      '!=')
         versions_sort <<< "${versions}"  | \
            fgrep -x -v "${version}" | \
            "${_choose}" -1
      ;;

      *)
         internal_fail "unknown operator \"${operator}\""
      ;;
   esac

   return 0
}


#
# A small parser
#

r_versions_qualify_s()
{
#  log_entry "r_versions_qualify_s" "${_s}" "$@"

   local versions="$1"

   local operator
   local value
   local version

   _s="${_s#"${_s%%[![:space:]]*}"}" # remove leading whitespace characters
   case "${_s}" in
      "("*)
         _s="${_s:1}"
         r_versions_qualify "${versions}"

         _s="${_s#"${_s%%[![:space:]]*}"}" # remove leading whitespace characters
         if [ "${_closer}" != 'YES' ]
         then
            if [ "${_s:0:1}" != ")" ]
            then
               fail "Closing ) missing at \"${_s}\" of versions qualifier \"${_qualifier}\""
            fi
            _s="${_s:1}"
         fi
         return
      ;;

      '>='*|'<='*|'=='*|'!='*)
         operator="${_s:0:2}"
         _s="${_s:2}"
      ;;

      '<>'*)
         operator='!='
         _s="${_s:2}"
      ;;

      '<'*|'>'*)
         operator="${_s:0:1}"
         _s="${_s:1}"
      ;;

      '='*)
         operator='=='
         _s="${_s:1}"
      ;;

      [0-9]*)
         operator='=='
      ;;

      "")
         fail "Missing expression after versions qualifier \"${_qualifier}\""
      ;;

      *)
         fail "Unknown command at \"${_s}\" of versions qualifier \"${_qualifier}\""
      ;;
   esac

   ## fall thru for common operation code
   _s="${_s#"${_s%%[![:space:]]*}"}" # remove leading whitespace characters
   version="${_s%%[ )]*}"
   _s="${_s#"${version}"}"
   #log_entry tags_match "${versions}" "${key}"
   RVAL="`versions_operation "${versions}" "${operator}" "${version}"`" || exit 1
}


r_versions_qualify_i()
{
#  log_entry "r_versions_qualify_i" "${_s}" "$@"
   local versions="$1"
   local result="$2"

   local tmp

   _s="${_s#"${_s%%[![:space:]]*}"}" # remove leading whitespace characters
   case "${_s}" in
      [Aa][Nn][Dd]*)
         _s="${_s:3}"
         r_versions_qualify "${versions}"
         RVAL="`fgrep -x -f <( echo "${result}") <<< "${RVAL}" `"
         return 0
      ;;

      [Oo][Rr]*)
         _s="${_s:2}"
         r_versions_qualify "${versions}"
         r_add_line "${result}" "${RVAL}"

         RVAL="`sort -u <<< "${RVAL}"`"
         return 0
      ;;

      ")")
         echo "${result}"
         return 0
      ;;

      "")
         echo "${result}"
         return 0
      ;;
   esac

   fail "Unexpected expression at ${_s} of versions qualifier \"${qualifier}\""
}


r_versions_qualify()
{
#  log_entry "r_versions_qualify" "${_s}" "$@"

   local versions="$1"

   local expr
   local result

   r_versions_qualify_s "${versions}"
   result="${RVAL}"

   while :
   do
      _s="${_s#"${_s%%[![:space:]]*}"}" # remove leading whitespace characters
      case "${_s}" in
         ")"*|"")
            break
         ;;
      esac
      r_versions_qualify_i "${versions}" "${result}"
      result="${RVAL}"
   done

   RVAL="${result}"
}


#
#
#
versions_filter()
{
   local versions="$1"
   local filter="$2"

   local _choose

   # used for error messages
   # pick newest by default
   _choose=tail

   filter="${filter#"${filter%%[![:space:]]*}"}" # remove leading whitespace characters
   case "${filter}" in
      [Oo][Ll][Dd][Ee][Ss][Tt]:*)
         filter="${filter:7}"
         _choose=head
      ;;

      [Nn][Ee][Ww][Ee][Ss][Tt]:*)
         filter="${filter:7}"
         _choose=tail
      ;;
   esac

   local _qualifier

   _qualifier="${filter}"

   if [ -z "${filter}" ]
   then
      filter=">= 0.0.0"
   fi

   local _s

   # used to traverse the string
   _s="${filter}"

   r_versions_qualify "${versions}"
   if [ ! -z "${RVAL}" ]
   then
      "${_choose}" -1 <<< "${RVAL}"
   fi

   return 0
}


tags_filter()
{
   log_entry "tags_filter" "$@"

   local tags="$1"
   local filter="$2"

   local versions
   local version

   versions="`tags_grep_versions <<< "${tags}" `" || exit 1

   version="`versions_filter "${versions}" "${filter}" `" || exit 1
   if [ -z "${version}" ]
   then
      RVAL=""
      return 0
   fi

   #
   # map version number back to tags
   #
   local pattern

   r_escaped_grep_pattern "${version}"
   pattern="^${RVAL}$|[a-zA-Z_-]${RVAL}\$"

   egrep  "${pattern}" <<< "${tags}" | head -1
}


is_tags_filter()
{
   log_entry "is_tags_filter" "$@"

   local filter="$1"

   filter="${filter#"${filter%%[![:space:]]*}"}" # remove leading whitespace characters
   case "${filter}" in
      [Oo][Ll][Dd][Ee][Ss][Tt]:*)
         return 0
      ;;

      [Nn][Ee][Ww][Ee][Ss][Tt]:*)
         return 0
      ;;
   esac

   case "${filter}" in
      *' '[Aa][Nn][Dd]' '*|*' '[Oo][Rr]' '*|*'<'*|*'>'*|*'='*)
         return 0
      ;;
   esac

   return 1
}


r_host_get_domain()
{
   #
   # remove foo.bar. from foo.bar.github.com
   #
   RVAL="$1"
   while :
   do
      case "${RVAL}" in
         *\.*\.*)
            RVAL="${RVAL#*\.}"
            continue
         ;;
      esac
      break
   done

   #
   # remove .com from github.com
   #
   RVAL="${RVAL%.*}"
}


r_url_get_domain()
{
   local url="$1"

   local host

   host="${url#*://}"
   host="${host%%/*}"

   r_host_get_domain "${host}"
}


fetch_filter_main()
{
   log_entry "fetch_filter_main" "$@"

   local OPTION_SCM="git"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            fetch_filter_usage
         ;;

         --scm)
            [ $# -eq 1 ] && fetch_filter_usage "Missing argument to \"$1\""
            shift

            OPTION_SCM="$1"
         ;;

         -*)
            fetch_filter_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ $# -ne 2 ] && fetch_filter_usage

   local filter="$1"
   shift
   local url="$1"
   shift

   local domain

   r_url_get_domain "${url}"
   domain="${RVAL}"

   # get rid of .com or so

   local domain_identifier
   r_identifier "${domain}"
   domain_identifier="${RVAL}"

   local r_callback

   r_callback="r_domain_${domain_identifier}_filter"

   if [ -z "${MULLE_FETCH_PLUGIN_SH}" ]
   then
      . "${MULLE_FETCH_LIBEXEC_DIR}/mulle-fetch-plugin.sh"
   fi

   #
   # if unsupported just emit the URL as is
   #
   if ! fetch_plugin_load_if_present "${domain_identifier}" "domain"
   then
      log_verbose "Domain \"${domain}\" not supported"

      printf "%s\n" "${url}"
      return 0
   fi

   if [ "`type -t "${r_callback}"`" != "function" ]
   then
      log_verbose "Domain plugin \"${host}\" has no \"${r_callback}\" function"

      printf "%s\n" "${url}"
      return 0
   fi

   "${r_callback}" "${url}" "${filter}" "${OPTION_SCM}"

   echo "${RVAL}"
}



fetch_compose_url_main()
{
   log_entry "fetch_compose_url_main" "$@"

   local OPTION_USER
   local OPTION_REPO
   local OPTION_TAG
   local OPTION_SCM="tar"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            fetch_compose_url_usage
         ;;

         --scm)
            [ $# -eq 1 ] && fetch_compose_url_usage "Missing argument to \"$1\""
            shift

            OPTION_SCM="$1"
         ;;

         --repo)
            [ $# -eq 1 ] && fetch_compose_url_usage "Missing argument to \"$1\""
            shift

            OPTION_REPO="$1"
         ;;

         --user)
            [ $# -eq 1 ] && fetch_compose_url_usage "Missing argument to \"$1\""
            shift

            OPTION_USER="$1"
         ;;

         --tag)
            [ $# -eq 1 ] && fetch_compose_url_usage "Missing argument to \"$1\""
            shift

            OPTION_TAG="$1"
         ;;

         -*)
            fetch_compose_url_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ $# -lt 1 -o $# -gt 2 ] && fetch_compose_url_usage

   local url="$1"
   shift

   repo="${1:-${OPTION_REPO}}"

   local domain

   r_url_get_domain "${url}"
   domain="${RVAL}"

   local domain_identifier

   r_identifier "${domain}"
   domain_identifier="${RVAL}"

   local r_callback

   r_callback="r_domain_${domain_identifier}_compose"

   if [ -z "${MULLE_FETCH_PLUGIN_SH}" ]
   then
      . "${MULLE_FETCH_LIBEXEC_DIR}/mulle-fetch-plugin.sh"
   fi

   #
   # if unsupported just emit the URL as is
   #
   if ! fetch_plugin_load_if_present "${RVAL}" "domain"
   then
      fail "Domain is not supported"
   fi

   if [ "`type -t "${r_callback}"`" != "function" ]
   then
      fail "Domain plugin \"${domain}\" has no \"${r_callback}\" function"
   fi

   "${r_callback}" "${repo}" "${OPTION_USER}" "${OPTION_TAG}" "${OPTION_SCM}"

   echo "${RVAL}"
}
