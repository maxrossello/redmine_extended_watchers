require_dependency 'issue'

module ExtendedWatchersIssuePatch
    
    def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
            unloadable

            named_scope :visible, lambda {|*args| { :include => [:project, :watchers],
                                                    :conditions => Issue.visible_condition(args.shift || User.current, *args) } }

            alias_method_chain :visible?, :extwatch
        end

        base.instance_eval do
          def visible_condition(user, options={})
            Project.allowed_to_condition(user, :view_issues, options) do |role, user|
              case role.issues_visibility
                when 'all'
                  nil
                when 'default'
                  user_ids = [user.id] + user.groups.map(&:id)
                  "(#{table_name}.is_private = #{connection.quoted_false} OR #{table_name}.author_id = #{user.id} OR #{Watcher.table_name}.user_id = #{user.id} OR #{table_name}.assigned_to_id IN (#{user_ids.join(',')}))"
                when 'own'
                  user_ids = [user.id] + user.groups.map(&:id)
                  "(#{table_name}.author_id = #{user.id} OR #{Watcher.table_name}.user_id = #{user.id} OR #{table_name}.assigned_to_id IN (#{user_ids.join(',')}))"
                else
                  '1=0'
                end
            end
          end

        end
    end

    module InstanceMethods
        def visible_with_extwatch?(usr=nil)
          (usr || User.current).allowed_to?(:view_issues, self.project) do |role, user|
            case role.issues_visibility
              when 'default'
                !self.is_private? || self.author == user || self.watched_by?(user) || user.is_or_belongs_to?(assigned_to)
              when 'own'
                self.author == user || self.watched_by?(user) || user.is_or_belongs_to?(assigned_to)
              else
                visible_without_extwatch?(usr)
            end
          end
        end

        # Override the acts_as_watchble default to allow any user with view issues
        # rights to watch/see this issue.
        def addable_watcher_users
          users = self.project.users.sort - self.watcher_users
          users.reject! {|user| !user.allowed_to?(:view_issues, self.project)}
          users
        end
        
    end

end

