require 'user_config'

module Adapter
  module UserConfigFile
    def read(key, options = nil)
      config[key]
    end

    def write(key, attributes, options = nil)
      config[key] = attributes
      config.save
    end

    def delete(key, options = nil)
      config.delete(key)
      config.save
    end

    def clear(options = nil)
      config.clear
      config.save
    end

    private

    def config
      @@conf ||= UserConfig.new Kood::KOOD_PATH
      @@conf[Kood.config_path]
    end
  end
end

Adapter.define(:user_config, Adapter::UserConfigFile)
