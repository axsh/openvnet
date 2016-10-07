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

def permutation_context(permutation, names, postfix = '')
  result = let_permutation(names, permutation, postfix)

  if result.empty?
    'none'
  else
    result.join(' and ')
  end
end
