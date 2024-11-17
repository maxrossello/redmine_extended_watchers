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

require_dependency 'user'

module ExtendedWatchersUserPatch

   def allowed_to?(action, context, options={}, &block)
      is_allowed = super(action, context, options, &block)
      return is_allowed if is_allowed || Setting.plugin_redmine_extended_watchers["policy"] != "extended"
      
      return false if context && context.is_a?(Project) && context.archived?
      return false if status == User::STATUS_LOCKED
      
      if (options[:watchers].nil? || options[:watchers]) && self.logged? && context && context.is_a?(Project)
         if action.is_a?(Hash)
            if action[:controller] == "issues" && action[:action] == "index"
               return true if Issue.where(:project_id => context).watched_by(self).joins(:project => :enabled_modules).where("#{EnabledModule.table_name}.name = 'issue_tracking'").any?
            end
         elsif action == :view_issues && options[:issue].nil?
            return true if Issue.where(:project_id => context).watched_by(self).joins(:project => :enabled_modules).where("#{EnabledModule.table_name}.name = 'issue_tracking'").any?
         end
      end
      return false
   end
end

unless User.included_modules.include?(ExtendedWatchersUserPatch)
   User.prepend(ExtendedWatchersUserPatch)
end
