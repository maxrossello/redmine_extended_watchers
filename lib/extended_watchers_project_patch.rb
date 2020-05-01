require_dependency 'user'

module ExtendedWatchersProjectPatch

   def visible_condition(user, options={})
      return super if Setting.plugin_redmine_extended_watchers["policy"] != "extended"

      issues = Issue.watched_by(user).joins(:project => :enabled_modules).where("#{EnabledModule.table_name}.name = 'issue_tracking'")

      if issues.any?
         super(user,options) + " OR #{Project.table_name}.id IN (#{issues.all.collect(&:project_id).join(",")})"
      else
         super(user,options)
      end
   end
  
end

unless Project.singleton_class.included_modules.include?(ExtendedWatchersProjectPatch)
   Project.singleton_class.send(:prepend, ExtendedWatchersProjectPatch)
end
