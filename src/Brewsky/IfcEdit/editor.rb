# editor.rb
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
    module Editor
      Sketchup::require File.join(LIB_MAIN_PATH, 'IfcLib')

      @dlg = UI::WebDialog.new("Show IFC-editor", true, "ShowIfcEditor", 400, 300, 150, 150, true);
      html_source = File.join(PLUGIN_PATH, 'html', 'template.html')
      @dlg.set_html(html_source)
      @dlg.set_file( html_source )
      @dlg_content = Hash.new
      
      # Load webdialog contents after page is loaded
      @dlg.add_action_callback("load") do |dialog, params|
        counter = 1
        
        ### materials
        
        @dlg.execute_script("$('#materials').append('<tr data-tt-id=\"0\"><td colspan=\"3\"><a href=\"#\">Materials</a></td></tr>');")

        Sketchup.active_model.materials.each do |entity|
          material = Brewsky::IFC::IfcMaterial.new(entity)
          name = material.name
          description = material.description
          category = material.category
          
          sCounter = counter.to_s
          script = "$('#materials').append('<tr data-tt-id=\"" + sCounter + "\" data-tt-parent-id=\"0\">"
          script = script + UI.html_textbox(sCounter, 'Name', name, 'Name of the material.')
          script = script + UI.html_textbox(sCounter, 'Description', description, 'Definition of the material in more descriptive terms than given by attributes Name or Category.')
          script = script + UI.html_textbox(sCounter, 'Category', category, "Definition of the category (group or type) of material, in more general terms than given by attribute Name. Example: a view definition may require each Material.Name to be unique, e.g. for each concrete of steel grade used in a project, in which case Material.Category could take the values \\'Concrete\\' or \\'Steel\\'.")
          script = script + "</tr>');"
          @dlg.execute_script(script)
          
          @dlg_content[counter] = material
          counter = counter + 1
        end
        
        ### layers
        
        layer_header = counter.to_s
        @dlg.execute_script("$('#layers').append('<tr data-tt-id=\"" + layer_header + "\"><td colspan=\"3\"><a href=\"#\">Layers</a></td></tr>');")
        counter = counter + 1

        Sketchup.active_model.layers.each do |entity|
          layer = Brewsky::IFC::IfcPresentationLayerAssignment.new(entity)
          sCounter = counter.to_s
          script = "$('#layers').append('<tr data-tt-id=\"" + sCounter + "\" data-tt-parent-id=\"" + layer_header + "\">"
          script = script + UI.html_textbox(sCounter, 'Name', layer.name, 'Name of the layer.')
          script = script + UI.html_textbox(sCounter, 'Description', layer.description, 'Additional description of the layer.')
          script = script + UI.html_textbox(sCounter, 'Identifier', layer.identifier, 'An (internal) identifier assigned to the layer.')
          script = script + "</tr>');"
          @dlg.execute_script(script)
          
          @dlg_content[counter] = layer
          counter = counter + 1
        end
        
        ### products
        
        object_header = counter
        @dlg.execute_script("$('#products').append('<tr data-tt-id=\"" + object_header.to_s + "\"><td colspan=\"5\"><a href=\"#\">Products</a></td></tr>');")
        counter = counter + 1

        Sketchup.active_model.entities.each do |entity|
          parent_counter = counter
          component_options = Brewsky::IfcLib::Rules.component_options
          group_options = Brewsky::IfcLib::Rules.component_options
          
          product = Brewsky::IFC::IfcProduct.new(entity)
          name = product.name
          description = product.description
          ifc_type = product.ifcType
          guid = product.globalId
          
          if entity.is_a?(Sketchup::ComponentInstance) || entity.is_a?(Sketchup::Group)
            if entity.manifold?
              @dlg_content[counter] = product

              sCounter = counter.to_s
              script = "$('#products').append('<tr data-tt-id=\"" + sCounter + "\" data-tt-parent-id=\"" + object_header.to_s + "\">"
              script = script + "<td><a href=\"#\" onClick=\"select(\\'" + sCounter + "\\')\"><img src=\"../images/select_small.png\" /></a></td>"
              script = script + UI.html_textbox(sCounter, "Name", name, "Optional name for use by the participating software systems or users.")
              script = script + UI.html_textbox(sCounter, "Description", description, "Optional description, provided for exchanging informative comments.")
              script = script + "<td>" + UI.html_option(component_options, sCounter + "_IfcType", ifc_type) + "</td>"
              script = script + UI.html_textbox(sCounter, "GlobalId", guid, "Assignment of a globally unique identifier within the entire software world.")
              script = script + "</tr>');"
              @dlg.execute_script(script)

              counter = counter + 1
            end
          end
        end
        
        @dlg.execute_script("$(\"#products\").treetable({ expandable: true });")
        @dlg.execute_script("$(\"#materials\").treetable({ expandable: true });")
        @dlg.execute_script("$(\"#layers\").treetable({ expandable: true });")
      end
      
      # Update data that is changed in webdialog
      @dlg.add_action_callback("update") do |dialog, params|
        aParams = params.split("_", 3)
        index = aParams[0].to_i
        property = aParams[1]
        value = aParams[2]
        product = @dlg_content[index]
        product.update(property, value)
      end
      
      # Select objects
      @dlg.add_action_callback("select") do |dialog, params|
        entity = @dlg_content[params.to_i].entity
        sel = Sketchup.active_model.selection
        sel.clear
        sel.add entity
      end
      
      def self.is_ifc?(entity)
        if entity.is_a? Sketchup::Group
          return case entity
            when Brewsky::IfcLib::IfcWall.check(entity) then return true
            when Brewsky::IfcLib::IfcSlab.check(entity) then return true
            when Brewsky::IfcLib::IfcBeam.check(entity) then return true
            when Brewsky::IfcLib::IfcColumn.check(entity) then return true
            when Brewsky::IfcLib::IfcBuildingElementProxy.check(entity) then return true
            else return false
          end
        elsif entity.is_a? Sketchup::ComponentInstance
        elsif entity.is_a? Sketchup::Material
        elsif entity.is_a? Sketchup::Model
        end
      end
      
      def self.show_dialog
        @dlg.show
      end
      module Data
        Sketchup::require File.join(LIB_MAIN_PATH, 'guid.rb')
        Sketchup::require File.join(LIB_MAIN_PATH, 'IFC.rb')
        def self.get_ifc_type(entity)
          ifc_type = entity.get_attribute "IfcProduct", "type"
        end
        def self.set_defaults(entity)
          hDefault = Hash.new
          hDefault[IfcProduct] = Hash.new
          hDefault[IfcProduct]["SubType"] = "IfcBuildingElementProxy"
          hDefault[IfcProduct]["GlobalId"] = Brewsky::IFC.GlobalId.new().value
          hDefault[IfcProduct]["Name"] = ""
          hDefault[IfcProduct]["Description"] = ""
          hDefault[IfcProduct]["ObjectType"] = ""
          hDefault[IfcProductRepresentation] = Hash.new
          hDefault[IfcProductRepresentation]["SubType"] = "IfcFacetedBrep"
          hDefault[IfcProductRepresentation]["GlobalId"] = Brewsky::IFC.GlobalId.new().value
          hDefault[IfcProductRepresentation]["Name"] = ""
          hDefault[IfcProductRepresentation]["Description"] = ""
          hDefault[IfcProductRepresentation]["Representations"] = ["self"]
          
        end
      end # module Data
      module UI
      
        # returns a self updating html form option string
        # parameters: options(array), id(string), selected_option(string, matching one of array)
        def self.html_option(options, id=nil, selected=nil, tooltip=nil)
          html = '<select'
          unless id.nil?          
            if id.is_a? String
              html << " id=\"" + id + "\" onblur=\"update(\\'" + id + "\\')\" "
            end
          end
          unless tooltip.nil?
            if tooltip.is_a? String
              html << " title=\"" + tooltip + "\""
            end
          end
          html << '>\n'
          options.each do |option|
            html << '<option value="' + option + '"'
            unless selected.nil?
              if selected == option
                html << ' selected'
              end
            end
            html << '>' + option + '</option>\n'
          end
          html << '</select>\n'
          return html
        end
        
        # returns a self updating html form textbox string
        # parameters: id(string), field name(string, first letter Uppercase), field current value(string)
        def self.html_textbox(id, key, value="", tooltip="")
          
          # excape all possible quotes in the string
          value.gsub!(/'/){ "\\'" }
          
          html = "<td><input type=\"text\" id=\"" + id + "_" + key + "\""
          unless tooltip.nil?
            if tooltip.is_a? String
              html << " title=\"" + tooltip + "\""
            end
          end
          html << " onblur=\"update(\\'" + id + "_" + key + "\\')\" value=\""
          unless value.nil? || value == ""
            html << value
          end
          html << "\" /></td>"
          return html
        end
      end # module UI
    end # module Editor
  end # module IfcEditor
end # module Brewsky
