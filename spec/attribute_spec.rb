module ActiveSfdc
  RSpec.describe Attribute do
    before do
      @table = ArelTable.new(:table)
    end

    it "defaults to unqualified" do
      node = described_class.new(@table, :sample)
      expect(node.qualified).to eq(false)
    end

    it "switch to qualifies" do
      node = described_class.new(@table, :sample)
      node.qualify
      expect(node.qualified).to eq(true)
    end
  end
end
