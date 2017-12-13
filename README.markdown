# vim-jira

Browse Jira tickets from Vim.  Update not supported.

## Requirements

Your Vim must be compiled with Python support.  The following Python packages
must be installed.
* jira (1.0.7): https://pypi.python.org/pypi/jira
* GitPython (2.1.0): https://pypi.python.org/pypi/GitPython
* keyring (10.0.2): https://pypi.python.org/pypi/keyring
* keyrings.alt (1.1.1): https://pypi.python.org/pypi/keyrings.alt (for cygwin)

The following Vim plugins are also required.
* Tabular: https://github.com/godlygeek/tabular.git

## First usage

The first time any of the commands provided by this plugin are invoked the
user will be promtped for their Jira server, username, and password.  This
information is saved via Python keyring.  It can be changed by the
`:JiraConfigure` command.

## Commands

This plugin provides the following commands

* `:JiraIssue`: Prompt for a Jira issue and display it.
* `:JiraSearch`: Prompt for a jql query string.  Display the list of matching issues.
* `:JiraMyIssues`: Display the list of issues maching the jql query `assignee = currentUser() and status = open`.
* `:JiraGitBranch`: Display the Jira issue using the current git branch as the issue key.
* `:JiraHistory`: Display the list of Jira queries performed in the current Vim session.
* `:JiraConfigure`: Prompt for Jira server, username, and password.

In list view, the &lt;cr&gt; key is mapped to display the issue in the current
cursor line.  The &lt;s&gt; key is mapped to sort.  Repeatedly pressing the
&lt;s&gt; key will cycle the sort through the following columns: Key, Updated
date, Priority, Status, Assignee, Summary.

In history view, the &lt;cr&gt; key will re-execute the query in the current
cursor line.  Note that the history view is editable.  The value of the
current line will be used as the query.

In issue view, the &lt;cr&gt; key is mapped to display the issue under the
cursor.

## Highlighting

In the buffers used by this plugin, the following Jira syntax is recognized

* Issue keys
* `[~user]`
* `{code}` blocks
* `{quote}` blocks
* `{noformat}` blocks
* `{{...}}` monospace
* `*...*` bold
* `_..._` italics
* `+...+` underline

If the Vim version supports conceal then the `{{`, `}}`, `*`, `_`, and `+`
format characers will be hidden.

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

