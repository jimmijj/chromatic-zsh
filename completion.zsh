# Setting attributes for the completion system

zstyle ':completion:*' group-name ''						     
zstyle ':completion:*:default'         list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*:commands'        list-colors '=*='"${__chromatic_attrib[ex]}"
zstyle ':completion:*:builtins'        list-colors '=*='"${__chromatic_attrib[builtins]}"
zstyle ':completion:*:functions'       list-colors '=*='"${__chromatic_attrib[functions]}"
zstyle ':completion:*:aliases'         list-colors '=*='"${__chromatic_attrib[aliases]}"
zstyle ':completion:*:parameters'      list-colors '=*='"${__chromatic_attrib[parameters]}"
zstyle ':completion:*:reserved-words'  list-colors '=*='"${__chromatic_attrib[reserved-words]}"
zstyle ':completion:*:manuals*'        list-colors '=*='"${__chromatic_attrib[manuals]}"
zstyle ':completion:*:options'         list-colors '=^(-- *)='"${__chromatic_attrib[options]}"
zstyle ':completion:*:directory-stack' list-colors '=(#b) #([0-9]#)*( *)==95='"${__chromatic_attrib[directories]}"
zstyle ':completion:*:*:kill:*'        list-colors '=(#b) #([0-9]#)* (*[a-z])*=34='"${__chromatic_attrib[process-ids]}"'='"${__chromatic_attrib[process-names]}"
zstyle ':completion:*:*:killall:*:processes-names' list-colors '=*='"${__chromatic_attrib[process-names]}"
