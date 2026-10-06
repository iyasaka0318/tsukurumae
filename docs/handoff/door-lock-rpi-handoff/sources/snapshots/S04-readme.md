## WIP

```
sudo apt install wiringpi
sudo apt install pigpio
```

``` /dev/input/by-id/usb-USB_Keyboard_USB_Keyboard_SN201706VER1-event-kbd ```

```sudo java -jar servoTester-1.0-SNAPSHOT.jar --Dpi4j.library.path="/opt/pi4j/lib"```

raspi3Bで動かすときはjar内の`natives/linux-arm`に`libconnector.so`を入れる  
gradleで自動化とかしたい気持ち

## セットアップ / デプロイ

```
./gradlew shadowJar
scp build/libs/keylocker2-1.0-SNAPSHOT-all.jar <PI-USER>@<PI-HOST>:/home/<PI-USER>/keylocker/keylocker2-1.0-SNAPSHOT-all.jar
sudo systemctl restart keylocker
```

`/home/<PI-USER>/keylocker/application.conf` はgit管理外(ラズパイ上に直置き)。
ラズパイ側のsystemd unitや`runKey.sh`などの控えは [`deploy/`](deploy/) に置いてある。

### 必須: `pigpiod`デーモンは無効化しておくこと

pi4jの`pi4j-plugin-pigpio`はGPIOハードウェアを直接掴む方式で、`pigpiod`デーモンが
起動していると競合して`PI_INIT_FAILED`で起動失敗する。

```
sudo systemctl stop pigpiod
sudo systemctl disable pigpiod
```

またGPIOへの直接アクセスにはroot権限が必要なので、`keylocker.service`はroot(sudo)で
起動すること(systemdのデフォルトなので通常は意識不要)。

### `application.conf`の`servoLockPosition`/`servoUnlockPosition`について

pi4jの`Pwm.on()`は0〜100の**パーセンテージ**として値を解釈する。以前`pigs`コマンド
(0〜255レンジ)方式に切り替えていた際の名残の値(2.55倍された値)が残っていると
サーボが範囲外のパルス幅を受け取って動かなくなるので注意。現在の正しい値は
`servoLockPosition = 6.0`, `servoUnlockPosition = 11.1`程度。

### 2026-08: 修正履歴

- **Discordbotの互換性修正**: `lavaplayer`が`com.sedmelluq:lavaplayer:1.3.78`(メンテ終了)
  から`dev.arbjerg:lavaplayer:2.2.2`に更新されたことに伴い、音声再生機能
  (`DiscordBot.kt`のAudioPlayer周り)を一旦削除。通知はテキストのみ。
- **FeliCa/GPIO関連**: 一時期`pi4j`を廃止して`pigpiod`(`pigs`コマンド)ベースの実装に
  していたが、原因はGPIO側ではなく`pigpiod`デーモンとpi4jのネイティブアクセスが
  競合していただけだったため、`pi4j`ベースの実装に戻した(上記の`pigpiod`無効化とセット)。
- **slf4j-apiのバージョン固定**: 上記lavaplayerの更新でslf4j-apiが2.0.7に引き上がり、
  logback-classic 1.2.11(SLF4J1.x系バインディング)を認識できずログが全て消えていた。
  `build.gradle.kts`で`slf4j-api`を`1.7.36`に強制固定して解消。
- **FeliCaリーダーのフリーズ検出と復帰**: リーダーが応答しなくなると読み取りスレッドが
  永久にブロックされ、エラーも出ないまま無反応になる不具合があった。フリーズ中に
  取得したスレッドダンプで原因を特定済み。

  **原因**: usb4javaの`IrpQueue.transferBulk`は、**読み取り方向**の転送が
  タイムアウトした場合に例外を投げず**無限にリトライ**する(書き込みは正常にエラーになる)。
  そのため`org.usb4java.javax.timeout`が効いているように見えて表に出てこず、
  `javax.usb.util.DefaultUsbIrp.waitUntilComplete()`のタイムアウト無しの
  `Object.wait()`で待ち続ける。コルーチンの`withTimeoutOrNull`もキャンセルが
  協調的なため効かない。アプリを再起動してもデバイス側は復帰しない。

  **対策**:
  - リトライループの唯一の脱出口は`isAborting()`なので、`RCS380.abort()`
    (両パイプの`abortAllSubmissions()`)を追加し、外部スレッドから解除できるようにした
  - `javax.usb.properties`に`org.usb4java.javax.timeout = 1000`を追加。
    この値が`abort()`が効くまでの最大待ち時間になる(既定5秒では遅い)
  - `RCS380.close()`が`pipeIn`をabortしないまま`sendCommand`を呼んでおり、
    応答しないリーダー相手にclose()自体がハングして再接続不能になっていたのを修正
  - 正常なリーダーはカードが無くても250ms周期で応答を返すので、
    **「最後にUSBコマンドが完了した時刻」**でフリーズを判定(タッチ時刻と違い
    深夜でも更新されるので誤検知しない)。15秒更新が無ければ`abort()`して再接続
  - 30分以内に3回連続でフリーズしたらデバイス自体が応答しないと判断し、
    `uhubctl`でUSBポート(`1-1.1`のポート2、要`apt install uhubctl`)を電源断→再投入
  - ブロッキングな読み取りを`Dispatchers.IO`へ移動(Pi3は4コアで`Default`が
    枯渇していたことがスレッドダンプで判明)

  フリーズの実測頻度は**1日7〜8回**、昼夜を問わず。毎回`abort()`+再接続で復帰しており、
  電源断へのエスカレーションが発動したことはない。

- **「1時間タッチが無ければUSB電源断」のウォッチドッグは削除しないこと**:

  RC-S380には**USB通信は正常なままRF(磁界)側だけが死ぬ**状態がある。この状態でも
  「カード無し」の応答を250ms周期で返し続けるため、**USB応答の途絶を見るフリーズ検知
  では原理的に検知できない**。ログにもエラーが一切出ない。

  復旧手段はUSBポートの電源断のみ。検知できない以上、**定期的に無条件で電源断する以外に
  方法がない**。削除するとRFが死んだ時点で無言のまま停止し続ける(実際に削除して
  FeliCaが2日半死んだ)。深夜の無駄撃ちはこの故障モードを拾うための代償。

- **再接続は成功するまで再試行する**: `FelicaService.open()`を1回呼ぶだけだと、その瞬間に
  デバイスが見えないと**二度と復帰せずログにも何も残らない**。指数バックオフ
  (最大30秒間隔)で再試行し、失敗を必ずログに残す。オープン成功時も
  `FeliCa reader opened`を出す(成功時が無言だと生死がログから判別できない)。

- **ポーリング応答時間の記録(調査用・判定には使っていない)**: RF停止を検知する
  手掛かりになるか確認するため、5分ごとに`felica poll stats: n=... min=... avg=... max=...`
  を出している。ポーリングは「11ms待って応答が無ければ諦めろ」という命令なので、
  RFが正常なら実際に待った時間が乗る。RF回路が死んでいる状態でfirmwareが待たずに
  即答しているなら分布が変わるはずで、そうであれば検知信号として使える。
  次にRF停止が起きたときのログを、正常時と比較して判断すること。

```
grep -a "felica poll stats" /home/<PI-USER>/keylog2.txt
```

- **後始末は必ず時間で打ち切る**: usb4javaの`AbstractIrpQueue.abort()`は
  **タイムアウト無しの`wait()`**で進行中の転送の完了を待つ。電源断でデバイスが
  消えた直後は完了扱いにならず戻ってこないことがある。ここで止まると
  `@Synchronized`の`close()`がモニタを握ったままになり、再接続の`open()`も
  待たされて**リーダー全体が無言で停止する**(実際に40分停止した)。
  `reader.close()`と`reader.abort()`は別スレッドで実行し5秒で打ち切る。

- **ウォッチドッグは状態を見ずに必ず開き直す**: 「既に接続されていれば再接続を
  見送る」という最適化を入れたところ、ポーリング側の復旧が固まったまま
  `felicaReader`がnullにならず、`isConnected()`がtrueを返すため
  **最後の砦であるウォッチドッグが仕事を見送った**。二重に開いても
  `open()`が先頭で`close()`を呼ぶので実害はない。

- **USBエラーを生存とみなさない**: `RCS380.sendCommand()`は`UsbException`を握り潰して
  `null`を返す。フリーズ判定の`lastCommandTime`を戻り値に関わらず更新していたため、
  **USBを抜くと死んだハンドルを250ms周期で叩き続けながら「生きている」と判定され続け、
  フリーズ検知が永久に発火しなかった**(差し直しても古いハンドルを掴んだままで復帰しない)。
  応答が取れたときだけ更新するよう修正。カード無しでも`80 00 00 00`が返るので、
  正常時は250ms周期で必ず更新される。
- **磁気リーダーの二重再接続バグ修正**: `Application.kt`の`onError`ハンドラと
  `MagneticReader`内部の`scheduleReconnect()`が同じ読み取りエラーで**両方**
  再接続を仕掛けていたため、1回のエラーで`open()`が二重に走っていた。
  `read()`はブロッキングで`job.cancel()`が効かず、読み取りループが毎回
  `input`を取り直す作りだったため、**古いjobと新しいjobが同一ストリームから
  1byteずつ交互に読む**状態になり、24byteのイベント境界が永久にずれる。
  結果、カードは読めて音も鳴るのにEnterキーが検出されず、エラーも出ないまま
  無反応になっていた(ラズパイ再起動でしか復旧しない)。対策として:
  - 再接続経路を`MagneticReader`側に一本化
  - 世代番号で古い読み取りjobを確実に停止
  - `open()`時に既存ストリーム/jobを必ず始末
  - 1byteずつではなく`readFully()`で24byte単位に読む
  - `input_event.type`が範囲外(境界ずれ)を検知したら自動で開き直す
  - ブロッキングreadを`Dispatchers.IO`に移動(Pi3は4コアで`Default`を占有するため)
  - `/dev/input/eventN`が作り直された場合に開き直す(1分ごとに確認)
  - openが連続20回失敗したら`uhubctl`でUSBポート(`1-1`のポート3)を電源断→再投入