require_relative "sample_subject"

RSpec.describe SampleSubject do
  let!(:dummy_client) { double(::Restforce) }
  let!(:dummy_config) { ActiveSfdc::Configuration.new }

  def make_row(**kwargs)
    ActiveSupport::HashWithIndifferentAccess.new({
      attributes: {
        type: 'SampleSubject',
        url: '/some/salesforce/uri/to/the/current/resource'
      },
      **kwargs
    })
  end

  def make_aggregate_row(**kwargs)
    ActiveSupport::HashWithIndifferentAccess.new({
      attributes: {
        type: 'AggregateResult',
      },
      **kwargs
    })
  end

  before do
    ActiveSfdc.configuration = dummy_config
    allow(dummy_config).to receive(:client).and_return(dummy_client)
  end

  it "does #find_by" do
    sql = described_class.where(Id: '3').limit(1).to_sql

    expect(dummy_client).to receive(:query).with(sql).and_return([])
    described_class.find_by(Id: '3')
  end

  it "does #sum" do
    sql = %{SELECT SUM(Id) FROM SampleSubject WHERE Id = '3'}

    expect(dummy_client).to receive(:query).with(sql).and_return([ make_aggregate_row(expr0: 1) ])
    described_class.where(Id: '3').sum(:Id)
  end

  it "does #sum with limit" do
    sql = %{SELECT SUM(Id) FROM SampleSubject WHERE Id = '3' LIMIT 10}

    expect(dummy_client).to receive(:query).with(sql).and_return([ make_aggregate_row(expr0: 1) ])
    described_class.where(Id: '3').limit(10).sum(:Id)
  end

  it "does #sum with limit 0" do
    expect(dummy_client).not_to receive(:query)
    described_class.where(Id: '3').limit(0).sum(:Id)
  end

  it "does #count" do
    sql = %{SELECT COUNT(Id) FROM SampleSubject WHERE Id = '3'}

    expect(dummy_client).to receive(:query).with(sql).and_return([ make_aggregate_row(expr0: 1) ])
    described_class.where(Id: '3').count
  end

  it "does #count limit 0" do
    expect(dummy_client).not_to receive(:query)
    described_class.where(Id: '3').limit(0).count
  end

  it "does #count limit 10" do
    sql = %{SELECT COUNT(Id) FROM SampleSubject WHERE Id = '3' LIMIT 10}
    expect(dummy_client).to receive(:query).with(sql).and_return([ make_aggregate_row(expr0: 1) ])
    described_class.where(Id: '3').limit(10).count(:Id)
  end

  it "does #count limit 10 all" do
    sql = %{SELECT COUNT(Id) FROM SampleSubject WHERE Id = '3' LIMIT 10}
    expect(dummy_client).to receive(:query).with(sql).and_return([ make_aggregate_row(expr0: 1) ])
    described_class.where(Id: '3').limit(10).count
  end

  it "does #count limit 10 and offset" do
    sql = %{SELECT COUNT(Id) FROM SampleSubject WHERE Id = '3' LIMIT 10 OFFSET 10}
    expect(dummy_client).to receive(:query).with(sql).and_return([ make_aggregate_row(expr0: 1) ])
    described_class.where(Id: '3').limit(10).offset(10).count(:Id)
  end

  it "does #count limit 10 and offset" do
    sql = %{SELECT COUNT(Id) count_id, status status, category category FROM SampleSubject GROUP BY status, category}
    expect(dummy_client).to receive(:query).with(sql).and_return([ make_aggregate_row(count_id: 1, status: 'Sample', category: 'category') ])
    described_class.group(:status, :category).count(:Id)
  end

  it "does #count having" do
    sql = %{SELECT COUNT(Id) count_all, Name samplesubject_name FROM SampleSubject GROUP BY Name HAVING (COUNT(Id) > 1)}
    expect(dummy_client).to receive(:query).with(sql).and_return([ make_aggregate_row(count_id: 1, status: 'Sample', category: 'category') ])
    described_class.group(:Name).having('COUNT(Id) > ?', 1).count
  end

  it "does #first" do
    sql = described_class.order(Id: :asc).limit(1).to_sql

    expect(dummy_client).to receive(:query).with(sql).and_return([])
    described_class.all.first
  end

  it "does #last" do
    sql = described_class.order(Id: :desc).limit(1).to_sql

    expect(dummy_client).to receive(:query).with(sql).and_return([])
    described_class.all.last
  end

  it "does #select" do
    sql = described_class.select(:Id).order(Id: :asc).limit(1).to_sql

    expect(dummy_client).to receive(:query).with(sql).and_return([])
    described_class.all.select(:Id).first
  end

  it "does #or" do
    prevquery = described_class.where(Id: '3')
    relation = described_class.where(Id: '3').limit(1).order(:asc).or(prevquery)
    sql = relation.to_sql

    expect(dummy_client).to receive(:query).with(sql).and_return([])
    relation.first
  end

  it "does #create" do
    expect(dummy_client).to receive(:create!)
                              .with(described_class.table_name, {Name: 'z'})
                              .and_return('1234')
    obj = described_class.new
    obj.Name = 'z'
    obj.save
  end

  it "does #update" do
    sql = described_class.where(Id: '3').limit(1).to_sql

    expect(dummy_client).to receive(:query)
                              .with(sql)
                              .and_return([
                                make_row(Name: 'z', Id: '3')
                              ])
    expect(dummy_client).to receive(:update!)
                              .with(described_class.table_name, {Id: '3', Name: 'CDE'})
                              .and_return('1234')

    obj = described_class.find_by(Id: '3')
    
    expect(obj.Id).to eq('3')

    obj.Name = 'CDE'
    obj.save
  end

  it "does empty #update" do
    sql = described_class.where(Id: '3').limit(1).to_sql

    expect(dummy_client).to receive(:query)
                              .with(sql)
                              .and_return([
                                make_row(Name: 'z', Id: '3')
                              ])
    expect(dummy_client).not_to receive(:update!)

    obj = described_class.find_by(Id: '3')
    
    expect(obj.Id).to eq('3')
    obj.save
  end
end
