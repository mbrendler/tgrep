
let s:buffer_seqno = 0

if !exists('g:tgrep_new_window_height_percent')
  let g:tgrep_new_window_height_percent = 30
endif

if !exists('g:tgrep_window_position')
  let g:tgrep_window_position = 'belowright'
endif

function! tgrep#find_tag(tagname)
  if tgrep#system("tgrep -s '^". a:tagname . "$'", 0) == 0
    if tgrep#system("tgrep -s '". a:tagname . "$'", 0) == 0
      call tgrep#system("tgrep -s '". a:tagname . "'", 1)
    endif
  endif
endfunction

function! tgrep#system(command, show_error)
  let l:content = system(a:command)
  if v:shell_error != 0
    if a:show_error
      echo "no tag found with: " . a:command
    end
    return 0
  endif
  call tgrep#open_window(l:content)
  return 1
endfunction

function! tgrep#open_window(content)
  let l:tgrep_winid = bufwinid(s:tgrep_buffer_name())
  if l:tgrep_winid != -1
    call win_gotoid(l:tgrep_winid)
  else
    execute "silent noswapfile keepalt " . g:tgrep_window_position . " new " . s:tgrep_buffer_name()
  endif
  setlocal buftype=nofile
  setlocal bufhidden=hide
  setlocal filetype=tgrep
  setlocal modifiable
  setlocal nolist
  setlocal colorcolumn=0
  setlocal nospell
  setlocal nowrap
  0,$delete
  put! =a:content
  setlocal nomodified
  setlocal nomodifiable
  if l:tgrep_winid == -1
    execute 'resize '. string(&lines * g:tgrep_new_window_height_percent / 100.0)
  endif
  nnoremap <buffer> q :bw<cr>
  nnoremap <buffer> <C-n> :call tgrep#find_next_tag()<CR>
  nnoremap <buffer> <C-p> :call tgrep#find_previous_tag()<CR>
  nnoremap <buffer> <Enter> :call tgrep#open_file('')<CR>
  nnoremap <buffer> <Space> :call tgrep#open_file('close')<CR>
  nnoremap <buffer> <C-t> :call tgrep#open_file('tab')<CR>
  1
endfunction

function! tgrep#open_file(action)
  let l:lines = getline('.', line('.') + 50)
  for lin in l:lines
    if lin =~ "^ . .*$"
      let l:edit_command = ":edit"
      if a:action == 'close'
        bw
      elseif a:action == 'tab'
        let l:edit_command = ":tabnew"
      else
        wincmd p
      endif
      execute l:edit_command . " " . substitute(lin, "^ . \\(.*\\):\\d*$", "\\1", "")
      execute ":" . str2nr(substitute(lin, "^.*:\\(\\d*\\)$", "\\1", ""))
      break
    endif
  endfor
endfunction

function! tgrep#find_next_tag()
  let l:line_number = line('.')
  let l:lines = getline(l:line_number + 1, l:line_number + 50)
  for lin in l:lines
    let l:line_number += 1
    if lin =~ '^[^ ]'
      execute ":" . l:line_number
      break
    endif
  endfor
endfunction

function! tgrep#find_previous_tag()
  let l:line_number = line('.')
  let l:lines = reverse(getline(max([l:line_number - 50, 0]), max([l:line_number - 1, 0])))
  for lin in l:lines
    let l:line_number -= 1
    if lin =~ '^[^ ]'
      execute ":" . l:line_number
      break
    endif
  endfor
endfunction

function! s:tgrep_buffer_name()
  if !exists('t:tgrep_buffer_name')
    let s:buffer_seqno += 1
    let t:tgrep_buffer_name = '__tgrep__' . s:buffer_seqno
  endif
  return t:tgrep_buffer_name
endfunction

nnoremap gü :call tgrep#find_tag(expand("<cword>"))<CR>
vnoremap gü :call tgrep#find_tag(VisualSelection())<CR>
