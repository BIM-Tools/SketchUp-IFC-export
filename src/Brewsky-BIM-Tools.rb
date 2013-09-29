# Brewsky-BIM-Tools.rb
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

# Show the Ruby Console at startup so we can
# see any programming errors we may make.

require 'sketchup.rb'
require 'extensions.rb'

module Brewsky

	PLUGIN_ROOT_PATH  = File.dirname(__FILE__)
	AUTHOR_PATH       = File.join(PLUGIN_ROOT_PATH, 'Brewsky')
	PLUGIN_PATH       = File.join(AUTHOR_PATH, 'BIM-Tools')

	extension = SketchupExtension.new(
		'BIM-Tools',
		File.join(PLUGIN_PATH, 'loader.rb')
	)
	
	extension.description = 'BIM-Tools common.'
	extension.version = '1.0.0'
	extension.copyright = '2013 Jan Brouwer'
	extension.creator = 'Jan Brouwer'
			
	Sketchup.register_extension(extension, true)

end # module Brewsky
