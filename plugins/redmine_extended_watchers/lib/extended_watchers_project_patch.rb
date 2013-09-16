require_dependency 'user'

module ExtendedWatchersProjectPatch

  class << Project
    alias visible_condition_old visible_condition
  end

  def self.included(base)
    base.instance_eval do
      def visible_condition(user, options={})
        visible_condition_old(user,options) + " OR #{Project.table_name}.id IN (#{Issue.visible.watched_by(user).all.collect(&:project_id).join(",")})"
      end
    end

  end

end