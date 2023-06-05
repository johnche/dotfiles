" Is this needed anymore?
"let g:ale_fixers['javascript'] = ['eslint']
"let g:ale_fixers['typescript'] = ['eslint']

let g:python_recommended_style=0
let g:prettier#autoformat_config_files = ['prettier.config.cjs']
let g:prettier#autoformat_config_present = 1
let g:prettier#config#config_precedence = 'prefer-file'

"au BufRead,BufNewFile *.tsx set filetype=typescript
au BufRead,BufNewFile *.tsx set filetype=typescriptreact
au BufRead,BufNewFile *.jsx set filetype=javascriptreact
