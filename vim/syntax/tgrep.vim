scriptencoding utf-8

if exists("b:current_syntax")
    finish
endif

syntax match TgrepComment ' \/\/.*$'
syntax match TgrepFunction '::\([^:( ]*\)'
syntax match TgrepSignature '(.*$'
syntax match TgrepKind '^ .\>'
" syntax match TgrepFile ' .*:'
syntax match TgrepLineNumber '\d*$'

" highlight default link TgrepClass Function
highlight default link TgrepComment Comment
highlight default link TgrepFunction Define
highlight default link TgrepSignature Special
highlight default link TgrepKind Conditional
" highlight default link TgrepFile Comment
highlight default link TgrepLineNumber Type

" highlight CursorLine cterm=reverse

let b:current_syntax = "tgrep"
