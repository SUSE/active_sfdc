module ActiveSfdc
  # SOQL supports a very limited set of Aggregates, we'll be migrating those
  # as soon as we're discovering them.
  module AggregateHandlers
    # * (sql star) is not a valid token in SOQL, so we'll switch that to Id. In
    # SFDC is guaranteed that Id is unique amongst all accessible objects.
    def aggregate_column(column_name)
      return column_name if Arel::Expressions === column_name

      if @klass.has_attribute?(column_name) || @klass.attribute_alias?(column_name)
        @klass.arel_attribute(column_name)
      else
        Arel.sql(column_name == :all ? "" : column_name.to_s)
      end
    end

    # SOQL supports a very limited set of Aggregates, we'll be migrating those
    # as soon as we're discovering them
    #
    # ActiveRecord defaults is to create queries in the form of
    #
    # SELECT COUNT(*) FROM (SELECT 1 as one FROM Table [Where clauses] [Limit/offset])
    #
    # From our current understanding, this is not possible in SOQL, so we'll
    # treat it as a plain query in the form of:
    #
    # SELECT COUNT(Id) count_Id FROM Table [WHERE expressions...] [Limit/offset]
    def build_count_subquery(relation, column_name, distinct)
      if column_name == :all
        column_alias = Arel.sql('Id')
      else
        column_alias = Arel.sql(column_name.to_s)
      end

      select_value = operation_over_aggregate_column(column_alias || Arel.sql('Id'), "count", false)

      relation.arel.projections.clear()
      relation.arel.project(select_value)
      relation.arel
    end

    def execute_grouped_calculation(operation, column_name, distinct) #:nodoc:
      group_attrs = group_values

      if group_attrs.first.respond_to?(:to_sym)
        association  = @klass._reflect_on_association(group_attrs.first)
        associated   = group_attrs.size == 1 && association && association.belongs_to? # only count belongs_to associations
        group_fields = Array(associated ? association.foreign_key : group_attrs)
      else
        group_fields = group_attrs
      end
      group_fields = arel_columns(group_fields)

      group_aliases = group_fields.map { |field| column_alias_for(field) }
      group_columns = group_aliases.zip(group_fields)

      if operation == "count" && column_name == :all
        aggregate_alias = "count_all"
      else
        aggregate_alias = column_alias_for([operation, column_name].join(" "))
      end

      select_values = [
        operation_over_aggregate_column(
          aggregate_column(column_name),
          operation,
          distinct).as(aggregate_alias)
      ]
      select_values += self.select_values unless having_clause.empty?

      select_values.concat group_columns.map { |aliaz, field|
        if field.respond_to?(:as)
          field.as(aliaz)
        else
          # SOQL doesn't support AS
          "#{field} #{aliaz}"
        end
      }

      relation = except(:group).distinct!(false)
      relation.group_values  = group_fields
      relation.select_values = select_values

      calculated_data = skip_query_cache_if_necessary { @klass.connection.select_all(relation.arel, nil) }

      if association
        key_ids     = calculated_data.collect { |row| row[group_aliases.first] }
        key_records = association.klass.base_class.where(association.klass.base_class.primary_key => key_ids)
        key_records = Hash[key_records.map { |r| [r.id, r] }]
      end

      Hash[calculated_data.map do |row|
        # Lets use a default type for this, in the future we could implement reflection
        # for grabbing the appropiate type
        type = ActiveRecord::Type.default_value

        key = group_columns.map { |aliaz, col_name|
          type_cast_calculated_value(row[aliaz], type)
        }
        key = key.first if key.size == 1
        key = key_records[key] if associated

        [key, type_cast_calculated_value(row[aggregate_alias], type, operation)]
      end]
    end

    # execute_simple_calculation gets triggered whenever an aggregate doesn't have
    # grouping
    def execute_simple_calculation(operation, column_name, distinct) #:nodoc:
      # LIMIT 0 clauses on aggregate queries will return a 0 result
      # no need to query salesforce for that
      return 0 if has_limit_or_offset? && limit_value == 0

      if operation == "count" && (column_name == :all && distinct || has_limit_or_offset?)
        # Shortcut when limit is zero.
        
        query_builder = build_count_subquery(spawn, column_name, distinct)
      else
        # PostgreSQL doesn't like ORDER BY when there are no GROUP BY
        relation = unscope(:order).distinct!(false)

        column = aggregate_column(column_name)
        select_value = operation_over_aggregate_column(column, operation, distinct)

        relation.select_values = [select_value]

        query_builder = relation.arel
      end

      result = skip_query_cache_if_necessary { @klass.connection.select_all(query_builder, nil) }
      row    = result.first

      value  = row && row.fetch("expr0")

      type   = type_for(column_name)
      
      type_cast_calculated_value(value, type, operation)
    end
  end
end