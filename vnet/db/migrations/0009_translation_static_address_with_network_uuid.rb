# -*- coding: utf-8 -*-

Sequel.migration do
  up do
    alter_table(:translation_static_addresses) do
      add_column :ingress_network_id, String, :null => false
      add_column :egress_network_id, String, :null => false
    end
  end

  down do
    alter_table(:translation_static_addresses) do
      drop_column :ingress_network_id
      drop_column :egress_network_id
    end
  end
end
