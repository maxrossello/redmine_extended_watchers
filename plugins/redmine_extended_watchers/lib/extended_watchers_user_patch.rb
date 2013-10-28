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
      if self.logged? && context && context.is_a?(Project)
        if action.is_a?(Hash)
          if action[:controller] == "issues" && action[:action] == "index"
            Issue.watched_by(self).joins(:project => :enabled_modules).where("#{EnabledModule.table_name}.name = 'issue_tracking'").all.each do |issue|
              return true if issue.project == context
            end
          end
        end
      end
      allowed_to_without_extwatch?(action, context, options, &block)
    end
  end
end