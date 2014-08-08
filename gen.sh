#!/bin/bash

# mpv shell completion script generator
# This is a hack. Oh noes!
# Copyright (C) 2014 Jens Oliver John <dev at 2ion dot de>
# Licensed under the GNU General Public License v3 or later

set -f
set -e

####################################################

readonly _f_header='
function _mpv(){
  local cur=${COMP_WORDS[COMP_CWORD]}
  local prev=${COMP_WORDS[COMP_CWORD-1]}
  case "$prev" in'

readonly _f_footer='
  esac
}
complete -F _mpv mpv'

readonly _case='
  %s) COMPREPLY=($(compgen -W "%s" -- "$cur")) ;;'

declare -a _allkeys

####################################################

echo "$_f_header"

for line in $(mpv --list-options \
  | grep -- -- \
  | sed 's/^\s*//;s/\s\+/,/g;s/,(default.*$//g') ; do
  key=${line%%,*}
  if [[ $key =~ \* ]] ; then
    key=${key%%\*}
  fi
  _allkeys="$_allkeys $key"
  val=${line#*,}
  type=${val%%,*}
  case "$type" in
    Choices*)
      tail=${val#*,}
      tail=${tail%%,(*}
      tail=${tail//,/ }
      printf "$_case" "$key" "$tail"
      ;;
    Object)
      tail=""
      for subline in $(mpv "$key" help \
        | tail -n+2 \
        | grep -v '^$' \
        | sed 's/\s*//g' \
        | cut -d: -f1); do
        if [[ -z $tail ]] ; then
          tail=$subline
        else
          tail="$tail $subline"
        fi
      done
      printf "$_case" "$key" "$tail"
      ;;
    Flag)
      printf "$_case" "$key" "yes no"
      ;;
  esac
done

printf "$_case" "*" "$_allkeys"

echo "$_f_footer"
