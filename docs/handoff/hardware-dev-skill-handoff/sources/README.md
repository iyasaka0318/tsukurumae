# ソース資料と取得範囲

## 会話

取得元はこのチャット「ドローンフレーム設計を確認」。別チャットの本文は取得していない。チャット一覧は対象スレッドの特定のみに使用した。

| ファイル | 内容 |
| --- | --- |
| [conversation.md](conversation.md) | 過去84ターンの取得可能なユーザー発言・AI進捗・回答。C001〜C084 |
| [conversation-index.json](conversation-index.json) | 同じ発言の機械可読索引。ターンID、日付、状態、役割付き |
| [requirements-user.md](requirements-user.md) | C084のユーザー要件原文 |

ローカルユーザーパスを正規化し、ブラウザー自動状態・ツール・内部推論を省略した。画像本体や添付の研究計画本文は同梱していない。発言に残る添付名を出典として扱い、画像の読み取り結果は保存メモと当時の回答に限る。単なる発言から現物寸法を追加で捏造していない。

## 保存済み記録のスナップショット

この資料作成時点のコピー。元ファイルを変更していない。元のリンク先のCAD・画像・旧版や外部資料まで同梱したものではないため、スナップショット内の元リンクは参照記録として読む。

| ID・コピー | 元のワークスペース内ファイル | 証拠としての扱い |
| --- | --- | --- |
| [S01](snapshots/S01-fit-test.md) | outputs/テスト手順と設計更新.md | 設計・試験・後日のユーザー報告追記 |
| [S02](snapshots/S02-pico-v2.md) | outputs/Pico_test_v2_印刷メモ.md | 試験版寸法と印刷後フィードバック |
| [S03](snapshots/S03-wiring-plan.md) | outputs/ドローン_配線実測と配置計画_更新待ち.md | 上向き端子、写真確認、ユーザー実測と未反映事項 |
| [S04](snapshots/S04-robot-selection.md) | outputs/研究用倒立ロボット_最小構成と選定基準.md | 初期の選定方針。最終BOMではない |
| [S05](snapshots/S05-battery.md) | outputs/バッテリー実測記録.md | 旧仕様書にある実測記載の検索結果。今回の再測定ではない |
| [S06](snapshots/S06-orca-presets.md) | outputs/orca_presets/読み込みと使い分け.md | JSON検証範囲。実印刷合格ではない |
| [S07](snapshots/S07-robot-v5-review.md) | outputs/倒立ロボット_v5_確認結果.md | 文書・計算のレビュー。実機試験ではない |
| [S08](snapshots/S08-motor-test.md) | outputs/esc_one_motor/実機テスト結果_2026-10-06.md | ユーザー実測・回転報告と未測定項目 |
| [S09](snapshots/S09-drone-v1.md) | outputs/drone_pico_w_v1/設計と組立.md | 接続後高さ未反映の初版CADの説明 |
| [S10](snapshots/S10-robot-v5-plan.md) | outputs/倒立ロボット_設計レビューと配置_v5.md | 現行研究設計案。実機未検証 |
| [S11](snapshots/S11-robot-v5-circuit.md) | outputs/倒立ロボット_全体回路案_v5.md | 現行電源・回路の計画 |
| [S12](snapshots/S12-robot-v5-logs.md) | outputs/倒立ロボット_計測とログ実装仕様_v5.md | 計時・RAM保持・回収の実装仕様 |
| [S13](snapshots/S13-old-drone-spec.md) | outputs/ドローン旧仕様_寸法参照用.md | 別AI由来の旧仕様。部品寸法参照用で現在の実行指示ではない |

コピー前の原ファイルSHA-256とコピー後のハッシュは[manifest.json](manifest.json)へ保存する。スナップショット冒頭に出典を追記し、ローカルパスを正規化したため、コピーのハッシュは原ファイルと異なる。

## 出典にない内容の扱い

ユーザーのIMU選定の振り返りはそのまま要件の動機として保存したが、元の「最安だからMPU-6050でよい」というAI回答は、このチャットに取得できていない。別の会話の実発言として再構成しない。

レビューの「前回の指摘は全て反映」等も、貼られたレビューの評価であり、今回の独立検証を意味しない。原会話の誤答を残すことと、現在の推奨として承認することは別。
