# 使用中のフィードバック

tsukurumae を実際に使ったときの指摘を集め、Skill の改善に回す場所。

## 流れ

1. **記録**：各プロジェクトで、AI がユーザーの指摘を `TSUKURUMAE_FEEDBACK.md` に自動で追記する（[references/feedback.md](../skills/tsukurumae/references/feedback.md)）。
2. **取り込み**：このリポジトリで「フィードバック取り込んで」と言い、その内容を渡す（ファイルの中身を貼る、パスを伝える、など）。AI が `inbox/YYYY-MM-DD-<プロジェクト名>.md` として保存する。
3. **反映**：AI が各項目を仕分けて、次のどれかに反映する。
   - 手戻りのパターン → `skills/tsukurumae/references/rework-catalog.md`
   - 原則・確定条件の不足 → `SKILL.md` や `references/`
   - 同じ失敗を見る評価ケース → `evals/`
   - 反映しない（方針変更だった、すでに対応済み、など）→ 理由だけ残す
4. **記録を閉じる**：反映した項目は、inbox のファイルの各項目の下に「反映：<反映先とコミット>」を書き足す。

## 状態

- `inbox/` に未処理のファイルがあれば、まずそれを処理する。
