# Setting attributes of the completion system

autoload -U compinit && compinit						     
zstyle ':completion:*' group-name ''						     
for key in "${(@k)__chromatic_attrib}"; do					     
    zstyle ':completion:*:'"$key*" list-colors '=*='
done										     
zstyle ':completion:*:directory-stack' list-colors '=(#b) #([0-9]#)*( *)==95='"${__chromatic_attrib[directories}"