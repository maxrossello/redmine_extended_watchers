require_dependency 'user'

module ExtendedWatchersUserPatch

    def allowed_to?(action, context, options={}, &block)
      is_allowed = super(action, context, options, &block)
      return true if is_allowed

      if (options[:watchers].nil? || options[:watchers]) && self.logged? && context && context.is_a?(Project)
        if action.is_a?(Hash)
          if action[:controller] == "issues" && action[:action] == "index"
            return true if Issue.where(:project_id => context).watched_by(self).joins(:project => :enabled_modules).where("#{EnabledModule.table_name}.name = 'issue_tracking'").any?
          end
        elsif action == :view_issues && !context.archived?
          return true if Issue.where(:project_id => context).watched_by(self).joins(:project => :enabled_modules).where("#{EnabledModule.table_name}.name = 'issue_tracking'").any?
        end
      end
      return false
    end
end

unless User.included_modules.include?(ExtendedWatchersUserPatch)
    User.send(:include, ExtendedWatchersUserPatch)
end
