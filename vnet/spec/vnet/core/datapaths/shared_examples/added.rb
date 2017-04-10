# -*- coding: utf-8 -*-

shared_examples 'datapath item added' do |name|
  id_sym = "#{name}_id".to_sym

  describe "#{name}" do
    let(:dp_obj) {
      Fabricate("datapath_#{name}").to_hash
    }

    it 'add and remove' do
      subject.install

      expect(subject.send("has_active_#{name}?", dp_obj[id_sym])).to be false
      expect(subject.send("is_#{name}_active?", dp_obj[id_sym])).to be false

      subject.send("add_active_#{name}", dp_obj)
      subject.send("activate_#{name}_id", dp_obj[id_sym])

      expect(subject.send("has_active_#{name}?", dp_obj[id_sym])).to be true
      expect(subject.send("is_#{name}_active?", dp_obj[id_sym])).to be true

      subject.send("deactivate_#{name}_id", dp_obj[id_sym])

      expect(subject.send("has_active_#{name}?", dp_obj[id_sym])).to be true
      expect(subject.send("is_#{name}_active?", dp_obj[id_sym])).to be false

      subject.send("remove_active_#{name}", dp_obj[id_sym])

      expect(subject.send("has_active_#{name}?", dp_obj[id_sym])).to be false
      expect(subject.send("is_#{name}_active?", dp_obj[id_sym])).to be false
    end

  end

end
