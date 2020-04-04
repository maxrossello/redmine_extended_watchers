module ExtendedWatchersApplicationControllerPatch

    def authorize(ctrl = params[:controller], action = params[:action], global = false)
      if (ctrl == "projects" && action == "show")
        if Issue.where(:project_id => @project).watched_by(User.current).any?
          unless User.current.allowed_to?({:controller => ctrl, :action => action}, @project || @projects, :global => global)
            if @project.archived?
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
      super(ctrl, action, global)
    end
    
end

unless ApplicationController.included_modules.include?(ExtendedWatchersApplicationControllerPatch)
  ApplicationController.send(:prepend, ExtendedWatchersApplicationControllerPatch)
end
