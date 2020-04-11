require_dependency 'issue'

module ExtendedWatchersIssueClassPatch

  def visible_condition(user, options={})
    return super(user, options) if (Setting.plugin_redmine_extended_watchers["policy"] == "default")
      
    watched_issues = []
    if user.id && user.logged?
      user_ids = [user.id] + user.groups.map(&:id).compact
      watched_issues = Issue.watched_by(user).joins(:project => :enabled_modules).where("#{EnabledModule.table_name}.name = 'issue_tracking'").map(&:id)
    end

    prj_clause = options.nil? || options[:project].nil? ? "1=1" : " #{Project.table_name}.id = #{options[:project].id} AND #{options[:project]}.status != #{Project::STATUS_ARCHIVED}"
    prj_clause << " OR (#{Project.table_name}.lft > #{options[:project].lft} AND #{Project.table_name}.rgt < #{options[:project].rgt} AND #{options[:project]}.status != #{Project::STATUS_ARCHIVED})" if !options.nil? and !options[:project].nil? and options[:with_subprojects]
    watched_group_issues_clause = ""
    watched_group_issues_clause <<  " OR #{table_name}.id IN (#{watched_issues.join(',')}) AND ( #{prj_clause} )" unless watched_issues.empty?

    "( " + super(user, options) + "#{watched_group_issues_clause}) "
  end
end


module ExtendedWatchersIssueInstancePatch
  
  def visible?(usr=nil)
    self.watcher_users.include?(usr || User.current) || (usr || User.current).allowed_to?(:view_issues, self.project, {issue: true}) do |role, user|
       visible = if user.logged?
         case role.issues_visibility
         when 'all'
           true
         when 'default'
           !self.is_private? || (self.author == user || user.is_or_belongs_to?(assigned_to))
         when 'own'
           self.author == user || user.is_or_belongs_to?(assigned_to)
         else
           false
         end
       else
         !self.is_private?
       end
       unless role.permissions_all_trackers?(:view_issues)
         visible &&= role.permissions_tracker_ids?(:view_issues, tracker_id)
       end
       visible ||= (Setting.plugin_redmine_extended_watchers["policy"] == "extended" &&
          self.watcher_users.include?(usr || User.current))
       visible
     end
  end

  # Override the acts_as_watchable default to allow any user with view issues
  # rights to watch/see this issue.
  def addable_watcher_users
    return super if Setting.plugin_redmine_extended_watchers["policy"] == "default"
      
    users = self.project.users.sort - self.watcher_users
    users.reject! {|user| !user.allowed_to?(:view_issues, self.project)}
    users
  end
        
end


unless Issue.included_modules.include?(ExtendedWatchersIssueInstancePatch)
    Issue.send(:prepend, ExtendedWatchersIssueInstancePatch)
end

unless Issue.singleton_class.included_modules.include?(ExtendedWatchersIssueClassPatch)
  Issue.singleton_class.send(:prepend, ExtendedWatchersIssueClassPatch)
end

