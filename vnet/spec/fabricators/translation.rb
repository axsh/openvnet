Fabricator(:translation, class_name: Vnet::Models::Translation) do
  id { id_sequence(:translation_ids) }
  mode 'static_address'
end
