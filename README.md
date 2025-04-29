# 競プロ用Docker環境

このDockerイメージは、C/C++開発用の環境を提供します。Ubuntu 22.04をベースにして、開発に必要なツールやSSHサーバーが設定されています。

## 特徴

- Ubuntu 22.04ベース
- タイムゾーン：Asia/Tokyo
- C/C++開発環境（gcc, g++, clang, gdb, cmake等）
- VSCodeリモート開発対応
- SSH接続サポート（鍵認証）
- VSCodeトンネル機能によるリモートアクセス（デーモン化）
- 永続的に動作するコンテナ設計

## 前提条件

- Dockerがインストールされていること
- SSH鍵が設定されていること（ビルド時に鍵を指定する方法があります）

## イメージのビルド

### 標準的なビルド
```bash
docker build -t dev-cpp-env .
```

### SSH鍵をビルド時に指定
ホストの認証済みSSH公開鍵を使用してビルドする場合:

```bash
# Windows PowerShellの場合
docker build -t dev-cpp-env --build-arg SSH_AUTHORIZED_KEYS="$(Get-Content $HOME/.ssh/authorized_keys)" .

# Windows コマンドプロンプトの場合
docker build -t dev-cpp-env --build-arg SSH_AUTHORIZED_KEYS="YOUR_SSH_PUBLIC_KEY_HERE" .

# Linux/macOSの場合
docker build -t dev-cpp-env --build-arg SSH_AUTHORIZED_KEYS="$(cat ~/.ssh/authorized_keys)" .
```

特定の公開鍵を指定する場合:

```bash
docker build -t dev-cpp-env --build-arg SSH_AUTHORIZED_KEYS="ssh-rsa AAAA... your-key-comment" .
```

## コンテナの起動

```bash
docker run -d -p 2222:22 --name dev-container dev-cpp-env
```

必要に応じてボリュームをマウントすることも可能です：

```bash
docker run -d -p 2222:22 -v /path/to/local/workspace:/workspace --name dev-container dev-cpp-env
```

## コンテナの状態確認

コンテナが正常に動作しているか確認するには：

```bash
docker logs dev-container
```

起動ログが表示され、「SSH server is running on port 22」などのメッセージが確認できます。

## コンテナへのアクセス方法

### 1. SSHで接続

```bash
ssh -p 2222 vscode@localhost
```

※SSH鍵認証が設定されています。対応する秘密鍵を使用してください。

### 2. VSCodeトンネルを使用した接続

コンテナ起動時に自動的にVSCodeトンネルサービスがデーモンとしてインストールされ、起動します。初回接続時には認証が必要です:

```bash
# トンネルサービスのログを表示して認証URLを取得
docker exec -it dev-container bash -c "su - vscode -c 'code tunnel service log'"
```

このコマンドを実行すると、ログの中に認証用のURLが表示されます。例：
```
To grant access to the server, please log into https://github.com/login/device and use code ABCD-EFGH
```

このURLをブラウザで開き、提示されたコードを入力して、Microsoftアカウント（またはGitHubアカウント）でログインして認証を完了します。

認証が完了したら、VSCodeのRemote Explorer（リモートエクスプローラー）から「Tunnels」セクションを開き、表示されているトンネル経由で接続できます。

他のデバイスからも同じMicrosoftアカウントでログインしたVS Codeからこのトンネルに接続できます。

### 3. コンテナにシェルで直接アクセス

```bash
# 通常ユーザー（vscode）としてアクセス
docker exec -it dev-container bash

# rootユーザーとしてアクセス
docker exec -it -u root dev-container bash
```

### 4. Visual Studio Codeからの接続

1. VSCodeに「Remote - SSH」拡張機能をインストール
2. VSCodeでリモートエクスプローラーを開く
3. SSH設定に以下を追加：

```
Host docker-dev
    HostName localhost
    User vscode
    Port 2222
    IdentityFile /path/to/private/key
```

4. 「docker-dev」に接続

## ユーザー情報

- ユーザー名: vscode
- UID/GID: 1000
- 権限: sudoパスワードなしで実行可能

## 作業ディレクトリ

コンテナ内の作業ディレクトリは `/workspace` に設定されています。

## 実装の詳細

このコンテナは以下の仕組みで永続的に動作します：

1. `start.sh`スクリプトがコンテナ起動時に実行されます
2. SSHサーバーがバックグラウンドで起動します
3. VSCodeトンネルサービスがシステムサービスとしてインストールされ、デーモンとして起動します
4. `tail -f`コマンドを使ってコンテナが終了しないようにしています
5. ログは`/var/log/docker-logs/keep-alive.log`に保存されます

VSCodeトンネルの認証状態は `/home/vscode/.vscode/tunnels` に保存され、コンテナを再起動しても維持されます。

### VSCodeトンネルサービスの管理

サービスの状態確認:
```bash
docker exec -it dev-container bash -c "su - vscode -c 'code tunnel service status'"
```

サービスの再起動:
```bash
docker exec -it dev-container bash -c "su - vscode -c 'code tunnel service restart'"
```

サービスのログ確認:
```bash
docker exec -it dev-container bash -c "su - vscode -c 'code tunnel service log'"
```

## 注意事項

- このコンテナはパスワード認証を無効化し、SSH鍵認証のみを許可しています
- SSH鍵はビルド時に `--build-arg SSH_AUTHORIZED_KEYS` で渡すことができます
- ビルド時に鍵を指定しなかった場合は、後でコンテナ内の `/home/vscode/.ssh/authorized_keys` ファイルに手動で追加する必要があります
- コンテナのセキュリティは、SSH鍵の安全な管理に依存しています
- 実運用環境では適切なセキュリティ対策を施してください
- コンテナを停止するには `docker stop dev-container` を実行してください

---

# Docker Environment for Competitive Programming

This Docker image provides a dedicated environment for competitive programming, primarily focused on C/C++. Based on Ubuntu 22.04, it includes necessary development tools and connectivity options to code from anywhere.

## Features

- Ubuntu 22.04 base
- Timezone: Asia/Tokyo
- C/C++ development environment (gcc, g++, clang, gdb, cmake, etc.)
- VSCode remote development support
- SSH connection support (key authentication)
- Remote access via VSCode tunnel feature (daemonized)
- Persistent container design
- Optimized for competitive programming contests

## Prerequisites

- Docker installed
- SSH key configured (can be specified at build time)

## Building the Image

### Standard Build
```bash
docker build -t dev-cpp-env .
```

### Specifying SSH Keys at Build Time
To build using the host's authorized SSH public keys:

```bash
# For Windows PowerShell
docker build -t dev-cpp-env --build-arg SSH_AUTHORIZED_KEYS="$(Get-Content $HOME/.ssh/authorized_keys)" .

# For Windows Command Prompt
docker build -t dev-cpp-env --build-arg SSH_AUTHORIZED_KEYS="YOUR_SSH_PUBLIC_KEY_HERE" .

# For Linux/macOS
docker build -t dev-cpp-env --build-arg SSH_AUTHORIZED_KEYS="$(cat ~/.ssh/authorized_keys)" .
```

To specify a particular public key:

```bash
docker build -t dev-cpp-env --build-arg SSH_AUTHORIZED_KEYS="ssh-rsa AAAA... your-key-comment" .
```

## Starting the Container

```bash
docker run -d -p 2222:22 --name dev-container dev-cpp-env
```

You can also mount volumes as needed:

```bash
docker run -d -p 2222:22 -v /path/to/local/workspace:/workspace --name dev-container dev-cpp-env
```

## Checking Container Status

To verify that the container is running properly:

```bash
docker logs dev-container
```

The startup logs will be displayed, including messages like "SSH server is running on port 22".

## Accessing the Container

### 1. SSH Connection

```bash
ssh -p 2222 vscode@localhost
```

Note: SSH key authentication is configured. Use the corresponding private key.

### 2. Connection Using VSCode Tunnel

The VSCode tunnel service is automatically installed and started as a daemon when the container launches. Authentication is required for first-time connection:

```bash
# Display tunnel service logs to get the authentication URL
docker exec -it dev-container bash -c "su - vscode -c 'code tunnel service log'"
```

This command will show an authentication URL in the logs. Example:
```
To grant access to the server, please log into https://github.com/login/device and use code ABCD-EFGH
```

Open this URL in your browser, enter the provided code, and log in with your Microsoft account (or GitHub account) to complete authentication.

After authentication, you can connect via the tunnel from the "Tunnels" section in VSCode's Remote Explorer.

You can also connect to this tunnel from other devices using VS Code logged in with the same Microsoft account.

### 3. Direct Shell Access to the Container

```bash
# Access as regular user (vscode)
docker exec -it dev-container bash

# Access as root user
docker exec -it -u root dev-container bash
```

### 4. Connection from Visual Studio Code

1. Install the "Remote - SSH" extension in VSCode
2. Open Remote Explorer in VSCode
3. Add the following to SSH config:

```
Host docker-dev
    HostName localhost
    User vscode
    Port 2222
    IdentityFile /path/to/private/key
```

4. Connect to "docker-dev"

## User Information

- Username: vscode
- UID/GID: 1000
- Privileges: sudo without password

## Working Directory

The container's working directory is set to `/workspace`.

## Implementation Details

This container operates continuously with the following mechanism:

1. The `start.sh` script runs when the container starts
2. The SSH server starts in the background
3. VSCode tunnel service is installed as a system service and started as a daemon
4. The `tail -f` command keeps the container running
5. Logs are stored in `/var/log/docker-logs/keep-alive.log`

The VSCode tunnel authentication state is saved in `/home/vscode/.vscode/tunnels` and persists through container restarts.

### Managing VSCode Tunnel Service

Checking service status:
```bash
docker exec -it dev-container bash -c "su - vscode -c 'code tunnel service status'"
```

Restarting the service:
```bash
docker exec -it dev-container bash -c "su - vscode -c 'code tunnel service restart'"
```

Checking service logs:
```bash
docker exec -it dev-container bash -c "su - vscode -c 'code tunnel service log'"
```

## Notes

- This container disables password authentication and allows only SSH key authentication
- SSH keys can be passed at build time with `--build-arg SSH_AUTHORIZED_KEYS`
- If keys are not specified at build time, they need to be manually added to `/home/vscode/.ssh/authorized_keys` file in the container
- Container security depends on safe management of SSH keys
- Use appropriate security measures in production environments
- To stop the container, run `docker stop dev-container`
