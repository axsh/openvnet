# -*- coding: utf-8 -*-

def legacy
  Vnspec::Legacy
end

def setup_legacy_machine
  legacy.setup
end

[:legacy1, :legacy_esxi].each do |name|
  define_method(name) do
    legacy[name]
  end
end
