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

  if isdirectory(path)
    execute printf('edit %s', fnameescape(path))
  else
    let dir = fnamemodify(path, ':p:h')
    execute printf('edit %s', fnameescape(dir))
    if fnamemodify(path, ':t') =~# '^\.' && !b:vaffle.shows_hidden_files
      let b:vaffle.shows_hidden_files = 1
      call vaffle#refresh()
    endif
    let item = vaffle#item#create(path)
    call vaffle#window#save_cursor(item)
    call vaffle#window#restore_cursor()
  endif
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

  if exists('g:vaffle_selection_bufnr')
      unlet g:vaffle_selection_bufnr
  endif
  if exists('g:vaffle_operation')
      unlet g:vaffle_operation
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


function! vaffle#check_selection()
  let env = vaffle#buffer#get_env()
  let sel = vaffle#get_selection()
  if sel.dir !=# env.dir && !empty(sel.basenames)
    echoerr 'Some items in other directory selected.'
    return 0
  endif
  return 1
endfunction


function! vaffle#cut(mode) abort
  let items = vaffle#get_cursor_items(a:mode)
  if empty(items)
    return
  endif

  if !vaffle#check_selection()
    return
  endif

  if len(items) == 1
    let item = items[0]

    if item.selected
      call vaffle#delete_selected()
    else
      call vaffle#select(item, 'cut')
      call vaffle#buffer#redraw_item(item)
    endif

    return
  endif

  for item in items
    call vaffle#select(item, 'cut')
    call vaffle#buffer#redraw_item(item)
  endfor
endfunction


function! vaffle#copy(mode) abort
  let items = vaffle#get_cursor_items(a:mode)
  if empty(items)
    return
  endif

  if !vaffle#check_selection()
    return
  endif

  for item in items
    call vaffle#select(item, 'copy')
    call vaffle#buffer#redraw_item(item)
  endfor
endfunction


function! vaffle#get_selection() abort
  let bufnr = get(g:, 'vaffle_selection_bufnr', 0)
  if (bufnr <= 0)
      return { 'dir': '', 'basenames': [] }
  endif

  let env = getbufvar(bufnr, 'vaffle', { 'dir': bufname(bufnr), 'items': [] })
  let items = copy(env.items)
  call filter(items, "v:val.selected")
  return { 'dir': env.dir, 'basenames': map(items, "v:val.basename") }
endfunction


function! vaffle#select(item, operation) abort
  let env = vaffle#buffer#get_env()
  let g:vaffle_selection_bufnr = bufnr()
  let g:vaffle_operation = a:operation
  let a:item.selected = v:true
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
  if empty(yn) || yn !=? 'y'
    echo 'Cancelled.'
    return
  endif

  call vaffle#file#delete(items)
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
