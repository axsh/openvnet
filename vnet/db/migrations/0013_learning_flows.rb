# -*- coding: utf-8 -*-

Sequel.migration do
  up do
    alter_table(:datapaths) do
      add_column :enable_ovs_learn_action, TrueClass, :null=>false, :default=>true
      add_unique_constraint [:dpid, :node_id, :is_deleted]
    end
  end

  down do
    alter_table(:datapaths) do
      drop_column :enable_ovs_learn_action
      drop_unique_constraint [:dpid, :node_id, :is_deleted]
    end
  end
end
