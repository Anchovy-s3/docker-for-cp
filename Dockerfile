FROM ubuntu:22.04

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

# グループが存在しない場合のみ作成（既に存在する場合はスキップ）
RUN if getent group $USER_GID > /dev/null 2>&1; then \
        echo "Group with GID $USER_GID already exists"; \
    else \
        groupadd --gid $USER_GID $USERNAME; \
    fi \
    # 既存のグループ名を取得（存在する場合）
    && GROUP_NAME=$(getent group $USER_GID | cut -d: -f1) \
    # ユーザーを作成
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME -g $GROUP_NAME \
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

# VSCodeをインストール
RUN apt-get update && apt-get install -y apt-transport-https
RUN wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg \
    && install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg \
    && sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list' \
    && rm -f packages.microsoft.gpg

RUN apt-get update && apt-get install -y code \
    && rm -rf /var/lib/apt/lists/*

# VS Code CLI用のパッケージ
RUN apt-get update && apt-get install -y \
    xdg-utils \
    && rm -rf /var/lib/apt/lists/*

# SSHサーバーの設定
RUN mkdir -p /var/run/sshd
# 空パスワード設定の代わりにSSH鍵認証を有効化
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config \
    && sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config

# ユーザーのSSH設定ディレクトリの作成
RUN mkdir -p /home/$USERNAME/.ssh \
    && chmod 700 /home/$USERNAME/.ssh

# 外部の公開鍵ファイルをコピー
COPY id_rsa.pub /home/$USERNAME/.ssh/authorized_keys
RUN chmod 600 /home/$USERNAME/.ssh/authorized_keys \
    && chown -R $USERNAME:$USERNAME /home/$USERNAME/.ssh

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

# スタートアップスクリプトの追加
COPY start.sh /start.sh
RUN sudo chmod +x /start.sh

# ユーザー権限をrootに戻す（スタートアップスクリプト用）
USER root

# SSHサーバーとtailを使用してコンテナを動作させ続ける
CMD ["/start.sh"]