FROM brainbeanapps/base-linux-build-environment:v3.0

LABEL maintainer="devops@brainbeanapps.com"

# Switch to root
USER root

# Set shell as non-interactive during build
# NOTE: This is discouraged in general, yet we're using it only during image build
ARG DEBIAN_FRONTEND=noninteractive

# Copy assets
WORKDIR /opt
COPY versions.list .

# Install various prerequisites
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    zlib1g-dev \
    libssl-dev \
    libreadline-dev \
    libyaml-dev \
    libsqlite3-dev \
    sqlite3 \
    libxml2-dev \
    libxslt1-dev \
    libcurl4-openssl-dev \
    software-properties-common \
    libffi-dev \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Install Node.js & npm
RUN curl -sL https://deb.nodesource.com/setup_12.x | bash - \
  && apt-get update \
  && apt-get install -y --no-install-recommends nodejs \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && npm install -g npm@latest

# Install Yarn
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
  && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
  && apt-get update \
  && apt-get install -y --no-install-recommends yarn \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Switch to user
USER user
WORKDIR /home/user

# Install rbenv
ENV RBENV_ROOT /home/user/.rbenv
ENV RUBY_BUILD_ROOT ${RBENV_ROOT}/plugins/ruby-build
ENV PATH="${RBENV_ROOT}/shims:${RBENV_ROOT}/bin:${RUBY_BUILD_ROOT}/bin:${PATH}"
RUN git clone https://github.com/rbenv/rbenv.git --depth 1 $RBENV_ROOT \
  && git clone https://github.com/rbenv/ruby-build.git --depth 1 $RUBY_BUILD_ROOT \
  && ${RBENV_ROOT}/bin/rbenv init - > /home/user/rbenv.sh \
  && chmod +x /home/user/rbenv.sh \
  && source /home/user/rbenv.sh \
  && echo 'source $HOME/rbenv.sh' > /home/user/.bashrc

# Install multiple versions of ruby
ARG CONFIGURE_OPTS=--disable-install-doc
RUN xargs -L 1 rbenv install < /opt/versions.list

# Install Bundler for each version of ruby
RUN echo 'gem: --no-rdoc --no-ri' >> /home/user/.gemrc
RUN bash -l -c 'for v in $(cat /opt/versions.list); do rbenv global $v; gem install bundler; done'
