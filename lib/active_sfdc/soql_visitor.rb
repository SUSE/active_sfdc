module ActiveSfdc
  class SOQLVisitor < ::Arel::Visitors::ToSql

    # this visitor deals with nested subqueries
    def visit_Arel_SelectManager(select_node, collector)
      subcollector = ::Arel::Collectors::SQLString.new
      accept(select_node.ast, subcollector)
      collector << "(#{subcollector.value})"
    end

    # ActiveSfdc::ArelTable behaves exactly as Arel::Table
    def visit_ActiveSfdc_ArelTable(attr_node, collector)
      visit_Arel_Table(attr_node, collector)
    end

    # if the attribute is qualified, relay back to the default visitor for
    # Arel::Attributes::Attribute, else just print the column name.
    def visit_ActiveSfdc_Attribute(attr_node, collector)
      return visit_Arel_Attributes_Attribute(attr_node, collector) if attr_node.qualified
      collector << quote_column_name(attr_node.name)
    end

    # Inequalities in SOQL are != ALWAYS
    def visit_Arel_Nodes_NotEqual(node, collector)
      collector = visit node.left, collector
      collector << ' != '
      visit node.right, collector
    end

    # Equalities in SOQL are = ALWAYS
    def visit_Arel_Nodes_Equality(node, collector)
      collector = visit node.left, collector
      collector << ' = '
      visit node.right, collector
    end

    # this is a pretty specific fix, just removes the handling of the .top branch
    # of the AST (which is only used for MSSQL) but here it produces a space in
    # the SELECT clause, it doesn't hurt execution, but leaves two spaces after
    # SELECT whenever a LIMIT clause is specified.
    def visit_Arel_Nodes_SelectCore(node, collector)
      collector << "SELECT"

      collector = maybe_visit node.set_quantifier, collector

      collect_nodes_for node.projections, collector, SPACE

      if node.source && !node.source.empty?
        collector << " FROM "
        collector = visit node.source, collector
      end

      collect_nodes_for node.wheres, collector, WHERE, AND
      collect_nodes_for node.groups, collector, GROUP_BY
      unless node.havings.empty?
        collector << " HAVING "
        inject_join node.havings, collector, AND
      end
      collect_nodes_for node.windows, collector, WINDOW

      collector
    end

    # SOQL alias are not explicit, they don't use the AS keyword
    def visit_Arel_Nodes_As(node, collector)
      collector = visit node.left, collector
      collector << " "
      visit node.right, collector
    end

    # SOQL alias are not explicit, they don't use the AS keyword
    def aggregate name, node, collector
      collector << "#{name}("
      # SOQL doesn't support distinct
      collector = inject_join(node.expressions, collector, ", ") << ")"
      if node.alias
        collector << " "
        visit node.alias, collector
      else
        collector
      end
    end
  end
end
