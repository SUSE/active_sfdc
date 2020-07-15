module ActiveSfdc
  module ProjectionNormalization
  	# If no fieldlist has been specified, relay #to projection_fields
    def build_select(arel)
      if select_values.any?
        arel.project(*arel_columns(select_values.uniq))
      else
        arel.project(*arel_columns(@klass._projection_fields.keys))
      end
    end
  end
end