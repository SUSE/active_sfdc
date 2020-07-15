module ActiveSfdc
  RSpec.describe "the SOQL visitor" do
    before do
      @visitor = SOQLVisitor.new(Connection.new(nil))
      @table = ArelTable.new(:table)
      @attr = @table[:id]
    end

    def compile(node)
      @visitor.accept(node, ::Arel::Collectors::SQLString.new).value
    end

    nodes_hash = {
      '!=': ['inequality', ::Arel::Nodes::NotEqual],
      '=':  ['equality', ::Arel::Nodes::Equality],
    }

    nodes_hash.each do |op, (name, nodetype)|
      context "#{name} operator (#{op})'" do
        it "handles strings" do
          val = ::Arel::Nodes.build_quoted('stringval', @table[:active])
          sql = compile nodetype.send(:new, @table[:active], val)
          expect(sql).to eq(%{active #{op} 'stringval'})
        end

        it "handles nil" do
          val = ::Arel::Nodes.build_quoted(nil, @table[:active])
          sql = compile nodetype.send(:new, @table[:active], val)
          expect(sql).to eq(%{active #{op} NULL})
        end

        it "handles numbers" do
          val = ::Arel::Nodes.build_quoted(123, @table[:active])
          sql = compile nodetype.send(:new, @table[:active], val)
          expect(sql).to eq(%{active #{op} 123})
        end

        it "handles booleans" do
          val = ::Arel::Nodes.build_quoted(false, @table[:active])
          sql = compile nodetype.send(:new, @table[:active], val)
          expect(sql).to eq(%{active #{op} false})
        end
      end
    end

    context "Nested selects" do
      it "renders the nested query in a proyection" do
        nested_table = ArelTable.new(:nested_table).project(:Id)
        sql = compile @table.project(nested_table).ast
        expect(sql).to eq(%{SELECT (SELECT Id FROM nested_table) FROM table})
      end
    end

    context "Aliases" do
      it "renders aliases without AS keyword" do
        nested_table = @table[:Id].as('c')
        sql = compile nested_table
        expect(sql).to eq(%{Id c})
      end
    end
  end
end
