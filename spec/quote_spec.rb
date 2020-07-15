module ActiveSfdc
  RSpec.describe "the to_sql visitor" do
    before do
      @visitor = SOQLVisitor.new(Connection.new(nil))
      @table = ArelTable.new(:users)
      @attr = @table[:id]
    end

    def compile(node)
      @visitor.accept(node, ::Arel::Collectors::SQLString.new).value
    end

    it "handles datetimes" do
      value = ::DateTime.now
      sql = compile @table[:value].eq(value)
      expect(sql).to eq(%{value = #{value.to_formatted_s(:iso8601)}})
    end

    it "handles datetimes with timezone" do
      value = ::Time.find_zone!('UTC').now
      sql = compile @table[:value].eq(value)
      expect(sql).to eq(%{value = #{value.to_formatted_s(:iso8601)}})
    end

    it "handles dates" do
      value = ::Date.today
      sql = compile @table[:value].eq(value)
      expect(sql).to eq(%{value = #{value.to_formatted_s(:iso8601)}})
    end

    it "handles null" do
      value = nil
      sql = compile @table[:value].eq(value)
      expect(sql).to eq(%{value = NULL})
    end

    it "handles boolean" do
      [true, false].each do |value|
        sql = compile @table[:value].eq(value)
        expect(sql).to eq(%{value = #{value}})
      end
    end
  end
end
