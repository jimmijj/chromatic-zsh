local ncolors="$(echotc Co)"
declare -A __chromatic_attrib __chromatic_attrib_zle

# Default atrributes
__chromatic_attrib=(
    aliases        '1;35'
    none           '0'
    builtins       '1;33'
    comments       '2;37'
    directories    '1;34'
    defaults       '0'
    files          '0'
    functions      '33'
    glob           '34'
    block          '46'
    manuals        '32'
    numbers        '2;36'
    options        '36'
    parameters     '32'
    process-ids    '1;31'
    process-names  '1;33'
    region         '44'
    redirection    '35'
    reserved-words '31'
    search-line    '37'
    search-pattern '1;33;41'
    separators     '35'
    special        '36'
    suffix         '1'
)

if [[ "$ncolors" == 256 ]]; then
    __chromatic_attrib+=(
	aliases        '38;5;128'
	builtins       '38;5;83'
	comments       '38;5;244'
	directories    '38;5;12'
	functions      '38;5;134'
	manuals        '38;5;34'
	numbers        '38;5;36'
	options        '38;5;71'
	parameters     '38;5;28'
        process-ids    '38;5;196'
	process-names  '33'
	region         '48;5;17'
    )
fi

## Add attributes from LS_COLORS
__chromatic_attrib+=(${=${(s.:.)=LS_COLORS//=/ }})

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
