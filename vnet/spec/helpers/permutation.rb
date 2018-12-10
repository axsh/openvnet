# -*- coding: utf-8 -*-

def all_permutations_generate(a, p, &block)
  a.shift { |k|
    if k.nil?
      yield p
    else
      k.each { |v|
        p.push(v)
        all_permutations_generate(a, p, &block)
        p.pop
      }
    end
  }
  a.unshift
end

def all_permutations(a, &block)
  all_permutations_generate(a.dup, [], &block)
end
