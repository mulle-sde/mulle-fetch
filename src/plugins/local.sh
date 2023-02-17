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
MULLE_FETCH_PLUGIN_LOCAL_SH='included'


###
### PLUGIN API
###

#
# this is useful in mulle-sourcetree to add existing subprojects that
# need to be compiled separately
#
fetch::plugin::local::fetch_project()
{
   [ $# -lt 8 ] && _internal_fail "parameters missing"

   local unused="$1"
   local name="$2"
   local url="$3"
   local branch="$4"
   local tag="$5"
   local sourcetype="$6"
   local sourceoptions="$7"
   local dstdir="$8"

   shift 8

   #
   # Could copy url which is a local directory now wholesale, which
   # might make sense on mingw, but would be really bothersome, when
   # you really wanted to symlink
   #
   [ ! -e "${dstdir}" ] && fail "${dstdir} not present"

   :
}

fetch::plugin::local::exists_project()
{
   log_entry "fetch::plugin::local::exists_project" "$@"

   local url="$3"             # URL of the clone

   fetch::source::validate_file_url "${url}"
}


fetch::plugin::local::guess_project()
{
   log_entry "fetch::plugin::local::guess_project" "$@"

   fetch::source::guess_project "$@"
}

