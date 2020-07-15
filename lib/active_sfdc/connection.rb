module ActiveSfdc
  # = SFDC Connection
  # here we'll mimick a database connection towards salesforce, however, active
  # record is very SQL-centric regarding this aspect, so we need to fake a number
  # of functions so it interfaces with SFDC more easily.
  #
  # - no prepared statements
  # - no table/view discovery
  # - hooking up the SOQL visitor
  # - hooking the SQL queries to SFDC.
  # - extending the quote behavior to match SOQL Rules.
  class Connection < ActiveRecord::ConnectionAdapters::AbstractAdapter
    def prepared_statements
      false
    end

    def sfdc_client
      ActiveSfdc.configuration.client
    end

    def exec_query(sql, name = 'SQL', binds = [], prepare: false)
      sfdc_client.query(sql)
    end

    def visitor
      ActiveSfdc::SOQLVisitor.new self
    end

    alias :arel_visitor :visitor

    # forcefully expose an empty set of tables
    def tables
      []
    end

    # forcefully expose an empty set of views
    def views
      []
    end

    include ActiveRecord::ConnectionAdapters::Quoting

    def quote(value)
      # Dates & Datetimes are rendered as literals
      if [DateTime, Date, ActiveSupport::TimeWithZone].include? value.class
        return value.to_formatted_s(:iso8601)
      end

      # nil, true, false = NULL, true, false
      case value
      when nil
        return 'NULL'
      when true
        return 'true'
      when false
        return 'false'
      end
      super
    end
  end
end
