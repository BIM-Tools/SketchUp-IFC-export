#       IfcExport.rb
#       
#       Copyright (C) 2013 Jan Brouwer <jan@brewsky.nl>
#       
#       This program is free software: you can redistribute it and/or modify
#       it under the terms of the GNU General Public License as published by
#       the Free Software Foundation, either version 3 of the License, or
#       (at your option) any later version.
#       
#       This program is distributed in the hope that it will be useful,
#       but WITHOUT ANY WARRANTY; without even the implied warranty of
#       MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#       GNU General Public License for more details.
#       
#       You should have received a copy of the GNU General Public License
#       along with this program.  If not, see <http://www.gnu.org/licenses/>.

module Brewsky
	module IfcExport

		Sketchup::require File.join(LIB_PATH, 'DefaultValues.rb')
		Sketchup::require File.join(LIB_MAIN_PATH, 'guid.rb')
		Sketchup::require File.join(LIB_MAIN_PATH, 'get_definition.rb')
		Sketchup::require File.join(LIB_MAIN_PATH, 'ifc_check.rb')
		Sketchup::require File.join(LIB_PATH, 'Ifc.rb')
		
		# basic IFC export class
		class IfcExporter
			attr_reader :a_Ifc, :ifcProject, :ifcOrganisation, :model, :defaults, :ifcOwnerHistory, :ifcGeometricRepresentationContext, :ifcSite, :ifcBuilding, :aContainedInBuilding
			def initialize(entities=nil)
				
				@model=Sketchup.active_model
			
				# load default values
				@defaults = DefaultValues.new
				
				# "total" IFC array
				@a_Ifc = Array.new
				
				# list of all used sketchup materials
				@hMaterials = Hash.new
				
				# list of all used sketchup layers
				@hLayers = Hash.new
				
				# This array will hold the record numbers of all entities that are direct "child" objects to the site
				@aContainedInBuilding = Array.new
				
				# create IfcProject object
				@ifcProject = IfcProject.new(self)
				
				# create IfcSite object
				@ifcSite = IfcSite.new(self, @ifcProject)
			
				# create a building on the site, temporary solution because multiple buildings could be present
				@ifcBuilding = IfcBuilding.new(self, @ifcSite)
		
				path=@model.path.tr("\\", "/")
				if not path or path==""
					UI.messagebox("IFC Exporter:\n\nPlease save your project before Exporting to IFC\n")
					return nil
				end
				@project_path=File.dirname(path)
				@title=@model.title
				@skpName=@title
				ifc_name = @skpName + ".ifc"
				ifc_filepath=File.join(@project_path, ifc_name)
					
				#aEntities = get_entities(entities)
				#if aEntities.length > 0 #if exportable objects have been found, start exporter
					if self.export(ifc_filepath)
						UI.messagebox("IFC Export completed:\n" + ifc_filepath + "\n")
					else
						UI.messagebox("IFC Exporter:\n\nExport failed.\n")
					end
				#else
				#	UI.messagebox("IFC Exporter:\n\nNo entities to export to IFC.\nExport failed.\n")
				#end
			end
			
			# main exporter method
			def export(location, aSuEntities=nil)
				Sketchup.set_status_text("IFCExporter: Exporting IFC entities...") # inform user that ifc-export is running
		
				ifc_filepath = location
				export_base_file = File.basename(@model.path, ".skp") + ".ifc"
				
				if aSuEntities.nil?
					aSuEntities = Sketchup.active_model.entities
				end


      
        ###################
        h_entities = self.get_su_entities(Sketchup.active_model)
        self.set_ifc_entities(h_entities, @ifcBuilding)

				# unnecesary step: collecting entities twice
				#aIfcEntities = Array.new
				#self.get_entities(aSuEntities, @ifcBuilding)#, aIfcEntities)
				
				#aIfcEntities.each do |ifcEntity|
				
				#aEntities.each do |entity|
				 ## entity.ifc_export(self)
				
					
					#subtype = entity.get_attribute "IfcProduct", "subtype"
					
					#case subtype
					#when "IfcWall"
						#ifcEntity = IfcWall.new(self, entity)
					#when "IfcSlab"
						#ifcEntity = IfcSlab.new(self, entity)
					#when "IfcBeam"
						#ifcEntity = IfcBeam.new(self, entity)
					#when "IfcColumn"
						#ifcEntity = IfcColumn.new(self, entity)
					#else
						#ifcEntity = IfcBuildingElementProxy.new(self, entity)
					#end
				 
				#end
				
				# fill site container object with ifc entities
				#container.fill()
				
				# fill the materials with attached objects
				@hMaterials.each_value do |ifcRelAssociatesMaterial|
					ifcRelAssociatesMaterial.fill
				end
				
				# fill the layers with attached objects
				@hLayers.each_value do |ifcLayer|
					ifcLayer.fill
				end
		
		
				File.open(ifc_filepath, 'w') do |file|
					file.write(self.ifc)
				end
			end # export
      
      def connected_check(aEntities)
        aSets = Hash.new
        
        def self.get_connected(aEntities, aSets)
          unless aEntities.length == 0
            aConnected = aEntities[0].all_connected
            aSets[aConnected] = nil
            aEntities = aEntities - aConnected
            self.get_connected(aEntities, aSets)
          end
        end
        
        self.get_connected(aEntities, aSets)
        return aSets
      end
        
      # create a Hash from all SU entities
      def get_su_entities(su_parent)
        h = Hash.new
        a_faces = Array.new
        if su_parent.is_a?(Sketchup::ComponentInstance)
          entities = su_parent.definition.entities
        else
          entities = su_parent.entities
        end
        
        entities.each do |su_entity|
          if su_entity.is_a?(Sketchup::Group) || su_entity.is_a?(Sketchup::ComponentInstance)
            h[su_entity] = get_su_entities(su_entity)
          elsif su_entity.is_a?(Sketchup::Face)
            a_faces << su_entity
          end
        end
        h.merge!(self.connected_check(a_faces))
        return h
      end # get_su_entities
      
      # create IFC entities from Hash
      def set_ifc_entities(h_entities, ifc_parent)
        h_entities.each do |ent, children|
            
          unless ent.is_a?(Array)
            subtype = ent.get_attribute "IfcProduct", "SubType"
          end
          
          if children.nil? || children.length == 1
            assembly = false
          else
            assembly = true
          end
          
          case subtype
          when "IfcWall"
            ifc_entity = IfcWall.new(self, ifc_parent, ent, assembly)
          when "IfcSlab"
            ifc_entity = IfcSlab.new(self, ifc_parent, ent, assembly)
          when "IfcBeam"
            ifc_entity = IfcBeam.new(self, ifc_parent, ent, assembly)
          when "IfcColumn"
            ifc_entity = IfcColumn.new(self, ifc_parent, ent, assembly)
          else
            ifc_entity = IfcBuildingElementProxy.new(self, ifc_parent, ent, nil, assembly)
          end
          
          self.collect_layers(ent, ifc_entity)
            
          if assembly == false
            self.collect_materials(ent, ifc_entity)            
          else
            self.set_ifc_entities(children, ifc_entity)
          end
        end
      end # set_ifc_entities
			
			def collect_materials(entity, ifcEntity)
				unless entity.nil? || entity.is_a?(Array)
          unless @hMaterials.has_key?(entity.material)
            ifc_material = IfcMaterial.new(self, entity.material)
           # IfcMaterialDefinitionRepresentation.new(self, ifc_material, entity.material)
            @hMaterials[entity.material] = IfcRelAssociatesMaterial.new(self, ifc_material)
          end
          @hMaterials[entity.material].add(ifcEntity)
        end
			end
			def collect_layers(entity, ifcEntity)
				unless entity.nil? || entity.is_a?(Array)
          #if entity.is_a?(Sketchup::Entities)
          #  entity = entity.parent
          #end
          unless @hLayers.has_key?(entity.layer)
            @hLayers[entity.layer] = IfcPresentationLayerAssignment.new(self, entity.layer)
          end
          @hLayers[entity.layer].add(ifcEntity)
        end
			end
			#def get_entities(entities)
				#if entities.nil?
					#entities = Sketchup.active_model.entities
				#end
				#ifc_entities = Array.new
				#entities.each do |entity|
					#if entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)
						#if entity.manifold?
							#ifc_entities << entity
						#end
					#end
				#end
				#return ifc_entities
			#end
			
			# recursively walk through the model and return found IFC entities
			def get_entities(aSuEntities, parent)#, aIfcEntities)
				
				aEdges = Array.new
				aFaces = Array.new
				#aComponents = Array.new
				aIfcEntities = Array.new
				
				# filter types of entities
				aSuEntities.each do |entity|
					ifcEntity = nil
					case entity
					when Sketchup::Group
						ifcEntity = Brewsky::IfcExport::ifc_check(entity)
						if ifcEntity.nil?
							ifcEntity = IfcElement.new(self, parent, entity)
						end
						aIfcEntities << ifcEntity
						
						# find nested entities
						get_entities(entity.entities, ifcEntity)#, aIfcEntities)
					when Sketchup::ComponentInstance
						ifcEntity = Brewsky::IfcExport::ifc_check(entity)
						if ifcEntity.nil?
							ifcEntity = IfcElement.new(self, parent, entity)
						end
						aIfcEntities << ifcEntity
						
						# find nested entities
						get_entities(entity.definition.entities, ifcEntity)#, aIfcEntities)
					when Sketchup::Edge
						aEdges << entity
					when Sketchup::Face
						aFaces << entity
					end
					#unless ifcEntity.nil?
					#	collect_materials(entity, ifcEntity.record_nr)
					#	collect_layers(entity, ifcEntity)
					#end
				end
				
				
				# create IfcProducts from "loose" geometry
				# if more than 1 connected group of objects: create products
				products = self.connected_check(aFaces)
				#if products.length > 1
					#products.each do |product|
						#IfcElement.new(self, parent, product)
					#end
				#elsif products.length == 1 && aComponents.length != 0
					#IfcElement.new(self, parent, products[0])
				#elsif products.length == 1 && aComponents.length == 0
					
					############ dit werkt alleen bij een ifcproduct!!!!!!
					
					#if parent.is_a? IfcProduct 
						#parent.set_ProductRepresentation(products[0])
					#else
						#IfcElement.new(self, parent, products[0])
					#end
				#end
				
				if products.length == 1 && aIfcEntities.length == 0
					
					parent.set_ProductRepresentation(products[0])
					#parent.set_ObjectPlacement(parent)
					
					#collect_materials(products[0][0].parent, parent.record_nr)
					#collect_layers(products[0][0].parent, parent)
					
				else
					
					products.each do |product|
						ifcEntity = IfcElement.new(self, parent, product)
						ifcEntity.set_ProductRepresentation(product)
						aIfcEntities << ifcEntity
					
						#collect_materials(product[0].parent, parent.record_nr)
						#collect_layers(product[0].parent, parent)
					end
					
				end
				return aIfcEntities
			end # get_entities
			
			# function to split a set of entities(edges and faces) into sets of connected entities
			# input: Array of entities
			# output: Array with sub-arrays containing connected entities
			#def connected_check(aEntities)
				#aSets = Array.new
				
				#def get_connected(aEntities, aSets)
					#unless aEntities.length == 0
						#aConnected = aEntities[0].all_connected
						#aSets << aConnected
						#aEntities = aEntities - aConnected
						#get_connected(aEntities, aSets)
					#end
				#end
				
				#self.get_connected(aEntities, aSets)
				#return aSets
			#end
			def add(entity)
				new_record_nr = @a_Ifc.length + 1
				new_record_nr = "#" + new_record_nr.to_s
				entity.record_nr=(new_record_nr)
				@a_Ifc << entity
			end
			
			def set_IfcOwnerHistory()
				if @ifcOwnerHistory.nil?
					@ifcOwnerHistory = IfcOwnerHistory.new(self)
				end
				return @ifcOwnerHistory # is this needed or automatically returned?
			end
			
			def set_IfcOrganization()
				if @ifcOrganization.nil?
					organisation_name = "'organisation_name'"
					organisation_description = "'organisation_description'"
					@ifcOrganization = IfcOrganization.new(self, organisation_name, organisation_description)
				end
				return @ifcOrganization
			end
			
			def set_IfcGeometricRepresentationContext()
				if @ifcGeometricRepresentationContext.nil?
					@ifcGeometricRepresentationContext = IfcGeometricRepresentationContext.new(self)
				end
				return @ifcGeometricRepresentationContext
			end
			
			# returns a string containing the full IFC file
			def ifc
				@a_Ifc
				s_EntityRecords = ""
				@a_Ifc.each do |ifcEntity|
					s_EntityRecords = s_EntityRecords + ifcEntity.record
				end
				return header + s_EntityRecords + footer
			end
			
			# returns a string containing a ifc entity's record/line
			def ifcRecord(ifcEntity)
				entityType = ifcEntity.entityType
				recordNr = ifcEntity.record_nr
				a_Attributes = ifcEntity.a_Attributes
				a_Attributes.map!{|x|x.nil? || x=="" || x=="''" || x==false ? "$":x}
				s_Attributes = ifcEntity.a_Attributes.join ', '
				return recordNr + " = " + entityType + "(" + s_Attributes + ");\n"
			end
			def header
				#@export_base_file = export_base_file
				time = Time.new
				@timestamp = time.strftime("%Y-%m-%dT%H:%M:%S")
				@author = @model.get_attribute "ifc", "author", "Architect"
				@organization = @model.get_attribute "ifc", "organization", "Building Designer Office"
				@preprocessor_version = "BIM-Tools IFC-exporter"
				@originating_system = "BIM-Tools IFC-exporter"
				@authorization = @model.get_attribute "ifc", "authorization", "The authorising person"
				
				return "ISO-10303-21;
HEADER;
FILE_DESCRIPTION( ('ViewDefinition [CoordinationView_V2.0]'),'2;1');
FILE_NAME ('" + @skpName + ".ifc', '" + @timestamp + "', ('" + @author + "'), ('" + @organization + "'), '" + @preprocessor_version + "', '" + @originating_system + "', '" + @authorization + "');
FILE_SCHEMA (('IFC2X3'));
ENDSEC;

DATA;
"
			end
			def footer
				return "ENDSEC;
END-ISO-10303-21;
	"
			end
		
			# returns a length converted to m, as a string
			def ifcLengthMeasure(number)
				return sprintf('%.8f', number.to_m).sub(/0{1,8}$/, '')
			end
		
			# returns a length converted to m, as a string
			def ifcAreaMeasure(number)
				return sprintf('%.8f', number.to_m).sub(/0{1,8}$/, '') # not correct for area!!!
			end
		
			# returns a length converted to m, as a string
			def ifcVolumeMeasure(number)
				return sprintf('%.8f', number.to_m).sub(/0{1,8}$/, '') # not correct for area!!!
			end
			
			# returns the value as a string
			def ifcLabel(value)
				return "'" + value + "'"
			end
			
			# returns a Real number, rounded down, as a string
			def ifcReal(number)
				return sprintf('%.8f', number).sub(/0{1,8}$/, '')
			end
		
			# returns a IFC list-string out of an array
			def ifcList(aList)
				sList = "("
				if aList.is_a? Array
					aList.each_index do |index|
						sList = sList + aList[index]
						unless aList.length - 1 == index
							sList = sList + ","
						end
					end
				else
					sList = sList + aList
				end
				sList = sList + ")"
				return sList
			end
      
			
			# function to figure out if an Array of Edges makes solid objects
			# input: Array of Edges
			# output: true or false
			def solid_check(aEdges)
				puts "solidcheck"
				if aEdges.length == 0
					return false
				end
				aEdges.each do |edge|
					if edge.faces.length != 2
						return false
					end
				end
				return true
			end # solid_check
		end # IfcExporter
	end # module IfcExport
end # module Brewsky
