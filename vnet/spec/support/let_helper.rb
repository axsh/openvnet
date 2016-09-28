# -*- coding: utf-8 -*-

def let_permutation(lets, permutation, postfix)
  result = lets.select.with_index { |name, index|
    permutation[index]
  }.map { |name, index|
    "#{name}#{postfix}"
  }
end

def let_context(permutation, let_ids: [])
  result = let_permutation(let_ids, permutation, '.id')

  if result.empty?
    'no lets'
  else
    result.join(' and ')
  end
end
