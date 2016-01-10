# Default atrributes

declare -A __chromatic_attrib

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
