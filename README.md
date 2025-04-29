# Docker開発環境

このDockerイメージは、C/C++開発用の環境を提供します。Ubuntu 22.04をベースにして、開発に必要なツールやSSHサーバーが設定されています。

## 特徴

- Ubuntu 22.04ベース
- 日本語対応（ja_JP.UTF-8）
- タイムゾーン：Asia/Tokyo
- C/C++開発環境（gcc, g++, clang, gdb, cmake等）
- VSCodeリモート開発対応
- SSH接続サポート（鍵認証）

## 前提条件

- Dockerがインストールされていること
- SSH鍵ペアが用意されていること（公開鍵が`id_rsa.pub`として配置済み）

## イメージのビルド

```bash
docker build -t dev-cpp-env .
```

## コンテナの起動

```bash
docker run -d -p 2222:22 --name dev-container dev-cpp-env
```

必要に応じてボリュームをマウントすることも可能です：

```bash
docker run -d -p 2222:22 -v /path/to/local/workspace:/workspace --name dev-container dev-cpp-env
```

## コンテナへのアクセス方法

### 1. SSHで接続

```bash
ssh -p 2222 vscode@localhost
```

※SSH鍵認証が設定されています。対応する秘密鍵を使用してください。

### 2. コンテナにシェルで直接アクセス

```bash
# 通常ユーザー（vscode）としてアクセス
docker exec -it dev-container bash

# rootユーザーとしてアクセス
docker exec -it -u root dev-container bash
```

### 3. Visual Studio Codeからの接続

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

## 注意事項

- このコンテナはパスワード認証を無効化し、SSH鍵認証のみを許可しています
- コンテナのセキュリティは、SSH鍵の安全な管理に依存しています
- 実運用環境では適切なセキュリティ対策を施してください
