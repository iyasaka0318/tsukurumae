# tsukurumae（つくるまえ）

作る前に、作るために必要なことを確かめさせる Agent Skill。Claude Code と Codex で使う。

ハードウェア（ドローン、ロボット、電装、3D プリント、CAD）でも、ソフトウェア（ファームウェア、アプリ、スクリプト、解析）でも、目的は同じ。
**作る前に確かめれば防げた手戻りを減らし、実際に動かさないと分からない問題に早く着く。**

> 開発中。サブエージェントによる比較評価（[run-01](evals/run-01/results.md)、[run-02](evals/run-02/results.md)、[run-03](evals/run-03/results.md)、[run-04](evals/run-04/results.md)）を経て、実際に使いながら改善している段階。

## 使い方

```
/tsukurumae ドローン作ろうと思ってる。計画はこれ（資料があれば添付）
```

Codex では `$tsukurumae`。ハードウェアやソフトウェアを作る話題では、自動で読み込まれることもある。

最初は**要件定義の段階**。AI が目的を言葉にして「これで合っていますか」と確かめ、開いた質問で方針を一緒に決める。あなたが話題にしていない分野（電装など）も AI から持ち出す。合意するまでコードや CAD は出さない。
合意したら `TSUKURUMAE_REQUIREMENTS.md`（要件定義書）に残し、**実行の段階**に移る。実行中の状態は `TSUKURUMAE_LEDGER.md`（台帳）に記録する。

## インストール

### プラグインとして入れる（おすすめ）

各マシンで1回だけ実行する。Skill を直して push したら、更新コマンドで反映される。

```bash
# Claude Code
claude plugin marketplace add iyasaka0318/tsukurumae
claude plugin install tsukurumae@tsukurumae
# 更新
claude plugin update tsukurumae@tsukurumae
```

```bash
# Codex（未確認。読み込めなければ下の「手でコピー」を使う）
codex plugin marketplace add iyasaka0318/tsukurumae --ref main
codex plugin add tsukurumae@tsukurumae
```

プラグインとして入れると、呼び出しが `/tsukurumae:tsukurumae` になる場合がある（未確認）。

### 手でコピーする

```bash
# Claude Code（全プロジェクト）
cp -r skills/tsukurumae ~/.claude/skills/
# Codex（全プロジェクト）
cp -r skills/tsukurumae ~/.agents/skills/
```

クラウドのセッションでは、ユーザー設定のプラグインが引き継がれないことがある。クラウドで使うプロジェクトでは、そのリポジトリの `.claude/skills/tsukurumae/`（Codex は `.agents/skills/tsukurumae/`）に置く。

台帳があるプロジェクトで毎回確実に使わせたい場合は、そのプロジェクトの `CLAUDE.md` または `AGENTS.md` に次の1行を加える。

```
このプロジェクトでは TSUKURUMAE_LEDGER.md を読み、tsukurumae スキルに従って作業する。
```

## 構成

```
.claude-plugin/               Claude Code のプラグイン定義
.codex-plugin/                Codex のプラグイン定義
.agents/plugins/              Codex のマーケットプレイス定義
skills/tsukurumae/
  SKILL.md                   本体：最優先ルール、始め方、原則、質問の出し方、送信前チェック
  agents/openai.yaml         Codex 用の設定
  references/
    intake.md                要件定義の段階の進め方と、分野ごとの観点
    requirements-template.md 要件定義書の書式
    readiness.md             作業ごとの確定条件
    evidence.md              証拠の強さと検証の段階
    hardware.md              ハードウェアの確認観点
    software.md              ソフトウェアの確認観点
    rework-catalog.md        実例から作った手戻りのパターン
    ledger-template.md       台帳の書式
docs/
  requirements.md            原要件
  design-memo.md             設計メモ
  handoff/                   実際の開発会話から作った実例資料と評価ケース
```

## 使いながら直す

Skill を使っている間に、あなたが AI の振る舞いを直すと（「違う」「先に聞いて」など）、AI がそのプロジェクトの `TSUKURUMAE_FEEDBACK.md` に自動で記録する。頼む必要はない。
たまに、このリポジトリで「フィードバック取り込んで」と言ってその内容を渡せば、AI が仕分けて Skill に反映する。手順は [feedback/README.md](feedback/README.md)。

記録の仕組みは開発中だけのもの。Skill が安定したら、`SKILL.md` の「改善用の記録」の節を消せば止まる。
