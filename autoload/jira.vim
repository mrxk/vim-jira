if exists('g:loaded_jira')
  finish
endif
let g:loaded_jira = 1

let s:jira_tab = 0
let s:jira_buf = 0
let s:history = []
let s:breadcrumbs = []

function! s:open_window(type)
    let found = 0
    " Find the tab with our buffer in it
    for t in range(tabpagenr('$'))
        for b in tabpagebuflist(t+1)
            if b == s:jira_buf
                let found = 1
                let s:jira_tab = t+1
            endif
        endfor
    endfor
    if found == 1
        "Found it.  Now see if we need to move to it.
        if winbufnr(0) != s:jira_buf
            execute 'normal!' s:jira_tab.'gt'
            let winnr = bufwinnr(s:jira_buf)
            execute winnr.'wincmd w'
        endif
        "Else present and selected.
    else
        "Did not find it.  Need to create it and set it up.
        tab new
        let s:jira_tab = tabpagenr()
        let s:jira_buf = winbufnr(0)
        call s:syntax()
        call s:assign_name()
        " Use the whole file for syntax
        syntax sync fromstart
        " Make this a temporary buffer
        setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile wrap
        " Handle lists correctly
        setlocal formatoptions=tqn
        setlocal formatlistpat=^\\s*[0-9#\\-*+]\\+[\\]:.)}\\t\ ]\\s*
        setlocal comments=
        " Handle issue ids as a single keyword
        setlocal iskeyword+=-
    endif
    call s:keys(a:type)
    setlocal modifiable
    silent %d
    call append(0, "Loading jira...")
    setlocal nomodifiable
    if a:type == 'search' || a:type == 'history'
        setlocal cursorline
    else
        setlocal nocursorline
    endif
    redraw
endfunction

function! s:assign_name()
  " Assign buffer name
  let prefix = '[Jira]'
  let name   = prefix
  let idx    = 2
  while bufexists(name)
    let name = printf('%s (%s)', prefix, idx)
    let idx = idx + 1
  endwhile
  silent! execute 'f' fnameescape(name)
endfunction

function! s:syntax()
    syntax clear
    syntax match jiraIssue /[A-Z][A-Z]*-\d\d*/
    syntax match jiraTitle /^Summary$\|^Description$\|^Comments$\|^Details$/
    syntax match jiraUser /\[\~.\{-}\]/
    syntax region jiraCode start=/{code}/ skip=/\v\\./ end=/{code}/
    syntax region jiraCode start=/{code:.\{-}}/ skip=/\v\\./ end=/{code}/
    syntax region jiraCode start=/{quote}/ skip=/\v\\./ end=/{quote}/
    syntax region jiraCode start=/{noformat}/ skip=/\v\\./ end=/{noformat}/
    syntax match jiraCommentAuthor /^[A-Za-z \(\)]*\w: \d\{4}-\d\{2}-\d\{2}T\d\{2}:\d\{2}:\d\{2}\.\d\{3}-\d*[ (edited)]*$/
    syntax match jiraLink /https*:\/\/[A-Za-z\.\/0-9\-\:_\<\> ?=&+%]*/
    syntax match jiraBold /\(\s\|^\)\*.\{-}\*\(\s\|$\)/ contains=jiraBoldStart,jiraBoldEnd containedin=ALL
    syntax match jiraItalic /\(\s\|^\)_.\{-}_\(\s\|$\)/ contains=jiraItalicStart,jiraItalicEnd containedin=ALL
    syntax match jiraUnderline /\(\s\|^\)+.\{-}+\(\s\|$\)/ contains=jiraUnderlineStart,jiraUnderlineEnd containedin=ALL
    syntax match jiraCodeInline /{{\_.\{-}}}/ contains=jiraCodeInlineStart,jiraCodeInlineEnd containedin=ALL
    if v:version >= 703
        syntax match jiraBoldStart contained /\(\s\|^\)\*/ conceal
        syntax match jiraBoldEnd contained /\*\(\s\|$\)/ cchar=  conceal
        syntax match jiraItalicStart contained /\(\s\|^\)_/ conceal
        syntax match jiraItalicEnd contained /_\(\s\|$\)/ cchar=  conceal
        syntax match jiraUnderlineStart contained /\(\s\|^\)+/ conceal
        syntax match jiraUnderlineEnd contained /+\(\s\|$\)/ cchar=  conceal
        syntax match jiraCodeInlineStart contained /{{/ conceal
        syntax match jiraCodeInlineEnd contained /}}/ conceal
        setlocal conceallevel=2
        setlocal concealcursor=nc
    endif
    highlight link jiraIssue Tag
    highlight link jiraTitle Title
    highlight link jiraCode Comment
    highlight link jiraCodeInline Comment
    highlight link jiraCodeInlineStart Comment
    highlight link jiraCodeInlineEnd Comment
    highlight link jiraCommentAuthor Type
    highlight link jiraUser Type
    highlight link jiraLink Underlined
    highlight def  jiraBold      term=bold      cterm=bold      gui=bold
    highlight def  jiraItalic    term=italic    cterm=italic    gui=italic
    highlight def  jiraUnderline term=underline cterm=underline gui=underline

endfunction

function s:wrap()
    let l:hits = []
    let l:in_code = 0
    for l:linenr in range(1,  line('$')+1)
        let l:line = getline(l:linenr)
        if l:line =~? '^\s*{code.\{-}}\s*$' || l:line=~? '^\s*{quote.\{-}}\s*$' || l:line=~? '^\s*{noformat.\{-}}\s*$'
            if l:in_code == 0
                let l:in_code = 1
            else
                let l:in_code = 0
            endif
        endif
        if strlen(l:line) > 80 && l:in_code != 1
            call add(l:hits, l:linenr)
        endif
    endfor
    call reverse(l:hits)
    for l:hit in l:hits
        execute 'silent normal!' . l:hit . "Ggql"
    endfor
endfunction

command! -nargs=0 JiraHistoryAtCursor call jira#history_go(getline('.'))
command! -nargs=0 JiraIssueAtLine call jira#search_go(getline('.'))
command! -nargs=0 JiraBack call jira#back()

function! s:keys(type)
    if a:type == 'history'
        nnoremap <silent> <buffer> <cr> :JiraHistoryAtCursor<cr>
    elseif a:type == 'search'
        nnoremap <silent> <buffer> <cr> :JiraIssueAtLine<cr>
    else
        nnoremap <silent> <buffer> <cr> :JiraIssueAtCursor<cr>
    endif
    nnoremap <silent> <buffer> <bs> :JiraBack<cr>
endfunction

function! jira#issue(key) abort
    if strlen(a:key)<1
        return
    endif
    call s:open_window("issue")
    execute 'python' "<< EOF"
import vim
import vimjira
vimjira.issue(vim.eval("a:key"))
EOF
endfunction

function! jira#gitbranch() abort
    let l:current_file = expand('%')
    if strlen(l:current_file) == 0 || l:current_file == '[Jira]'
        let l:current_file = '.'
    endif
    call s:open_window("issue")
    execute 'python' "<< EOF"
import vim
import vimjira
vimjira.gitbranch(vim.eval("l:current_file"))
EOF
endfunction

function! jira#search(query) abort
    if strlen(a:query)<1
        return
    endif
    call s:open_window("search")
    execute 'python' "<< EOF"
import vimjira
vimjira.search(vim.eval("a:query"))
EOF
endfunction

function! jira#search_go(line) abort
    if strlen(a:line)<1
        return
    endif
    let l:parts = split(a:line)
    let l:issue = parts[0]
    call s:open_window("issue")
    execute 'python' "<< EOF"
import vim
import vimjira
vimjira.issue(vim.eval("l:issue"))
EOF
endfunction

function! jira#history() abort
    call s:open_window("history")
    call add(s:breadcrumbs, 'history:')
    " Leave this window modifiable so I can edit searches and re-run them
    set modifiable
    silent %d
    call append(0, 'history')
    call append(1, s:history)
    execute 'normal! gg'
endfunction

function! jira#history_go(line) abort
    let parts = split(a:line, ':')
    let type = parts[0]
    if type == 'issue'
        call jira#issue(join(parts[1:-1], ':'))
    elseif type == 'history'
        call jira#history()
    elseif type == 'query'
        call jira#search(join(parts[1:-1], ':'))
    endif
endfunction

function! jira#back() abort
    if len(s:breadcrumbs) == 0
        echom "No previous page"
        return
    elseif len(s:breadcrumbs) == 1
        echom "No previous page"
        return
    elseif len(s:breadcrumbs) == 2
        let l:target = s:breadcrumbs[0]
        let s:breadcrumbs = []
        call jira#history_go(l:target)
    else
        let l:target = s:breadcrumbs[-2]
        let s:breadcrumbs = s:breadcrumbs[:-3]
        call jira#history_go(l:target)
    endif
endfunction
