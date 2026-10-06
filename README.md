# tsukurumae（つくるまえ）

作る前に、作るために必要なことを確かめさせる Agent Skill。Claude Code と Codex で使う。

ハードウェア（ドローン、ロボット、電装、3D プリント、CAD）でも、ソフトウェア（ファームウェア、アプリ、スクリプト、解析）でも、目的は同じ。
**作る前に確かめれば防げた手戻りを減らし、実際に動かさないと分からない問題に早く着く。**

> 開発中。評価はまだ実施していない。

## 使い方

```
/tsukurumae ドローン作ろうと思ってる。計画はこれ（資料があれば添付）
```

Codex では `$tsukurumae`。ハードウェアやソフトウェアを作る話題では、自動で読み込まれることもある。

AI は案件の性質（ハードかソフトか、CAD を使うか、研究か趣味か）を発言と資料から判定し、分からないことだけを聞く。プロジェクトのルートに `TSUKURUMAE_LEDGER.md`（台帳）を作り、決定・仮定・試験結果を記録しながら進める。

## インストール

```bash
# Claude Code（全プロジェクト）
cp -r skills/tsukurumae ~/.claude/skills/
# Claude Code（このプロジェクトだけ）
cp -r skills/tsukurumae <project>/.claude/skills/

# Codex（全プロジェクト）
cp -r skills/tsukurumae ~/.agents/skills/
# Codex（このプロジェクトだけ）
cp -r skills/tsukurumae <project>/.agents/skills/
```

台帳があるプロジェクトで毎回確実に使わせたい場合は、そのプロジェクトの `CLAUDE.md` または `AGENTS.md` に次の1行を加える。

```
このプロジェクトでは TSUKURUMAE_LEDGER.md を読み、tsukurumae スキルに従って作業する。
```

## 構成

```
skills/tsukurumae/
  SKILL.md                   本体：最優先ルール、始め方、原則、質問の出し方、送信前チェック
  agents/openai.yaml         Codex 用の設定
  references/
    intake.md                案件の受け取り方
    readiness.md             作業ごとの確定条件
    evidence.md              証拠の強さと検証の段階
    hardware.md              ハードウェアの確認観点
    software.md              ソフトウェアの確認観点（暫定版）
    rework-catalog.md        実例から作った手戻りのパターン
    ledger-template.md       台帳の書式
docs/
  requirements.md            原要件
  design-memo.md             設計メモ
  handoff/                   実際の開発会話から作った実例資料と評価ケース
```
