require_dependency 'issue'

module ExtendedWatchersIssuePatch
    
    def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
            unloadable

            alias_method_chain :visible?, :extwatch
        end

        base.instance_eval do
          def visible_condition(user, options={})

            watched_issues = []
            if user.logged?
              user_ids = [user.id] + user.groups.map(&:id)
              watched_issues = Issue.watched_by(user).map(&:id)
            end

            prj_clause = options.nil? || options[:project].nil? ? nil : " #{Project.table_name}.id = #{options[:project].id}"
            prj_clause << " OR (#{Project.table_name}.lft > #{options[:project].lft} AND #{Project.table_name}.rgt < #{options[:project].rgt})" if !options.nil? and options[:with_subprojects]
            watched_group_issues_clause = ""
            watched_group_issues_clause <<  " OR #{table_name}.id IN (#{watched_issues.join(',')}" <<
                (prj_clause.nil? ? "" : " AND ( #{prj_clause} )")  <<
                ")"  unless watched_issues.empty?

            condition = "( " + Project.allowed_to_condition(user, :view_issues, options) do |role, user|
              # Keep the code DRY
              if [ 'default', 'own' ].include?(role.issues_visibility)
                watched_issues_clause = watched_issues.empty? ? "" : " OR #{table_name}.id IN (#{watched_issues.join(',')})"
              end

              if user.logged?
                case role.issues_visibility
                when 'all'
                  nil
                when 'default'
                  "(#{table_name}.is_private = #{connection.quoted_false} OR #{table_name}.author_id = #{user.id} OR #{table_name}.assigned_to_id IN (#{user_ids.join(',')}) #{watched_issues_clause})"
                when 'own'
                  "(#{table_name}.author_id = #{user.id} OR #{table_name}.assigned_to_id IN (#{user_ids.join(',')}) #{watched_issues_clause})"
                else
                  '1=0'
                end
              else
                "(#{table_name}.is_private = #{connection.quoted_false})"
              end
            end + "#{watched_group_issues_clause}) "

            condition
          end
        end
    end

    module InstanceMethods
        def visible_with_extwatch?(usr=nil)
          visible = (usr || User.current).allowed_to?(:view_issues, self.project) do |role, user|
            if user.logged?
              case role.issues_visibility
              when 'all'
                true
              when 'default'
                !self.is_private? || (self.author == user || self.watched_by?(user) || user.is_or_belongs_to?(assigned_to))
              when 'own'
                self.author == user || self.watched_by?(user) || user.is_or_belongs_to?(assigned_to)
              else
                visible_without_extwatch?(usr)
              end
            else
              visible_without_extwatch?(usr)
            end
          end
 
          if !visible && (usr || User.current).logged?
            visible = self.watched_by?(usr || User.current)
          end

          logger.error "visible_with_extwatch #{visible}"
          visible
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

