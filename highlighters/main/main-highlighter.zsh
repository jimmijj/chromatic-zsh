#!/usr/bin/env zsh
# -------------------------------------------------------------------------------------------------
# Copyright (c) 2010-2011 zsh-syntax-highlighting contributors
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification, are permitted
# provided that the following conditions are met:
#
#  * Redistributions of source code must retain the above copyright notice, this list of conditions
#    and the following disclaimer.
#  * Redistributions in binary form must reproduce the above copyright notice, this list of
#    conditions and the following disclaimer in the documentation and/or other materials provided
#    with the distribution.
#  * Neither the name of the zsh-syntax-highlighting contributors nor the names of its contributors
#    may be used to endorse or promote products derived from this software without specific prior
#    written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
# FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
# IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
# OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# -------------------------------------------------------------------------------------------------


# Define default styles.
ZSH_HIGHLIGHT_STYLES=(${(kv)__chromatic_attrib_zle})


: ${ZSH_HIGHLIGHT_STYLES[default]:=none}
: ${ZSH_HIGHLIGHT_STYLES[unknown-token]:=fg=red,bold}
: ${ZSH_HIGHLIGHT_STYLES[command_prefix]:=fg=green}
: ${ZSH_HIGHLIGHT_STYLES[redirection]:=fg=magenta}
: ${ZSH_HIGHLIGHT_STYLES[file]:=}
: ${ZSH_HIGHLIGHT_STYLES[globbing]:=fg=blue}
: ${ZSH_HIGHLIGHT_STYLES[history-expansion]:=fg=blue}
: ${ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]:=fg=cyan}
: ${ZSH_HIGHLIGHT_STYLES[back-double-quoted-argument]:=fg=cyan}
: ${ZSH_HIGHLIGHT_STYLES[region]:=bg=blue}
: ${ZSH_HIGHLIGHT_STYLES[special]:=none}
: ${ZSH_HIGHLIGHT_STYLES[suffix]:=none}

# Whether the highlighter should be called or not.
_zsh_highlight_main_highlighter_predicate()
{
    _zsh_highlight_buffer_modified
}

## In case we need to highlight in other circumstances then default from highlighter_predicate lets define a switcher
_zsh_highlight_main_highlighter_predicate_switcher()
{
    case $1 in
	'b') # buffer
            _zsh_highlight_main_highlighter_predicate()
	    {
		_zsh_highlight_buffer_modified
	    };;
	'c') # cursor
	    _zsh_highlight_main_highlighter_predicate()
	    {
		_zsh_highlight_cursor_moved
	    };;
	'bc') bccounter=0 # buffer and cursor
	      _zsh_highlight_main_highlighter_predicate()
	      {
		  ## In order to prevent slowdown only one invocation of this function is allowed.
		  ## Most visible reason is with matching part of the file - to retain highlighting only one right/left move of the cursor is possible.
		  ((bccounter++))
		  (( bccounter > 1 )) && _zsh_highlight_main_highlighter_predicate_switcher b
		  _zsh_highlight_cursor_moved || _zsh_highlight_buffer_modified
	      };;
	*);;
    esac
}

# Main syntax highlighting function.
_zsh_highlight_main_highlighter()
{
    emulate -L zsh
    setopt localoptions extendedglob bareglobqual
    local start_pos=0 end_pos highlight_glob=true new_expression=true arg style lsstyle start_file_pos end_file_pos sudo=false sudo_arg=false
    typeset -a ZSH_HIGHLIGHT_TOKENS_COMMANDSEPARATOR
    typeset -a ZSH_HIGHLIGHT_TOKENS_REDIRECTION
    typeset -a ZSH_HIGHLIGHT_TOKENS_PRECOMMANDS
    typeset -a ZSH_HIGHLIGHT_TOKENS_FOLLOWED_BY_COMMANDS
    region_highlight=()

    ZSH_HIGHLIGHT_TOKENS_COMMANDSEPARATOR=(
	'|' '||' ';' '&' '&&' '&|' '|&' '&!' '(' ';;'
    )
    ZSH_HIGHLIGHT_TOKENS_REDIRECTION=(
	'<' '<>' '>' '>|' '>!' '>>' '>>|' '>>!' '<<' '<<-' '<<<' '<&' '>&' '<& -' '>& -' '<& p' '>& p' '&>' '>&|' '>&!' '&>|' '&>!' '>>&' '&>>' '>>&|' '>>&!' '&>>|' '&>>!'
    )
    ZSH_HIGHLIGHT_TOKENS_PRECOMMANDS=(
	'builtin' 'command' 'exec' 'functions' 'nocorrect' 'noglob' 'type' 'unalias' 'unhash' 'whence' 'where' 'which' 'do'
    )
    # Tokens that are always immediately followed by a command.
    ZSH_HIGHLIGHT_TOKENS_FOLLOWED_BY_COMMANDS=(
	$ZSH_HIGHLIGHT_TOKENS_COMMANDSEPARATOR $ZSH_HIGHLIGHT_TOKENS_PRECOMMANDS
    )

    splitbuf1=(${(z)BUFFER})
    splitbuf2=(${(z)BUFFER//$'\n'/ \$\'\\\\n\' }) # ugly hack, but I have no other idea
    local argnum=0
    for arg in ${(z)${(z)BUFFER}}; do
	((argnum++))
	if [[ $splitbuf1[$argnum] != $splitbuf2[$argnum] ]] && new_expression=true && continue

	   local substr_color=0 isfile=false
	   local style_override=""
	   [[ $start_pos -eq 0 && $arg = 'noglob' ]] && highlight_glob=false
	   ((start_pos+=${#BUFFER[$start_pos+1,-1]}-${#${BUFFER[$start_pos+1,-1]##[[:space:]]#}}))
	   ((end_pos=$start_pos+${#arg}))

	   # Parse the sudo command line
	   if $sudo; then
	       case "$arg" in
		   # Flag that requires an argument
		   '-'[Cgprtu]) sudo_arg=true;;
		   # This prevents misbehavior with sudo -u -otherargument
		   '-'*)        sudo_arg=false;;
		   *)           if $sudo_arg; then
				    sudo_arg=false
				else
				    sudo=false
				    new_expression=true
				fi
				;;
	       esac
	   fi
	   if $new_expression; then
	       new_expression=false
	       if [[ "$arg" = "sudo" ]]; then
		   sudo=true
	       else
		   _check_common_expression "$arg" || _check_leading_expression "$arg"
	       fi
	   else
	       _check_common_expression "$arg" || _check_subsequent_expression "$arg" || style=$ZSH_HIGHLIGHT_STYLES[default];
	   fi
	   # if a style_override was set (eg in _zsh_highlight_main_highlighter_check_path), use it
	   [[ -n $style_override ]] && style=$ZSH_HIGHLIGHT_STYLES[$style_override]
	   if [[ $isfile == true ]]; then
	       ((start_file_pos=start_pos+${#arg}-${#arg:t}))
	       end_file_pos=$end_pos
	       ((end_pos=end_pos-${#arg:t}))
	       region_highlight+=("$start_file_pos $end_file_pos $lsstyle")
	   fi
	   [[ $substr_color = 0 ]] && region_highlight+=("$start_pos $end_pos $style")
	   [[ -n ${(M)ZSH_HIGHLIGHT_TOKENS_FOLLOWED_BY_COMMANDS:#"$arg"} ]] && new_expression=true
	   [[ $isfile == true ]] && start_pos=$end_file_pos || start_pos=$end_pos
    done
}

## common
_check_common_expression()
{
    case "$1" in
	"'"*"'") style="${__chromatic_attrib_zle[comments]}";;
	'"'*'"') style="${__chromatic_attrib_zle[comments]}"
		 region_highlight+=("$start_pos $end_pos $style")
		 _zsh_highlight_main_highlighter_highlight_string
		 substr_color=1
		 ;;
	'$'[-#'$''*'@?!]|'$'[a-zA-Z0-9_]##|'${'?##'}') style="${__chromatic_attrib_zle[parameters]}";;
	'$('*')')
	    region_highlight+=("$start_pos $((start_pos+2)) ${__chromatic_attrib_zle[ex]}")
	    region_highlight+=("$((end_pos-1)) $end_pos ${__chromatic_attrib_zle[ex]}")
	    substr_color=1
	    ;;
	'`'*'`')
	    region_highlight+=("$start_pos $((start_pos+1)) ${__chromatic_attrib_zle[builtins]}")
	    region_highlight+=("$((end_pos-1)) $end_pos ${__chromatic_attrib_zle[builtins]}")
	    substr_color=1
	    ;;
	'{'|'}') style="${__chromatic_attrib_zle[reserved-words]}";;
	*'*'*) $highlight_glob && style=$ZSH_HIGHLIGHT_STYLES[globbing] || style=$ZSH_HIGHLIGHT_STYLES[default];;
	';') style="${__chromatic_attrib_zle[separators]}";;
	*) if _zsh_highlight_main_highlighter_check_path; then
	       style="${__chromatic_attrib_zle[di]}"
	   elif [[ -n ${(M)ZSH_HIGHLIGHT_TOKENS_REDIRECTION:#"$1"} ]]; then
	       style=$ZSH_HIGHLIGHT_STYLES[redirection]
	   elif [[ $1[0,1] = $histchars[0,1] ]]; then
	       style=$ZSH_HIGHLIGHT_STYLES[history-expansion]
	   else
	       style=$ZSH_HIGHLIGHT_STYLES[default]
	   fi
	   _zsh_highlight_main_highlighter_check_file && isfile=true
	   ;;
    esac
}
_check_leading_expression()
{
    case "$1" in
	'(('*'))') style="${__chromatic_attrib_zle[numbers]}";;
	'('|')') style="${__chromatic_attrib_zle[functions]}";;
    esac
    res=$(LC_ALL=C builtin type -w $arg 2>/dev/null)
    case $res in
	*': reserved')  style="${__chromatic_attrib_zle[reserved-words]}"
			return 0;;
	*': alias')     style="${__chromatic_attrib_zle[aliases]}"
			local aliased_command="${"$(alias -- $arg)"#*=}"
			[[ -n ${(M)ZSH_HIGHLIGHT_TOKENS_FOLLOWED_BY_COMMANDS:#"$aliased_command"} && -z ${(M)ZSH_HIGHLIGHT_TOKENS_FOLLOWED_BY_COMMANDS:#"$arg"} ]] && ZSH_HIGHLIGHT_TOKENS_FOLLOWED_BY_COMMANDS+=($arg)
			return 0;;
	*': builtin')   style="${__chromatic_attrib_zle[builtins]}"
			return 0;;
	*': function')  style="${__chromatic_attrib_zle[functions]}"
			return 0;;
	*': command'|*': hashed') style="${__chromatic_attrib_zle[ex]}"
			return 0;;
	*)              if _zsh_highlight_main_highlighter_check_assign; then
			    style="${__chromatic_attrib_zle[parameters]}"
			    new_expression=true
			elif _zsh_highlight_main_highlighter_check_command; then
			    style=$ZSH_HIGHLIGHT_STYLES[command_prefix]
			elif [[ $arg[0,1] == $histchars[0,1] || $arg[0,1] == $histchars[2,2] ]]; then
			    style=$ZSH_HIGHLIGHT_STYLES[history-expansion]
			elif [[ -n ${(M)ZSH_HIGHLIGHT_TOKENS_REDIRECTION:#"$arg"} ]]; then
			    style=$ZSH_HIGHLIGHT_STYLES[redirection]
			else
			    style=$ZSH_HIGHLIGHT_STYLES[unknown-token]
			fi
			;;
    esac
}
_check_subsequent_expression()
{
    case "$1" in
	'--'*|'-'*) style="${__chromatic_attrib_zle[options]}";;
	'|'|'|&') style="${__chromatic_attrib_zle[pi]}";;
	'||'|'&&'|'&'|'&|'|'&!'|';;') style="${__chromatic_attrib_zle[separators]}";;
	'$(('*'))') style="${__chromatic_attrib_zle[numbers]}";;
	'<('*')'|'>('*')'|'=('*')')
	    region_highlight+=("$start_pos $((start_pos+2)) ${__chromatic_attrib_zle[cd]}")
	    region_highlight+=("$((end_pos-1)) $end_pos ${__chromatic_attrib_zle[cd]}")
	    substr_color=1
	    ;;
    esac
}

# Check if the argument is variable assignment
_zsh_highlight_main_highlighter_check_assign()
{
    setopt localoptions extended_glob
    [[ $arg == [[:alpha:]_][[:alnum:]_]#(|\[*\])=* ]]
}

# Check if the argument is a path.
_zsh_highlight_main_highlighter_check_path()
{
    setopt localoptions nonomatch
    local expanded_path; : ${expanded_path:=${(Q)~arg}}
    [[ -z $expanded_path ]] && return 1
    [[ -e $expanded_path ]] && return 0
    # Search the path in CDPATH
    local cdpath_dir
    for cdpath_dir in $cdpath ; do
	[[ -e "$cdpath_dir/$expanded_path" ]] && return 0
    done
    [[ ! -e ${expanded_path:h} ]] && return 1
    if [[ ${BUFFER[1]} != "-" && ${#LBUFFER} == $end_pos ]]; then
	local -a tmp
	# got a path prefix?
	tmp=( ${expanded_path}*(N) )
	(( $#tmp > 0 )) && style_override=path_prefix && _zsh_highlight_main_highlighter_predicate_switcher bc && return 0
    fi
    return 1
}

# Highlight special chars inside double-quoted strings
_zsh_highlight_main_highlighter_highlight_string()
{
    setopt localoptions extendedglob noksharrays
    local i j k style varflag str_start str_end
    ((str_start=start_pos+1)); str_end=0
    for substr in "${(Qz)arg}"; do
	((str_start+=${#BUFFER[$str_start+1,-1]}-${#${BUFFER[$str_start+1,-1]##[[:space:]]#}}))
	((str_end=str_start+${#substr}))
	case "$substr" in
	    '$(('*'))') style="${__chromatic_attrib_zle[numbers]}"
			region_highlight+=("$str_start $str_end $style")
			;;
	    '$('*')') style="${__chromatic_attrib_zle[builtins]}"
		      region_highlight+=("$str_start $str_end $style")
		      ;;
	    '`'*'`') style="${__chromatic_attrib_zle[builtins]}"
		      region_highlight+=("$str_start $str_end $style")
		      ;;
	    '$'[-#'$''*'@?!]|'$'[a-zA-Z0-9_]##|'${'?##'}') style="${__chromatic_attrib_zle[parameters]}"
							   region_highlight+=("$str_start $str_end $style")
						     ;;
	esac
	str_start="$str_end"
    done
    
    # Starting quote is at 1, so start parsing at offset 2 in the string.
#     for (( i = 2 ; i < end_pos - start_pos ; i += 1 )) ; do
# 	(( j = i + start_pos - 1 ))
# 	(( k = j + 1 ))
# 	case "$arg[$i]" in
# 	    '$') style=$ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]
# 		  (( varflag = 1))
#   		  ;;
# 	    "\\") style=$ZSH_HIGHLIGHT_STYLES[back-double-quoted-argument]
# 		  for (( c = i + 1 ; c < end_pos - start_pos ; c += 1 )); do
# 		      [[ "$arg[$c]" != ([0-9,xX,a-f,A-F]) ]] && break
# 		  done
# 		  AA=$arg[$i+1,$c-1]
# 		  # Matching for HEX and OCT values like \0xA6, \xA6 or \012
# 		  if [[ "$AA" =~ "^(0*(x|X)[0-9,a-f,A-F]{1,2})" || "$AA" =~ "^(0[0-7]{1,3})" ]];then
# 		      (( k += $#MATCH ))
# 		      (( i += $#MATCH ))
# 		  else
# 		      (( k += 1 )) # Color following char too.
# 		      (( i += 1 )) # Skip parsing the escaped char.
# 		  fi
# 		  (( varflag = 0 )) # End of variable
# 		  ;;
# 	    ([^a-zA-Z0-9_])) (( varflag = 0 )) # End of variable
#                              continue
#                              ;;
#             *) [[ $varflag -eq 0 ]] && continue ;;
# esac
# region_highlight+=("$j $k $style")
# done
}
 
## Check if command with given prefix exists
_zsh_highlight_main_highlighter_check_command()
{
    setopt localoptions nonomatch
    local -a prefixed_command
    [[ $arg != $arg:t ]] && return 1  # don't match anything if explicit path is present
    for p in $path; do prefixed_command+=( $p/${arg}*(N) ); done
    [[ ${BUFFER[1]} != "-" && ${#LBUFFER} == $end_pos && $#prefixed_command > 0 ]] && return 0 || return 1
}

## Check if the argument is a file, if yes change the style accordingly
_zsh_highlight_main_highlighter_check_file()
{
    setopt localoptions nonomatch
    local expanded_arg matched_file

    expanded_arg="${(Q)~arg}"
    [[ -z "$expanded_arg" ]] && return 1
    [[ -d "$expanded_arg" ]] && return 1
    [[ "${BUFFER[1]}" != "-" && "${#LBUFFER}" == "$end_pos" ]] && matched_file=("${expanded_arg}"*(Noa^/[1]))
    [[ -e "$expanded_arg" || -e "$matched_file" ]] && lsstyle=none || return 1
    [[ -e "$matched_file" ]] && _zsh_highlight_main_highlighter_predicate_switcher bc

    [[ ! -z "${ZSH_HIGHLIGHT_STYLES[file]}" ]] && lsstyle="${ZSH_HIGHLIGHT_STYLES[file]}" && return 0

    # [[ rs ]]
    # [[ -d $expanded_arg || -d $matched_file ]] && lsstyle=$__chromatic_attrib_zle[di] && return 0
    [[ -h "$expanded_arg" || -h "$matched_file" ]] && lsstyle="${__chromatic_attrib_zle[ln]}" && return 0
    # [[ mh ]]
    [[ -p "$expanded_arg" || -p "$matched_file" ]] && lsstyle="${__chromatic_attrib_zle[pi]}" && return 0
    [[ -S "$expanded_arg" || -S "$matched_file" ]] && lsstyle="${__chromatic_attrib_zle[so]}" && return 0
    # [[ do ]]
    [[ -b "$expanded_arg" || -b "$matched_file" ]] && lsstyle="${__chromatic_attrib_zle[bd]}" && return 0
    [[ -c "$expanded_arg" || -c "$matched_file" ]] && lsstyle="${__chromatic_attrib_zle[cd]}" && return 0
    # [[ or ]]
    # [[ mi ]]
    [[ -u "$expanded_arg" || -u "$matched_file" ]] && lsstyle="${__chromatic_attrib_zle[su]}" && return 0
    [[ -g "$expanded_arg" || -g "$matched_file" ]] && lsstyle="${__chromatic_attrib_zle[sg]}" && return 0
    # [[ ca ]]
    # [[ tw ]]
    # [[ ow ]]
    [[ -k "$expanded_arg" || -k "$matched_file" ]] && lsstyle="${__chromatic_attrib_zle[st]}" && return 0
    [[ -x "$expanded_arg" || -x "$matched_file" ]] && lsstyle="${__chromatic_attrib_zle[ex]}" && return 0

    [[ -e "$expanded_arg" ]] && lsstyle="${__chromatic_attrib_zle[*.$expanded_arg:e]}" && return 0
    [[ -n "$matched_file:e" ]] && lsstyle="${__chromatic_attrib_zle[*.$matched_file:e]}" && return 0

    return 0
}
