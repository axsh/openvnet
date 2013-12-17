# -*- coding: utf-8 -*-

module Vnet::Models

  class TranslateStaticAddress < Base

    many_to_one :translation

    subset(:alives, {})

  end

end
