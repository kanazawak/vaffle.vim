let s:save_cpo = &cpoptions
set cpoptions&vim

function! s:map_default(mode, lhs, vaffle_command, sp_args) abort
  let rhs = maparg(a:lhs, a:mode)
  if !empty(rhs)
    return
  endif

  execute printf('%smap %s %s <Plug>(vaffle-%s)',
        \ a:mode,
        \ a:sp_args,
        \ a:lhs,
        \ a:vaffle_command)
endfunction

function! s:set_up_default_mappings() abort
  call s:map_default('n', '.',       'toggle-hidden',    '<buffer> <silent>')
  " Operations for selected items
  call s:map_default('n', 'x',       'fill-cmdline',     '<buffer> <silent>')
  call s:map_default('n', 'r',       'rename-selected',  '<buffer> <silent>')
  " Operations for a item on cursor
  call s:map_default('n', 'l',       'open-current',     '<buffer> <silent>')
  call s:map_default('n', 't',       'open-current-tab', '<buffer> <nowait> <silent>')
  " Misc
  call s:map_default('n', 'o',       'mkdir',            '<buffer> <silent>')
  call s:map_default('n', 'i',       'new-file',         '<buffer> <silent>')
  call s:map_default('n', '~',       'open-home',        '<buffer> <silent>')
  call s:map_default('n', 'h',       'open-parent',      '<buffer> <silent>')
  call s:map_default('n', 'R',       'refresh',          '<buffer> <silent>')

  " Removed <Esc> mappings because they cause a conflict with arrow keys in terminal...
  " In terminal, arrow keys are simulated as follows:
  "   <Up>:    ^[OA
  "   <Down>:  ^[OB
  "   <Right>: ^[OC
  "   <Left>:  ^[OD
  " These keys contain ^[ (equivalent to <Esc>), so they cause quitting a Vaffle buffer.
  " nmap <buffer> <silent> <Esc>      <Plug>(vaffle-quit)
endfunction


function! s:create_line_from_item(item) abort
  if exists('*g:VaffleCreateLineFromItem')
    return g:VaffleCreateLineFromItem(a:item)
  end
  return printf('%s %s',
        \ a:item.selected ? '*' : ' ',
        \ a:item.basename . (a:item.is_dir ? '/' : ''))
endfunction


function! vaffle#buffer#init() abort
  if g:vaffle_use_default_mappings
    call s:set_up_default_mappings()
  endif

  setlocal nobuflisted
  setlocal bufhidden=hide
  setlocal buftype=nowrite
  setlocal matchpairs=
  setlocal noswapfile
  setlocal nowrap
  setlocal filetype=vaffle

  let env = vaffle#buffer#get_env()
  let env.items = vaffle#env#create_items(env)
  let env.max_labeldispwidth = 0
  for item in env.items
    let env.max_labeldispwidth = max([
                \ env.max_labeldispwidth,
                \ strdisplaywidth(item.label)])
  endfor

  call vaffle#buffer#redraw()
endfunction


function! vaffle#buffer#redraw() abort
  setlocal modifiable

  " Clear buffer before drawing items
  if search('.', 'n') > 0
    silent keepjumps %s/.//g
  endif

  let env = vaffle#buffer#get_env()
  let items = env.items
  if !empty(items)
    let lnum = 1
    for item in items
      let line = s:create_line_from_item(item)
      call setline(lnum, line)
      let lnum += 1
    endfor
  else
    call setline(1, '  (no items)')
  endif

  silent keepjumps v/\S/d

  setlocal nomodifiable
  setlocal nomodified

  call vaffle#window#restore_cursor()
endfunction


function! vaffle#buffer#redraw_item(item) abort
  setlocal modifiable

  let lnum = a:item.index + 1
  call setline(lnum, s:create_line_from_item(a:item))

  setlocal nomodifiable
  setlocal nomodified
endfunction


function! vaffle#buffer#get_env() abort
  let b:vaffle = get(b:, 'vaffle', vaffle#env#create(expand('%')))
  return b:vaffle
endfunction


let &cpoptions = s:save_cpo
