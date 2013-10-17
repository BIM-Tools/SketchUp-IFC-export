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
				set_IfcProject
				
				# create IfcSite object
				set_IfcSite(@ifcProject)
				
				set_IfcBuilding(@ifcSite)
		
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
					
				aEntities = get_entities(entities)
				if aEntities.length > 0 #if exportable objects have been found, start exporter
					if self.export(aEntities, ifc_filepath)
						UI.messagebox("IFC Export completed:\n" + ifc_filepath + "\n")
					else
						UI.messagebox("IFC Exporter:\n\nExport failed.\n")
					end
				else
					UI.messagebox("IFC Exporter:\n\nNo entities to export to IFC.\nExport failed.\n")
				end
			end
			
			def export(aEntities, location)
				Sketchup.set_status_text("IFCExporter: Exporting IFC entities...") # inform user that ifc-export is running
		
				ifc_filepath = location
				export_base_file = File.basename(@model.path, ".skp") + ".ifc"
				
				# create empty site container object
				container = IfcRelContainedInSpatialStructure.new(self)
				
				aEntities.each do |entity|
				 # entity.ifc_export(self)
				
					
					subtype = entity.get_attribute "IfcProduct", "subtype"
					
					case subtype
					when "IfcWall"
						ifcEntity = IfcWall.new(self, entity)
					when "IfcSlab"
						ifcEntity = IfcSlab.new(self, entity)
					when "IfcBeam"
						ifcEntity = IfcBeam.new(self, entity)
					when "IfcColumn"
						ifcEntity = IfcColumn.new(self, entity)
					else
						ifcEntity = IfcBuildingElementProxy.new(self, entity)
					end
				 
					collect_materials(entity, ifcEntity.record_nr)
					collect_layers(entity, ifcEntity)
				end
				
				# fill site container object with ifc entities
				container.fill()
				
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
			end
			def collect_materials(entity, ifcEntity)
				unless entity.material.nil?
					unless @hMaterials.has_key?(entity.material)
						@hMaterials[entity.material] = IfcRelAssociatesMaterial.new(self, IfcMaterial.new(self, entity.material))
					end
					@hMaterials[entity.material].add(ifcEntity)
				end
			end
			def collect_layers(entity, ifcEntity)
				unless @hLayers.has_key?(entity.layer)
					@hLayers[entity.layer] = IfcPresentationLayerAssignment.new(self, entity.layer)
				end
				@hLayers[entity.layer].add(ifcEntity)
			end
			def get_entities(entities)
				if entities.nil?
					entities = Sketchup.active_model.entities
				end
				ifc_entities = Array.new
				entities.each do |entity|
					if entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)
						if entity.manifold?
							ifc_entities << entity
						end
					end
				end
				return ifc_entities
			end
			def add(entity)
				new_record_nr = @a_Ifc.length + 1
				new_record_nr = "#" + new_record_nr.to_s
				entity.record_nr=(new_record_nr)
				@a_Ifc << entity
			end
			
			def set_IfcProject()
				@ifcProject = IfcProject.new(self)
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
			
			def set_IfcSite(project)
				if @ifcSite.nil?
					@ifcSite = IfcSite.new(self)
					# IFCRELAGGREGATES('1hGct2v1LFjuexLy7xe$Mo', #2, 'ProjectContainer', 'ProjectContainer for Sites', #1, (#23));
					name = "'ProjectContainer'"
					description = "'ProjectContainer for Sites'"
					IfcRelAggregates.new(self, name, description, project, @ifcSite)
				end
				return @ifcSite
			end
			
			# create a building on the site, temporary solution because multiple buildings could be present
			def set_IfcBuilding(site)
				if @ifcBuilding.nil?
					@ifcBuilding = IfcBuilding.new(self)
					# IFCRELAGGREGATES('1_M0EvY2z24AX0l7nBeVj1', #2, 'SiteContainer', 'SiteContainer For Buildings', #23, (#29));
					name = "'SiteContainer'"
					description = "'SiteContainer For Buildings'"
					IfcRelAggregates.new(self, name, description, site, @ifcBuilding)
				end
				return @ifcBuilding
			end
			
			def add_to_building(ifc_entity)
				@aContainedInBuilding << ifc_entity.record_nr
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
FILE_DESCRIPTION (('ViewDefinition [CoordinationView]'), '2;1');
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
		end
	end # module IfcExport
end # module Brewsky
