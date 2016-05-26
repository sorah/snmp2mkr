# Snmp2mkr: Send SNMP values to Mackerel

## Features

- Collect SNMP values then send it to Mackerel
- Supports sending values in indivisual hosts (e.g. Create host on mackerel for each wi-fi access points)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'snmp2mkr'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install snmp2mkr

## Usage

### Configuration

``` yaml
api_key: ... # EnvString
#  env: MKR_API_KEY
persist_file: ... # EnvString
templates: # TemplateCollection
  router: # Template
    templates: # TemplatesList
      - cisco-841
  wlc: # Template
    templates: # TemplatesList
      - system-mib
      - if-mib
      - ip-mib
      - airespace-wireless-mib_ap-as-metrics

  cisco-841: # Template
    templates: # TemplatesList
      - system-mib
      - if-mib
      - ip-mib

  system-mib: # Template
    meta: # MetaDefinition
      keys:
        sysdescr: 'SNMPv2-MIB::system.sysDescr.0' # oidstring
      values:
        sysdescr: '#{sysdescr}' # ValueDefinition
  if-mib: # Template
    interfaces: # InterfacesDefinition
      keys:
        ifDescr: 'IF-MIB::ifDescr' # Oid
      match:
        ifIndex: '#{index}' # TemplateString
      values:
        name: '#{ifDescr}' # ValueDefinition
    metric_discoveries: # MetricDiscoveryRuleCollection
      interface: # MetricDiscoveryRule
        keys:
          ifDescr: 'IF-MIB::ifDescr' # Oid
        metrics:
          "interface.#{ifDescr}.rxBytes": "IF-MIB::ifInOctets.#{index}" # MetricDefinition
          "interface.#{ifDescr}.txBytes": "IF-MIB::ifOutOctets.#{index}" # MetricDefinition
          "interface.#{ifDescr}.rxBytes.delta": # MetricDefinition
            oid: "IF-MIB::ifInOctets.#{index}" # Oid
            transformations: # TransformSpecificationList
              - type: persec # TransformSpecification
          "interface.#{ifDescr}.txBytes.delta": # MetricDefinition
            oid: "IF-MIB::ifOutOctets.#{index}" # Oid
            transformations: # Transformspecification
              - type: persec # TransformSpeccifiation
  ip-mib: # Template
    interfaces: # InterfacesDefinition
      keys:
        ipAdEntIfIndex: 'IP-MIB::ipAdEntIfIndex' # Oid
        ipAdEntAddr: 'IP-MIB::ipAdEntIfAddr' # Oid
      match:
        ifIndex: '#{ipAdEntIfIndex}' # TemplateString
      values:
        ipv4Addresses: # ValueDefinition
          type: array_append
          value: '#{ipAdEntAddr}' # TemplateString

  airespace-wireless-mib_ap-as-metrics: # Template
    metric_discoveries: # MetricDiscoveryRuleCollection
      ap: # MetricDiscoveryRule
        keys:
          bsnAPName: 'AIRESPACE-WIRELESS-MIB::bsnAPName' # Oid
        metrics:
          "custom.wlc.ap.#{bsnAPName}.clients.2_4.count": 'AIRESPACE-WIRELESS-MIB::bsnApIfNoOfUsers.#{index}.0' # MetricDefinition
          "custom.wlc.ap.#{bsnAPName}.clients.5.count": 'AIRESPACE-WIRELESS-MIB::bsnApIfNoOfUsers.#{index}.1' # MetricDefinition

  airespace-wireless-mib_ap-as-hosts:
    vhost_discoveries: # VhostsDiscoveryRuleCollection
      ap: # VhostDiscoveryRule
        keys:
          bsnAPName: 'AIRESPACE-WIRELESS-MIB::bsnAPName' # Oid
        name: 'ap-#{bsnAPName}' # TemplateString
        roles:
          - aaa:bbb
        metrics:
          "custom.ap.clients.2_4.count": 'AIRESPACE-WIRELESS-MIB::bsnApIfNoOfUsers.#{index}.0' # MetricDefinition
          "custom.ap.clients.5.count": 'AIRESPACE-WIRELESS-MIB::bsnApIfNoOfUsers.#{index}.1' # MetricDefinition

  airespace-wireless-mib_ess:
    metric_discoveries: # MetricDiscoveryRuleCollection
      ap:
        keys:
          bsnDot11EssSsid: 'AIRESPACE-WIRELESS-MIB::bsnDot11EssSsid'
        metrics:
          "custom.wlc.ess.#{bsnDot11EssSsid}.clients.count": 'AIRESPACE-WIRELESS-MIB::bsnDot11EssNumberOfMobileStations.#{index}'


hosts:
  router-001:
    host: 192.168.10.1
    snmp:
      version: 2c
      community: public
      #  env: SNMP_COMMUNITY
    templates:
      - router
# templates_dir: # load from indivisual files
# hosts_dir: 
```

### Running

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/snmp2mkr.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

