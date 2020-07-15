require "ostruct"

require "arel"
require "restforce"
require "active_record"


require "active_sfdc/configuration"
require "active_sfdc/arel_table"
require "active_sfdc/attribute"
require "active_sfdc/aggregate_handlers"
require "active_sfdc/create_update_hooks"
require "active_sfdc/projection_normalization"
require "active_sfdc/structural_compatibility"
require "active_sfdc/base"
require "active_sfdc/soql_visitor"
require "active_sfdc/connection"

module ActiveSfdc
  class Error < StandardError; end
  class SandboxModeEnabled < Error; end
  # Your code goes here...
end
