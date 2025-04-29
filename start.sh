#!/bin/bash

# SSHサーバーをバックグラウンドで起動
/usr/sbin/sshd

# VSCode Serverのディレクトリ権限を確認
chown -R vscode:vscode /home/vscode/.vscode-server

# VSCodeサービスのインストールと起動
su - vscode -c "code tunnel service install"
echo "VSCode tunnel service installed"

# VSCodeトンネルサービスの起動
su - vscode -c "code tunnel service start"
echo "VSCode tunnel service started"

# ログファイル用のディレクトリを作成
mkdir -p /var/log/docker-logs
touch /var/log/docker-logs/keep-alive.log
chmod 666 /var/log/docker-logs/keep-alive.log

echo "Container started at $(date)" > /var/log/docker-logs/keep-alive.log
echo "SSH server is running on port 22" >> /var/log/docker-logs/keep-alive.log
echo "VSCode tunnel service is installed and running as a daemon" >> /var/log/docker-logs/keep-alive.log
echo "To authenticate, run: docker exec -it <container_id> bash -c \"su - vscode -c 'code tunnel service log'\"" >> /var/log/docker-logs/keep-alive.log
echo "Use 'docker exec -it <container_id> bash' to get a shell" >> /var/log/docker-logs/keep-alive.log

# コンテナを継続的に実行させるためのダミープロセス
tail -f /var/log/docker-logs/keep-alive.log