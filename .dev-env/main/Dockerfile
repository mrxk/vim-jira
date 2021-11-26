FROM alpine:3.14.1
LABEL creator=dev-env
RUN apk add \
    cargo \
    curl \
    gcc \
    git \
    libffi-dev \
    musl-dev \
    openssh \
    openssl-dev \
    py-pip \
    python3 \
    python3-dev \
    rust \
    sudo \
    vim
RUN pip3 install \
    jira \
    gitpython \
    keyring \
    keyrings.alt
RUN adduser -D vimjira vimjira && \
    echo "vimjira ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/010_vimjira-nopasswd
COPY vimrc /home/vimjira/.vimrc
RUN chown vimjira:vimjira /home/vimjira/.vimrc
USER vimjira
RUN curl -fLo /home/vimjira/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
ENTRYPOINT ["/bin/ash"]

