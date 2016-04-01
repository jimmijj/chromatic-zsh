## parse the entire command line and build region_highlight array
_parse()
{
    emulate -L zsh
    setopt localoptions extendedglob bareglobqual
    typeset -a ZSH_HIGHLIGHT_TOKENS_COMMANDSEPARATOR
    typeset -a ZSH_HIGHLIGHT_TOKENS_REDIRECTION
    typeset -a ZSH_HIGHLIGHT_TOKENS_PRECOMMANDS
    typeset -a ZSH_HIGHLIGHT_TOKENS_FOLLOWED_BY_COMMANDS
    region_highlight=()

    ## list of complex commands, numbers means: 1 - match only on leading position, 0 - anywhere
    local -a _groups=('0 (,)' '0 [,]' '0 {,}' '0 [[,]]' '1 if,then,elif,else,fi' '1 case,in,esac' '1 for,in,do,done' '1 while,do,done')
    ## range of each block, and temporary array for future use
    _block=()
    _blockp=()

    ZSH_HIGHLIGHT_TOKENS_COMMANDSEPARATOR=(
	'|' '||' ';' '&' '&&' '&|' '|&' '&!' '(' ';;' '{'
    )
    ZSH_HIGHLIGHT_TOKENS_REDIRECTION=(
	'<' '<>' '>' '>|' '>!' '>>' '>>|' '>>!' '<<' '<<-' '<<<' '<&' '>&' '<& -' '>& -' '<& p' '>& p' '&>' '>&|' '>&!' '&>|' '&>!' '>>&' '&>>' '>>&|' '>>&!' '&>>|' '&>>!'
    )
    ZSH_HIGHLIGHT_TOKENS_PRECOMMANDS=(
	'builtin' 'command' 'exec' 'functions' 'nocorrect' 'noglob' 'type' 'unalias' 'unhash' 'whence' 'where' 'which' 'if' 'then' 'elif' 'else' 'do' 'while'
    )

    # Tokens that are always immediately followed by a command.
    ZSH_HIGHLIGHT_TOKENS_FOLLOWED_BY_COMMANDS=(
	$ZSH_HIGHLIGHT_TOKENS_COMMANDSEPARATOR $ZSH_HIGHLIGHT_TOKENS_PRECOMMANDS
    )

    _split "$BUFFER" 0
}

_split()
{
    local buf=$1 init_pos=$2
    local start_pos=0 end_pos highlight_glob=true isleading=1 nextleading=0 arg style lsstyle start_file_pos end_file_pos sudo=false sudo_arg=false isbrace=0
    local splitbuf1=(${(z)${(z)buf}})
    local splitbuf2=(${(z)${(z)buf//$'\n'/ \$\'\\\\n\' }}) # ugly hack, but I have no better idea
    local argnum=0
    for arg in $splitbuf1; do
	((argnum++))
	if [[ $splitbuf1[$argnum] != $splitbuf2[$argnum] ]] && isleading=1 && continue

	local issubstring=0 isfile=0 isgroup=0
	[[ $start_pos -eq $init_pos && $arg = 'noglob' ]] && highlight_glob=false
	((start_pos+=${#buf[$start_pos+1,-1]}-${#${buf[$start_pos+1,-1]##[[:space:]]#}}))
	((end_pos=start_pos+${#arg}))

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
				 nextleading=0
			     fi
			     ;;
	    esac
	fi

	style="${__chromatic_attrib_zle[default]}"
	if ((isleading)); then
	    nextleading=0
	    if [[ "$arg" = "sudo" ]]; then
		sudo=true
	    else
		_check_common_expression "$arg" "$((init_pos+start_pos))" || _check_leading_expression "$arg" "$((init_pos+start_pos))"
	    fi
	else
	    _check_common_expression "$arg" "$((init_pos+start_pos))" || _check_subsequent_expression "$arg" "$((init_pos+start_pos))"
	fi

	((isbrace==1&&isbrace++||(isbrace=0)))
	if ((isfile)); then
	    ((start_file_pos=start_pos+${#arg}-${#arg:t}))
	    end_file_pos=$end_pos
	    ((end_pos=end_pos-${#arg:t}))
	    region_highlight+=("$((init_pos+start_file_pos)) $((init_pos+end_file_pos)) $lsstyle")
	fi
	((issubstring==0)) && region_highlight+=("$((init_pos+start_pos)) $((init_pos+end_pos)) $style")
	[[ $isleading == 1 && -n ${(M)ZSH_HIGHLIGHT_TOKENS_FOLLOWED_BY_COMMANDS:#"$arg"} ]] && nextleading=1
	((isfile)) && start_pos=$end_file_pos || start_pos=$end_pos
	isleading=$nextleading
    done
}


## Look for expressions which may be present on any position in the command line
_check_common_expression()
{
    local arg="$1" start_pos="$2"

    ## Look for complex expressions - openning word...
    if [[ -n ${(M)_groups:#* $arg,*} ]]; then
	if ((isleading)); then
		_blockp+=(${(M)_groups:#* $arg,*}":$start_pos $end_pos")
		style="${__chromatic_attrib_zle[reserved-words]}"
		[[ $arg == '(' ]] && style="${__chromatic_attrib_zle[functions]}"
		[[ $arg == '[' ]] && style="${__chromatic_attrib_zle[builtins]}"
		[[ $arg == '{' ]] && isbrace=1
	elif [[ ${${(M)_groups:#* $arg,*}% *} == 0 ]]; then
	    _blockp+=(${(M)_groups:#* $arg,*}":$start_pos $end_pos")
	    [[ $arg == '{' ]] && isbrace=1 && style="${__chromatic_attrib_zle[reserved-words]}"
	fi
	return 0
    ##... or closing...
    elif [[ -n ${(M)_blockp[-1]:#*,$arg:*} ]]; then
	if ((${_blockp[-1]%% *}<=isleading)); then
	    _block+=("${_blockp[-1]#*:}" "$start_pos $end_pos")
	    _blockp=(${_blockp:0:-1})
	    style="${__chromatic_attrib_zle[reserved-words]}"
	    [[ $arg == ')' ]] && style="${__chromatic_attrib_zle[functions]}"
	    [[ $arg == ']' ]] && style="${__chromatic_attrib_zle[builtins]}"
	fi
	return 0
    ##... or in the middle.
    elif [[ -n ${(M)_blockp[-1]:#*,$arg,*} ]]; then
	_block+=("${_blockp[-1]#*:}" "$start_pos $end_pos")
	style="${__chromatic_attrib_zle[reserved-words]}"
	return 0
    fi

    case "$arg" in
	"'"*"'") style="${__chromatic_attrib_zle[comments]}";;
	'"'*'"')
	    style="${__chromatic_attrib_zle[comments]}"
	    region_highlight+=("$start_pos $end_pos $style")
	    _substring
	    issubstring=1
	    ;;
	'$'[-#'$''*'@?!]|'$'[a-zA-Z0-9_]##) style="${__chromatic_attrib_zle[parameters]}";;
	'${'?##'}')
	    style="${__chromatic_attrib_zle[parameters]}";
	    _block+=("$start_pos $((start_pos+2))" "$((end_pos-1)) $end_pos");;
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
	    issubstring=1;;
	'`'*'`')
	    region_highlight+=("$start_pos $((start_pos+1)) ${__chromatic_attrib_zle[builtins]}")
	    region_highlight+=("$((end_pos-1)) $end_pos ${__chromatic_attrib_zle[builtins]}")
	    _block+=("$start_pos $((start_pos+1))" "$((end_pos-1)) $end_pos")
	    issubstring=1;;
	?'..'?|[0-9]##'..'[0-9]##'..'[0-9]##) ((isbrace==2)) && style="${__chromatic_attrib_zle[numbers]}";;
	*'*'*) $highlight_glob && style="${__chromatic_attrib_zle[glob]}";;
	';') nextleading=1; style="${__chromatic_attrib_zle[separators]}";;
	[0-9]'>') style="${__chromatic_attrib_zle[redirection]}";;
	*) if [[ -n ${(M)ZSH_HIGHLIGHT_TOKENS_REDIRECTION:#"$arg"} ]]; then
	       style=$__chromatic_attrib_zle[redirection]
	   elif [[ $arg[0,1] = $histchars[0,1] ]]; then
	       style=$__chromatic_attrib_zle[history-expansion]
	   else
	       _check_file && isfile=1
	   fi
	   ;;
    esac
}

## Look for a leading expressions
_check_leading_expression()
{
    local arg="$1" start_pos="$2"
    local res=$(LC_ALL=C builtin type -w "$arg" 2>/dev/null)
    case $res in
	*': reserved')  style="${__chromatic_attrib_zle[reserved-words]}";;
	*': alias')     style="${__chromatic_attrib_zle[aliases]}"
			local aliased_command="${"$(alias -- $arg)"#*=}"
			[[ -n ${(M)ZSH_HIGHLIGHT_TOKENS_FOLLOWED_BY_COMMANDS:#"$aliased_command"} && -z ${(M)ZSH_HIGHLIGHT_TOKENS_FOLLOWED_BY_COMMANDS:#"$arg"} ]] && ZSH_HIGHLIGHT_TOKENS_FOLLOWED_BY_COMMANDS+=($arg);;
	*': builtin')   style="${__chromatic_attrib_zle[builtins]}";;
	*': function')  style="${__chromatic_attrib_zle[functions]}";;
	*': command'|*': hashed') style="${__chromatic_attrib_zle[ex]}";;
	*)
            if [[ $arg == [a-zA-Z0-9_]##(|\[*\])=* ]]; then
		style="${__chromatic_attrib_zle[parameters]}"
		nextleading=1
	    elif _check_command; then
		style=$__chromatic_attrib_zle[command_prefix]
	    elif [[ $arg[0,1] == $histchars[0,1] || $arg[0,1] == $histchars[2,2] ]]; then
		style=$__chromatic_attrib_zle[history-expansion]
	    else
	    case "$arg" in
		'(('*'))')
		    style="${__chromatic_attrib_zle[numbers]}"
		    _block+=("$start_pos $((start_pos+2))" "$((end_pos-2)) $end_pos");;
		*) ;;
	    esac
	    fi
	    ;;
    esac
}

## Look for a subsequent expressions
_check_subsequent_expression()
{
    local arg="$1" start_pos="$2"
    case "$arg" in
	'--'*|'-'*) style="${__chromatic_attrib_zle[options]}";;
	'|'|'|&')
	    nextleading=1
	    style="${__chromatic_attrib_zle[pi]}";;
	'||'|'&&'|'&'|'&|'|'&!'|';;')
	    nextleading=1
	    style="${__chromatic_attrib_zle[separators]}";;
	'<('*')'|'>('*')'|'=('*')')
	    region_highlight+=("$start_pos $((start_pos+2)) ${__chromatic_attrib_zle[cd]}")
	    region_highlight+=("$((end_pos-1)) $end_pos ${__chromatic_attrib_zle[cd]}")
	    _block+=("$start_pos $((start_pos+2))" "$((end_pos-1)) $end_pos")
	    _split "${1[3,-2]}" "$((start_pos+2))"
	    issubstring=1;;
    esac
}

## Highlight selected atoms inside double-quoted string
_substring()
{
    setopt localoptions extendedglob
    local arg="$1" start_pos="$2" str_start str_end
    ((str_start=start_pos+1)); str_end=0
    for substr in "${(Qz)arg}"; do
	((str_start+=${#BUFFER[$str_start+1,-1]}-${#${BUFFER[$str_start+1,-1]##[[:space:]]#}}))
	((str_end=str_start+${#substr}))
	case "$substr" in
	    '$(('*'))') region_highlight+=("$str_start $str_end ${__chromatic_attrib_zle[numbers]}");;
	    '$('*')') region_highlight+=("$str_start $str_end ${__chromatic_attrib_zle[builtins]}");;
	    '`'*'`') region_highlight+=("$str_start $str_end ${__chromatic_attrib_zle[builtins]}");;
	    '$'[-#'$''*'@?!]|'$'[a-zA-Z0-9_]##|'${'?##'}') region_highlight+=("$str_start $str_end ${__chromatic_attrib_zle[parameters]}");;
	    *\\[[:xdigit:]UXnrtuvx]*) _check_xdigit "$substr";;
	esac
	str_start="$str_end"
    done
}

## Look for hexadecimal digit
_check_xdigit()
{
    [[ $1 =~ (.*)(\\\\[[:xdigit:]UXnrtuvx]) ]] && region_highlight+=("$((str_start+mbegin[2]-1)) $((str_start+mend[2])) ${__chromatic_attrib_zle[special]}") && "$0" "${match[1]}"
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
    [[ "${BUFFER[1]}" != "-" && "${#LBUFFER}" == "$end_pos" ]] && matched_file=("${expanded_arg}"*(Noa[1]))
    [[ -e "$expanded_arg" || -e "$matched_file" ]] && lsstyle=none || return 1
    [[ "$expanded_arg" != "$expanded_arg:t" ]] && style="${__chromatic_attrib_zle[di]}";
    [[ ! -e "$expanded_arg" && -e "$matched_file" ]] && style="${__chromatic_attrib_zle[path]}" && _reparse=2

    [[ ! -z "${__chromatic_attrib_zle[file]}" ]] && lsstyle="${__chromatic_attrib_zle[file]}" && return 0

    # [[ rs ]]
    [[ -d "$expanded_arg" ]] && lsstyle="${__chromatic_attrib_zle[di]}" && return 0
    [[ -d "$matched_file" ]] && lsstyle="${__chromatic_attrib_zle[path]}" && return 0
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
