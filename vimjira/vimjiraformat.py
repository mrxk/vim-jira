#!/usr/bin/python
import vim
import vimjira
import re
from HTMLParser import HTMLParser, HTMLParseError
from htmlentitydefs import name2codepoint

class FormatHTML(HTMLParser):
    def __init__(self):
        HTMLParser.__init__(self)
        self.text = []
        self.indent_level = 0
        self.strip_newlines = True
        self.links = []

    def handle_starttag(self, tag, attrs):
        if tag == 'br':
            self.text.append("\n")
        elif tag == 'p':
            self.text.append("\n\n")
        elif tag == 'pre':
            self.strip_newlines = False
            self.text.append("\n{code}\n")
        elif tag == 'ol':
            self.indent_level = self.indent_level + 1
        elif tag == 'ul':
            self.indent_level = self.indent_level + 1
        elif tag == 'li':
            self.text.append("\n" + ("    " * self.indent_level) + "* ")
        elif tag == 'a':
            for attr in attrs:
                if attr[0] == "href":
                    idx = str(len(self.links) + 1)
                    self.links.append("  [" + idx + "]" + attr[1])
                    self.text.append("[" + idx + "]")

    def handle_startendtag(self, tag, attrs):
        if tag == 'br':
            self.text.append("\n")
        elif tag == 'p':
            self.text.append("\n\n")

    def handle_endtag(self, tag):
        if tag == 'br':
            self.text.append("\n")
        elif tag == 'p':
            self.text.append("\n\n")
        elif tag == 'pre':
            self.strip_newlines = True
            self.text.append("\n{code}\n")
        elif tag == 'ol':
            self.indent_level = self.indent_level - 1
        elif tag == 'ul':
            self.indent_level = self.indent_level - 1

    def handle_data(self, data):
        data = data.replace("\r\n", "\n")
        if self.strip_newlines:
            data = data.replace("\n", "")
        if re.match(r'^[\n\s]$', data):
            return
        self.text.append(data)

    def handle_entityref(self, name):
        if name == "nbsp":
            self.text.append(" ")

    def get_text(self):
        ltext = ''.join(self.text).strip()
        ltext = re.sub(r'\n\n[\n]+', '\n\n', ltext)
        if len(self.links) > 0:
            ltext = ltext + "\n\nReferences\n"
            for link in self.links:
                ltext = ltext + "\n" + link
        return ltext

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

def display_asignee_line(assignee):
    if assignee:
        vim.current.buffer.append("Assignee     : {0}".format(as_ascii(assignee.displayName)))
    else:
        vim.current.buffer.append("Assignee     : {0}".format('[Unassigned]'))

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

def extract_text(text):
    try:
        parser = FormatHTML()
        parser.feed(text)
        parser.close()
        return parser.get_text()
    except:
        pass

def is_formatting_enabled():
    fmt = int(vim.eval("g:vim_jira_format_output"))
    return fmt == 1

def current_width():
    width = int(vim.eval("winwidth(0)"))
    if width > 79:
        width = 79
    return width

def display_description(description):
    width = current_width()
    curbuf = vim.current.buffer
    curbuf.append("")
    curbuf.append("Description")
    curbuf.append("="*width)
    if not description:
        return
    curbuf = vim.current.buffer
    if is_formatting_enabled() and description.startswith("<p>"):
        description = extract_text(description)
    for oline in description.split('\r\n'):
        for iline in oline.split('\n'):
            curbuf.append(as_ascii(iline))

def display_comments(issue):
    width = current_width()
    curbuf = vim.current.buffer
    comments = issue.fields.comment.comments
    curbuf.append("")
    curbuf.append("Comments")
    curbuf.append("="*width)
    if len(comments) > 0:
        for comment in comments:
            updated = ""
            if comment.created != comment.updated:
                updated = " (edited)"
            title = "{0}: {1}{2}".format(as_ascii(comment.author), comment.created, updated)
            curbuf.append("")
            curbuf.append(title)
            curbuf.append('-'*width)
            body = comment.body
            if is_formatting_enabled() and body.startswith("<"):
                body = extract_text(body)
            for oline in body.split('\r\n'):
                for iline in as_ascii(oline).split('\n'):
                    curbuf.append(as_ascii(iline))

def display_issue(issue):
    width = current_width()
    vim.command('setlocal modifiable')
    curbuf = vim.current.buffer
    del curbuf[:]
    curbuf[0] = "{0} : {1}/browse/{2}".format(issue.key, vimjira.get_server(), issue.key)
    curbuf.append("="*width)
    curbuf.append("")
    curbuf.append(as_ascii(issue.fields.summary))
    curbuf.append("")
    curbuf.append("Details")
    curbuf.append("="*width)
    resolution = ''
    if issue.fields.resolutiondate:
        resolution = "({0} - {1})".format(issue.fields.resolution, issue.fields.resolutiondate)
    curbuf.append("Status       : {0} {1}".format(as_ascii(issue.fields.status), resolution))
    curbuf.append("Priority     : {0}".format(get_priority_name(issue)))
    curbuf.append("Issue type   : {0}".format(as_ascii(issue.fields.issuetype)))
    curbuf.append("Components   : {0}".format(", ".join([c.name for c in issue.fields.components])))
    curbuf.append("Reporter     : {0}".format(as_ascii(issue.fields.reporter.displayName)))
    display_asignee_line(issue.fields.assignee)
    curbuf.append("Created      : {0}".format(issue.fields.created))
    curbuf.append("Updated      : {0}".format(issue.fields.updated))
    curbuf.append("Project      : {0}".format(as_ascii(issue.fields.project)))
    display_a_version_line(issue.fields.versions)
    display_f_version_line(issue.fields.fixVersions)
    display_labels_line(issue.fields.labels)
    display_environment_line(issue.fields.environment)
    display_subtasks(issue.fields.subtasks)
    display_links(issue.fields.issuelinks)
    display_description(issue.fields.description)
    display_comments(issue)

    #vim.command('/^Description$')
    #vim.command('normal! jjgqG')
    if is_formatting_enabled():
        vim.command('call s:wrap()')
    vim.command('normal! 1G')
    vim.command('redraw')
    vim.command('setlocal nomodifiable')

def display_issue_collection(title, issues):
    vim.command('setlocal modifiable')
    curbuf = vim.current.buffer
    del curbuf[:]
    curbuf[0] = '{0} ({1} issues)'.format(title, len(issues))
    curbuf.append("Key | Updated date | Priority | Status | Assignee | Summary")
    curbuf.append("--- | ------------ | -------- | ------ | -------- | -------")
    if len(issues) > 0:
        curbuf[0] = '{0} ({1} issues)'.format(title, len(issues))
        for issue in issues:
            if (issue.fields.assignee):
                curbuf.append("{0}| {1}| {2}| {3}| {4}| {5}".format(issue.key, issue.fields.updated, get_priority_name(issue), issue.fields.status, issue.fields.assignee.displayName, as_ascii(issue.fields.summary)))
            else:
                curbuf.append("{0}| {1}| {2}| {3}| {4}| {5}".format(issue.key, issue.fields.updated, get_priority_name(issue), issue.fields.status, '[Unassigned]', as_ascii(issue.fields.summary)))
        vim.command('2,$Tabularize /|')
        vim.command('normal! gg')
    vim.command('setlocal nomodifiable')

def display_error(e):
    vim.command('setlocal modifiable')
    curbuf = vim.current.buffer
    del curbuf[:]
    for line in str(e).split('\n'):
        curbuf.append(line)
    vim.command('setlocal nomodifiable')
