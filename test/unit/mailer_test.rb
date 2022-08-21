# encoding: utf-8
#
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
    nonmemember = User.find(4)
    Role.find(2).remove_permission!(:view_issues)
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'default' } do
      assert Mailer.deliver_issue_add(issue)
      assert !last_email.to.include?(user.mail)
      
      # even if user is watcher
      issue.add_watcher(user)
      user.reload
      assert Mailer.deliver_issue_add(issue)
      assert !last_email.to.include?(user.mail)
      
      # neither non members with issue view permission
      assert !last_email.to.include?(nonmemember.mail)

      # unless they are watching
      issue.add_watcher(nonmemember)
      nonmemember.reload
      assert Mailer.deliver_issue_add(issue)
      assert last_email.to.include?(nonmemember.mail)
      
      # but not if nonmembers do not have view issue permission
      Role.non_member.remove_permission!(:view_issues)
      nonmemember.reload
      assert Mailer.deliver_issue_add(issue)
      assert !last_email.to.include?(nonmemember.mail)
    end
  end

  test "#protected issue_add should notify project members that are not allow to view the issue but watch" do
    issue = Issue.find(1)
    user = User.find(3)
    nonmemember = User.find(4)
    Role.find(2).remove_permission!(:view_issues)
    assert Mailer.deliver_issue_add(issue)
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'protected' } do
      assert Mailer.deliver_issue_add(issue)
      assert !last_email.to.include?(user.mail)
      
      # even if member user is watcher, but without view issue permission
      issue.add_watcher(user)
      user.reload
      assert Mailer.deliver_issue_add(issue)
      assert !last_email.to.include?(user.mail)
      
      # neither non members with issue view permission
      assert !last_email.to.include?(nonmemember.mail)

      # unless they are watching
      issue.add_watcher(nonmemember)
      nonmemember.reload
      assert Mailer.deliver_issue_add(issue)
      assert last_email.to.include?(nonmemember.mail)
      
      # but not if nonmembers do not have view issue permission
      Role.non_member.remove_permission!(:view_issues)
      nonmemember.reload
      assert Mailer.deliver_issue_add(issue)
      assert !last_email.to.include?(nonmemember.mail)
    end
  end

  test "#extended issue_add should notify project members that are not allow to view the issue but watch" do
    issue = Issue.find(1)
    user = User.find(3)
    nonmemember = User.find(4)
    Role.find(2).remove_permission!(:view_issues)
    assert Mailer.deliver_issue_add(issue)
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'extended' } do
      assert Mailer.deliver_issue_add(issue)
      assert !last_email.to.include?(user.mail)
      
      # unless user is watcher
      issue.add_watcher(user)
      user.reload
      assert Mailer.deliver_issue_add(issue)
      assert last_email.to.include?(user.mail)
      
      # not for non members with issue view permission
      assert !last_email.to.include?(nonmemember.mail)

      # unless they are watching
      issue.add_watcher(nonmemember)
      nonmemember.reload
      assert Mailer.deliver_issue_add(issue)
      assert last_email.to.include?(nonmemember.mail)
      
      # even if nonmembers do not have view issue permission
      Role.non_member.remove_permission!(:view_issues)
      nonmemember.reload
      assert Mailer.deliver_issue_add(issue)
      assert last_email.to.include?(nonmemember.mail)
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
      assert last_email.to.include?(user.mail)
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
      assert last_email.to.include?(user.mail)
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
      assert last_email.to.include?(user.mail)
    end
  end

  
  test "#default issue_add should not notify watchers not allowed to view the issue" do
    issue = Issue.find(1)
    user = User.find(9)
    Watcher.create!(:watchable => issue, :user => user)
    Role.non_member.remove_permission!(:view_issues)
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'default' } do
      assert Mailer.deliver_issue_add(issue)
      assert !last_email.to.include?(user.mail)
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
      assert !last_email.to.include?(user.mail)
    end
  end

  test "#extended issue_add should not notify watchers not allowed to view the issue" do
    issue = Issue.find(1)
    user = User.find(9)
    Watcher.create!(:watchable => issue, :user => user)
    Role.non_member.remove_permission!(:view_issues)
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'extended' } do
      # the plugin provides full watching features, including notifications, also to watchers with no membership
      assert Mailer.deliver_issue_add(issue)
      assert last_email.to.include?(user.mail)
    end
  end

  
  def test_issue_edit_should_send_private_notes_to_watchers_with_permission_only
    Issue.find(1).set_watcher(User.find_by_login('someone'))
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
    end

    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'protected' } do
      Role.non_member.add_permission! :view_private_notes
      Mailer.deliver_issue_edit(journal)
      assert_include 'someone@foo.bar', ActionMailer::Base.deliveries.last.to.sort

      Role.non_member.remove_permission! :view_private_notes
      Mailer.deliver_issue_edit(journal)
      assert_not_include 'someone@foo.bar', ActionMailer::Base.deliveries.last.to.sort
    end

    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'extended' } do
      Role.non_member.add_permission! :view_private_notes
      Mailer.deliver_issue_edit(journal)
      assert_include 'someone@foo.bar', ActionMailer::Base.deliveries.last.to.sort

      Role.non_member.remove_permission! :view_private_notes
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

  def last_email
    mail = ActionMailer::Base.deliveries.last
    assert_not_nil mail
    mail
  end

end
