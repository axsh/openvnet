# -*- coding: utf-8 -*-

# TODO: Make permutations a real class with proper enumerators.

# TODO: Add permutations generators that creates fewer permutations to
# reduce the runtime of specs. E.g. allow parameters that hints at
# what kind of permutations we wish to have.

def permutations_bool(size)
  [false, true].repeated_permutation(size)
end

def permutation_select(enumerable, permutation)
  enumerable.each_with_index.select { |item, index|
    permutation[index]
  }.map { |item, index|
    item
  }
end

def permutation_reject(enumerable, permutation)
  enumerable.each_with_index.reject { |item, index|
    permutation[index]
  }.map { |item, index|
    item
  }
end

def permutation_each(enumerable, permutation, &block)
  enumerable.each_with_index.map { |item, index|
    yield item, permutation[index]
  }
end

def permutation_names(names, permutation, prefix: nil, postfix: nil)
  permutation_select(names, permutation).map { |name|
    "#{prefix}#{name}#{postfix}"
  }
end

def permutation_context(names, permutation, prefix: nil, postfix: nil, join_string: ', ', empty_string: 'none')
  permutation_names(names, permutation, postfix: postfix, prefix: prefix).tap { |results|
    return empty_string if results.empty?
  }.join(join_string)
end
