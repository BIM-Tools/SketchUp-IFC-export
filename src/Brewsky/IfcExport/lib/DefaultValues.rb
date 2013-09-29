#       DefaultValues.rb
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
		class DefaultValues
			def initialize
				@h_defaults = Hash.new
							
				# open the file
				f = File.open(File.join(PLUGIN_PATH, 'bim-tools.cfg'), 'r')
		
				# loop through each record in the file, adding each record to our array.
				f.each_line { |line|
					
					# parse line unless the first character == # or the line is empty
					unless line[0] == 35 || line.length == 1
						a_Value = line.split('=')
						key = a_Value[0].strip
						value = a_Value[1].strip
						@h_defaults[key] = value
					end
				}
			end
			
			# call this function to get a default value for "key", if does not exist it returns nil
			def get(key)
				if @h_defaults[key]
					return @h_defaults[key]
				else
					return nil
				end
			end
		end
	end # module IfcExport
end # module Brewsky
