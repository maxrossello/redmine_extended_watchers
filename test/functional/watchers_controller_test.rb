# Extended Watchers plugin for Redmine
# Copyright (C) 2013-  Massimo Rossello
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

class ExtWatchWatchersControllerTest < Redmine::ControllerTest
  tests WatchersController
  fixtures :projects, :users, :roles, :members, :member_roles, :enabled_modules,
           :issues, :trackers, :projects_trackers, :issue_statuses, :enumerations, :watchers,
           :groups_users

  def setup
    User.current = nil
    Role.find(2).add_permission!(:add_issue_watchers)
  end

  # addable_watcher_users are the first users listed with empty search field
  # users_for_new_watcher are the users listed after a search string is provided

  def test_default_users_for_new_watcher_public
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'default' } do
      @request.session[:user_id] = 2

      get :autocomplete_for_user, :params => {:q => 'robert', :project_id => 'ecookbook'}, :xhr => true
      assert_response :success
      assert_select 'input', :count => 1
      assert_select 'input[name=?][value="4"]', 'watcher[user_ids][]'

      get :autocomplete_for_user, :params => {:q => 'dave', :project_id => 'ecookbook'}, :xhr => true
      assert_response :success
      assert_select 'input', :count => 1
      assert_select 'input[name=?][value="3"]', 'watcher[user_ids][]'
      assert_select 'input[name=?][value="5"]', 'watcher[user_ids][]', :count => 0
      
      Role.non_member.remove_permission!(:view_issues)

      get :autocomplete_for_user, :params => {:q => 'robert', :project_id => 'ecookbook'}, :xhr => true
      assert_response :success
      assert_select 'input', :count => 1
      assert_select 'input[name=?][value="4"]', 'watcher[user_ids][]'

      get :autocomplete_for_user, :params => {:q => 'dave', :project_id => 'ecookbook'}, :xhr => true
      assert_response :success
      assert_select 'input', :count => 1
      assert_select 'input[name=?][value="3"]', 'watcher[user_ids][]'
      assert_select 'input[name=?][value="5"]', 'watcher[user_ids][]', :count => 0
    end
  end  
  
  def test_protected_users_for_new_watcher_public
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'protected' } do
      @request.session[:user_id] = 2

      get :autocomplete_for_user, :params => {:q => 'robert', :project_id => 'ecookbook'}, :xhr => true
      assert_response :success
      assert_select 'input', :count => 1
      assert_select 'input[name=?][value="4"]', 'watcher[user_ids][]'

      get :autocomplete_for_user, :params => {:q => 'dave', :project_id => 'ecookbook'}, :xhr => true
      assert_response :success
      assert_select 'input', :count => 1
      assert_select 'input[name=?][value="3"]', 'watcher[user_ids][]'
      assert_select 'input[name=?][value="5"]', 'watcher[user_ids][]', :count => 0
      
      Role.non_member.remove_permission!(:view_issues)

      get :autocomplete_for_user, :params => {:q => 'robert', :project_id => 'ecookbook'}, :xhr => true
      assert_response :success
      assert @response.body.blank?

      get :autocomplete_for_user, :params => {:q => 'dave', :project_id => 'ecookbook'}, :xhr => true
      assert_response :success
      assert_select 'input', :count => 1
      assert_select 'input[name=?][value="3"]', 'watcher[user_ids][]'
      assert_select 'input[name=?][value="5"]', 'watcher[user_ids][]', :count => 0
    end
  end  

  def test_extended_users_for_new_watcher_public
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'extended' } do
      @request.session[:user_id] = 2

      get :autocomplete_for_user, :params => {:q => 'robert', :project_id => 'ecookbook'}, :xhr => true
      assert_response :success
      assert_select 'input', :count => 1
      assert_select 'input[name=?][value="4"]', 'watcher[user_ids][]'

      get :autocomplete_for_user, :params => {:q => 'dave', :project_id => 'ecookbook'}, :xhr => true
      assert_response :success
      assert_select 'input', :count => 1
      assert_select 'input[name=?][value="3"]', 'watcher[user_ids][]'
      assert_select 'input[name=?][value="5"]', 'watcher[user_ids][]', :count => 0
      
      Role.non_member.remove_permission!(:view_issues)

      get :autocomplete_for_user, :params => {:q => 'robert', :project_id => 'ecookbook'}, :xhr => true
      assert_response :success
      assert_select 'input', :count => 1
      assert_select 'input[name=?][value="4"]', 'watcher[user_ids][]'

      get :autocomplete_for_user, :params => {:q => 'dave', :project_id => 'ecookbook'}, :xhr => true
      assert_response :success
      assert_select 'input', :count => 1
      assert_select 'input[name=?][value="3"]', 'watcher[user_ids][]'
      assert_select 'input[name=?][value="5"]', 'watcher[user_ids][]', :count => 0
    end
  end  

  def test_default_users_for_new_watcher_private
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'default' } do
      @request.session[:user_id] = 2

      get :autocomplete_for_user, :params => {:q => 'robert', :project_id => 'onlinestore'}, :xhr => true
      assert_response :success
      assert_select 'input', :count => 1
      assert_select 'input[name=?][value="4"]', 'watcher[user_ids][]'

      get :autocomplete_for_user, :params => {:q => 'dave', :project_id => 'onlinestore'}, :xhr => true
      assert_response :success
      assert_select 'input', :count => 1
      assert_select 'input[name=?][value="3"]', 'watcher[user_ids][]'
      assert_select 'input[name=?][value="5"]', 'watcher[user_ids][]', :count => 0
      
      # for private projects, this does not make a change
      Role.non_member.remove_permission!(:view_issues)

      get :autocomplete_for_user, :params => {:q => 'robert', :project_id => 'onlinestore'}, :xhr => true
      assert_response :success
      assert_select 'input', :count => 1
      assert_select 'input[name=?][value="4"]', 'watcher[user_ids][]'

      get :autocomplete_for_user, :params => {:q => 'dave', :project_id => 'onlinestore'}, :xhr => true
      assert_response :success
      assert_select 'input', :count => 1
      assert_select 'input[name=?][value="3"]', 'watcher[user_ids][]'
      assert_select 'input[name=?][value="5"]', 'watcher[user_ids][]', :count => 0

    end
  end  
  
  def test_protected_users_for_new_watcher_private
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'protected' } do
      @request.session[:user_id] = 2

      get :autocomplete_for_user, :params => {:q => 'robert', :project_id => 'onlinestore'}, :xhr => true
      assert_response :success
      assert @response.body.blank?

      get :autocomplete_for_user, :params => {:q => 'misc', :project_id => 'onlinestore'}, :xhr => true
      assert_response :success
      assert_select 'input', :count => 1
      assert_select 'input[name=?][value="8"]', 'watcher[user_ids][]'
      assert_select 'input[name=?][value="2"]', 'watcher[user_ids][]', :count => 0
      assert_select 'input[name=?][value="9"]', 'watcher[user_ids][]', :count => 0
      
      # for private projects, this does not make a change
      Role.non_member.remove_permission!(:view_issues)

      get :autocomplete_for_user, :params => {:q => 'robert', :project_id => 'onlinestore'}, :xhr => true
      assert_response :success
      assert @response.body.blank?

      get :autocomplete_for_user, :params => {:q => 'misc', :project_id => 'onlinestore'}, :xhr => true
      assert_response :success
      assert_select 'input', :count => 1
      assert_select 'input[name=?][value="8"]', 'watcher[user_ids][]'
      assert_select 'input[name=?][value="2"]', 'watcher[user_ids][]', :count => 0
      assert_select 'input[name=?][value="9"]', 'watcher[user_ids][]', :count => 0
    end
  end  

  def test_extended_users_for_new_watcher_private
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'extended' } do
      @request.session[:user_id] = 2

      get :autocomplete_for_user, :params => {:q => 'robert', :project_id => 'onlinestore'}, :xhr => true
      assert_response :success
      assert_select 'input', :count => 1
      assert_select 'input[name=?][value="4"]', 'watcher[user_ids][]'

      get :autocomplete_for_user, :params => {:q => 'dave', :project_id => 'onlinestore'}, :xhr => true
      assert_response :success
      assert_select 'input', :count => 1
      assert_select 'input[name=?][value="3"]', 'watcher[user_ids][]'
      assert_select 'input[name=?][value="5"]', 'watcher[user_ids][]', :count => 0
      
      # for private projects, this does not make a change
      Role.non_member.remove_permission!(:view_issues)

      get :autocomplete_for_user, :params => {:q => 'robert', :project_id => 'onlinestore'}, :xhr => true
      assert_response :success
      assert_select 'input', :count => 1
      assert_select 'input[name=?][value="4"]', 'watcher[user_ids][]'

      get :autocomplete_for_user, :params => {:q => 'dave', :project_id => 'onlinestore'}, :xhr => true
      assert_response :success
      assert_select 'input', :count => 1
      assert_select 'input[name=?][value="3"]', 'watcher[user_ids][]'
      assert_select 'input[name=?][value="5"]', 'watcher[user_ids][]', :count => 0
    end
  end  

  
  def test_default_watch_should_be_denied_without_view_issue_permission
    Role.find(2).remove_permission! :view_issues
    @request.session[:user_id] = 3
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'default' } do
      assert_no_difference('Watcher.count') do
        post :watch, :params => {:object_type => 'issue', :object_id => '1'}, :xhr => true
        assert_response 403
      end
    end
  end

  def test_protected_watch_should_be_denied_without_view_issue_permission
    Role.find(2).remove_permission! :view_issues
    @request.session[:user_id] = 3
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'protected' } do
      assert_no_difference('Watcher.count') do
        post :watch, :params => {:object_type => 'issue', :object_id => '1'}, :xhr => true
        assert_response 403
      end
    end
  end

  def test_extended_watch_should_be_denied_without_view_issue_permission
    Role.find(2).remove_permission! :view_issues
    @request.session[:user_id] = 3
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'extended' } do
      assert_no_difference('Watcher.count') do
        post :watch, :params => {:object_type => 'issue', :object_id => '1'}, :xhr => true
        assert_response 403
      end
    end
  end

  
  def test_default_watch_invalid_object_should_respond_with_404
    @request.session[:user_id] = 3
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'default' } do
      assert_no_difference('Watcher.count') do
        post :watch, :params => {:object_type => 'issue', :object_id => '999'}, :xhr => true
        assert_response 404
      end
    end
  end

  def test_protected_watch_invalid_object_should_respond_with_404
    @request.session[:user_id] = 3
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'protected' } do
      assert_no_difference('Watcher.count') do
        post :watch, :params => {:object_type => 'issue', :object_id => '999'}, :xhr => true
        assert_response 404
      end
    end
  end

  def test_extended_watch_invalid_object_should_respond_with_404
    @request.session[:user_id] = 3
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'extended' } do
      assert_no_difference('Watcher.count') do
        post :watch, :params => {:object_type => 'issue', :object_id => '999'}, :xhr => true
        assert_response 404
      end
    end
  end


  def test_default_autocomplete_on_watchable_creation_public
    @request.session[:user_id] = 2
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'default' } do
      get :autocomplete_for_user, :params => {:q => 'mi', :project_id => 'ecookbook'}, :xhr => true
      assert_response :success
      assert_select 'input', :count => 4
      assert_select 'input[name=?][value="1"]', 'watcher[user_ids][]'
      assert_select 'input[name=?][value="2"]', 'watcher[user_ids][]'
      assert_select 'input[name=?][value="8"]', 'watcher[user_ids][]'
      assert_select 'input[name=?][value="9"]', 'watcher[user_ids][]'
      
      Role.non_member.remove_permission!(:view_issues)

      get :autocomplete_for_user, :params => {:q => 'mi', :project_id => 'ecookbook'}, :xhr => true
      assert_response :success
      assert_select 'input', :count => 4
      assert_select 'input[name=?][value="1"]', 'watcher[user_ids][]'
      assert_select 'input[name=?][value="2"]', 'watcher[user_ids][]'
      assert_select 'input[name=?][value="8"]', 'watcher[user_ids][]'
      assert_select 'input[name=?][value="9"]', 'watcher[user_ids][]'
    end
  end

  def test_protected_autocomplete_on_watchable_creation_public
    @request.session[:user_id] = 2
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'protected' } do
      get :autocomplete_for_user, :params => {:q => 'mi', :project_id => 'ecookbook'}, :xhr => true
      assert_response :success
      assert_select 'input', :count => 4
      assert_select 'input[name=?][value="1"]', 'watcher[user_ids][]'
      assert_select 'input[name=?][value="2"]', 'watcher[user_ids][]'
      assert_select 'input[name=?][value="8"]', 'watcher[user_ids][]'
      assert_select 'input[name=?][value="9"]', 'watcher[user_ids][]'
      
      Role.non_member.remove_permission!(:view_issues)

      get :autocomplete_for_user, :params => {:q => 'mi', :project_id => 'ecookbook'}, :xhr => true
      assert_response :success
      assert_select 'input', :count => 2
      assert_select 'input[name=?][value="1"]', 'watcher[user_ids][]'
      assert_select 'input[name=?][value="2"]', 'watcher[user_ids][]'
      assert_select 'input[name=?][value="8"]', 'watcher[user_ids][]', :count => 0
      assert_select 'input[name=?][value="9"]', 'watcher[user_ids][]', :count => 0
    end
  end

  def test_extended_autocomplete_on_watchable_creation_public
    @request.session[:user_id] = 2
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'extended' } do
      get :autocomplete_for_user, :params => {:q => 'mi', :project_id => 'ecookbook'}, :xhr => true
      assert_response :success
      assert_select 'input', :count => 4
      assert_select 'input[name=?][value="1"]', 'watcher[user_ids][]'
      assert_select 'input[name=?][value="2"]', 'watcher[user_ids][]'
      assert_select 'input[name=?][value="8"]', 'watcher[user_ids][]'
      assert_select 'input[name=?][value="9"]', 'watcher[user_ids][]'
      
      Role.non_member.remove_permission!(:view_issues)

      get :autocomplete_for_user, :params => {:q => 'mi', :project_id => 'ecookbook'}, :xhr => true
      assert_response :success
      assert_select 'input', :count => 4
      assert_select 'input[name=?][value="1"]', 'watcher[user_ids][]'
      assert_select 'input[name=?][value="2"]', 'watcher[user_ids][]'
      assert_select 'input[name=?][value="8"]', 'watcher[user_ids][]'
      assert_select 'input[name=?][value="9"]', 'watcher[user_ids][]'
    end
  end

  def test_default_autocomplete_on_watchable_creation_private
    @request.session[:user_id] = 2
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'default' } do
      get :autocomplete_for_user, :params => {:q => 'mi', :project_id => 'onlinestore'}, :xhr => true
      assert_response :success
      assert_select 'input', :count => 4
      assert_select 'input[name=?][value="1"]', 'watcher[user_ids][]'
      assert_select 'input[name=?][value="2"]', 'watcher[user_ids][]'
      assert_select 'input[name=?][value="8"]', 'watcher[user_ids][]'
      assert_select 'input[name=?][value="9"]', 'watcher[user_ids][]'
      
      # for private projects, this does not make a change
      Role.non_member.remove_permission!(:view_issues)

      get :autocomplete_for_user, :params => {:q => 'mi', :project_id => 'onlinestore'}, :xhr => true
      assert_response :success
      assert_select 'input', :count => 4
      assert_select 'input[name=?][value="1"]', 'watcher[user_ids][]'
      assert_select 'input[name=?][value="2"]', 'watcher[user_ids][]'
      assert_select 'input[name=?][value="8"]', 'watcher[user_ids][]'
      assert_select 'input[name=?][value="9"]', 'watcher[user_ids][]'
    end
  end

  def test_protected_autocomplete_on_watchable_creation_private
    @request.session[:user_id] = 2
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'protected' } do
      get :autocomplete_for_user, :params => {:q => 'mi', :project_id => 'onlinestore'}, :xhr => true
      assert_response :success
      assert_select 'input', :count => 3
      assert_select 'input[name=?][value="1"]', 'watcher[user_ids][]'
      assert_select 'input[name=?][value="2"]', 'watcher[user_ids][]'
      assert_select 'input[name=?][value="8"]', 'watcher[user_ids][]'
      assert_select 'input[name=?][value="9"]', 'watcher[user_ids][]', :count => 0
      
      # for private projects, this does not make a change
      Role.non_member.remove_permission!(:view_issues)

      get :autocomplete_for_user, :params => {:q => 'mi', :project_id => 'onlinestore'}, :xhr => true
      assert_response :success
      assert_select 'input', :count => 3
      assert_select 'input[name=?][value="1"]', 'watcher[user_ids][]'
      assert_select 'input[name=?][value="2"]', 'watcher[user_ids][]'
      assert_select 'input[name=?][value="8"]', 'watcher[user_ids][]'
      assert_select 'input[name=?][value="9"]', 'watcher[user_ids][]', :count => 0
    end
  end

  def test_extended_autocomplete_on_watchable_creation_private
    @request.session[:user_id] = 2
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'extended' } do
      get :autocomplete_for_user, :params => {:q => 'mi', :project_id => 'onlinestore'}, :xhr => true
      assert_response :success
      assert_select 'input', :count => 4
      assert_select 'input[name=?][value="1"]', 'watcher[user_ids][]'
      assert_select 'input[name=?][value="2"]', 'watcher[user_ids][]'
      assert_select 'input[name=?][value="8"]', 'watcher[user_ids][]'
      assert_select 'input[name=?][value="9"]', 'watcher[user_ids][]'

      # for private projects, this does not make a change
      Role.non_member.remove_permission!(:view_issues)

      get :autocomplete_for_user, :params => {:q => 'mi', :project_id => 'onlinestore'}, :xhr => true
      assert_response :success
      assert_select 'input', :count => 4
      assert_select 'input[name=?][value="1"]', 'watcher[user_ids][]'
      assert_select 'input[name=?][value="2"]', 'watcher[user_ids][]'
      assert_select 'input[name=?][value="8"]', 'watcher[user_ids][]'
      assert_select 'input[name=?][value="9"]', 'watcher[user_ids][]'
    end
  end

  
  def test_default_search_non_member_on_create_public
    @request.session[:user_id] = 2
    project = Project.find_by_name("ecookbook")
    user = User.generate!(:firstname => 'issue15622')
    membership = user.membership(project)
    assert_nil membership
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'default' } do
      get :autocomplete_for_user, :params => {:q => 'issue15622', :project_id => 'ecookbook'}, :xhr => true
      assert_response :success
      assert_select 'input', :count => 1
      
      Role.non_member.remove_permission!(:view_issues)

      get :autocomplete_for_user, :params => {:q => 'issue15622', :project_id => 'ecookbook'}, :xhr => true
      assert_response :success
      assert_select 'input', :count => 1
    end
  end

  def test_protected_search_non_member_on_create_public
    @request.session[:user_id] = 2
    project = Project.find_by_name("ecookbook")
    user = User.generate!(:firstname => 'issue15622')
    membership = user.membership(project)
    assert_nil membership
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'protected' } do
      get :autocomplete_for_user, :params => {:q => 'issue15622', :project_id => 'ecookbook'}, :xhr => true
      assert_response :success
      assert_select 'input', :count => 1
      
      Role.non_member.remove_permission!(:view_issues)

      get :autocomplete_for_user, :params => {:q => 'issue15622', :project_id => 'ecookbook'}, :xhr => true
      assert_response :success
      assert @response.body.blank?
    end
  end

  def test_extended_search_non_member_on_create_public
    @request.session[:user_id] = 2
    project = Project.find_by_name("ecookbook")
    user = User.generate!(:firstname => 'issue15622')
    membership = user.membership(project)
    assert_nil membership
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'extended' } do
      get :autocomplete_for_user, :params => {:q => 'issue15622', :project_id => 'ecookbook'}, :xhr => true
      assert_response :success
      assert_select 'input', :count => 1

      Role.non_member.remove_permission!(:view_issues)
      
      get :autocomplete_for_user, :params => {:q => 'issue15622', :project_id => 'ecookbook'}, :xhr => true
      assert_response :success
      assert_select 'input', :count => 1
    end
  end
  
  def test_default_search_non_member_on_create_private
    @request.session[:user_id] = 2
    project = Project.find_by_name("ecookbook")
    user = User.generate!(:firstname => 'issue15622')
    membership = user.membership(project)
    assert_nil membership
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'default' } do
      get :autocomplete_for_user, :params => {:q => 'issue15622', :project_id => 'onlinestore'}, :xhr => true
      assert_response :success
      assert_select 'input', :count => 1

      # for private projects, this does not make a change
      Role.non_member.remove_permission!(:view_issues)

      get :autocomplete_for_user, :params => {:q => 'issue15622', :project_id => 'onlinestore'}, :xhr => true
      assert_response :success
      assert_select 'input', :count => 1
    end
  end

  def test_protected_search_non_member_on_create_private
    @request.session[:user_id] = 2
    project = Project.find_by_name("ecookbook")
    user = User.generate!(:firstname => 'issue15622')
    membership = user.membership(project)
    assert_nil membership
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'protected' } do
      get :autocomplete_for_user, :params => {:q => 'issue15622', :project_id => 'onlinestore'}, :xhr => true
      assert_response :success
      assert @response.body.blank?

      # for private projects, this does not make a change
      Role.non_member.remove_permission!(:view_issues)

      get :autocomplete_for_user, :params => {:q => 'issue15622', :project_id => 'onlinestore'}, :xhr => true
      assert_response :success
      assert @response.body.blank?
    end
  end

  def test_extended_search_non_member_on_create_private
    @request.session[:user_id] = 2
    project = Project.find_by_name("ecookbook")
    user = User.generate!(:firstname => 'issue15622')
    membership = user.membership(project)
    assert_nil membership
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'extended' } do
      get :autocomplete_for_user, :params => {:q => 'issue15622', :project_id => 'onlinestore'}, :xhr => true
      assert_response :success
      assert_select 'input', :count => 1
      
      # for private projects, this does not make a change
      Role.non_member.remove_permission!(:view_issues)

      get :autocomplete_for_user, :params => {:q => 'issue15622', :project_id => 'onlinestore'}, :xhr => true
      assert_response :success
      assert_select 'input', :count => 1
    end
  end


  def test_default_autocomplete_for_user_should_return_visible_users_public
    Role.update_all :users_visibility => 'members_of_visible_projects'

    hidden = User.generate!(:lastname => 'autocomplete_hidden')
    visible = User.generate!(:lastname => 'autocomplete_visible')
    User.add_to_project(visible, Project.find(1))

    @request.session[:user_id] = 2
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'default' } do
      get :autocomplete_for_user, :params => {:q => 'autocomp', :project_id => 'ecookbook'}, :xhr => true
      assert_response :success

      assert_include visible.name, response.body
      assert_not_include hidden.name, response.body
    end
  end

  def test_protected_autocomplete_for_user_should_return_visible_users_public
    Role.update_all :users_visibility => 'members_of_visible_projects'

    hidden = User.generate!(:lastname => 'autocomplete_hidden')
    visible = User.generate!(:lastname => 'autocomplete_visible')
    User.add_to_project(visible, Project.find(1))

    @request.session[:user_id] = 2
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'protected' } do
      get :autocomplete_for_user, :params => {:q => 'autocomp', :project_id => 'ecookbook'}, :xhr => true
      assert_response :success

      assert_include visible.name, response.body
      assert_not_include hidden.name, response.body
    end
  end
  
  def test_extended_autocomplete_for_user_should_return_all_users_public
    Role.update_all :users_visibility => 'members_of_visible_projects'

    hidden = User.generate!(:lastname => 'autocomplete_hidden')
    visible = User.generate!(:lastname => 'autocomplete_visible')
    User.add_to_project(visible, Project.find(1))

    @request.session[:user_id] = 2
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'extended' } do
      get :autocomplete_for_user, :params => {:q => 'autocomp', :project_id => 'ecookbook'}, :xhr => true
      assert_response :success

      assert_include visible.name, response.body
      assert_include hidden.name, response.body
    end
  end

  def test_default_autocomplete_for_user_should_return_visible_users_private
    Role.update_all :users_visibility => 'members_of_visible_projects'

    hidden = User.generate!(:lastname => 'autocomplete_hidden')
    visible = User.generate!(:lastname => 'autocomplete_visible')
    User.add_to_project(visible, Project.find(1))

    @request.session[:user_id] = 2
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'default' } do
      get :autocomplete_for_user, :params => {:q => 'autocomp', :project_id => 'onlinestore'}, :xhr => true
      assert_response :success

      assert_include visible.name, response.body
      assert_not_include hidden.name, response.body
    end
  end

  def test_protected_autocomplete_for_user_should_return_visible_users_private
    Role.update_all :users_visibility => 'members_of_visible_projects'

    hidden = User.generate!(:lastname => 'autocomplete_hidden')
    visible = User.generate!(:lastname => 'autocomplete_visible')
    User.add_to_project(visible, Project.find(1))

    @request.session[:user_id] = 2
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'protected' } do
      get :autocomplete_for_user, :params => {:q => 'autocomp', :project_id => 'onlinestore'}, :xhr => true
      assert_response :success

      # visible has no view permission into onlinestore
      assert_not_include visible.name, response.body
      assert_not_include hidden.name, response.body
    end
  end
  
  def test_extended_autocomplete_for_user_should_return_all_users_private
    Role.update_all :users_visibility => 'members_of_visible_projects'

    hidden = User.generate!(:lastname => 'autocomplete_hidden')
    visible = User.generate!(:lastname => 'autocomplete_visible')
    User.add_to_project(visible, Project.find(1))

    @request.session[:user_id] = 2
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'extended' } do
      get :autocomplete_for_user, :params => {:q => 'autocomp', :project_id => 'onlinestore'}, :xhr => true
      assert_response :success

      assert_include visible.name, response.body
      assert_include hidden.name, response.body
    end
  end
  
  
  
  def test_default_autocomplete_for_user_should_not_return_users_without_object_visibility
    @request.session[:user_id] = 1
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'default' } do
      get :autocomplete_for_user, :params => {
        q: 'rober',
        project_id: 'onlinestore',
        object_id: '4',
        object_type: 'issue'
      }, :xhr => true

      assert_response :success

      assert response.body.blank?
    end
  end

  def test_protected_autocomplete_for_user_should_not_return_users_without_object_visibility
    @request.session[:user_id] = 1
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'protected' } do
      get :autocomplete_for_user, :params => {
        q: 'rober',
        project_id: 'onlinestore',
        object_id: '4',
        object_type: 'issue'
      }, :xhr => true

      assert_response :success

      assert response.body.blank?
    end
  end

  def test_extended_autocomplete_for_user_should_also_return_users_without_object_visibility
    @request.session[:user_id] = 1
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'extended' } do
      get :autocomplete_for_user, :params => {
        q: 'rober',
        project_id: 'onlinestore',
        object_id: '4',
        object_type: 'issue'
      }, :xhr => true

      assert_response :success

      assert !response.body.blank?
    end
  end
	
  
  
  def test_default_watcher_user_create_refresh_in_sidebar
    @request.session[:user_id] = 2
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'default' } do
      assert_difference('Watcher.count') do
        post :create, :params => {
          :object_type => 'issue', :object_id => '6',
          :watcher => {:user_id => '8'}
        }, :xhr => true
        assert_response :success
        assert_match /watchers/, response.body
        assert_match /ajax-modal/, response.body
      end
      assert Issue.find(6).watched_by?(User.find(8))
    end
  end

  def test_protected_watcher_user_create_refresh_in_sidebar
    @request.session[:user_id] = 2
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'protected' } do
      assert_difference('Watcher.count') do
        post :create, :params => {
          :object_type => 'issue', :object_id => '6',
          :watcher => {:user_id => '8'}
        }, :xhr => true
        assert_response :success
        assert_match /watchers/, response.body
        assert_match /ajax-modal/, response.body
      end
      assert Issue.find(6).watched_by?(User.find(8))
    end
  end

  def test_extended_watcher_user_create_refresh_in_sidebar
    @request.session[:user_id] = 2
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'extended' } do
      assert_difference('Watcher.count') do
        post :create, :params => {
          :object_type => 'issue', :object_id => '6',
          :watcher => {:user_id => '8'}
        }, :xhr => true
        assert_response :success
        assert_match /watchers/, response.body
        assert_match /ajax-modal/, response.body
      end
      assert Issue.find(6).watched_by?(User.find(8))
    end
  end



  # nonmember user that cannot view project issues
  def test_default_watcher_nonmember_user_create_refresh_in_sidebar
    @request.session[:user_id] = 2
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'default' } do
      assert_no_difference('Watcher.count') do
        post :create, :params => {
          :object_type => 'issue', :object_id => '6',
          :watcher => {:user_id => '4'}
        }, :xhr => true
        assert_response :success
        assert_match /watchers/, response.body
        assert_match /ajax-modal/, response.body
      end
      assert !Issue.find(6).watched_by?(User.find(4))
    end
  end

  def test_protected_watcher_nonmember_user_create_refresh_in_sidebar
    @request.session[:user_id] = 2
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'protected' } do
      assert_no_difference('Watcher.count') do
        post :create, :params => {
          :object_type => 'issue', :object_id => '6',
          :watcher => {:user_id => '4'}
        }, :xhr => true
        assert_response :success
        assert_match /watchers/, response.body
        assert_match /ajax-modal/, response.body
      end
      assert !Issue.find(6).watched_by?(User.find(4))
    end
  end

  def test_extended_watcher_nonmember_user_create_refresh_in_sidebar
    @request.session[:user_id] = 2
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'extended' } do
      assert_difference('Watcher.count') do
        post :create, :params => {
          :object_type => 'issue', :object_id => '6',
          :watcher => {:user_id => '4'}
        }, :xhr => true
        assert_response :success
        assert_match /watchers/, response.body
        assert_match /ajax-modal/, response.body
      end
      assert Issue.find(6).watched_by?(User.find(4))
    end
  end
  
  
  
  def test_default_watcher_group_create_refresh_in_sidebar
    @request.session[:user_id] = 2
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'default' } do
      assert_difference('Watcher.count') do
        post :create, :params => {
          :object_type => 'issue', :object_id => '6',
          :watcher => {:user_id => '10'}
        }, :xhr => true
        assert_response :success
        assert_match /watchers/, response.body
        assert_match /ajax-modal/, response.body
      end
      assert Issue.find(6).watched_by?(Group.find(10))
    end
  end

  def test_protected_watcher_group_create_refresh_in_sidebar
    @request.session[:user_id] = 2
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'protected' } do
      assert_difference('Watcher.count') do
        post :create, :params => {
          :object_type => 'issue', :object_id => '6',
          :watcher => {:user_id => '10'}
        }, :xhr => true
        assert_response :success
        assert_match /watchers/, response.body
        assert_match /ajax-modal/, response.body
      end
      assert Issue.find(6).watched_by?(Group.find(10))
    end
  end

  def test_extended_watcher_group_create_refresh_in_sidebar
    @request.session[:user_id] = 2
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'extended' } do
      assert_difference('Watcher.count') do
        post :create, :params => {
          :object_type => 'issue', :object_id => '6',
          :watcher => {:user_id => '10'}
        }, :xhr => true
        assert_response :success
        assert_match /watchers/, response.body
        assert_match /ajax-modal/, response.body
      end
      assert Issue.find(6).watched_by?(Group.find(10))
    end
  end

end
