let s:save_cpo = &cpoptions
set cpoptions&vim


function! vaffle#window#get_env() abort
  let w:vaffle = get(w:, 'vaffle', { 'cursor_items': {} })
  return w:vaffle
endfunction


function! vaffle#window#save_cursor(item) abort
  let env = vaffle#buffer#get_env()
  let win_env = vaffle#window#get_env()
  let win_env.cursor_items[env.dir] = a:item
endfunction


function! s:get_saved_cursor_lnum() abort
  let env = vaffle#buffer#get_env()
  let win_env = vaffle#window#get_env()
  let cursor_items = win_env.cursor_items
  let cursor_item = get(cursor_items, env.dir, '')
  if empty(cursor_item)
    return 1
  endif

  let items = filter(
        \ copy(env.items),
        \ 'v:val.path ==# cursor_item.path')
  if empty(items)
    return cursor_item.index + 1
  endif

  let cursor_item = items[0]
  return index(env.items, cursor_item) + 1
endfunction


function! vaffle#window#restore_cursor() abort
  let initial_lnum = s:get_saved_cursor_lnum()
  call cursor([initial_lnum, 1, 0, 1])
endfunction


let &cpoptions = s:save_cpo
