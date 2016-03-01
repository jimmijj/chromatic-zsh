## parse the entire command line and build region_highlight array
_parse()
{
    # if _zsh_highlight_cursor_moved && ! _zsh_highlight_buffer_modified; then
    # case ${BUFFER[$CURSOR]} in
    # 	'('|')'|'['|']'|'{'|'}') :;;
    # 	*) return 0;
    # esac
    # fi

    emulate -L zsh
    setopt localoptions extendedglob bareglobqual
    local start_pos=0 end_pos highlight_glob=true new_expression=true arg style lsstyle start_file_pos end_file_pos sudo=false sudo_arg=false isbrace=0
    typeset -a ZSH_HIGHLIGHT_TOKENS_COMMANDSEPARATOR
    typeset -a ZSH_HIGHLIGHT_TOKENS_REDIRECTION
    typeset -a ZSH_HIGHLIGHT_TOKENS_PRECOMMANDS
    typeset -a ZSH_HIGHLIGHT_TOKENS_FOLLOWED_BY_COMMANDS
    region_highlight=()
    _block=()
    _blokl=()
    _blockp=()

    ZSH_HIGHLIGHT_TOKENS_COMMANDSEPARATOR=(
	'|' '||' ';' '&' '&&' '&|' '|&' '&!' '(' ';;' '{'
    )
    ZSH_HIGHLIGHT_TOKENS_REDIRECTION=(
	'<' '<>' '>' '>|' '>!' '>>' '>>|' '>>!' '<<' '<<-' '<<<' '<&' '>&' '<& -' '>& -' '<& p' '>& p' '&>' '>&|' '>&!' '&>|' '&>!' '>>&' '&>>' '>>&|' '>>&!' '&>>|' '&>>!'
    )
    ZSH_HIGHLIGHT_TOKENS_PRECOMMANDS=(
	'builtin' 'command' 'exec' 'functions' 'nocorrect' 'noglob' 'type' 'unalias' 'unhash' 'whence' 'where' 'which' 'do'
    )
    group_tokens=(
	'(' ')' '$(*)' '&' '&&' '&|' '|&' '&!' '(' ';;' '{'
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

	   local substr_color=0 isfile=false isgroup=0
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
	       _check_common_expression "$arg" || _check_subsequent_expression "$arg" || style="${__chromatic_attrib_zle[default]}";
	   fi

	   ((isbrace==1&&isbrace++||(isbrace=0)))
	   # if a style_override was set (eg in _zsh_highlight_main_highlighter_check_path), use it
	   [[ -n $style_override ]] && style=$__chromatic_attrib_zle[$style_override]
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

## Look for expressions which may be present on any position in the command line
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
        ')')
	    ((_blockl[1]>0)) && _block+=("$_blockp[${_blockl[1]}]" "$((end_pos-1)) $end_pos") && ((_blockl[1]--))
            style="${__chromatic_attrib_zle[functions]}";;
	'$(('*'))')
	    style="${__chromatic_attrib_zle[numbers]}"
	    _block+=("$start_pos $((start_pos+3))" "$((end_pos-2)) $end_pos");;
	'$['*']')
	    style="${__chromatic_attrib_zle[numbers]}"
	    _block+=("$start_pos $((start_pos+2))" "$((end_pos-1)) $end_pos");;
	'$('*')')
	    region_highlight+=("$start_pos $((start_pos+2)) ${__chromatic_attrib_zle[ex]}")
	    region_highlight+=("$((end_pos-1)) $end_pos ${__chromatic_attrib_zle[ex]}")
	    _block+=("$start_pos $((start_pos+2))" "$((end_pos-1)) $end_pos")
	    substr_color=1;;
	'`'*'`')
	    region_highlight+=("$start_pos $((start_pos+1)) ${__chromatic_attrib_zle[builtins]}")
	    region_highlight+=("$((end_pos-1)) $end_pos ${__chromatic_attrib_zle[builtins]}")
	    _block+=("$start_pos $((start_pos+1))" "$((end_pos-1)) $end_pos")
	    substr_color=1;;
	'{') isbrace=1; style="${__chromatic_attrib_zle[reserved-words]}";;
	'}') style="${__chromatic_attrib_zle[reserved-words]}";;
	?'..'?|[0-9]##'..'[0-9]##'..'[0-9]##) ((isbrace==2)) && style="${__chromatic_attrib_zle[numbers]}";;
	*'*'*) $highlight_glob && style="${__chromatic_attrib_zle[globs]}";;
	';') style="${__chromatic_attrib_zle[separators]}";;
	*) if _check_path; then
	       style="${__chromatic_attrib_zle[di]}"
	   elif [[ -n ${(M)ZSH_HIGHLIGHT_TOKENS_REDIRECTION:#"$1"} ]]; then
	       style=$__chromatic_attrib_zle[redirection]
	   elif [[ $1[0,1] = $histchars[0,1] ]]; then
	       style=$__chromatic_attrib_zle[history-expansion]
	   else
	       style="${__chromatic_attrib[default]}"
	   fi
	   _check_file && isfile=true
	   ;;
    esac
}

## Look for a leading expressions
_check_leading_expression()
{
    res=$(LC_ALL=C builtin type -w "$1" 2>/dev/null)
    case $res in
	*': reserved')  style="${__chromatic_attrib_zle[reserved-words]}";;
	*': alias')     style="${__chromatic_attrib_zle[aliases]}"
			local aliased_command="${"$(alias -- $arg)"#*=}"
			[[ -n ${(M)ZSH_HIGHLIGHT_TOKENS_FOLLOWED_BY_COMMANDS:#"$aliased_command"} && -z ${(M)ZSH_HIGHLIGHT_TOKENS_FOLLOWED_BY_COMMANDS:#"$arg"} ]] && ZSH_HIGHLIGHT_TOKENS_FOLLOWED_BY_COMMANDS+=($arg);;
	*': builtin')   style="${__chromatic_attrib_zle[builtins]}";;
	*': function')  style="${__chromatic_attrib_zle[functions]}";;
	*': command'|*': hashed') style="${__chromatic_attrib_zle[ex]}";;
	*)
            if [[ [a-zA-Z0-9_]##(|\[*\])=* ]]; then
		style="${__chromatic_attrib_zle[parameters]}"
		new_expression=true
	    elif _check_command; then
		style=$__chromatic_attrib_zle[command_prefix]
	    elif [[ $arg[0,1] == $histchars[0,1] || $arg[0,1] == $histchars[2,2] ]]; then
		style=$__chromatic_attrib_zle[history-expansion]
	    else
	    case "$1" in
		'(('*'))')
		    style="${__chromatic_attrib_zle[numbers]}"
		    _block+=("$start_pos $((start_pos+2))" "$((end_pos-2)) $end_pos");;
		'(')
		    ((_blockl[1]++))
		    _blockp[${_blockl[1]}]="$start_pos $end_pos"
		    style="${__chromatic_attrib_zle[functions]}";;
		*) ;;
	    esac
	    fi
	    ;;
    esac
}

## Look for a subsequent expressions
_check_subsequent_expression()
{
    case "$1" in
	'--'*|'-'*) style="${__chromatic_attrib_zle[options]}";;
	'|'|'|&') style="${__chromatic_attrib_zle[pi]}";;
	'||'|'&&'|'&'|'&|'|'&!'|';;') style="${__chromatic_attrib_zle[separators]}";;
	'<('*')'|'>('*')'|'=('*')')
	    region_highlight+=("$start_pos $((start_pos+2)) ${__chromatic_attrib_zle[cd]}")
	    region_highlight+=("$((end_pos-1)) $end_pos ${__chromatic_attrib_zle[cd]}")
	    _block+=("$start_pos $((start_pos+2))" "$((end_pos-1)) $end_pos")
	    substr_color=1;;
    esac
}

## Check if the argument is a path
_check_path()
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
	(( $#tmp > 0 )) && style_override=path_prefix && : _zsh_highlight_main_highlighter_predicate_switcher bc && return 0
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
# 	    '$') style=$__chromatic_attrib_zle[dollar-double-quoted-argument]
# 		  (( varflag = 1))
#   		  ;;
# 	    "\\") style=$__chromatic_attrib_zle[back-double-quoted-argument]
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
_check_command()
{
    setopt localoptions nonomatch
    local -a prefixed_command
    [[ $arg != $arg:t ]] && return 1  # don't match anything if explicit path is present
    for p in $path; do prefixed_command+=( $p/${arg}*(N) ); done
    [[ ${BUFFER[1]} != "-" && ${#LBUFFER} == $end_pos && $#prefixed_command > 0 ]] && return 0 || return 1
}

## Check if the argument is a file, if yes change the style accordingly
_check_file()
{
    setopt localoptions nonomatch
    local expanded_arg matched_file

    expanded_arg=${(Q)~arg}
    [[ -z "$expanded_arg" ]] && return 1
    [[ -d "$expanded_arg" ]] && return 1
    [[ "${BUFFER[1]}" != "-" && "${#LBUFFER}" == "$end_pos" ]] && matched_file=("${expanded_arg}"*(Noa^/[1]))
    [[ -e "$expanded_arg" || -e "$matched_file" ]] && lsstyle=none || return 1
    [[ -e "$matched_file" ]] && : _zsh_highlight_main_highlighter_predicate_switcher bc

    [[ ! -z "${__chromatic_attrib_zle[file]}" ]] && lsstyle="${__chromatic_attrib_zle[file]}" && return 0

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
