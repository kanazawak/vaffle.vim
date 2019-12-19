let s:save_cpo = &cpoptions
set cpoptions&vim


function! vaffle#item#create(path) abort
  let item = {}
  let item.index = -1
  let item.path = vaffle#util#normalize_path(a:path)
  let item.is_dir = isdirectory(a:path)
  let item.is_link = (item.path !=# a:path)
  let item.basename = item.is_dir
        \ ? fnamemodify(a:path, ':t')
        \ : fnamemodify(a:path, ':p:t')
  let item.ftime = getftime(item.path)
  let item.size = item.is_dir
        \ ? len(glob(item.path . '/*', 0, 1, 1))
        \   + len(glob(item.path . '/.*', 0, 1, 1)) - 2
        \ : getfsize(item.path)
  let item.label = item.basename
  if item.is_link
      let item.label = item.label . ' -> ' . item.path
  endif

  let sel = vaffle#get_selection()
  if sel.dir ==# expand('%:p:h') && match(sel.basenames, item.basename) >= 0
      let item.selected = 1
  else
      let item.selected = 0
  endif

  return item
endfunction

let &cpoptions = s:save_cpo
