#       Ifc.rb
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

		# http://www.dds-cad.net/files/net.dds-cad.com/downloads/Presseberichte/IA_IfcForProductLibraries_V01.pdf
		#IfcTypeObject
		#IfcRelDefinesByType 
		
		# IFC export base element
		class IfcBase
			attr_accessor :record_nr, :a_Attributes, :entityType
			
			# run this every time in initialize for all common properties
			def init_common(ifc_exporter)
				@ifc_exporter = ifc_exporter
				@model = @ifc_exporter.model
				@ifc_exporter.add(self)
				
				# IFC object name in CamelCase
				@entityTypeCc = self.class.name.split('::').last
				
				# IFC object name in UPPERCASE
				@entityType = @entityTypeCc.upcase
			end
			
			# returns a new row number
			def record_nr=(s_record_nr)
				@record_nr = s_record_nr
			end
			
			# function returns IFC "content"
			def record_content
				return ""
			end
			
			# function creates full IFC record
			def record
				return @ifc_exporter.ifcRecord(self)
				#return @record_nr + " = " + record_content + ";
		#"
			end
			
			def get_default(ifc_type, key)
				default = ifc_type + '_' + key
				if @ifc_exporter.defaults.get(default)
					@ifc_exporter.defaults.get(default)
				else
					return nil
				end
			end # get_default
			
			def set_name(entity=nil, ifc_type=nil, su_name=nil)
				return nil if entity.nil?
				return nil unless ifc_type.is_a? String
				name = nil
				
				if entity.get_attribute(ifc_type, 'Name').nil?
					unless su_name.nil? || entity.name == ""
						name = "'" + entity.name + "'"
						entity.set_attribute(ifc_type, 'Name', name)
					end
					
					if name.nil?
						if self.get_default(ifc_type, 'Name').nil?
							return nil
						else
							return "'" + self.get_default(ifc_type, 'Name') + "'"
						end
					else
						return name
					end
				else
					return entity.get_attribute(ifc_type, 'Name')
				end
			end # set_name
			
			def set_description(entity=nil, ifc_type=nil, su_description=nil)
				return nil if entity.nil?
				return nil unless ifc_type.is_a? String
				description = nil
				
				if entity.get_attribute(ifc_type, 'Description').nil?
					unless su_description.nil? || entity.description == ""
						description = "'" + entity.description + "'"
						entity.set_attribute(ifc_type, 'Description', description)
					end
					
					if description.nil?
						if self.get_default(ifc_type, 'Description').nil?
							return nil
						else
							return "'" + self.get_default(ifc_type, 'Description') + "'"
						end
					else
						return description
					end
				else
					return entity.get_attribute(ifc_type, 'Description')
				end
			end # set_description
		end # IfcBase

		#7 = IFCUNITASSIGNMENT((#8, #9, #10, #11, #15, #16, #17, #18, #19));
		#8 = IFCSIUNIT(*, .LENGTHUNIT., $, .METRE.);
		#9 = IFCSIUNIT(*, .AREAUNIT., $, .SQUARE_METRE.);
		#10 = IFCSIUNIT(*, .VOLUMEUNIT., $, .CUBIC_METRE.);
		#11 = IFCCONVERSIONBASEDUNIT(#12, .PLANEANGLEUNIT., 'DEGREE', #13);
		#12 = IFCDIMENSIONALEXPONENTS(0, 0, 0, 0, 0, 0, 0);
		#13 = IFCMEASUREWITHUNIT(IFCPLANEANGLEMEASURE(1.745E-2), #14);
		#14 = IFCSIUNIT(*, .PLANEANGLEUNIT., $, .RADIAN.);
		#15 = IFCSIUNIT(*, .SOLIDANGLEUNIT., $, .STERADIAN.);
		#16 = IFCSIUNIT(*, .MASSUNIT., $, .GRAM.);
		#17 = IFCSIUNIT(*, .TIMEUNIT., $, .SECOND.);
		#18 = IFCSIUNIT(*, .THERMODYNAMICTEMPERATUREUNIT., $, .DEGREE_CELSIUS.);
		#19 = IFCSIUNIT(*, .LUMINOUSINTENSITYUNIT., $, .LUMEN.);
		class IfcUnitAssignment < IfcBase
			# Attribute	Type	                  Defined By
			# Units	    SET OF IfcUnit (SELECT)	IfcUnitAssignment
			def initialize(ifc_exporter)
				@ifc_exporter = ifc_exporter
				@entityType = "IFCUNITASSIGNMENT"
				@ifc_exporter.add(self)
				
				aUnits = Array.new
				aUnits << IfcSIUnit.new(@ifc_exporter, ".LENGTHUNIT.", ".METRE.").record_nr
				aUnits << IfcSIUnit.new(@ifc_exporter, ".AREAUNIT.", ".SQUARE_METRE.").record_nr
				aUnits << IfcSIUnit.new(@ifc_exporter, ".VOLUMEUNIT.", ".CUBIC_METRE.").record_nr
				aUnits << IfcConversionBasedUnit.new(@ifc_exporter).record_nr
				aUnits << IfcSIUnit.new(@ifc_exporter, ".SOLIDANGLEUNIT.", ".STERADIAN.").record_nr
				aUnits << IfcSIUnit.new(@ifc_exporter, ".MASSUNIT.", ".GRAM.").record_nr
				aUnits << IfcSIUnit.new(@ifc_exporter, ".TIMEUNIT.", ".SECOND.").record_nr
				aUnits << IfcSIUnit.new(@ifc_exporter, ".THERMODYNAMICTEMPERATUREUNIT.", ".DEGREE_CELSIUS.").record_nr
				aUnits << IfcSIUnit.new(@ifc_exporter, ".LUMINOUSINTENSITYUNIT.", ".LUMEN.").record_nr
				
				# "local" IFC array
				@a_Attributes = Array.new
				@a_Attributes << @ifc_exporter.ifcList(aUnits)
			end
		end
		
		class IfcSIUnit < IfcBase
			# Attribute	  Type	                            Defined By
			# Dimensions*	IfcDimensionalExponents (ENTITY)	IfcSIUnit(Redcl from IfcNamedUnit)
			# UnitType	  IfcUnitEnum (ENUM)	              IfcNamedUnit
			# Prefix	    IfcSIPrefix (ENUM)	              IfcSIUnit
			# Name	      IfcSIUnitName (ENUM)	            IfcSIUnit
			def initialize(ifc_exporter, unitType, name)
				@ifc_exporter = ifc_exporter
				@entityType = "IFCSIUNIT"
				@ifc_exporter.add(self)
				
				# "local" IFC array
				@a_Attributes = Array.new
				@a_Attributes << "*"
				@a_Attributes << unitType
				@a_Attributes << "$"
				@a_Attributes << name
			end
		end
		
		#11 = IFCCONVERSIONBASEDUNIT(#12, .PLANEANGLEUNIT., 'DEGREE', #13);
		#12 = IFCDIMENSIONALEXPONENTS(0, 0, 0, 0, 0, 0, 0);
		#13 = IFCMEASUREWITHUNIT(IFCPLANEANGLEMEASURE(1.745E-2), #14);
		#14 = IFCSIUNIT(*, .PLANEANGLEUNIT., $, .RADIAN.);
		class IfcConversionBasedUnit < IfcBase
			# Attribute	        Type	                            Defined By
			# Dimensions	      IfcDimensionalExponents (ENTITY)	IfcNamedUnit
			# UnitType	        IfcUnitEnum (ENUM)	              IfcNamedUnit
			# Name	            IfcLabel (STRING)	                IfcConversionBasedUnit
			# ConversionFactor	IfcMeasureWithUnit (ENTITY)	      IfcConversionBasedUnit
			def initialize(ifc_exporter)
				@ifc_exporter = ifc_exporter
				@entityType = "IFCCONVERSIONBASEDUNIT"
				@ifc_exporter.add(self)
				
				# "local" IFC array
				@a_Attributes = Array.new
				@a_Attributes << IfcDimensionalExponents.new(@ifc_exporter).record_nr
				@a_Attributes << ".PLANEANGLEUNIT."
				@a_Attributes << "'DEGREE'"
				@a_Attributes << IfcMeasureWithUnit.new(@ifc_exporter).record_nr
			end
		end
		
		
		#12 = IFCDIMENSIONALEXPONENTS(0, 0, 0, 0, 0, 0, 0);
		class IfcDimensionalExponents < IfcBase
			def initialize(ifc_exporter)
				@ifc_exporter = ifc_exporter
				@entityType = "IFCDIMENSIONALEXPONENTS"
				@ifc_exporter.add(self)
				
				# "local" IFC array
				@a_Attributes = Array.new
				@a_Attributes << "0"
				@a_Attributes << "0"
				@a_Attributes << "0"
				@a_Attributes << "0"
				@a_Attributes << "0"
				@a_Attributes << "0"
				@a_Attributes << "0"
			end
		end
		
		#13 = IFCMEASUREWITHUNIT(IFCPLANEANGLEMEASURE(1.745E-2), #14);
		#14 = IFCSIUNIT(*, .PLANEANGLEUNIT., $, .RADIAN.);
		class IfcMeasureWithUnit < IfcBase
			def initialize(ifc_exporter)
				@ifc_exporter = ifc_exporter
				@entityType = "IFCMEASUREWITHUNIT"
				@ifc_exporter.add(self)
				
				# "local" IFC array
				@a_Attributes = Array.new
				@a_Attributes << "IFCPLANEANGLEMEASURE(1.745E-2)"
				@a_Attributes << IfcSIUnit.new(@ifc_exporter, ".PLANEANGLEUNIT.", ".RADIAN.").record_nr
			end
		end

		class IfcQuantityLength < IfcBase
		# Attribute	  Type	                  Defined By
		# Name	      IfcLabel (STRING)	      IfcPhysicalQuantity
		# Description	IfcText (STRING)	      IfcPhysicalQuantity
		# Unit	      IfcNamedUnit (ENTITY)	  IfcPhysicalSimpleQuantity
		# LengthValue	IfcLengthMeasure (REAL)	IfcQuantityLength
			attr_accessor :record_nr
			def initialize(ifc_exporter, name, value)
				@ifc_exporter = ifc_exporter
				@model = ifc_exporter.model
				@entityType = "IFCQUANTITYLENGTH"
				@ifc_exporter.add(self)
				
				# "local" IFC array
				@a_Attributes = Array.new
				@a_Attributes << ifc_exporter.ifcLabel(name)
				@a_Attributes << nil
				@a_Attributes << nil
				@a_Attributes << ifc_exporter.ifcLengthMeasure(value)
			end
		end
		
		class IfcQuantityArea < IfcBase
		# Attribute	  Type	                  Defined By
		# Name	      IfcLabel (STRING)	      IfcPhysicalQuantity
		# Description	IfcText (STRING)	      IfcPhysicalQuantity
		# Unit	      IfcNamedUnit (ENTITY)	  IfcPhysicalSimpleQuantity
		# AreaValue	  IfcAreaMeasure (REAL)	  IfcQuantityArea
			attr_accessor :record_nr
			def initialize(ifc_exporter, name, value)
				@ifc_exporter = ifc_exporter
				@model = ifc_exporter.model
				@entityType = "IFCQUANTITYAREA"
				@ifc_exporter.add(self)
				
				# "local" IFC array
				@a_Attributes = Array.new
				@a_Attributes << ifc_exporter.ifcLabel(name)
				@a_Attributes << nil
				@a_Attributes << nil
				@a_Attributes << ifc_exporter.ifcAreaMeasure(value)
			end
		end
		
		class IfcQuantityVolume < IfcBase
		# Attribute	    Type	                  Defined By
		# Name	        IfcLabel (STRING)	      IfcPhysicalQuantity
		# Description	  IfcText (STRING)	      IfcPhysicalQuantity
		# Unit	        IfcNamedUnit (ENTITY)	  IfcPhysicalSimpleQuantity
		# VolumeValue	  IfcVolumeMeasure (REAL)	IfcQuantityVolume
			attr_accessor :record_nr
			def initialize(ifc_exporter, name, value)
				@ifc_exporter = ifc_exporter
				@model = ifc_exporter.model
				@entityType = "IFCQUANTITYVOLUME"
				@ifc_exporter.add(self)
				
				# "local" IFC array
				@a_Attributes = Array.new
				@a_Attributes << ifc_exporter.ifcLabel(name)
				@a_Attributes << nil
				@a_Attributes << nil
				@a_Attributes << ifc_exporter.ifcVolumeMeasure(value)
			end
		end
		
		class IfcRoot < IfcBase
			attr_accessor :globalId, :name, :description, :record_nr#, :ownerHistory        
			def set_globalId(entity, ifc_type)
				if entity.get_attribute(ifc_type, "GlobalId")
					return entity.get_attribute(ifc_type, "GlobalId")
				else
					guid = "'" + Brewsky::IFC::new_guid + "'"
					entity.set_attribute(ifc_type, "GlobalId", guid)
					return guid
				end
			end

		end
			
		
		class IfcObject < IfcRoot
			#Attribute	      Type	                            Defined By
			#GlobalId	        IfcGloballyUniqueId (STRING)	    IfcRoot
			#OwnerHistory	    IfcOwnerHistory (ENTITY)	        IfcRoot
			#Name	            IfcLabel (STRING)	                IfcRoot #optional
			#Description	    IfcText (STRING)	                IfcRoot #optional
			#ObjectType	      IfcLabel (STRING)	                IfcObject
			attr_accessor :objectType
			def set_objectType(entity)
				@objectType = nil
			end
			def set_ObjectType
				return nil
			end
		end
		
		#1 = IFCPROJECT('0YvctVUKr0kugbFTf53O9L', #2, 'Default Project', 'Description of Default Project', $, $, $, (#20), #7);
		#7 = IFCUNITASSIGNMENT((#8, #9, #10, #11, #15, #16, #17, #18, #19));
		#8 = IFCSIUNIT(*, .LENGTHUNIT., $, .METRE.);
		#9 = IFCSIUNIT(*, .AREAUNIT., $, .SQUARE_METRE.);
		#10 = IFCSIUNIT(*, .VOLUMEUNIT., $, .CUBIC_METRE.);
		#11 = IFCCONVERSIONBASEDUNIT(#12, .PLANEANGLEUNIT., 'DEGREE', #13);
		#12 = IFCDIMENSIONALEXPONENTS(0, 0, 0, 0, 0, 0, 0);
		#13 = IFCMEASUREWITHUNIT(IFCPLANEANGLEMEASURE(1.745E-2), #14);
		#14 = IFCSIUNIT(*, .PLANEANGLEUNIT., $, .RADIAN.);
		#15 = IFCSIUNIT(*, .SOLIDANGLEUNIT., $, .STERADIAN.);
		#16 = IFCSIUNIT(*, .MASSUNIT., $, .GRAM.);
		#17 = IFCSIUNIT(*, .TIMEUNIT., $, .SECOND.);
		#18 = IFCSIUNIT(*, .THERMODYNAMICTEMPERATUREUNIT., $, .DEGREE_CELSIUS.);
		#19 = IFCSIUNIT(*, .LUMINOUSINTENSITYUNIT., $, .LUMEN.);
		class IfcProject < IfcObject
			# Attribute	              Type	                                    Defined By
			# GlobalId	              IfcGloballyUniqueId (STRING)	            IfcRoot
			# OwnerHistory	          IfcOwnerHistory (ENTITY)	                IfcRoot
			# Name	                  IfcLabel (STRING)	                        IfcRoot
			# Description	            IfcText (STRING)	                        IfcRoot
			# ObjectType	            IfcLabel (STRING)	                        IfcObject
			# LongName	              IfcLabel (STRING)	                        IfcProject
			# Phase	                  IfcLabel (STRING)	                        IfcProject
			# RepresentationContexts	SET OF IfcRepresentationContext (ENTITY)	IfcProject
			# UnitsInContext	        IfcUnitAssignment (ENTITY)	              IfcProject
			attr_accessor :record_nr, :ifcOwnerHistory
			def initialize(ifc_exporter)
				init_common(ifc_exporter)
				@ifcOwnerHistory = IfcOwnerHistory.new(@ifc_exporter)
				ifcUnitAssignment = IfcUnitAssignment.new(@ifc_exporter)
				aIfcGeometricRepresentationContext = Array.new
				aIfcGeometricRepresentationContext << @ifc_exporter.set_IfcGeometricRepresentationContext.record_nr#IfcGeometricRepresentationContext.new(@ifc_exporter, @model).record_nr

				# "local" IFC array
				@a_Attributes = Array.new
				@a_Attributes << set_globalId(@model, @entityTypeCc)
				@a_Attributes << @ifcOwnerHistory.record_nr
				@a_Attributes << set_name(@model, @entityTypeCc)
				@a_Attributes << set_description(@model, @entityTypeCc)
				@a_Attributes << nil
				@a_Attributes << nil
				@a_Attributes << nil
				@a_Attributes << @ifc_exporter.ifcList(aIfcGeometricRepresentationContext)
				@a_Attributes << ifcUnitAssignment.record_nr
			end
			
		end
		
		#2 = IFCOWNERHISTORY(#3, #6, $, .ADDED., $, $, $, 1217620436);
		class IfcOwnerHistory < IfcBase
			# Attribute	                Type	                            Defined By
			# OwningUser	              IfcPersonAndOrganization (ENTITY)	IfcOwnerHistory
			# OwningApplication	        IfcApplication (ENTITY)         	IfcOwnerHistory
			# State	                    IfcStateEnum (ENUM)	              IfcOwnerHistory (optional)
			# ChangeAction	            IfcChangeActionEnum (ENUM)	      IfcOwnerHistory
			# LastModifiedDate	        IfcTimeStamp (INTEGER)	          IfcOwnerHistory (optional)
			# LastModifyingUser	        IfcPersonAndOrganization (ENTITY)	IfcOwnerHistory (optional)
			# LastModifyingApplication  IfcApplication (ENTITY)	          IfcOwnerHistory (optional)
			# CreationDate	            IfcTimeStamp (INTEGER)	          IfcOwnerHistory
			attr_accessor :record_nr
			def initialize(ifc_exporter)
				@ifc_exporter = ifc_exporter
				@model = ifc_exporter.model
				@entityType = "IFCOWNERHISTORY"
				@ifc_exporter.add(self)
				
				# "local" IFC array
				@a_Attributes = Array.new
				@a_Attributes << IfcPersonAndOrganization.new(@ifc_exporter).record_nr
				@a_Attributes << IfcApplication.new(@ifc_exporter).record_nr
				@a_Attributes << nil
				@a_Attributes << ".ADDED." # ???
				@a_Attributes << nil
				@a_Attributes << nil
				@a_Attributes << nil
				@a_Attributes << "1217620436" # !!!
			end
		end
		
		#3 = IFCPERSONANDORGANIZATION(#4, #5, $);
		class IfcPersonAndOrganization < IfcBase
			# Attribute	      Type	                        Defined By
			# ThePerson	      IfcPerson (ENTITY)	          IfcPersonAndOrganization
			# TheOrganization	IfcOrganization (ENTITY)	    IfcPersonAndOrganization
			# Roles           LIST OF IfcActorRole (ENTITY)	IfcPersonAndOrganization (optional)
			attr_accessor :record_nr
			def initialize(ifc_exporter)
				@ifc_exporter = ifc_exporter
				@model = ifc_exporter.model
				@entityType = "IFCPERSONANDORGANIZATION"
				@ifc_exporter.add(self)
				
				# "local" IFC array
				@a_Attributes = Array.new
				@a_Attributes << IfcPerson.new(@ifc_exporter).record_nr
				@a_Attributes << @ifc_exporter.set_IfcOrganization.record_nr
				@a_Attributes << nil
			end
		end
		
		#4 = IFCPERSON('ID001', 'Bonsma', 'Peter', $, $, $, $, $);
		class IfcPerson < IfcBase
			# Attribute	    Type	                        Defined By
			# ID	          IfcIdentifier (STRING)	      IfcPerson (optional)
			# FamilyName	  IfcLabel (STRING)	            IfcPerson (optional)
			# GivenName	    IfcLabel (STRING)	            IfcPerson (optional)
			# MiddleNames	  LIST OF IfcLabel (STRING)	    IfcPerson (optional)
			# PrefixTitles	LIST OF IfcLabel (STRING)	    IfcPerson (optional)
			# SuffixTitles	LIST OF IfcLabel (STRING)	    IfcPerson (optional)
			# Roles	        LIST OF IfcActorRole (ENTITY)	IfcPerson (optional)
			# Addresses	    LIST OF IfcAddress (ENTITY)	  IfcPerson (optional)
			attr_accessor :record_nr
			def initialize(ifc_exporter)
				@ifc_exporter = ifc_exporter
				@model = ifc_exporter.model
				@entityType = "IFCPERSON"
				@ifc_exporter.add(self)
				
				# "local" IFC array
				@a_Attributes = Array.new
				@a_Attributes << nil
				@a_Attributes << nil
				@a_Attributes << nil
				@a_Attributes << nil
				@a_Attributes << nil
				@a_Attributes << nil
				@a_Attributes << nil
				@a_Attributes << nil
			end
		end
		
		#5 = IFCORGANIZATION($, 'TNO', 'TNO Building Innovation', $, $);
		class IfcOrganization < IfcBase
			# Attribute	    Type	                        Defined By
			# ID	          IfcIdentifier (STRING)	      IfcOrganization (optional)
			# Name      	  IfcLabel (STRING)	            IfcOrganization
			# Description	  IfcText (STRING)	            IfcOrganization (optional)
			# Roles	        LIST OF IfcActorRole (ENTITY)	IfcOrganization (optional)
			# Addresses	    LIST OF IfcAddress (ENTITY)	  IfcOrganization (optional)
			attr_accessor :record_nr
			def initialize(ifc_exporter, organisation_name=nil, organisation_description=nil)
				init_common(ifc_exporter)
				
				# "local" IFC array
				@a_Attributes = Array.new
				@a_Attributes << nil
				@a_Attributes << set_name(@model, @entityTypeCc)
				@a_Attributes << set_description(@model, @entityTypeCc)
				@a_Attributes << nil
				@a_Attributes << nil
			end
		end
		
		#6 = IFCAPPLICATION(#5, '0.10', 'Test Application', 'TA 1001');
		class IfcApplication < IfcBase
			# Attribute	            Type	                    Defined By
			# ApplicationDeveloper	IfcOrganization (ENTITY)	IfcApplication
			# Version	              IfcLabel (STRING)	        IfcApplication
			# ApplicationFullName	  IfcLabel (STRING)	        IfcApplication
			# ApplicationIdentifier	IfcIdentifier (STRING)	  IfcApplication
			attr_accessor :record_nr
			def initialize(ifc_exporter)
				@ifc_exporter = ifc_exporter
				@model = ifc_exporter.model
				@entityType = "IFCAPPLICATION"
				@ifc_exporter.add(self)
				
				# "local" IFC array
				@a_Attributes = Array.new
				#@a_Attributes << @ifc_exporter.set_IfcOrganization.record_nr
				@a_Attributes << IfcOrganization.new(@ifc_exporter, "'BIM-Tools Project'", "'Open source Building-modeller project'").record_nr
				@a_Attributes << "'0.12.2'"
				@a_Attributes << "'BIM-Tools for SketchUp'"
				@a_Attributes << "'BIM-Tools'"
			end
		end
		
		
		# IFCRELAGGREGATES('1_M0EvY2z24AX0l7nBeVj1', #2, 'SiteContainer', 'SiteContainer For Buildings', #23, (#29));
		class IfcRelAggregates < IfcRoot
			# Attribute	      Type	                              Defined By
			# GlobalId	      IfcGloballyUniqueId (STRING)	      IfcRoot
			# OwnerHistory	  IfcOwnerHistory (ENTITY)	          IfcRoot
			# Name	          IfcLabel (STRING)	                  IfcRoot
			# Description	    IfcText (STRING)	                  IfcRoot
			# RelatingObject	IfcObjectDefinition (ENTITY)	      IfcRelDecomposes
			# RelatedObjects	SET OF IfcObjectDefinition (ENTITY)	IfcRelDecomposes
			attr_accessor :record_nr
					#IfcRelAggregates.new(self, name, description, site, @ifcBuilding)
			def initialize(ifc_exporter, name, description, relating, related)
				init_common(ifc_exporter)
				
				# "local" IFC array
				@a_Attributes = Array.new
				@a_Attributes << set_globalId(@model, @entityTypeCc)
				@a_Attributes << @ifc_exporter.ifcProject.ifcOwnerHistory.record_nr
				@a_Attributes << name
				@a_Attributes << description
				@a_Attributes << relating.record_nr
				@a_Attributes << @ifc_exporter.ifcList(related.record_nr)
			end
		end

		
		class IfcExtrudedAreaSolid < IfcBase
			# Attribute	        Type	                          Defined By
			# SweptArea	        IfcProfileDef (ENTITY)	        IfcSweptAreaSolid
			# Position	        IfcAxis2Placement3D (ENTITY)    IfcSweptAreaSolid
			# ExtrudedDirection	IfcDirection (ENTITY)	          IfcExtrudedAreaSolid
			# Depth	            IfcPositiveLengthMeasure (REAL)	IfcExtrudedAreaSolid
			attr_accessor :sweptArea, :position, :extrudedDirection, :depth, :record_nr, :entityType
			def initialize(ifc_exporter, bt_entity, loop, depth=nil)
				@ifc_exporter = ifc_exporter
				@bt_entity = bt_entity
				@loop = loop
				@entityType = "IFCEXTRUDEDAREASOLID"
				@ifc_exporter.add(self)
				
				offset = @bt_entity.offset * -1
				vector = Geom::Vector3d.new 0,0,offset
				@transformation = Geom::Transformation.translation vector
				
				#@transformation = @bt_entity.geometry.transformation
				
				# "local" IFC array
				@a_Attributes = Array.new
				@a_Attributes << set_SweptArea
				@a_Attributes << set_Position
				@a_Attributes << set_ExtrudedDirection(loop)
				@a_Attributes << set_Depth(depth)
			end
			def set_SweptArea
		#85 = IFCARBITRARYCLOSEDPROFILEDEF(.AREA., $, #86);
		#86 = IFCPOLYLINE((#87, #88, #89, #90, #91));
		#87 = IFCCARTESIANPOINT((0., 0.));
		#88 = IFCCARTESIANPOINT((0., 3.000E-1));
		#89 = IFCCARTESIANPOINT((5., 3.000E-1));
		#90 = IFCCARTESIANPOINT((5., 0.));
		#91 = IFCCARTESIANPOINT((0., 0.));
				return IfcArbitraryClosedProfileDef.new(@ifc_exporter, @bt_entity, @loop).record_nr
			end
			def set_Position
				return IfcAxis2Placement3D.new(@ifc_exporter, @transformation).record_nr
			end
			def set_ExtrudedDirection(loop)
				vec = Geom::Vector3d.new(0,0,1) #loop.face.normal.transform @transformation.inverse#@transformation.zaxis#.reverse #
				return IfcDirection.new(@ifc_exporter, vec).record_nr
			end
			def set_Depth(depth=nil)
				if depth.nil?
					return @ifc_exporter.ifcLengthMeasure(@bt_entity.width)
				else
					return @ifc_exporter.ifcLengthMeasure(depth)
				end
			end
		end

		# entity must be of the type group component instance
		#97= IFCFACETEDBREP(#106);
		class IfcFacetedBrep < IfcBase
			# Attribute	    Type	                          Defined By
			# Outer	        IfcClosedShell (ENTITY)	        IfcManifoldSolidBrep
			attr_accessor :record_nr
			def initialize(ifc_exporter, entity)
				
				init_common(ifc_exporter)
				
				# "local" IFC array
				@a_Attributes = Array.new
				@a_Attributes << set_IfcClosedShell(entity)
			end
			def set_IfcClosedShell(entity)
				return IfcClosedShell.new(@ifc_exporter, entity).record_nr
			end
		end

		# entity must be of the type group component instance
		#106= IFCCLOSEDSHELL((#110,#153,#172,#207,#218,#229,#240,#251,#262,#273));
		class IfcClosedShell < IfcBase
			# Attribute	    Type	                          Defined By
			# CfsFaces      SET OF IfcFace (ENTITY)	        IfcConnectedFaceSet
			
			attr_accessor :record_nr
			def initialize(ifc_exporter, entity)
				init_common(ifc_exporter)
				
				# "local" IFC array
				@a_Attributes = Array.new
				@a_Attributes << set_IfcFaces(entity)
			end
			def set_IfcFaces(entity)
				hVertices = Hash.new
				aFaces = Array.new
				
				# in this case we need a definition, not an instance
				definition = Brewsky::IFC::definition(entity)
				definition.entities.each do |ent|
					if ent.is_a? Sketchup::Face
						aFaces << IfcFace.new(@ifc_exporter, ent, hVertices).record_nr
					end
				end
				return @ifc_exporter.ifcList(aFaces)
			end
		end

		# entity must be of the type face
		#153= IFCFACE((#157));
		class IfcFace < IfcBase
			# Attribute	    Type	                          Defined By
			# Bounds        SET OF IfcFaceBound (ENTITY)	  IfcFace
			
			attr_accessor :record_nr
			def initialize(ifc_exporter, entity, hVertices)
				init_common(ifc_exporter)
				
				# "local" IFC array
				@a_Attributes = Array.new
				@a_Attributes << set_IfcFaceBound(entity, hVertices)
			end
			def set_IfcFaceBound(entity, hVertices)
				aFace = Array.new
				entity.loops.each do |loop|
					if loop == entity.outer_loop
						aFace << IfcFaceOuterBound.new(@ifc_exporter, loop, hVertices).record_nr
					else
						aFace << IfcFaceBound.new(@ifc_exporter, loop, hVertices).record_nr
					end
				end
				return @ifc_exporter.ifcList(aFace)
			end
		end

		# entity must be of the type loop
		#157= IFCFACEOUTERBOUND(#160,.T.);
		class IfcFaceOuterBound < IfcBase
			# Attribute     Type	            Defined By
			# Bound         IfcLoop (ENTITY)	IfcFaceBound
			# Orientation   BOOLEAN	          IfcFaceBound
			
			attr_accessor :record_nr
			def initialize(ifc_exporter, entity, hVertices)
				init_common(ifc_exporter)
				
				# "local" IFC array
				@a_Attributes = Array.new
				@a_Attributes << IfcPolyLoop.new(@ifc_exporter, entity, hVertices).record_nr
				@a_Attributes << ".T."
			end
		end

		# entity must be of the type loop
		#157= IFCFACEOUTERBOUND(#160,.T.);
		class IfcFaceBound < IfcBase
			# Attribute     Type	            Defined By
			# Bound         IfcLoop (ENTITY)	IfcFaceBound
			# Orientation   BOOLEAN	          IfcFaceBound
			
			attr_accessor :record_nr
			def initialize(ifc_exporter, entity, hVertices)
				init_common(ifc_exporter)
				
				# "local" IFC array
				@a_Attributes = Array.new
				@a_Attributes << IfcPolyLoop.new(@ifc_exporter, entity, hVertices).record_nr
				@a_Attributes << ".T."
			end
		end


		# entity must be of the type loop
		#160= IFCPOLYLOOP((#133,#129,#164,#168));
		class IfcPolyLoop < IfcBase
			# Attribute Type	                                      Defined By
			# Polygon   LIST OF IfcCartesianPoint (ENTITY) (ENTITY)	IfcPolyLoop

			attr_accessor :record_nr
			def initialize(ifc_exporter, entity, hVertices)
				init_common(ifc_exporter)
				
				# "local" IFC array
				@a_Attributes = Array.new
				@a_Attributes << set_Polygon(entity, hVertices)
			end
			def set_Polygon(entity, hVertices)
				aPts = Array.new
				entity.vertices.each do |vertex|
					
					# check if the given vertex already has an IfcCartesianPoint
					unless hVertices[vertex]
						hVertices[vertex] = IfcCartesianPoint.new(@ifc_exporter, vertex.position)
					end
					aPts << hVertices[vertex].record_nr
				end
				return @ifc_exporter.ifcList(aPts)
			end
		end
		
		class WscIfcExtrudedAreaSolid < IfcExtrudedAreaSolid # special version for ifcwallstandardcase
			attr_accessor :sweptArea, :position, :extrudedDirection, :depth, :record_nr, :entityType
			def initialize(ifc_exporter, bt_entity, loop, depth=nil)
				@ifc_exporter = ifc_exporter
				@bt_entity = bt_entity
				@loop = loop
				@entityType = "IFCEXTRUDEDAREASOLID"
				@ifc_exporter.add(self)
				
				vector = Geom::Vector3d.new 0,0,0
				@transformation = Geom::Transformation.translation vector
				
				# "local" IFC array
				@a_Attributes = Array.new
				@a_Attributes << set_SweptArea
				@a_Attributes << set_Position
				@a_Attributes << set_ExtrudedDirection(loop)
				@a_Attributes << set_Depth(depth)
			end
		end
		
		class IfcArbitraryClosedProfileDef < IfcBase
			attr_accessor :record_nr, :entityType
			def initialize(ifc_exporter, bt_entity, loop)
				@ifc_exporter = ifc_exporter
				@bt_entity = bt_entity
				@loop = loop
				@entityType = "IFCARBITRARYCLOSEDPROFILEDEF"
				@ifc_exporter.add(self)
				
				# "local" IFC array
				@a_Attributes = Array.new
				@a_Attributes << ".AREA."
				@a_Attributes << nil
				@a_Attributes << IfcPolyline.new(@ifc_exporter, @bt_entity, @loop).record_nr
			end
		end
		
		class IfcPolyline < IfcBase
			attr_accessor :record_nr, :entityType
			def initialize(ifc_exporter, bt_entity, loop, closed=true)
				@ifc_exporter = ifc_exporter
				@bt_entity = bt_entity
				@loop = loop
				@entityType = "IFCPOLYLINE"
				@ifc_exporter.add(self)
				
				# "local" IFC array
				@a_Attributes = Array.new
				pts = Array.new
				
				#t = @bt_entity.geometry.transformation.inverse
				#verts = bt_entity.source.outer_loop.vertices
				#verts = @loop.vertices
				#verts.each do |vert|
					#position = vert.position#.transform! t
				@loop.each do |position|
					ifcCartesianPoint = IfcCartesianPoint.new(@ifc_exporter, position)
					pts << ifcCartesianPoint.record_nr
				end

				#add endpoint, only complete loop for a closed curve, not an open curve
				if closed == true
					pts << pts[0]
				end
				@a_Attributes << @ifc_exporter.ifcList(pts)
			end
		end
		
		class IfcObjectPlacement < IfcBase
			def initialize(ifc_exporter, bt_entity)
				@entityType = "IFCOBJECTPLACEMENT"
				ifc_exporter.add(self)
			end
		end
		
		class IfcLocalPlacement < IfcObjectPlacement
			def initialize(ifc_exporter, transformation_parent=nil, transformation=nil)
				@ifc_exporter = ifc_exporter
				@entityType = "IFCLOCALPLACEMENT"
				@ifc_exporter.add(self)
				
				# "local" IFC array
				@a_Attributes = Array.new
				@a_Attributes << set_placement(transformation_parent)
				@a_Attributes << set_placement(transformation)
			end
			
			# this should link to the placement of the parent object
			# for simplicity returns origin
			# ERROR: Field PlacementRelTo of IfcLocalPlacement cannot contain a IfcAxis2Placement3D
			def set_placement(transformation)
				if transformation.nil?
					return nil
				else
					return IfcAxis2Placement3D.new(@ifc_exporter, transformation).record_nr
				end
			end
		end
		
		class IfcPlacement < IfcBase
			attr_accessor :location
			def initialize(ifc_exporter, bt_entity)
				@entityType = "IFCPLACEMENT"
				ifc_exporter.add(self)
			end
		end
		
		class IfcAxis2Placement3D < IfcPlacement
			attr_accessor :axis, :refDirection
			def initialize(ifc_exporter, transformation)
				@ifc_exporter = ifc_exporter
				@entityType = "IFCAXIS2PLACEMENT3D"
				@ifc_exporter.add(self)
					
				# "local" IFC array
				@a_Attributes = Array.new
				@a_Attributes << set_Location(transformation).record_nr
				@a_Attributes << set_Axis(transformation).record_nr
				@a_Attributes << set_RefDirection(transformation).record_nr # ?????????????
			end
			def set_Location(transformation)
				@location = transformation.origin #	IfcCartesianPoint
				return IfcCartesianPoint.new(@ifc_exporter, @location)
			end  
			def set_Axis(transformation)
				vec = transformation.zaxis # IfcDirection
				return IfcDirection.new(@ifc_exporter, vec)
			end  
			def set_RefDirection(transformation)
				vec = transformation.xaxis # ??? #	IfcDirection  
				return IfcDirection.new(@ifc_exporter, vec)
			end
		end
		
		class IfcCartesianPoint < IfcBase
			attr_accessor :coordinates
			def initialize(ifc_exporter, point3d)
				@ifc_exporter = ifc_exporter
				@entityType = "IFCCARTESIANPOINT"
				ifc_exporter.add(self)
				@coordinates = point3d
				
				# "local" IFC array
				@a_Attributes = Array.new
				s_Ifc = "(" # LIST
				s_Ifc = s_Ifc + @ifc_exporter.ifcLengthMeasure(@coordinates.x) # should end with 0. : IfcLengthMeasure  # LIST
				s_Ifc = s_Ifc + ", "  # LIST
				s_Ifc = s_Ifc + @ifc_exporter.ifcLengthMeasure(@coordinates.y) # should end with 0. : IfcLengthMeasure  # LIST
				s_Ifc = s_Ifc + ", "  # LIST
				s_Ifc = s_Ifc + @ifc_exporter.ifcLengthMeasure(@coordinates.z) # should end with 0. : IfcLengthMeasure  # LIST
				s_Ifc = s_Ifc + ")"  # LIST
				@a_Attributes << s_Ifc
			end
		end
		
		class IfcDirection < IfcBase
			attr_accessor :directionRatios
			def initialize(ifc_exporter, vector)
				@ifc_exporter = ifc_exporter
				@entityType = "IFCDIRECTION"
				ifc_exporter.add(self)
				vector.normalize! # direction ratios == x,y and z value of normal vector
				@directionRatios = vector
				
				#		lat = [lat[0], latpart[0] + latpart[1], latpart[2] + latpart[3]]
				#return @ifc_exporter.ifcList(lat)
				
				# "local" IFC array
				@a_Attributes = Array.new
				#s_Ifc = "(" # LIST
				#s_Ifc = s_Ifc + @ifc_exporter.ifcLengthMeasure(@directionRatios.x)#@directionRatios.x.to_s # LIST
				#s_Ifc = s_Ifc + ", "  # LIST
				#s_Ifc = s_Ifc + @ifc_exporter.ifcLengthMeasure(@directionRatios.y)#@directionRatios.y.to_s # LIST
				#s_Ifc = s_Ifc + ", "  # LIST
				#s_Ifc = s_Ifc + @ifc_exporter.ifcLengthMeasure(@directionRatios.z)#@directionRatios.z.to_s # LIST
				#s_Ifc = s_Ifc + ")"  # LIST
				aList = [@ifc_exporter.ifcReal(@directionRatios.x), @ifc_exporter.ifcReal(@directionRatios.y), @ifc_exporter.ifcReal(@directionRatios.z)]
				@a_Attributes << @ifc_exporter.ifcList(aList)#s_Ifc
			end
		end		
		
		#20 = IFCGEOMETRICREPRESENTATIONCONTEXT($, 'Model', 3, 1.000E-5, #21, $);
		#21 = IFCAXIS2PLACEMENT3D(#22, $, $);
		#22 = IFCCARTESIANPOINT((0., 0., 0.));
		class IfcGeometricRepresentationContext < IfcBase
			# Attribute	                      Type	                      Defined By
			# ContextIdentifier	              IfcLabel (STRING)	          IfcRepresentationContext
			# ContextType	                    IfcLabel (STRING)	          IfcRepresentationContext
			# CoordinateSpaceDimension	      IfcDimensionCount (INTEGER)	IfcGeometricRepresentationContext
			# Precision	                      REAL	                      IfcGeometricRepresentationContext
			# WorldCoordinateSystem	          IfcAxis2Placement (SELECT)	IfcGeometricRepresentationContext
			# TrueNorth	                      IfcDirection (ENTITY)	      IfcGeometricRepresentationContext
			def initialize(ifc_exporter)
				@model = ifc_exporter.model
				@ifc_exporter = ifc_exporter
				@entityType = "IFCGEOMETRICREPRESENTATIONCONTEXT"
				@ifc_exporter.add(self)
				
				transformation = Geom::Transformation.new
				
				# "local" IFC array
				@a_Attributes = Array.new
				@a_Attributes << nil
				@a_Attributes << "'Model'"
				@a_Attributes << "3"
				@a_Attributes << "1.000E-5"
				@a_Attributes << IfcAxis2Placement3D.new(@ifc_exporter, transformation).record_nr
				@a_Attributes << nil
			end
		end
		
		# http://www.buildingsmart-tech.org/ifc/IFC2x4/alpha/html/ifcsharedbldgelements/lexical/ifcwall.htm
		
		# Quantity Use Definition:
		# The quantities relating to the IfcWall and IfcWallStandardCase are defined by the IfcElementQuantity and attached by the IfcRelDefinesByProperties relationship. It is accessible by the inverse IsDefinedBy relationship. The following base quantities are defined and should be exchanged with the IfcElementQuantity.MethodOfMeasurement = 'BaseQuantities'. Other quantities can be defined being subjected to local standard of measurement with another string value assigned to MethodOfMeasurement.
		
		# Name	              Description	Value                                                                                                                                                         Type
		# Length	            Total nominal length of the wall along the wall path.	                                                                                                                    IfcQuantityLength
		# Width	              Total nominal width (or thickness) of the wall measured perpendicular to the wall path. It should only be provided, if it is constant along the wall path.	              IfcQuantityLength
		# Height	            Total nominal height of the wall. It should only be provided, if it is constant along the wall path.	                                                                    IfcQuantityLength
		# GrossFootprintArea	Area of the wall as viewed by a ground floor view, not taking any wall modifications (like recesses) into account. It is also referred to as the foot print of the wall.	IfcQuantityArea
		# NetFootprintArea	  Area of the wall as viewed by a ground floor view, taking all wall modifications (like recesses) into account. It is also referred to as the foot print of the wall.	    IfcQuantityArea
		# GrossSideArea	      Area of the wall as viewed by an elevation view of the middle plane of the wall.  It does not take into account any wall modifications (such as openings).	              IfcQuantityArea
		# NetSideArea	        Area of the wall as viewed by an elevation view of the middle plane. It does take into account all wall modifications (such as openings).	                                IfcQuantityArea
		# GrossVolume	        Volume of the wall, without taking into account the openings and the connection geometry.	                                                                                IfcQuantityVolume
		# NetVolume	          Volume of the wall, after subtracting the openings and after considering the connection geometry.	                                                                        IfcQuantityVolume
		
		class IfcElementQuantity < IfcRoot
		# Attribute	          Type	                              Defined By
		# GlobalId	          IfcGloballyUniqueId (STRING)	      IfcRoot
		# OwnerHistory	      IfcOwnerHistory (ENTITY)	          IfcRoot
		# Name	              IfcLabel (STRING)	                  IfcRoot             OPTIONAL
		# Description	        IfcText (STRING)	                  IfcRoot             OPTIONAL
		# MethodOfMeasurement	IfcLabel (STRING)	                  IfcElementQuantity  OPTIONAL
		# Quantities	        SET OF IfcPhysicalQuantity (ENTITY)	IfcElementQuantity
		
			def initialize(ifc_exporter, planar)
				@ifc_exporter = ifc_exporter
				@model = ifc_exporter.model
				@planar = planar
				@entityType = "IFCELEMENTQUANTITY"
				@ifc_exporter.add(self)
				
				quantities = Array.new
				quantities << IfcQuantityLength.new(@ifc_exporter, "Length", planar.length?).record_nr #quantities["Length"] = planar.length?
				quantities << IfcQuantityLength.new(@ifc_exporter, "Width", planar.width).record_nr #quantities["Width"] = planar.width
				quantities << IfcQuantityLength.new(@ifc_exporter, "Height", planar.height?).record_nr #quantities["Height"] = planar.height?
				quantities << IfcQuantityArea.new(@ifc_exporter, "GrossFootprintArea", planar.length? * planar.width).record_nr #quantities["GrossFootprintArea"] = planar.length? * planar.width
				quantities << IfcQuantityArea.new(@ifc_exporter, "NetFootprintArea", planar.length? * planar.width).record_nr #quantities["NetFootprintArea"] = planar.length? * planar.width
				quantities << IfcQuantityArea.new(@ifc_exporter, "GrossSideArea", planar.height? * planar.length?).record_nr #quantities["GrossSideArea"] = planar.height? * planar.length?
				quantities << IfcQuantityArea.new(@ifc_exporter, "NetSideArea", planar.height? * planar.length?).record_nr #quantities["NetSideArea"] = planar.height? * planar.length?
				quantities << IfcQuantityVolume.new(@ifc_exporter, "GrossVolume", planar.height? * planar.length? * planar.width).record_nr #quantities["GrossVolume"] = planar.height? * planar.length? * planar.width
				quantities << IfcQuantityVolume.new(@ifc_exporter, "NetVolume", planar.geometry.volume * (25.4 **3)).record_nr #quantities["NetVolume"] = planar.geometry.volume * (25.4 **3)
		
				# "local" IFC array
				@a_Attributes = Array.new
				@a_Attributes << set_globalId
				@a_Attributes << @ifc_exporter.ifcProject.ifcOwnerHistory.record_nr
				@a_Attributes << set_name
				@a_Attributes << set_description
				@a_Attributes << "'BaseQuantities'"
				@a_Attributes << ifc_exporter.ifcList(quantities)
			end
		end
		
		class IfcRelDefinesByProperties < IfcRoot
		# Attribute	                  Type	                            Defined By
		# GlobalId	                  IfcGloballyUniqueId (STRING)	    IfcRoot
		# OwnerHistory	              IfcOwnerHistory (ENTITY)	        IfcRoot
		# Name	                      IfcLabel (STRING)	                IfcRoot
		# Description	                IfcText (STRING)	                IfcRoot
		# RelatedObjects	            SET OF IfcObject (ENTITY)	        IfcRelDefines
		# RelatingPropertyDefinition	IfcPropertySetDefinition (ENTITY)	IfcRelDefinesByProperties
			attr_accessor :record_nr
			def initialize(ifc_exporter, planar, aRelatedObjects)
				@ifc_exporter = ifc_exporter
				@model = ifc_exporter.model
				@entityType = "IFCRELDEFINESBYPROPERTIES"
				@ifc_exporter.add(self)
				
				# "local" IFC array
				@a_Attributes = Array.new
				@a_Attributes << set_globalId
				@a_Attributes << @ifc_exporter.ifcProject.ifcOwnerHistory.record_nr
				@a_Attributes << set_name
				@a_Attributes << set_description
				@a_Attributes << ifc_exporter.ifcList(aRelatedObjects)
				@a_Attributes << IfcElementQuantity.new(@ifc_exporter, planar).record_nr
			end
		end

	# kleur exporteren
	#231= IFCEXTRUDEDAREASOLID(#227,#228,#36,2960.);
	#246= IFCCOLOURRGB($,0.76078431,0.61568627,0.54509804);
	#247= IFCSURFACESTYLERENDERING(#246,0.,IFCNORMALISEDRATIOMEASURE(0.69),$,$,$,IFCNORMALISEDRATIOMEASURE(0.83),$,.NOTDEFINED.);
	#248= IFCSURFACESTYLE('21 Buitenwand metselwerk',.BOTH.,(#247));
	#250= IFCPRESENTATIONSTYLEASSIGNMENT((#248));
	#252= IFCSTYLEDITEM(#231,(#250),$);
	
		#9=IFCCARTESIANPOINT((0.,0.,0.));
		#10=IFCDIRECTION((1.,0.,0.));
		#12=IFCDIRECTION((0.,0.,1.));
		#16=IFCAXIS2PLACEMENT3D(#9,#12,#10);
		#17=IFCGEOMETRICREPRESENTATIONCONTEXT($,$,3,$,#16,$);
		#25=IFCCOLOURRGB($,0.901961,0.901961,0.901961);
		#26=IFCSURFACESTYLERENDERING(#25,$,$,$,$,$,$,$,$);
		#27=IFCSURFACESTYLE('Silka Kalkzandsteen CS12',.BOTH.,(#26));
		#28=IFCPRESENTATIONSTYLEASSIGNMENT((#27));
		#29=IFCSTYLEDITEM($,(#28),$);
		
		#30=IFCSTYLEDREPRESENTATION(#17,'Style','Material',(#29));
		#31=IFCMATERIAL('Silka Kalkzandsteen CS12');
		#32=IFCMATERIALDEFINITIONREPRESENTATION($,$,(#30),#31);

		#31=IFCMATERIAL('Silka Kalkzandsteen CS12');
		class IfcMaterial < IfcBase
			# Attribute	  Type	            Defined By
			# Name	      IfcLabel (STRING)	IfcMaterial
			# Description IfcText           IfcMaterial   OPTIONAL 2x4
			# Category    IfcLabel          IfcMaterial   OPTIONAL 2x4
			def initialize(ifc_exporter, su_material)
				init_common(ifc_exporter)
				material_name = su_material.name
				
				IfcMaterialDefinitionRepresentation.new(ifc_exporter, self, su_material)
				
				# "local" IFC array
				@a_Attributes = Array.new
				@a_Attributes << "'" + material_name + "'"
			end
		end
		
		#32=IFCMATERIALDEFINITIONREPRESENTATION($,$,(#30),#31);
		class IfcMaterialDefinitionRepresentation < IfcBase
			# Attribute           Type	                              Defined By
			# Name                IfcLabel (STRING)	                  IfcProductRepresentation  OPTIONAL
			# Description         IfcText (STRING)	                  IfcProductRepresentation  OPTIONAL
			# Representations     LIST OF IfcRepresentation (ENTITY)	IfcProductRepresentation (IfcStyledRepresentation)
			# RepresentedMaterial	IfcMaterial (ENTITY)	              IfcMaterialDefinitionRepresentation
			def initialize(ifc_exporter, ifc_material, su_material)
				init_common(ifc_exporter)
				
				# "local" IFC array
				@a_Attributes = Array.new
				@a_Attributes << nil
				@a_Attributes << nil
				@a_Attributes << ifc_exporter.ifcList(IfcStyledRepresentation.new(ifc_exporter, su_material).record_nr)
				@a_Attributes << ifc_material.record_nr
			end
		end
		
		#30=IFCSTYLEDREPRESENTATION(#17,'Style','Material',(#29));
		class IfcStyledRepresentation < IfcBase
			# Attribute	                Type	Defined By
			# ContextOfItems	          IfcRepresentationContext (ENTITY)	    IfcRepresentation
			# RepresentationIdentifier	IfcLabel (STRING)	                    IfcRepresentation  OPTIONAL
			# RepresentationType	      IfcLabel (STRING)	                    IfcRepresentation  OPTIONAL
			# Items	                    SET OF IfcRepresentationItem (ENTITY)	IfcRepresentation
			def initialize(ifc_exporter, su_material)
				init_common(ifc_exporter)
				side = "POSITIVE"
				
				# "local" IFC array
				@a_Attributes = Array.new
				@a_Attributes << IfcRepresentationContext.new(ifc_exporter).record_nr
				@a_Attributes << nil
				@a_Attributes << nil
				@a_Attributes << ifc_exporter.ifcList(IfcSurfaceStyle.new(ifc_exporter, su_material, side).record_nr)
			end
		end
		
		class IfcRepresentationContext < IfcBase
			# Attribute	        Type	            Defined By
			# ContextIdentifier	IfcLabel (STRING)	IfcRepresentationContext  OPTIONAL
			# ContextType	      IfcLabel (STRING)	IfcRepresentationContext  OPTIONAL
			def initialize(ifc_exporter)
				init_common(ifc_exporter)

				# "local" IFC array
				@a_Attributes = Array.new
				@a_Attributes << nil
				@a_Attributes << nil
			end
		end
		
		# IFCMATERIALLAYER(#148,100.,.U.);
		class IfcMaterialLayer < IfcBase
			# Attribute	      Type	                          Defined By
			# Material	      IfcMaterial (ENTITY)	          IfcMaterialLayer
			# LayerThickness	IfcPositiveLengthMeasure (REAL)	IfcMaterialLayer
			# IsVentilated	  IfcLogical (LOGICAL)	          IfcMaterialLayer
			def initialize(ifc_exporter, material_name, layerThickness)
				@ifc_exporter = ifc_exporter
				@entityType = "IFCMATERIALLAYER"
				ifc_exporter.add(self)
				
				# "local" IFC array
				@a_Attributes = Array.new
				@a_Attributes << IfcMaterial.new(ifc_exporter, material_name).record_nr
				@a_Attributes << layerThickness.to_mm.to_f.to_s
				@a_Attributes << ".U."
			end
		end
		
		# IFCMATERIALLAYERSET((#136,#141,#146,#151),'01 Algemene BU wand iso');
		class IfcMaterialLayerSet < IfcBase
			# Attribute	      Type	                            Defined By
			# MaterialLayers	LIST OF IfcMaterialLayer (ENTITY)	IfcMaterialLayerSet
			# LayerSetName	  IfcLabel (STRING)	                IfcMaterialLayerSet
			def initialize(ifc_exporter, aMaterialLayers, sLayerSetName)
				@ifc_exporter = ifc_exporter
				@entityType = "IFCMATERIALLAYERSET"
				ifc_exporter.add(self)
				
				# "local" IFC array
				@a_Attributes = Array.new
				@a_Attributes << ifc_exporter.ifcList(aMaterialLayers)
				@a_Attributes << "'" + sLayerSetName + "'"
			end
		end

		# IFCMATERIALLAYERSETUSAGE(#153,.AXIS2.,.POSITIVE.,0.);
		class IfcMaterialLayerSetUsage < IfcBase
			# Attribute	              Type	                          Defined By
			# ForLayerSet	            IfcMaterialLayerSet (ENTITY)	  IfcMaterialLayerSetUsage
			# LayerSetDirection	      IfcLayerSetDirectionEnum (ENUM)	IfcMaterialLayerSetUsage
			# DirectionSense	        IfcDirectionSenseEnum (ENUM)	  IfcMaterialLayerSetUsage
			# OffsetFromReferenceLine	IfcLengthMeasure (REAL)	        IfcMaterialLayerSetUsage
			def initialize(ifc_exporter, ifcMaterialLayerSet)
				@ifc_exporter = ifc_exporter
				@entityType = "IFCMATERIALLAYERSETUSAGE"
				ifc_exporter.add(self)
				
				# "local" IFC array
				@a_Attributes = Array.new
				@a_Attributes << ifcMaterialLayerSet.record_nr
				@a_Attributes << ".AXIS2."
				@a_Attributes << ".POSITIVE."
				@a_Attributes << "0."
			end
		end
		
		# IFCRELASSOCIATESMATERIAL('3rezN6ZsexG8ShnqMhP$g5',#13,$,$,(#170),#155);
		class IfcRelAssociatesMaterial < IfcRoot
			# Attribute	        Type	                        Defined By
			# GlobalId	        IfcGloballyUniqueId (STRING)	IfcRoot
			# OwnerHistory	    IfcOwnerHistory (ENTITY)	    IfcRoot                   OPTIONAL
			# Name	            IfcLabel (STRING)	            IfcRoot                   OPTIONAL
			# Description	      IfcText (STRING)	            IfcRoot                   OPTIONAL
			# RelatedObjects	  SET OF IfcRoot (ENTITY)	      IfcRelAssociates
			# RelatingMaterial	IfcMaterialSelect (SELECT)	  IfcRelAssociatesMaterial
			def initialize(ifc_exporter, ifcMaterialSelect)
				init_common(ifc_exporter)
				@ifcMaterialSelect = ifcMaterialSelect
				@ifc_exporter = ifc_exporter
				@aRelatedObjects = Array.new
			end
			def fill()
				# "local" IFC array
				@a_Attributes = Array.new
				@a_Attributes << "'" + Brewsky::IFC::new_guid + "'"
				@a_Attributes << @ifc_exporter.ifcProject.ifcOwnerHistory.record_nr
				@a_Attributes << nil
				@a_Attributes << nil
				@a_Attributes << @ifc_exporter.ifcList(@aRelatedObjects)
				@a_Attributes << @ifcMaterialSelect.record_nr
			end
			def add(ifcEntity)
				@aRelatedObjects << ifcEntity
			end
		end
		
		#IFCCOLOURRGB($,0.76078431,0.61568627,0.54509804);
		class IfcColourRgb < IfcBase
			# Attribute	Type	                            Defined By
			# Red	      IfcNormalisedRatioMeasure (REAL)	IfcColourRgb
			# Green	    IfcNormalisedRatioMeasure (REAL)	IfcColourRgb
			# Blue	    IfcNormalisedRatioMeasure (REAL)	IfcColourRgb
			def initialize(ifc_exporter, material)
				@ifc_exporter = ifc_exporter
				@entityType = "IFCCOLOURRGB"
				@ifc_exporter.add(self)
				@material = material

				# "local" IFC array
				@a_Attributes = Array.new
				@a_Attributes << nil
				@a_Attributes << color(0)
				@a_Attributes << color(1)
				@a_Attributes << color(2)
			end
			def color(id)
				if @material.nil?
					return "1."
				else
					rgb = @material.color.to_a[id]
					return (rgb.to_f / 255.to_f).to_s
				end
			end
		end
		
		#IFCSURFACESTYLERENDERING(#246,0.,IFCNORMALISEDRATIOMEASURE(0.69),$,$,$,IFCNORMALISEDRATIOMEASURE(0.83),$,.NOTDEFINED.);
		class IfcSurfaceStyleShading < IfcBase
			# Attribute	                Type	                              Defined By
			# SurfaceColour	            IfcColourRgb (ENTITY)	              IfcSurfaceStyleShading
			def initialize(ifc_exporter, material)
				init_common(ifc_exporter)
				
				# "local" IFC array
				@a_Attributes = Array.new
				@a_Attributes << IfcColourRgb.new(ifc_exporter, material).record_nr
			end
		end
		
		#IFCSURFACESTYLERENDERING(#246,0.,IFCNORMALISEDRATIOMEASURE(0.69),$,$,$,IFCNORMALISEDRATIOMEASURE(0.83),$,.NOTDEFINED.);
		class IfcSurfaceStyleRendering < IfcSurfaceStyleShading
			# Attribute	                Type	                              Defined By
			# SurfaceColour	            IfcColourRgb (ENTITY)	              IfcSurfaceStyleShading
			# Transparency	            IfcNormalisedRatioMeasure (REAL)	  IfcSurfaceStyleRendering  OPTIONAL
			# DiffuseColour	            IfcColourOrFactor (SELECT)	        IfcSurfaceStyleRendering  OPTIONAL
			# TransmissionColour	      IfcColourOrFactor (SELECT)	        IfcSurfaceStyleRendering  OPTIONAL
			# DiffuseTransmissionColour	IfcColourOrFactor (SELECT)	        IfcSurfaceStyleRendering  OPTIONAL
			# ReflectionColour	        IfcColourOrFactor (SELECT)	        IfcSurfaceStyleRendering  OPTIONAL
			# SpecularColour	          IfcColourOrFactor (SELECT)	        IfcSurfaceStyleRendering  OPTIONAL
			# SpecularHighlight	        IfcSpecularHighlightSelect (SELECT)	IfcSurfaceStyleRendering  OPTIONAL
			# ReflectanceMethod	        IfcReflectanceMethodEnum (ENUM)	    IfcSurfaceStyleRendering
			
			def initialize(ifc_exporter, material)
				init_common(ifc_exporter)
				
				# "local" IFC array
				@a_Attributes = Array.new
				@a_Attributes << IfcColourRgb.new(ifc_exporter, material).record_nr
				@a_Attributes << "IFCNORMALISEDRATIOMEASURE(" + material.alpha.to_s + ")"
				@a_Attributes << nil
				@a_Attributes << nil
				@a_Attributes << nil
				@a_Attributes << nil
				@a_Attributes << nil
				@a_Attributes << nil
				@a_Attributes << ".NOTDEFINED."
			end
		end
		
		#IFCSURFACESTYLE('21 Buitenwand metselwerk',.BOTH.,(#247));
		class IfcSurfaceStyle < IfcBase
			# Attribute Type	                                        Defined By
			# Name	    IfcLabel (STRING)	                            IfcPresentationStyle
			# Side	    IfcSurfaceSide (ENUM)	                        IfcSurfaceStyle
			# Styles	  SET OF IfcSurfaceStyleElementSelect (SELECT)	IfcSurfaceStyle
			def initialize(ifc_exporter, material, side)
				@ifc_exporter = ifc_exporter
				@entityType = "IFCSURFACESTYLE"
				@ifc_exporter.add(self)
				aSurfaceStyleElementSelect = Array.new
				aSurfaceStyleElementSelect << IfcSurfaceStyleRendering.new(ifc_exporter, material).record_nr
				
				# "local" IFC array
				@a_Attributes = Array.new
				@a_Attributes << "'" + material_name(material) + "'"
				@a_Attributes << "." + side + "."
				@a_Attributes << ifc_exporter.ifcList(aSurfaceStyleElementSelect)
			end
			def material_name(material)
				material == nil ? "Default" : material.name
			end
		end
		
	#250= IFCPRESENTATIONSTYLEASSIGNMENT((#248));
		class IfcPresentationStyleAssignment < IfcBase
			# Attribute Type	                                      Defined By
			# Styles	  SET OF IfcPresentationStyleSelect (SELECT)	IfcPresentationStyleAssignment
			def initialize(ifc_exporter, material, side)
				@ifc_exporter = ifc_exporter
				@entityType = "IFCPRESENTATIONSTYLEASSIGNMENT"
				@ifc_exporter.add(self)
				aPresentationStyleSelect = Array.new
				aPresentationStyleSelect << IfcSurfaceStyle.new(ifc_exporter, material, side).record_nr
				
				# "local" IFC array
				@a_Attributes = Array.new
				@a_Attributes << ifc_exporter.ifcList(aPresentationStyleSelect)
			end
		end
		
		#IFCSTYLEDITEM(#231,(#250),$);
		class IfcStyledItem < IfcBase
			# Attribute Type	                                          Defined By
			# Item	    IfcRepresentationItem (ENTITY)	                IfcStyledItem
			# Styles	  SET OF IfcPresentationStyleAssignment (ENTITY)	IfcStyledItem
			# Name	    IfcLabel (STRING)                               IfcStyledItem OPTIONAL
			def initialize(ifc_exporter, entity, source)
				@ifc_exporter = ifc_exporter
				@entityType = "IFCSTYLEDITEM"
				@ifc_exporter.add(self)
				aPresentationStyles = Array.new
				aPresentationStyles << IfcPresentationStyleAssignment.new(ifc_exporter, source.material, "POSITIVE").record_nr
				aPresentationStyles << IfcPresentationStyleAssignment.new(ifc_exporter, source.back_material, "NEGATIVE").record_nr
				
				# "local" IFC array
				@a_Attributes = Array.new
				@a_Attributes << entity
				@a_Attributes << ifc_exporter.ifcList(aPresentationStyles)
				@a_Attributes << nil
			end
		end
		
	# kleur exporteren
	#231= IFCEXTRUDEDAREASOLID(#227,#228,#36,2960.);
	#246= IFCCOLOURRGB($,0.76078431,0.61568627,0.54509804);
	#247= IFCSURFACESTYLERENDERING(#246,0.,IFCNORMALISEDRATIOMEASURE(0.69),$,$,$,IFCNORMALISEDRATIOMEASURE(0.83),$,.NOTDEFINED.);
	#248= IFCSURFACESTYLE('21 Buitenwand metselwerk',.BOTH.,(#247));
	#250= IFCPRESENTATIONSTYLEASSIGNMENT((#248));
	#252= IFCSTYLEDITEM(#231,(#250),$);

	# materiaal omschrijving exporteren
	#136= IFCMATERIALLAYER(#123,100.,.U.);
	#138= IFCMATERIAL('410 Luchtspouw buiten');
	#141= IFCMATERIALLAYER(#138,40.,.U.);
	#143= IFCMATERIAL('400 Isolatie basis');
	#146= IFCMATERIALLAYER(#143,100.,.U.);
	#148= IFCMATERIAL('100 Leeg- Binnenblad');
	#151= IFCMATERIALLAYER(#148,100.,.U.);
	#153= IFCMATERIALLAYERSET((#136,#141,#146,#151),'01 Algemene BU wand iso');
	#155= IFCMATERIALLAYERSETUSAGE(#153,.AXIS2.,.POSITIVE.,0.);
	#244= IFCRELASSOCIATESMATERIAL('3rezN6ZsexG8ShnqMhP$g5',#13,$,$,(#170),#155);
	#170= IFCWALLSTANDARDCASE('0lJANQLbCEHPkU1Xq9w_bk',#13,'Wand-001',$,$,#167,#240,'2F4CA5DA-5653-0E45-9B-9E-061D09EBE96E');

		
#973 = IFCPRESENTATIONLAYERASSIGNMENT('Layer0', $, (#32,#974,#1026,#1078,#1218), $);
		#1388=IFCPRESENTATIONLAYERASSIGNMENT('A-AREAIDM',$,(#388,#456,#516,#602,#662,#722,#790),$);
		class IfcPresentationLayerAssignment < IfcBase
			# Attribute	        Type	                        	Defined By
			# Name							IfcLabel (STRING)								IfcPresentationLayerAssignment
			# Description				IfcText (STRING)								IfcPresentationLayerAssignment
			# AssignedItems			SET OF IfcLayeredItem (SELECT)	IfcPresentationLayerAssignment
			# Identifier				IfcIdentifier (STRING)					IfcPresentationLayerAssignment
			def initialize(ifc_exporter, su_entity)
				init_common(ifc_exporter)
				@ifc_exporter = ifc_exporter
				@su_entity = su_entity
				@aAssignedItems = Array.new
			end
			def fill()
				# "local" IFC array
				@a_Attributes = Array.new
				@a_Attributes << set_name(@su_entity, @entityTypeCc)
				@a_Attributes << set_description(@su_entity, @entityTypeCc)
				@a_Attributes << @ifc_exporter.ifcList(@aAssignedItems)
				@a_Attributes << nil
			end
			def add(ifcEntity)
				@aAssignedItems << ifcEntity.representation.record_nr
			end
		end
		
		# this could be the most basic element that has sub-elements in the bim-tools project library
		class IfcProduct < IfcObject
			#Attribute	      Type	                            Defined By
			#GlobalId	        IfcGloballyUniqueId (STRING)	    IfcRoot
			#OwnerHistory	    IfcOwnerHistory (ENTITY)	        IfcRoot
			#Name	            IfcLabel (STRING)	                IfcRoot #optional
			#Description	    IfcText (STRING)	                IfcRoot #optional
			#ObjectType	      IfcLabel (STRING)	                IfcObject
			#ObjectPlacement	IfcObjectPlacement (ENTITY)	      IfcProduct
			#Representation	  IfcProductRepresentation (ENTITY)	IfcProduct
			attr_accessor :objectPlacement, :representation
			def set_objectPlacement(entity=nil)
				
				#parent transformation
				transformation_parent = nil
				
				#entity transformation
				if entity.nil?
					transformation = nil
				else
					transformation = entity.transformation
				end
				
				return IfcLocalPlacement.new(@ifc_exporter, transformation_parent, transformation)
			end
			def set_ProductRepresentation(entity)
				aRepresentations = Array.new
				aBrep = Array.new
				aBrep << IfcFacetedBrep.new(@ifc_exporter, entity).record_nr
				@representation = IfcShapeRepresentation.new(@ifc_exporter, "'Body'", "'Brep'", aBrep)
				aRepresentations << @representation.record_nr
				return IfcProductDefinitionShape.new(@ifc_exporter, entity, aRepresentations)
			end
		end
		
	#18=IFCBUILDING('ABCDEFGHIJKLMNOPQ00002',#9,'Testgebouw ','Omschrijving',$,$,$,$,.ELEMENT.,$,$,$);
		class IfcBuilding < IfcProduct
			# Attribute	            Type	                            Defined By
			# GlobalId	            IfcGloballyUniqueId (STRING)	    IfcRoot
			# OwnerHistory	        IfcOwnerHistory (ENTITY)	        IfcRoot
			# Name	                IfcLabel (STRING)	                IfcRoot
			# Description	          IfcText (STRING)	                IfcRoot
			# ObjectType	          IfcLabel (STRING)	                IfcObject
			# ObjectPlacement	      IfcObjectPlacement (ENTITY)	      IfcProduct
			# Representation	      IfcProductRepresentation (ENTITY)	IfcProduct
			# LongName	            IfcLabel (STRING)	                IfcSpatialStructureElement
			# CompositionType	      IfcElementCompositionEnum (ENUM)	IfcSpatialStructureElement
			# ElevationOfRefHeight	IfcLengthMeasure (REAL)	          IfcBuilding
			# ElevationOfTerrain	  IfcLengthMeasure (REAL)	          IfcBuilding
			# BuildingAddress	      IfcPostalAddress (ENTITY)	        IfcBuilding
			def initialize(ifc_exporter)
				init_common(ifc_exporter)
				
				# TODO!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
				#41 = IFCRELAGGREGATES('2QTqyzvgj6qBjsx1U3rHkG', #2, 'BuildingContainer', 'BuildingContainer for BuildigStories', #29, (#35));
				
				# "local" IFC array
				@a_Attributes = Array.new
				@a_Attributes << set_globalId(@model, @entityTypeCc)
				@a_Attributes << @ifc_exporter.ifcProject.ifcOwnerHistory.record_nr #set_ownerHistory()
				@a_Attributes << set_name
				@a_Attributes << set_description
				@a_Attributes << nil
				@a_Attributes << nil# set_objectPlacement().record_nr
				@a_Attributes << nil
				@a_Attributes << nil
				@a_Attributes << ".ELEMENT."
				@a_Attributes << nil
				@a_Attributes << nil
				@a_Attributes << nil
			end
			def set_guid
				if @model.get_attribute("IfcBuilding", "GlobalId")
					return @model.get_attribute("IfcBuilding", "GlobalId")
				else
					guid = Brewsky::IFC::new_guid
					@model.set_attribute("IfcBuilding", "GlobalId", guid)
					return guid
				end
			end
			def set_name
				if @model.get_attribute("IfcBuilding", "Name")
					return @model.get_attribute("IfcBuilding", "Name")
				elsif @ifc_exporter.defaults.get("building_name")
					name = @ifc_exporter.defaults.get("building_name")
					@model.set_attribute("IfcBuilding", "Name", name)
					return name
				else
					return nil
				end
			end
			def set_description
				if @model.get_attribute("IfcBuilding", "Description")
					return @model.get_attribute("IfcBuilding", "Description")
				elsif @ifc_exporter.defaults.get("building_description")
					description = @ifc_exporter.defaults.get("building_description")
					@model.set_attribute("IfcBuilding", "Description", description)
					return description
				else
					return nil
				end
			end
		end
		
		#46 = IFCRELCONTAINEDINSPATIALSTRUCTURE('2Or2FBptr1gPkbt_$syMeu', #2, 'Default Building', 'Contents of Building Storey', (#47, #170), #37);
		class IfcRelContainedInSpatialStructure < IfcProduct
			# Attribute	        Type	                              Defined By
			# GlobalId	        IfcGloballyUniqueId (STRING)	      IfcRoot
			# OwnerHistory	    IfcOwnerHistory (ENTITY)	          IfcRoot
			# Name	            IfcLabel (STRING)	                  IfcRoot                           OPTIONAL
			# Description	      IfcText (STRING)	                  IfcRoot                           OPTIONAL
			# RelatedElements	  SET OF IfcProduct (ENTITY)	        IfcRelContainedInSpatialStructure
			# RelatingStructure	IfcSpatialStructureElement (ENTITY)	IfcRelContainedInSpatialStructure
			def initialize(ifc_exporter)
				@ifc_exporter = ifc_exporter
				@entityType = "IFCRELCONTAINEDINSPATIALSTRUCTURE"
				@ifc_exporter.add(self)
			end
			def fill()
				# "local" IFC array
				@a_Attributes = Array.new
				@a_Attributes << "'" + Brewsky::IFC::new_guid + "'"
				@a_Attributes << @ifc_exporter.ifcProject.ifcOwnerHistory.record_nr
				@a_Attributes << "'BuildingContainer'" # only correct for site!!!
				@a_Attributes << "'Contents of Building'" # only correct for site!!!
				@a_Attributes << @ifc_exporter.ifcList(@ifc_exporter.aContainedInBuilding)
				@a_Attributes << @ifc_exporter.ifcBuilding.record_nr
			end
		end
		
		class IfcRelVoidsElement < IfcRoot
		
			# Attribute	              Type	                                Defined By
			# GlobalId	              IfcGloballyUniqueId (STRING)	        IfcRoot
			# OwnerHistory	          IfcOwnerHistory (ENTITY)	            IfcRoot
			# Name	                  IfcLabel (STRING)	                    IfcRoot
			# Description	            IfcText (STRING)	                    IfcRoot
			# RelatingBuildingElement	IfcElement (ENTITY)	                  IfcRelVoidsElement
			# RelatedOpeningElement	  IfcFeatureElementSubtraction (ENTITY)	IfcRelVoidsElement
			attr_accessor :name, :description, :record_nr
			def initialize(ifc_exporter, ifcPlate, ifcOpeningElement)
				@ifc_exporter = ifc_exporter
				@entityType = "IFCRELVOIDSELEMENT"
				ifc_exporter.add(self)
				
				# "local" IFC array
				@a_Attributes = Array.new
				@a_Attributes << set_globalId()
				@a_Attributes << @ifc_exporter.ifcProject.ifcOwnerHistory.record_nr
				@a_Attributes << set_name #optional
				@a_Attributes << set_description #optional
				@a_Attributes << ifcPlate.record_nr
				@a_Attributes << ifcOpeningElement.record_nr
			end
			def set_name
				return nil
			end
			def set_description
				return nil
			end
		end
		
		# IFCPRODUCTDEFINITIONSHAPE($, $, (#79, #83));
		#20 = IFCGEOMETRICREPRESENTATIONCONTEXT = none, $
		#79 = IFCSHAPEREPRESENTATION(#20, 'Axis', 'Curve2D', (#80));
		#83 = IFCSHAPEREPRESENTATION(#20, 'Body', 'SweptSolid', (#84));
		#84 = IFCEXTRUDEDAREASOLID(#85, #92, #96, 2.300);
		#85 = IFCARBITRARYCLOSEDPROFILEDEF(.AREA., $, #86);
		#92 = IFCAXIS2PLACEMENT3D(#93, #94, #95);
		#96 = IFCDIRECTION((0., 0., 1.));
		class IfcProductDefinitionShape < IfcBase
			attr_accessor :name, :description, :record_nr, :representations
			def initialize(ifc_exporter, bt_entity, aRepresentations)
				@ifc_exporter = ifc_exporter
				@bt_entity = bt_entity
				@representations = aRepresentations
				@entityType = "IFCPRODUCTDEFINITIONSHAPE"
				ifc_exporter.add(self)
				
				# "local" IFC array
				@a_Attributes = Array.new
				@a_Attributes << nil #optional
				@a_Attributes << nil #optional
				@a_Attributes << set_representations #optional
			end
			def set_representations
				return @ifc_exporter.ifcList(@representations)
			end
		end
		
		class IfcShapeRepresentation < IfcBase
			# Attribute       Type                               Defined By
			# Name            IfcLabel (STRING)                  IfcProductRepresentation
			# Description     IfcText (STRING)                   IfcProductRepresentation
			# Representations LIST OF IfcRepresentation (ENTITY) IfcProductRepresentation
			attr_accessor :name, :description, :representations, :record_nr
			def initialize(ifc_exporter, name, description, aRepresentations)
				@ifc_exporter = ifc_exporter
				@name = name
				@description = description
				@representations = aRepresentations
				@entityType = "IFCSHAPEREPRESENTATION"
				ifc_exporter.add(self)
				
				# "local" IFC array
				@a_Attributes = Array.new
				@a_Attributes << @ifc_exporter.set_IfcGeometricRepresentationContext.record_nr
				@a_Attributes << @name #optional
				@a_Attributes << @description #optional
				@a_Attributes << set_representations #optional
			end
			def set_representations
				return @ifc_exporter.ifcList(@representations)
			end
		end
		
		# IFCSITE('" + site_id + "', " + id_s(2) + ", '" + site_name + "', '" + site_description + "', $, " + id_s(24) + ", $, $, .ELEMENT., (" + lat[0] + ", " + lat[1] + ", " + lat[2] + "), (" + long[0] + ", " + long[1] + ", " + long[2] + "), $, $, $);"
		
		#24 = IFCSITE('2ZjPp2Z9P6D8e7u9GDoxr4', #2, 'Default Site', 'Description of Default Site', $, #25, $, $, .ELEMENT., (24, 28, 0), (54, 25, 0), 10., $, $);
		#25 = IFCLOCALPLACEMENT($, #26);
		#26 = IFCAXIS2PLACEMENT3D(#27, #28, #29);
		#27 = IFCCARTESIANPOINT((0.E-1, 0.E-1, 0.E-1));
		#28 = IFCDIRECTION((0.E-1, 0.E-1, 1.));
		#29 = IFCDIRECTION((1., 0.E-1, 0.E-1));
		
		#43 = IFCRELAGGREGATES('1f_92NYQD0lBChEeKfihEz', #2, 'BuildingContainer', 'BuildingContainer for BuildigStories', #30, (#37));
		#44 = IFCRELAGGREGATES('03QlbDcwz3wAQb2KBzxujQ', #2, 'SiteContainer', 'SiteContainer For Buildings', #24, (#30));
		#45 = IFCRELAGGREGATES('07oQHvxvvFswj91PBXi3Mo', #2, 'ProjectContainer', 'ProjectContainer for Sites', #1, (#24));
		#46 = IFCRELCONTAINEDINSPATIALSTRUCTURE('2Or2FBptr1gPkbt_$syMeu', #2, 'Default Building', 'Contents of Building Storey', (#47, #170), #37);
		class IfcSite < IfcProduct
		# Attribute	      Type	                                    Defined By
		# GlobalId	      IfcGloballyUniqueId (STRING)	            IfcRoot
		# OwnerHistory	  IfcOwnerHistory (ENTITY)	                IfcRoot
		# Name	          IfcLabel (STRING)	                        IfcRoot                     OPTIONAL
		# Description	    IfcText (STRING)	                        IfcRoot                     OPTIONAL
		# ObjectType	    IfcLabel (STRING)	                        IfcObject                   OPTIONAL
		# ObjectPlacement	IfcObjectPlacement (ENTITY)	              IfcProduct                  OPTIONAL
		# Representation	IfcProductRepresentation (ENTITY)	        IfcProduct                  OPTIONAL
		# LongName	      IfcLabel (STRING)	                        IfcSpatialStructureElement  OPTIONAL
		# CompositionType	IfcElementCompositionEnum (ENUM)	        IfcSpatialStructureElement
		# RefLatitude	    IfcCompoundPlaneAngleMeasure (AGGREGATE)	IfcSite                     OPTIONAL
		# RefLongitude	  IfcCompoundPlaneAngleMeasure (AGGREGATE)	IfcSite                     OPTIONAL
		# RefElevation	  IfcLengthMeasure (REAL)	                  IfcSite                     OPTIONAL
		# LandTitleNumber	IfcLabel (STRING)	                        IfcSite                     OPTIONAL
		# SiteAddress	    IfcPostalAddress (ENTITY)	                IfcSite                     OPTIONAL
			def initialize(ifc_exporter)
				init_common(ifc_exporter)
				
				# placement of the site is on the origin, it does not have geometry yet
				site_placement = nil
				
				# set project location
				set_latlong
				
				# "local" IFC array
				@a_Attributes = Array.new
				@a_Attributes << set_globalId(@model, @entityTypeCc)
				@a_Attributes << @ifc_exporter.ifcProject.ifcOwnerHistory.record_nr #set_ownerHistory()
				@a_Attributes << set_name(@model, @entityTypeCc)
				@a_Attributes << set_description(@model, @entityTypeCc)
				@a_Attributes << nil
				@a_Attributes << set_objectPlacement(site_placement).record_nr
				@a_Attributes << nil
				@a_Attributes << nil
				@a_Attributes << ".ELEMENT."
				@a_Attributes << latitude
				@a_Attributes << longtitude
				@a_Attributes << elevation
				@a_Attributes << nil
				@a_Attributes << nil
				
			end
			
			def set_guid
				if @model.get_attribute("IfcSite", "GlobalId")
					return @model.get_attribute("IfcSite", "GlobalId")
				else
					guid = Brewsky::IFC::new_guid
					@model.set_attribute("IfcSite", "GlobalId", guid)
					return guid
				end
			end
			
			# get project location
			def set_latlong
				local_coordinates = [0,0,0]
				local_point = Geom::Point3d.new(local_coordinates)
				ll = Sketchup.active_model.point_to_latlong(local_point)
				@latlong = ll
			end
			def latitude
				lat = sprintf("%.4f", @latlong[0])
				lat = lat.split('.')
				latpart = lat[1].split(//)
				lat = [lat[0], latpart[0] + latpart[1], latpart[2] + latpart[3]]
				return @ifc_exporter.ifcList(lat)
			end
			def longtitude
				long = sprintf("%.4f", @latlong[1])
				long = long.split('.')
				longpart = long[1].split(//)
				long = [long[0], longpart[0] + longpart[1], longpart[2] + longpart[3]]
				return @ifc_exporter.ifcList(long)
			end
			def elevation
				return @ifc_exporter.ifcLengthMeasure(@latlong[2])
			end
		end
		
		class IfcElement < IfcProduct
			attr_accessor :tag
			def set_tag(entity)
				@tag = nil
			end
		end
		
		#97 = IFCOPENINGELEMENT('2LcE70iQb51PEZynawyvuT', #2, 'Opening Element xyz', 'Description of Opening', $, #98, #103, $);
		#98 = IFCLOCALPLACEMENT(#46, #99);
		#99 = IFCAXIS2PLACEMENT3D(#100, #101, #102);
		#100 = IFCCARTESIANPOINT((9.000E-1, 0., 2.500E-1));
		#101 = IFCDIRECTION((0., 0., 1.));
		#102 = IFCDIRECTION((1., 0., 0.));
		#103 = IFCPRODUCTDEFINITIONSHAPE($, $, (#110));
		#109 = IFCRELVOIDSELEMENT('3lR5koIT51Kwudkm5eIoTu', #2, $, $, #45, #97);
		#110 = IFCSHAPEREPRESENTATION(#20, 'Body', 'SweptSolid', (#111));
		#111 = IFCEXTRUDEDAREASOLID(#112, #119, #123, 1.400);
		#112 = IFCARBITRARYCLOSEDPROFILEDEF(.AREA., $, #113);
		#113 = IFCPOLYLINE((#114, #115, #116, #117, #118));
		#114 = IFCCARTESIANPOINT((0., 0.));
		#115 = IFCCARTESIANPOINT((0., 3.000E-1));
		#116 = IFCCARTESIANPOINT((7.500E-1, 3.000E-1));
		#117 = IFCCARTESIANPOINT((7.500E-1, 0.));
		#118 = IFCCARTESIANPOINT((0., 0.));
		#119 = IFCAXIS2PLACEMENT3D(#120, #121, #122);
		#120 = IFCCARTESIANPOINT((0., 0., 0.));
		#121 = IFCDIRECTION((0., 0., 1.));
		#122 = IFCDIRECTION((1., 0., 0.));
		#123 = IFCDIRECTION((0., 0., 1.));
		class IfcOpeningElement < IfcElement
			# Attribute	      Type	                            Defined By
			# GlobalId	      IfcGloballyUniqueId (STRING)	    IfcRoot
			# OwnerHistory	  IfcOwnerHistory (ENTITY)	        IfcRoot
			# Name	          IfcLabel (STRING)	                IfcRoot
			# Description	    IfcText (STRING)	                IfcRoot
			# ObjectType	    IfcLabel (STRING)	                IfcObject
			# ObjectPlacement	IfcObjectPlacement (ENTITY)	      IfcProduct
			# Representation	IfcProductRepresentation (ENTITY)	IfcProduct
			# Tag	            IfcIdentifier (STRING)	          IfcElement
			attr_accessor :name, :description, :record_nr
			def initialize(ifc_exporter, bt_entity, ifcPlate, opening)
				@ifc_exporter = ifc_exporter
				@bt_entity = bt_entity
				@opening = opening
				@entityType = "IFCOPENINGELEMENT"
				ifc_exporter.add(self)
				
				# link to the planar in which to cut the hole
				IfcRelVoidsElement.new(@ifc_exporter, ifcPlate, self)
				
				# "local" IFC array
				@a_Attributes = Array.new
				@a_Attributes << "'" + @ifc_exporter.project.new_guid + "'"#set_globalId(bt_entity)
				@a_Attributes << @ifc_exporter.ifcProject.ifcOwnerHistory.record_nr
				@a_Attributes << set_name #optional
				@a_Attributes << set_description #optional
				@a_Attributes << set_ObjectType
				@a_Attributes << set_objectPlacement(bt_entity).record_nr #optional
				@a_Attributes << set_ProductRepresentation.record_nr #optional
				@a_Attributes << set_Tag
			end
			def set_name
				return nil
			end
			def set_description
				return nil
			end
			def set_ObjectType
				return nil
			end
			def set_ProductRepresentation
				aRepresentations = Array.new
				aSweptSolid = Array.new
				aSweptSolid << IfcExtrudedAreaSolid.new(@ifc_exporter, @bt_entity, @opening).record_nr
				aRepresentations << IfcShapeRepresentation.new(@ifc_exporter, "'Body'", "'SweptSolid'", aSweptSolid).record_nr
				return IfcProductDefinitionShape.new(@ifc_exporter, @bt_entity, aRepresentations)
			end
			def set_Tag
				return nil
			end
		end
		
		class IfcBuildingElement < IfcElement
			#Attribute	      Type	                            Defined By
			#GlobalId	        IfcGloballyUniqueId (STRING)	    IfcRoot
			#OwnerHistory	    IfcOwnerHistory (ENTITY)	        IfcRoot
			#Name	            IfcLabel (STRING)	                IfcRoot (OPTIONAL)
			#Description	    IfcText (STRING)	                IfcRoot (OPTIONAL)
			#ObjectType	      IfcLabel (STRING)	                IfcObject (OPTIONAL)
			#ObjectPlacement	IfcObjectPlacement (ENTITY)	      IfcProduct (OPTIONAL)
			#Representation	  IfcProductRepresentation (ENTITY)	IfcProduct (OPTIONAL)
			#Tag	            IfcIdentifier (STRING)	          IfcElement (OPTIONAL)
			def set_Tag
				return nil
			end
		end
		
		#335= IFCBUILDINGELEMENTPROXY('klqTK3FMXbp3CxV_vgB$sh',#1,'DAKLIGGER','120/400',$,#328,#331,'201:100071:1357846514-100130',$);
		class IfcBuildingElementProxy < IfcBuildingElement
			#Attribute	      Type	                            Defined By
			#GlobalId	        IfcGloballyUniqueId (STRING)	    IfcRoot
			#OwnerHistory	    IfcOwnerHistory (ENTITY)	        IfcRoot
			#Name	            IfcLabel (STRING)	                IfcRoot (OPTIONAL)
			#Description	    IfcText (STRING)	                IfcRoot (OPTIONAL)
			#ObjectType	      IfcLabel (STRING)	                IfcObject (OPTIONAL)
			#ObjectPlacement	IfcObjectPlacement (ENTITY)	      IfcProduct (OPTIONAL)
			#Representation	  IfcProductRepresentation (ENTITY)	IfcProduct (OPTIONAL)
			#Tag	            IfcIdentifier (STRING)	          IfcElement (OPTIONAL)
			#CompositionType	IfcElementCompositionEnum (ENUM)	IfcBuildingElementProxy (OPTIONAL)
			def initialize(ifc_exporter, entity)
				init_common(ifc_exporter)

				# "local" IFC array
				@a_Attributes = Array.new
				@a_Attributes << set_globalId(entity, @entityTypeCc)
				@a_Attributes << @ifc_exporter.ifcProject.ifcOwnerHistory.record_nr
				@a_Attributes << set_name(entity, @entityTypeCc, true)
				@a_Attributes << set_description(entity, @entityTypeCc)
				@a_Attributes << set_ObjectType
				@a_Attributes << set_objectPlacement(entity).record_nr
				@a_Attributes << set_ProductRepresentation(entity).record_nr
				@a_Attributes << set_Tag
				@a_Attributes << set_CompositionType
				
				#add self to the list of entities contained in the building
				@ifc_exporter.add_to_building(self)
			end
			def set_CompositionType
				return nil
			end
		end

		class IfcWall < IfcBuildingElement
			#Attribute	      Type	                            Defined By
			#GlobalId	        IfcGloballyUniqueId (STRING)	    IfcRoot
			#OwnerHistory	    IfcOwnerHistory (ENTITY)	        IfcRoot
			#Name	            IfcLabel (STRING)	                IfcRoot (OPTIONAL)
			#Description	    IfcText (STRING)	                IfcRoot (OPTIONAL)
			#ObjectType	      IfcLabel (STRING)	                IfcObject (OPTIONAL)
			#ObjectPlacement	IfcObjectPlacement (ENTITY)	      IfcProduct (OPTIONAL)
			#Representation	  IfcProductRepresentation (ENTITY)	IfcProduct (OPTIONAL)
			#Tag	            IfcIdentifier (STRING)	          IfcElement (OPTIONAL)
			def initialize(ifc_exporter, entity)
				init_common(ifc_exporter)

				# "local" IFC array
				@a_Attributes = Array.new
				@a_Attributes << set_globalId(entity, @entityTypeCc)
				@a_Attributes << @ifc_exporter.ifcProject.ifcOwnerHistory.record_nr
				@a_Attributes << set_name(entity, @entityTypeCc, true)
				@a_Attributes << set_description(entity, @entityTypeCc)
				@a_Attributes << set_ObjectType
				@a_Attributes << set_objectPlacement(entity).record_nr
				@a_Attributes << set_ProductRepresentation(entity).record_nr
				@a_Attributes << set_Tag
				
				#add self to the list of entities contained in the building
				@ifc_exporter.add_to_building(self)
			end
		end

		class IfcSlab < IfcBuildingElement
			#Attribute	      Type	                            Defined By
			#GlobalId	        IfcGloballyUniqueId (STRING)	    IfcRoot
			#OwnerHistory	    IfcOwnerHistory (ENTITY)	        IfcRoot
			#Name	            IfcLabel (STRING)	                IfcRoot (OPTIONAL)
			#Description	    IfcText (STRING)	                IfcRoot (OPTIONAL)
			#ObjectType	      IfcLabel (STRING)	                IfcObject (OPTIONAL)
			#ObjectPlacement	IfcObjectPlacement (ENTITY)	      IfcProduct (OPTIONAL)
			#Representation	  IfcProductRepresentation (ENTITY)	IfcProduct (OPTIONAL)
			#Tag	            IfcIdentifier (STRING)	          IfcElement (OPTIONAL)
			#PredefinedType		IfcSlabTypeEnum (ENUM)						IfcSlab (OPTIONAL)
			def initialize(ifc_exporter, entity)
				init_common(ifc_exporter)

				# "local" IFC array
				@a_Attributes = Array.new
				@a_Attributes << set_globalId(entity, @entityTypeCc)
				@a_Attributes << @ifc_exporter.ifcProject.ifcOwnerHistory.record_nr
				@a_Attributes << set_name(entity, @entityTypeCc, true)
				@a_Attributes << set_description(entity, @entityTypeCc)
				@a_Attributes << set_ObjectType
				@a_Attributes << set_objectPlacement(entity).record_nr
				@a_Attributes << set_ProductRepresentation(entity).record_nr
				@a_Attributes << set_Tag
				@a_Attributes << set_PredefinedType
				
				#add self to the list of entities contained in the building
				@ifc_exporter.add_to_building(self)
			end
			def set_PredefinedType
				return nil
			end
		end

		class IfcBeam < IfcBuildingElement
			#Attribute	      Type	                            Defined By
			#GlobalId	        IfcGloballyUniqueId (STRING)	    IfcRoot
			#OwnerHistory	    IfcOwnerHistory (ENTITY)	        IfcRoot
			#Name	            IfcLabel (STRING)	                IfcRoot (OPTIONAL)
			#Description	    IfcText (STRING)	                IfcRoot (OPTIONAL)
			#ObjectType	      IfcLabel (STRING)	                IfcObject (OPTIONAL)
			#ObjectPlacement	IfcObjectPlacement (ENTITY)	      IfcProduct (OPTIONAL)
			#Representation	  IfcProductRepresentation (ENTITY)	IfcProduct (OPTIONAL)
			#Tag	            IfcIdentifier (STRING)	          IfcElement (OPTIONAL)
			def initialize(ifc_exporter, entity)
				init_common(ifc_exporter)

				# "local" IFC array
				@a_Attributes = Array.new
				@a_Attributes << set_globalId(entity, @entityTypeCc)
				@a_Attributes << @ifc_exporter.ifcProject.ifcOwnerHistory.record_nr
				@a_Attributes << set_name(entity, @entityTypeCc, true)
				@a_Attributes << set_description(entity, @entityTypeCc)
				@a_Attributes << set_ObjectType
				@a_Attributes << set_objectPlacement(entity).record_nr
				@a_Attributes << set_ProductRepresentation(entity).record_nr
				@a_Attributes << set_Tag
				
				#add self to the list of entities contained in the building
				@ifc_exporter.add_to_building(self)
			end
		end

		class IfcColumn < IfcBuildingElement
			#Attribute	      Type	                            Defined By
			#GlobalId	        IfcGloballyUniqueId (STRING)	    IfcRoot
			#OwnerHistory	    IfcOwnerHistory (ENTITY)	        IfcRoot
			#Name	            IfcLabel (STRING)	                IfcRoot (OPTIONAL)
			#Description	    IfcText (STRING)	                IfcRoot (OPTIONAL)
			#ObjectType	      IfcLabel (STRING)	                IfcObject (OPTIONAL)
			#ObjectPlacement	IfcObjectPlacement (ENTITY)	      IfcProduct (OPTIONAL)
			#Representation	  IfcProductRepresentation (ENTITY)	IfcProduct (OPTIONAL)
			#Tag	            IfcIdentifier (STRING)	          IfcElement (OPTIONAL)
			def initialize(ifc_exporter, entity)
				init_common(ifc_exporter)

				# "local" IFC array
				@a_Attributes = Array.new
				@a_Attributes << set_globalId(entity, @entityTypeCc)
				@a_Attributes << @ifc_exporter.ifcProject.ifcOwnerHistory.record_nr
				@a_Attributes << set_name(entity, @entityTypeCc, true)
				@a_Attributes << set_description(entity, @entityTypeCc)
				@a_Attributes << set_ObjectType
				@a_Attributes << set_objectPlacement(entity).record_nr
				@a_Attributes << set_ProductRepresentation(entity).record_nr
				@a_Attributes << set_Tag
				
				#add self to the list of entities contained in the building
				@ifc_exporter.add_to_building(self)
			end
		end
		
		class IfcPlate < IfcBuildingElement
			def initialize(project, ifc_exporter, planar)
				@project = project
				@ifc_exporter = ifc_exporter
				@planar = planar
				@entityType = "IFCPLATE"
				@ifc_exporter.add(self)
				
				# "local" IFC array
				@a_Attributes = Array.new
				@a_Attributes << set_globalId(planar)
				@a_Attributes << @ifc_exporter.ifcProject.ifcOwnerHistory.record_nr #set_ownerHistory()
				@a_Attributes << set_name(planar) #optional
				@a_Attributes << set_description(planar) #optional
				@a_Attributes << set_objectType("Planar") #optional
				@a_Attributes << set_objectPlacement(planar).record_nr #optional
				@a_Attributes << set_representations.record_nr #optional
				@a_Attributes << set_tag(planar) #optional
				
				# define openings
				openings
				
				#add self to the list of entities contained in the building
				@ifc_exporter.add_to_building(self)
			end
			def set_representations
				# Ifcplate has 2 or more representations, 
				# SweptSolid Representation(1)
				# Clipping Representation
				# MappedRepresentation(2)
				aRepresentations = Array.new
				aSweptSolid = Array.new
				#83 = IFCSHAPEREPRESENTATION(#20, 'Body', 'SweptSolid', (#84));
				loop = @planar.source.outer_loop
				
				@points = Array.new
				loop.vertices.each do |vert|
					t = @planar.geometry.transformation.inverse
					p = vert.position.transform! t
					@points << p
				end
				
				aSweptSolid << IfcExtrudedAreaSolid.new(@ifc_exporter, @planar, @points).record_nr
				aRepresentations << IfcShapeRepresentation.new(@ifc_exporter, "'Body'", "'SweptSolid'", aSweptSolid).record_nr # SweptSolid Representation
				#a_representations << IfcShapeRepresentation.new(@ifc_exporter, 'Body', 'MappedRepresentation', aRepresentations).record_nr # Mapped Representation
				return IfcProductDefinitionShape.new(@ifc_exporter, @planar, aRepresentations)
			end
			def openings
			
				# get all opening-loops from planar
				#aOpenings = @planar.get_openings
				#aOpenings[0].each do |opening|
				@planar.openings.each do |opening|
					IfcOpeningElement.new(@ifc_exporter, @planar, self, opening)
				end
				# delete temporary group
				#aOpenings[1].erase!
			end
		end
		
		#copy from ifcplate, needs cleaning up
		
		#class IfcWall < IfcPlate #officially not correct!!! IfcBuildingElement
			#attr_accessor :record_nr
			#def initialize(project, ifc_exporter, planar)
				#@project = project
				#@ifc_exporter = ifc_exporter
				#@planar = planar
				#@entityType = "IFCWALL"
				#@ifc_exporter.add(self)
				
				## "local" IFC array
				#@a_Attributes = Array.new
				#@a_Attributes << set_globalId(planar)
				#@a_Attributes << @ifc_exporter.ifcProject.ifcOwnerHistory.record_nr #set_ownerHistory()
				#@a_Attributes << set_name(planar) #optional
				#@a_Attributes << set_description(planar) #optional
				#@a_Attributes << set_objectType("Planar") #optional
				#@a_Attributes << set_objectPlacement(planar).record_nr #optional
				#@a_Attributes << set_representations.record_nr #optional
				#@a_Attributes << set_tag(planar) #optional
				
				## define openings
				#openings
				
				#set_BaseQuantities
				
				##add self to the list of entities contained in the building
				#@ifc_exporter.add_to_building(self)
			#end
			#def set_BaseQuantities
				#aRelatedObjects = [self.record_nr]
				#IfcRelDefinesByProperties.new(@ifc_exporter, @planar, aRelatedObjects)
			#end
		#end
		
		##copy from ifcplate, needs cleaning up
		#class IfcSlab < IfcPlate
		## Attribute	      Type	                            Defined By
		## GlobalId	      IfcGloballyUniqueId (STRING)	    IfcRoot
		## OwnerHistory	  IfcOwnerHistory (ENTITY)	        IfcRoot
		## Name	          IfcLabel (STRING)	                IfcRoot
		## Description	    IfcText (STRING)	                IfcRoot
		## ObjectType	    IfcLabel (STRING)	                IfcObject
		## ObjectPlacement	IfcObjectPlacement (ENTITY)	      IfcProduct
		## Representation	IfcProductRepresentation (ENTITY)	IfcProduct
		## Tag	            IfcIdentifier (STRING)	          IfcElement
		## PredefinedType	IfcSlabTypeEnum (ENUM)	          IfcSlab
			#def initialize(project, ifc_exporter, planar)
				#@project = project
				#@ifc_exporter = ifc_exporter
				#@planar = planar
				#@entityType = "IFCSLAB"
				#@ifc_exporter.add(self)
				
				## "local" IFC array
				#@a_Attributes = Array.new
				#@a_Attributes << set_globalId(planar)
				#@a_Attributes << @ifc_exporter.ifcProject.ifcOwnerHistory.record_nr #set_ownerHistory()
				#@a_Attributes << set_name(planar) #optional
				#@a_Attributes << set_description(planar) #optional
				#@a_Attributes << set_objectType("Planar") #optional
				#@a_Attributes << set_objectPlacement(planar).record_nr #optional
				#@a_Attributes << set_representations.record_nr #optional
				#@a_Attributes << set_tag(planar) #optional
				#@a_Attributes << ifcSlabTypeEnum(planar) #optional
				
				## define openings
				#openings
				
				##add self to the list of entities contained in the building
				#@ifc_exporter.add_to_building(self)
			#end
			#def ifcSlabTypeEnum(planar)
				## Return options: FLOOR, ROOF, LANDING, BASESLAB, USERDEFINED, NOTDEFINED
				#if planar.element_type == "Floor"
					#return ".FLOOR."
				#elsif planar.element_type == "Roof"
					#return ".ROOF."
				#else
					#return ".NOTDEFINED."
				#end
			#end
		#end
		
		#copy from IfcWall, needs cleaning up
		class IfcWallStandardCase < IfcPlate #officially not correct!!!
			# Attribute	      Type	                            Defined By
			# GlobalId	      IfcGloballyUniqueId (STRING)	    IfcRoot
			# OwnerHistory	  IfcOwnerHistory (ENTITY)	        IfcRoot
			# Name	          IfcLabel (STRING)	                IfcRoot     OPTIONAL
			# Description	    IfcText (STRING)	                IfcRoot     OPTIONAL
			# ObjectType	    IfcLabel (STRING)	                IfcObject   OPTIONAL
			# ObjectPlacement	IfcObjectPlacement (ENTITY)	      IfcProduct  OPTIONAL
			# Representation	IfcProductRepresentation (ENTITY)	IfcProduct  OPTIONAL
			# Tag           	IfcIdentifier (STRING)	          IfcElement  OPTIONAL
			attr_accessor :record_nr
			def initialize(project, ifc_exporter, planar)
				@project = project
				@ifc_exporter = ifc_exporter
				@planar = planar
				@entityType = "IFCWALLSTANDARDCASE"
				@ifc_exporter.add(self)
		
				# "local" IFC array
				@a_Attributes = Array.new
				@a_Attributes << set_globalId(planar)
				@a_Attributes << @ifc_exporter.ifcProject.ifcOwnerHistory.record_nr
				@a_Attributes << set_name(planar)
				@a_Attributes << set_description(planar)
				@a_Attributes << set_objectType("Planar")
				@a_Attributes << set_objectPlacement(planar).record_nr
				@a_Attributes << set_representations.record_nr
				@a_Attributes << set_tag(planar)
				
				# define openings
				openings
				
				set_BaseQuantities
				set_materials
				
				#add self to the list of entities contained in the building
				@ifc_exporter.add_to_building(self)
			end
			def set_materials
				if @planar.source.material.nil?
					material_name = "Default"
				else
					material_name = @planar.source.material.name
				end
				layerThickness = @planar.width
				aMaterialLayers = Array.new
				aMaterialLayers << IfcMaterialLayer.new(@ifc_exporter, material_name, layerThickness).record_nr
				sLayerSetName = layerThickness.to_s + " " + material_name
				materialLayerSet = IfcMaterialLayerSet.new(@ifc_exporter, aMaterialLayers, sLayerSetName)
				materialLayerSetUsage = IfcMaterialLayerSetUsage.new(@ifc_exporter, materialLayerSet)
				aRelatedObjects = Array.new
				aRelatedObjects << self.record_nr
				IfcRelAssociatesMaterial.new(@ifc_exporter, aRelatedObjects, materialLayerSetUsage)
			end
			def set_objectPlacement(bt_entity)
				
				#parent transformation
				transformation_parent = nil
				
				#entity transformation, rotated for IfcWallStandardCase
				if bt_entity.nil?
					transformation = nil
				else
					# hij moet draaien om de interne as van de group en niet om die van de oorsprong!!!!!!!!!!!!!!
					t_bt_entity = bt_entity.geometry.transformation
					#xaxis = t_bt_entity.xaxis
					#yaxis = t_bt_entity.zaxis.reverse
					#origin = t_bt_entity.origin
					#transformation = Geom::Transformation.new(origin, xaxis, yaxis)
					point = Geom::Point3d.new(0, 0, 0)
					vector = Geom::Vector3d.new(1, 0, 0)
					angle = Math::PI / -2
					rotation = Geom::Transformation.rotation(point, vector, angle)
					transformation = t_bt_entity * rotation
				end
				return IfcLocalPlacement.new(@ifc_exporter, transformation_parent, transformation)
			end
			def set_representations
				aRepresentations = Array.new
				aCurve2d = Array.new
				aPath = Array.new
				aPath << Geom::Point3d.new(0,0,0)
				aPath << Geom::Point3d.new(@planar.length?,0,0)
				aSweptSolid = Array.new
				projection = get_projection(@planar)
				loop = projection
				aCurve2d << IfcPolyline.new(@ifc_exporter, @planar, aPath, false).record_nr
				aSweptSolid << WscIfcExtrudedAreaSolid.new(@ifc_exporter, @planar, loop, @planar.height?).record_nr
	#201= IFCSHAPEREPRESENTATION(#51,'Axis','Curve2D',(#197));
				aRepresentations << IfcShapeRepresentation.new(@ifc_exporter, "'Axis'", "'Curve2D'", aCurve2d).record_nr # SweptSolid Representation
				aRepresentations << IfcShapeRepresentation.new(@ifc_exporter, "'Body'", "'SweptSolid'", aSweptSolid).record_nr # SweptSolid Representation
				#group.erase!
				#aRepresentations.each do|representation|
					IfcStyledItem.new(@ifc_exporter, aCurve2d[0], @planar.source)
					IfcStyledItem.new(@ifc_exporter, aSweptSolid[0], @planar.source)
				#end
				return IfcProductDefinitionShape.new(@ifc_exporter, @planar, aRepresentations)
			end
			
			# returns the loop (and group) of the vertical projection of the wall
			# Make sure you delete the temporary group afterwards
			# based on clsPlanarElement.get_openings
			def get_projection(bt_entity)
				@geometry = bt_entity.geometry
				loop = nil
				group = @geometry.entities.add_group
				
					point = Geom::Point3d.new(0, 0, 0)
					vector = Geom::Vector3d.new(1, 0, 0)
					angle = Math::PI / -2
					rotation = Geom::Transformation.rotation(point, vector, angle)
					group.transform! rotation
				
				#transform =  group.transformation.invert! * instance.transformation
			
				# copy all geometry edges to the new group
				@geometry.entities.each do |entity|
					if entity.is_a?(Sketchup::Edge)
						new_start = entity.start.position.transform rotation.inverse
						new_start.z= 0
						new_end = entity.end.position.transform rotation.inverse
						new_end.z= 0
						group.entities.add_edges new_start, new_end
					end
				end
				
				# intersect all edges
				faces=[]
				group.entities.each do |entity|
					faces << entity
				end
				group.entities.intersect_with false, group.transformation, group.entities, group.transformation, true, faces
				
				# create all possible faces
				group.entities.each do |entity|
					if entity.is_a?(Sketchup::Edge)
						entity.find_faces
					end
				end
				
				# delete unneccesary edges
				group.entities.each do |entity|
					if entity.is_a?(Sketchup::Edge)
						if entity.faces.length != 1
							entity.erase!
						end
					end
				end
				
				#find all outer loops of the cutting component
				group.entities.each do |entity|
					if entity.is_a?(Sketchup::Face)
						loop = entity.outer_loop
					end
				end
				points = Array.new
				loop.vertices.each do |vert|
					points << vert.position
				end
				group.erase!
				return points
			end
		end
		
	end # module IfcExport
end # module Brewsky
