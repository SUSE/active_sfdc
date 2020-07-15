module ActiveSfdc
	# Custom arel table to pass down non-qualified identifiers by default
  class ArelTable < ::Arel::Table
    def [](name)
      Attribute.new(self, name)
    end
  end
end
