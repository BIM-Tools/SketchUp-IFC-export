# IfcLib.rb
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
  module IfcLib
    module Rules
      def self.group_options()
        return ["-", "IfcWall", "IfcSlab", "IfcBeam", "IfcColumn", "IfcBuildingElementProxy"] # "IfcBuilding", IfcBuildingStorey"
      end
      def self.component_options()
        return Array.new(group_options)
      end
      def self.material_options()
        return ["IfcMaterial"]
      end
    end # module Rules
    module IfcBase
      @name = "IfcBase"
      def check(entity)
        attrdict = entity.attribute_dictionary @name
      end
    end # module IfcBase
    module IfcWall
      @name = "IfcWall"
      extend IfcBase
    end # module IfcWall
    module IfcSlab
      @name = "IfcSlab"
      extend IfcBase
    end # module IfcSlab
    module IfcBeam
      @name = "IfcBeam"
      extend IfcBase
    end # module IfcBeam
    module IfcColumn
      @name = "IfcColumn"
      extend IfcBase
    end # module IfcColumn
    module IfcBuildingElementProxy
      @name = "IfcBuildingElementProxy"
      extend IfcBase
    end # module IfcBuildingElementProxy
    
    # Brewsky::IfcLib::IfcWall.check(Sketchup.active_model.selection[0])

  end # module IfcLib
end # module Brewsky
