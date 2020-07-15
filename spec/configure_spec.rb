RSpec.describe 'settings' do
  before do
    ActiveSfdc.configuration = ActiveSfdc::Configuration.new
  end

  it 'should save restforce settings' do
    ActiveSfdc.configure do |c|
      c.host = 'https://dummy-host.com/'
    end
    expect(ActiveSfdc.configuration.host).to eq('https://dummy-host.com/')
  end

  it 'replaces uses a given client' do
    dbl = double(Restforce)
    ActiveSfdc.configure do |c|
      c.client = dbl
    end
    expect(ActiveSfdc.configuration.client).to eq(dbl)
  end

  context 'sandboxed' do
    it 'picks it up from configure' do
      ActiveSfdc.configure do |c|
        c.sandboxed = true
      end
      expect(ActiveSfdc.configuration.sandboxed?).to eq(true)
    end

    it 'picks it up from Rails application sandbox' do
      Rails = double('Rails')
      application = double('Rails::Application')
      allow(Rails).to receive(:application).and_return(application)
      allow(application).to receive(:sandbox).and_return(true)

      ActiveSfdc.configure do |c|
      end

      expect(ActiveSfdc.configuration.sandboxed?).to eq(true)
    end

    it 'automatically sets it to false' do
      ActiveSfdc.configure do |c|
      end

      expect(ActiveSfdc.configuration.sandboxed?).to eq(false)
    end
  end
end
