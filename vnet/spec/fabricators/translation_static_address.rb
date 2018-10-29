Fabricator(:translation_static_address, class_name: Vnet::Models::TranslationStaticAddress) do
  id { id_sequence(:translation_static_address_ids) }
end

