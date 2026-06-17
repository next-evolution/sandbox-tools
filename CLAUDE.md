# sandbox-tools

sandbox プロジェクトのローカルインフラ・API テストツール集。
MySQL / Redis の Docker Compose 環境と、Bruno API テストコレクションを管理する。

---

## このファイルの管理方針

**CLAUDE.md は「Claudeの行動を変える指示書」** であり、ドキュメントではない。
毎回コンテキストに全文読み込まれるため、肥大化させない。

| 種類 | 置き場所 |
|---|---|
| コーディング規約・禁止事項 | **CLAUDE.md** |
| Docker 環境・テーブル一覧・環境変数の詳細 | `docs/docker.md` |
| Bruno テストコレクション詳細・実行方法 | `bruno/README.md` |
| Bruno 実装メモ（懸念事項・未確認事項） | `bruno/MEMO.md` |
| タスク指示（step 系） | **プロンプトで渡す** |

---

## ドキュメント参照先

| 内容 | ファイル |
|---|---|
| Docker Compose 環境・テーブル一覧・環境変数 | [docs/docker.md](docs/docker.md) |
| Bruno テストコレクション詳細・実行方法 | [bruno/README.md](bruno/README.md) |
| Bruno 実装メモ（動作確認前の懸念事項） | [bruno/MEMO.md](bruno/MEMO.md) |

### 利用可能なカスタムコマンド

| コマンド | 用途 |
|---|---|
| `/docs-check` | ドキュメント（`docs/*.md`）と実装の乖離チェック。コミット前などに手動実行する |

---

## 言語設定

- 常に日本語で会話する
- コメントも日本語で記述する
- エラーメッセージの説明も日本語で行う

---

## Docker 起動

```bash
cd docker
cp .env.compose.example .env.compose  # 初回のみ・値を実際の環境に合わせて編集
docker compose --env-file .env.compose up -d
```

### 環境変数ファイル

| ファイル | 用途 |
|---|---|
| `docker/.env.compose.example` | テンプレート（git 管理対象） |
| `docker/.env.compose` | 実際の値（git 除外済み） |

詳細は [docs/docker.md](docs/docker.md) 参照。

---

## Bruno テスト

### 前提

```bash
npm install -g @usebruno/cli
cd bruno
cp environments/local.bru.example environments/local.bru
# 各値を実際の環境に合わせて編集する
```

### 初期化フロー（DB 再構築後に実行）

```bash
# 1. ユーザー初期化（user.csv を全件ループ）
./bruno/setup/100_initialize/setup.sh

# 2. マスターデータ・バーデータ・ZigZag 登録
./bruno/setup/200_master_data/register.sh
```

詳細・シナリオ一覧・トークン引き継ぎ方式は [bruno/README.md](bruno/README.md) 参照。

---

## 規約

### 環境変数

新しい環境変数を追加・削除・リネームしたら `docker/.env.compose.example` の該当箇所も同時に更新する。

### データファイル

`data/` 配下の CSV/TXT は Bruno テストと Docker init スクリプトで共用する。
ファイルを追加・削除したら [docs/docker.md](docs/docker.md) のデータファイル一覧も更新する。

### init スクリプト実行順

`docker/mysql/initdb.d/` のファイル名プレフィックスで順序が決まる。

| プレフィックス | 用途 |
|---|---|
| `00_` | データベース作成（DROP & CREATE） |
| `10_` | アプリテーブル作成（`sandbox_user`） |
| `20_` | FX 系テーブル作成・データロード定義 |
| `99_` | アプリ DB ユーザー作成・管理者初期データ投入 |

新しいテーブルを追加したら `20_` プレフィックスで追加し、[docs/docker.md](docs/docker.md) のテーブル一覧も更新する。
