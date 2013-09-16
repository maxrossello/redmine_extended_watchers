require_dependency 'watchers_controller'

module ExtendedWatchersControllerPatch
    
    def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
            unloadable
        end
    end

    module InstanceMethods

        def check_project_privacy
          if (params[:action] == 'unwatch') && (params[:object_type] == 'issue')
            if User.current.logged?
              issue = Issue.find(params[:object_id])
              return issue.watched_by?(User.current)
            end
          end
          super()
        end

    end

end

