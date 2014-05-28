# -*- coding: utf-8 -*-
class MockPortManager < Vnet::Core::PortManager

  def ports
    @items
  end

end
