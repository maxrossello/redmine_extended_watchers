require_dependency 'issue'

module ExtendedWatchersIssueClassPatch

  def visible_condition(user, options={})

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
    visible = super(usr)
    return true if visible

    if (usr || User.current).logged?
      visible = self.watched_by?(usr || User.current)
    end

    visible
  end

  # Override the acts_as_watchable default to allow any user with view issues
  # rights to watch/see this issue.
  def addable_watcher_users
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

