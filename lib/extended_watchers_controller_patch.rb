require_dependency 'watchers_controller'

module ExtendedWatchersControllerPatch
    
    def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
            unloadable

            alias_method_chain :autocomplete_for_user, :extwatch
        end
    end

    module InstanceMethods

        def autocomplete_for_user_with_extwatch
          @users = User.active.sorted.like(params[:q]).limit(100).all
          @users.reject! {|user| !user.allowed_to?(:view_issues, @project)}
          if @watched
            @users -= @watched.watcher_users
          end
          render :layout => false
        end

    end

end

