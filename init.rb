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

require 'redmine'

Rails.logger.info 'Starting Extended Watchers plugin for Redmine'

require_relative 'lib/extended_watchers_issue_patch'
require_relative 'lib/extended_watchers_controller_patch'
require_relative 'lib/extended_watchers_user_patch'
require_relative 'lib/extended_watchers_principal_patch'
require_relative 'lib/extended_watchers_project_patch'
require_relative 'lib/extended_watchers_application_controller_patch'

Redmine::Plugin.register :redmine_extended_watchers do
  name 'Redmine Extended Watchers plugin'
  author 'Massimo Rossello'
  description 'Enables all users to be assigned as watchers of an issue and have limited access to it in the project'
  version '5.1.0'
  url 'https://github.com/maxrossello/redmine_extended_watchers.git'
  author_url 'https://github.com/maxrossello'
  requires_redmine :version_or_higher => '5.1.0'

  # policy: default, extended, protected 
  settings :default => {'policy' => 'extended'}, :partial => 'settings/extwatch_settings'
end
