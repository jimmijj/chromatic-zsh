chromatic-zsh
======================================================================
This project started from the zsh-syntax-highlighting, redesigned it completely added many new features and lifted up to the next level.

   ![](misc/sample.gif)

The aim of this project now is to provide unified colorful [zsh](http://www.zsh.org) environment.

That includes:
 - completion system
   * commands, functions, aliases, etc.
   * possible commands arguments or options (like directory stack for `cd` or process ids for `kill`)
 - syntax
   * including blocks of complex commands
   * including files according to their attributes
 - searched patterns in history
 - selected regions
 - default color scheme for some commands output (like `less` or `grep`)

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


Some features for completion system works only if it is enable. Thus, although not strictly neccessary, I recommend to add also to ~/.zshrc:

    autoload -U compinit && compinit
    zstyle ':completion:*' verbose yes
    zstyle ':completion:*' group-name ''
    zstyle ':completion:*' menu select


Examples
----------------------------------------------------------------------
 - The basic `ls` output with `--color` option (on GNU system) uses `$LS_COLORS` environment variable to attach color to each file type. The result may look like that: 

   ![](misc/ls.png)

 - One expects that the same color is used in completion system

   ![](misc/ls_comp.png)

   (note: at the end of the line `tab` was hit)

- and also syntax highlighting on the command line:

  ![](misc/ls_high.png)

- Options and their descriptions are highlighted differently:

  ![](misc/ls_opt.png)

  (again notice tab after `-`)

- Here is the sample of some longer command line...

  ![](misc/screenshot.png)

- and completion with many categories:

  ![](misc/comp.png)

  Notice the same color for the same group (reserved words, parameters, etc) on the command line and completion system with the example above.

- Directories are in blue everywhere, also in the directory stack completion of `cd -`.

  ![](misc/cd_comp.png)

- Process ids are red by default, clearly separated from pseudoterminal numbers

  ![](misc/kill_comp.png)

- Searched pattern looks the same regardless where search took place: shell history or grep command

  ![](misc/search.png)

  ![](misc/grep.png)
