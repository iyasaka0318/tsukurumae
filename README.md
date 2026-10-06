# tsukurumae（つくるまえ）

**AI にハードウェアを作らせる前に、作るために必要な質問をさせる Skill。**

Claude Code、Codex、Cursor などの既存の AI エージェントに読み込ませて、ハードウェア開発中の AI の振る舞いを改善する。
ドローン、倒立振子、ロボット、組込み、センサ機器、3D プリント試作、電装を含む個人開発が対象。

## なぜ必要か
AI は「これを作りたい」と言われると、すぐに部品選定・CAD・コード生成に進みがちである。
しかしハードウェア開発では、ユーザー自身が「何を決めなければならないか」を認識していないことが多い。

- 「安い方がいい」→ 最安の IMU を選んだが、研究用途には性能が足りなかった
- 「Pico 2 WH を使う」→ ヘッダー実装済みであること、ジャンパ線の高さ、USB アクセス、ケーブル方向を確認しないまま CAD を作り、何度も作り直した

この Skill は、こうした**作る前に聞けば防げた手戻り**を減らし、**実機でしか分からない問題に早く到達する**ことを目的とする。

## 動き方

```
Step 1 要求定義・前提監査 ─Gate 1→ Step 2 システム設計・成立性 ─Gate 2→
Step 3 実装条件監査 ─Gate 3 (Design Input Freeze)→ CAD・回路・配線・コード →
Step 4 試作 → 観察 → 診断 → 修正（必要なステップへ戻る）
```

- 最終目的から逆算し、ユーザーが言っていない論点を AI 側から出す
- 質問に優先度（Critical / Blocking / Important / Nice to know）を付け、必要な分だけ聞く
- 調べれば分かることは調べ、ユーザーにしか決められないことを聞く
- 情報を「確定・仮定・決定・仮決定・不明・未回答・制約・希望・リスク・依存」で管理する（開発台帳）
- Gate 3 を通るまで CAD・回路・配線を出力しない

## 構成

```
skills/tsukurumae/
  SKILL.md                        # 本体（常に読まれる。行動原則・質問の優先度・Gate）
  references/
    step1-requirements.md         # 要求定義・前提監査
    step2-system-design.md        # システム設計・成立性確認
    step3-implementation-audit.md # 実装条件監査（Design Input Freeze）
    component-checklists.md       # 部品カテゴリ別の実装論点
    step4-prototype-loop.md       # 試作・フィードバック
    ledger-template.md            # 開発台帳の書式
evals/
  README.md                       # 評価方法
  cases/                          # 実際の失敗に基づくテストケース
docs/
  requirements.md                 # この Skill の要件
```

## インストール

### Claude Code
```bash
# 全プロジェクトで使う
mkdir -p ~/.claude/skills && cp -r skills/tsukurumae ~/.claude/skills/
# 特定のプロジェクトだけで使う
mkdir -p <project>/.claude/skills && cp -r skills/tsukurumae <project>/.claude/skills/
```
ハードウェアの話題で自動的に読み込まれる。明示的に使うときは `/tsukurumae` と入力する。

### Codex
Agent Skills 形式（`SKILL.md`）に対応したバージョンでは、Codex の skills ディレクトリ（例：`~/.codex/skills/`）へ `skills/tsukurumae` をコピーする。
対応していない場合は、プロジェクトの `AGENTS.md` から `skills/tsukurumae/SKILL.md` を読むように指示する。

### Cursor
Skill に対応したバージョンではそのディレクトリへコピーする。対応していない場合は、`.cursor/rules/` に `SKILL.md` の内容を置くか、ルールから `skills/tsukurumae/SKILL.md` を参照する。

> 各ツールの Skill の置き場所はバージョンで変わることがあるため、使っているツールのドキュメントで確認してください。

## 評価
[evals/README.md](evals/README.md) を参照。自分の開発で手戻りが起きたら `evals/cases/` にケースを追加し、回帰テストとして使う。

## ロードマップ
- [x] MVP：Markdown のみ。要求整理 → 論点抽出 → 質問 → システム計画 → 実装条件の再監査 → Gate
- [ ] 実例（ドローン、倒立振子）で評価し、チェックリストを改善する
- [ ] 重量・電力・推力の計算補助
- [ ] BOM 生成、部品価格・データシート取得
- [ ] CAD・回路設計ツールや MCP との連携
