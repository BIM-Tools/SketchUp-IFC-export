# IFC.rb
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
  module IFC
    
    # max 255 characters!
    class Ifc_String
      attr_reader :value
      def initialize(string=nil)
        #if string.is_a? String
        #  @value = string
        #elsif string.to_s
        #  @value = string.to_s
        #else
        #  @value = get_default()
        #end
        if string.nil?
          @value = get_default()
        else
          @value = string
        end
      end
      def get_default()
        puts "Given value could not be converted to a String, returning empty string"
        return ""
      end
    end # class Ifc_String
    class GlobalId < Ifc_String
      def get_default()
        guid = '';22.times{|i|guid<<'0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz_$'[rand(64)]}
        @value = guid
      end
    end # class GlobalId
    class IfcLabel < Ifc_String
    end # class IfcLabel
    class IfcText < Ifc_String
    end # class IfcText
    
    # Object for all sub-types of the IfcProduct-object, contains all methods for modifying IFC-object properties/data in SketchUp
    class IfcProduct
      attr_reader :ifcType, :globalId, :ownerHistory, :name, :description, :objectType, :objectPlacement, :representation, :entity
      def initialize(entity)
        @entity = entity
        @object = 'IfcProduct'
        set_IfcType()
        set_GlobalId()
        set_OwnerHistory()
        set_Name()
        set_Description()
        set_ObjectType()
        set_ObjectPlacement()
        set_Representation()
      end
      def update(property, value)
        # eval("set_" + property)(value)
        set_property = "set_" + property
        send(set_property, value)
      end
      def set_IfcType(input=nil)
        property = 'subtype'
        if input.nil?
          @ifcType = @entity.get_attribute @object, property
        else
          @ifcType = input
          @entity.set_attribute @object, property, @ifcType
        end
      end
      def set_GlobalId(input=nil)
        property = 'GlobalId'
        if input.nil?
          value = @entity.get_attribute @object, property
          @globalId = GlobalId.new(value).value
          #guid = GlobalId.new(value).value
          #@globalId = guid.value
          @entity.set_attribute @object, property, @globalId
        else
          @globalId = input
          @entity.set_attribute @object, property, @globalId
        end
      end
      def set_OwnerHistory(input="")
        @ownerHistory = ""
      end
      def set_Name(input=nil)
        property = 'Name'
        if input.nil?
          value = @entity.get_attribute @object, property
          if value.nil?
            value = @entity.name
          end
          @name = Ifc_String.new(value).value
        else
          @name = Ifc_String.new(input).value
        end
        @entity.set_attribute @object, property, @name
        @entity.name = @name
      end
      def set_Description(input=nil)
        property = 'Description'
        if input.nil?
          value = @entity.get_attribute @object, property
          @description = Ifc_String.new(value).value
        else
          @description = Ifc_String.new(input).value
        end
        @entity.set_attribute @object, property, @description
        #@entity.definition.description = @description
      end
      def set_ObjectType(input=nil)
        property = 'ObjectType'
        if input.nil?
          value = @entity.get_attribute @object, property
          @objectType = Ifc_String.new(value).value
        else
          @objectType = Ifc_String.new(input).value
        end
        @entity.set_attribute @object, property, @objectType
      end
      def set_ObjectPlacement(input=nil)
      end
      def set_Representation(input=nil)
      end
    end # IfcProduct
    
    # Object for all sub-types of the IfcProduct-object, contains all methods for modifying IFC-object properties/data in SketchUp
    class IfcMaterial
      attr_reader :name, :description, :category, :entity#, :globalId
      def initialize(entity)
        @entity = entity
        @object = 'IfcMaterial'
        #set_GlobalId()
        set_Name()
        set_Description
        set_Category()
      end
      def update(property, value)
        # eval("set_" + property)(value)
        set_property = "set_" + property
        send(set_property, value)
      end
      def set_OwnerHistory(input="")
        @ownerHistory = ""
      end
      def set_Name(input=nil)
        property = 'Name'
        if input.nil?
          value = @entity.get_attribute @object, property
          if value.nil?
            value = @entity.name
          end
          @name = Ifc_String.new(value).value
        else
          @name = Ifc_String.new(input).value
        end
        @entity.set_attribute @object, property, @name
        @entity.name = @name
      end
      def set_Description(input=nil)
        property = 'Description'
        if input.nil?
          value = @entity.get_attribute @object, property
          @description = Ifc_String.new(value).value
        else
          @description = Ifc_String.new(input).value
        end
        @entity.set_attribute @object, property, @description
      end
      def set_Category(input=nil)
        property = 'Category'
        if input.nil?
          value = @entity.get_attribute @object, property
          @category = Ifc_String.new(value).value
        else
          @category = Ifc_String.new(input).value
        end
        @entity.set_attribute @object, property, @category
      end
      #def set_GlobalId(input=nil)
        #property = 'GlobalId'
        #if input.nil?
          #value = @entity.get_attribute @object, property
          #@globalId = GlobalId.new(value).value
        #else
          #@globalId = input
          #@entity.set_attribute @object, property, @globalId
        #end
      #end
    end # IfcMaterial
    
    # IFC version of the sketchup layer
    class IfcPresentationLayerAssignment
      attr_reader :name, :description, :identifier, :entity
      def initialize(entity)
        @entity = entity
        @object = 'IfcPresentationLayerAssignment'
        set_Name()
        set_Description
        set_Identifier()
      end
      def update(property, value)
        set_property = "set_" + property
        send(set_property, value)
      end
      def set_OwnerHistory(input="")
        @ownerHistory = ""
      end
      def set_Name(input=nil)
        property = 'Name'
        if input.nil?
          value = @entity.get_attribute @object, property
          if value.nil?
            value = @entity.name
          end
          @name = Ifc_String.new(value).value
        else
          @name = Ifc_String.new(input).value
        end
        @entity.set_attribute @object, property, @name
        @entity.name= @name
      end
      def set_Description(input=nil)
        property = 'Description'
        if input.nil?
          value = @entity.get_attribute @object, property
          @description = Ifc_String.new(value).value
        else
          @description = Ifc_String.new(input).value
        end
        @entity.set_attribute @object, property, @description
      end
      def set_Identifier(input=nil)
        property = 'Identifier'
        if input.nil?
          value = @entity.get_attribute @object, property
          @identifier = Ifc_String.new(value).value
        else
          @identifier = Ifc_String.new(input).value
        end
        @entity.set_attribute @object, property, @identifier
      end
    end # IfcPresentationLayerAssignment
  end # module IFC
end # module Brewsky
