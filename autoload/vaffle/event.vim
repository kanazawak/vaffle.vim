let s:save_cpo = &cpoptions
set cpoptions&vim


function! s:newtralize_netrw() abort
  augroup FileExplorer
    autocmd!
  augroup END
endfunction


function! vaffle#event#on_bufenter() abort
  call s:newtralize_netrw()

  let should_init = isdirectory(expand('%'))

  if should_init
    call vaffle#init()
  else
    " Store bufnr of non-directory buffer to back to initial buffer
    call vaffle#window#store_non_vaffle_buffer(bufnr('%'))
  endif
endfunction


function! vaffle#event#on_winleave() abort
  let env = vaffle#buffer#get_env()
  let cursor_items = vaffle#get_cursor_items(env, 'n')
  if !empty(cursor_items)
    call vaffle#window#save_cursor(cursor_items[0])
  endif
endfunction


let &cpoptions = s:save_cpo
