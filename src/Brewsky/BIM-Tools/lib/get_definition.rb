# Thanks to ThomThom for this method!
# source: http://www.thomthom.net/thoughts/2012/02/definitions-and-instances-in-sketchup/

# Returns the definition for a +Group+, +ComponentInstance+ or +Image+
#
# @param [Sketchup::ComponentInstance, Sketchup::Group, Sketchup::Image] instance
#
# @return [Sketchup::ComponentDefinition]

module Brewsky
	module IFC
		def self.definition(instance)
			if instance.is_a?(Sketchup::ComponentInstance)
				return instance.definition
			elsif instance.is_a?(Sketchup::Group)
				# (i) group.entities.parent should return the definition of a group.
				# But because of a SketchUp bug we must verify that group.entities.parent
				# returns the correct definition. If the returned definition doesn't
				# include our group instance then we must search through all the
				# definitions to locate it.
				if instance.entities.parent.instances.include?(instance)
					return instance.entities.parent
				else
					Sketchup.active_model.definitions.each { |definition|
						return definition if definition.instances.include?(instance)
					}
				end
			elsif instance.is_a?(Sketchup::Image)
				Sketchup.active_model.definitions.each { |definition|
					if definition.image? && definition.instances.include?(instance)
						return definition
					end
				}
			end
			return nil
		end
	end # module IFC
end # module Brewsky

