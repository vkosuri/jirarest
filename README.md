# jirarest
jira tcl rest apis

Working example

``` tcl
% lappend auto_path [join [pwd]]
% package require jira
% ::jira::login http://jira.test.com test testpass
% ::jira::getJiraAttachement 123 testlog

```