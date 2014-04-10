# -*- coding: utf-8 -*-

module Vnet::Models

  class TranslationStaticAddress < Base

    many_to_one :translation

    subset(:alives, {})

  end

end
