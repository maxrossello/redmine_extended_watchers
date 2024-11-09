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

class ExtWatchProjectsControllerTest < Redmine::ControllerTest
  tests ProjectsController
  fixtures :projects, :users, :roles, :members, :member_roles, :enabled_modules,
           :issues, :trackers, :projects_trackers, :issue_statuses, :enumerations, :watchers

  def setup
    User.current = nil
    Role.find(2).add_permission!(:add_issue_watchers)    
  end

  def test_default_watcher_public_project_index_list
    # project visibility also depends on visibility of other modules than issues, so generate new one
    @project = Project.generate!(:name => "dummy", :is_public => true)
    @project.add_default_member(User.find(2))
      
    @issue = Issue.generate!(:project => @project)
    @issue.add_watcher(User.find(2))
    @issue.add_watcher(User.find(4))
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'default' } do
      @request.session[:user_id] = 2
      get :index
      assert_select 'a.project', { text: @project.name }
      @request.session[:user_id] = 4
      get :index
      assert_select 'a.project', { text: @project.name }

      # nonmember role anyway has :view_projects permission on public projects        
      Role.non_member.remove_permission!(:view_issues)
      @request.session[:user_id] = 2
      get :index
      assert_select 'a.project', { text: @project.name }
      @request.session[:user_id] = 4
      get :index
      assert_select 'a.project', { text: @project.name }
    end
  end
  
  def test_protected_watcher_public_project_index_list
    # project visibility also depends on visibility of other modules than issues, so generate new one
    @project = Project.generate!(:name => "dummy", :is_public => true)
    @project.add_default_member(User.find(2))
      
    @issue = Issue.generate!(:project => @project)
    @issue.add_watcher(User.find(2))
    @issue.add_watcher(User.find(4))
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'protected' } do
      @request.session[:user_id] = 2
      get :index
      assert_select 'a.project', { text: @project.name }
      @request.session[:user_id] = 4
      get :index
      assert_select 'a.project', { text: @project.name }

      # nonmember role anyway has :view_projects permission on public projects        
      Role.non_member.remove_permission!(:view_issues)
      @request.session[:user_id] = 2
      get :index
      assert_select 'a.project', { text: @project.name }
      @request.session[:user_id] = 4
      get :index
      assert_select 'a.project', { text: @project.name }
    end
  end

  def test_extended_watcher_public_project_index_list
    # project visibility also depends on visibility of other modules than issues, so generate new one
    @project = Project.generate!(:name => "dummy", :is_public => true)
    @project.add_default_member(User.find(2))
      
    @issue = Issue.generate!(:project => @project)
    @issue.add_watcher(User.find(2))
    @issue.add_watcher(User.find(4))
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'extended' } do
      @request.session[:user_id] = 2
      get :index
      assert_select 'a.project', { text: @project.name }
      @request.session[:user_id] = 4
      get :index
      assert_select 'a.project', { text: @project.name }

      # nonmember role anyway has :view_projects permission on public projects        
      Role.non_member.remove_permission!(:view_issues)
      @request.session[:user_id] = 2
      get :index
      assert_select 'a.project', { text: @project.name }
      @request.session[:user_id] = 4
      get :index
      assert_select 'a.project', { text: @project.name }
    end
  end

  
  def test_default_watcher_private_project_index_list
    # project visibility also depends on visibility of other modules than issues, so generate new one
    @project = Project.generate!(:name => "dummy", :is_public => false)
    @project.add_default_member(User.find(2))
      
    @issue = Issue.generate!(:project => @project)
    @issue.add_watcher(User.find(2))
    @issue.add_watcher(User.find(4))
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'default' } do
      @request.session[:user_id] = 2
      get :index
      assert_select 'a.project', { text: @project.name }
      @request.session[:user_id] = 4
      get :index
      assert_select 'a.project', { text: @project.name, :count => 0 }

      # nonmember role has no effect on private projects        
      Role.non_member.remove_permission!(:view_issues)
      @request.session[:user_id] = 2
      get :index
      assert_select 'a.project', { text: @project.name }
      @request.session[:user_id] = 4
      get :index
      assert_select 'a.project', { text: @project.name, :count => 0 }
    end
  end

  def test_protected_watcher_private_project_index_list
    # project visibility also depends on visibility of other modules than issues, so generate new one
    @project = Project.generate!(:name => "dummy", :is_public => false)
    @project.add_default_member(User.find(2))
      
    @issue = Issue.generate!(:project => @project)
    @issue.add_watcher(User.find(2))
    @issue.add_watcher(User.find(4))
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'protected' } do
      # only watcher with view_issues permission can view project
      @request.session[:user_id] = 2
      get :index
      assert_select 'a.project', { text: @project.name }
      @request.session[:user_id] = 4
      get :index
      assert_select 'a.project', { text: @project.name, :count => 0 }

      # nonmember role has no effect on private projects        
      Role.non_member.remove_permission!(:view_issues)
      @request.session[:user_id] = 2
      get :index
      assert_select 'a.project', { text: @project.name }
      @request.session[:user_id] = 4
      get :index
      assert_select 'a.project', { text: @project.name, :count => 0 }
    end
  end

  def test_extended_watcher_private_project_index_list
    # project visibility also depends on visibility of other modules than issues, so generate new one
    @project = Project.generate!(:name => "dummy", :is_public => false)
    @project.add_default_member(User.find(2))
      
    @issue = Issue.generate!(:project => @project)
    @issue.add_watcher(User.find(2))
    @issue.add_watcher(User.find(4))
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'extended' } do
      # watching extends project visibility also to non member
      @request.session[:user_id] = 2
      get :index
      assert_select 'a.project', { text: @project.name }
      @request.session[:user_id] = 4
      get :index
      assert_select 'a.project', { text: @project.name }

      # nonmember role has no effect on private projects        
      Role.non_member.remove_permission!(:view_issues)
      @request.session[:user_id] = 2
      get :index
      assert_select 'a.project', { text: @project.name }
      @request.session[:user_id] = 4
      get :index
      assert_select 'a.project', { text: @project.name }
    end
  end

  
  def test_default_watcher_public_project_show
    # project visibility also depends on visibility of other modules than issues, so generate new one
    @project = Project.generate!(:name => "dummy", :is_public => true)
    @project.add_default_member(User.find(2))
      
    @issue = Issue.generate!(:project => @project)
    @issue.add_watcher(User.find(2))
    @issue.add_watcher(User.find(4))
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'default' } do
      @request.session[:user_id] = 2
      get :show, :params => {
        :id => @project.id
      }
      assert_response :success
      @request.session[:user_id] = 4
      get :show, :params => {
        :id => @project.id
      }
      assert_response :success

      # nonmember role anyway has :view_projects permission on public projects        
      Role.non_member.remove_permission!(:view_issues)
      @request.session[:user_id] = 2
      get :show, :params => {
        :id => @project.id
      }
      assert_response :success
      @request.session[:user_id] = 4
      get :show, :params => {
        :id => @project.id
      }
      assert_response :success
    end
  end
  
  def test_protected_watcher_public_project_show
    # project visibility also depends on visibility of other modules than issues, so generate new one
    @project = Project.generate!(:name => "dummy", :is_public => true)
    @project.add_default_member(User.find(2))
      
    @issue = Issue.generate!(:project => @project)
    @issue.add_watcher(User.find(2))
    @issue.add_watcher(User.find(4))
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'protected' } do
      @request.session[:user_id] = 2
      get :show, :params => {
        :id => @project.id
      }
      assert_response :success
      @request.session[:user_id] = 4
      get :show, :params => {
        :id => @project.id
      }
      assert_response :success

      # nonmember role anyway has :view_projects permission on public projects        
      Role.non_member.remove_permission!(:view_issues)
      @request.session[:user_id] = 2
      get :show, :params => {
        :id => @project.id
      }
      assert_response :success
      @request.session[:user_id] = 4
      get :show, :params => {
        :id => @project.id
      }
      assert_response :success
    end
  end

  def test_extended_watcher_public_project_show
    # project visibility also depends on visibility of other modules than issues, so generate new one
    @project = Project.generate!(:name => "dummy", :is_public => true)
    @project.add_default_member(User.find(2))
      
    @issue = Issue.generate!(:project => @project)
    @issue.add_watcher(User.find(2))
    @issue.add_watcher(User.find(4))
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'extended' } do
      @request.session[:user_id] = 2
      get :show, :params => {
        :id => @project.id
      }
      assert_response :success
      @request.session[:user_id] = 4
      get :show, :params => {
        :id => @project.id
      }
      assert_response :success

      # nonmember role anyway has :view_projects permission on public projects        
      Role.non_member.remove_permission!(:view_issues)
      @request.session[:user_id] = 2
      get :show, :params => {
        :id => @project.id
      }
      assert_response :success
      @request.session[:user_id] = 4
      get :show, :params => {
        :id => @project.id
      }
      assert_response :success
    end
  end

  
  def test_default_watcher_private_project_show
    # project visibility also depends on visibility of other modules than issues, so generate new one
    @project = Project.generate!(:name => "dummy", :is_public => false)
    @project.add_default_member(User.find(2))
      
    @issue = Issue.generate!(:project => @project)
    @issue.add_watcher(User.find(2))
    @issue.add_watcher(User.find(4))
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'default' } do
      @request.session[:user_id] = 2
      get :show, :params => {
        :id => @project.id
      }
      assert_response :success
      @request.session[:user_id] = 4
      get :show, :params => {
        :id => @project.id
      }
      assert_response 403

      # nonmember role has no effect on private projects        
      Role.non_member.remove_permission!(:view_issues)
      @request.session[:user_id] = 2
      get :show, :params => {
        :id => @project.id
      }
      assert_response :success
      @request.session[:user_id] = 4
      get :show, :params => {
        :id => @project.id
      }
      assert_response 403
    end
  end

  def test_protected_watcher_private_project_show
    # project visibility also depends on visibility of other modules than issues, so generate new one
    @project = Project.generate!(:name => "dummy", :is_public => false)
    @project.add_default_member(User.find(2))
      
    @issue = Issue.generate!(:project => @project)
    @issue.add_watcher(User.find(2))
    @issue.add_watcher(User.find(4))
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'protected' } do
      # only watcher with view_issues permission can view project
      @request.session[:user_id] = 2
      get :show, :params => {
        :id => @project.id
      }
      assert_response :success
      @request.session[:user_id] = 4
      get :show, :params => {
        :id => @project.id
      }
      assert_response 403

      # nonmember role has no effect on private projects        
      Role.non_member.remove_permission!(:view_issues)
      @request.session[:user_id] = 2
      get :show, :params => {
        :id => @project.id
      }
      assert_response :success
      @request.session[:user_id] = 4
      get :show, :params => {
        :id => @project.id
      }
      assert_response 403
    end
  end

  def test_extended_watcher_private_project_show
    # project visibility also depends on visibility of other modules than issues, so generate new one
    @project = Project.generate!(:name => "dummy", :is_public => false)
    @project.add_default_member(User.find(2))
      
    @issue = Issue.generate!(:project => @project)
    @issue.add_watcher(User.find(2))
    @issue.add_watcher(User.find(4))
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'extended' } do
      # watching extends project visibility also to non member
      @request.session[:user_id] = 2
      get :show, :params => {
        :id => @project.id
      }
      assert_response :success
      @request.session[:user_id] = 4
      get :show, :params => {
        :id => @project.id
      }
      # redirected to issues
      assert_response 302
      @response.header["Location"].match? '.*/issues'

      # nonmember role has no effect on private projects        
      Role.non_member.remove_permission!(:view_issues)
      @request.session[:user_id] = 2
      get :show, :params => {
        :id => @project.id
      }
      assert_response :success
      @request.session[:user_id] = 4
      get :show, :params => {
        :id => @project.id
      }
      # redirected to issues
      assert_response 302
      @response.header["Location"].match? '.*/issues'
    end
  end

  
  def test_extended_watcher_public_project_index_only_enables_issues_module
    @project = Project.generate!(:name => "dummy", :is_public => true)
    Role.non_member.remove_permission!(:view_issues)
    @issue = Issue.generate!(:project => @project)
    @issue.add_watcher(User.find(2))
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'extended' } do
      @request.session[:user_id] = 2
      get :index, :params => {
        :id => @project.id
      }
      assert_response :success
      assert_select '.tabs ul li .issues', { text: I18n.t(:label_issue_plural) }
      assert_select '.tabs ul li .overview', { count: 0 }
    end
  end

  
  def test_extended_watcher_private_project_index_only_enables_issues_module
    @project = Project.generate!(:name => "dummy", :is_public => false)
    @issue = Issue.generate!(:project => @project)
    @issue.add_watcher(User.find(2))
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'extended' } do
      @request.session[:user_id] = 2
      get :index, :params => {
        :id => @project.id
      }
      assert_response :success
      assert_select '.tabs ul li .issues', { text: I18n.t(:label_issue_plural) }
      assert_select '.tabs ul li .overview', { count: 0 }
    end
  end
  
  
  # public project can be seen by nonmember for :view_project is allowed
  def test_extended_watcher_private_project_show_redirects_to_issues_module
    @project = Project.generate!(:name => "dummy", :is_public => false)
    @issue = Issue.generate!(:project => @project)
    @issue.add_watcher(User.find(2))
    with_settings :plugin_redmine_extended_watchers => { 'policy' => 'extended' } do
      @request.session[:user_id] = 2
      get :index, :params => {
        :id => @project.id
      }
      assert_response :success
      assert_select '.tabs ul li .issues', { text: I18n.t(:label_issue_plural) }
      assert_select '.tabs ul li .overview', { count: 0 }
    end
  end

  
end
