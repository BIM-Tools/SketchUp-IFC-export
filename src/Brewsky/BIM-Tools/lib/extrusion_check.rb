# extrusion_check.rb
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
  module IFC

		# function to figure out if both values are almost equal
		def self.approx(val, other, relative_epsilon=Float::EPSILON, epsilon=Float::EPSILON)
			difference = other - val
			return true if difference.abs <= epsilon
			relative_error = (difference / (val > other ? val : other)).abs
			return relative_error <= relative_epsilon
		end

		# function to figure out if a group or component is an extrusion profile
		# input: Sketchup::Group or Sketchup::ComponentInstance
		# output:
		#  - if extrusion: an Array containing the bottom face and the edge of the extrusion
		#  - if no extrusion: false
		def self.extrusion?(entity)
			aCaps = Array.new
			if entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)
				if entity.manifold?
				
					# if the entity is a component instance: use the definition instead
					if entity.is_a?(Sketchup::ComponentInstance)
						entity = entity.definition
					end
					
					# collect all faces from the object
					aFaces = Array.new
					entity.entities.each do |ent|
						if ent.is_a? Sketchup::Face
							aFaces << ent
						end
					end
					
					# an extruded profile has at least 5 faces
					if aFaces.length >= 5
						aParallels = Array.new
						aSides = Array.new

						# create a big array combining all faces with each other for comparison
						# improved in ruby 1.8.7 and later...
						# aFaces.combination(2).to_a.each do |faces|
						combination = (0...(aFaces.size-1)).inject([]) {|pairs,x| pairs += ((x+1)...aFaces.size).map {|y| [aFaces[x],aFaces[y]]}}
						combination.each do |faces|
							
							# if 2 faces have the same size and are parallel, they could be the extrusions caps
							if approx(faces[0].area, faces[1].area, 0.000000001) and faces[0].normal.parallel? faces[1].normal
								aParallels << faces
							end
							
							# all faces that are not part of aParallels must have 4 edges
							aFaces.each do |face|
								side = true
								aParallels.each do |aSet|
									if face == aSet[0] || face == aSet[1]
										side = false
										break
									end
								end
								if side == true
									if face.edges.length == 4
										aSides << face
									else
										#return false # NO EXTRUSION!!!
									end
								end
							end
						end
						
						if aParallels.length == 1
							aCaps = aParallels[0] # this one set contains the caps!
							
						# if multiple sets of parallel faces exist, figure out which would be a possible set of caps
						elsif aParallels.length > 1
							four_edges = Array.new
							aParallels.each do |aSet|
								if aSet[0].edges.length == 4
									four_edges << aSet
								end
							end
							
							if aParallels.length - four_edges.length == 1
								intersection = aParallels - four_edges # this one intersecting set contains the caps!
								aCaps = intersection[0]
							
							# if all faces have 4 edges then figure out of one set is parallel to the xy-plane and set this as the caps set
							elsif aParallels.length == four_edges.length
								aParallels.each do |aSet|
									if aSet[0].normal.z == 1
										aCaps = aSet # this set contains the caps!
										break
									end
								end
							end
						else
							return false # NO EXTRUSION!!!
						end
						
						if aCaps[0].is_a? Sketchup::Face
							unless aCaps[0].edges.length + 2 == aFaces.length
								aCaps = false # NO EXTRUSION!!!
							end
						else
							aCaps = false
						end
						
						if aCaps == false
							return false
						else
							
							# find extrusion-vector
							edgeuse = aCaps[0].outer_loop.edgeuses[0]
							vert = nil
							if edgeuse.reversed?
								vert = edgeuse.edge.end
							else
								vert = edgeuse.edge.start
							end
							ext_edge = nil
							vert.edges.each do |edge|
								if edge.line[1].parallel? aCaps[0].normal # this will not work with non-vertical extrusions
									ext_edge = edge
									break
								end
							end
							
							# find bottom-face
							ext_face = nil # bottom face
							if ext_edge.line[1].samedirection? aCaps[0].normal
								ext_face = aCaps[1]
							else
								ext_face = aCaps[0]
							end
							
							# return array with bottom face and extrusion edge
							return [ext_face, ext_edge]
						end
					end
				else
					return false
				end
			end
		end
  end # module IFC
end # module Brewsky
