module ActiveSfdc
  module CreateUpdateHooks
    # shortcut
    def sfdc_client
      ActiveSfdc.configuration.client
    end

    def _ensure_sandbox
      if ActiveSfdc.configuration.sandboxed?
        raise ActiveSfdc::SandboxModeEnabled.new('Running with sandbox enabled, writes are disabled.')
      end
    end

    # only commit writes if we're not in sandbox mode
    def _update_record(values, id, id_was)
      _ensure_sandbox

      values['Id'] = id
      result = sfdc_client.update!(table_name, values.symbolize_keys)
    end

    def insert(values)
      _ensure_sandbox

      result = sfdc_client.create!(table_name, values.symbolize_keys)
    end
  end
end
