require 'optparse'
require 'snmp2mkr/config'
require 'snmp2mkr/engine'

module Snmp2mkr
  class Cli
    def initialize(argv)
      @argv = argv.dup
    end

    attr_reader :argv

    def run
      case @argv.shift
      when 'start'
        do_start
        return 0
      when 'test'
        raise NotImplementedError
      when 'import'
        raise NotImplementedError
      else
      end
    end

    def do_start
      parse_argv
      engine = Engine.new(config, log_level: options[:log_level])
      engine.run!
    end

    def parse_argv
      optparse.parse(argv).tap do
        Dir.chdir(File.dirname(options[:config])) if options[:config_chdir]
      end
    end

    def optparse
      @optparse ||= OptionParser.new do |opt|
        opt.on('-c YAML', '--config YAML', 'specify configuration file (default ./config.yml)') do |path|
          options[:config] = path
        end

        opt.on('-C', '--chdir-config-dir', 'chdir working directory to same as configuration file (default false)') do |path|
          options[:config_chdir] = true
        end

        opt.on('-c YAML', '--config YAML', 'specify configuration file (default ./config.yml)') do |path|
          options[:config] = path
        end

        opt.on('-l LOGLEVEL', '--log-level LOGLEVEL', 'log level (default "info")') do |l|
          options[:log_level] = l
        end
      end
    end

    def options
      @options ||= {
        log_level: 'info',
        config: './config.yml',
        config_chdir: false,
      }
    end

    def config
      @config ||= Snmp2mkr::Config.from_yaml(File.read(options[:config]))
    end
  end
end
