chromatic-zsh
======================================================================
The aim of this project is to provide unified colorful [zsh](http://www.zsh.org) environment.

That includes:
 - completion system
   * commands, functions, aliases, etc.
   * possible commands arguments or options (like directory stack for `cd` or process ids for `kill`)
 - syntax
   * including files according to their attributes
 - searched patterns in history
 - selected regions
 - default color of some commands output (like `less` or `grep`)

All colors are coherent among different context, so that i.e. file.txt is presented always in the color regardless whether its the output of `ls file.txt`, suggestion from completion system or written by hand directly on the command line (see below for examples).

The program check the terminal capability and uses 256 (if possible) or 8 color palette.
All color are configurable.


Installation procedure
----------------------------------------------------------------------
 - Download the script or clone this repository:

        git clone git://github.com/jimmijj/chromatic-zsh.git

 - Add full path of the script at the end of `~/.zshrc`:

        echo '. /path/to/chromatic-zsh/chromatic-zsh.zsh' >>~/.zshrc

 - Start new session with `zsh`.

Examples
----------------------------------------------------------------------
 - The basic `ls` output with `--color` option (on GNU) uses `$LS_COLORS` environment variable to attache color for each file type. Say the result looks like that: 

![](misc/ls.png)

 - The chromatic-zsh uses the same color for completion system...

![](misc/ls_comp.png)

(note: at the end of the line `tab` was hit)

- and systax highlighting:

 ![](misc/ls_high.png)

- Options and their descriptions are highlighted differently:

![](misc/ls_opt.png)

(again notice tab after `-`)

- Here is the sample of some longer command line...

![](misc/screenshot.png)

- and completion with many categories:

![](misc/comp.png)

Notice the same color for the same group (reserved words, parameters, etc) on the command line and completion system.

- Directories are always in blue, also in the directory stack completion of `cd -`.

![](misc/cd_comp.png)

- Process ids are red by default, clearly separated from pseudotermianal numbers
![](misc/kill_comp.png)

- Last example: searched pattern looks the same regardless where search took place: shell history or grep command

![](misc/search.png)

![](misc/grep.png)




----

The part of the program uses zsh-syntax-highlighting.
