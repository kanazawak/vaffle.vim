let s:save_cpo = &cpoptions
set cpoptions&vim


function! vaffle#get_cursor_items(mode) abort
  let env = vaffle#buffer#get_env()
  let items = env.items
  if empty(items)
    return []
  endif

  let in_visual_mode = (a:mode ==? 'v')
  let indexes = in_visual_mode
        \ ? range(line('''<') - 1, line('''>') - 1)
        \ : [line('.') - 1]
  return map(
        \ copy(indexes),
        \ 'items[v:val]')
endfunction


function! vaffle#get_selected_items() abort
  let env = vaffle#buffer#get_env()
  let selected_items = filter(
        \ copy(env.items),
        \ 'v:val.selected')
  if !empty(selected_items)
    return selected_items
  endif

  return vaffle#get_cursor_items('n')
endfunction


function! vaffle#start(...) abort
  let path = get(a:000, 0, '')
  if empty(path)
    let path = getcwd()
  endif

  execute printf('edit %s', fnameescape(path))
endfunction


function! vaffle#init() abort
  try
    call vaffle#buffer#init()
    call vaffle#window#init()
  catch /:E37:/
    call vaffle#util#echo_error(
          \ 'E37: No write since last change')
    return
  endtry
endfunction


function! vaffle#refresh() abort
  let cursor_items = vaffle#get_cursor_items('n')
  if !empty(cursor_items)
    call vaffle#window#save_cursor(cursor_items[0])
  endif

  if exists('g:vaffle_selection')
    unlet g:vaffle_selection
  endif

  let env = vaffle#buffer#get_env()
  let env.items = vaffle#env#create_items(env)

  call vaffle#buffer#redraw()
endfunction


function! vaffle#open_current(open_mode) abort
  let item = get(
        \ vaffle#get_cursor_items('n'),
        \ 0,
        \ {})
  if empty(item)
    return
  endif

  call vaffle#window#save_cursor(item)

  call vaffle#file#open([item], a:open_mode)
endfunction


function! vaffle#open_selected() abort
  let items = vaffle#get_selected_items()
  if empty(items)
    return
  endif

  call vaffle#window#save_cursor(items[0])

  call vaffle#file#open(items, '')
endfunction


function! vaffle#open(path) abort
  let env = vaffle#buffer#get_env()
  let env_dir = env.dir

  let cursor_items = vaffle#get_cursor_items('n')
  if !empty(cursor_items)
    call vaffle#window#save_cursor(cursor_items[0])
  endif

  let new_dir = isdirectory(expand(a:path)) ?
        \ expand(a:path) :
        \ fnamemodify(expand(a:path), ':h')
  let new_item = vaffle#item#create(new_dir)
  call vaffle#file#open([new_item], '')

  " Move cursor to previous current directory
  let prev_dir_item =vaffle#item#create(env_dir)
  call vaffle#window#save_cursor(prev_dir_item)
  call vaffle#window#restore_cursor()
endfunction


function! vaffle#open_parent() abort
  let env = vaffle#buffer#get_env()
  let parent_dir = fnameescape(fnamemodify(env.dir, ':h'))
  if parent_dir !=# env.dir
    call vaffle#open(parent_dir)
  endif
endfunction


function! vaffle#toggle_current(mode) abort
  let items = vaffle#get_cursor_items(a:mode)
  if empty(items)
    return
  endif

  let env = vaffle#buffer#get_env()
  let sel = vaffle#get_selection()
  if sel.dir !=# env.dir && !empty(sel.dict)
    echoerr 'some items in other directory selected'
    return
  endif

  if len(items) == 1
    let item = items[0]
    call vaffle#set_selected(item, !item.selected)

    call vaffle#buffer#redraw_item(item)

    " Move cursor to next item
    normal! j0

    return
  endif

  let selected = items[0].selected ? 0 : 1
  for item in items
    call vaffle#set_selected(item, selected)
    call vaffle#buffer#redraw_item(item)
  endfor
endfunction


function! vaffle#toggle_all() abort
  let env = vaffle#buffer#get_env()
  let sel = vaffle#get_selection()

  let items = env.items
  if empty(items)
    return
  endif

  if sel.dir !=# env.dir && !empty(sel.dict)
    echoerr 'some items in other directory selected'
    return
  endif

  let selected = items[0].selected ? 0 : 1

  for item in items
    call vaffle#set_selected(item, selected)
  endfor

  call vaffle#buffer#redraw()
endfunction


function! vaffle#get_selection() abort
  return get(g:, 'vaffle_selection', { 'dir': '', 'dict': {} })
endfunction

function! vaffle#set_selected(item, selected) abort
  let env = vaffle#buffer#get_env()
  let sel = vaffle#get_selection()
  let sel.dir = env.dir

  if a:selected == 0
    if has_key(sel.dict, a:item.basename)
      call remove(sel.dict, a:item.basename)
    endif
  else
    let sel.dict[a:item.basename] = 1
  endif
  let a:item.selected = a:selected

  let g:vaffle_selection = sel
endfunction


function! vaffle#quit() abort
  " Try restoring previous buffer
  let bufnr = vaffle#window#get_env().non_vaffle_bufnr
  if bufexists(bufnr)
    execute printf('buffer! %d', bufnr)
    return
  endif

  enew
endfunction


function! vaffle#delete_selected() abort
  let items = vaffle#get_selected_items()
  if empty(items)
    return
  endif

  let message = (len(items) == 1)
        \ ? printf('Delete ''%s'' (y/N)? ', items[0].basename)
        \ : printf('Delete %d selected files (y/N)? ', len(items))
  let yn = input(message)
  echo "\n"
  if empty(yn) || yn ==? 'n'
    echo 'Cancelled.'
    return
  endif

  call vaffle#file#delete(items)
  call vaffle#refresh()
endfunction


function! vaffle#move_selected() abort
  let items = vaffle#get_selected_items()
  if empty(items)
    return
  endif

  let message = (len(items) == 1)
        \ ? printf('Move ''%s'' to: ', items[0].basename)
        \ : printf('Move %d selected files to: ', len(items))
  let dst_name = input(message, '', 'dir')
  echo "\n"
  if empty(dst_name)
    echo 'Cancelled.'
    return
  endif

  call vaffle#file#move(
        \ vaffle#buffer#get_env(),
        \ items, dst_name)
  call vaffle#refresh()
endfunction


function! vaffle#mkdir() abort
  let name = input('New directory name: ')
  echo "\n"
  if empty(name)
    echo 'Cancelled.'
    return
  endif

  call vaffle#file#mkdir(
        \ vaffle#buffer#get_env(),
        \ name)
  call vaffle#refresh()
endfunction


function! vaffle#new_file() abort
  let name = input('New file name: ')
  echo "\n"
  if empty(name)
    echo 'Cancelled.'
    return
  endif

  call vaffle#file#edit(
        \ vaffle#buffer#get_env(),
        \ name)
endfunction


function! vaffle#rename_selected() abort
  let items = vaffle#get_selected_items()
  if empty(items)
    return
  endif

  if len(items) == 1
    let def_name = vaffle#util#get_last_component(
          \ items[0].path, items[0].is_dir)
    let new_basename = input('New file name: ', def_name)
    echo "\n"
    if empty(new_basename)
      echo 'Cancelled.'
      return
    endif

    call vaffle#file#rename(
          \ vaffle#buffer#get_env(),
          \ items, [new_basename])
    call vaffle#refresh()
    return
  endif

  call vaffle#rename_buffer#new(items)
endfunction


function! vaffle#toggle_hidden() abort
  let env = vaffle#buffer#get_env()
  let env.shows_hidden_files = !env.shows_hidden_files

  let item = get(
        \ vaffle#get_cursor_items('n'),
        \ 0,
        \ {})
  if !empty(item)
    call vaffle#window#save_cursor(item)
  endif

  let env.items = vaffle#env#create_items(env)

  call vaffle#buffer#redraw()
endfunction


function! vaffle#fill_cmdline() abort
  let items = vaffle#get_selected_items()
  if empty(items)
    return
  endif

  let paths = map(items, 'fnameescape(v:val.path)')

  let cmdline =printf(
        \ ": %s\<Home>",
        \ join(paths, ' '))
  call feedkeys(cmdline)
endfunction


let &cpoptions = s:save_cpo
