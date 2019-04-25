FROM ruby:2.6.2-alpine
Label maintainer="myprogramingnotes@gmail.com"


#################################################### Make GOSU WORK ####################################################
ENV GOSU_VERSION 1.11
RUN set -eux; \
  \
  apk add --no-cache --virtual .gosu-deps \
    dpkg \
    gnupg \
  ; \
  \
  dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
  wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch"; \
  wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc"; \
  \
# verify the signature
  export GNUPGHOME="$(mktemp -d)"; \
# for flaky keyservers, consider: 
# https://github.com/tianon/pgp-happy-eyeballs, 
# also https://github.com/docker-library/php/pull/666
  gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
  gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu; \
  command -v gpgconf && gpgconf --kill all || :; \
  rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc; \
  \
# clean up fetch dependencies
  apk del --no-network .gosu-deps; \
  \
  chmod +x /usr/local/bin/gosu; \
# verify that the binary works
  gosu --version; \
  gosu nobody true
########################################################################################################################

WORKDIR /srv/app
COPY ./Gemfile ./Gemfile.lock /srv/app/
RUN bundle install --without development test
COPY ./lib /srv/app/lib/ 
COPY ./kanayo.rb /srv/app 
RUN mv kanayo.rb kanayo
RUN ln -s $PWD/kanayo /usr/local/bin/
RUN chmod +x kanayo

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
