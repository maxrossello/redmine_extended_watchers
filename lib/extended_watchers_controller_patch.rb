require_dependency 'watchers_controller'

module ExtendedWatchersControllerPatch
    
  def check_project_privacy
    if Setting.plugin_redmine_extended_watchers["policy"] == "extended" &&
      User.current.logged? && (params[:action] == 'unwatch') && (params[:object_type] == 'issue')
      return Issue.find(params[:object_id]).watched_by?(User.current)
    end
    super()
  end

end

unless WatchersController.included_modules.include?(ExtendedWatchersControllerPatch)
    WatchersController.send(:prepend, ExtendedWatchersControllerPatch)
end
