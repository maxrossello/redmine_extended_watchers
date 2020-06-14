# Extended Watchers plugin for Redmine
# Copyright (C) 2013-2020  Massimo Rossello
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

module ExtendedWatchersProjectPatch

   def visible_condition(user, options={})
      return super if Setting.plugin_redmine_extended_watchers["policy"] == "default"

      # 'visible' filters out watched issues in protected mode which the user has no permission to view for
      issues = Issue.visible.watched_by(user).joins(:project => :enabled_modules).where("#{EnabledModule.table_name}.name = 'issue_tracking'")

      if issues.any?
        super(user,options) + " OR (#{Project.table_name}.id IN (#{issues.all.collect(&:project_id).join(",")}))"
      else
        super(user,options)
      end
   end
  
end

unless Project.singleton_class.included_modules.include?(ExtendedWatchersProjectPatch)
   Project.singleton_class.send(:prepend, ExtendedWatchersProjectPatch)
end
