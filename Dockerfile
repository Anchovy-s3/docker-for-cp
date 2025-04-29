FROM ubuntu:24.04

# タイムゾーンの設定
ENV TZ=Asia/Tokyo
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 必要なパッケージのインストール
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    git \
    gnupg \
    lsb-release \
    ca-certificates \
    build-essential \
    gdb \
    cmake \
    python3 \
    python3-pip \
    openssh-server \
    locales \
    sudo \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# 日本語ロケールの設定
RUN locale-gen ja_JP.UTF-8
ENV LANG ja_JP.UTF-8
ENV LANGUAGE ja_JP:ja
ENV LC_ALL ja_JP.UTF-8

# VSCode用の非rootユーザーの作成
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# C/C++開発用の追加パッケージ
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    make \
    clang \
    clang-format \
    clang-tidy \
    && rm -rf /var/lib/apt/lists/*

# SSHサーバーの設定
RUN mkdir -p /var/run/sshd
RUN echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
RUN echo "PermitEmptyPasswords no" >> /etc/ssh/sshd_config

# VSCode Server用のディレクトリ
RUN mkdir -p /home/$USERNAME/.vscode-server/extensions \
    && chown -R $USERNAME:$USERNAME /home/$USERNAME/.vscode-server

# 作業ディレクトリの作成
RUN mkdir -p /workspace && chown -R $USERNAME:$USERNAME /workspace
WORKDIR /workspace

# ユーザー切り替え
USER $USERNAME

# SSHサーバーの起動
EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]