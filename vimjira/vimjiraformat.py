#!/usr/bin/python
import vim
import vimjira
from jira.client import JIRA

def as_ascii(str):
    if str is None:
        return None
    return unicode(str).encode('ascii', 'xmlcharrefreplace')

def get_priority_name(issue):
    if issue.fields.priority:
        return as_ascii(issue.fields.priority.name)
    else:
        return ""

def format_link(link):
    if hasattr(link, 'inwardIssue'):
        return "{0} - {1} (i)".format(link.inwardIssue.key, link.type)
    else:
        return "{0} - {1} (o)".format(link.outwardIssue.key, link.type)

def display_subtasks(subtasks):
    if not subtasks or len(subtasks) == 0:
        return
    first = True
    curbuf = vim.current.buffer
    for t in subtasks:
        if first:
            curbuf.append("Subtasks     : {0}".format(t.key))
            first = False
        else:
            curbuf.append("               {0}".format(t.key))

def display_links(links):
    if not links or len(links) == 0:
        return
    first = True
    curbuf = vim.current.buffer
    for l in links:
        if first:
            curbuf.append("Issue links  : {0}".format(format_link(l)))
            first = False
        else:
            curbuf.append("               {0}".format(format_link(l)))

def display_labels_line(labels):
    labels = ", ".join(labels)
    if len(labels) > 0:
        vim.current.buffer.append("Labels       : {0}".format(labels))

def display_a_version_line(versions):
    versions = ", ".join([v.name for v in versions])
    if len(versions) > 0:
        vim.current.buffer.append("Affects ver  : {0}".format(versions))

def display_f_version_line(versions):
    versions = ", ".join([v.name for v in versions])
    if len(versions) > 0:
        vim.current.buffer.append("Fixed ver    : {0}".format(versions))

def display_environment_line(environment):
    if not environment:
        return
    first = True
    curbuf = vim.current.buffer
    for oline in as_ascii(environment).split('\r\n'):
        for iline in as_ascii(oline).split('\n'):
            if first:
                curbuf.append("Environment  : {0}".format(iline))
                first = False
            else:
                curbuf.append("               {0}".format(iline))

def display_comments(issue):
    curbuf = vim.current.buffer
    comments = issue.fields.comment.comments
    curbuf.append("")
    curbuf.append("Comments")
    curbuf.append("="*79)
    if len(comments) > 0:
        for comment in comments:
            updated = ""
            if comment.created != comment.updated:
                updated = " (edited)"
            title = "{0}: {1}{2}".format(as_ascii(comment.author), comment.created, updated)
            curbuf.append("")
            curbuf.append(title)
            curbuf.append('-'*79)
            for oline in as_ascii(comment.body).split('\r\n'):
                for iline in as_ascii(oline).split('\n'):
                    curbuf.append(iline)

def display_issue(issue):
    vim.command('setlocal modifiable')
    curbuf = vim.current.buffer
    del curbuf[:]
    curbuf[0] = "{0} : {1}/browse/{2}".format(issue.key, vimjira.get_server(), issue.key)
    curbuf.append("="*79)
    curbuf.append("")
    curbuf.append(as_ascii(issue.fields.summary))
    curbuf.append("")
    curbuf.append("Details")
    curbuf.append("="*79)
    resolution = ''
    if issue.fields.resolutiondate:
        resolution = "({0} - {1})".format(issue.fields.resolution, issue.fields.resolutiondate)
    curbuf.append("Status       : {0} {1}".format(as_ascii(issue.fields.status), resolution))
    curbuf.append("Priority     : {0}".format(get_priority_name(issue)))
    curbuf.append("Issue type   : {0}".format(as_ascii(issue.fields.issuetype)))
    curbuf.append("Components   : {0}".format(", ".join([c.name for c in issue.fields.components])))
    curbuf.append("Reporter     : {0}".format(as_ascii(issue.fields.reporter)))
    curbuf.append("Assignee     : {0}".format(as_ascii(issue.fields.assignee)))
    curbuf.append("Created      : {0}".format(issue.fields.created))
    curbuf.append("Updated      : {0}".format(issue.fields.updated))
    curbuf.append("Project      : {0}".format(as_ascii(issue.fields.project)))
    display_a_version_line(issue.fields.versions)
    display_f_version_line(issue.fields.fixVersions)
    display_labels_line(issue.fields.labels)
    display_environment_line(issue.fields.environment)
    display_subtasks(issue.fields.subtasks)
    display_links(issue.fields.issuelinks)
    curbuf.append("")
    curbuf.append("Description")
    curbuf.append("="*79)
    if issue.fields.description:
        for oline in issue.fields.description.split('\r\n'):
            for iline in oline.split('\n'):
                curbuf.append(as_ascii(iline))

    display_comments(issue)

    #vim.command('/^Description$')
    #vim.command('normal! jjgqG')
    vim.command('call s:wrap()')
    vim.command('normal! 1G')
    vim.command('redraw')
    vim.command('setlocal nomodifiable')

def display_issue_collection(title, issues):
    vim.command('setlocal modifiable')
    curbuf = vim.current.buffer
    del curbuf[:]
    curbuf[0] = '{0} ({1} issues)'.format(title, len(issues))
    if len(issues) > 0:
        curbuf[0] = '{0} ({1} issues)'.format(title, len(issues))
        for issue in sorted(issues, key=lambda i: str(i.fields.assignee)+str(i.fields.updated), reverse=True):
            curbuf.append("{0}| {1}| {2}| {3}| {4}| {5}".format(issue.key, issue.fields.updated, get_priority_name(issue), issue.fields.status, issue.fields.assignee, as_ascii(issue.fields.summary)))
        vim.command('2,$Tabularize /|')
        vim.command('normal! gg')
    vim.command('setlocal nomodifiable')
    vim.command('redraw')

def display_error(e):
    vim.command('setlocal modifiable')
    curbuf = vim.current.buffer
    del curbuf[:]
    for line in str(e).split('\n'):
        curbuf.append(line)
    vim.command('setlocal nomodifiable')
