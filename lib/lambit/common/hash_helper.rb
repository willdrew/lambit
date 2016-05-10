# encoding: UTF-8

module Lambit
  module Common
    module HashHelper
      refine ::Hash do
        def symbolize_keys
          self.each_with_object({}){|(k,v), h| h[k.to_sym] = v}
        end

        def symbolize_keys_deep
          h = self.symbolize_keys
          h.each do |k, v|
            if v.respond_to?(:has_key?)
              h[k.to_sym] = v.symbolize_keys_deep
            elsif v.respond_to?(:each)
              v.each_with_index do |item, index|
                if item.respond_to?(:has_key?)
                  v[index] = item.symbolize_keys_deep
                else
                  v[index] = item
                end
              end
            end
          end
        end

        def difference(other)
          reject do |k,v|
            other.has_key? k
          end
        end

        def self.recursive_merge!(other_hash)
          other_hash.each_pair do |k, v|
            cur_val = self[k]
            if cur_val.is_a?(Hash) && v.is_a?(Hash)
              self[k] = recursive_merge!(cur_val, v)
            elsif !v.nil?
              self[k] = v
            end
          end
          self
        end
      end
    end
  end
end
