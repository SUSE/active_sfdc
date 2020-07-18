require_relative "sample_subject"

RSpec.describe 'Sample Queries from SFDC Documentation' do
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

  context 'queries' do
    context 'Simple query' do
      let(:described_class) do
        Class.new(ActiveSfdc::Base) do
          def self.table_name
            'Account'
          end
        end
      end

      result_sql = %{SELECT Id, Name, BillingCity FROM Account}

      subject do
        described_class.select(:Id, :Name, :BillingCity)
      end

      it 'renders the correct query' do
        expect(dummy_client).to receive(:query).with(result_sql).and_return([])
        subject.to_a
      end
    end

    context 'WHERE' do
      let(:described_class) do
        Class.new(ActiveSfdc::Base) do
          def self.table_name
            'Contact'
          end
        end
      end

      result_sql = %{SELECT Id FROM Contact WHERE (Name LIKE 'A%') AND MailingCity = 'California'}

      subject do
        described_class.where('Name LIKE ?', "A%").where(MailingCity: 'California')
      end

      it 'renders the correct query' do
        expect(dummy_client).to receive(:query).with(result_sql).and_return([])
        subject.to_a
      end
    end

    context 'ORDER BY' do
      let(:described_class) do
        Class.new(ActiveSfdc::Base) do
          def self.table_name
            'Account'
          end
        end
      end

      result_sql = %{SELECT Name FROM Account ORDER BY Name DESC NULLS LAST}

      subject do
        described_class.select(:Name).order("Name DESC NULLS LAST")
      end

      it 'renders the correct query' do
        expect(dummy_client).to receive(:query).with(result_sql).and_return([])
        subject.to_a
      end
    end

    context 'LIMIT' do
      let(:described_class) do
        Class.new(ActiveSfdc::Base) do
          def self.table_name
            'Account'
          end
        end
      end

      result_sql = %{SELECT Name FROM Account WHERE Industry = 'media' LIMIT 125}

      subject do
        described_class.select(:Name).where(Industry: 'media').limit(125)
      end

      it 'renders the correct query' do
        expect(dummy_client).to receive(:query).with(result_sql).and_return([])
        subject.to_a
      end
    end

    context 'Order by with LIMIT' do
      let(:described_class) do
        Class.new(ActiveSfdc::Base) do
          def self.table_name
            'Account'
          end
        end
      end

      result_sql = %{SELECT Name FROM Account WHERE Industry = 'media' ORDER BY BillingPostalCode ASC NULLS LAST LIMIT 125}

      subject do
        described_class.select(:Name).where(Industry: 'media').order("BillingPostalCode ASC NULLS LAST").limit(125)
      end

      it 'renders the correct query' do
        expect(dummy_client).to receive(:query).with(result_sql).and_return([])
        subject.to_a
      end
    end

    context 'OFFSET with ORDER BY' do
      let(:described_class) do
        Class.new(ActiveSfdc::Base) do
          def self.table_name
            'Merchandise__c'
          end
        end
      end

      result_sql = %{SELECT Name, Id FROM Merchandise__c ORDER BY Name ASC OFFSET 100}

      subject do
        described_class.select(:Name, :Id).order(:Name).offset(100)
      end

      it 'renders the correct query' do
        expect(dummy_client).to receive(:query).with(result_sql).and_return([])
        subject.to_a
      end
    end

    context 'OFFSET with ORDER BY and LIMIT' do
      let(:described_class) do
        Class.new(ActiveSfdc::Base) do
          def self.table_name
            'Merchandise__c'
          end
        end
      end

      result_sql = %{SELECT Name, Id FROM Merchandise__c ORDER BY Name ASC LIMIT 20 OFFSET 100}

      subject do
        described_class.select(:Name, :Id).order(:Name).limit(20).offset(100)
      end

      it 'renders the correct query' do
        expect(dummy_client).to receive(:query).with(result_sql).and_return([])
        subject.to_a
      end
    end

    context 'Relationship queries: child-to-parent sample 1' do
      let(:described_class) do
        Class.new(ActiveSfdc::Base) do
          def self.table_name
            'Contact'
          end
        end
      end

      result_sql = %{SELECT Contact.FirstName, Account.Name FROM Contact}

      subject do
        described_class.select('Contact.FirstName', 'Account.Name')
      end

      it 'renders the correct query' do
        expect(dummy_client).to receive(:query).with(result_sql).and_return([])
        subject.to_a
      end
    end

    context 'Relationship queries: child-to-parent sample 2' do
      let(:described_class) do
        Class.new(ActiveSfdc::Base) do
          def self.table_name
            'Contact'
          end
        end
      end

      result_sql = %{SELECT Id, Name, Account.Name FROM Contact WHERE Account.Industry = 'media'}

      subject do
        described_class.select(:Id, :Name, 'Account.Name').where('Account.Industry': 'media')
      end

      it 'renders the correct query' do
        expect(dummy_client).to receive(:query).with(result_sql).and_return([])
        subject.to_a
      end
    end

    context 'Relationship queries: parent-to-child sample 1' do
      let(:described_class) do
        Class.new(ActiveSfdc::Base) do
          def self.table_name
            'Account'
          end
        end
      end

      let(:aux_class) do
        Class.new(ActiveSfdc::Base) do
          def self.table_name
            'Contacts'
          end
        end
      end

      result_sql = %{SELECT Name, (SELECT LastName FROM Contacts) FROM Account}

      subject do
        described_class.select(:Name, "(#{aux_class.select(:LastName).to_sql})")
      end

      it 'renders the correct query' do
        expect(dummy_client).to receive(:query).with(result_sql).and_return([])
        subject.to_a
      end
    end
    context 'Relationship query with WHERE' do
      let(:described_class) do
        Class.new(ActiveSfdc::Base) do
          def self.table_name
            'Account'
          end
        end
      end

      let(:aux_class) do
        Class.new(ActiveSfdc::Base) do
          def self.table_name
            'Contacts'
          end
        end
      end

      result_sql = %{SELECT Name, (SELECT LastName FROM Contacts WHERE CreatedBy.Alias = 'x') FROM Account WHERE Industry = 'media'}

      subject do
        described_class.select(:Name, "(#{aux_class.select(:LastName).where('CreatedBy.Alias': 'x').to_sql})").where(Industry: 'media')
      end

      it 'renders the correct query' do
        expect(dummy_client).to receive(:query).with(result_sql).and_return([])
        subject.to_a
      end
    end

    context 'Relationship query: child-to parent with custom objects' do
      let(:described_class) do
        Class.new(ActiveSfdc::Base) do
          def self.table_name
            'Daughter__c'
          end
        end
      end

      result_sql = %{SELECT Id, FirstName__c, Mother_of_Child__r.FirstName__c FROM Daughter__c WHERE (Mother_of_Child__r.LastName__c LIKE 'C%')}

      subject do
        described_class.select(*%i[Id FirstName__c Mother_of_Child__r.FirstName__c]).where("Mother_of_Child__r.LastName__c LIKE ?", 'C%')
      end

      it 'renders the correct query' do
        expect(dummy_client).to receive(:query).with(result_sql).and_return([])
        subject.to_a
      end
    end

    context 'Relationship query: parent to child with custom objects' do
      let(:described_class) do
        Class.new(ActiveSfdc::Base) do
          def self.table_name
            'Merchandise__c'
          end
        end
      end

      let(:aux_class) do
        Class.new(ActiveSfdc::Base) do
          def self.table_name
            'Line_Items__r'
          end
        end
      end

      result_sql = %{SELECT Name, (SELECT Name FROM Line_Items__r) FROM Merchandise__c WHERE (Name LIKE 'Acme%')}

      subject do
        described_class.select(:Name, "(#{aux_class.select(:Name).to_sql})").where("Name LIKE ?", 'Acme%')
      end

      it 'renders the correct query' do
        expect(dummy_client).to receive(:query).with(result_sql).and_return([])
        subject.to_a
      end
    end

    context 'Relationship queries with polymorphic key sample 1' do
      let(:described_class) do
        Class.new(ActiveSfdc::Base) do
          def self.table_name
            'Task'
          end
        end
      end

      result_sql = %{SELECT Id, Owner.Name FROM Task WHERE (Owner.FirstName LIKE 'B%')}

      subject do
        described_class.select(*%i[Id Owner.Name]).where("Owner.FirstName LIKE ?", 'B%')
      end

      it 'renders the correct query' do
        expect(dummy_client).to receive(:query).with(result_sql).and_return([])
        subject.to_a
      end
    end

    context 'Relationship queries with polymorphic key sample 2' do
      let(:described_class) do
        Class.new(ActiveSfdc::Base) do
          def self.table_name
            'Task'
          end
        end
      end

      result_sql = %{SELECT Id, Who.FirstName, Who.LastName FROM Task WHERE (Owner.FirstName LIKE 'B%')}

      subject do
        described_class.select(*%i[Id Who.FirstName Who.LastName]).where("Owner.FirstName LIKE ?", 'B%')
      end

      it 'renders the correct query' do
        expect(dummy_client).to receive(:query).with(result_sql).and_return([])
        subject.to_a
      end
    end

    context 'Relationship queries with polymorphic key sample 2' do
      let(:described_class) do
        Class.new(ActiveSfdc::Base) do
          def self.table_name
            'Event'
          end
        end
      end

      result_sql = %{SELECT Id, What.Name FROM Event}

      subject do
        described_class.select(*%i[Id What.Name])
      end

      it 'renders the correct query' do
        expect(dummy_client).to receive(:query).with(result_sql).and_return([])
        subject.to_a
      end
    end

    context 'Relationship queries with aggregate sample 1' do
      let(:described_class) do
        Class.new(ActiveSfdc::Base) do
          def self.table_name
            'Account'
          end
        end
      end

      let(:aux_class) do
        Class.new(ActiveSfdc::Base) do
          def self.table_name
            'Notes'
          end
        end
      end

      result_sql = %{SELECT Name, (SELECT CreatedBy.Name FROM Notes) FROM Account}

      subject do
        described_class.select(:Name, "(#{aux_class.select('CreatedBy.Name').to_sql})")
      end

      it 'renders the correct query' do
        expect(dummy_client).to receive(:query).with(result_sql).and_return([])
        subject.to_a
      end
    end

    context 'Relationship queries with aggregate sample 2' do
      let(:described_class) do
        Class.new(ActiveSfdc::Base) do
          def self.table_name
            'Opportunity'
          end
        end
      end

      let(:aux_class) do
        Class.new(ActiveSfdc::Base) do
          def self.table_name
            'OpportunityLineItems'
          end
        end
      end

      result_sql = %{SELECT Amount, Id, Name, (SELECT Quantity, ListPrice, PricebookEntry.UnitPrice, PricebookEntry.Name FROM OpportunityLineItems) FROM Opportunity}

      subject do
        described_class.select(*%i[Amount Id Name], "(#{aux_class.select(*%i[Quantity ListPrice PricebookEntry.UnitPrice PricebookEntry.Name]).to_sql})")
      end

      it 'renders the correct query' do
        expect(dummy_client).to receive(:query).with(result_sql).and_return([])
        subject.to_a
      end
    end

    context 'Simple query: the UserId and LoginTime for each user' do
      let(:described_class) do
        Class.new(ActiveSfdc::Base) do
          def self.table_name
            'LoginHistory'
          end
        end
      end

      result_sql = %{SELECT UserId, LoginTime FROM LoginHistory}

      subject do
        described_class.select(*%i[UserId LoginTime])
      end

      it 'renders the correct query' do
        expect(dummy_client).to receive(:query).with(result_sql).and_return([])
        subject.to_a
      end
    end

    context 'Relationship queries with number of logins per user in a specific time range' do
      let(:described_class) do
        Class.new(ActiveSfdc::Base) do
          def self.table_name
            'LoginHistory'
          end
        end
      end

      result_sql = %{SELECT COUNT(ID) count_id, UserId userid FROM LoginHistory WHERE (LoginTime > 2010-09-20T22:16:30+00:00 AND LoginTime < 2010-09-21T22:16:30+00:00) GROUP BY UserId}

      subject do
        start_date = '2010-09-20T22:16:30Z'.to_datetime
        end_date = '2010-09-21T22:16:30Z'.to_datetime

        described_class.group(:UserId).where("LoginTime > ? AND LoginTime < ?", start_date, end_date).count(:ID)
      end

      it 'renders the correct query' do
        expect(dummy_client).to receive(:query).with(result_sql).and_return([])
        subject.to_a
      end
    end

    context 'Query to retrieve the RecordType per user' do
      let(:described_class) do
        Class.new(ActiveSfdc::Base) do
          def self.table_name
            'RecordType'
          end
        end
      end

      result_sql = %{SELECT Id, Name, IsActive, SobjectType, DeveloperName, Description FROM RecordType}

      subject do
        described_class.select(*%i[Id Name IsActive SobjectType DeveloperName Description])
      end

      it 'renders the correct query' do
        expect(dummy_client).to receive(:query).with(result_sql).and_return([])
        subject.to_a
      end
    end
  end

  describe 'aggregates' do
    # these result sql cannot be fetched with to_sql so we check for client
    # .query calls to match the arguments.
    context 'count()' do
      let(:described_class) do
        Class.new(ActiveSfdc::Base) do
          def self.table_name
            'Contact'
          end
        end
      end

      result_sql = %{SELECT COUNT() FROM Contact}

      subject do
        described_class.count
      end

      it 'renders the correct query' do
        expect(dummy_client).to receive(:query).with(result_sql).and_return([make_aggregate_row(expr0: 1)])
        subject
      end
    end

    context 'GROUP BY' do
      let(:described_class) do
        Class.new(ActiveSfdc::Base) do
          def self.table_name
            'Lead'
          end
        end
      end

      result_sql = %{SELECT COUNT(Name) count_name, LeadSource leadsource FROM Lead GROUP BY LeadSource}

      subject do
        described_class.select(:LeadSource).group(:LeadSource).count(:Name)
      end

      it 'renders the correct query' do
        expect(dummy_client).to receive(:query).with(result_sql).and_return([make_aggregate_row(expr0: 1)])
        subject
      end
    end

    context 'HAVING' do
      let(:described_class) do
        Class.new(ActiveSfdc::Base) do
          def self.table_name
            'Account'
          end
        end
      end

      result_sql = %{SELECT COUNT(Id) count_id, Name name FROM Account GROUP BY Name HAVING (COUNT(Id) > 1)}

      subject do
        described_class.group(:Name).having("COUNT(Id) > 1").count(:Id)
      end

      it 'renders the correct query' do
        expect(dummy_client).to receive(:query).with(result_sql).and_return([make_aggregate_row(expr0: 1)])
        subject
      end
    end
  end
end
