# base image
ARG ARCH=amd64
FROM $ARCH/debian:buster-slim

# environment
ENV ADMIN_PASSWORD=admin

# labels
LABEL maintainer="YangJfei" \
  org.label-schema.schema-version="1.0" \
  org.label-schema.name="yangjifei/cups-qnap-hplip-plugin" \
  org.label-schema.description="Simple CUPS docker image" \
  org.label-schema.version="0.1" \
  org.label-schema.url="https://hub.docker.com/r/yangjifei/cups-qnap-hplip-plugin" \
  org.label-schema.vcs-url="https://gitlab.com/yangjifei/docker-cups-qnap-hplip-plugin"

# install packages
RUN apt-get update \
  && apt-get install -y \
  sudo \
  cups \
  cups-bsd \
  cups-filters \
  foomatic-db-compressed-ppds \
  printer-driver-all \
  openprinting-ppds \
  hpijs-ppds \
  hp-ppd \
  hplip \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# add print user
RUN adduser --home /home/admin --shell /bin/bash --gecos "admin" --disabled-password admin \
  && adduser admin sudo \
  && adduser admin lp \
  && adduser admin lpadmin

# disable sudo password checking
RUN echo 'admin ALL=(ALL:ALL) ALL' >> /etc/sudoers

# enable access to CUPS
RUN /usr/sbin/cupsd \
  && while [ ! -f /var/run/cups/cupsd.pid ]; do sleep 1; done \
  && cupsctl --remote-admin --remote-any --share-printers \
  && kill $(cat /var/run/cups/cupsd.pid) \
  && echo "ServerAlias *" >> /etc/cups/cupsd.conf

# copy /etc/cups for skeleton usage
RUN cp -rp /etc/cups /etc/cups-skel

# add hplip plugin installer
COPY hplip-3.21.12-plugin.run /opt/hplip-3.21.12-plugin.run

RUN echo '#!/bin/bash\n\
set -e\n\
rm -f /var/hp-plugin.lock\n\
echo "Running hp-plugin installer..."\n\
hp-plugin -i -p /opt/hplip-3.21.12-plugin.run\n\
echo "HP Plugin installation completed."\n' > /usr/local/bin/install-hp-plugin.sh && \
    chmod +x /usr/local/bin/install-hp-plugin.sh

# entrypoint
ADD docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT [ "docker-entrypoint.sh" ]

# default command
CMD ["cupsd", "-f"]

# volumes
VOLUME ["/etc/cups"]

# ports
EXPOSE 631