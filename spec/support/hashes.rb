RSpec::Matchers.define :include_json do |expected|
  def included?(hash, expected)
    hash.symbolize_keys!
    expected.symbolize_keys!

    included = []
    expected.each do |key, value|
      included << if !hash.include?(key)
        false
      elsif value.is_a? Hash
        included?(hash[key], value)
      elsif value.is_a? Array
        # For the simple case that I'm testing I can assume that
        # array will just contain hashes and that all of the hashes
        # from expected array are included in one of the hashes from
        # original array
        value.all? { |v|
          v.is_a?(Hash) && hash[key].any? { |h| included?(h, v) }
        }
      else
        hash[key] == value
      end
    end

    included.all? { |i| i }
  end

  match do |json|
    json = JSON.parse(json) unless json.is_a?(Hash)

    included?(json, expected)
  end
end
