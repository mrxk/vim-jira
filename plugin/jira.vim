python << EOF
import vim, os, sys

for p in vim.eval("&runtimepath").split(','):
    dname = os.path.join(p, "vimjira")
    if os.path.exists(dname):
        if dname not in sys.path:
            sys.path.append(dname)
            break

EOF

command! -nargs=0 JiraIssue call inputsave() | call jira#issue(input('Jira issue: ')) | call inputrestore()
command! -nargs=0 JiraSearch call inputsave() | call jira#search(input('Jira query string: ')) | call inputrestore()
command! -nargs=0 JiraMyIssues call jira#search('assignee = currentUser() and status = open')
command! -nargs=0 JiraMySprint call jira#search('assignee = currentUser() and sprint in openSprints()')
command! -nargs=0 JiraGitBranch call jira#gitbranch()
command! -nargs=0 JiraHistory call jira#history()
command! -nargs=0 JiraConfigure call jira#configure()

