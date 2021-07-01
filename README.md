# vim-literate-markdown

![Demo gif](demo.gif)

## What?

This is a Vim plugin that attempts to replicate a subset of the features of Emacs' Org mode code handling.
So for example, tangling the code from the current file, or executing blocks of code.
For this purpose, it provides some mappings and commands for Markdown files.

This plugin is a work in progress and far from complete.
For more information about its features, see [`doc/literate-markdown.txt`](doc/literate-markdown.txt) (best viewed in Vim).
For examples of literate programming, see [`examples/`](examples/).

**Disclaimer:** this code is not extensively tested. It works for me, running Vim 8.2 in the terminal on macOS, but it's not guaranteed to work for others. It might not work in Neovim, as I don't use Neovim.

## Why?

Literate programming is a great way to provide explanation about what you're doing in code.
It also lets you document what you're doing without the need to follow the exact order of the code, unlike comments embedded in source code.
You can e.g. layout the overall structure of a program and then jump immediately to some specific computation.
Emacs handles literate programming quite well in Org mode; I didn't know about anything similar for Vim, particularly for Markdown files.
So I wrote this to allow literate programming in Markdown, because in my opinion Markdown is a much more universal syntax than Org.

## Installation

You can use your favorite plugin manager (I recommend [vim-plug](https://github.com/junegunn/vim-plug)).
You can also use Vim's built-in package functionality (`:h packages`).
