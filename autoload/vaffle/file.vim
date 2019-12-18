let s:save_cpo = &cpoptions
set cpoptions&vim


function! vaffle#file#delete(items) abort
  for item in a:items
    let flag = g:vaffle_force_delete
          \ ? 'rf'
          \ : (item.is_dir ? 'd' : '')
    if delete(item.path, flag) < 0
      call vaffle#util#echo_error(
            \ printf('Cannot delete file: ''%s''', item.basename))
    else
      echo printf('Deleted file: ''%s''',
            \ item.basename)
    endif
  endfor
endfunction


function! vaffle#file#mkdir(env, name) abort
  let path = vaffle#util#normalize_path(printf('%s/%s',
        \ a:env.dir,
        \ a:name))

  if filereadable(path) || isdirectory(path)
    call vaffle#util#echo_error(
          \ printf('File already exists: ''%s''', a:name))
    return
  endif

  call mkdir(path, '')

  echo printf('Created new directory: ''%s''',
        \ a:name)
endfunction


function! vaffle#file#rename(env, items, new_basenames) abort
  let cwd = a:env.dir
  let index = 0
  for item in a:items
    let new_basename = a:new_basenames[index]
    let new_path = vaffle#util#normalize_path(printf('%s/%s',
          \ cwd,
          \ new_basename))
    let index += 1

    if filereadable(new_path) || isdirectory(new_path)
      call vaffle#util#echo_error(
            \ printf('File already exists, skipped: ''%s''', new_path))
      continue
    endif

    call rename(item.path, new_path)

    echo printf('Renamed file: ''%s'' -> ''%s''',
          \ item.basename,
          \ new_basename)
  endfor
endfunction


let &cpoptions = s:save_cpo
