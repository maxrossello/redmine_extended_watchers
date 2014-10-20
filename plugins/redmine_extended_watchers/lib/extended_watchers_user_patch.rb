require_dependency 'user'

module ExtendedWatchersUserPatch

  def self.included(base)
    base.send(:include, InstanceMethods)
    base.class_eval do
      unloadable

      alias_method_chain :allowed_to?, :extwatch
    end
  end

  module InstanceMethods
    def allowed_to_with_extwatch?(action, context, options={}, &block)
      is_allowed = allowed_to_without_extwatch?(action, context, options, &block)
      return true if is_allowed

      if (options[:watchers].nil? || options[:watchers]) && self.logged? && context && context.is_a?(Project)
        if action.is_a?(Hash)
          if action[:controller] == "issues" && action[:action] == "index"
            return true if Issue.where(:project_id => context).watched_by(self).joins(:project => :enabled_modules).where("#{EnabledModule.table_name}.name = 'issue_tracking'").any?
          end
        elsif action == :view_issues
          return true if Issue.where(:project_id => context).watched_by(self).joins(:project => :enabled_modules).where("#{EnabledModule.table_name}.name = 'issue_tracking'").any?
        end
      end
      return false
    end
  end
end
