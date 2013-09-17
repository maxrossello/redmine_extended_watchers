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
          if User.current.logged? && (params[:action] == 'unwatch') && (params[:object_type] == 'issue')
            return Issue.find(params[:object_id]).watched_by?(User.current)
          end
          super()
        end

    end

end

