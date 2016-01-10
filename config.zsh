# Default atrributes

declare -A __chromatic_attrib __chromatic_attrib_zle

local ncolors=$(echotc Co)

if [[ $ncolors == 256 ]]; then
    __chromatic_attrib=(
	commands       '38;5;77'
	builtins       '38;5;83'
	functions      '38;5;134'
	aliases        '38;5;128'
	parameters     '38;5;28'
	reserved-words '31'
	manuals        '38;5;34'
	options        '38;5;71'
	directories    '38;5;12'
        process-ids    '38;5;196'
	process-names  '33'
    )
else
    __chromatic_attrib=(
	commands       '1;33'
	builtins       '1;33'
	functions      '33'
	aliases        '1;35'
	parameters     '32'
	reserved-words '31'
	manuals        '32'
	options        '36'
	directories    '1;34'
        process-ids    '1;31'
        process-names  '1;33'
    )
fi


## Return attribute in the format compatible with zle_highlight, unfolded from color code
takeattrib()
{
    local -a attrib
    while [ "$#" -gt 0 ]; do
	[[ "$1" == 38 && "$2" == 5 ]] && {attrib+=("fg=$3"); shift 3; continue}
	[[ "$1" == 48 && "$2" == 5 ]] && {attrib+=("bg=$3"); shift 3; continue}
	case $1 in
	    00|0) attrib+=("none"); shift;;
            01|1) attrib+=("bold" ); shift;;
            02|2) attrib+=("faint"); shift;;
            03|3) attrib+=("italic"); shift;;
            04|4) attrib+=("underscore"); shift;;
            05|5) attrib+=("blink"); shift;;
            07|7) attrib+=("standout"); shift;;
            08|8) attrib+=("concealed"); shift;;
            3[0-7]) attrib+=("fg=$(($1-30))"); shift;;
            4[0-7]) attrib+=("bg=$(($1-40))"); shift;;
            9[0-7]) [[ "$ncolors" == 256 ]] && attrib+=("fg=$(($1-82))") || attrib+=("fg=$(($1-90))" "bold"); shift;;
            10[0-7]) [[ "$ncolors" == 256 ]] && attrib+=("bg=$(($1-92))") || attrib+=("bg=$(($1-100))" "bold"); shift;;
            *) shift;;
        esac
    done
    code="${(j:,:)attrib}"
}

## Convert array __chromatic_attrib to format compatible with zle_highlight
for key in "${(@k)__chromatic_attrib}"; do
    code="${__chromatic_attrib[$key]}"
    takeattrib ${(s.;.)code}
    __chromatic_attrib_zle+=("$key" "$code")
done
