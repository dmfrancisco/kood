require 'kood/adapter/git'
require 'kood/adapter/user_config'
require 'kood/extensions/grit'
require 'kood/errors'
require 'kood/version'

module Kood
  autoload :Card,  'kood/card'
  autoload :List,  'kood/list'
  autoload :Board, 'kood/board'

  require 'kood/cli'
  require 'kood/core'
end
