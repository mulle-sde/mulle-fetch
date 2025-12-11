#!/usr/bin/env bash
# shellcheck shell=bash

_mulle_fetch_complete()
{
   # Declare local variables
   local cur prev words cword
   _get_comp_words_by_ref -n : cur prev words cword

   # Initialize COMPREPLY
   COMPREPLY=()

   # Extract the command (skip program name at words[0])
   local i=1
   local cmd=""

   # Find the first non-option word after mulle-fetch (the command)
   while [[ $i -lt $cword ]]; do
      if [[ "${words[i]}" != -* && -z "$cmd" ]]; then
         cmd="${words[i]}"
         break
      fi
      ((i++))
   done

   if [[ -z "$cmd" ]]; then
      # No command yet, suggest main commands
      local main_commands="\
         allow cfetch checkout convenient-fetch debug-clib-fetch exists fetch \
         libexec-dir library-path list operation plugin prevent search-local \
         set-url status uname update upgrade version"
      COMPREPLY=($(compgen -W "${main_commands}" -- "$cur"))
      return 0
   fi

   case "$cmd" in
      plugin)
         if [[ $cword -eq $((i+1)) ]]; then
            # Subcommand for plugin (completing right after "plugin")
            COMPREPLY=($(compgen -W "list" -- "$cur"))
         else
            # Options for plugin command
            COMPREPLY=($(compgen -W "--help -h" -- "$cur"))
         fi
         ;;

      fetch|cfetch|convenient-fetch)
         # Options for fetch commands
         local fetch_options="--help -h --absolute-symlinks --cache-dir --copy --curl-flags \
            --file --git --github --github-user --hardlink --mirror-dir --no-absolute-symlinks \
            --no-print --no-refresh --no-symlink --no-symlinks --prefix --print --recursive \
            --refresh --symlink --symlink-copy --symlink-returns-4 --symlinks --tar \
            --tool-flags --tool-options --write-protect -b -d -l -o -s -t --branch \
            --search-path --local-search-path --options --source --scm --tag"
         if [[ "$cur" == -* ]]; then
            COMPREPLY=($(compgen -W "${fetch_options}" -- "$cur"))
         elif [[ "$prev" == "--cache-dir" || "$prev" == "--mirror-dir" || "$prev" == "-l" || "$prev" == "--search-path" || "$prev" == "--local-search-path" ]]; then
            COMPREPLY=($(compgen -d -- "$cur"))
         elif [[ "$prev" == "-s" || "$prev" == "--source" || "$prev" == "--scm" ]]; then
            local scms="clib copy file git local svn symlink tar zip"
            COMPREPLY=($(compgen -W "${scms}" -- "$cur"))
         elif [[ "$prev" == "--branch" || "$prev" == "-b" || "$prev" == "--tag" || "$prev" == "-t" ]]; then
            COMPREPLY=()
         else
            COMPREPLY=($(compgen -f -- "$cur"))
         fi
         ;;

      search-local)
         local options="--help -h -l -o -s -u --local-search-path --options --scm --source --url"
         if [[ "$cur" == -* ]]; then
            COMPREPLY=($(compgen -W "${options}" -- "$cur"))
         elif [[ "$prev" == "-l" || "$prev" == "--local-search-path" ]]; then
            COMPREPLY=($(compgen -d -- "$cur"))
         elif [[ "$prev" == "-s" || "$prev" == "--source" || "$prev" == "--scm" ]]; then
            local scms="clib copy file git local svn symlink tar zip"
            COMPREPLY=($(compgen -W "${scms}" -- "$cur"))
         else
            COMPREPLY=()
         fi
         ;;

      update|upgrade)
         local options="--help -h -b -o -s -t --branch --options --scm --source --tag"
         if [[ "$cur" == -* ]]; then
            COMPREPLY=($(compgen -W "${options}" -- "$cur"))
         elif [[ "$prev" == "-s" || "$prev" == "--source" || "$prev" == "--scm" ]]; then
            local scms="clib copy file git local svn symlink tar zip"
            COMPREPLY=($(compgen -W "${scms}" -- "$cur"))
         elif [[ "$prev" == "--branch" || "$prev" == "-b" || "$prev" == "--tag" || "$prev" == "-t" ]]; then
            COMPREPLY=()
         else
            COMPREPLY=($(compgen -d -- "$cur"))
         fi
         ;;

      exists)
         local options="--help -h -s --scm --source"
         if [[ "$cur" == -* ]]; then
            COMPREPLY=($(compgen -W "${options}" -- "$cur"))
         elif [[ "$prev" == "-s" || "$prev" == "--source" || "$prev" == "--scm" ]]; then
            local scms="clib copy file git local svn symlink tar zip"
            COMPREPLY=($(compgen -W "${scms}" -- "$cur"))
         else
            COMPREPLY=()
         fi
         ;;

      set-url)
         local options="--help -h -o -s --options --scm --source"
         if [[ "$cur" == -* ]]; then
            COMPREPLY=($(compgen -W "${options}" -- "$cur"))
         elif [[ "$prev" == "-s" || "$prev" == "--source" || "$prev" == "--scm" ]]; then
            local scms="clib copy file git local svn symlink tar zip"
            COMPREPLY=($(compgen -W "${scms}" -- "$cur"))
         else
            COMPREPLY=($(compgen -d -- "$cur"))
         fi
         ;;

      status|checkout)
         local options="--help -h -o -s --options --scm --source"
         if [[ "$cur" == -* ]]; then
            COMPREPLY=($(compgen -W "${options}" -- "$cur"))
         elif [[ "$prev" == "-s" || "$prev" == "--source" || "$prev" == "--scm" ]]; then
            local scms="clib copy file git local svn symlink tar zip"
            COMPREPLY=($(compgen -W "${scms}" -- "$cur"))
         else
            COMPREPLY=($(compgen -d -- "$cur"))
         fi
         ;;

      operation)
         local options="--help -h -s --scm --source"
         if [[ "$cur" == -* ]]; then
            COMPREPLY=($(compgen -W "${options}" -- "$cur"))
         elif [[ "$prev" == "-s" || "$prev" == "--source" || "$prev" == "--scm" ]]; then
            local scms="clib copy file git local svn symlink tar zip"
            COMPREPLY=($(compgen -W "${scms}" -- "$cur"))
         else
            COMPREPLY=()
         fi
         ;;

      allow|prevent|uname|version|libexec-dir|library-path)
         # Simple commands, no arguments
         if [[ "$cur" == -* ]]; then
            COMPREPLY=($(compgen -W "--help -h" -- "$cur"))
         else
            COMPREPLY=()
         fi
         ;;

      list|debug-clib-fetch)
         if [[ "$cur" == -* ]]; then
            COMPREPLY=($(compgen -W "--help -h" -- "$cur"))
         else
            COMPREPLY=()
         fi
         ;;

      *)
         # Default to file completion
         COMPREPLY=($(compgen -f -- "$cur"))
         ;;
   esac

   return 0
}

complete -F _mulle_fetch_complete mulle-fetch
