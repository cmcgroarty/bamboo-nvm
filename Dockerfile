FROM debian:bookworm-slim
LABEL org.opencontainers.image.authors="cmcgroarty@idesignconsulting.com"

SHELL ["/bin/bash", "--login" , "-c"]

# bamboo plan deps
RUN apt update && apt install --no-install-recommends -y \
    curl \
    ca-certificates \
    git \
    gnupg

# add nvm
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash

# add yarn source
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

RUN apt update && apt install --no-install-recommends -y yarn

# install pnpm from pnpm
RUN curl -fsSL https://get.pnpm.io/install.sh | ENV="$HOME/.bashrc" SHELL="$(which bash)" bash -

# clean up
RUN rm -rf /var/lib/apt/lists/* \
&& apt purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
&& apt clean

# create bamboo user and group that aligns with prod-bamboo-az1 uid/gid
RUN adduser bamboo --uid 1002 --shell /bin/bash


# add ngsw-rehash
ADD https://github.com/dev-jan/ngsw-rehash/releases/download/v1.0/ngsw-rehash-linux-x86 /home/bamboo/bin/ngsw-rehash
RUN chown -R bamboo:bamboo /home/bamboo/bin
RUN chmod +x /home/bamboo/bin/ngsw-rehash

RUN source ~/.bashrc
RUN source ~/.profile


# a few environment variables to make NPM installs easier
# good colors for most applications
ENV TERM=xterm
# avoid million NPM install messages
ENV npm_config_loglevel=warn

RUN pnpm --version

RUN rm -rf /tmp/*

USER bamboo:bamboo
