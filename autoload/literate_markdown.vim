if exists('g:loaded_literate_markdown_autoload')
  finish
endif
let g:loaded_literate_markdown_autoload = 1

" TODO: use exceptions, refactor code

let s:codeblock_start = '^ *```[a-z]\+'
let s:codeblock_end = '^ *```$'
let s:tangle_directive = '<!-- *:Tangle'
let s:result_comment_start = '<!--\nRESULT:'
let s:result_comment_end = '^-->'
let s:ALL_INTERP = ''

" returns [interpreter, filename]
function! s:ParseTangleDirective(ln)
  let theline = getline(a:ln)->matchlist(':Tangle\(([a-zA-Z0-9]*)\)* \(.*\) -->')[0:2]
  if empty(theline)
    echoerr 'No filename in Tangle directive on line ' .. a:ln
    return []
  endif
  let [_, interp, fname] = theline
  if fname[0] !=# '/'
    let fname = expand("%:p:h") . '/' . fname
  endif
  return [s:Lang2Interpreter(interp[1:-2]), fnameescape(fname)]
endfunction

" returns end line of a code block
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

" returns [contents of a code block]
function! s:GetBlockContents(start, end)
  " i.e. if there's no end
  if a:end ==# 0
    let retval = []
  else
    let retval = getline(a:start+1, a:end-1)
  endif
  return retval
endfunction

" returns all code in the current buffer in the form
" {'interpreter': {'file1': [line1, line2], 'file2': [line1, line2]}...}
function! s:GetAllCode()
  let codelines = {}

  " The current files set for various interpreters
  let curfiles = {}

  " The interpreter specified in the most recent Tangle directive
  let last_set_interp = s:ALL_INTERP

  let curline = 1
  let endline = line("$")

  " Loop through lines
  while curline <=# endline
    " If this line has a Tangle directive
    if match(getline(curline), s:tangle_directive) >=# 0

      " Try to parse the directive
      let parsedline = s:ParseTangleDirective(curline)
      if empty(parsedline)
        return {}
      endif
      let [last_set_interp, curfile] = parsedline

      " Change the current file for the interpreter
      let curfiles[last_set_interp] = curfile

      " If the interpreter has already been specified
      if has_key(codelines, last_set_interp)
        " If the interpreter does not yet have any lines for this file
        if !has_key(codelines[last_set_interp], curfile)
          " Add it
          let codelines[last_set_interp][curfile] = []
        endif
        " If the interpreter already has lines for the file, don't do anything
      " If the interpreter itself hasn't been specified yet
      else
        " Add it
        let codelines[last_set_interp] = {curfile: []}
      endif
      " Go to next line
      let curline += 1
    else
      " Find a block on this line
      let block_pos_on_this_line = match(getline(curline), s:codeblock_start)

      " If there's a block, process it
      if block_pos_on_this_line >=# 0
        " Get the contents of this block
        let block_contents = s:GetBlockContents(curline, s:GetBlockEnd(curline))

        if len(block_contents) ==# 0
          echoerr 'No end of block starting on line '.curline
          return {}
        endif

        " Find out the amount of leading indentation (using the first line)
        let nleadingspaces = matchend(block_contents[0], '^ \+')
        if nleadingspaces ==# -1
          let nleadingspaces = 0
        endif

        " Get the interpreter for this block
        let block_interp = s:GetBlockInterpreter(curline)
        if !empty(block_interp)
          " Allow overriding all interpreters to a 'general' file:
          " If the last Tangle directive didn't have an interpreter, direct
          " all blocks to that file
          if last_set_interp ==# ""
            " Get the current file for 'all interpreters'
            let curfile = curfiles[last_set_interp]
            let curinterp = s:ALL_INTERP
          " If the last Tangle directive specified an interpreter
          else
            " If the interpreter was specified in a Tangle directive, use its
            " current file
            if has_key(codelines, block_interp)
              let curfile = curfiles[block_interp]
              let curinterp = block_interp
            " Otherwise, use the 'general' file if specified
            elseif has_key(codelines, s:ALL_INTERP)
              let curfile = curfiles[s:ALL_INTERP]
              let curinterp = s:ALL_INTERP
            endif
          endif

          " Add the lines to the current file to the current interpreter,
          " stripping leading indentation and appending a newline
          if exists('curinterp')
            call extend(codelines[curinterp][curfile], (map(block_contents, 'v:val['.nleadingspaces.':]')+['']))
          endif
        endif

        " Skip to after the block
        let curline += len(block_contents)+2
      " Otherwise, go to the next line
      else
        let curline += 1
      endif
    endif
  endwhile

  return codelines
endfunction

" Write [lines] to fname and open it in a split
function! s:SaveLines(lines, fname)
  if writefile(a:lines, a:fname) ==# 0
    exe 'split '.a:fname
  else
    echoerr "Could not write to file ".a:fname
  endif
endfunction

" Returns the interpreter name for a programming language
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

" Gets the interpreter name for a code block
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
  " Get all of the code blocks in the file
  let lines = s:GetAllCode()

  " If there's any, tangle it
  if len(lines) ># 0
    " Merge lines from all interpreters into the files
    let all_interps_combined = {}
    for fname_and_lines in lines->values()
      for [fname, flines] in fname_and_lines->items()
        if all_interps_combined->has_key(fname)
          call extend(all_interps_combined[fname], flines)
        else
          let all_interps_combined[fname] = flines
        endif
      endfor
    endfor

    " Loop through the filenames and corresponding code
    for [fname, flines] in items(all_interps_combined)
      " Write the code to the respective file
      call s:SaveLines(flines, fname)
    endfor
  endif
endfunction

