module Adapter
  module Git
    attr_accessor :file_extension

    def key_for(key)
      key = super + "." + (@file_extension || 'yml')
      File.join(*[options[:path], key].compact)
    end

    def encode(value)
      # If it contains a `content` attribute, other data is in a YAML front matter block
      if value.key? "content"
        content = value["content"].to_s
        value.delete("content")

        data = value.to_yaml
        data += "---\n\n"
        data += content
        data
      else
        # Standard YAML file
        value.to_yaml
      end
    end

    def decode(value)
      # Check if a YAML front matter block is present
      yaml_regex = /\A(---\s*\n.*?\n?)^(---\s*$\n?)/m
      if value =~ yaml_regex
        content = value.sub(yaml_regex, "")
        data = YAML.load($1)
        data["content"] = content
        data
      else
        # Standard YAML file
        data = YAML.load(value)
      end
    rescue => e
      raise "YAML Exception: #{ e.message }"
    end
  end
end
