# sandbox-tools

sandbox プロジェクトのローカルインフラ・API テストツール集。

## 概要

| ディレクトリ | 用途 |
|---|---|
| `docker/` | MySQL / Redis の Docker Compose 環境 |
| `bruno/` | Bruno API テストコレクション |
| `data/` | マスターデータ・足データ CSV（Bruno と Docker init で共用） |

## クイックスタート

### 1. Docker 起動

```bash
cd docker
cp .env.compose.example .env.compose  # 初回のみ・値を実際の環境に合わせて編集
docker compose --env-file .env.compose up -d
```

### 2. Bruno セットアップ・初期データ投入

```bash
npm install -g @usebruno/cli
cd bruno
cp environments/local.bru.example environments/local.bru
# 各値を実際の環境に合わせて編集する

# ユーザー初期化（user.csv を全件ループ）
./setup/100_initialize/setup.sh

# マスターデータ・バーデータ・ZigZag 登録
./setup/200_master_data/register.sh
```

## ドキュメント

| 内容 | ファイル |
|---|---|
| Docker Compose 環境・テーブル一覧・環境変数 | [docs/docker.md](docs/docker.md) |
| Bruno テストコレクション詳細・実行方法 | [bruno/README.md](bruno/README.md) |
| Bruno 実装メモ（懸念事項・未確認事項） | [bruno/MEMO.md](bruno/MEMO.md) |

## 関連リポジトリ

| リポジトリ | 用途 |
|---|---|
| `sandbox-api-springboot` | Spring Boot REST API 本体 |
| `sandbox-tools`（本リポジトリ） | ローカルインフラ・テストツール |
