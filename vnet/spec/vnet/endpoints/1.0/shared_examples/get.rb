# -*- coding: utf-8 -*-

def test_with_db_entries(size)
  context "with #{size} entries in the database" do
    let(:entries) { size }

    it "should return #{size} entries" do
      expect(last_response).to succeed.with_body_size(size)
    end
  end
end

shared_examples "GET /" do
  describe "GET /" do
    before(:each) do
      entries.times { Fabricate(fabricator) }
      get api_suffix
    end

    context "with no entries in the database" do
      let(:entries) { 0 }

      it "should return json with empty items" do
        expect(last_response).to succeed.with_body({
          "total_count" => 0,
          "offset" =>  0,
          "limit" => Vnet::Configurations::Webapi.conf.pagination_limit,
          "items" => [],
        })
      end
    end

    test_with_db_entries 3
  end
end

shared_examples "GET /:uuid" do
  describe "GET /:uuid" do
    before(:each) do
      get api_suffix_with_uuid
    end

    include_examples "api_with_uuid_in_suffix"

    context "with an existing uuid" do
      let!(:object) { Fabricate(fabricator) }
      let(:api_suffix_with_uuid) { "#{api_suffix}/#{object.canonical_uuid}" }

      it "should return one entry" do
        expect(last_response).to succeed.with_body_containing({:uuid => object.canonical_uuid})
      end
    end
  end
end

shared_examples "GET /:uuid/postfix" do
  describe "GET /:uuid/postfix" do
    let!(:object) { Fabricate(fabricator) }
    let(:api_suffix_with_uuid) { "#{api_suffix}/#{object.canonical_uuid}/#{api_postfix}" }

    before(:each) do
      entries.times { postfix_fabricate }
      get api_suffix_with_uuid
    end

    context "with no entries in the database" do
      let(:entries) { 0 }

      it "should return json with empty items" do
        expect(last_response).to succeed.with_body({
          "total_count" => 0,
          "offset" =>  0,
          "limit" => Vnet::Configurations::Webapi.conf.pagination_limit,
          "items" => [],
        })
      end
    end

    test_with_db_entries 1
  end
end

