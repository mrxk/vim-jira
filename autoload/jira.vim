if exists('g:loaded_jira')
  finish
endif
let g:loaded_jira = 1

if !exists('g:vim_jira_use_single_tab')
    let g:vim_jira_use_single_tab = 0
endif

if !exists('g:vim_jira_format_output')
    let g:vim_jira_format_output = 1
endif

let s:sort_order = 'default'
let s:jira_tab = 0
let s:history = []
let s:breadcrumbs = []

function! s:tab_title(type)
    if strlen(a:type) == 0
        return '[Jira]'
    endif
    return '[Jira '.a:type.']'
endfunction

function! s:open_tab(type)
    let l:type = a:type
    if g:vim_jira_use_single_tab == 1
        let l:type = ''
    endif
    let l:found = 0
    let l:tab_title = s:tab_title(l:type)
    " Find the tab with our buffer in it
    for t in range(tabpagenr('$'))
        for b in tabpagebuflist(t+1)
            if bufname(b) ==# l:tab_title
                let l:found = 1
                let s:jira_tab = t+1
            endif
        endfor
    endfor
    if l:found == 1
        "Found it.  Now move to it.
        execute 'normal!' s:jira_tab.'gt'
    "Else present and selected.
    else
        "Did not find it.  Need to create it and set it up.
        tab new
        let s:jira_tab = tabpagenr()
        call s:syntax()
        call s:assign_name(l:type)
        " Use the whole file for syntax
        syntax sync fromstart
        " Make this a temporary buffer
        setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile
        " Handle lists correctly
        setlocal formatoptions=tqn
        setlocal formatlistpat=^\\s*[0-9#\\-*+]\\+[\\]:.)}\\t\ ]\\s*
        setlocal comments=
    endif
    call s:keys(a:type)
    setlocal modifiable
    silent %d
    call setline(1, "Loading jira...")
    setlocal nomodifiable
    if a:type == 'search' || a:type == 'history'
        setlocal cursorline
        setlocal nowrap
    else
        setlocal nocursorline
        setlocal wrap
    endif
    redraw
endfunction

function! s:assign_name(type)
  " Assign buffer name
  let prefix = s:tab_title(a:type)
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
    syntax match jiraLink /https*:\/\/[A-Za-z\.\/0-9\-\:_ ?=&+%;#!]*/
    syntax match jiraBold /\(\s\|^\)\*.\{-}\*\(\s\|$\)/ contains=jiraBoldStart,jiraBoldEnd containedin=ALL
    syntax match jiraBold /\(\s\|^\){\*}.\{-}{\*}\(\s\|$\)/ contains=jiraBoldStart,jiraBoldEnd containedin=ALL
    syntax match jiraItalic /\(\s\|^\)_.\{-}_\(\s\|$\)/ contains=jiraItalicStart,jiraItalicEnd containedin=ALL
    syntax match jiraUnderline /\(\s\|^\)+.\{-}+\(\s\|$\)/ contains=jiraUnderlineStart,jiraUnderlineEnd containedin=ALL
    syntax match jiraCodeInline /{{\_.\{-}}}/ contains=jiraCodeInlineStart,jiraCodeInlineEnd containedin=ALL
    if v:version >= 703
        syntax match jiraBoldStart contained /\s\*/ cchar=  conceal
        syntax match jiraBoldStart contained /^\*/ conceal
        syntax match jiraBoldStart contained /\s{\*}/ cchar=  conceal
        syntax match jiraBoldStart contained /^{\*}/ conceal
        syntax match jiraBoldEnd contained /\*\s/ cchar=  conceal
        syntax match jiraBoldEnd contained /\*$/ conceal
        syntax match jiraBoldEnd contained /{\*}\s/ cchar=  conceal
        syntax match jiraBoldEnd contained /{\*}$/ conceal
        syntax match jiraItalicStart contained /\s_/ cchar=  conceal
        syntax match jiraItalicStart contained /^_/ conceal
        syntax match jiraItalicEnd contained /_\s/ cchar=  conceal
        syntax match jiraItalicEnd contained /_$/ conceal
        syntax match jiraUnderlineStart contained /\s+/ cchar=  conceal
        syntax match jiraUnderlineStart contained /^+/ conceal
        syntax match jiraUnderlineEnd contained /+\s/ cchar=  conceal
        syntax match jiraUnderlineEnd contained /+$/ conceal
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
        if l:line =~? '\s*{code.\{-}}\s*' || l:line=~? '\s*{quote.\{-}}\s*' || l:line=~? '\s*{noformat.\{-}}\s*'
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

command! -nargs=0 JiraIssueAtCursor call jira#issue(expand('<cWORD>'))
command! -nargs=0 JiraHistoryAtCursor call jira#history_go(getline('.'))
command! -nargs=0 JiraIssueAtLine call jira#search_go(getline('.'))
command! -nargs=0 JiraBack call jira#back()
command! -nargs=0 JiraNextSort call jira#next_sort()

function! s:keys(type)
    if a:type == 'history'
        nnoremap <silent> <buffer> <cr> :JiraHistoryAtCursor<cr>
        silent! nunmap <silent> <buffer> s
    elseif a:type == 'search'
        nnoremap <silent> <buffer> <cr> :JiraIssueAtLine<cr>
        nnoremap <silent> <buffer> s :JiraNextSort<cr>
    else
        nnoremap <silent> <buffer> <cr> :JiraIssueAtCursor<cr>
        silent! nunmap <silent> <buffer> s
    endif
    nnoremap <silent> <buffer> <bs> :JiraBack<cr>
endfunction

function! jira#configure() abort
    execute 'python' "<< EOF"
import vim
import vimjira
vimjira.configure()
EOF
endfunction

function! jira#issue(key) abort
    if strlen(a:key)<1
        return
    endif
    call s:open_tab(a:key)
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
    call s:open_tab("git branch")
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
    call s:open_tab("search")
    execute 'python' "<< EOF"
import vimjira
vimjira.search(vim.eval("a:query"))
EOF
    call s:sort_issues_buffer()
endfunction

function! jira#next_sort()
    if s:sort_order == 'key'
        let s:sort_order = 'date'
    elseif s:sort_order == 'date'
        let s:sort_order = 'priority'
    elseif s:sort_order == 'priority'
        let s:sort_order = 'status'
    elseif s:sort_order == 'status'
        let s:sort_order = 'assignee'
    elseif s:sort_order == 'assignee'
        let s:sort_order = 'summary'
    elseif s:sort_order == 'summary'
        let s:sort_order = 'default'
    elseif s:sort_order == 'default'
        let s:sort_order = 'key'
    endif
    call s:sort_issues_buffer()
endfunction

function! s:get_sort_separator() abort
    if s:sort_order == 'key'
        return "vvv           | ------------                 | -------- | ------ | --------   | -------"
    elseif s:sort_order == 'date'
        return "---           | vvvvvvvvvvvv                 | -------- | ------ | --------   | -------"
    elseif s:sort_order == 'priority'
        return "---           | ------------                 | vvvvvvvv | ------ | --------   | -------"
    elseif s:sort_order == 'status'
        return "---           | ------------                 | -------- | vvvvvv | --------   | -------"
    elseif s:sort_order == 'assignee'
        return "---           | ------------                 | -------- | ------ | vvvvvvvv   | -------"
    elseif s:sort_order == 'summary'
        return "---           | ------------                 | -------- | ------ | --------   | vvvvvvv"
    else
        return "---           | ------------                 | -------- | ------ | --------   | -------"
    endif
endfunction


function! s:compare_lines(line1, line2)
    let l:parts1 = split(a:line1, '|')
    let l:parts2 = split(a:line2, '|')
    let l:idx = 0
    if s:sort_order == 'default'
        let l:val1 = l:parts1[4].l:parts1[1]
        let l:val2 = l:parts2[4].l:parts2[1]
        if l:parts1[4] != l:parts2[4]
            let l:val = l:parts1[4] > l:parts2[4] ? 1 : l:parts1[4] < l:parts2[4] ? -1 : 0
            return l:val
        else
            let l:val = l:parts1[1] > l:parts2[1] ? 1 : l:parts1[1] < l:parts2[1] ? -1 : 0
            return -l:val
        endif
    endif
    if s:sort_order == 'key'
        let l:parts1 = split(l:parts1[0], '-')
        let l:parts2 = split(l:parts2[0], '-')
        if l:parts1[0] != l:parts2[0]
            let l:val = l:parts1[0] > l:parts2[0] ? 1 : l:parts1[0] < l:parts2[0] ? -1 : 0
            return l:val
        else
            let l:val = l:parts1[1]+1 > l:parts2[1]+1 ? 1 : l:parts1[1]+1 < l:parts2[1]+1 ? -1 : 0
            return -l:val
        endif
    endif
    let l:asc = 0
    if s:sort_order == 'date'
        let l:idx = 1
    elseif s:sort_order == 'priority'
        let l:idx = 2
        let l:asc = 1
    elseif s:sort_order == 'status'
        let l:idx = 3
    elseif s:sort_order == 'assignee'
        let l:idx = 4
        let l:asc = 1
    elseif s:sort_order == 'summary'
        let l:idx = 5
        let l:asc = 1
    endif
    let l:val = l:parts1[l:idx] > l:parts2[l:idx] ? 1 : l:parts1[l:idx] < l:parts2[l:idx] ? -1 : 0
    if l:asc == 0
        return -l:val
    else
        return l:val
endfunction

function! s:sort_issues_buffer() abort
    set modifiable
    call setline(3, s:get_sort_separator())
    call setline(4, sort(getline(4, '$'), function('s:compare_lines')))
    " Re-tabularize to line up the sort separator
    execute '2,$Tabularize /|'
    execute 'normal! gg'
    set nomodifiable
endfunction

function! jira#search_go(line) abort
    if strlen(a:line)<1
        return
    endif
    let l:parts = split(a:line)
    let l:issue = parts[0]
    call s:open_tab(l:issue)
    execute 'python' "<< EOF"
import vim
import vimjira
vimjira.issue(vim.eval("l:issue"))
EOF
endfunction

function! jira#history() abort
    call s:open_tab("history")
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
