require_dependency 'user'

module ExtendedWatchersUserPatch

   def allowed_to?(action, context, options={}, &block)
      is_allowed = super(action, context, options, &block)
      return is_allowed if is_allowed || Setting.plugin_redmine_extended_watchers["policy"] != "extended"
      
      return false if context && context.is_a?(Project) && context.archived?
      
      if (options[:watchers].nil? || options[:watchers]) && self.logged? && context && context.is_a?(Project)
         if action.is_a?(Hash)
            if action[:controller] == "issues" && action[:action] == "index"
               return true if Issue.where(:project_id => context).watched_by(self).joins(:project => :enabled_modules).where("#{EnabledModule.table_name}.name = 'issue_tracking'").any?
            end
         elsif action == :view_issues && options[:issue].nil?
            return true if Issue.where(:project_id => context).watched_by(self).joins(:project => :enabled_modules).where("#{EnabledModule.table_name}.name = 'issue_tracking'").any?
         end
      end
      return false
   end
end

unless User.included_modules.include?(ExtendedWatchersUserPatch)
   User.send(:prepend, ExtendedWatchersUserPatch)
end
