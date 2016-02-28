typeset -gA array
## First set static zle_highlight and activate it
_search()
{
    zle_highlight=(default:"${__chromatic_attrib_zle[none]}" isearch:"${__chromatic_attrib_zle[search-pattern]}" region:"${__chromatic_attrib_zle[region]}" special:"${__chromatic_attrib_zle[special]}" suffix:"${__chromatic_attrib_zle[suffix]}")
} && _search

## Next rebuilt dynamically region_highlight on any buffer event
_syntax()
{
    [[ "$BUFFER" != "$_lastbuffer" ]] && _zsh_highlight_main_highlighter && region_highlight_copy=("${region_highlight[@]}")
    
    [[ "$BUFFER" == "$_lastbuffer" ]] && ((CURSOR!=_lastcursor)) &&
	{
	    region_highlight=("${region_highlight_copy[@]}")
	    for x in ${(k)array}; do
		read ts bs <<<"$x"
		read te be <<<"${array[$x]}"
		(((CURSOR>ts&&CURSOR<=bs)||(CURSOR>te&&CURSOR<=be))) && region_highlight+=("$ts $bs bg=33" "$te $be bg=133")
	    done
	}
    
    #    region_highlight=("${region_highlight_copy[@]}")
    ((REGION_ACTIVE)) && region_highlight+=("$((CURSOR < MARK ? CURSOR : MARK)) $((CURSOR > MARK ? CURSOR : MARK)) ${${(M)zle_highlight[@]:#region*}#region:}")
    
    _lastbuffer="$BUFFER"; _lastcursor="$CURSOR"
}

typeset -gA ZSH_HIGHLIGHT_STYLES
typeset -gA ZSH_HIGHLIGHT_FILES

# Whether the command line buffer has been modified or not.
#
# Returns 0 if the buffer has changed since _zsh_highlight was last called.
_zsh_highlight_buffer_modified()
{
    [[ "${_ZSH_HIGHLIGHT_PRIOR_BUFFER:-}" != "$BUFFER" ]]
}

# Whether the cursor has moved or not.
#
# Returns 0 if the cursor has moved since _zsh_highlight was last called.
_zsh_highlight_cursor_moved()
{
    [[ -n $CURSOR ]] && [[ -n ${_ZSH_HIGHLIGHT_PRIOR_CURSOR-} ]] && (($_ZSH_HIGHLIGHT_PRIOR_CURSOR != $CURSOR))
}


# -------------------------------------------------------------------------------------------------
# Setup functions
# -------------------------------------------------------------------------------------------------

# Rebind all ZLE widgets to make them invoke _zsh_highlights.
_zsh_highlight_bind_widgets()
{
    # Load ZSH module zsh/zleparameter, needed to override user defined widgets.
    zmodload zsh/zleparameter 2>/dev/null || {
	echo 'zsh-syntax-highlighting: failed loading zsh/zleparameter.' >&2
	return 1
    }

    # Override ZLE widgets to make them invoke _zsh_highlight.
    local cur_widget
    for cur_widget in ${${(f)"$(builtin zle -la)"}:#(.*|_*|orig-*|run-help|beep|auto-*|*-argument|argument-base|clear-screen|describe-key-briefly|history-incremental*|kill-buffer|overwrite-mode|push-input|push-line-or-edit|reset-prompt|set-local-history|split-undo|undefined-key|what-cursor-position|where-is)}; do
	case $widgets[$cur_widget] in

	    # Already rebound event: do nothing.
	    user:$cur_widget|user:_zsh_highlight_widget_*);;

	    # User defined widget: override and rebind old one with prefix "orig-".
	    user:*) eval "zle -N orig-$cur_widget ${widgets[$cur_widget]#*:}; \
                    _zsh_highlight_widget_$cur_widget() { builtin zle orig-$cur_widget -- \"\$@\" && _syntax }; \
                    zle -N $cur_widget _zsh_highlight_widget_$cur_widget";;

	    # Completion widget: override and rebind old one with prefix "orig-".
	    completion:*) eval "zle -C orig-$cur_widget ${${widgets[$cur_widget]#*:}/:/ }; \
                          _zsh_highlight_widget_$cur_widget() { builtin zle orig-$cur_widget -- \"\$@\" && _syntax }; \
                          zle -N $cur_widget _zsh_highlight_widget_$cur_widget";;

	    # Builtin widget: override and make it call the builtin ".widget".
	    builtin) eval "_zsh_highlight_widget_$cur_widget() { builtin zle .$cur_widget -- \"\$@\" && _syntax }; \
                     zle -N $cur_widget _zsh_highlight_widget_$cur_widget";;

	    # Default: unhandled case.
	    *) echo "zsh-syntax-highlighting: unhandled ZLE widget '$cur_widget'" >&2 ;;
	esac
    done

    ## Special treatment of history-incremental* search widgets
    for search_widget in history-incremental-pattern-search-backward history-incremental-pattern-search-forward history-incremental-search-backward history-incremental-search-forward; do
	eval "_zsh_highlight_widget_$search_widget () { zle_highlight=(default:\${__chromatic_attrib_zle[search-line]} isearch:\${__chromatic_attrib_zle[search-pattern]}); builtin zle .$search_widget -- \"\$@\" && _search && _syntax }; zle -N $search_widget _zsh_highlight_widget_$search_widget"
    done
}

# -------------------------------------------------------------------------------------------------
# Setup
# -------------------------------------------------------------------------------------------------

# Try binding widgets.
_zsh_highlight_bind_widgets || {
    echo 'zsh-syntax-highlighting: failed binding ZLE widgets, exiting.' >&2
    return 1
}

## Load highlighters
. ${0:h}/highlighters/main/main-highlighter.zsh

# Reset scratch variables when commandline is done.
_zsh_highlight_preexec_hook()
{
    _ZSH_HIGHLIGHT_PRIOR_BUFFER=
    _ZSH_HIGHLIGHT_PRIOR_CURSOR=
}
autoload -U add-zsh-hook
add-zsh-hook preexec _zsh_highlight_preexec_hook
