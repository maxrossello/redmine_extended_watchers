require_dependency 'journal'

module ExtendedWatchersJournalPatch
    
    def self.included(base)
        base.class_eval do
            unloadable

            named_scope :visible, lambda {|*args| {
              :include => {:issue => [:project, :watchers]},
              :conditions => Issue.visible_condition(args.shift || User.current, *args)
            }}

        end
    end

end

