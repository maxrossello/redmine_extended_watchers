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

require File.expand_path('../../test_helper', __FILE__)

# tests against an issue in a private project

class WatcherTestExtendedWatchersPrivateProject < ActiveSupport::TestCase
  fixtures :projects, :users, :email_addresses, :members, :member_roles, :roles, :enabled_modules,
           :issues, :issue_statuses, :enumerations, :trackers, :projects_trackers,
           :watchers

  def setup
    User.current = nil
    @user = User.find(2)
    @nonmember = User.find(4)
    @issue = Issue.find(4)
    @project = @issue.project
  end

  # addable_watcher_users are the first users listed with empty search field
  # users_for_new_watcher are the users listed after a search string is provided

  def test_default_add_watcher_users_selection
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'default' } do
      assert @issue.addable_watcher_users.size == 2
      assert @issue.addable_watcher_users.include? User.find(2)
      assert @issue.addable_watcher_users.include? User.find(8)
      Role.non_member.remove_permission!(:view_issues)
      assert @issue.addable_watcher_users.size == 2
      assert @issue.addable_watcher_users.include? User.find(2)
      assert @issue.addable_watcher_users.include? User.find(8)
    end
  end
    
  def test_protected_add_watcher_users_selection
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'protected' } do
      assert @issue.addable_watcher_users.size == 2
      assert @issue.addable_watcher_users.include? User.find(2)
      assert @issue.addable_watcher_users.include? User.find(8)
      Role.non_member.remove_permission!(:view_issues)
      assert @issue.addable_watcher_users.size == 2
      assert @issue.addable_watcher_users.include? User.find(2)
      assert @issue.addable_watcher_users.include? User.find(8)
    end
  end

  def test_extended_add_watcher_users_selection
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'extended' } do
      assert @issue.addable_watcher_users.size == 2
      assert @issue.addable_watcher_users.include? User.find(2)
      assert @issue.addable_watcher_users.include? User.find(8)
      Role.non_member.remove_permission!(:view_issues)
      assert @issue.addable_watcher_users.size == 2
      assert @issue.addable_watcher_users.include? User.find(2)
      assert @issue.addable_watcher_users.include? User.find(8)
    end
  end

  # plugin allows to add any user as a watcher, then the issue becomes visible to it

  def test_default_addable_watcher_users_should_not_include_user_that_cannot_view_the_object
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'default' } do
      issue = Issue.new(:project => Project.find(1), :is_private => true)
      assert_nil issue.addable_watcher_users.detect {|user| !issue.visible?(user)}
      Role.non_member.remove_permission!(:view_issues)
      assert_nil issue.addable_watcher_users.detect {|user| !issue.visible?(user)}
    end
  end

  # a private issue is anyway listed since watching will open it up  
  def test_protected_addable_watcher_users_should_also_include_user_that_cannot_view_the_object
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'protected' } do
      issue = Issue.new(:project => Project.find(1), :is_private => true)
      assert_not_nil issue.addable_watcher_users.detect {|user| !issue.visible?(user)}
      Role.non_member.remove_permission!(:view_issues)
      assert_not_nil issue.addable_watcher_users.detect {|user| !issue.visible?(user)}
    end
  end

  # a private issue is anyway listed since watching will open it up  
  def test_extended_addable_watcher_users_should_also_include_user_that_cannot_view_the_object
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'protected' } do
      issue = Issue.new(:project => Project.find(1), :is_private => true)
      assert_not_nil issue.addable_watcher_users.detect {|user| !issue.visible?(user)}
      Role.non_member.remove_permission!(:view_issues)
      assert_not_nil issue.addable_watcher_users.detect {|user| !issue.visible?(user)}
    end
  end

  
  def test_default_recipients_nonmember_view
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'default' } do
      @issue.watchers.delete_all
      @issue.reload

      assert @issue.watcher_recipients.empty?
      assert @issue.add_watcher(@user)
      assert @issue.add_watcher(@nonmember)

      @user.mail_notification = 'all'
      @user.save!
      @nonmember.mail_notification = 'all'
      @nonmember.save!
      @issue.reload
      assert @issue.watcher_recipients.include?(@user.mail)
      assert !@issue.watcher_recipients.include?(@nonmember.mail)

      @user.mail_notification = 'none'
      @user.save!
      @nonmember.mail_notification = 'none'
      @nonmember.save!
      @issue.reload
      assert !@issue.watcher_recipients.include?(@user.mail)
      assert !@issue.watcher_recipients.include?(@nonmember.mail)
    end
  end
  
  def test_default_recipients_nonmember_not_view
    Role.non_member.remove_permission!(:view_issues)
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'default' } do
      @issue.watchers.delete_all
      @issue.reload

      assert @issue.watcher_recipients.empty?
      assert @issue.add_watcher(@user)
      assert @issue.add_watcher(@nonmember)

      @user.mail_notification = 'all'
      @user.save!
      @nonmember.mail_notification = 'all'
      @nonmember.save!
      @issue.reload
      assert @issue.watcher_recipients.include?(@user.mail)
      assert !@issue.watcher_recipients.include?(@nonmember.mail)

      @user.mail_notification = 'none'
      @user.save!
      @nonmember.mail_notification = 'none'
      @nonmember.save!
      @issue.reload
      assert !@issue.watcher_recipients.include?(@user.mail)
      assert !@issue.watcher_recipients.include?(@nonmember.mail)
    end
  end

  def test_protected_recipients_nonmember_view
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'protected' } do
      @issue.watchers.delete_all
      @issue.reload

      assert @issue.watcher_recipients.empty?
      assert @issue.add_watcher(@user)
      # add_watcher does not make any control
      assert @issue.add_watcher(@nonmember)

      @user.mail_notification = 'all'
      @user.save!
      @nonmember.mail_notification = 'all'
      @nonmember.save!
      @issue.reload
      assert @issue.watcher_recipients.include?(@user.mail)
      assert !@issue.watcher_recipients.include?(@nonmember.mail)

      @user.mail_notification = 'none'
      @user.save!
      @nonmember.mail_notification = 'none'
      @nonmember.save!
      @issue.reload
      assert !@issue.watcher_recipients.include?(@user.mail)
      assert !@issue.watcher_recipients.include?(@nonmember.mail)
    end
  end

  def test_protected_recipients_nonmember_not_view
    Role.non_member.remove_permission!(:view_issues)
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'protected' } do
      @issue.watchers.delete_all
      @issue.reload

      assert @issue.watcher_recipients.empty?
      assert @issue.add_watcher(@user)
      # add_watcher does not make any control
      assert @issue.add_watcher(@nonmember)

      @user.mail_notification = 'all'
      @user.save!
      @nonmember.mail_notification = 'all'
      @nonmember.save!
      @issue.reload
      assert @issue.watcher_recipients.include?(@user.mail)
      assert !@issue.watcher_recipients.include?(@nonmember.mail)

      @user.mail_notification = 'none'
      @user.save!
      @nonmember.mail_notification = 'none'
      @nonmember.save!
      @issue.reload
      assert !@issue.watcher_recipients.include?(@user.mail)
      assert !@issue.watcher_recipients.include?(@nonmember.mail)
    end
  end

  def test_extended_recipients_nonmember_view
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'extended' } do
      @issue.watchers.delete_all
      @issue.reload

      assert @issue.watcher_recipients.empty?
      assert @issue.add_watcher(@user)
      assert @issue.add_watcher(@nonmember)

      @user.mail_notification = 'all'
      @user.save!
      @nonmember.mail_notification = 'all'
      @nonmember.save!
      @issue.reload
      assert @issue.watcher_recipients.include?(@user.mail)
      assert @issue.watcher_recipients.include?(@nonmember.mail)

      @user.mail_notification = 'none'
      @user.save!
      @nonmember.mail_notification = 'none'
      @nonmember.save!
      @issue.reload
      assert !@issue.watcher_recipients.include?(@user.mail)
      assert !@issue.watcher_recipients.include?(@nonmember.mail)
    end
  end

  def test_extended_recipients_nonmember_not_view
    Role.non_member.remove_permission!(:view_issues)
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'extended' } do
      @issue.watchers.delete_all
      @issue.reload

      assert @issue.watcher_recipients.empty?
      assert @issue.add_watcher(@user)
      assert @issue.add_watcher(@nonmember)

      @user.mail_notification = 'all'
      @user.save!
      @nonmember.mail_notification = 'all'
      @nonmember.save!
      @issue.reload
      assert @issue.watcher_recipients.include?(@user.mail)
      assert @issue.watcher_recipients.include?(@nonmember.mail)

      @user.mail_notification = 'none'
      @user.save!
      @nonmember.mail_notification = 'none'
      @nonmember.save!
      @issue.reload
      assert !@issue.watcher_recipients.include?(@user.mail)
      assert !@issue.watcher_recipients.include?(@nonmember.mail)
    end
  end
  
  
  def test_default_recipients_private_issue_nonmember_view
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'default' } do
      issue = Issue.generate!(:project => Project.find(1), :is_private => true)

      assert issue.watcher_recipients.empty?
      assert issue.add_watcher(@user)
      assert issue.add_watcher(@nonmember)

      @user.mail_notification = 'all'
      @user.save!
      @nonmember.mail_notification = 'all'
      @nonmember.save!
      issue.reload
      assert issue.watcher_recipients.include?(@user.mail)
      assert !issue.watcher_recipients.include?(@nonmember.mail)

      @user.mail_notification = 'none'
      @user.save!
      @nonmember.mail_notification = 'none'
      @nonmember.save!
      issue.reload
      assert !issue.watcher_recipients.include?(@user.mail)
      assert !issue.watcher_recipients.include?(@nonmember.mail)
    end
  end

  def test_default_recipients_private_issue_nonmember_not_view
    Role.non_member.remove_permission!(:view_issues)
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'default' } do
      issue = Issue.generate!(:project => Project.find(1), :is_private => true)

      assert issue.watcher_recipients.empty?
      assert issue.add_watcher(@user)
      assert issue.add_watcher(@nonmember)

      @user.mail_notification = 'all'
      @user.save!
      @nonmember.mail_notification = 'all'
      @nonmember.save!
      issue.reload
      assert issue.watcher_recipients.include?(@user.mail)
      assert !issue.watcher_recipients.include?(@nonmember.mail)

      @user.mail_notification = 'none'
      @user.save!
      @nonmember.mail_notification = 'none'
      @nonmember.save!
      issue.reload
      assert !issue.watcher_recipients.include?(@user.mail)
      assert !issue.watcher_recipients.include?(@nonmember.mail)
    end
  end

  def test_protected_recipients_private_issue_nonmember_view
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'protected' } do
      issue = Issue.generate!(:project => Project.find(1), :is_private => true)

      assert issue.watcher_recipients.empty?
      assert issue.add_watcher(@user)
      assert issue.add_watcher(@nonmember)

      @user.mail_notification = 'all'
      @user.save!
      @nonmember.mail_notification = 'all'
      @nonmember.save!
      issue.reload
      assert issue.watcher_recipients.include?(@user.mail)
      assert issue.watcher_recipients.include?(@nonmember.mail)

      @user.mail_notification = 'none'
      @user.save!
      @nonmember.mail_notification = 'none'
      @nonmember.save!
      issue.reload
      assert !issue.watcher_recipients.include?(@user.mail)
      assert !issue.watcher_recipients.include?(@nonmember.mail)
    end
  end

  def test_protected_recipients_private_issue_nonmember_not_view
    Role.non_member.remove_permission!(:view_issues)
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'protected' } do
      issue = Issue.generate!(:project => Project.find(1), :is_private => true)

      assert issue.watcher_recipients.empty?
      assert issue.add_watcher(@user)
      assert issue.add_watcher(@nonmember)

      @user.mail_notification = 'all'
      @user.save!
      @nonmember.mail_notification = 'all'
      @nonmember.save!
      issue.reload
      assert issue.watcher_recipients.include?(@user.mail)
      assert !issue.watcher_recipients.include?(@nonmember.mail)

      @user.mail_notification = 'none'
      @user.save!
      @nonmember.mail_notification = 'none'
      @nonmember.save!
      issue.reload
      assert !issue.watcher_recipients.include?(@user.mail)
      assert !issue.watcher_recipients.include?(@nonmember.mail)
    end
  end

  def test_extended_recipients_private_issue_nonmember_view
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'extended' } do
      issue = Issue.generate!(:project => Project.find(1), :is_private => true)

      assert issue.watcher_recipients.empty?
      assert issue.add_watcher(@user)
      assert issue.add_watcher(@nonmember)

      @user.mail_notification = 'all'
      @user.save!
      @nonmember.mail_notification = 'all'
      @nonmember.save!
      issue.reload
      assert issue.watcher_recipients.include?(@user.mail)
      assert issue.watcher_recipients.include?(@nonmember.mail)

      @user.mail_notification = 'none'
      @user.save!
      @nonmember.mail_notification = 'none'
      @nonmember.save!
      issue.reload
      assert !issue.watcher_recipients.include?(@user.mail)
      assert !issue.watcher_recipients.include?(@nonmember.mail)
    end
  end

  def test_extended_recipients_private_issue_nonmember_not_view
    Role.non_member.remove_permission!(:view_issues)
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'extended' } do
      issue = Issue.generate!(:project => Project.find(1), :is_private => true)

      assert issue.watcher_recipients.empty?
      assert issue.add_watcher(@user)
      assert issue.add_watcher(@nonmember)

      @user.mail_notification = 'all'
      @user.save!
      @nonmember.mail_notification = 'all'
      @nonmember.save!
      issue.reload
      assert issue.watcher_recipients.include?(@user.mail)
      assert issue.watcher_recipients.include?(@nonmember.mail)

      @user.mail_notification = 'none'
      @user.save!
      @nonmember.mail_notification = 'none'
      @nonmember.save!
      issue.reload
      assert !issue.watcher_recipients.include?(@user.mail)
      assert !issue.watcher_recipients.include?(@nonmember.mail)
    end
  end

  
  def test_default_prune_with_user
    Watcher.where("user_id = 9").delete_all
    user = User.find(9)

    # public
    Watcher.create!(:watchable => Issue.find(1), :user => user)

    # private project (id: 2)
    Member.create!(:project => Project.find(2), :principal => user, :role_ids => [1])
    Watcher.create!(:watchable => Issue.find(4), :user => user)

    assert_no_difference 'Watcher.count' do
      Watcher.prune(:user => User.find(9))
    end

    Member.delete_all

    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'default' } do
      assert_difference 'Watcher.count', -1 do
        Watcher.prune(:user => User.find(9))
      end

      assert Issue.find(1).watched_by?(user)
      assert !Issue.find(4).watched_by?(user)
    end
  end
  
  def test_protected_prune_with_user
    Watcher.where("user_id = 9").delete_all
    user = User.find(9)

    # public
    Watcher.create!(:watchable => Issue.find(1), :user => user)

    # private project (id: 2)
    Member.create!(:project => Project.find(2), :principal => user, :role_ids => [1])
    Watcher.create!(:watchable => Issue.find(4), :user => user)

    assert_no_difference 'Watcher.count' do
      Watcher.prune(:user => User.find(9))
    end

    Member.delete_all

    # user lost membership and thus issue visibility even if watched, therefore issue watcher is pruned
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'protected' } do
      assert_difference 'Watcher.count', -1 do
        Watcher.prune(:user => User.find(9))
      end

      assert Issue.find(1).watched_by?(user)
      assert !Issue.find(4).watched_by?(user)
    end
  end

  def test_extended_prune_with_user
    Watcher.where("user_id = 9").delete_all
    user = User.find(9)

    # public
    Watcher.create!(:watchable => Issue.find(1), :user => user)

    # private project (id: 2)
    Member.create!(:project => Project.find(2), :principal => user, :role_ids => [1])
    Watcher.create!(:watchable => Issue.find(4), :user => user)

    assert_no_difference 'Watcher.count' do
      Watcher.prune(:user => User.find(9))
    end

    Member.delete_all

    # watching does allow issue visibility, therefore issue watcher is not pruned
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'extended' } do
      assert_no_difference 'Watcher.count' do
        Watcher.prune(:user => User.find(9))
      end

      assert Issue.find(1).watched_by?(user)
      assert Issue.find(4).watched_by?(user)
    end
  end


  def test_default_prune_with_project
    user = User.find(9)
    Watcher.new(:watchable => Issue.find(4), :user => User.find(9)).save(:validate => false) # project 2
    Watcher.new(:watchable => Issue.find(6), :user => User.find(9)).save(:validate => false) # project 5

    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'default' } do
      assert Watcher.prune(:project => Project.find(5)) > 0
      assert Issue.find(4).watched_by?(user)
      assert !Issue.find(6).watched_by?(user)
    end
  end

  def test_protected_prune_with_project
    user = User.find(9)
    Watcher.new(:watchable => Issue.find(4), :user => User.find(9)).save(:validate => false) # project 2
    Watcher.new(:watchable => Issue.find(6), :user => User.find(9)).save(:validate => false) # project 5

    # user lost membership and thus issue visibility even if watched, therefore issue watcher is pruned
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'protected' } do
      assert Watcher.prune(:project => Project.find(5)) > 0
      assert Issue.find(4).watched_by?(user)
      assert !Issue.find(6).watched_by?(user)
    end
  end

  def test_extended_prune_with_project
    user = User.find(9)
    Watcher.new(:watchable => Issue.find(4), :user => User.find(9)).save(:validate => false) # project 2
    Watcher.new(:watchable => Issue.find(6), :user => User.find(9)).save(:validate => false) # project 5

    # watching does allow issue visibility, therefore issue watcher is not pruned
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'extended' } do
      assert Watcher.prune(:project => Project.find(5)) == 0
      assert Issue.find(4).watched_by?(user)
      assert Issue.find(6).watched_by?(user)
    end
  end


  def test_default_prune_all
    user = User.find(9)
    Watcher.new(:watchable => Issue.find(4), :user => User.find(9)).save(:validate => false)

    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'default' } do
      assert Watcher.prune > 0
      assert !Issue.find(4).watched_by?(user)
    end
  end

  def test_protected_prune_all
    user = User.find(9)
    Watcher.new(:watchable => Issue.find(4), :user => User.find(9)).save(:validate => false)

    # user lost membership and thus issue visibility even if watched, therefore issue watcher is pruned
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'protected' } do
      assert Watcher.prune > 0
      assert !Issue.find(4).watched_by?(user)
    end
  end
  
  def test_extended_prune_all
    user = User.find(9)
    Watcher.new(:watchable => Issue.find(4), :user => User.find(9)).save(:validate => false)

    # watching does allow issue visibility, therefore issue watcher is not pruned
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'extended' } do
      assert Watcher.prune == 0
      assert Issue.find(4).watched_by?(user)
    end
  end
  
end
