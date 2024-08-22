FROM debian:bookworm-slim
LABEL org.opencontainers.image.authors="cmcgroarty@idesignconsulting.com"

SHELL ["/bin/bash", "--login" , "-c"]

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

# add nvm
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash

# nvm
RUN echo 'export NVM_DIR="$HOME/.nvm"'                                       >> "$HOME/.bashrc"
RUN echo '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm' >> "$HOME/.bashrc"
RUN echo '[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion" # This loads nvm bash_completion' >> "$HOME/.bashrc"

# install pnpm from pnpm
RUN curl -fsSL https://get.pnpm.io/install.sh | ENV="$HOME/.bashrc" SHELL="$(which bash)" bash -


RUN source $HOME/.bashrc
RUN source $HOME/.profile



# a few environment variables to make NPM installs easier
# good colors for most applications
ENV TERM=xterm
# avoid million NPM install messages
ENV npm_config_loglevel=warn
