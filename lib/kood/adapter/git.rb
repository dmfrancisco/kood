require 'adapter-git'

module Adapter
  # This reopens the git adapter module and changes part of its behavior.
  #
  # It adds support for custom file extensions. Like the original git adapter, data is
  # persisted in YAML but, if there is a key named `content`, then the content will be
  # saved in plain text and a YAML front matter block is added to the top of the file.
  #
  module Git
    attr_accessor :file_extension

    # Transform a key into a filename
    # @return [String] the name of the file
    def key_for(key)
      key = super + "." + (@file_extension || 'yml')
      File.join(*[options[:path], key].compact)
    end

    # Encode data to be written
    # @return [String] data in `yaml` format or `yaml frontmatter + text`
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

    # Decode data to be read
    # @return [Hash] data
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
