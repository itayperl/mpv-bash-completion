#!/bin/bash

# gen.sh - mpv Bash completion script generator
# Copyright (C) 2014-2015 Jens Oliver John <dev at 2ion dot de>
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
  _filedir "@(mp?(e)g|MP?(E)G|wm[av]|WM[AV]|avi|AVI|asf|ASF|asx|ASX|vob|VOB|bin|BIN|dat|DAT|vcd|VCD|ps|PS|pes|PES|fl[iv]|FL[IV]|fxm|FXM|viv|VIV|rm?(j)|RM?(J)|ra?(m)|RA?(M)|yuv|YUV|mov|MOV|qt|QT|mp[234]|MP[234]|m4[av]|M4[AV]|og[gmavx]|OG[GMAVX]|w?(a)v|W?(A)V|dump|DUMP|mk[av]|MK[AV]|m4a|M4A|aac|AAC|m[24]v|M[24]V|dv|DV|rmvb|RMVB|mid|MID|t[ps]|T[PS]|3g[p2]|3gpp?(2)|mpc|MPC|flac|FLAC|vro|VRO|divx|DIVX|aif?(f)|AIF?(F)|m2t?(s)|M2T?(S)|vdr|VDR|xvid|XVID|ape|APE|gif|GIF|nut|NUT|bik|BIK|webm|WEBM|amr|AMR|awb|AWB|iso|ISO)?(.part)"
}
complete -o nospace -F _mpv mpv
if [[ -n $BASH_VERSINFO && $BASH_VERSINFO -eq 3 ]] ; then
  echo "[$0] WARNING: This script is not compatible with Bash 3.x!">&2
fi'
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
# Process options
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
      if [[ $line =~ \[nocfg\] ]] ; then
        _allkeys="$_allkeys $key"
      else
        _allkeys="$_allkeys ${key}="
        _cur_flag_cases=("${_cur_flag_cases[@]}" \
          "$(printf "$template_case" "${key}=*" "${key}=yes ${key}=no")")
      fi
      ;;
    Integer|Audio)
      _allkeys="$_allkeys $key"
      val=${val/any/99}
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
    *)
      _allkeys="$_allkeys $key"
      ;;
  esac
done

{
echo "--------------------------------------------@"
echo "Completions dependent on the preceeding word@${#_prev_cases[@]}"
echo "Completions dependent on the current word@${#_cur_flag_cases[@]}"
echo "Total completions@$(echo $_allkeys | tr ' ' '\n' | wc -l)"
echo "Total mpv options@$(mpv --list-options | grep '^ --' | wc -l)"
echo "--------------------------------------------@"
} | column -s@ -t >&2

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
