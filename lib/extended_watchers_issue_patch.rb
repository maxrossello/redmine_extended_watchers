# Extended Watchers plugin for Redmine
# Copyright (C) 2013-2020  Massimo Rossello
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 3
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

require_dependency 'issue'

# including IssueQuery needs the DB to be connected, which may not be the case when 'rails db:create'
begin
#  ActiveRecord::Base.establish_connection
#  ActiveRecord::Base.connection
#  raise 'not connected' unless ActiveRecord::Base.connected?
  require_dependency 'issue_query'
rescue
  return
end



module ExtendedWatchersIssueClassPatch

  def visible_condition(user, options={})
    return super(user, options) if (Setting.plugin_redmine_extended_watchers["policy"] == "default")
      
    watched_issues = []

    prj_clause = options.nil? || options[:project].nil? ? "1=1" : " #{Project.table_name}.id = #{options[:project].id} AND #{Project.table_name}.status != #{Project::STATUS_ARCHIVED}"
    prj_clause << " OR (#{Project.table_name}.lft > #{options[:project].lft} AND #{Project.table_name}.rgt < #{options[:project].rgt} AND #{Project.table_name}.status != #{Project::STATUS_ARCHIVED})" if !options.nil? and !options[:project].nil? and options[:with_subprojects]
    prj_clause = "(" + Project.allowed_to_condition(user, :view_issues) + ") AND (" + prj_clause + ")" if user.id and user.logged? and Setting.plugin_redmine_extended_watchers["policy"] == "protected"
    
    # NOTE: Issue from is aliased to 'subtasks' to cope with IssueQuery's :total_estimated_hours QueryColumn
    watched_issues_clause = " OR ( (#{Issue.table_name}.id IN "+
                                     "("+
                                          #Issue.select(:id).from("#{Issue.table_name} subtasks").joins(:watchers).
                                          Issue.select(:id).joins(:watchers).
                                          where("#{Watcher.table_name}.user_id" => ([user.id] + user.groups.map(&:id).compact)).to_sql +
                                     ")"+
                                  ") AND ( #{prj_clause} )"+
                                ")" if user.id && user.logged?

    "( " + super(user, options) + "#{watched_issues_clause} ) "
  end
  
  # patch act_as_activity_provider
  # postpone :limit option management in case the database can't handle IN+LIMIT into inner query for watchers
  def find_events(event_type, user, from, to, options)
    begin
      super(event_type, user, from, to, options)
    rescue
      provider_options = activity_provider_options[event_type]
      raise "#{self.name} can not provide #{event_type} events." if provider_options.nil?
      
      scope = (provider_options[:scope] || self)
      
      if from && to
        scope = scope.where("#{provider_options[:timestamp]} BETWEEN ? AND ?", from, to)
      end
      
      if options[:author]
        return [] if provider_options[:author_key].nil?
        scope = scope.where("#{provider_options[:author_key]} = ?", options[:author].id)
      end
      
      if provider_options.has_key?(:permission)
        scope = scope.where(Project.allowed_to_condition(user, provider_options[:permission] || :view_project, options))
      elsif respond_to?(:visible)
        scope = scope.visible(user, options)
      else
        ActiveSupport::Deprecation.warn "acts_as_activity_provider with implicit :permission option is deprecated. Add a visible scope to the #{self.name} model or use explicit :permission option."
        scope = scope.where(Project.allowed_to_condition(user, "view_#{self.name.underscore.pluralize}".to_sym, options))
      end
      
      if options[:limit]
        # id and creation time should be in same order in most cases
        scope = scope.reorder("#{table_name}.id DESC").limit(options[:limit])
      end

      scope.to_a
    end
  end

end


module ExtendedWatchersIssueInstancePatch
  
  def visible?(usr=nil)
    return true if Setting.plugin_redmine_extended_watchers["policy"] == "extended" && self.watcher_users.include?(usr || User.current)
      
    (usr || User.current).allowed_to?(:view_issues, self.project, {issue: true}) do |role, user|
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
      visible ||= (Setting.plugin_redmine_extended_watchers["policy"] == "protected" && self.watcher_users.include?(usr || User.current))
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


module ExtendedWatchersIssueQueryClassPatch
  
  extend ActiveSupport::Concern

  included do    
    # IssueQuery replaces 'issues' with 'subtasks' over visible_condition string, to calculate the estimated hours recursively,
    # thus additional statements are compromised.
    # Here extending the substitution to achieve a "FROM issues subtasks" instead of "FROM subtasks" (which does not exist)
    
    index = IssueQuery.available_columns.find_index {|column| column.name == :total_estimated_hours}

    if index
      IssueQuery.available_columns[index] =
        QueryColumn.new(
          :total_estimated_hours,
          :sortable => -> {
            "COALESCE((SELECT SUM(estimated_hours) FROM #{Issue.table_name} subtasks" +
            " WHERE #{Issue.visible_condition(User.current).gsub(/\bissues\b/, 'subtasks').gsub(/FROM +(\"|\`|\')?subtasks[^ ]?/, "FROM #{Issue.table_name} subtasks")}"+
            "       AND subtasks.root_id = #{Issue.table_name}.root_id AND subtasks.lft >= #{Issue.table_name}.lft AND subtasks.rgt <= #{Issue.table_name}.rgt), 0)"
          },
          :default_order => 'desc')
    end
  end
end




unless Issue.included_modules.include?(ExtendedWatchersIssueInstancePatch)
    Issue.send(:prepend, ExtendedWatchersIssueInstancePatch)
end

unless Issue.singleton_class.included_modules.include?(ExtendedWatchersIssueClassPatch)
  Issue.singleton_class.send(:prepend, ExtendedWatchersIssueClassPatch)
end

unless IssueQuery.singleton_class.included_modules.include?(ExtendedWatchersIssueQueryClassPatch)
  IssueQuery.singleton_class.send(:include, ExtendedWatchersIssueQueryClassPatch)
end

