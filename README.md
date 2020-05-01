# Redmine Extended Watchers

Tested with Redmine 3.4.13.

In plain Redmine, non member users of a project can be added as issue watchers by member users, but nevertheless the watcher user does not gain any additional view permission either on the watched issue  nor the container project. This is rather misleading and prevents a scenario where a project member wants to engage a non-member user over a specific issue without the need to change overall project permissions and disclose further details.

This plug-in allows to unambiguously add a watcher to an issue if and only if this provides additional view permissions to the watcher user. It adds two alternative behaviors to watchers management with a different scope: one removes ambiguity by applying a restriction to the users that can be added as watchers; the other, instead, extends the visibility permissions of the user.

Refer to the *Configuration* paragraph below for further details.

## Installation

Simply install the plug-in into the Redmine plugins folder and restart your server.

## Configuration

In the plugin configuration page the administrator can select one out of three watchers behavior.

![plugin configuration](screenshots/plugin_config.png) 

* **Default**
  The Redmine default behavior is preserved. A user has issue view permission according to its role settings. A project member can add any user in the system as a watcher, nevertheless the watcher user does not gain any additional issue or project view permission, nor it gets notified via email for an issue change or a new comment added.
  
* **Extended**
  A project member can add any user in the system as a watcher. As a consequence, the issue is always visible to the watcher and issue changes are notified via email according to the user's settings. If the container project was not already visible because of assigned roles, then it becomes accessible and visible also in the project list. However, only the issues module will be disclosed, whereas every other enabled module in the system (e.g. wiki, roadmaps, forums, news, etc.) will remain hidden.
  
  Additional visibility applies to private issues too. Additional view permissions last until the issue is watched, and are removed thereafter.
* **Protected**
  A project member cannot assign a user as issue watcher unless it has permission to view it. Furthermore, in case the watcher role in the project has just 'issues created by or assigned to the user' permission, then it also gains issue view permission and issue change email notifications when assigned as a watcher.
  
  Additional visibility applies to private issues too. 
  Note: a watcher user that looses view permissions because of role assignments still remains a watcher, but it will anyway have no visibility of the issue nor of the container project. However, it will regain additional permissions once it gains project access because of restored role permissions.