chromatic-zsh
=======================

The aim of this project is to provide unified colorful [zsh](http://www.zsh.org) environment including syntax, files, selected regions, searched patterns, completion system, etc.
All objects retain defined attributes, regardless of the context.

Examples
--------

![](misc/screenshot.png)


How to install
--------------

* Download the script or clone this repository:

        git clone git://github.com/jimmijj/chromatic-zsh.git

* Source the script

        . /path/to/chromatic-zsh/chromatic-zsh.zsh

* Add previous line at the end of `~/.zshrc` and start new session.

        cat <<<'. /path/to/chromatic-zsh/chromatic-zsh.zsh' >>~/.zshrc && zsh
