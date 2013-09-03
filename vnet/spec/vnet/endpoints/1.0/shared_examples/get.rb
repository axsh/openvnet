# -*- coding: utf-8 -*-

def test_with_db_entries(size)
  context "with #{size} entries in the database" do
    let(:entries) { size }

    it "should return #{size} entries" do
      last_response.should succeed.with_body_size(size)
    end
  end
end

shared_examples "a get call without uuid" do
  before(:each) do
    entries.times { Fabricate(fabricator) }
    get api_suffix
  end

  context "with no entries in the database" do
    let(:entries) { 0 }

    it "should return empty json" do
      last_response.should succeed.with_empty_body
    end
  end

  test_with_db_entries 3
end

shared_examples "a get call with uuid" do
  before(:each) do
    get api_suffix_with_uuid
  end

  include_examples "api_with_uuid_in_suffix"

  context "with an existing uuid" do
    let!(:object) { Fabricate(fabricator) }
    let(:api_suffix_with_uuid) { "#{api_suffix}/#{object.canonical_uuid}" }

    it "should return one entry" do
      last_response.should succeed.with_body_containing({:uuid => object.canonical_uuid})
    end
  end
end
