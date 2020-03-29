# Redmine Extended Watchers

Tested with Redmine 3.4.13.

In plain Redmine, currently, non member users of a project can be added as issue watchers by member users, but issue change notifications won't be sent to them. This is very confusing.

This plug-in allows to add any user in the system as a watcher of some issue. 
The system behavior for the watcher user will be similar to that of 'view assigned issues' permission, except that the whole project gets hidden back if the last issue is unwatched (unless other permissions are given).

If only watching an issue in a project, all other project modules will be hidden. The project overview is redirected to the issues view, showing just the watched issue(s).

The same applies to private issues: once they are watched, they become visible, and the containing project as well.

## Installation

Simply install the plug-in into the Redmine plugins folder and restart your server.