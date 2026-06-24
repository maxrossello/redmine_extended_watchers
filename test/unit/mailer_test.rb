# encoding: utf-8
#
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

require File.expand_path('../../test_helper', __FILE__)

class MailerTestExtendedWatchers < ActiveSupport::TestCase
  include Redmine::I18n
  include Rails::Dom::Testing::Assertions
  fixtures :projects, :enabled_modules, :issues, :users, :email_addresses, :user_preferences, :members,
           :member_roles, :roles, :documents, :attachments, :news,
           :tokens, :journals, :journal_details, :changesets,
           :trackers, :projects_trackers,
           :issue_statuses, :enumerations, :messages, :boards, :repositories,
           :wikis, :wiki_pages, :wiki_contents, :wiki_content_versions,
           :versions,
           :comments

  def setup
    ActionMailer::Base.deliveries.clear
    Setting.plain_text_mail = '0'
    Setting.default_language = 'en'
    set_language_if_valid 'en' # testsuite
    User.current = nil
  end

  test "#default issue_add should not notify project members that are not allow to view the issue" do
    issue = Issue.find(1)
    user = User.find(3)
    nonmember = User.find(4)
    Role.find(2).remove_permission!(:view_issues) # role of user 3
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'default' } do
      assert Mailer.deliver_issue_add(issue)
      assert_not_include user.mail, recipients
      
      # even if user is watcher
      issue.add_watcher(user)
      user.reload
      ActionMailer::Base.deliveries.clear
      assert Mailer.deliver_issue_add(issue)
      assert_not_include user.mail, recipients
      
      # neither non members with issue view permission
      assert_not_include nonmember.mail, recipients

      # unless they are watching
      issue.add_watcher(nonmember)
      nonmember.reload
      ActionMailer::Base.deliveries.clear
      assert Mailer.deliver_issue_add(issue)
      assert_include nonmember.mail, recipients
      
      # but not if nonmembers do not have view issue permission
      Role.non_member.remove_permission!(:view_issues)
      nonmember.reload
      ActionMailer::Base.deliveries.clear
      assert Mailer.deliver_issue_add(issue)
      assert_not_include nonmember.mail, recipients
      
      # nor with nonmember groups that has restricted view issue permission
      role = Role.generate!(permissions: [:view_issues, :view_watchers], issues_visibility: 'own')
      Member.create!(:project => issue.project, :principal => Group.non_member, :role_ids => [role.id])
      nonmember.reload
      issue.project.reload
      ActionMailer::Base.deliveries.clear
      assert Mailer.deliver_issue_add(issue)
      assert_not_include nonmember.mail, recipients
      
      # unless issue visibility is at least default
      role.update! issues_visibility: 'default'
      nonmember.reload
      issue.project.reload   # to reload memberships
      ActionMailer::Base.deliveries.clear
      assert Mailer.deliver_issue_add(issue)
      assert_include nonmember.mail, recipients
    end
  end

  test "#protected issue_add should notify project members that are not allow to view the issue but watch" do
    issue = Issue.find(1)
    user = User.find(3)
    nonmember = User.find(4)
    Role.find(2).remove_permission!(:view_issues)
    assert Mailer.deliver_issue_add(issue)
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'protected' } do
      assert Mailer.deliver_issue_add(issue)
      assert_not_include user.mail, recipients
      
      # even if member user is watcher, but without view issue permission
      issue.add_watcher(user)
      user.reload
      assert Mailer.deliver_issue_add(issue)
      assert_not_include user.mail, recipients
      
      # neither non members with issue view permission
      assert_not_include nonmember.mail, recipients

      # unless they are watching
      issue.add_watcher(nonmember)
      nonmember.reload
      assert Mailer.deliver_issue_add(issue)
      assert_include nonmember.mail, recipients
      
      # but not if nonmembers do not have view issue permission
      Role.non_member.remove_permission!(:view_issues)
      nonmember.reload
      issue.project.reload
      ActionMailer::Base.deliveries.clear
      assert Mailer.deliver_issue_add(issue)
      assert_not_include nonmember.mail, recipients

      # unless with nonmember groups that has at least own view issue permission
      role = Role.generate!(permissions: [:view_issues, :view_watchers], issues_visibility: 'own')
      Member.create!(:project => issue.project, :principal => Group.non_member, :role_ids => [role.id])
      nonmember.reload
      issue.project.reload
      ActionMailer::Base.deliveries.clear
      assert Mailer.deliver_issue_add(issue)
      assert_include nonmember.mail, recipients
    end
  end

  test "#extended issue_add should notify project members that are not allow to view the issue but watch" do
    issue = Issue.find(1)
    user = User.find(3)
    nonmember = User.find(4)
    Role.find(2).remove_permission!(:view_issues)
    assert Mailer.deliver_issue_add(issue)
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'extended' } do
      assert Mailer.deliver_issue_add(issue)
      assert_not_include user.mail, recipients
      
      # unless user is watcher
      issue.add_watcher(user)
      user.reload
      assert Mailer.deliver_issue_add(issue)
      assert_include user.mail, recipients
      
      # not for non members with issue view permission
      assert_not_include nonmember.mail, recipients

      # unless they are watching
      issue.add_watcher(nonmember)
      nonmember.reload
      assert Mailer.deliver_issue_add(issue)
      assert_include nonmember.mail, recipients
      
      # even if nonmembers do not have view issue permission
      Role.non_member.remove_permission!(:view_issues)
      nonmember.reload
      assert Mailer.deliver_issue_add(issue)
      assert_include nonmember.mail, recipients
    end
  end

  
  test "#default issue_add should notify non member issue watchers" do
    issue = Issue.find(1)
    user = User.find(9)
    # minimal email notification options
    user.pref.no_self_notified = '1'
    user.pref.save
    user.mail_notification = false
    user.save

    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'extended' } do
      Watcher.create!(:watchable => issue, :user => user)
      assert Mailer.deliver_issue_add(issue)
      assert_include user.mail, recipients
    end
  end

  test "#protected issue_add should notify non member issue watchers" do
    issue = Issue.find(1)
    user = User.find(9)
    # minimal email notification options
    user.pref.no_self_notified = '1'
    user.pref.save
    user.mail_notification = false
    user.save

    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'protected' } do
      Watcher.create!(:watchable => issue, :user => user)
      assert Mailer.deliver_issue_add(issue)
      assert_include user.mail, recipients
    end
  end

  test "#extended issue_add should notify non member issue watchers" do
    issue = Issue.find(1)
    user = User.find(9)
    # minimal email notification options
    user.pref.no_self_notified = '1'
    user.pref.save
    user.mail_notification = false
    user.save

    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'extended' } do
      Watcher.create!(:watchable => issue, :user => user)
      assert Mailer.deliver_issue_add(issue)
      assert_include user.mail, recipients
    end
  end

  
  test "#default issue_add should not notify watchers not allowed to view the issue" do
    issue = Issue.find(1)
    user = User.find(9)
    Watcher.create!(:watchable => issue, :user => user)
    Role.non_member.remove_permission!(:view_issues)
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'default' } do
      assert Mailer.deliver_issue_add(issue)
      assert_not_include user.mail, recipients
    end
  end

  test "#protected issue_add should not notify watchers not allowed to view the issue" do
    issue = Issue.find(1)
    user = User.find(9)
    Watcher.create!(:watchable => issue, :user => user)
    Role.non_member.remove_permission!(:view_issues)
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'protected' } do
      # the protected mode requires view issue permission to extend watchers permissions
      assert Mailer.deliver_issue_add(issue)
      assert_not_include user.mail, recipients
    end
  end

  test "#extended issue_add should notify watchers not allowed to view the issue" do
    issue = Issue.find(1)
    user = User.find(9)
    Watcher.create!(:watchable => issue, :user => user)
    Role.non_member.remove_permission!(:view_issues)
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'extended' } do
      # the plugin provides full watching features, including notifications, also to watchers with no membership
      assert Mailer.deliver_issue_add(issue)
      assert_include user.mail, recipients
    end
  end

  
  def test_default_issue_edit_should_send_private_notes_to_watchers_with_permission_only
    issue = Issue.find(1)
    nonmember = User.find_by_login('someone')
    issue.set_watcher(nonmember)
    journal = Journal.find(1)
    journal.private_notes = true
    journal.save!

    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'default' } do
      Role.non_member.add_permission! :view_private_notes
      Mailer.deliver_issue_edit(journal)
      assert_include 'someone@foo.bar', ActionMailer::Base.deliveries.last.to.sort

      Role.non_member.remove_permission! :view_private_notes
      Mailer.deliver_issue_edit(journal)
      assert_not_include 'someone@foo.bar', ActionMailer::Base.deliveries.last.to.sort

      # nor with nonmember group that has restricted view issue permission
      role = Role.generate!(permissions: [:view_issues, :view_private_notes, :view_watchers], issues_visibility: 'own')
      Member.create!(:project => issue.project, :principal => Group.non_member, :role_ids => [role.id])
      nonmember.reload
      issue.project.reload
      journal.reload
      ActionMailer::Base.deliveries.clear
      Mailer.deliver_issue_edit(journal)
      assert_not_include 'someone@foo.bar', ActionMailer::Base.deliveries.last.to.sort
      
      # unless issue visibility is at least default
      role.update! issues_visibility: 'default'
      nonmember.reload
      issue.reload
      journal.reload
      ActionMailer::Base.deliveries.clear
      Mailer.deliver_issue_edit(journal)
      assert_include 'someone@foo.bar', ActionMailer::Base.deliveries.last.to.sort
      
      # but not without :view_private_notes permission
      role.remove_permission!(:view_private_notes)
      nonmember.reload
      issue.reload
      journal.reload
      ActionMailer::Base.deliveries.clear
      Mailer.deliver_issue_edit(journal)
      assert_not_include 'someone@foo.bar', ActionMailer::Base.deliveries.last.to.sort
    end
  end

  def test_protected_issue_edit_should_send_private_notes_to_watchers_with_permission_only
    issue = Issue.find(1)
    nonmember = User.find_by_login('someone')
    issue.set_watcher(nonmember)
    journal = Journal.find(1)
    journal.private_notes = true
    journal.save!

    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'protected' } do
      Role.non_member.add_permission! :view_private_notes
      Mailer.deliver_issue_edit(journal)
      assert_include 'someone@foo.bar', ActionMailer::Base.deliveries.last.to.sort

      Role.non_member.remove_permission! :view_private_notes
      Mailer.deliver_issue_edit(journal)
      assert_not_include 'someone@foo.bar', ActionMailer::Base.deliveries.last.to.sort

      # unless with nonmember group that has at least own view issue permission
      role = Role.generate!(permissions: [:view_issues, :view_private_notes, :view_watchers], issues_visibility: 'own')
      Member.create!(:project => issue.project, :principal => Group.non_member, :role_ids => [role.id])
      nonmember.reload
      issue.project.reload
      journal.reload
      ActionMailer::Base.deliveries.clear
      Mailer.deliver_issue_edit(journal)
      assert_include 'someone@foo.bar', ActionMailer::Base.deliveries.last.to.sort
      
      # but not without :view_private_notes permission
      role.remove_permission!(:view_private_notes)
      nonmember.reload
      issue.reload
      journal.reload
      ActionMailer::Base.deliveries.clear
      Mailer.deliver_issue_edit(journal)
      assert_not_include 'someone@foo.bar', ActionMailer::Base.deliveries.last.to.sort
    end
  end

  def test_extended_issue_edit_should_send_private_notes_to_watchers_with_permission_only
    issue = Issue.find(1)
    nonmember = User.find_by_login('someone')
    issue.set_watcher(nonmember)
    journal = Journal.find(1)
    journal.private_notes = true
    journal.save!

    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'extended' } do
      Role.non_member.add_permission! :view_private_notes
      Mailer.deliver_issue_edit(journal)
      assert_include 'someone@foo.bar', ActionMailer::Base.deliveries.last.to.sort

      Role.non_member.remove_permission! :view_private_notes
      Mailer.deliver_issue_edit(journal)
      assert_not_include 'someone@foo.bar', ActionMailer::Base.deliveries.last.to.sort

      # unless with nonmember group that has :view_private_notes permission
      role = Role.generate!(permissions: [:view_issues, :view_private_notes, :view_watchers], issues_visibility: 'own')
      Member.create!(:project => issue.project, :principal => Group.non_member, :role_ids => [role.id])
      nonmember.reload
      issue.project.reload
      journal.reload
      ActionMailer::Base.deliveries.clear
      Mailer.deliver_issue_edit(journal)
      assert_include 'someone@foo.bar', ActionMailer::Base.deliveries.last.to.sort
      
      # but not without :view_private_notes permission
      role.remove_permission!(:view_private_notes)
      nonmember.reload
      issue.reload
      journal.reload
      ActionMailer::Base.deliveries.clear
      Mailer.deliver_issue_edit(journal)
      assert_not_include 'someone@foo.bar', ActionMailer::Base.deliveries.last.to.sort
    end
  end
  

  def test_issue_edit_with_relation_should_notify_users_who_can_see_the_related_issue
    issue = Issue.generate!
    issue.init_journal(User.find(1))
    private_issue = Issue.generate!(:is_private => true)
    IssueRelation.create!(:issue_from => issue, :issue_to => private_issue, :relation_type => 'relates')
    issue.reload
    assert_equal 1, issue.journals.size
    journal = issue.journals.first
    
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'default' } do
      ActionMailer::Base.deliveries.clear

      Mailer.deliver_issue_edit(journal)
      last_email.to.each do |email|
        user = User.find_by_mail(email)
        assert private_issue.visible?(user), "Issue was not visible to #{user}"
      end
    end

    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'protected' } do
      ActionMailer::Base.deliveries.clear

      Mailer.deliver_issue_edit(journal)
      last_email.to.each do |email|
        user = User.find_by_mail(email)
        assert private_issue.visible?(user), "Issue was not visible to #{user}"
      end
    end

    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'extended' } do
      ActionMailer::Base.deliveries.clear

      Mailer.deliver_issue_edit(journal)
      last_email.to.each do |email|
        user = User.find_by_mail(email)
        assert private_issue.visible?(user), "Issue was not visible to #{user}"
      end
    end
  end

  
  def test_default_reminders_should_only_include_issues_the_user_can_see
    with_settings :default_language => 'en' do
      user = User.find(3)
      member = Member.create!(:project_id => 2, :principal => user, :role_ids => [1])
      issue = Issue.create!(:project_id => 2, :tracker_id => 1, :status_id => 1,
                      :subject => 'Issue dlopper should not see', :assigned_to_id => 3,
                      :due_date => 5.days.from_now,
                      :author_id => 2)
      member.destroy
      
      with_settings :plugin_redmine_extended_watchers => { 'policy' => 'default' } do

        ActionMailer::Base.deliveries.clear

        Mailer.reminders(:days => 42)
        assert_equal 1, ActionMailer::Base.deliveries.size
        mail = last_email
        assert mail.to.include?('dlopper@somenet.foo')
        assert_mail_body_no_match 'Issue dlopper should not see', mail
        
        # neither if watching
        issue.add_watcher(user)
        ActionMailer::Base.deliveries.clear

        Mailer.reminders(:days => 42)
        assert_equal 1, ActionMailer::Base.deliveries.size
        mail = last_email
        assert mail.to.include?('dlopper@somenet.foo')
        assert_mail_body_no_match 'Issue dlopper should not see', mail
      end
    end
  end

  def test_protected_reminders_should_only_include_issues_the_user_can_see
    with_settings :default_language => 'en' do
      user = User.find(3)
      member = Member.create!(:project_id => 2, :principal => user, :role_ids => [1])
      issue = Issue.create!(:project_id => 2, :tracker_id => 1, :status_id => 1,
      :subject => 'Issue dlopper should not see', :assigned_to_id => 3,
      :due_date => 5.days.from_now,
      :author_id => 2)
      member.destroy

      with_settings :plugin_redmine_extended_watchers => { 'policy' => 'protected' } do

        ActionMailer::Base.deliveries.clear

        Mailer.reminders(:days => 42)
        assert_equal 1, ActionMailer::Base.deliveries.size
        mail = last_email
        assert mail.to.include?('dlopper@somenet.foo')
        assert_mail_body_no_match 'Issue dlopper should not see', mail

        # neither if watching
        issue.add_watcher(user)
        ActionMailer::Base.deliveries.clear

        Mailer.reminders(:days => 42)
        assert_equal 1, ActionMailer::Base.deliveries.size
        mail = last_email
        assert mail.to.include?('dlopper@somenet.foo')
        assert_mail_body_no_match 'Issue dlopper should not see', mail
      end
    end
  end

  def test_extended_reminders_should_only_include_issues_the_user_can_see
    with_settings :default_language => 'en' do
      user = User.find(3)
      member = Member.create!(:project_id => 2, :principal => user, :role_ids => [1])
      issue = Issue.create!(:project_id => 2, :tracker_id => 1, :status_id => 1,
      :subject => 'Issue dlopper should not see', :assigned_to_id => 3,
      :due_date => 5.days.from_now,
      :author_id => 2)
      member.destroy

      with_settings :plugin_redmine_extended_watchers => { 'policy' => 'extended' } do

        ActionMailer::Base.deliveries.clear

        Mailer.reminders(:days => 42)
        assert_equal 1, ActionMailer::Base.deliveries.size
        mail = last_email
        assert mail.to.include?('dlopper@somenet.foo')
        assert_mail_body_no_match 'Issue dlopper should not see', mail

        # unless if watching
        issue.add_watcher(user)
        ActionMailer::Base.deliveries.clear

        Mailer.reminders(:days => 42)
        assert_equal 1, ActionMailer::Base.deliveries.size
        mail = last_email
        assert mail.to.include?('dlopper@somenet.foo')
        assert_mail_body_match 'Issue dlopper should not see', mail
      end
    end
  end
  
  
  private

  # Returns an array of email addresses to which emails were sent
  def recipients
    ActionMailer::Base.deliveries.map(&:to).flatten.sort
  end

  def last_email
    mail = ActionMailer::Base.deliveries.last
    assert_not_nil mail
    mail
  end

end
