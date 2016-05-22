require 'spec_helper'
require 'snmp2mkr/config'

require 'snmp2mkr/config_types/base'

require 'snmp2mkr/config_types/env_string'
require 'snmp2mkr/config_types/template_string'
require 'snmp2mkr/config_types/raw_string'

require 'snmp2mkr/config_types/oid'

require 'snmp2mkr/config_types/template'
require 'snmp2mkr/config_types/templates_list'
require 'snmp2mkr/config_types/template_collection'

require 'snmp2mkr/config_types/metric_definition'
require 'snmp2mkr/config_types/metric_definition_collection'

require 'snmp2mkr/config_types/metric_discovery_rule'
require 'snmp2mkr/config_types/metric_discovery_rule_collection'

require 'snmp2mkr/config_types/transformation'

require 'snmp2mkr/config_types/meta_definition'

require 'snmp2mkr/config_types/value_definition'

require 'snmp2mkr/config_types/interfaces_definition'

require 'snmp2mkr/config_types/vhost_discovery_rule'
require 'snmp2mkr/config_types/vhost_discovery_rule_collection'

require 'snmp2mkr/config_types/host_definition'
require 'snmp2mkr/config_types/host_collection'

require 'snmp2mkr/config_types/host_snmp_definition'

describe Snmp2mkr::Config do
  let(:yaml) { <<-'EOF' }
api_key: apikey # EnvString
persist_file: persist # EnvString
templates: # TemplateCollection
  a: # Template
    templates: # TemplatesList
      - template0
      - metadef
      - interfacedef
      - metricsdiscoverydef
      - vhostsdiscoverydef

  template0: # Template
    templates: # TemplatesList
      - metricsdef

  metricsdef:
    metrics: # MetricsDefinitionCollection
      "custom.snmp1": "IF-MIB::ifInOctets.1" # MetricDefinition
      "custom.snmp2": # MetricDefinition
        oid: "IF-MIB::ifInOctets.1" # Oid
        transformations:
          - type: persec # Transformation

  metadef: # Template
    meta: # MetaDefinition
      keys:
        sysdescr: 'SNMPv2-MIB::system.sysDescr.0' # Oid
      values:
        sysdescr: '#{sysdescr}' # ValueDefinition

  interfacedef: # Template
    interfaces: # InterfacesDefinition
      keys:
        ifDescr: 'IF-MIB::ifDescr' # Oid
      match:
        ifIndex: '#{index}' # TemplateString
      values:
        name: '#{ifDescr}' # ValueDefinition

  interfacedef2: # Template
    interfaces: # InterfacesDefinition
      keys:
        ipAdEntIfIndex: 'IP-MIB::ipAdEntIfIndex' # Oid
      match:
        ifIndex: '#{ipAdEntIfIndex}' # TemplateString
      values:
        ipv4Addresses: # ValueDefinition
          type: array_append
          value: '#{ipAdEntAddr}' # TemplateString

  metricsdiscoverydef:
    metric_discoveries: # MetricDiscoveryRuleCollection
      metricsdisc: # MetricDiscoveryRule
        keys:
          ifDescr: 'IF-MIB::ifDescr' # Oid
        metrics:
          "interface.#{ifDescr}.txBytes": "IF-MIB::ifOutOctets.#{index}" # MetricDefinition
          "interface.#{ifDescr}.txBytes.delta": # MetricDefinition
            oid: "IF-MIB::ifOutOctets.#{index}" # Oid
            transformations: # TransformSpecificationList
              - type: persec # TransformSpecification

  vhostdiscoverydef:
    vhost_discoveries: # VhostDiscoveryRuleCollection
      vhostsdisc: # VhostDiscoveryRule
        keys:
          bsnAPName: 'AIRESPACE-WIRELESS-MIB::bsnAPName' # Oid
        name: 'ap-#{bsnAPName}' # TemplateString
        roles:
          - aaa:bbb # TemplateString
        metrics: # MetricsDefinitionCollection
          "custom.ap.clients.2_4.count": 'AIRESPACE-WIRELESS-MIB::bsnApIfNoOfUsers.#{index}.0' # MetricDefinition

hosts: # HostCollection
  host01: # HostDefinition
    host: 192.168.10.1
    snmp: # HostSnmpDefinition
      version: 2c
      community: public # EnvString
      #  env: SNMP_COMMUNITY
    templates: # TemplatesList
      - a
  EOF

  subject(:config) { Snmp2mkr::Config.from_yaml(yaml) }

  specify do
    expect(config.api_key).to be_a(Snmp2mkr::ConfigTypes::EnvString)
    expect(config.api_key.value).to eq 'apikey'
  end

  specify do
    expect(config.persist_file).to be_a(Snmp2mkr::ConfigTypes::EnvString)
    expect(config.persist_file.value).to eq 'persist'
  end

  specify do
    expect(config.templates).to be_a(Snmp2mkr::ConfigTypes::TemplateCollection)
    expect(config.templates['template0']).to be_a(Snmp2mkr::ConfigTypes::Template)
  end

  specify do
    expect(config.templates).to be_a(Snmp2mkr::ConfigTypes::TemplateCollection)
    expect(config.templates['template0']).to be_a(Snmp2mkr::ConfigTypes::Template)
  end

  specify do
    expect(config.templates['template0'].templates).to be_a(Snmp2mkr::ConfigTypes::TemplatesList)
    expect(config.templates['template0'].templates.evaluate).to eq(%w(metricsdef))
  end

  specify do
    expect(config.templates['metricsdef'].metrics).to be_a(Snmp2mkr::ConfigTypes::MetricDefinitionCollection)

    expect(config.templates['metricsdef'].metrics['custom.snmp1']).to be_a(Snmp2mkr::ConfigTypes::MetricDefinition)
    expect(config.templates['metricsdef'].metrics['custom.snmp1'].name).to be_a(Snmp2mkr::ConfigTypes::TemplateString)
    expect(config.templates['metricsdef'].metrics['custom.snmp1'].name.value).to eq('custom.snmp1')
    expect(config.templates['metricsdef'].metrics['custom.snmp1'].oid).to be_a(Snmp2mkr::ConfigTypes::Oid)
    expect(config.templates['metricsdef'].metrics['custom.snmp1'].oid.evaluate).to eq('IF-MIB::ifInOctets.1')

    expect(config.templates['metricsdef'].metrics['custom.snmp2']).to be_a(Snmp2mkr::ConfigTypes::MetricDefinition)
    expect(config.templates['metricsdef'].metrics['custom.snmp2'].oid).to be_a(Snmp2mkr::ConfigTypes::Oid)
    expect(config.templates['metricsdef'].metrics['custom.snmp2'].oid.evaluate).to eq('IF-MIB::ifInOctets.1')

    expect(config.templates['metricsdef'].metrics['custom.snmp2'].transformations).to be_a(Array)
    expect(config.templates['metricsdef'].metrics['custom.snmp2'].transformations[0]).to be_a(Snmp2mkr::ConfigTypes::Transformation)
    expect(config.templates['metricsdef'].metrics['custom.snmp2'].transformations[0].type).to eq 'persec'
  end

  specify do
    expect(config.templates['metadef'].meta).to be_a(Snmp2mkr::ConfigTypes::MetaDefinition)

    expect(config.templates['metadef'].meta.keys['sysdescr']).to be_a(Snmp2mkr::ConfigTypes::Oid)
    expect(config.templates['metadef'].meta.keys['sysdescr'].evaluate).to eq('SNMPv2-MIB::system.sysDescr.0')

    expect(config.templates['metadef'].meta.values['sysdescr']).to be_a(Snmp2mkr::ConfigTypes::ValueDefinition)
    expect(config.templates['metadef'].meta.values['sysdescr'].type).to eq('string')
    expect(config.templates['metadef'].meta.values['sysdescr'].value).to be_a(Snmp2mkr::ConfigTypes::TemplateString)
    expect(config.templates['metadef'].meta.values['sysdescr'].value.value).to eq('#{sysdescr}')
  end

  specify do
    expect(config.templates['interfacedef'].interfaces).to be_a(Snmp2mkr::ConfigTypes::InterfacesDefinition)

    expect(config.templates['interfacedef'].interfaces.keys['ifDescr']).to be_a(Snmp2mkr::ConfigTypes::Oid)
    expect(config.templates['interfacedef'].interfaces.keys['ifDescr'].evaluate).to eq('IF-MIB::ifDescr')

    expect(config.templates['interfacedef'].interfaces.match['ifIndex']).to be_a(Snmp2mkr::ConfigTypes::TemplateString)
    expect(config.templates['interfacedef'].interfaces.match['ifIndex'].value).to eq('#{index}')

    expect(config.templates['interfacedef'].interfaces.values['name']).to be_a(Snmp2mkr::ConfigTypes::ValueDefinition)
    expect(config.templates['interfacedef'].interfaces.values['name'].type).to eq('string')
    expect(config.templates['interfacedef'].interfaces.values['name'].value).to be_a(Snmp2mkr::ConfigTypes::TemplateString)
    expect(config.templates['interfacedef'].interfaces.values['name'].value.value).to eq('#{ifDescr}')
  end

  specify do
    expect(config.templates['metricsdiscoverydef'].metric_discoveries).to be_a(Snmp2mkr::ConfigTypes::MetricDiscoveryRuleCollection)
    expect(config.templates['metricsdiscoverydef'].metric_discoveries['metricsdisc']).to be_a(Snmp2mkr::ConfigTypes::MetricDiscoveryRule)

    expect(config.templates['metricsdiscoverydef'].metric_discoveries['metricsdisc'].keys['ifDescr']).to be_a(Snmp2mkr::ConfigTypes::Oid)
    expect(config.templates['metricsdiscoverydef'].metric_discoveries['metricsdisc'].keys['ifDescr'].evaluate).to eq('IF-MIB::ifDescr')

    expect(config.templates['metricsdiscoverydef'].metric_discoveries['metricsdisc'].metrics).to be_a(Snmp2mkr::ConfigTypes::MetricDefinitionCollection)

    expect(config.templates['metricsdiscoverydef'].metric_discoveries['metricsdisc'].metrics['interface.#{ifDescr}.txBytes']).to be_a(Snmp2mkr::ConfigTypes::MetricDefinition)
    expect(config.templates['metricsdiscoverydef'].metric_discoveries['metricsdisc'].metrics['interface.#{ifDescr}.txBytes'].name).to be_a(Snmp2mkr::ConfigTypes::TemplateString)
    expect(config.templates['metricsdiscoverydef'].metric_discoveries['metricsdisc'].metrics['interface.#{ifDescr}.txBytes'].name.value).to eq 'interface.#{ifDescr}.txBytes'
    expect(config.templates['metricsdiscoverydef'].metric_discoveries['metricsdisc'].metrics['interface.#{ifDescr}.txBytes'].oid).to be_a(Snmp2mkr::ConfigTypes::Oid)
    expect(config.templates['metricsdiscoverydef'].metric_discoveries['metricsdisc'].metrics['interface.#{ifDescr}.txBytes'].oid.value).to be_a(Snmp2mkr::ConfigTypes::TemplateString)
    expect(config.templates['metricsdiscoverydef'].metric_discoveries['metricsdisc'].metrics['interface.#{ifDescr}.txBytes'].oid.value.value).to eq 'IF-MIB::ifOutOctets.#{index}'

    expect(config.templates['metricsdiscoverydef'].metric_discoveries['metricsdisc'].metrics['interface.#{ifDescr}.txBytes.delta']).to be_a(Snmp2mkr::ConfigTypes::MetricDefinition)
    expect(config.templates['metricsdiscoverydef'].metric_discoveries['metricsdisc'].metrics['interface.#{ifDescr}.txBytes.delta'].name).to be_a(Snmp2mkr::ConfigTypes::TemplateString)
    expect(config.templates['metricsdiscoverydef'].metric_discoveries['metricsdisc'].metrics['interface.#{ifDescr}.txBytes.delta'].name.value).to eq 'interface.#{ifDescr}.txBytes.delta'
    expect(config.templates['metricsdiscoverydef'].metric_discoveries['metricsdisc'].metrics['interface.#{ifDescr}.txBytes.delta'].oid).to be_a(Snmp2mkr::ConfigTypes::Oid)
    expect(config.templates['metricsdiscoverydef'].metric_discoveries['metricsdisc'].metrics['interface.#{ifDescr}.txBytes.delta'].oid.value).to be_a(Snmp2mkr::ConfigTypes::TemplateString)
    expect(config.templates['metricsdiscoverydef'].metric_discoveries['metricsdisc'].metrics['interface.#{ifDescr}.txBytes.delta'].oid.value.value).to eq 'IF-MIB::ifOutOctets.#{index}'
    expect(config.templates['metricsdiscoverydef'].metric_discoveries['metricsdisc'].metrics['interface.#{ifDescr}.txBytes.delta'].transformations).to be_a(Array)
    expect(config.templates['metricsdiscoverydef'].metric_discoveries['metricsdisc'].metrics['interface.#{ifDescr}.txBytes.delta'].transformations[0]).to be_a(Snmp2mkr::ConfigTypes::Transformation)
    expect(config.templates['metricsdiscoverydef'].metric_discoveries['metricsdisc'].metrics['interface.#{ifDescr}.txBytes.delta'].transformations[0].type).to eq 'persec'
  end

  specify do
    expect(config.templates['vhostdiscoverydef'].vhost_discoveries).to be_a(Snmp2mkr::ConfigTypes::VhostDiscoveryRuleCollection)
    expect(config.templates['vhostdiscoverydef'].vhost_discoveries['vhostsdisc']).to be_a(Snmp2mkr::ConfigTypes::VhostDiscoveryRule)

    expect(config.templates['vhostdiscoverydef'].vhost_discoveries['vhostsdisc'].keys['bsnAPName']).to be_a(Snmp2mkr::ConfigTypes::Oid)
    expect(config.templates['vhostdiscoverydef'].vhost_discoveries['vhostsdisc'].keys['bsnAPName'].evaluate).to eq('AIRESPACE-WIRELESS-MIB::bsnAPName')

    expect(config.templates['vhostdiscoverydef'].vhost_discoveries['vhostsdisc'].name).to be_a(Snmp2mkr::ConfigTypes::TemplateString)
    expect(config.templates['vhostdiscoverydef'].vhost_discoveries['vhostsdisc'].name.value).to eq('ap-#{bsnAPName}')

    expect(config.templates['vhostdiscoverydef'].vhost_discoveries['vhostsdisc'].roles).to be_a(Array)
    expect(config.templates['vhostdiscoverydef'].vhost_discoveries['vhostsdisc'].roles.size).to eq 1
    expect(config.templates['vhostdiscoverydef'].vhost_discoveries['vhostsdisc'].roles[0]).to be_a(Snmp2mkr::ConfigTypes::TemplateString)
    expect(config.templates['vhostdiscoverydef'].vhost_discoveries['vhostsdisc'].roles[0].value).to eq('aaa:bbb')

    expect(config.templates['vhostdiscoverydef'].vhost_discoveries['vhostsdisc'].metrics).to be_a(Snmp2mkr::ConfigTypes::MetricDefinitionCollection)

    expect(config.templates['vhostdiscoverydef'].vhost_discoveries['vhostsdisc'].metrics['custom.ap.clients.2_4.count']).to be_a(Snmp2mkr::ConfigTypes::MetricDefinition)
    expect(config.templates['vhostdiscoverydef'].vhost_discoveries['vhostsdisc'].metrics['custom.ap.clients.2_4.count'].name).to be_a(Snmp2mkr::ConfigTypes::TemplateString)
    expect(config.templates['vhostdiscoverydef'].vhost_discoveries['vhostsdisc'].metrics['custom.ap.clients.2_4.count'].name.value).to eq 'custom.ap.clients.2_4.count'
    expect(config.templates['vhostdiscoverydef'].vhost_discoveries['vhostsdisc'].metrics['custom.ap.clients.2_4.count'].oid).to be_a(Snmp2mkr::ConfigTypes::Oid)
    expect(config.templates['vhostdiscoverydef'].vhost_discoveries['vhostsdisc'].metrics['custom.ap.clients.2_4.count'].oid.value).to be_a(Snmp2mkr::ConfigTypes::TemplateString)
    expect(config.templates['vhostdiscoverydef'].vhost_discoveries['vhostsdisc'].metrics['custom.ap.clients.2_4.count'].oid.value.value).to eq 'AIRESPACE-WIRELESS-MIB::bsnApIfNoOfUsers.#{index}.0'
  end

  specify do
    expect(config.hosts).to be_a(Snmp2mkr::ConfigTypes::HostCollection)
    expect(config.hosts['host01']).to be_a(Snmp2mkr::ConfigTypes::HostDefinition)
    expect(config.hosts['host01'].host).to eq('192.168.10.1')
    expect(config.hosts['host01'].snmp).to be_a(Snmp2mkr::ConfigTypes::HostSnmpDefinition)
    expect(config.hosts['host01'].snmp.version).to eq('2c')
    expect(config.hosts['host01'].snmp.community).to be_a(Snmp2mkr::ConfigTypes::EnvString)
    expect(config.hosts['host01'].snmp.community.value).to eq('public')
    expect(config.hosts['host01'].templates).to be_a(Snmp2mkr::ConfigTypes::TemplatesList)
    expect(config.hosts['host01'].templates.evaluate).to eq(%w(a))
  end
end
