# Snmp2mkr: Send SNMP values to Mackerel

[![CircleCI](https://circleci.com/gh/sorah/snmp2mkr.svg?style=svg)](https://circleci.com/gh/sorah/snmp2mkr)

## Features

- Collect SNMP values then send it to Mackerel
- Supports sending values in indivisual hosts (e.g. Create host on mackerel for each wi-fi access points)

## Installation

### Rubygems

Add this line to your application's Gemfile:

```ruby
gem 'snmp2mkr'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install snmp2mkr

### Docker image

https://quay.io/repository/sorah/snmp2mkr

`/var/lib/snmp2mkr/config.yml` is loaded by default. It's recommended to give a volume (`-v /somewhere:/var/lib/snmp2mkr`) then place config.yml, and let snmp2mkr allow to write `persist_file` there.

#### Tags

- commit: `quay.io/sorah/snmp2mkr:{GIT_COMMIT_SHA}`
- master: `quay.io/sorah/snmp2mkr:master`
- released version: `quay.io/sorah/snmp2mkr:v0.1.0`


## Usage

### Configuration

``` yaml
api_key: ...
persist_file: ...

templates:
  if-mib:
    metric_discoveries:
      interface:
        keys:
          ifDescr: 'IF-MIB::ifDescr'
        metrics:
          "interface.#{ifDescr}.rxBytes": "IF-MIB::ifInOctets.#{index}"
          "interface.#{ifDescr}.txBytes": "IF-MIB::ifOutOctets.#{index}"
          "interface.#{ifDescr}.rxBytes.delta":
            oid: "IF-MIB::ifInOctets.#{index}"
            transformations:
              - type: persec
          "interface.#{ifDescr}.txBytes.delta":
            oid: "IF-MIB::ifOutOctets.#{index}"
            transformations:
              - type: persec

hosts:
  rt01:
    host: 192.168.1.1
    port: 161
    discovery_interval: 120
    interval: 60
    snmp:
      verison: 2c
      community: public
    templates:
      - if-mib
```

See [./examples](./examples) directory for detail

### Running

```
snmp2mkr start -c ./config.yml
```

### Test discovery

```
snmp2mkr test -c ./config.yml
```

### Importing MIB files

```
snmp2mkr import -t ./mib CISCO-PROCESS-MIB.mib
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sorah/snmp2mkr.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

