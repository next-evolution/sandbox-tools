# docs-check

`docs/docker.md` と `bruno/README.md` が実装と乖離していないかチェックする。

## 手順

以下を順番に実施し、差異をまとめてレポートする。

### 1. Docker サービス vs `docs/docker.md`

- `docker/docker-compose.yml` を読む
- サービス名・イメージ・コンテナ名・ポートマッピングを抽出し、`docs/docker.md` の「サービス構成」と照合する

### 2. 環境変数 vs `docs/docker.md`

- `docker/.env.compose.example` を読む
- 変数名・説明と `docs/docker.md` の「環境変数」テーブルを照合する

### 3. init スクリプト vs `docs/docker.md`

- `docker/mysql/initdb.d/` のファイル一覧を取得する
- 各スクリプトで `CREATE TABLE` されているテーブル名を抽出し、`docs/docker.md` の「初期化スクリプト」と「テーブル一覧」を照合する
- `docs/docker.md` に記載があるが実ファイルが存在しないものをチェックする
- 実ファイルが存在するが `docs/docker.md` に記載がないものをチェックする

### 4. データファイル vs `docs/docker.md`

- `data/` 直下のファイル・ディレクトリ一覧を取得する
- `docs/docker.md` の「データファイル」テーブルと照合する
- 実ファイルが存在するが記載がないもの、記載があるが実ファイルが存在しないものをチェックする

### 5. Bruno シナリオ vs `bruno/README.md`

- `bruno/setup/` と `bruno/scenarios/` 配下のディレクトリ・ファイル一覧を取得する
- `bruno/README.md` の「ファイル構成」および「シナリオ概要」と照合する
- 実ファイルが存在するが記載がないもの、記載があるが実ファイルが存在しないものをチェックする

## レポート形式

差異がある場合:

```
## 差異あり

### [ファイル名]
- **項目**: （ドキュメントの記載）
- **実装**: （実際の実装）
- **修正案**: （推奨される修正内容）
```

差異がない場合:

```
## 差異なし
docs/*.md と実装の間に乖離は見つかりませんでした。
```
