# Redmine Extended Watchers

In versions of Redmine prior to 4.2, non member users of a project could be added as issue watchers by member users without gaining the necessary view permission to see the project and the issue itself.  
This plug-in was originally created to fix this misleading behavior in one of two possible directions: either forbid users that are not project members as Watchers or allow them but simultaneously soft-grant them the needed permissions.

In Extended Mode, the plug-in allows you to add users as issue watchers even if they don't have sufficient viewing permissions in the project. The user will be then soft-granted viewing permissions to the project and the watched issue.  
Alternatively, in Protected Mode, the plug-in allows you to prevent adding watchers that do not have sufficient viewing permissions already.

Starting with Redmine 4.2, the default behavior was made more consistent by not allowing non member users as Watchers, comparable to the Protected Mode of this plug-in. However, the Protected Mode is still useful to configure the individual privileges granted on watched issues through the membership to an unprivileged Role that would otherwise allow to see and manage, with those defined privileges, only the own issues. Thus, being assigned as a watcher to an otherwise hidden issue will grant the issue privileges in the Role over the watched issue(s) too, similarly to the case when the issue is assigned to the user.

Furthermore, Redmine can now also assign roles and watch capability to groups too, therefore these policies are also valid for groups.  
In this respect, you may intend the Protected Mode as a way to read the *"issues created by or assigned to the user"* setting as *"issues created by or assigned to or watched by the user/group"*.

Refer to the *Configuration* paragraph below for further details.

## Version

Tests are performed through [redmine_testsuites](https://github.com/maxrossello/redmine_testsuites) including all the plugins it supports.

The plugin version corresponds to minimum version of Redmine required. Look at dedicated branch for each Redmine version.

## Installation

Simply install the plug-in into the Redmine plugins folder and restart your server.

## Configuration

In the plugin configuration page the administrator can select one out of three watchers behavior.

![plugin configuration](screenshots/plugin_config.png) 

* **Default**
  The Redmine default behavior is preserved. A user or group has issue view permission according to its role settings. A project member can add any user or group in the system as a watcher according to the  visibility that its role allows, nevertheless the watcher user/group does not gain any additional issue or project view permission, nor it gets notified via email for an issue change or a new comment added.
  
* **Extended**
  A project member can add any user or group in the system as a watcher according to the visibility that its role allows. As a consequence, the issue is always visible to the watcher and issue changes are notified via email according to the user/group's settings, as long as the issue tracking module is enabled in the project. 
  
  If the container project was not already visible because of assigned roles, then it becomes accessible and visible also in the project list. However, only the issues module will be disclosed, whereas every other enabled module in the system (e.g. wiki, roadmaps, forums, news, etc.) will remain hidden.
  
  In summary, watching acts as a lightweight permission to access specific issues that allows to disclose single items to non members. Below is a screenshot depicting how a non-member user or group watching an issue would view the private project containing the watched issue
  
  ![watcher project view](screenshots/watcher_view.png)
  
  
  Additional visibility applies to private issues too. It lasts until the issue is watched, and is removed thereafter.
  
  **Warning:** this mode is specifically crafted to grant visibility to *any* user in the system. Therefore, the list of *all* users becomes visible in the autocompletion form irrespective of the user visibility assigned to the user's role. This overrides the privacy enforcement patches introduced since Redmine 5.1.4.
  
* **Protected**
  A project member cannot assign a user or group to watch an issue, and a watcher cannot have additional view permission over an issue, unless either: 

  * the candidate watcher is a project member with a role that has at least *issues created by or assigned to the user* permission in the project (i.e. *view issues*) or,
  * the project is public, the candidate watcher has no role in the project, but the nonmember role has that permission

  As per Redmine policies:

  * the assigner must have *add watcher* permission; 
  * the nonmember role is considered if and only if the project is public and the candidate watcher has no other role in the project
  * the issue tracking module must be enabled in the project
  
  Watching an issue overtakes the visibility limitations of the user/group role(s) over the issue's tracker.
  
  As a consequence of watching under above conditions, the issue is always visible to the watcher and issue changes are notified via email according to the user/group's settings.
  
  Additional visibility applies to private issues too. It lasts until the issue is watched, and is removed thereafter.
  
  Note: a watcher user or group that looses view permissions because of role assignments still remains a watcher, but it will anyway have no visibility of the issue nor of the container project. However, it will regain additional permissions once it gains project access because of restored role permissions, unless the issue's watchers are pruned.
