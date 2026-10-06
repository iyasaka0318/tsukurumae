# Claude Code + Codex Workflow

## Roles

最初に実装を依頼された AI を **Builder**、もう一方を **Reviewer** とします。担当は固定ではなく、タスクごとに入れ替えられます。

Builder は要求理解、調査、実装、関連テスト、指摘の検証と修正を担当します。Reviewer は最初はコードを変更せず、`git diff`、変更ファイル、関連コード、テストを確認します。

## Standard Flow

レビューは既定では挟みません。個人開発のため、通常は Builder がそのまま push まで進みます。

```text
通常  User -> Builder -> Implementation -> Tests -> Commit -> Push

重要  User -> Builder -> Implementation -> Tests -> Commit -> Push
      -> Builder がレビューを提案 -> User が Reviewer に依頼 -> Review
      -> Builder が findings を検証 -> Fix -> Commit -> Push
```

1. Builder は開始前の `git status` を記録し、既存変更を保護する。
2. Builder は最小限の変更を実装し、利用可能な検証を実行する。
3. Builder は差分を確認して commit と push を行う。stage は変更ファイルを個別に指定し、意図しないファイルが含まれていないことを確認する。
4. 変更が Important Changes に当たる場合だけ、Builder は push 後に「これはレビューする価値があるかもしれません」と理由を添えて提案する。依頼するかは User が決める。それ以外では提案しない。
5. Reviewer は bugs、edge cases、security、regressions、typing、race conditions、error handling、performance、maintainability、unnecessary complexity、missing tests を確認する。
6. Reviewer は重要度順に、根拠となるファイルと行、影響、再現条件または修正案を報告する。問題がなければ明記し、残る検証不足も示す。
7. Builder は指摘をコード上で一件ずつ検証し、妥当なものだけを修正する。採用しない指摘には短い技術的理由を残す。修正は追加の commit として行う。

## Important Changes

認証・認可、データ形式や DB、public API、並行処理、大きな依存更新、広い範囲の設計変更など、失敗したときの影響が大きい変更が対象です。

この場合だけ Builder は、実装前の設計比較か push 後のレビューを提案します。提案には対象と理由を添えます。依頼するかは User が決め、断られた場合はそのまま進めます。設計比較を行う場合は、Claude Code と Codex が別々に案を出し、前提、変更範囲、互換性、リスク、テスト方針を比較してから Builder が実装します。

すべての作業で [AI_RULES.md](AI_RULES.md) を適用します。

