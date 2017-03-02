# -*- coding: utf-8 -*-

Sequel.migration do
  up do
    alter_table(:filter_statics) do
      drop_column :passthrough
      add_column :action, String, :null => false
    end
  end

  down do
    alter_table(:filter_statics) do
      add_column :passthrough, FalseClass, :null => false
      drop_column :action
    end
  end
end
