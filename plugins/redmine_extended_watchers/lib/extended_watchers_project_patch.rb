require_dependency 'user'

module ExtendedWatchersProjectPatch

  class << Project
    alias visible_condition_old visible_condition
  end

  def self.included(base)
    base.instance_eval do
      def visible_condition(user, options={})
        issues = Issue.watched_by(user).joins(:project => :enabled_modules).where("#{EnabledModule.table_name}.name = 'issue_tracking'")

        if issues.any?
          visible_condition_old(user,options) + " OR #{Project.table_name}.id IN (#{issues.all.collect(&:project_id).join(",")})"
        else
          visible_condition_old(user,options)
        end
      end
    end

  end

end