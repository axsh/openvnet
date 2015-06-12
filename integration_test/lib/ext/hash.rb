class Hash
  def symbolize_keys
    inject({}) do |options, (key, value)|
      value = case value
      when Array
        value.map{|v| v.is_a?(Hash) ? v.symbolize_keys : v }
      when Hash
        value.symbolize_keys
      else
        value
      end
      options[(key.to_sym rescue key) || key] = value
      options
    end
  end
end
