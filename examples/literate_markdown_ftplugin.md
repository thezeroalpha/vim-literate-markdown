<!-- :Tangle(vim) ../after/ftplugin/markdown.vim -->
# vim-literate-markdown: ftplugin
This file is activated after other markdown ftplugin files.
The general structure of the file is:

<!-- :Tangle(vim) <^> -->
```vim
<<load guard>>

<<commands>>

<<mappings>>

<<b:undo_ftplugin>>
```

The load guard lets the user disable the autoloaded functions by setting the variable `g:loaded_literate_markdown`.
If it's set, the entire file is skipped.

<!-- :Tangle(vim) <load guard> -->
```vim
if exists('g:loaded_literate_markdown')
  finish
endif
let g:loaded_literate_markdown = 1
```

## Commands
The plugin provides two different commands.
Both are buffer-local, because they should only be enabled in markdown buffers.

One is for tangling:

<!-- :Tangle(vim) <commands> -->
```vim
command -buffer -bar Tangle call literate_markdown#Tangle()
```

And the other to execute blocks:

<!-- :Tangle(vim) <commands>+ -->
```vim
command -buffer -bar ExecPrevBlock call literate_markdown#ExecPreviousBlock()
```

## Mappings
The ftplugin also provides two buffer-local normal-mode mappings.
They are only `<Plug>` mappings, so as not to force mappings on users.
You can map them in your own `after/ftplugin/markdown.vim` with e.g. `nmap <buffer> <leader>ct <Plug>LitMdTangle`.

<!-- :Tangle(vim) <mappings> -->
```vim
nnoremap <buffer> <Plug>LitMdExecPrevBlock :<c-u>ExecPrevBlock<CR>
nnoremap <buffer> <Plug>LitMdTangle :<c-u>Tangle<CR>
```

## Undo ftplugin
Finally, the `b:undo_ftplugin` variable is set to undo the changes made in this file when the filetype is changed.

First, a small trick to either overwrite or extend the `b:undo_ftplugin` variable:

<!-- :Tangle(vim) <b:undo_ftplugin> -->
```vim
let b:undo_ftplugin = (exists('b:undo_ftplugin') ? b:undo_ftplugin.'|' : '')
```

And then the actual settings:

<!-- :Tangle(vim) <b:undo_ftplugin>+ -->
```vim
let b:undo_ftplugin .= 'delcommand Tangle | delcommand ExecPrevBlock'
let b:undo_ftplugin .= '| nunmap <buffer> <Plug>LitMdExecPrevBlock'
```
