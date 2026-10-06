# Raspberry Pi 電子錠 — 会話引継ぎ資料

この資料は、電子錠の復旧・保守・切り分けを続けた会話を、Skill「tsukurumae」の設計と評価に使うために整理したものです。Skill本体・電子錠コードの変更ではありません。

## 読む順序
1. [プロジェクト概要](docs/project-summary.md)
2. [会話記録](sources/conversation.md) と [索引](sources/conversation-index.json)
3. [失敗分析](examples/failures.md) と [残したい行動](examples/good-behaviors.md)
4. [評価ケース](evals/cases.md)

## 取得範囲と証拠
対象は、このチャットで現在取得できる履歴部分とユーザー貼付の端末出力です。全履歴のエクスポート、過去AI回答の完全な逐語録、元ログ／実設定ファイルは取得できていません。会話記録では、AI回答の原文を取得できない場合は「取得不可」とし、補作していません。ユーザー報告、貼付出力、AI回答、今回の分析を区別しました。S番号の原ファイルコピーはありません。

## 秘密情報の除去
値を資料へ転記しない形で除去しました。
- `<REDACTED:credential>`: 2件（JWT署名用値、Discord認証値）
- `<REDACTED:channel-id>`: 2件（テキスト／ボイスチャンネル識別値）
- `<REDACTED:account-id>`: 2件（Windows／Raspberry Piローカルアカウント名）
- ローカルパスは `<HOME>` または `<WORKSPACE>` に一般化。出現数は validation.json を参照。
- FeliCaカード識別子は原ログが完全でないため、値を記載せず省略（正確な置換数は算出不可）。

## 除外したもの
Discord/JWT秘密値、カードUID、個別識別値、Pi上の実ファイル全体、AI内部推論、未取得のAI発言、画像・配線・USB波形、認証付きURL、個人連絡先。会話に貼られた設定・ログは必要な事実のみ要約しました。

ファイル数、件数、JSON・リンク・秘密情報検査は [validation.json](validation.json) を参照。