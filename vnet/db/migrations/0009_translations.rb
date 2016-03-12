# -*- coding: utf-8 -*-

Sequel.migration do
  up do

    create_table(:translation_statics) do
      primary_key :id
      Integer :translation_id, :index => true, :null => false

      String :protocol, :null => false

      Bignum :ingress_address, :null => false
      Bignum :egress_address, :null => false

      Integer :ingress_port
      Integer :egress_port
      
      DateTime :created_at, :null =>false
      DateTime :updated_at, :null =>false
      DateTime :deleted_at, :index => true
      Integer :is_deleted, :null =>false, :default =>0

      unique [:translation_id,
              :protocol,
              :ingress_address,
              :egress_address,
              :ingress_port,
              :egress_port,
              :is_deleted
             ]
    end

  end

  down do
    drop_table(:translation_statics,
              )
  end
end
