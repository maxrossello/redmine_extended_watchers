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

module ExtendedWatchersProjectPatch

   def allowed_to_condition(user, permission, options={})
     condition = super(user, permission, options)
     return condition if (permission != :view_project or (setting = Setting.plugin_redmine_extended_watchers["policy"]) == "default")
     
     return "( " + condition + " OR (#{Project.table_name}.id IN (#{Project.select(:id).joins(:issues).where(Issue.visible_condition(user)).to_sql})) )"
   end
   
end

unless Project.singleton_class.included_modules.include?(ExtendedWatchersProjectPatch)
   Project.singleton_class.send(:prepend, ExtendedWatchersProjectPatch)
end
