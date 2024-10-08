FROM debian:bookworm-slim
LABEL org.opencontainers.image.authors="cmcgroarty@idesignconsulting.com"

# bamboo plan deps
RUN apt update && apt install --no-install-recommends -y \
    curl \
    wget \
    ca-certificates \
    git \
    gnupg

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

# add blank .bashrc
COPY .bashrc $HOME/.bashrc
RUN chown -R $USERNAME:$USERNAME $HOME/.bashrc

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
      && git fetch \
      && git checkout `git describe --abbrev=0 --tags --match "v[0-9]*" $(git rev-list --tags --max-count=1)` \
      && \. "$NVM_DIR/nvm.sh"

# nvm
RUN echo 'export NVM_DIR="$HOME/.nvm"' >> "$HOME/.bashrc"
RUN echo '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm' >> "$HOME/.bashrc"

# a few environment variables to make NPM installs easier
# good colors for most applications
ENV TERM=xterm
# avoid million NPM install messages
ENV npm_config_loglevel=warn

USER root:root
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

USER $USERNAME:$USERNAME

SHELL ["/bin/bash", "--login", "-c"]
RUN source ~/.bashrc

ENTRYPOINT ["docker-entrypoint.sh"]