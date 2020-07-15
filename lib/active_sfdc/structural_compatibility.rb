module ActiveSfdc
  module StructuralCompatibility
  	# SFDC objects don't need this check
    def structurally_incompatible_values_for_or(_)
      []
    end
  end
end