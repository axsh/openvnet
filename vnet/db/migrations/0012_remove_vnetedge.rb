# -*- coding: utf-8 -*-

Sequel.migration do
  up do
    drop_table(:vlan_translations)
  end

  down do
    create_table(:vlan_translations) do
      primary_key :id
      String :uuid, :unique => true, :null => false

      Integer :translation_id, :index => true
      Bignum :mac_address
      Integer :vlan_id
      Integer :network_id
    end
  end
end
