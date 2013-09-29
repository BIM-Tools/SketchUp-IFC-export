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
  module IfcEditor
  
    Sketchup::require File.join(PLUGIN_PATH, 'editor')
    
    # create toolbar  
    #toolbar = UI::Toolbar.new 'IFC Editor'
    cmd = UI::Command.new('Open IFC Editor.') { 
     Brewsky::IfcEditor::Editor::show_dialog
    }
    cmd.small_icon = File.join(IMAGE_PATH, 'IfcEdit_small.png')
    cmd.large_icon = File.join(IMAGE_PATH, 'IfcEdit_large.png')
    cmd.tooltip = "IFC Editor"
    cmd.status_bar_text = "Edit IFC-data"
    cmd.menu_text = "IFC Editor"
    TOOLBAR = TOOLBAR.add_item cmd
    TOOLBAR.show

  end # module IfcEditor
end # module Brewsky
