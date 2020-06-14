# Redmine - project management software
# Copyright (C) 2006-2017  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
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

require File.expand_path('../../test_helper', __FILE__)

class UserTestExtendedWatchers < ActiveSupport::TestCase
  fixtures :users, :email_addresses, :members, :projects, :roles, :member_roles, :auth_sources,
            :trackers, :issue_statuses,
            :projects_trackers,
            :watchers,
            :issue_categories, :enumerations, :issues,
            :journals, :journal_details,
            :groups_users,
            :enabled_modules,
            :tokens

  include Redmine::I18n

  def setup
    @jsmith = User.find(2)  # Manager
    @dlopper = User.find(3) # Developer
  end

  def test_default_allowed_to_for_normal_users
    project = Project.find(1)
    Role.find(2).remove_permission!(:view_issues)
    Issue.find(1).add_watcher(@dlopper)
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'default' } do
      assert_equal false, @dlopper.allowed_to?(:view_issues, project) #Developer
    end
  end

  def test_protected_allowed_to_for_normal_users
    project = Project.find(1)
    Role.find(2).remove_permission!(:view_issues)
    Issue.find(1).add_watcher(@dlopper)
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'protected' } do
      assert_equal false, @dlopper.allowed_to?(:view_issues, project) #Developer
    end
  end
  
  def test_extended_allowed_to_for_normal_users
    project = Project.find(1)
    Role.find(2).remove_permission!(:view_issues)
    Issue.find(1).add_watcher(@dlopper)
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'extended' } do
      assert_equal true, @dlopper.allowed_to?(:view_issues, project) #Developer
    end
  end


  def test_default_allowed_to_for_project_with_module_disabled_should_return_false
    project = Project.find(1)
    Issue.find(1).add_watcher(@jsmith)
    project.enabled_module_names = ["wiki"]
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'default' } do
      assert_equal false, @jsmith.allowed_to?(:view_issues, project)
    end
  end

  def test_protected_allowed_to_for_project_with_module_disabled_should_return_false
    project = Project.find(1)
    Issue.find(1).add_watcher(@jsmith)
    project.enabled_module_names = ["wiki"]
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'protected' } do
      assert_equal false, @jsmith.allowed_to?(:view_issues, project)
    end
  end

  def test_extended_allowed_to_for_project_with_module_disabled_should_return_false
    project = Project.find(1)
    Issue.find(1).add_watcher(@jsmith)
    project.enabled_module_names = ["wiki"]
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'extended' } do
      # watching does not grant additional visibility when disabled modules
      assert_equal false, @jsmith.allowed_to?(:view_issues, project)
    end
  end

  
  def test_default_allowed_to_with_multiple_projects
    projects = [ Project.find(1), Project.find(2) ]
    Issue.find(4).add_watcher(@dlopper)
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'default' } do
      assert_equal false, @dlopper.allowed_to?(:view_issues, projects) #cannot see Project(2)
    end
  end

  def test_protected_allowed_to_with_multiple_projects
    projects = [ Project.find(1), Project.find(2) ]
    Issue.find(4).add_watcher(@dlopper)
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'protected' } do
      assert_equal false, @dlopper.allowed_to?(:view_issues, projects) #cannot see Project(2)
    end
  end

  def test_extended_allowed_to_with_multiple_projects
    projects = [ Project.find(1), Project.find(2) ]
    Issue.find(4).add_watcher(@dlopper)
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'extended' } do
      assert_equal true, @dlopper.allowed_to?(:view_issues, projects) #cannot see Project(2)
    end
  end

end
