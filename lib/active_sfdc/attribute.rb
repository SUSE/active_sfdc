module ActiveSfdc
  # Custom attribute to render Table identifiers as 
  # > identifier
  # unless it's forcefully qualified, then it'll be rendered in the form of
  # > table.attribute
  class Attribute < ::Arel::Attributes::Attribute
    attr_accessor :qualified

    def initialize(table, name)
      super(table, name)
      @qualified = unqualify
    end

    def qualify
      @qualified = true
    end

    def unqualify
      @qualified = false
    end
  end
end
