let s:save_cpo = &cpoptions
set cpoptions&vim


if exists('g:loaded_vaffle')
  finish
endif
let g:loaded_vaffle = 1


augroup vaffle_vim
  autocmd!
  autocmd BufEnter * call s:on_bufenter()
augroup END


function! s:on_bufenter() abort
  " Remove netrw handlers.
  autocmd! FileExplorer *

  let should_init = isdirectory(expand('%')) && search('.', 'n') == 0
  if should_init
    call vaffle#buffer#init()
  endif
endfunction


function! s:set_up_default_config()
  let config_dict = {
        \   'vaffle_force_delete': 0,
        \   'vaffle_show_hidden_files': 0,
        \   'vaffle_use_default_mappings': 1,
        \ }

  for var_name in keys(config_dict)
    let g:[var_name] = get(
          \ g:,
          \ var_name,
          \ config_dict[var_name])
  endfor
endfunction

call s:set_up_default_config()

command! -bar -nargs=? -complete=dir Vaffle call vaffle#open(fnamemodify(<f-args>, ':p'))


nnoremap <silent> <Plug>(vaffle-toggle-hidden)    :<C-u>call vaffle#toggle_hidden()<CR>
" Operations for selected items
nnoremap <silent> <Plug>(vaffle-fill-cmdline)     :<C-u>call vaffle#fill_cmdline()<CR>
nnoremap <silent> <Plug>(vaffle-rename-selected)  :<C-u>call vaffle#rename_selected()<CR>
" Operations for a item on cursor
nnoremap <silent> <Plug>(vaffle-open-current)     :<C-u>call vaffle#open_current()<CR>
" Misc
nnoremap <silent> <Plug>(vaffle-mkdir)            :<C-u>call vaffle#mkdir()<CR>
nnoremap <silent> <Plug>(vaffle-new-file)         :<C-u>call vaffle#new_file()<CR>
nnoremap <silent> <Plug>(vaffle-open-home)        :<C-u>call vaffle#open(expand("~"))<CR>
nnoremap <silent> <Plug>(vaffle-open-parent)      :<C-u>call vaffle#open_parent()<CR>
nnoremap <silent> <Plug>(vaffle-refresh)          :<C-u>call vaffle#refresh()<CR>

let &cpoptions = s:save_cpo
