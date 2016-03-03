## First set static zle_highlight and activate it
_search()
{
    zle_highlight=(default:"${__chromatic_attrib_zle[none]}" isearch:"${__chromatic_attrib_zle[search-pattern]}" region:"${__chromatic_attrib_zle[region]}" special:"${__chromatic_attrib_zle[special]}" suffix:"${__chromatic_attrib_zle[suffix]}")
} && _search

## Next rebuilt dynamically region_highlight on any buffer event
_syntax()
{
    if [[ "$BUFFER" != "$_lastbuffer" ]]; then
	_parse
	region_highlight_copy=("${region_highlight[@]}")
fi
#   elif ((CURSOR!=_lastcursor)); then
 #   fi

    region_highlight=("${region_highlight_copy[@]}")
    for ts bs te be in ${(zkv)_block}; do
	(((CURSOR>=ts&&CURSOR<bs)||(CURSOR>te&&CURSOR<=be))) && region_highlight+=("$ts $bs ${__chromatic_attrib_zle[suffix]}" "$te $be ${__chromatic_attrib_zle[suffix]}")
    done
    
    ((REGION_ACTIVE)) && region_highlight+=("$((CURSOR < MARK ? CURSOR : MARK)) $((CURSOR > MARK ? CURSOR : MARK)) ${${(M)zle_highlight[@]:#region*}#region:}")
    
    _lastbuffer="$BUFFER"; _lastcursor="$CURSOR"
}

## Widgets redefinition to call _syntax on each event
_redefine_widgets()
{
    local widget
    for widget in ${${(f)"$(builtin zle -la)"}:#(.*|_*|run-help|beep|auto-*|*-argument|argument-base|clear-screen|describe-key-briefly|history-incremental*|kill-buffer|overwrite-mode|push-input|push-line-or-edit|reset-prompt|set-local-history|split-undo|undefined-key|what-cursor-position|where-is)}; do
	case $widgets[$widget] in

	    # Builtin widgets: override and make it call the builtin ".widget".
	    builtin) eval "_._$widget() { builtin zle .$widget -- \"\$@\" && _syntax }; \
                     zle -N $widget _._$widget";;

	    # Completion widget
	    completion:*)
		eval "zle -C _._-$widget ${${widgets[$widget]#*:}/:/ }; _._$widget() { builtin zle _._-$widget -- \"\$@\" && _syntax }; \
                          zle -N $widget _._$widget";;

	    ## Skip widgets defined by users and the like
	    *) ;;
	esac
    done

    ## Rebuild zle_highlight array for history-incremental* search widgets
    for widget in history-incremental-pattern-search-backward history-incremental-pattern-search-forward history-incremental-search-backward history-incremental-search-forward; do
	eval "_._$widget() { zle_highlight=(default:\${__chromatic_attrib_zle[search-line]} isearch:\${__chromatic_attrib_zle[search-pattern]}); builtin zle .$widget -- \"\$@\" && _search && _syntax }; zle -N $widget _._$widget"
    done
} && _redefine_widgets

## Load parser
. "${0:h}"/parser.zsh
