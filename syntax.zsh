## First set static zle_highlight and activate it
_search()
{
    zle_highlight=(default:"${__chromatic_attrib_zle[none]}" isearch:"${__chromatic_attrib_zle[search-pattern]}" region:"${__chromatic_attrib_zle[region]}" special:"${__chromatic_attrib_zle[special]}" suffix:"${__chromatic_attrib_zle[suffix]}")
} && _search

reparse=0
## Next rebuilt dynamically region_highlight on any buffer event
_syntax()
{
    ## Run parser if buffer has changed
    if [[ "$BUFFER" != "$_lastbuffer" || "$_reparse" -gt 0 ]]; then
	((_reparse--))
	_parse
	region_highlight_copy=("${region_highlight[@]}")
    elif ((CURSOR!=_lastcursor)); then
     	_reparse=0
    fi

    ## Restore saved region_highlight (it could have been changed if the cursor has moved)
    region_highlight=("${region_highlight_copy[@]}")

    ## Cursor highlighting as a standout is not needed in the newest gnome-terminal and its derivatives (eg. terminator)
    #region_highlight+=("$CURSOR $((CURSOR+1)) standout")

    ## Highlight complex commands if cursor is on their position
    for ts bs te be in ${(zkv)_block}; do
	(((CURSOR>=ts&&CURSOR<bs)||(CURSOR>te&&CURSOR<=be))) && region_highlight+=("$ts $bs ${__chromatic_attrib_zle[block]}" "$te $be ${__chromatic_attrib_zle[block]}")
    done

    ## Bring back region higlighting from zle_highlight array (was overwriten by region_highlight)
    ((REGION_ACTIVE)) && region_highlight+=("$((CURSOR < MARK ? CURSOR : MARK)) $((CURSOR > MARK ? CURSOR : MARK)) ${${(M)zle_highlight[@]:#region*}#region:}")

    _lastbuffer="$BUFFER"; _lastcursor="$CURSOR"
}

## Widgets redefinition to call _syntax on each event
_redefine_widgets()
{
    local widget
    for widget in ${${(f)"$(builtin zle -la)"}:#(.*|_*|run-help|beep|auto-*|*-argument|argument-base|clear-screen|describe-key-briefly|history-incremental*|kill-buffer|overwrite-mode|push-input|push-line-or-edit|reset-prompt|set-local-history|split-undo|undefined-key|what-cursor-position|where-is|yank*)}; do
	case $widgets[$widget] in

	    # Builtin widgets: override and make it call the builtin ".widget".
	    builtin) eval "_._$widget() { builtin zle .$widget -- \"\$@\" && _syntax }; zle -N $widget _._$widget";;

	    # Completion widget
	    completion:*)
		eval "zle -C _._-$widget ${${widgets[$widget]#*:}/:/ }; _._$widget() { builtin zle _._-$widget -- \"\$@\" && _syntax }; zle -N $widget _._$widget";;

	    ## Skip widgets defined by users and the like
	    *) ;;
	esac
    done

    ## Rebuild zle_highlight array for history-incremental* search widgets
    for widget in history-incremental-pattern-search-backward history-incremental-pattern-search-forward history-incremental-search-backward history-incremental-search-forward; do
	eval "_._$widget() { zle_highlight=(default:\${__chromatic_attrib_zle[search-line]} isearch:\${__chromatic_attrib_zle[search-pattern]}); builtin zle .$widget -- \"\$@\" && _search && _syntax }; zle -N $widget _._$widget"
    done

    ## For yank* widgets set appropriate flag
    for widget in yank yank-pop; do
	eval "_._$widget() { builtin zle .$widget -- \"\$@\" && _syntax && zle -f yank }; zle -N $widget _._$widget"
    done

} && _redefine_widgets

## Load parser
. "${0:h}"/parser.zsh
