# -*- coding: utf-8 -*-

shared_examples 'delete items on service manager' do |item_names|
  describe "delete items from #{item_names.join(', ')}" do
    failed_permutation = nil

    # We always complete all tests in a permutation even if one of
    # them fails. This allows us to see if they all fail or just a
    # few.
    around(:each) do |example|
      if failed_permutation
        next failed_permutation == current_permutation ? example.run : example.skip
      end

      # puts "current_permutation for context #{current_permutation}"

      failed_permutation = current_permutation
      example.run
      failed_permutation = nil if example.exception.nil?
    end

    permutations_bool(item_names.size).each { |permutation|
      context "where #{permutation_context(item_names, permutation)} is deleted" do

        let(:current_permutation) { permutation }

        [:before, :after].each { |created_when|
          it "with items created #{created_when} do_initialize" do
            case created_when
            when :before
              item_models
            when :after
            else
              raise "Invalid create_when '#{created_when.inspect}'"
            end

            vnet_info.initialize_manager_list([manager], 10, 5)

            item_models.each { |item_model|
              expect(manager).to be_manager_with_loaded(item_model)
            }

            permutation_select(item_models, permutation).each { |item_model|
              item_model.destroy
              publish_item_deleted_event(manager, item_model)
            }

            expect(manager).to be_manager_with_item_count(permutation.count(false))

            permutation_each(item_models, permutation) { |item_model, deleted|
              if deleted
                expect(manager).to be_manager_with_unloaded(item_model)
              else
                expect(manager).to be_manager_with_loaded(item_model)
              end
            }
          end
        }

      end
    }
  end
end
