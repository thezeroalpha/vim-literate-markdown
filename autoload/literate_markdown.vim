if exists('g:loaded_literate_markdown_autoload')
  finish
endif
let g:loaded_literate_markdown_autoload = 1

" TODO: use exceptions, refactor code

let s:codeblock_start = '^ *```[a-z]\+'
let s:codeblock_end = '^ *```$'
let s:tangle_directive = '<!-- *:Tangle '
let s:result_comment_start = '<!--\nRESULT:'
let s:result_comment_end = '^-->'

function! s:GetFilename()
  " TODO: add optional parameter to tangle only specific language
  " maybe format like: <!-- :Tangle(lang) /path/to/file -->

  let ln = search(s:tangle_directive, 'n')
  if ln ==# 0
    echoerr 'No :Tangle directive found'
    return ''
  else
    let fname = getline(ln)->matchstr(':Tangle \zs.*\ze -->')
    if fname ==# ''
      echoerr 'No filename set.'
    else
      if fname[0] !=# '/'
        let fname = expand("%:p:h") . '/' . fname
      endif
      return fnameescape(fname)
    endif
  endif
endfunction

function! s:GetBlockEnd(start)
  " Save the cursor
  let rowsave = line('.')
  let colsave = col('.')

  " search() starts from cursor
  call cursor(a:start, 1)

  " nW == don't move cursor, no wrap search
  let endblock = search(s:codeblock_end, 'nW')
  call cursor(rowsave, colsave)
  return endblock
endfunction

function! s:GetBlockContents(start, end)
  " i.e. if there's no end
  if a:end ==# 0
    let retval = []
  else
    let retval = getline(a:start+1, a:end-1)
  endif
  return retval
endfunction

function! s:GetAllCode()
  let codelines = []
  let endline = line("$")

  let curline = 1
  while curline <=# endline
    let block_pos_on_this_line = match(getline(curline), s:codeblock_start)

    if block_pos_on_this_line >=# 0
      let block_contents = s:GetBlockContents(curline, s:GetBlockEnd(curline))
      if len(block_contents) ==# 0
        echoerr 'No end of block starting on line '.curline
        return []
      else
        let nleadingspaces = matchend(block_contents[0], '^ \+')
        if nleadingspaces ==# -1
          let nleadingspaces = 0
        endif
        if len(codelines) !=# 0
          call add(codelines, '')
        endif
        call extend(codelines, map(block_contents, 'v:val['.nleadingspaces.':]'))

        let curline += len(block_contents)+2
      endif
    else
      let curline += 1
    endif
  endwhile

  return codelines
endfunction

function! s:SaveLines(lines, fname)
  if writefile(a:lines, a:fname) ==# 0
    exe 'drop '.a:fname
  else
    echoerr "Could not write to file ".a:fname
  endif
endfunction

function! s:Lang2Interpreter(lang)
  let lang = a:lang
  if exists('g:literate_markdown_interpreters')
    for [interp, langnames] in items(g:literate_markdown_interpreters)
      if index(langnames, lang) >= 0
        return interp
      endif
    endfor
  endif
  if exists('b:literate_markdown_interpreters')
    for [interp, langnames] in items(b:literate_markdown_interpreters)
      if index(langnames, lang) >= 0
        return interp
      endif
    endfor
  endif

  let lang2interp = {
        \ 'python3': ['py', 'python', 'python3'],
        \ 'python2': ['python2'],
        \ 'ruby': ['rb', 'ruby'],
        \ 'sh': ['sh'],
        \ 'bash': ['bash']
        \ }
  for [interp, langnames] in items(lang2interp)
    if index(langnames, lang) >= 0
      return interp
    endif
  endfor
  return ''
endfunction

function! s:GetBlockInterpreter(blockstart)
  " A markdown block beginning looks like this: ```lang
  let lang = getline(a:blockstart)[3:]
  if empty(lang)
    return ''
  endif

  let interp = s:Lang2Interpreter(lang)
  if empty(interp)
    echoerr 'No interpreter configured for language ' . lang
  endif

  return interp
endfunction

function! s:GetResultLine(blockend)
  let rowsave = line('.')
  let colsave = col('.')
  call cursor(a:blockend, 1)
  let nextblock = search(s:codeblock_start, 'nW')
  let linenum = search(s:result_comment_start, 'cnW', nextblock)
  call cursor(rowsave, colsave)

  if linenum == 0
    call append(a:blockend, ['', '<!--', 'RESULT:', '', '-->', ''])
    let linenum = a:blockend+2
  endif
  return linenum+1
endfunction

function! s:ClearResult(outputline)
  let rowsave = line('.')
  let colsave = col('.')
  call cursor(a:outputline, 1)
  let resultend = search(s:result_comment_end, 'nW')
  if resultend ==# 0
    echoerr 'Result block has no end'
  else
    execute a:outputline.','.resultend.'delete _'
  endif
  call cursor(rowsave, colsave)
endfunction

function! literate_markdown#ExecPreviousBlock()
  let blockstart = search(s:codeblock_start, 'nbW')
  if blockstart == 0
    echoerr 'No previous block found'
    return
  endif

  let blockend = s:GetBlockEnd(blockstart)

  if blockend == 0
    echoerr 'No end for block'
    return
  endif

  let interp = s:GetBlockInterpreter(blockstart)
  if empty(interp)
    echoerr 'No interpreter specified for block'
    return
  endif

  let block_contents = s:GetBlockContents(blockstart, blockend)

  " TODO: This here will need to be different if accounting for state
  " (try channels? jobs? hidden term? other options?)
  let result_lines = systemlist(interp, block_contents)

  let outputline = s:GetResultLine(blockend)
  call s:ClearResult(outputline)
  call append(outputline-1, ['RESULT:'] + result_lines + ['-->'])
endfunction

function! literate_markdown#Tangle()
  let fname = s:GetFilename()
  if fname ==# ''
    return
  endif
  let lines = s:GetAllCode()
  if len(lines) ># 0
    call s:SaveLines(lines, fname)
  endif
endfunction

