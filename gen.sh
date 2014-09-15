#!/bin/bash

# gen.sh - mpv Bash completion script generator
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
#
# Project homepage: https://github.com/2ion/mpv-bash-completion

set -f

####################################################
# Immutable globals
# _* -> templates
####################################################

readonly regex_float_range='([\-]?[0-9\.]+),to,([\-]?[0-9\.]+)'
readonly regex_integer_range='([\-]?[0-9]+),to,([\-]?[0-9]+)'
readonly template_header='#!/bin/bash
# mpv(1) completion

_mpv(){
  local cur=${COMP_WORDS[COMP_CWORD]}
  local prev=${COMP_WORDS[COMP_CWORD-1]}
  COMP_WORDBREAKS=${COMP_WORDBREAKS/=/}
  compopt +o default +o filenames'

readonly template_body_flag_cases_open='
  if [[ -n $cur ]] ; then
    case "$cur" in'
readonly template_body_flag_cases_close='
    esac
  fi'
readonly template_body_prev_cases_open='
  if [[ -n $prev ]] ; then
    case "$prev" in'
readonly template_body_prev_cases_close='
    esac
  fi'
readonly template_footer='
  if [[ $cur =~ ^- ]] ; then
    COMPREPLY=($(compgen -W "%s" -- "$cur"))
    return
  fi
  compopt -o filenames -o default
  COMPREPLY=($(compgen -- "$cur"))
}
complete -o nospace -F _mpv mpv'
readonly template_case='
      %s) COMPREPLY=($(compgen -W "%s" -- "$cur")) ; return ;;'

####################################################
# Mutable globals
####################################################

declare _allkeys=""
declare -a _prev_cases=()
declare -a _cur_flag_cases=()

####################################################
# Functions
####################################################

ensure_float_suffix(){
  if [[ ! $1 =~ \. ]] ; then
    echo "${1}.0"
  else
    echo "$1"
  fi
  return 0
}

####################################################
# Process options and check deps
####################################################

while getopts ":h" opt ; do
  case "$opt" in
    h)
      echo -n "mpv Bash completion script generator
Usage:
  ${0##*/} [<options>]
Options:
  -h  Print this message and exit
"
      exit 0
      ;;
    *)
      echo "Invalid option: $opt -- Abort."
      exit 1
      ;;
  esac
done

for dep in mpv sed grep tail cut ; do
  if ! type "$dep" &>/dev/null ; then
    echo "Error: required command $dep not found in PATH. Abort." >&2
    exit 1
  fi
done

####################################################
# main()
####################################################

for line in $(mpv --list-options \
  | grep -- -- \
  | sed 's/^\s*//;s/\s\+/,/g;s/,(default.*$//g') ; do
  key=${line%%,*}
  if [[ $key =~ \* ]] ; then
    key=${key%%\*}
  fi
  val=${line#*,}
  type=${val%%,*}
  case "$type" in
    Choices*)
      _allkeys="$_allkeys $key"
      tail=${val#*,}
      tail=${tail%%,(*}
      tail=${tail//,/ }
      _prev_cases=("${_prev_cases[@]}" \
        "$(printf "$template_case" "$key" "$tail")")
      ;;
    Object)
      _allkeys="$_allkeys $key"
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
      _prev_cases=("${_prev_cases[@]}" \
        "$(printf "$template_case" "$key" "$tail")")
      ;;
    Flag)
      if [[ $key =~ nocfg ]] ; then
        _allkeys="$_allkeys $key"
      else
        _allkeys="$_allkeys ${key}="
        _cur_flag_cases=("${_cur_flag_cases[@]}" \
          "$(printf "$template_case" "${key}=*" "${key}=yes ${key}=no")")
      fi
      ;;
    Integer)
      _allkeys="$_allkeys $key"
      if [[ $val =~ $regex_integer_range ]] ; then
        _prev_cases=("${_prev_cases[@]}" \
          "$(printf "$template_case" "$key" \
            "${BASH_REMATCH[1]} ${BASH_REMATCH[2]}")")
      fi
      ;;
    Float)
      _allkeys="$_allkeys $key"
      if [[ $val =~ $regex_float_range ]] ; then
        _prev_cases=("${_prev_cases[@]}" \
          "$(printf "$template_case" "$key" \
            "$(ensure_float_suffix ${BASH_REMATCH[1]}) $(ensure_float_suffix ${BASH_REMATCH[2]})")")
      fi
      ;;
  esac
done

####################################################
# Output
####################################################

printf "$template_header"

echo -n "${template_body_flag_cases_open}"
echo -n "${_cur_flag_cases[@]}"
echo -n "${template_body_flag_cases_close}"

echo -n "${template_body_prev_cases_open}"
echo -n "${_prev_cases[@]}"
echo -n "${template_body_prev_cases_close}"


printf "$template_footer" "$_allkeys"

exit 0
