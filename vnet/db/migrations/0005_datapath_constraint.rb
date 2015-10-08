Sequel.migration do
  up do
    alter_table(:datapath_networks) do
      add_index [:mac_address_id, :is_deleted], :unique=>true
    end
  end
end
