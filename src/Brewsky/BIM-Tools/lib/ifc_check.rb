# ifc_check.rb
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
#  
#
# A SketchUp Ruby Extension that adds a textual IFC-data
# (Industry Foundation Classes) editor to sketchup.

require 'sketchup.rb'

module Brewsky
  module IfcExport

		# function to figure out if a group or component has IFC information
		# input: Sketchup::Group or Sketchup::ComponentInstance
		# output:
		#  - if extrusion: true
		#  - if no extrusion: false
		def self.ifc_check(entity)
			if entity.is_a?(Sketchup::ComponentInstance)
				entity = entity.definition
			end
			
			if entity.get_attribute("IfcProduct", "type").nil?
				return nil
			else
				return true
			end
		end # is_ifc?
  end # module IfcExport
end # module Brewsky
