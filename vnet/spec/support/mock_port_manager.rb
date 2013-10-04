# -*- coding: utf-8 -*-
class MockPortManager < Vnet::Openflow::PortManager

  def ports
    @items
  end

end
