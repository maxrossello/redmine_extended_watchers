module ExtendedWatchersApplicationControllerPatch

  def self.included(base)
    base.send(:include, InstanceMethods)

    base.class_eval do
      unloadable

      alias_method_chain :authorize, :extwatch
    end
  end

  module InstanceMethods

    def authorize_with_extwatch(ctrl = params[:controller], action = params[:action], global = false)
      if (ctrl == "projects" && action == "show")
        Issue.watched_by(User.current).all.each do |issue|
          if issue.project == @project
            unless User.current.allowed_to?({:controller => ctrl, :action => action}, @project || @projects, :global => global)
              redirect_to _project_issues_path(@project)
            end
            return true
          end
        end
      elsif (ctrl == "issues" && action == "show")
        return true if Issue.find(params[:id]).joins(:project => :enabled_modules).where("#{EnabledModule.table_name}.name = 'issue_tracking'").watched_by?(User.current)
      end
      authorize_without_extwatch(ctrl, action, global)
    end
  end
end
