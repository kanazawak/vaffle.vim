let s:save_cpo = &cpoptions
set cpoptions&vim


function! vaffle#util#normalize_path(path) abort
  if a:path ==? '/'
    return '/'
  endif

  let result = fnamemodify(resolve(a:path), ':p')

  " Remove trailing path separator
  return (match(result, '\(/\|\\\)$') >= 0)
        \ ? fnamemodify(result, ':h')
        \ : result
endfunction


function! vaffle#util#echo_error(message) abort
  echohl Error
  echomsg a:message
  echohl None
endfunction


let &cpoptions = s:save_cpo
