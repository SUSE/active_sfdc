module ActiveSfdc
  class Base < ::ActiveRecord::Base
    include ::ActiveModel::AttributeMethods
    # All salesforce are guaranteed to have a primary Id field.
    self.primary_key = 'Id'

    class << self
      # this is a makeshift reflection interface and projection guessing mechanism
      # SOQL doesn't support selecting star as in regular SQL
      # (Meaning: "SELECT * FROM Account" is an invalid sentence)
      # So we need to project always something to it, since Id is guaranteed to
      # exist, we'll use Id as a default field, and anything other field included
      # in #default_projection_fields
      def _projection_fields
        {
          Id: :string,
          **projection_fields,
        }.map do |key, type_name|
          type = ::ActiveRecord::ConnectionAdapters::SqlTypeMetadata.new(type: type_name)
          [key.to_s, ::ActiveRecord::ConnectionAdapters::Column.new(key.to_s, nil, type, true)]
        end.to_h
      end

      # :nocov:
      def projection_fields
        {}
      end
      # :nocov:

      # Don't use the default rails connection, we need our salesforce magic
      # connection
      def connection
        @connection ||= Connection.new(nil)
      end

      # clearing column_types logic from here
      def find_by_sql(sql, binds = [], preparable: nil, &block)
        result_set = connection.select_all(sanitize_sql(sql), "#{name} Load", binds, preparable: preparable)
        column_types = {}
        message_bus = ActiveSupport::Notifications.instrumenter

        payload = {
          record_count: result_set.length,
          class_name: name
        }

        message_bus.instrument("instantiation.active_record", payload) do
          result_set.map { |record| instantiate(record, column_types, &block) }
        end
      end

      # Automatically infer the Salesforce Object name by the class name
      def table_name
        self.name.split('::').last
      end

      # Here we inject our own table, so we can use unqualified identifiers
      def arel_table
        @arel_table ||= ArelTable.new table_name
      end

      # we overwrite some of the SQL-tied methods of ActiveRecord::Relation
      # that cannot be overwritten in class definition time since they're
      # overwritten each time that relation gets called.
      def relation # :nodoc:
        modules = [
          ActiveSfdc::AggregateHandlers,
          ActiveSfdc::ProjectionNormalization,
          ActiveSfdc::CreateUpdateHooks,
          ActiveSfdc::StructuralCompatibility
        ]
        super.extending!(*modules)
      end

      # Mocking the load_schema so it picks up #projection_fields definition
      # to define the object schema
      def load_schema!
        @columns_hash = _projection_fields.except(*ignored_columns)

        @columns_hash.each do |name, column|
          define_attribute(
            name,
            connection.lookup_cast_type_from_column(column),
            default: column.default,
            user_provided_default: false
          )
        end
      end
    end

    # tackle the INSERT query build to be handled by CreateUpdateHooks#insert 
    # instead. There object creation will be handed over the restforce gem.
    def _create_record(&block)
      attributes_values = changes.map{|k, v| [k.to_sym, v.last]}.to_h
      attributes_values.delete(:Id)

      new_id = self.class.unscoped.insert attributes_values
      self.id ||= new_id if self.class.primary_key

      @new_record = false

      yield(self) if block_given?

      id
    end

    # tackle the UPDATE query build to be handled by CreateUpdateHooks#_update_record
    # instead. There object updates will be handed over the restforce gem.
    def _update_record(*args, &block)
      attributes_values = changes.map{|k, v| [k.to_sym, v.last]}.to_h

      if attributes_values.empty?
        rows_affected = 0
      else
        rows_affected = self.class.unscoped._update_record attributes_values, id, id_was
      end

      yield(self) if block_given?

      rows_affected
    end
  end
end
