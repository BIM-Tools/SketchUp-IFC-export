# loader.rb
#  
# Copyright 2013 Jan Brouwer <jan@brewsky.nl>
#  
#       
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#       
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#       
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

require 'sketchup.rb'

module Brewsky
  module IfcExport
    
    # Add IFC export command to BIM-Tools Toolbar
    cmd = UI::Command.new("Export to IFC") {
      Sketchup::require File.join(PLUGIN_PATH, 'exporter.rb')
      exporter = IfcExporter.new(Sketchup.active_model.entities)
    }
    cmd.small_icon = File.join(IMAGE_PATH, 'IfcExport_small.png')
    cmd.large_icon = File.join(IMAGE_PATH, 'IfcExport_large.png')
    cmd.tooltip = "IFC export"
    cmd.status_bar_text = "Export the current model to IFC"
    cmd.menu_text = "IFC export"
    TOOLBAR = TOOLBAR.add_item cmd
    TOOLBAR.show

  end # module IfcExport
end # module Brewsky
