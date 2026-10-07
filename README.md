# tsukurumae（つくるまえ）

始める前に、目的から、何をどう進めるかを AI と一緒に考えて決める Agent Skill。Claude Code と Codex で使う。
ハードウェア（ドローン、ロボット、電装、3D プリント、CAD）やソフトウェア（ファームウェア、アプリ、スクリプト、解析）の開発・改修に加え、研究や卒論の計画、調査、企画など、作るものがない場面でも使う。

**使うとどうなるか**
- **AI が、あなたの目的から逆算して、提案や改善案を出してくる。** あなたが考えていなかった方向や、計画を変える案も含む。
- その土台として、分からないまま進めることと、「そういうつもりじゃなかった」が減る。
- そのぶん、最初に聞かれる数は多くなる。
- 結果として、手戻りが減って楽になることもある。

> 開発中。サブエージェントによる比較評価（[run-01](evals/run-01/results.md)、[run-02](evals/run-02/results.md)、[run-03](evals/run-03/results.md)、[run-04](evals/run-04/results.md)、[run-05](evals/run-05/results.md)）を経て、実際に使いながら改善している段階。

## 使い方

```
/tsukurumae ドローン作ろうと思ってる。計画はこれ（資料があれば添付）
/tsukurumae 卒論の計画を立てたい
```

Codex では `$tsukurumae`。

1. **方針を決める（この Skill）**：AI が目的と現状を捉え、目的をよりよく実現する方向を、あなたが考えていなかったものも含めて提案する。判断の軸も目的から立てる。開いた質問で方針を一緒に決める。合意するまで、コード・CAD・章立てなどの成果物は作らない。
2. **合意したら、決めたことを残す。** 形は案件に合わせる。
   - 開発なら `TSUKURUMAE_REQUIREMENTS.md`（要件定義書）。研究計画や企画なら、その計画書そのものに書く。
   - 別の会話で作業が続くなら `TSUKURUMAE_GUIDE.md`（作業する AI 向けの指示書）と、`CLAUDE.md` / `AGENTS.md` に「指示書を読む」の1行。
3. **作業は新しい会話で始める。** Claude Code も Codex も `CLAUDE.md` / `AGENTS.md` を自動で読むので、`/tsukurumae` なしで指示書に従って進む。案を作ったり重要な判断をしたりする前に、作業する AI も目的に立ち返る。
4. **方針を変えたいときは** `/tsukurumae 見直して` で、残した文書を更新する。

## インストール

### プラグインとして入れる（おすすめ）

各マシンで1回だけ実行する。Skill を直して push したら、更新コマンドで反映される。
手でコピーした `~/.claude/skills/tsukurumae` が残っていると、古い版が読まれることがある。プラグインに切り替えたら消す。

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

## 構成

```
.claude-plugin/ .codex-plugin/ .agents/plugins/   プラグインの定義
skills/tsukurumae/
  SKILL.md                    本体：要件定義の考え方と、終わり方
  agents/openai.yaml          Codex 用の設定
  references/
    intake.md                 要件定義の観点の例（縛られない）
    requirements-template.md  要件定義書の書式
    guide-template.md         案件専用の指示書の書式
    feedback.md               改善用の記録の書式
    materials/                指示書を作るときに選んで使う材料（証拠、確定条件、ハード・ソフトの観点、過去の手戻り）
TSUKURUMAE_REQUIREMENTS.md    この開発の要件定義書
TSUKURUMAE_GUIDE.md           この開発の指示書
docs/                         要件の履歴、設計メモ、実例資料（handoff）
evals/                        評価の記録（run-01〜05）
feedback/                     使用中のフィードバックの取り込み
```

## 使いながら直す

Skill を使っている間に、あなたが AI の振る舞いを直すと（「違う」「先に聞いて」など）、AI がそのプロジェクトの `TSUKURUMAE_FEEDBACK.md` に自動で記録する。頼む必要はない。
たまに、このリポジトリで「フィードバック取り込んで」と言ってその内容を渡せば、AI が仕分けて Skill に反映する。手順は [feedback/README.md](feedback/README.md)。

記録の仕組みは開発中だけのもの。Skill が安定したら、`SKILL.md` の「改善用の記録」の節を消せば止まる。
