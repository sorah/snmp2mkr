FROM quay.io/sorah/rbenv:2.3
MAINTAINER sorah.jp

RUN /bin/echo -e '#!/bin/bash\ncd /opt/snmp2mkr && exec bundle exec bin/snmp2mkr "$@"' > /usr/bin/snmp2mkr
RUN chmod +x /usr/bin/snmp2mkr

RUN mkdir -p /opt/snmp2mkr/lib/snmp2mkr
RUN mkdir /var/lib/snmp2mkr
WORKDIR /opt/snmp2mkr

ADD Gemfile /opt/snmp2mkr
ADD lib/snmp2mkr/version.rb /opt/snmp2mkr/lib/snmp2mkr
ADD snmp2mkr.gemspec /opt/snmp2mkr
RUN bundle install --jobs=3 --retry=3

ADD . /opt/snmp2mkr/

ENV LANG en_US.UTF-8

CMD ["/usr/bin/snmp2mkr", "start", "-C", "-c", "/var/lib/snmp2mkr/config.yml", "-l", "debug"]
