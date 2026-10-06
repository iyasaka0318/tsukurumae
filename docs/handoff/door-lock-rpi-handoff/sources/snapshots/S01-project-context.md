# プロジェクト引き継ぎ

このリポジトリで作業する AI 向けの前提知識です。ルールは [AI_RULES.md](AI_RULES.md)、役割分担は [AI_WORKFLOW.md](AI_WORKFLOW.md)、セットアップとデプロイ手順は [../Readme.md](../Readme.md) にあります。ここには**それらに書いていない、実機を触って分かったこと**をまとめます。

## これは何か

研究室のドアに付いている**電子ロック**です。Raspberry Pi 3 (`<PI-HOST>`, 64bit, 4コア, メモリ1GB) の上で1つの JVM プロセスとして動いています。

- FeliCa (Sony RC-S380) と磁気カードで解錠する
- サーボモーターで物理的に施錠・解錠する
- ドアベルのボタンを押すと Discord に通知が飛ぶ
- Ktor の Web 管理画面 (`:8080`) でカード登録と履歴閲覧ができる

**止まると人が部屋に入れなくなります。** 中からは物理的に出られるので閉じ込めは起きませんが、朝一番に来た人が入れないと詰みます。

## 最重要:このリポジトリではテストができない

GPIO と USB の実機に依存しているため、**手元で動作確認する方法がありません**。

- テストは `src/jvmTest/` に 1 ファイルあるだけで、実質機能していない
- CI もない
- formatter, lint, typecheck の設定もない

**実際に使える検証は次の2つだけです。**

```bash
./gradlew compileKotlinJvm   # コンパイル確認(速い)
./gradlew shadowJar          # fat jar 生成(初回は依存DLで5〜10分)
```

存在しないコマンドを探さないでください。`./gradlew test` は通りますが、意味のあるテストはありません。

動作確認は**ユーザーが実機に転送して再起動する**ことでしか行えません。**デプロイ(`scp` と `systemctl restart`)は AI 側で実行しないでください。**

## コードの地図

実装の中心は `src/jvmMain/kotlin/` です。JS 側 (`src/jsMain/`) は管理画面のフロントで、ここ数か月触っていません。

| パス | 役割 | 状態 |
|---|---|---|
| `com/<PKG-1>/Application.kt` | 起動と全体の配線。267行 | **変更が集中する場所** |
| `com/<PKG-1>/felica/FelicaReader.kt` | FeliCa のポーリングとフリーズ検知 | 何度も直している |
| `com/<PKG-1>/felica/FelicaService.kt` | FeliCa の open/close の入口 | |
| `com/<PKG-1>/magnetic/MagneticReader.kt` | 磁気カード。evdev を直接読む | |
| `com/<PKG-1>/door/DoorByGpio.kt` | サーボとドアセンサ (pi4j) | |
| `jp/<PKG-3>/RCS380.kt` | RC-S380 の USB ドライバ。外部からの移植 | **危険地帯** |
| `net/<PKG-2>/DiscordBot.kt` | Discord 通知 | 後輩が改修中 |
| `net/<PKG-2>/DoorBell.kt` | ドアベルのボタン (pi4j)。Discord とは無関係 | |
| `deploy/` | ラズパイ上の systemd unit などの控え | 編集しても実機には反映されない |

## ハードウェアの故障モード

ここが本題です。**このリーダーは壊れ方が3種類あり、それぞれ検知可否が違います。**

### 1. USB 転送のハング(検知できる)

usb4java の `IrpQueue.transferBulk` は、**読み取り方向**の転送がタイムアウトすると例外を投げず**無限にリトライ**します(書き込みは正常にエラーになる)。そのため `javax.usb.util.DefaultUsbIrp.waitUntilComplete()` のタイムアウト無しの `Object.wait()` で永久に待ち続けます。

- コルーチンの `withTimeoutOrNull` は効きません。キャンセルが協調的で、ブロッキング呼び出しは中断できないためです
- 唯一の脱出口はリトライループ内の `isAborting()` の確認なので、**別スレッドから `RCS380.abort()` を呼ぶ**しかありません
- `javax.usb.properties` の `org.usb4java.javax.timeout = 1000` が、`abort()` が効くまでの最大待ち時間になります

検知は「最後に **成功した** USB コマンドの時刻」で行います。正常なリーダーはカードが無くても 250ms 周期で `80 00 00 00`(カード無し)を返すため、深夜でも更新され続けます。5秒更新が無ければ異常です。

**`RCS380.sendCommand()` は `UsbException` を握り潰して `null` を返します。** 戻り値を見ずに「呼び出しが返ってきた = 生きている」と判定すると、USB を抜いた後も生存扱いになり検知が永久に発火しません。

### 2. RF 停止(**検知できない**)

USB 通信は完全に正常なまま、**RF(磁界)側だけが死ぬ**状態があります。

この状態のリーダーも「カード無し」の応答を 250ms 周期で返し続けるため、**「誰もかざしていない」と完全に同一のバイト列**になります。区別する情報が送られてきません。ログにもエラーが一切出ません。

復旧手段は **USB ポートの電源断のみ**です。検知できない以上、**1時間タッチが無ければ無条件で電源断する**という力技しかありません。

> このウォッチドッグを「深夜に無駄撃ちしているだけ」と判断して削除したら、FeliCa が2日半死んだまま無言になりました。**消さないでください。**

### 3. 後始末が戻ってこない

usb4java の `AbstractIrpQueue.abort()` は**タイムアウト無しの `wait()`** で進行中の転送の完了を待ちます。電源断でデバイスが消えた直後は完了扱いにならず、戻ってこないことがあります。

ここで止まると `@Synchronized` の `close()` がモニタを握ったままになり、再接続の `open()` も待たされ、**リーダー全体が無言で停止します**(実際に40分停止)。

**後始末は必ず時間で打ち切ってください。** `FelicaReader.runBounded()` がその役割です。

## 試して駄目だったこと

同じ提案が繰り返されるのを避けるため、記録しておきます。

| 試したこと | 結果 |
|---|---|
| アプリを3時間ごとに再起動 | **無意味。** デバイス側の状態は変わらない |
| `withTimeoutOrNull` で USB コマンドを打ち切る | **効かない。** ブロッキング呼び出しはキャンセルできない |
| USB 省電力の無効化 (`usb-power-fix.service`) | 効果なし。しかも起動時1回しか適用されない |
| pi4j をやめて `pigs` コマンドで GPIO を叩く | 毎秒60回 fork+exec で CPU を食い潰した。pi4j に戻した |
| USB の物理抜き差し | アプリが古いハンドルを掴んだままなので**復帰しない** |
| 「既に接続済みなら再接続を見送る」最適化 | `isConnected()` が信用できず、**最後の砦が仕事を見送った** |

## 踏みやすい罠

- **`pigpiod` は必ず無効化**。pi4j が GPIO を直接掴むので、デーモンが動いていると `PI_INIT_FAILED` で起動失敗する
- **`application.conf` の `servoLockPosition` / `servoUnlockPosition`** は 0〜100 のパーセンテージ。`pigs` 時代の名残(2.55倍された値)が残るとサーボが全く動かない。正しい値は `6.0` と `11.1`
- **`Application.kt` の `readLine()` ループ**。stdin が EOF だと待ち時間ゼロの無限ループで1コアを食う。systemd unit が `screen` を噛ませているのはこれを避けるため
- **`logback.xml` で JDA のログが ERROR に抑制されている**。Discord のボイス接続を調査するときは DEBUG に上げないと何も見えない
- **ログのローテーションには `copytruncate` が必須**。`tee -a` が fd を保持し続けるため、通常の rename 方式だと新しいログが永遠に空になる
- **`Dispatchers.Default` はコア数(4)しかない**。ブロッキング I/O を載せると他の処理まで巻き添えで止まる。必ず `Dispatchers.IO` を使う

## ログの読み方

すべて `/home/<PI-USER>/keylog2.txt`(日次ローテーション、7世代)。`journalctl -u keylocker` にはアプリのログは出ません(`screen` 経由のため)。

```bash
# 異常の一覧(古いログも含めて時系列に)
zcat -f /home/<PI-USER>/keylog2.txt* 2>/dev/null | grep -a "frozen\|freeze #\|reopen\|idle for over\|Power-cycling\|desync\|Mag read error" | sort | tail -40

# 応答時間の推移
zcat -f /home/<PI-USER>/keylog2.txt* 2>/dev/null | grep -a "felica poll stats" | sort | tail -20

# FeliCa で解錠できた時刻(%G で始まるのは磁気カード)
zcat -f /home/<PI-USER>/keylog2.txt* 2>/dev/null | grep -a "touch:" | grep -av "%G" | sort | tail -30
```

古いログにバイナリが混ざっているため、`grep` には `-a` が要ります。

## いま進行中の調査

**RF 停止を応答時間で検知できないか試しています。** 判定はまだしておらず、5分ごとに記録だけしています。

- ポーリングは「11ms 待って応答が無ければ諦めろ」という命令
- RF が正常なら磁界を焚いて実際に待つため、その時間が乗る
- **正常時のベースラインは `avg=17.0ms`**(min 15.8 / max 23)。数日間ほぼ変動なし
- RF が死んだ状態で firmware が待たずに即答しているなら、`avg` が 6ms 前後に落ちるはず

**まだ RF 停止のサンプルが取れていません。** 次に「朝一番のタッチが失敗した日」が出たら、その前夜の `avg` と比較して判定します。

外れた場合(`avg` が変わらない場合)は、この方法では検知できないという結論になり、1時間ウォッチドッグのまま運用を続けます。
