
if exists('g:loaded_literate_markdown_autoload')
  finish
endif
let g:loaded_literate_markdown_autoload = 1


let s:codeblock_start = '^ *```[a-z]\+'
let s:codeblock_end = '^ *```$'

let s:tangle_directive = '^\s*<!-- *:Tangle'

let s:ALL_INTERP = ''

let s:result_comment_start = '<!--\nRESULT:'
let s:result_comment_end = '^-->'


" Write [lines] to fname and open it in a split
function! s:SaveLines(lines, fname)
  if writefile(a:lines, a:fname) ==# 0
    if !exists('g:literate_markdown_no_open_tangled_files')
        exe 'split '.a:fname
    endif
  else
    echoerr "Could not write to file ".a:fname
  endif
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
        \ 'bash': ['bash'],
        \ 'cat /tmp/program.c && gcc /tmp/program.c -o /tmp/program && /tmp/program': ['c'],
        \ }
  for [interp, langnames] in items(lang2interp)
    if index(langnames, lang) >= 0
      return interp
    endif
  endfor
  return ''
endfunction

function! s:GetBlockLang(blockstart)
  let lang = getline(a:blockstart)[3:]
  return lang
endfunction

" Gets the interpreter name for a code block
function! s:GetBlockInterpreter(blockstart)
  " A markdown block beginning looks like this: ```lang
  let lang = s:GetBlockLang(a:blockstart)
  if empty(lang)
    return ''
  endif

  let interp = s:Lang2Interpreter(lang)

  if empty(interp)
    let interp = lang
  endif
  return interp
endfunction



function! s:ParseTangleDirective(ln)
  let theline = getline(a:ln)->matchlist('\v^\s*\<!-- :Tangle(\([a-zA-Z0-9]*\))* (\<\^?\>)? ?(\<[^>]+\>\+?)? ?(.*)? --\>')[1:4]
  if empty(theline)
    throw 'Cannot parse tangle directive on line ' .. a:ln
  endif
  let [interp, should_expand_macros, macro_group, fname] = theline

  if empty(should_expand_macros) && empty(macro_group) && empty(fname)
    throw 'No filename in tangle directive on line ' .. a:ln
  endif

  if !empty(fname)
    if fname[0] !=# '/'
      let fname = expand("%:p:h") . '/' . fname
    endif
    let fname = fnameescape(fname)
  endif
  let theinterp = s:Lang2Interpreter(interp[1:-2])
  if empty(theinterp)
    let theinterp = interp[1:-2]
  endif
  return [theinterp, should_expand_macros, macro_group, fnameescape(fname)]
endfunction

function! s:AddBlock(interps_files, block, block_start_line, last_set_interp, curfiles)
  let interps_files = a:interps_files

  if type(a:block) ==# v:t_dict
    let block_contents = a:block['contents']
  else
    let block_contents = a:block
  endif

  " Find out the amount of leading indentation (using the first line)
  " TODO: this should be the least indented line
  let nleadingspaces = matchend(block_contents[0], '^ \+')
  if nleadingspaces ==# -1
    let nleadingspaces = 0
  endif

  " Get the interpreter for this block
  let block_interp = s:GetBlockInterpreter(a:block_start_line)
  if empty(block_interp)
    let block_interp = s:GetBlockLang(a:block_start_line)
  endif
  if !empty(block_interp)
    " Allow overriding all interpreters to a 'general' file:
    " If the last Tangle directive didn't have an interpreter, direct
    " all blocks to that file
    if a:last_set_interp ==# s:ALL_INTERP && has_key(a:curfiles, s:ALL_INTERP)
      " Get the current file for 'all interpreters'
      let curfile = a:curfiles[s:ALL_INTERP]
      let curinterp = s:ALL_INTERP
      " If the last Tangle directive specified an interpreter
    else
      " If the interpreter was specified in a Tangle directive, use its
      " current file
      if has_key(interps_files, block_interp)
        let curfile = a:curfiles[block_interp]
        let curinterp = block_interp
        " Otherwise, use the 'general' file if specified
      elseif has_key(interps_files, s:ALL_INTERP)
        let curfile = a:curfiles[s:ALL_INTERP]
        let curinterp = s:ALL_INTERP
      endif
    endif

    " Add the lines to the current file to the current interpreter,
    " stripping leading indentation and appending a newline
    if exists('curinterp')
      if type(a:block) ==# v:t_dict
        call add(interps_files[curinterp][curfile], {'expand': a:block['expand'], 'contents': (map(block_contents, 'v:val['.nleadingspaces.':]')+[''])})
      else
        call extend(interps_files[curinterp][curfile], (map(block_contents, 'v:val['.nleadingspaces.':]')+['']))
      endif
    endif
  endif

  return interps_files
endfunction

function! s:ProcessMacroExpansions(lines, macros)
  let final_lines = {}
  for [interp, fnames] in a:lines->items()
    if has_key(a:macros, interp)
      for [fname, flines] in fnames->items()
        if has_key(a:macros[interp], fname)
          if !has_key(a:macros[interp][fname], 'toplevel')
            throw "Macros exist, but no top-level structure defined for file " .. fname
          endif

          let toplevel = a:macros[interp][fname]['toplevel']
          let lines_here = []
          for line in toplevel
            if line->trim()->match('<<[^>]\+>>') >=# 0
              call extend(lines_here, s:ExpandMacro(a:macros, interp, fname, line))
            else
              call add(lines_here, line)
            endif
          endfor

          if !has_key(final_lines, interp)
            let final_lines[interp] = {fname: lines_here}
          else
            let final_lines[interp][fname] = lines_here
          endif
        else
          if !has_key(final_lines, interp)
            let final_lines[interp] = {fname: a:lines[interp][fname]}
          else
            let final_lines[interp][fname] = a:lines[interp][fname]
          endif
        endif
      endfor
    else
      let final_lines[interp] = a:lines[interp]
    endif
  endfor
  return final_lines
endfunction

function! s:ExpandMacro(macros, interp, fname, line)
  let nleadingspaces = matchend(a:line, '^ \+')
  if nleadingspaces ==# -1
    let nleadingspaces = 0
  endif

  let macro_tag = trim(a:line)[2:-3]
  let expanded = []
  if !has_key(a:macros[a:interp][a:fname]['macros'], macro_tag)
    throw "Macro " .. macro_tag .. " not defined for file " .. a:fname
  endif

  let expansion = a:macros[a:interp][a:fname]['macros'][macro_tag]
  if type(expansion) ==# v:t_dict
    let expansion = [expansion]
  endif
  for expanded_line in expansion
    if type(expanded_line) ==# v:t_dict && expanded_line['expand']
      for l in expanded_line['contents']
        if l->trim()->match('<<[^>]\+>>') >=# 0
          call extend(expanded, s:ExpandMacro(a:macros, a:interp, a:fname, repeat(" ", nleadingspaces)..l))
        else
          call add(expanded, repeat(" ", nleadingspaces)..l)
        endif
      endfor
    else
      call add(expanded, repeat(" ", nleadingspaces)..expanded_line)
    endif
  endfor

  return expanded
endfunction

function! s:GetAllCode()
  
  " The current files set for various interpreters
  let curfiles = {}
  
  " Finalized code, by interpreter and file
  let interps_files = {}
  
  let last_set_interp = s:ALL_INTERP
  
  let macros = {}

  let curline = 1
  let endline = line("$")

  " Loop through lines
  while curline <=# endline
    
    " If this line has a Tangle directive
    if match(getline(curline), s:tangle_directive) >=# 0
      
      " Try to parse the directive
      let parsedline = s:ParseTangleDirective(curline)
      let [last_set_interp, should_expand_macros, macro_group, curfile] = parsedline
      
      " Process file and interpreter declaration
      if !empty(curfile)
        " Change the current file for the interpreter
        let curfiles[last_set_interp] = curfile
      
        " Process interpreter declaration
        " If the interpreter has already been specified
        if has_key(interps_files, last_set_interp)
          " If the interpreter does not yet have any lines for this file
          if !has_key(interps_files[last_set_interp], curfile)
            " Add it
            let interps_files[last_set_interp][curfile] = []
          endif
          " If the interpreter already has lines for the file, don't do anything
          " If the interpreter itself hasn't been specified yet
        else
          " Add it
          let interps_files[last_set_interp] = {curfile: []}
        endif
      endif
      
      if !empty(should_expand_macros) || !empty(macro_group)
        if getline(curline+1)->match(s:codeblock_start) ==# -1
          throw "Tangle directive specifies macros on line " .. curline .. " but no code block follows."
        endif
        let block_contents = s:GetBlockContents(curline+1, s:GetBlockEnd(curline+1))
        let block_interp = s:GetBlockInterpreter(curline+1)
      
        if empty(block_interp)
          throw ("Macro expansion defined, but no block language set on line " .. (curline+1))
        endif
      
        " If the last set interpreter was generic, it should override all blocks
        if last_set_interp ==# s:ALL_INTERP
          let block_interp = s:ALL_INTERP
        endif
      
        
        " Process macro expansion
        " Top-level macros
        if !empty(should_expand_macros) && stridx(should_expand_macros, "^") >=# 0
          if !empty(macro_group)
            throw "Top-level macro block on line "  .. curline .. " cannot also belong to macro group."
          endif
        
          if has_key(curfiles, block_interp)
            let curfile = curfiles[block_interp]
          elseif has_key(curfiles, s:ALL_INTERP)
            let curfile = curfiles[s:ALL_INTERP]
          else
            throw "No current file set for block on line " .. curline+1
          endif
        
          if !has_key(macros, block_interp)
            let macros[block_interp] = {}
          endif
          if !has_key(macros[block_interp], curfile)
            let macros[block_interp][curfile] = {}
          endif
        
          if has_key(macros[block_interp][curfile], 'toplevel')
            throw "Duplicate top-level macro definition on line " .. curline
          endif
        
          " Add the current block as a top-level macro
          let macros[block_interp][curfile]['toplevel'] = block_contents
          " For regular macro expansion, just add the block
        endif
        
        " Potentially save block as macro
        if !empty(macro_group)
          " If extending an existing macro
          if !empty(should_expand_macros)
            let to_add = [{'expand': 1, 'contents': ['']+(block_contents) }]
          else
            let to_add = ['']+block_contents
          endif
        
          " If adding to an existing macro
          if stridx(macro_group, "+") ==# len(macro_group)-1
            let macro_tag = macro_group[1:-3]
            if empty(macro_tag)
              throw "Macro tag on line " .. curline .. " cannot be empty"
            endif
        
            if has_key(curfiles, block_interp)
              let curfile = curfiles[block_interp]
            elseif has_key(curfiles, s:ALL_INTERP)
              let curfile = curfiles[s:ALL_INTERP]
            else
              throw "No current file set for block on line " .. curline+1
            endif
        
            if !has_key(macros, block_interp)
                  \ || !has_key(macros[block_interp], curfile)
                  \ || !has_key(macros[block_interp][curfile], 'macros')
                  \ || !has_key(macros[block_interp][curfile]['macros'], macro_tag)
              throw "Requested to extend macro <" .. macro_tag .. "> on line " .. curline .. ", but it's not yet defined"
            endif
        
            if type(to_add) ==# v:t_dict
              call add(macros[block_interp][curfile]['macros'][macro_tag], to_add)
            else
              call extend(macros[block_interp][curfile]['macros'][macro_tag], to_add)
            endif
        
          " If defining a new macro
          else
            if has_key(curfiles, block_interp)
              let curfile = curfiles[block_interp]
            elseif has_key(curfiles, s:ALL_INTERP)
              let curfile = curfiles[s:ALL_INTERP]
            else
              throw "No current file set for block on line " .. curline+1
            endif
        
            let macro_tag = macro_group[1:-2]
            if empty(macro_tag)
              throw "Macro tag on line " .. curline .. " cannot be empty"
            endif
        
            if !has_key(macros, block_interp)
              let macros[block_interp] = {}
            endif
            if !has_key(macros[block_interp], curfile)
              let macros[block_interp][curfile] = {}
            endif
        
            if has_key(macros[block_interp][curfile], 'macros') && has_key(macros[block_interp][curfile]['macros'], macro_tag)
              throw "Duplicate definition of macro tag <" .. macro_tag .. "> on line " .. curline
            endif
        
            if has_key(macros[block_interp][curfile], 'macros')
              let macros[block_interp][curfile]['macros'][macro_tag] = to_add
            else
              let macros[block_interp][curfile]['macros'] = {macro_tag: to_add}
            endif
          endif
        endif
      
        " When processing macros, we process the block also, so move the
        " cursor after it
        let curline += len(block_contents)+2
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
          throw 'No end of block starting on line '.curline
        endif
        
        let interps_files = s:AddBlock(interps_files, block_contents, curline, last_set_interp, curfiles)
        
        " Skip to after the block
        let curline += len(block_contents)+2
    
      " Otherwise, go to the next line
      else
        let curline += 1
      endif
    endif
  endwhile

  
  if exists('g:literate_markdown_debug')
    echomsg interps_files
    echomsg macros
  endif
  return [interps_files, macros]
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
    throw 'Result block has no end'
  else
    execute a:outputline.','.resultend.'delete _'
  endif
  call cursor(rowsave, colsave)
endfunction


function! literate_markdown#Tangle()
  " Get all of the code blocks in the file
  try
    let [lines, macros] = s:GetAllCode()

    if !empty(macros)
      let lines = s:ProcessMacroExpansions(lines, macros)
    endif


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
  catch
    echohl Error
    echomsg "Error: " .. v:exception .. " (from " .. v:throwpoint .. ")"
    echohl None
  endtry
endfunction

function! literate_markdown#ExecPreviousBlock()
  let blockstart = search(s:codeblock_start, 'nbW')
  if blockstart == 0
    throw 'No previous block found'
  endif

  let blockend = s:GetBlockEnd(blockstart)

  if blockend == 0
    throw 'No end for block'
  endif

  let interp = s:GetBlockInterpreter(blockstart)
  if empty(interp)
    throw 'No interpreter specified for block'
  endif

  let block_contents = s:GetBlockContents(blockstart, blockend)

  " TODO: This here will need to be different if accounting for state
  " (try channels? jobs? hidden term? other options?)
  let result_lines = systemlist(interp, block_contents)

  let outputline = s:GetResultLine(blockend)
  call s:ClearResult(outputline)
  call append(outputline-1, ['RESULT:'] + result_lines + ['-->'])
endfunction
