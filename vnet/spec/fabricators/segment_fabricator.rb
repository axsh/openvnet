# -*- coding: utf-8 -*-

Fabricator(:segment, class_name: Vnet::Models::Segment) do
  id { id_sequence(:segment_ids) }
end
