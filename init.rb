require 'redmine'

Rails.logger.info 'Starting Extended Watchers plugin for Redmine'

require_dependency 'extended_watchers_issue_patch'
require_dependency 'extended_watchers_controller_patch'
require_dependency 'extended_watchers_user_patch'

Rails.configuration.to_prepare do
  unless Issue.included_modules.include?(ExtendedWatchersIssuePatch)
      Issue.send(:include, ExtendedWatchersIssuePatch)
  end

  unless WatchersController.included_modules.include?(ExtendedWatchersControllerPatch)
      WatchersController.send(:include, ExtendedWatchersControllerPatch)
  end

  unless User.included_modules.include?(ExtendedWatchersUserPatch)
      User.send(:include, ExtendedWatchersUserPatch)
  end

  unless Project.included_modules.include?(ExtendedWatchersProjectPatch)
    Project.send(:include, ExtendedWatchersProjectPatch)
  end

  unless ApplicationController.included_modules.include?(ExtendedWatchersApplicationControllerPatch)
    ApplicationController.send(:include, ExtendedWatchersApplicationControllerPatch)
  end
end

Redmine::Plugin.register :redmine_extended_watchers do
  name 'Redmine Extended Watchers plugin'
  author 'Massimo Rossello'
  description 'Enables all users to be assigned as watchers of an issue and have limited access to it in the project'
  version '1.0.5'
  url 'https://github.com/maxrossello/redmine_extended_watchers.git'
  author_url 'https://github.com/maxrossello'
  requires_redmine :version_or_higher => '2.1.0'
end
