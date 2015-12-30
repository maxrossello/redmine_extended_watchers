require_dependency 'issue'

module ExtendedWatchersIssuePatch

    def self.included(base)
        base.send(:include, InstanceMethods)
        base.extend ClassMethods
        base.class_eval do
            unloadable

            alias_method_chain :visible?, :extwatch
            class << self
              alias_method_chain :visible_condition, :extwatch
            end

        end

    end

    module ClassMethods
      def visible_condition_with_extwatch(user, options={})

        watched_issues = []
        if user.logged?
          user_ids = [user.id] + user.groups.map(&:id).compact
          watched_issues = Issue.watched_by(user).joins(:project => :enabled_modules).where("#{EnabledModule.table_name}.name = 'issue_tracking'").map(&:id)

        end

        prj_clause = options.nil? || options[:project].nil? ? nil : " #{Project.table_name}.id = #{options[:project].id}"
        prj_clause << " OR (#{Project.table_name}.lft > #{options[:project].lft} AND #{Project.table_name}.rgt < #{options[:project].rgt})" if !options.nil? and !options[:project].nil? and options[:with_subprojects]
        watched_group_issues_clause = ""
        watched_group_issues_clause <<  " OR #{table_name}.id IN (#{watched_issues.join(',')})" <<
            (prj_clause.nil? ? "" : " AND ( #{prj_clause} )") unless watched_issues.empty?

        "( " + visible_condition_without_extwatch(user, options) + "#{watched_group_issues_clause}) "

      end
    end

    module InstanceMethods
        def visible_with_extwatch?(usr=nil)
          visible = visible_without_extwatch?(usr)
          return true if visible

          if (usr || User.current).logged?
            visible =  self.watched_by?(usr)
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

