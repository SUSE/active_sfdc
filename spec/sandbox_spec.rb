require_relative "sample_subject"

RSpec.describe 'Sandbox mode' do
  let!(:dummy_client) { double(::Restforce) }
  let!(:dummy_config) { ActiveSfdc::Configuration.new }

  before do
    ActiveSfdc.configuration = dummy_config
    allow(dummy_config).to receive(:client).and_return(dummy_client)
  end

  context 'when enabled' do
    before do
      ActiveSfdc.configuration.sandboxed = true
    end

    it "raises when trying to write changes" do
      expect(dummy_client).not_to receive(:create!)

      obj = SampleSubject.new
      obj.Name = 'z'

      expect { obj.save }.to raise_error(ActiveSfdc::SandboxModeEnabled)
    end
  end

  context 'when disabled' do
    before do
      ActiveSfdc.configuration.sandboxed = false
    end

    it "raises when trying to write changes" do
      expect(dummy_client).to receive(:create!)

      obj = SampleSubject.new
      obj.Name = 'z'
      expect { obj.save }.not_to raise_error
    end
  end
end
