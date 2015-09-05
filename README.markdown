# vim-jira

Browse Jira tickets from vim.  Update not supported.

## Requirements

Your Vim must be compiled with Python support.  The following Python packages
must be available.
* jira
* GitPython
* keyring

This plugin works best if your display is 79 columns wide or wider.

## First usage

The first time any of the commands provided by this plugin are invoked the
user will be promtped for their Jira server, username, and password.  This
information is saved via Python keyring.  It can be changed by the
`:JiraConfigure` command.

## Features

* `:JiraIssue`: Prompt for a Jira issue and display it.
* `:JiraSearch`: Prompt for a jql query string.  Display the list of matching issues.
* `:JiraMyIssues`: Display the list of issues maching the jql query `assignee = currentUser() and status = open`.
* `:JiraGitBranch`: Display the Jira issue using the current git branch as the issue key.
* `:JiraHistory`: Display the list of Jira queries performed in the current Vim session.
* `:JiraConfigure`: Prompt for Jira server, username, and password.

In list view, the <cr> key is mapped to display the issue in the current
cursor line.

In history view, the <cr> key will re-execute the query in the current cursor
line.  Note that the history view is editable.  The value of the current line
will be used as the query.

In issue view, the <cr> key is mapped to display the issue under the cursor.

## Highlighting

In the buffers used by this plugin, the following Jira syntax is recognized

* Issue keys
* [~user]
* {code} blocks
* {quote} blocks
* {noformat} blocks
* *...* bold
* _..._ italics
* +...+ underline

## Example mapping

This plugin does not map any keys outside of its own buffers.  I use the
following mapping in my .vimrc:

    nnoremap <silent> <leader>ji :JiraIssue<cr>
    nnoremap <silent> <leader>js :JiraSearch<cr>
    nnoremap <silent> <leader>jo :JiraMyIssues<cr>
    nnoremap <silent> <leader>jh :JiraHistory<cr>
    nnoremap <silent> <leader>jg :JiraGitBranch<cr>

## Known issues

A jql query with single quotes is currently broken.  Double quotes work fine.
