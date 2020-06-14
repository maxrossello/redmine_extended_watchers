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

require_dependency 'watchers_controller'

module ExtendedWatchersControllerPatch
    
  def users_for_new_watcher
    users = super
    if Setting.plugin_redmine_extended_watchers["policy"] == "protected" && @project.present?
      users.reject! {|user| !user.allowed_to?(:view_issues, @project)}
    end
    users
  end

end

unless WatchersController.included_modules.include?(ExtendedWatchersControllerPatch)
    WatchersController.send(:prepend, ExtendedWatchersControllerPatch)
end
