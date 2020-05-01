require 'redmine'

Rails.logger.info 'Starting Extended Watchers plugin for Redmine'

require_dependency 'extended_watchers_issue_patch'
require_dependency 'extended_watchers_controller_patch'
require_dependency 'extended_watchers_user_patch'
require_dependency 'extended_watchers_project_patch'
require_dependency 'extended_watchers_application_controller_patch'

Redmine::Plugin.register :redmine_extended_watchers do
  name 'Redmine Extended Watchers plugin'
  author 'Massimo Rossello'
  description 'Enables all users to be assigned as watchers of an issue and have limited access to it in the project'
  version '3.4.0.3'
  url 'https://github.com/maxrossello/redmine_extended_watchers.git'
  author_url 'https://github.com/maxrossello'
  requires_redmine :version_or_higher => '3.4.0'
  
  # policy: default, extended, protected 
  settings :default => {'policy' => 'extended'}, :partial => 'settings/extwatch_settings'
end
