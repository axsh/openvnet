# -*- coding: utf-8 -*-

shared_examples 'interface assoc on endpoints' do |other_name|

  describe "Many to many relation calls for #{other_name}s" do
    let!(:base_object) { Fabricate(fabricator) }
    let(:relation_fabricator) { other_name }
    let(:join_table_fabricator) { "interface_#{other_name}".to_sym }

    let!(:interface) { Fabricate(:interface) { uuid 'if-test' } }

    accepted_params = {
      static: true
    }

    include_examples 'PUT many_to_many_relation', "#{other_name}s", accepted_params
    include_examples 'PUT many_to_many_relation', "#{other_name}s", { static: false }, [:static]
  end

end
