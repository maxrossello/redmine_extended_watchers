# Redmine - project management software
# Copyright (C) 2006-2017  Jean-Philippe Lang
# Copyright (C) 2013-  Massimo Rossello
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

require_relative '../test_helper'

class IssueTestExtendedWatchers < ActiveSupport::TestCase
  fixtures :projects, :users, :email_addresses, :user_preferences, :members, :member_roles, :roles,
           :groups_users,
           :trackers, :projects_trackers,
           :enabled_modules,
           :versions,
           :issue_statuses, :issue_categories, :issue_relations, :workflows,
           :enumerations,
           :issues, :journals, :journal_details,
           :watchers,
           :custom_fields, :custom_fields_projects, :custom_fields_trackers, :custom_values,
           :time_entries

  include Redmine::I18n

  def setup
    set_language_if_valid 'en'
    @ppublic = Project.generate!(:name => "public", :is_public => true)
    @pprivate = Project.generate!(:name => "private", :is_public => false)

    @ipupu = Issue.generate!(:project => @ppublic, :is_private => false, :subject => 'Public in public')
    @ipupr = Issue.generate!(:project => @ppublic, :is_private => true, :subject => 'Private in public')
    @iprpu = Issue.generate!(:project => @pprivate, :is_private => false, :subject => 'Public in private')
    @iprpr = Issue.generate!(:project => @pprivate, :is_private => true, :subject => 'Private in private')
  end

  def teardown
    User.current = nil
  end

  def assert_visibility_match(user, issues)
    assert_equal issues.collect(&:id).sort, Issue.all.select {|issue| issue.visible?(user)}.collect(&:id).sort
  end

  def test_default_visible_scope_for_non_member
    user = User.find(9)
    assert user.projects.empty?
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'default' } do
      # Non member user should see issues of public projects only
      issues = Issue.visible(user).to_a
      assert issues.any?
      assert_nil issues.detect {|issue| !issue.project.is_public?}
      assert_nil issues.detect {|issue| issue.is_private?}
      assert_visibility_match user, issues
      
      # even if watching
      @ipupu.add_watcher(user)
      @ipupr.add_watcher(user)
      @iprpu.add_watcher(user)
      @iprpr.add_watcher(user)
      issues = Issue.visible(user).to_a
      assert_nil issues.detect {|issue| !issue.project.is_public?}
      assert_nil issues.detect {|issue| issue.is_private?}
      assert_visibility_match user, issues

      # and nonmember has no :view_issues permission
      Role.non_member.remove_permission!(:view_issues)
      user.reload
      issues = Issue.visible(user).to_a
      assert_nil issues.detect {|issue| !issue.project.is_public?}
      assert_nil issues.detect {|issue| issue.is_private?}
      assert_visibility_match user, issues
    end
  end

  def test_protected_visible_scope_for_non_member
    user = User.find(9)
    assert user.projects.empty?
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'protected' } do
      # Non member user should see issues of public projects only
      issues = Issue.visible(user).to_a
      assert issues.any?
      assert_nil issues.detect {|issue| !issue.project.is_public?}
      assert_nil issues.detect {|issue| issue.is_private?}
      assert_visibility_match user, issues
      
      # unless watching
      @ipupu.add_watcher(user)
      @ipupr.add_watcher(user)
      @iprpu.add_watcher(user)
      @iprpr.add_watcher(user)
      issues = Issue.visible(user).to_a
      assert_nil issues.detect {|issue| !issue.project.is_public?}
      assert_equal 1, issues.count {|issue| issue.is_private?} # watched private issue in public project
      assert_visibility_match user, issues

      # unless nonmember has no :view_issues permission
      Role.non_member.remove_permission!(:view_issues)
      user.reload
      issues = Issue.visible(user).to_a
      assert_nil issues.detect {|issue| !issue.project.is_public?}
      assert_nil issues.detect {|issue| issue.is_private?}
      assert_visibility_match user, issues
    end
  end

  def test_extended_visible_scope_for_non_member
    user = User.find(9)
    assert user.projects.empty?
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'extended' } do
      # Non member user should see issues of public projects only
      issues = Issue.visible(user).to_a
      assert issues.any?
      assert_nil issues.detect {|issue| !issue.project.is_public?}
      assert_nil issues.detect {|issue| issue.is_private?}
      assert_visibility_match user, issues
      
      # unless watching
      @ipupu.add_watcher(user)
      @ipupr.add_watcher(user)
      @iprpu.add_watcher(user)
      @iprpr.add_watcher(user)
      issues = Issue.visible(user).to_a
      assert_equal 2, issues.count{|issue| !issue.project.is_public?}
      assert_equal 2, issues.count {|issue| issue.is_private?}
      assert_visibility_match user, issues

      # even if nonmember has no :view_issues permission
      Role.non_member.remove_permission!(:view_issues)
      user.reload
      issues = Issue.visible(user).to_a
      assert_equal 2, issues.count {|issue| !issue.project.is_public?}
      assert_equal 2, issues.count {|issue| issue.is_private?}
      assert_visibility_match user, issues
    end
  end

  
  def test_default_visible_scope_for_non_member_with_own_issues_visibility
    Role.non_member.update! :issues_visibility => 'own'
    Issue.create!(:project_id => @ppublic, :tracker_id => 1, :author_id => 9, :subject => 'Issue by non member')
    Issue.create!(:project_id => @pprivate, :tracker_id => 1, :author_id => 9, :subject => 'Issue by non member')
    user = User.find(9)

    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'default' } do
      issues = Issue.visible(user).to_a
      assert issues.any?
      assert_nil issues.detect {|issue| issue.author != user}
      assert_visibility_match user, issues
      
      # even if watching
      @ipupu.add_watcher(user)
      @ipupr.add_watcher(user)
      @iprpu.add_watcher(user)
      @iprpr.add_watcher(user)
      issues = Issue.visible(user).to_a
      assert issues.any?
      assert_nil issues.detect {|issue| issue.author != user}
      assert_visibility_match user, issues

      # and nonmember has no :view_issues permission
      Role.non_member.remove_permission!(:view_issues)
      user.reload
      issues = Issue.visible(user).to_a
      assert !issues.any?
      assert_nil issues.detect {|issue| issue.author != user}
      assert_visibility_match user, issues
    end
  end

  def test_protected_visible_scope_for_non_member_with_own_issues_visibility
    Role.non_member.update! :issues_visibility => 'own'
    Issue.create!(:project_id => @ppublic, :tracker_id => 1, :author_id => 9, :subject => 'Issue by non member')
    Issue.create!(:project_id => @pprivate, :tracker_id => 1, :author_id => 9, :subject => 'Issue by non member')
    user = User.find(9)

    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'protected' } do
      issues = Issue.visible(user).to_a
      assert issues.any?
      assert_nil issues.detect {|issue| issue.author != user}
      assert_visibility_match user, issues
      
      # unless if watching
      @ipupu.add_watcher(user)
      @ipupr.add_watcher(user)
      @iprpu.add_watcher(user)
      @iprpr.add_watcher(user)
      issues = Issue.visible(user).to_a
      assert_equal 2, issues.count {|issue| issue.author != user} # 2 watched in public project
      assert_nil issues.detect{|issue| !issue.project.is_public?}
      assert_equal 1, issues.count {|issue| issue.is_private?} # watched private issue in public project
      assert_visibility_match user, issues

      # unless nonmember has no :view_issues permission
      Role.non_member.remove_permission!(:view_issues)
      user.reload
      issues = Issue.visible(user).to_a
      assert !issues.any?
      assert_nil issues.detect {|issue| issue.author != user}
      assert_visibility_match user, issues
    end
  end

  def test_extended_visible_scope_for_non_member_with_own_issues_visibility
    Role.non_member.update! :issues_visibility => 'own'
    Issue.create!(:project_id => @ppublic, :tracker_id => 1, :author_id => 9, :subject => 'Issue by non member')
    Issue.create!(:project_id => @pprivate, :tracker_id => 1, :author_id => 9, :subject => 'Issue by non member')
    user = User.find(9)

    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'extended' } do
      issues = Issue.visible(user).to_a
      assert issues.any?
      assert_nil issues.detect {|issue| issue.author != user}
      assert_visibility_match user, issues
      
      # unless if watching
      @ipupu.add_watcher(user)
      @ipupr.add_watcher(user)
      @iprpu.add_watcher(user)
      @iprpr.add_watcher(user)
      issues = Issue.visible(user).to_a
      assert_equal 2, issues.count {|issue| !issue.project.is_public?}
      assert_equal 2, issues.count {|issue| issue.is_private?}
      assert_visibility_match user, issues

      # even if nonmember has no :view_issues permission
      Role.non_member.remove_permission!(:view_issues)
      user.reload
      issues = Issue.visible(user).to_a
      assert_equal 2, issues.count {|issue| !issue.project.is_public?}
      assert_equal 2, issues.count {|issue| issue.is_private?}
      assert_visibility_match user, issues
    end
  end
  
  
  def test_default_visible_scope_for_member_of_public_project
    user = User.find(9)
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'default' } do
      # User should see issues of projects for which user has view_issues permissions only
      Role.non_member.remove_permission!(:view_issues)
      Member.create!(:principal => user, :project_id => @ppublic.id, :role_ids => [2])
      issues = Issue.visible(user).to_a
      assert issues.any?
      assert_nil issues.detect {|issue| issue.project_id != @ppublic.id}
      assert_nil issues.detect {|issue| issue.is_private?}
      assert_visibility_match user, issues

      # even if watching
      @ipupu.add_watcher(user)
      @ipupr.add_watcher(user)
      issues = Issue.visible(user).to_a
      assert issues.any?
      assert_nil issues.detect {|issue| issue.project_id != @ppublic.id}
      assert_nil issues.detect {|issue| issue.is_private?}
      assert_visibility_match user, issues
    end
  end

  def test_protected_visible_scope_for_member_of_public_project
    user = User.find(9)
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'protected' } do
      # User should see issues of projects for which user has view_issues permissions only
      Role.non_member.remove_permission!(:view_issues)
      Member.create!(:principal => user, :project_id => @ppublic.id, :role_ids => [2])
      issues = Issue.visible(user).to_a
      assert issues.any?
      assert_nil issues.detect {|issue| issue.project_id != @ppublic.id}
      assert_nil issues.detect {|issue| issue.is_private?}
      assert_visibility_match user, issues

      # unless watching
      @ipupu.add_watcher(user)
      @ipupr.add_watcher(user)
      issues = Issue.visible(user).to_a
      assert issues.any?
      assert_nil issues.detect {|issue| issue.project_id != @ppublic.id}
      assert_equal 1, issues.count {|issue| issue.is_private?}
      assert_visibility_match user, issues
    end
  end

  def test_extended_visible_scope_for_member_of_public_project
    user = User.find(9)
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'extended' } do
      # User should see issues of projects for which user has view_issues permissions only
      Role.non_member.remove_permission!(:view_issues)
      Member.create!(:principal => user, :project_id => @ppublic.id, :role_ids => [2])
      issues = Issue.visible(user).to_a
      assert issues.any?
      assert_nil issues.detect {|issue| issue.project_id != @ppublic.id}
      assert_nil issues.detect {|issue| issue.is_private?}
      assert_visibility_match user, issues

      # unless watching
      @ipupu.add_watcher(user)
      @ipupr.add_watcher(user)
      issues = Issue.visible(user).to_a
      assert issues.any?
      assert_nil issues.detect {|issue| issue.project_id != @ppublic.id}
      assert_equal 1, issues.count {|issue| issue.is_private?}
      assert_visibility_match user, issues
    end
  end

  
  def test_default_visible_scope_for_member_without_view_issues_permission_and_non_member_role_having_the_permission
    Role.non_member.add_permission!(:view_issues)
    Role.find(1).remove_permission!(:view_issues)
    user = User.find(2)
    Member.create!(:principal => user, :project_id => @ppublic.id, :role_ids => [1])

    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'default' } do
      assert_equal 0, Issue.where(:project_id => @ppublic.id).visible(user).count
      assert_equal false, Issue.where(:project_id => @ppublic.id).first.visible?(user)
      
      # even if watching
      @ipupu.add_watcher(user)
      @ipupr.add_watcher(user)
      assert_equal 0, Issue.where(:project_id => @ppublic.id).visible(user).count
      assert_equal false, Issue.where(:project_id => @ppublic.id).first.visible?(user)
    end
  end

  def test_protected_visible_scope_for_member_without_view_issues_permission_and_non_member_role_having_the_permission
    Role.non_member.add_permission!(:view_issues)
    Role.find(1).remove_permission!(:view_issues)
    user = User.find(2)
    Member.create!(:principal => user, :project_id => @ppublic.id, :role_ids => [1])

    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'protected' } do
      assert_equal 0, Issue.where(:project_id => @ppublic.id).visible(user).count
      assert_equal false, Issue.where(:project_id => @ppublic.id).first.visible?(user)
      
      # even if watching (nonmember permission is not considered when user has any role)
      @ipupu.add_watcher(user)
      @ipupr.add_watcher(user)
      assert_equal 0, Issue.where(:project_id => @ppublic.id).visible(user).count
      assert_equal false, Issue.where(:project_id => @ppublic.id).first.visible?(user)
    end
  end

  def test_extended_visible_scope_for_member_without_view_issues_permission_and_non_member_role_having_the_permission
    Role.non_member.add_permission!(:view_issues)
    Role.find(1).remove_permission!(:view_issues)
    user = User.find(2)
    Member.create!(:principal => user, :project_id => @ppublic.id, :role_ids => [1])

    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'extended' } do
      assert_equal 0, Issue.where(:project_id => @ppublic.id).visible(user).count
      assert_equal false, Issue.where(:project_id => @ppublic.id).first.visible?(user)

      # unless watching
      @ipupu.add_watcher(user)
      @ipupr.add_watcher(user)
      assert_equal 2, Issue.where(:project_id => @ppublic.id).visible(user).count
      assert_equal true, Issue.where(:project_id => @ppublic.id).first.visible?(user)
    end
  end
  
  
  def test_default_visible_scope_with_custom_non_member_role_having_restricted_permission
    role = Role.generate!(:permissions => [:view_project])
    assert Role.non_member.has_permission?(:view_issues)
    user = User.generate!
    Member.create!(:principal => Group.non_member, :project_id => @ppublic.id, :roles => [role])

    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'default' } do
      issues = Issue.visible(user).to_a
      assert issues.any?
      assert_nil issues.detect {|issue| issue.project_id == @ppublic.id}
        
      # even if watching
      @ipupu.add_watcher(user)
      @ipupr.add_watcher(user)
      issues = Issue.visible(user).to_a
      assert issues.any?
      assert_nil issues.detect {|issue| issue.project_id == @ppublic.id}
    end
  end

  def test_protected_visible_scope_with_custom_non_member_role_having_restricted_permission
    role = Role.generate!(:permissions => [:view_project])
    assert Role.non_member.has_permission?(:view_issues)
    user = User.generate!
    Member.create!(:principal => Group.non_member, :project_id => @ppublic.id, :roles => [role])

    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'protected' } do
      issues = Issue.visible(user).to_a
      assert issues.any?
      assert_nil issues.detect {|issue| issue.project_id == @ppublic.id}
      
      # even if watching (nonmember permission is not considered when user has any role)
      @ipupu.add_watcher(user)
      @ipupr.add_watcher(user)
      issues = Issue.visible(user).to_a
      assert issues.any?
      assert_nil issues.detect {|issue| issue.project_id == @ppublic.id}
    end
  end

  def test_extended_visible_scope_with_custom_non_member_role_having_restricted_permission
    role = Role.generate!(:permissions => [:view_project])
    assert Role.non_member.has_permission?(:view_issues)
    user = User.generate!
    Member.create!(:principal => Group.non_member, :project_id => @ppublic.id, :roles => [role])

    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'extended' } do
      issues = Issue.visible(user).to_a
      assert issues.any?
      assert_nil issues.detect {|issue| issue.project_id == @ppublic.id}
      
      # unless watching
      @ipupu.add_watcher(user)
      @ipupr.add_watcher(user)
      issues = Issue.visible(user).to_a
      assert issues.any?
      assert_equal 2, issues.count {|issue| issue.project_id == @ppublic.id}
    end
  end
  
  
  def test_default_visible_scope_with_custom_non_member_role_having_extended_permission
    role = Role.generate!(:permissions => [:view_project, :view_issues])
    Role.non_member.remove_permission!(:view_issues)
    user = User.generate!
    Member.create!(:principal => Group.non_member, :project_id => 1, :roles => [role])

    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'default' } do
      issues = Issue.visible(user).to_a
      assert issues.any?
      assert_not_nil issues.detect {|issue| issue.project_id == 1}
    end
  end

  def test_protected_visible_scope_with_custom_non_member_role_having_extended_permission
    role = Role.generate!(:permissions => [:view_project, :view_issues])
    Role.non_member.remove_permission!(:view_issues)
    user = User.generate!
    Member.create!(:principal => Group.non_member, :project_id => 1, :roles => [role])

    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'protected' } do
      issues = Issue.visible(user).to_a
      assert issues.any?
      assert_not_nil issues.detect {|issue| issue.project_id == 1}
    end
  end

  def test_extended_visible_scope_with_custom_non_member_role_having_extended_permission
    role = Role.generate!(:permissions => [:view_project, :view_issues])
    Role.non_member.remove_permission!(:view_issues)
    user = User.generate!
    Member.create!(:principal => Group.non_member, :project_id => 1, :roles => [role])

    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'extended' } do
      issues = Issue.visible(user).to_a
      assert issues.any?
      assert_not_nil issues.detect {|issue| issue.project_id == 1}
    end
  end
  
  
  def test_default_visible_scope_for_member_with_groups_should_return_assigned_issues
    user = User.find(8)
    assert user.groups.any?
    group = user.groups.first
    Member.create!(:principal => group, :project_id => 1, :role_ids => [2])
    Role.non_member.remove_permission!(:view_issues)

    with_settings :issue_group_assignment => '1' do
      issue = Issue.create!(:project_id => 1, :tracker_id => 1, :author_id => 3,
        :status_id => 1, :priority => IssuePriority.all.first,
        :subject => 'Assignment test',
        :assigned_to => group,
        :is_private => true)

      with_settings :plugin_redmine_extended_watchers => { 'policy' => 'default' } do
        Role.find(2).update! :issues_visibility => 'default'
        issues = Issue.visible(User.find(8)).to_a
        assert issues.any?
        assert issues.include?(issue)

        Role.find(2).update! :issues_visibility => 'own'
        issues = Issue.visible(User.find(8)).to_a
        assert issues.any?
        assert_include issue, issues
      end
    end
  end

  def test_protected_visible_scope_for_member_with_groups_should_return_assigned_issues
    user = User.find(8)
    assert user.groups.any?
    group = user.groups.first
    Member.create!(:principal => group, :project_id => 1, :role_ids => [2])
    Role.non_member.remove_permission!(:view_issues)
  
    with_settings :issue_group_assignment => '1' do
      issue = Issue.create!(:project_id => 1, :tracker_id => 1, :author_id => 3,
        :status_id => 1, :priority => IssuePriority.all.first,
        :subject => 'Assignment test',
        :assigned_to => group,
        :is_private => true)
  
      with_settings :plugin_redmine_extended_watchers => { 'policy' => 'protected' } do
        Role.find(2).update! :issues_visibility => 'default'
        issues = Issue.visible(User.find(8)).to_a
        assert issues.any?
        assert issues.include?(issue)
  
        Role.find(2).update! :issues_visibility => 'own'
        issues = Issue.visible(User.find(8)).to_a
        assert issues.any?
        assert_include issue, issues
      end
    end
  end
  
  def test_extended_visible_scope_for_member_with_groups_should_return_assigned_issues
    user = User.find(8)
    assert user.groups.any?
    group = user.groups.first
    Member.create!(:principal => group, :project_id => 1, :role_ids => [2])
    Role.non_member.remove_permission!(:view_issues)
  
    with_settings :issue_group_assignment => '1' do
      issue = Issue.create!(:project_id => 1, :tracker_id => 1, :author_id => 3,
        :status_id => 1, :priority => IssuePriority.all.first,
        :subject => 'Assignment test',
        :assigned_to => group,
        :is_private => true)
  
      with_settings :plugin_redmine_extended_watchers => { 'policy' => 'extended' } do
        Role.find(2).update! :issues_visibility => 'default'
        issues = Issue.visible(User.find(8)).to_a
        assert issues.any?
        assert issues.include?(issue)
  
        Role.find(2).update! :issues_visibility => 'own'
        issues = Issue.visible(User.find(8)).to_a
        assert issues.any?
        assert_include issue, issues
      end
    end
  end
  
  
  def test_default_visible_scope_for_member_with_limited_tracker_ids
    role = Role.find(1)
    role.set_permission_trackers :view_issues, [2]
    role.save!
    user = User.find(2)
    Member.create!(:principal => user, :project_id => @ppublic.id, :role_ids => [1])
    i1 = Issue.generate!(:project => @ppublic, :is_private => false, :subject => 'Tracker 1', :tracker_id => 3)
    i2 = Issue.generate!(:project => @ppublic, :is_private => false, :subject => 'Tracker 2', :tracker_id => 2)

    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'default' } do
      issues = Issue.where(:project_id => @ppublic.id).visible(user).to_a
      assert issues.any?
      assert_equal [2], issues.map(&:tracker_id).uniq

      assert Issue.where(:project_id => @ppublic.id).all? {|issue| issue.visible?(user) ^ issue.tracker_id != 2}
        
      # watching does not change behavior
      i1.add_watcher(user)
      issues = Issue.where(:project_id => @ppublic.id).visible(user).to_a
      assert_equal [2], issues.map(&:tracker_id).uniq
      assert Issue.where(:project_id => @ppublic.id).all? {|issue| issue.visible?(user) ^ issue.tracker_id != 2}
    end
  end

  def test_protected_visible_scope_for_member_with_limited_tracker_ids
    role = Role.find(1)
    role.set_permission_trackers :view_issues, [2]
    role.save!
    user = User.find(2)
    Member.create!(:principal => user, :project_id => @ppublic.id, :role_ids => [1])
    i1 = Issue.generate!(:project => @ppublic, :is_private => false, :subject => 'Tracker 1', :tracker_id => 3)
    i2 = Issue.generate!(:project => @ppublic, :is_private => false, :subject => 'Tracker 2', :tracker_id => 2)
  
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'protected' } do
      issues = Issue.where(:project_id => @ppublic.id).visible(user).to_a
      assert issues.any?
      assert_equal [2], issues.map(&:tracker_id).uniq
  
      assert Issue.where(:project_id => @ppublic.id).all? {|issue| issue.visible?(user) ^ issue.tracker_id != 2}
  
      # watching changes behavior
      i1.add_watcher(user)
      issues = Issue.where(:project_id => @ppublic.id).visible(user).to_a
      assert_equal [2,3], issues.map(&:tracker_id).uniq.sort
      assert Issue.where(:project_id => @ppublic.id).all? {|issue| issue.visible?(user) ^ (issue.tracker_id != 2 && issue.tracker_id != 3)}
    end
  end

  def test_extended_visible_scope_for_member_with_limited_tracker_ids
    role = Role.find(1)
    role.set_permission_trackers :view_issues, [2]
    role.save!
    user = User.find(2)
    Member.create!(:principal => user, :project_id => @ppublic.id, :role_ids => [1])
    i1 = Issue.generate!(:project => @ppublic, :is_private => false, :subject => 'Tracker 1', :tracker_id => 3)
    i2 = Issue.generate!(:project => @ppublic, :is_private => false, :subject => 'Tracker 2', :tracker_id => 2)
  
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'extended' } do
      issues = Issue.where(:project_id => @ppublic.id).visible(user).to_a
      assert issues.any?
      assert_equal [2], issues.map(&:tracker_id).uniq
  
      assert Issue.where(:project_id => @ppublic.id).all? {|issue| issue.visible?(user) ^ issue.tracker_id != 2}
  
      # watching changes behavior
      i1.add_watcher(user)
      issues = Issue.where(:project_id => @ppublic.id).visible(user).to_a
      assert_equal [2,3], issues.map(&:tracker_id).uniq.sort
      assert Issue.where(:project_id => @ppublic.id).all? {|issue| issue.visible?(user) ^ (issue.tracker_id != 2 && issue.tracker_id != 3)}
    end
  end

  
  def test_default_visible_scope_should_consider_tracker_ids_on_each_project
    user = User.generate!

    project1 = Project.generate!
    role1 = Role.generate!
    role1.add_permission! :view_issues
    role1.set_permission_trackers :view_issues, :all
    role1.save!
    User.add_to_project(user, project1, role1)

    project2 = Project.generate!
    role2 = Role.generate!
    role2.add_permission! :view_issues
    role2.set_permission_trackers :view_issues, [2]
    role2.save!
    User.add_to_project(user, project2, role2)

    visible_issues = [
      Issue.generate!(:project => project1, :tracker_id => 1),
      Issue.generate!(:project => project1, :tracker_id => 2),
      Issue.generate!(:project => project2, :tracker_id => 2)
    ]
    hidden_issue = Issue.generate!(:project => project2, :tracker_id => 1)

    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'default' } do
      issues = Issue.where(:project_id => [project1.id, project2.id]).visible(user)
      assert_equal visible_issues.map(&:id), issues.ids.sort

      assert visible_issues.all? {|issue| issue.visible?(user)}
      assert !hidden_issue.visible?(user)
      
      # watching does not change behavior
      hidden_issue.add_watcher(user)
      
      issues = Issue.where(:project_id => [project1.id, project2.id]).visible(user)
      assert_equal visible_issues.map(&:id), issues.ids.sort
      
      assert visible_issues.all? {|issue| issue.visible?(user)}
      assert !hidden_issue.visible?(user)
    end
  end

  def test_protected_visible_scope_should_not_consider_tracker_ids_on_each_project_when_watched
    user = User.generate!
  
    project1 = Project.generate!
    role1 = Role.generate!
    role1.add_permission! :view_issues
    role1.set_permission_trackers :view_issues, :all
    role1.save!
    User.add_to_project(user, project1, role1)
  
    project2 = Project.generate!
    role2 = Role.generate!
    role2.add_permission! :view_issues
    role2.set_permission_trackers :view_issues, [2]
    role2.save!
    User.add_to_project(user, project2, role2)
  
    visible_issues = [
      Issue.generate!(:project => project1, :tracker_id => 1),
      Issue.generate!(:project => project1, :tracker_id => 2),
      Issue.generate!(:project => project2, :tracker_id => 2)
    ]
    hidden_issue = Issue.generate!(:project => project2, :tracker_id => 1)
  
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'protected' } do
      issues = Issue.where(:project_id => [project1.id, project2.id]).visible(user)
      assert_equal visible_issues.map(&:id), issues.ids.sort
  
      assert visible_issues.all? {|issue| issue.visible?(user)}
      assert !hidden_issue.visible?(user)
      
      # watching changes behavior
      hidden_issue.add_watcher(user)
      
      issues = Issue.where(:project_id => [project1.id, project2.id]).visible(user)
      assert_equal (visible_issues + [hidden_issue]).map(&:id), issues.ids.sort
      
      assert (visible_issues + [hidden_issue]).all? {|issue| issue.visible?(user)}
      assert hidden_issue.visible?(user)
    end
  end
  
  def test_extended_visible_scope_should_not_consider_tracker_ids_on_each_project_when_watched
    user = User.generate!
  
    project1 = Project.generate!
    role1 = Role.generate!
    role1.add_permission! :view_issues
    role1.set_permission_trackers :view_issues, :all
    role1.save!
    User.add_to_project(user, project1, role1)
  
    project2 = Project.generate!
    role2 = Role.generate!
    role2.add_permission! :view_issues
    role2.set_permission_trackers :view_issues, [2]
    role2.save!
    User.add_to_project(user, project2, role2)
  
    visible_issues = [
      Issue.generate!(:project => project1, :tracker_id => 1),
      Issue.generate!(:project => project1, :tracker_id => 2),
      Issue.generate!(:project => project2, :tracker_id => 2)
    ]
    hidden_issue = Issue.generate!(:project => project2, :tracker_id => 1)
  
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'extended' } do
      issues = Issue.where(:project_id => [project1.id, project2.id]).visible(user)
      assert_equal visible_issues.map(&:id), issues.ids.sort
  
      assert visible_issues.all? {|issue| issue.visible?(user)}
      assert !hidden_issue.visible?(user)
      
      # watching changes behavior
      hidden_issue.add_watcher(user)
      
      issues = Issue.where(:project_id => [project1.id, project2.id]).visible(user)
      assert_equal (visible_issues + [hidden_issue]).map(&:id), issues.ids.sort
      
      assert (visible_issues + [hidden_issue]).all? {|issue| issue.visible?(user)}
      assert hidden_issue.visible?(user)
    end
  end

  
  def test_default_visible_scope_should_not_consider_roles_without_view_issues_permission
    user = User.generate!
    role1 = Role.generate!
    role1.remove_permission! :view_issues
    role1.set_permission_trackers :view_issues, :all
    role1.save!
    role2 = Role.generate!
    role2.add_permission! :view_issues
    role2.set_permission_trackers :view_issues, [2]
    role2.save!
    User.add_to_project(user, Project.find(1), [role1, role2])

    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'default' } do
      issues = Issue.where(:project_id => 1).visible(user).to_a
      assert issues.any?
      assert_equal [2], issues.map(&:tracker_id).uniq
  
      assert Issue.where(:project_id => 1).all? {|issue| issue.visible?(user) ^ issue.tracker_id != 2}
        
      # watching does not change behavior
      Issue.find(1).add_watcher(user)
      
      issues = Issue.where(:project_id => 1).visible(user).to_a
      assert issues.any?
      assert_equal [2], issues.map(&:tracker_id).uniq
      
      assert Issue.where(:project_id => 1).all? {|issue| issue.visible?(user) ^ issue.tracker_id != 2}
    end
  end

  def test_protected_visible_scope_should_not_consider_roles_without_view_issues_permission
    user = User.generate!
    role1 = Role.generate!
    role1.remove_permission! :view_issues
    role1.set_permission_trackers :view_issues, :all
    role1.save!
    role2 = Role.generate!
    role2.add_permission! :view_issues
    role2.set_permission_trackers :view_issues, [2]
    role2.save!
    User.add_to_project(user, Project.find(1), [role1, role2])
  
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'protected' } do
      issues = Issue.where(:project_id => 1).visible(user).to_a
      assert issues.any?
      assert_equal [2], issues.map(&:tracker_id).uniq
  
      assert Issue.where(:project_id => 1).all? {|issue| issue.visible?(user) ^ issue.tracker_id != 2}
        
      # watching changes behavior
      Issue.find(1).add_watcher(user)
      
      issues = Issue.where(:project_id => 1).visible(user).to_a
      assert issues.any?
      assert_equal [1,2], issues.map(&:tracker_id).uniq.sort
      
      assert Issue.where(:project_id => 1).all? {|issue| (issue.visible?(user) ^ issue.tracker_id != 2) || issue.id == 1 }
    end
  end
  
  
  def test_extended_visible_scope_should_not_consider_roles_without_view_issues_permission
    user = User.generate!
    role1 = Role.generate!
    role1.remove_permission! :view_issues
    role1.set_permission_trackers :view_issues, :all
    role1.save!
    role2 = Role.generate!
    role2.add_permission! :view_issues
    role2.set_permission_trackers :view_issues, [2]
    role2.save!
    User.add_to_project(user, Project.find(1), [role1, role2])
  
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'extended' } do
      issues = Issue.where(:project_id => 1).visible(user).to_a
      assert issues.any?
      assert_equal [2], issues.map(&:tracker_id).uniq
  
      assert Issue.where(:project_id => 1).all? {|issue| issue.visible?(user) ^ issue.tracker_id != 2}
        
      # watching changes behavior
      Issue.find(1).add_watcher(user)
      
      issues = Issue.where(:project_id => 1).visible(user).to_a
      assert issues.any?
      assert_equal [1,2], issues.map(&:tracker_id).uniq.sort
      
      assert Issue.where(:project_id => 1).all? {|issue| (issue.visible?(user) ^ issue.tracker_id != 2) || issue.id == 1 }
    end
  end

  
  def test_default_visible_scope_with_project_and_subprojects
    project = Project.find(1)
    user = User.find(2)
    subproject = Project.find_by_identifier('subproject1')
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'default' } do
      issues = Issue.visible(user, :project => project, :with_subprojects => true).to_a
      projects = issues.collect(&:project).uniq
      assert projects.size > 1
      assert_equal [], projects.select {|p| !p.is_or_is_descendant_of?(project)}
      assert_not_nil projects.detect {|p| p.is_descendant_of?(project)}
        
      # not visible if nonmember has no visibility, even if watching
      Issue.find(5).add_watcher(user)
      Role.non_member.remove_permission!(:view_issues)
      user.reload

      issues = Issue.visible(user, :project => project, :with_subprojects => true).to_a
      projects = issues.collect(&:project).uniq
      assert !projects.include?(subproject)
    end
  end

  def test_protected_visible_scope_with_project_and_subprojects
    project = Project.find(1)
    user = User.find(2)
    subproject = Project.find_by_identifier('subproject1')
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'protected' } do
      issues = Issue.visible(user, :project => project, :with_subprojects => true).to_a
      projects = issues.collect(&:project).uniq
      assert projects.size > 1
      assert_equal [], projects.select {|p| !p.is_or_is_descendant_of?(project)}
      assert_not_nil projects.detect {|p| p.is_descendant_of?(project)}
        
      # not visible if nonmember has no visibility, even if watching
      Issue.find(5).add_watcher(user)
      Role.non_member.remove_permission!(:view_issues)
      user.reload

      issues = Issue.visible(user, :project => project, :with_subprojects => true).to_a
      projects = issues.collect(&:project).uniq
      assert !projects.include?(subproject)
    end
  end

  def test_extended_visible_scope_with_project_and_subprojects
    project = Project.find(1)
    user = User.find(2)
    subproject = Project.find_by_identifier('subproject1')
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'extended' } do
      issues = Issue.visible(user, :project => project, :with_subprojects => true).to_a
      projects = issues.collect(&:project).uniq
      assert projects.size > 1
      assert_equal [], projects.select {|p| !p.is_or_is_descendant_of?(project)}
      assert_not_nil projects.detect {|p| p.is_descendant_of?(project)}
        
      # visible even if nonmember has no visibility, because of watching
      Issue.find(5).add_watcher(user)
      Role.non_member.remove_permission!(:view_issues)
      user.reload
  
      issues = Issue.visible(user, :project => project, :with_subprojects => true).to_a
      projects = issues.collect(&:project).uniq
      assert projects.size > 1
      assert_equal [], projects.select {|p| !p.is_or_is_descendant_of?(project)}
      assert_not_nil projects.detect {|p| p.is_descendant_of?(project)}
      assert projects.include?(subproject)
    end
  end

  
  def test_visible_and_nested_set_scopes_on_watching
    user = User.generate!
    Role.find(2).update! :issues_visibility => 'own'
    Member.create!(:project_id => 1, :principal => user, :role_ids => [2])
    parent = Issue.generate!(:assigned_to => user)
    assert parent.visible?(user)
    child1 = Issue.generate!(:parent_issue_id => parent.id, :assigned_to => user)
    child2 = Issue.generate!(:parent_issue_id => parent.id)
    child2.add_watcher(user)
    parent.reload
    child1.reload
    child2.reload
    
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'default' } do
      assert child1.visible?(user)
      assert !child2.visible?(user)
      assert_equal 2, parent.descendants.count
      assert_equal 1, parent.descendants.visible(user).count
      # awesome_nested_set 2-1-stable branch has regression.
      # https://github.com/collectiveidea/awesome_nested_set/commit/3d5ac746542b564f6586c2316180254b088bebb6
      # ActiveRecord::StatementInvalid: SQLite3::SQLException: ambiguous column name: lft:
      assert_equal 2, parent.descendants.collect{|i| i}.size
      assert_equal 1, parent.descendants.visible(user).collect{|i| i}.size
    end
    
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'protected' } do
      assert child1.visible?(user)
      assert child2.visible?(user)
      assert_equal 2, parent.descendants.count
      assert_equal 2, parent.descendants.visible(user).count
      # awesome_nested_set 2-1-stable branch has regression.
      # https://github.com/collectiveidea/awesome_nested_set/commit/3d5ac746542b564f6586c2316180254b088bebb6
      # ActiveRecord::StatementInvalid: SQLite3::SQLException: ambiguous column name: lft:
      assert_equal 2, parent.descendants.collect{|i| i}.size
      assert_equal 2, parent.descendants.visible(user).collect{|i| i}.size
    end

    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'extended' } do
      assert child1.visible?(user)
      assert child2.visible?(user)
      assert_equal 2, parent.descendants.count
      assert_equal 2, parent.descendants.visible(user).count
      # awesome_nested_set 2-1-stable branch has regression.
      # https://github.com/collectiveidea/awesome_nested_set/commit/3d5ac746542b564f6586c2316180254b088bebb6
      # ActiveRecord::StatementInvalid: SQLite3::SQLException: ambiguous column name: lft:
      assert_equal 2, parent.descendants.collect{|i| i}.size
      assert_equal 2, parent.descendants.visible(user).collect{|i| i}.size
    end

  end

  
  def test_default_watcher_recipients_should_not_include_users_that_cannot_view_the_issue
    user = User.find(3)
    issue = Issue.find(9)
    Watcher.create!(:user => user, :watchable => issue)
    assert issue.watched_by?(user)
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'default' } do
      assert !issue.watcher_recipients.include?(user.mail)
    end
  end

  def test_protected_watcher_recipients_should_not_include_users_that_cannot_view_the_issue
    user = User.find(3)
    issue = Issue.find(9)
    Watcher.create!(:user => user, :watchable => issue)
    assert issue.watched_by?(user)
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'protected' } do
      # the plugin does not let the issue visible to watchers without view permissions (private project)
      assert !issue.watcher_recipients.include?(user.mail)
    end
  end

  def test_extended_watcher_recipients_should_not_include_users_that_cannot_view_the_issue
    user = User.find(3)
    issue = Issue.find(9)
    Watcher.create!(:user => user, :watchable => issue)
    assert issue.watched_by?(user)
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'extended' } do
      # the plugin lets the issue visible to watchers even on private project
      assert issue.watcher_recipients.include?(user.mail)
    end
  end

  
def test_default_visible_scope_for_non_member_with_group_watching
  user = User.find(9)
  group = Group.new(:name => "Test group")
  assert group.save
  group.reload
  group.users << user

  assert user.projects.empty?
  with_settings :plugin_redmine_extended_watchers => { 'policy' => 'default' } do
    # Non member user should see issues of public projects only
    issues = Issue.visible(user).to_a
    assert issues.any?
    assert_nil issues.detect {|issue| !issue.project.is_public?}
    assert_nil issues.detect {|issue| issue.is_private?}
    assert_visibility_match user, issues
    
    # even if watching
    @ipupu.add_watcher(group)
    @ipupr.add_watcher(group)
    @iprpu.add_watcher(group)
    @iprpr.add_watcher(group)
    issues = Issue.visible(user).to_a
    assert_nil issues.detect {|issue| !issue.project.is_public?}
    assert_nil issues.detect {|issue| issue.is_private?}
    assert_visibility_match user, issues

    # and nonmember has no :view_issues permission
    Role.non_member.remove_permission!(:view_issues)
    user.reload
    issues = Issue.visible(user).to_a
    assert_nil issues.detect {|issue| !issue.project.is_public?}
    assert_nil issues.detect {|issue| issue.is_private?}
    assert_visibility_match user, issues
  end
end

def test_protected_visible_scope_for_non_member_with_group_watching
  user = User.find(9)
  group = Group.new(:name => "Test group")
  assert group.save
  group.reload
  group.users << user

  assert user.projects.empty?
  with_settings :plugin_redmine_extended_watchers => { 'policy' => 'protected' } do
    # Non member user should see issues of public projects only
    issues = Issue.visible(user).to_a
    assert issues.any?
    assert_nil issues.detect {|issue| !issue.project.is_public?}
    assert_nil issues.detect {|issue| issue.is_private?}
    assert_visibility_match user, issues
    
    # unless watching
    @ipupu.add_watcher(group)
    @ipupr.add_watcher(group)
    @iprpu.add_watcher(group)
    @iprpr.add_watcher(group)
    issues = Issue.visible(user).to_a
    assert_nil issues.detect {|issue| !issue.project.is_public?}
    assert_equal 1, issues.count {|issue| issue.is_private?} # watched private issue in public project
    assert_visibility_match user, issues

    # unless nonmember has no :view_issues permission
    Role.non_member.remove_permission!(:view_issues)
    user.reload
    issues = Issue.visible(user).to_a
    assert_nil issues.detect {|issue| !issue.project.is_public?}
    assert_nil issues.detect {|issue| issue.is_private?}
    assert_visibility_match user, issues
  end
end

def test_extended_visible_scope_for_non_member_with_group_watching
  user = User.find(9)
  group = Group.new(:name => "Test group")
  assert group.save
  group.reload
  group.users << user

  assert user.projects.empty?
  with_settings :plugin_redmine_extended_watchers => { 'policy' => 'extended' } do
    # Non member user should see issues of public projects only
    issues = Issue.visible(user).to_a
    assert issues.any?
    assert_nil issues.detect {|issue| !issue.project.is_public?}
    assert_nil issues.detect {|issue| issue.is_private?}
    assert_visibility_match user, issues
    
    # unless watching
    @ipupu.add_watcher(group)
    @ipupr.add_watcher(group)
    @iprpu.add_watcher(group)
    @iprpr.add_watcher(group)
    issues = Issue.visible(user).to_a
    assert_equal 2, issues.count{|issue| !issue.project.is_public?}
    assert_equal 2, issues.count {|issue| issue.is_private?}
    assert_visibility_match user, issues

    # even if nonmember has no :view_issues permission
    Role.non_member.remove_permission!(:view_issues)
    user.reload
    issues = Issue.visible(user).to_a
    assert_equal 2, issues.count {|issue| !issue.project.is_public?}
    assert_equal 2, issues.count {|issue| issue.is_private?}
    assert_visibility_match user, issues
  end
end


end
