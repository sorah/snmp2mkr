require 'yaml'
require 'snmp2mkr/config_types/root'

module Snmp2mkr
  class Config
    def self.from_yaml(yaml)
      self.new YAML.load(yaml)
    end

    def initialize(hash)
      @root = ConfigTypes::Root.new(hash)
    end

    def hosts
      @root.hosts
    end

    def templates
      @root.templates
    end

    def persist_file
      @root.persist_file
    end

    def api_key
      @root.api_key
    end
  end
end
