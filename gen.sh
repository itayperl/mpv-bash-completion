#!/bin/bash

# gen.sh - mpv Bash completion script generator - This is a hack. Oh noes!
# Copyright (C) 2014 Jens Oliver John <dev at 2ion dot de>
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

set -f

####################################################

if [[ $1 = -h ]] ; then
  echo "gen.sh - mpv shell completion script generator
Script version: $VERSION
Homepage: https://github.com/2ion/mpv-bash-completion
--
This program doesn't accept any command line options except for -h.
Make sure that the mpv command is in \$PATH."
  exit 0
fi

for dep in mpv sed grep tail cut ; do
  if ! type "$dep" &>/dev/null ; then
    echo "Error: required command $dep not found in PATH. Abort." >&2
    exit 1
  fi
done

####################################################

readonly _f_header='#!/bin/bash
# Bash completion file for the mpv media player 
# Project homepage: https://github.com/mpv-player/mpv

_mpv(){
  local cur=${COMP_WORDS[COMP_CWORD]}
  local prev=${COMP_WORDS[COMP_CWORD-1]}
  if [[ ! $cur =~ ^- ]] ; then
    COMPREPLY=($(compgen -f -- "$cur")) 
    return 0
  fi
  case "$prev" in'

readonly _f_footer='
  esac
}
complete -o nospace -F _mpv mpv'

readonly _case='
    %s) COMPREPLY=($(compgen -W "%s" -- "$cur")) ;;'

declare -a _allkeys

####################################################

echo -n "$_f_header"

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
