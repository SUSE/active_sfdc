class SampleSubject < ActiveSfdc::Base
  def self.projection_fields
    {
      Name: :string,
      SUSE_Account_Number__c: :string
    }
  end
end