FROM debian:bookworm-slim
LABEL org.opencontainers.image.authors="cmcgroarty@idesignconsulting.com"

# bamboo plan deps
RUN apt update && apt install --no-install-recommends -y \
    curl \
    wget \
    ca-certificates \
    git \
    gnupg

# add yarn source
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

RUN apt update && apt install --no-install-recommends -y yarn

# clean up
RUN rm -rf /var/lib/apt/lists/* \
&& apt purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
&& apt clean

RUN rm -rf /tmp/*
# create bamboo user and group that aligns with prod-bamboo-az1 uid/gid
ENV USERNAME=bamboo
ENV UID=1002
ENV HOME=/home/$USERNAME
RUN adduser $USERNAME --uid $UID --home $HOME --shell /bin/bash

# add ngsw-rehash
ADD https://github.com/dev-jan/ngsw-rehash/releases/download/v1.0/ngsw-rehash-linux-x86 $HOME/bin/ngsw-rehash
RUN chown -R $USERNAME:$USERNAME $HOME/bin
RUN chmod +x $HOME/bin/ngsw-rehash

USER $USERNAME:$USERNAME
SHELL ["/bin/bash", "--login", "-c"]

ENV NVM_DIR=$HOME/.nvm
# add nvm
RUN git clone https://github.com/nvm-sh/nvm.git "$NVM_DIR" \
      && cd "$NVM_DIR" \
      && git checkout `git describe --abbrev=0 --tags --match "v[0-9]*" $(git rev-list --tags --max-count=1)` \
      && \. "$NVM_DIR/nvm.sh"

# nvm
# wait for https://github.com/nvm-sh/nvm/commit/4beab63631764fc381a0e56273faf8d43b8f9509
# to be released to solve error on bamboo
#/home/bamboo/.nvm/nvm.sh: line 552: unpaired_line: unbound variable
#/home/bamboo/.nvm/nvm.sh: line 3771: VERSION: unbound variable
RUN echo 'export NVM_DIR="$HOME/.nvm"' >> "$HOME/.profile"
RUN echo '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm' >> "$HOME/.profile"

# install pnpm from pnpm
RUN curl -fsSL https://get.pnpm.io/install.sh | ENV="$HOME/.profile" SHELL="$(which bash)" bash -

# a few environment variables to make NPM installs easier
# good colors for most applications
ENV TERM=xterm
# avoid million NPM install messages
ENV npm_config_loglevel=warn

RUN bash -l -c "source $HOME/.profile"
