let s:save_cpo = &cpoptions
set cpoptions&vim


" `vaffle#env` represents an environment to create Vaffle buffer.


function! vaffle#env#create(path) abort
  let env = {}
  let env.dir = vaffle#util#normalize_path(a:path)
  let env.shows_hidden_files = g:vaffle_show_hidden_files
  let env.items = []
  return env
endfunction


function! vaffle#env#create_items(env) abort
  let env_dir = fnameescape(fnamemodify(a:env.dir, ':p'))
  let paths = glob(env_dir . '*', 1, 1)
  if a:env.shows_hidden_files
    let hidden_paths = glob(env_dir . '.*', 1, 1)
    " Exclude '.' & '..'
    call filter(hidden_paths, 'match(v:val, ''\(/\|\\\)\.\.\?$'') < 0')

    call extend(paths, hidden_paths)
  end

  let items =  map(
        \ copy(paths),
        \ 'vaffle#item#create(v:val)')
  call sort(items, s:get_comparator())

  let index = 0
  for item in items
    let item.index = index
    let index += 1
  endfor

  return items
endfunction


function! s:get_comparator() abort
  if exists('*g:VaffleGetComparator')
    return g:VaffleGetComparator()
  endif
  return 'vaffle#sorter#default#compare'
endfunction


let &cpoptions = s:save_cpo
