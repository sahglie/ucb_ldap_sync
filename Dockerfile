# syntax=docker/dockerfile:1

ARG RUBY_VERSION=3.1.2

################################################################################
# base
################################################################################
FROM ruby:$RUBY_VERSION-slim-bullseye as base
ENV TZ="US/Pacific"

# Core packages
RUN <<EOF
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
    build-essential \
    gnupg2 \
    bind9-dnsutils \
    curl \
    wget \
    vim \
    git \
    less
apt-get clean
rm -rf /var/cache/apt/archives/*
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
truncate -s 0 /var/log/*log
EOF

# PostgreSQL
ARG PG_MAJOR=14

RUN <<EOF
curl -sSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /usr/share/keyrings/postgres-archive-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/postgres-archive-keyring.gpg] https://apt.postgresql.org/pub/repos/apt/" \
  bullseye-pgdg main $PG_MAJOR | tee /etc/apt/sources.list.d/postgres.list > /dev/null
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get -yq dist-upgrade
DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
  libpq-dev \
  postgresql-client-$PG_MAJOR
apt-get clean
rm -rf /var/cache/apt/archives/*
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
truncate -s 0 /var/log/*log
EOF

# NodeJS and Yarn
ARG NODE_MAJOR=18
ARG YARN_VERSION=1.22
RUN curl -sL https://deb.nodesource.com/setup_$NODE_MAJOR.x | bash -

RUN <<EOF
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get -yq dist-upgrade
DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
    nodejs
apt-get clean
rm -rf /var/cache/apt/archives/*
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
truncate -s 0 /var/log/*log
EOF
RUN npm install -g yarn@$YARN_VERSION

# Bundler and Rubygems
ENV LANG=C.UTF-8 \
  BUNDLE_JOBS=4 \
  BUNDLE_RETRY=3

# Store Bundler settings in the project's root
ENV BUNDLE_APP_CONFIG=.bundle

# Upgrade RubyGems and install the latest Bundler version
RUN gem update --system && gem install bundler


################################################################################
# development
################################################################################
from base as development

ENV RAILS_ROOT=/usr/src/app
RUN mkdir -p $RAILS_ROOT
WORKDIR $RAILS_ROOT

COPY Gemfile* $RAILS_ROOT
#COPY yarn.lock package.json $RAILS_ROOT

WORKDIR $RAILS_ROOT
RUN gem install mini_racer

RUN bundle install
RUN yarn install

COPY ./ $RAILS_ROOT

#RUN yarn build
#RUN yarn build:css

CMD ["bash"]
