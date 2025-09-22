#!/usr/bin/env bash
# shellcheck shell=bash

_mulle_fetch_complete()
{
   # Declare local variables
   local cur prev words cword
   _get_comp_words_by_ref -n : cur prev words cword

   # Initialize COMPREPLY
   COMPREPLY=()

   # Extract the command and subcommand positions
   local i=1
   local cmd=""
   local subcmd=""

   # Find the main command
   while [[ $i -lt $cword ]]; do
      if [[ "${words[i]}" != -* ]]; then
         if [[ -z "$cmd" ]]; then
            cmd="${words[i]}"
         elif [[ -z "$subcmd" ]]; then
            subcmd="${words[i]}"
         fi
         ((i++))
      else
         ((i++))
      fi
   done

   if [[ -z "$cmd" ]]; then
      # No command yet, suggest main commands
      local main_commands="\
         domain cfetch fetch search-local update upgrade allow exists libexec-dir operation list prevent uname version plugin"
      COMPREPLY=($(compgen -W "${main_commands}" -- "$cur"))
      return 0
   fi

   case "$cmd" in
      plugin)
         if [[ $cword -eq $i ]]; then
            # Subcommand for plugin
            COMPREPLY=($(compgen -W "list" -- "$cur"))
         else
            # Options for plugin command
            COMPREPLY=($(compgen -W "--help -h" -- "$cur"))
         fi
         ;;

      fetch|cfetch|search-local|update|upgrade|exists|set-url|status|checkout)
         # Options for fetch-related commands
         local fetch_options="--help -h --absolute-symlinks --cache-dir --copy --mirror-dir --recursive --refresh --symlink --symlink-returns-4 --no-symlink --write-protect -b -l -o -s -t --branch --search-path --local-search-path --options --source --scm --tag"
         if [[ "$cur" == -* ]]; then
            COMPREPLY=($(compgen -W "${fetch_options}" -- "$cur"))
         elif [[ "$prev" == "--cache-dir" || "$prev" == "--mirror-dir" || "$prev" == "-l" || "$prev" == "--search-path" || "$prev" == "--local-search-path" ]]; then
            COMPREPLY=($(compgen -d -- "$cur"))
         elif [[ "$prev" == "-s" || "$prev" == "--source" || "$prev" == "--scm" ]]; then
            # Get SCM types dynamically if possible
            local scms
            if command -v mulle-fetch >/dev/null 2>&1; then
               scms=$(mulle-fetch plugin list 2>/dev/null)
            else
               scms="git tar zip clib svn symlink copy file"
            fi
            COMPREPLY=($(compgen -W "${scms}" -- "$cur"))
         elif [[ "$prev" == "--branch" || "$prev" == "-b" || "$prev" == "--tag" || "$prev" == "-t" ]]; then
            COMPREPLY=()  # No specific completion
         else
            COMPREPLY=($(compgen -f -- "$cur"))  # File completion for URLs or files
         fi
         ;;

      domain|operation)
         # For domain, assume basic help, and operation similar
         if [[ "$cur" == -* ]]; then
            COMPREPLY=($(compgen -W "--help -h --source --scm -s" -- "$cur"))
         elif [[ "$prev" == "-s" || "$prev" == "--source" || "$prev" == "--scm" ]]; then
            local scms
            if command -v mulle-fetch >/dev/null 2>&1; then
               scms=$(mulle-fetch plugin list 2>/dev/null)
            else
               scms="git tar zip clib svn symlink copy file"
            fi
            COMPREPLY=($(compgen -W "${scms}" -- "$cur"))
         else
            COMPREPLY=($(compgen -W "help" -- "$cur"))
         fi
         ;;

      allow|prevent|uname|version|libexec-dir)
         # Simple commands, no arguments usually
         COMPREPLY=($(compgen -W "--help -h" -- "$cur"))
         ;;

      list)
         COMPREPLY=($(compgen -W "--help -h" -- "$cur"))
         ;;

      *)
         # Default to file completion
         COMPREPLY=($(compgen -f -- "$cur"))
         ;;
   esac

   return 0
}

complete -F _mulle_fetch_complete mulle-fetch
