# -*- coding: utf-8 -*-

def vms
  Vnspec::VM
end

def setup_vm
  vms.setup
end

(1..7).map{|i| "vm#{i}".to_sym }.each do |name|
  define_method(name) do
    vms[name]
  end
end

