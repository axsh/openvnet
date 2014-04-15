# -*- coding: utf-8 -*-

module Vnet::Models

  class TranslationStaticAddress < Base

    many_to_one :translation
    many_to_one :route_link

    subset(:alives, {})

  end

end
