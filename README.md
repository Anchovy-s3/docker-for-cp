# 競プロ用Docker開発環境

このDockerイメージは、C/C++開発用の環境を提供します。Ubuntu 22.04をベースにして、開発に必要なツールやSSHサーバーが設定されています。

## 特徴

- Ubuntu 22.04ベース
- 日本語対応（ja_JP.UTF-8）
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
