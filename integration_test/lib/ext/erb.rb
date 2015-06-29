# -*- coding: utf-8 -*-
class ERB
  def result_hash(hash)
    b = binding
    eval(hash.collect{|k,v| "#{k} = hash[#{k.inspect}];" }.join, b)
    result b
  end
end
