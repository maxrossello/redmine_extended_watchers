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

module ExtendedWatchersApplicationControllerPatch

   def authorize(ctrl = params[:controller], action = params[:action], global = false)
      if Setting.plugin_redmine_extended_watchers["policy"] == "extended"
         if (ctrl == "projects" && action == "show")
            if Issue.where(:project_id => @project).watched_by(User.current).any?
               unless User.current.allowed_to?({:controller => ctrl, :action => action}, @project || @projects, :global => global)
                  if @project.archived?
                     @archived_project = @project
                     render_403 :message => :notice_not_authorized_archived_project
                  else
                     redirect_to _project_issues_path(@project)
                  end
               end
               return true
            end
         elsif (ctrl == "issues" && action == "show")
            return true if Issue.joins(:project => :enabled_modules).where("#{EnabledModule.table_name}.name = 'issue_tracking'").find(params[:id]).watched_by?(User.current)
         end
      end
      
      super(ctrl, action, global)
   end
   
  def check_project_privacy
    if Setting.plugin_redmine_extended_watchers["policy"] == "extended" &&
      User.current.logged? && (params[:action] == 'unwatch') && (params[:object_type] == 'issue')
      return Issue.find(params[:object_id]).watched_by?(User.current)
    end
    super
  end

end

unless ApplicationController.included_modules.include?(ExtendedWatchersApplicationControllerPatch)
  ApplicationController.send(:prepend, ExtendedWatchersApplicationControllerPatch)
end
