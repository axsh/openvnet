# -*- coding: utf-8 -*-

module Vnspec
  module ParallelModule

    def each
      all.each { |vm| yield vm }
    end

    def parallel_each(&block)
      Parallel.each(all, &block)
    end

    def parallel_all?(&block)
      result = true

      Parallel.each(all) { |item|
        success = false unless block.call(item)
      }
      result
    end

  end
end
