" 頑張らないMRU/W

if exists("g:loaded_tinymru")
  finish
endif
let g:loaded_tinymru = 1

let s:mru = []
let s:mrw = []


function! s:init() abort
  let g:tinymru = extend({"max": 100, "mru": "", "mrw": ""}, get(g:, "tinymru", {}))
  if empty(g:tinymru.mru)
    " MRUファイルが指定されていなければoldfilesを整理して使う
    let s:mru = filter(copy(v:oldfiles), "filereadable(v:val)")
    let s:mru = map(s:mru, "resolve(fnamemodify(v:val, ':p'))")
  endif
  augroup vimrc_mru
    autocmd BufEnter,BufWritePost * call s:add("mru")
    autocmd BufWritePost * call s:add("mrw")
  augroup END
  " startup時にファイルを指定している時用
  call call(function("s:add"), ["mru"] + argv())
endfunction

function! s:read(type) abort
  let ret = s:[a:type]
  let f = g:tinymru[a:type]
  if !empty(f)
    silent! let ret = readfile(fnamemodify(f, ":p"))
  endif
  return ret
endfunction

function! s:write(type) abort
  let f = g:tinymru[a:type]
  if !empty(f)
    call writefile(s:[a:type], fnamemodify(f, ":p"))
  endif
endfunction

function! s:add(type, ...) abort
  if !empty(&buftype) || empty(@%)
    return
  endif
  let files = map(a:0 != 0 ? copy(a:000) : [bufname()], "resolve(fnamemodify(v:val, ':p'))")
  let v = s:read(a:type)
  for f in files
    let v = filter(v, "v:val !=# f")
    let v = insert(v, f)
  endfor
  let v = v[: g:tinymru.max]
  let s:[a:type] = v
  call s:write(a:type)
endfunction

function! s:open(type) abort
  enew
  setlocal buftype=nofile bufhidden=wipe noswapfile nobuflisted
  let files = s:read(a:type)
  silent keepmarks keepjumps call setline(1, files)
  nnoremap <buffer> <CR> gf
endfunction

if v:vim_did_enter
  call s:init() "lazy load
else
  autocmd VimEnter * call s:init()
endif

nnoremap <silent> <Plug>(tinymru-open-mru) :<C-u>call <SID>open("mru")<CR>
nnoremap <silent> <Plug>(tinymru-open-mrw) :<C-u>call <SID>open("mrw")<CR>
