
if exists('g:loaded_literate_markdown')
  finish
endif
let g:loaded_literate_markdown = 1


command -buffer -bar Tangle call literate_markdown#Tangle()

command -buffer -bar ExecPrevBlock call literate_markdown#ExecPreviousBlock()


nnoremap <buffer> <Plug>LitMdExecPrevBlock :<c-u>ExecPrevBlock<CR>
nnoremap <buffer> <Plug>LitMdTangle :<c-u>Tangle<CR>


let b:undo_ftplugin = (exists('b:undo_ftplugin') ? b:undo_ftplugin.'|' : '')

let b:undo_ftplugin .= 'delcommand Tangle | delcommand ExecPrevBlock'
let b:undo_ftplugin .= '| nunmap <buffer> <Plug>LitMdExecPrevBlock'
