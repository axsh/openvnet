# -*- coding: utf-8 -*-

module Vnspec
  module ParallelModule

    def parallel_each(&block)
      Parallel.each(all, &block)
    end

    def parallel_all?(&block)
      result = true

      Parallel.each(all) { |vm|
        success = false unless block.call(vm)
      }
      result
    end

  end
end
