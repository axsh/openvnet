# -*- coding: utf-8 -*-

Sequel.migration do
  up do
    alter_table(:topology_datapaths) do
      add_column :ip_lease_id, Integer, :null => false
    end
  end

  down do
    alter_table(:topology_datapaths) do
      drop_column :ip_lease_id
    end
  end
end
