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
api_key: ...
#  env: MKR_API_KEY
templates:
  router:
    templates:
      - cisco-841
  wlc:
    templates:
      - system-mib
      - if-mib
      - ip-mib
      - airespace-wireless-mib_ap-as-metrics

  cisco-841:
    templates:
      - system-mib
      - if-mib
      - ip-mib

  system-mib:
    meta:
      sysdescr: 'SNMPv2-MIB::system.sysDescr.0'
  if-mib:
    interfaces:
      keys:
        ifDescr: 'IF-MIB::ifDescr'
      match:
        ifIndex: '#{index}'
      values:
        name: '#{ifDescr}'
    metrics_discovery:
      interface:
        keys:
          ifDescr: 'IF-MIB::ifDescr'
        metrics:
          "#{name}.rxBytes": "IF-MIB::ifInOctets.#{index}"
          "#{name}.txBytes": "IF-MIB::ifOutOctets.#{index}"
          "interface.#{name}.rxBytes.delta":
            oid: "IF-MIB::ifInOctets.#{index}"
            transform:
              - type: persec
          "interface.#{name}.txBytes.delta":
            oid: "IF-MIB::ifOutOctets.#{index}"
            transform:
              - type: persec
  ip-mib:
    interfaces:
      keys:
        ipAdEntIfIndex: 'IP-MIB::ipAdEntIfIndex'
        ipAdEntAddr: 'IP-MIB::ipAdEntIfAddr'
      match:
        ifIndex: '#{ipAdEntIfIndex}'
      values:
        ipv4Addresses:
          type: append_array
          value: '#{ipAdEntAddr}'

  airespace-wireless-mib_ap-as-metrics:
    metrics_discovery:
      ap:
        keys:
          bsnAPName: 'AIRESPACE-WIRELESS-MIB::bsnAPName'
        metrics:
          "custom.wlc.ap.#{bsnAPName}.clients.2_4.count": 'AIRESPACE-WIRELESS-MIB::bsnApIfNoOfUsers.#{index}.0'
          "custom.wlc.ap.#{bsnAPName}.clients.5.count": 'AIRESPACE-WIRELESS-MIB::bsnApIfNoOfUsers.#{index}.1'

  airespace-wireless-mib_ap-as-hosts:
    vhosts_discovery:
      ap:
        keys:
          bsnAPName: 'AIRESPACE-WIRELESS-MIB::bsnAPName'
        name: 'ap-#{bsnAPName}'
        roles:
          - aaa:bbb
        metrics:
          "custom.ap.clients.2_4.count": 'AIRESPACE-WIRELESS-MIB::bsnApIfNoOfUsers.#{index}.0'
          "custom.ap.clients.5.count": 'AIRESPACE-WIRELESS-MIB::bsnApIfNoOfUsers.#{index}.1'

  airespace-wireless-mib_ess:
    metrics_discovery:
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

