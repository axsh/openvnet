# -*- coding: utf-8 -*-

shared_examples 'delete items on service manager' do |item_names|
  permutations_bool(item_names.size).each { |permutation|
    context permutation_context(item_names, permutation) do

      [:before, :after].each { |created_when|
        it "was created #{created_when} do_initialize" do
          case created_when
          when :before
            item_models
          when :after
          else
            raise "Invalid create_when '#{created_when.inspect}'"
          end

          vnet_info.start_managers([manager])

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