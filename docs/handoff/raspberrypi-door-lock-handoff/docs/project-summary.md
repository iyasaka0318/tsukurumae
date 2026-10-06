# プロジェクト概要

## 目的
研究室の電子錠を運用しながら、FeliCa、磁気カード、Discord通知、GPIO駆動の問題を切り分ける。ユーザーは鍵のコードを担当し、Discord bot修正は後輩に引き継ぐ案だった。

## 技術構成（会話で確認できた範囲）
- Raspberry Pi上のKotlin/JVMアプリ。Ktorで8080番の管理画面。
- GPIO／サーボはPi4J pigpioプラグインと `libpigpio.so`。外部HOCON設定を読む。
- FeliCaはSony RC-S380/S（USB ID 054c:06c1）。スタックに `javax.usb`、usb4java/libusb、RCS380送信コード。
- 磁気リーダーはUSB疑似キーボード／Linux evdevとして読む構成。アプリログにMagneticReaderイベント。
- SQLite、Web画面、Discord連携。別のPython discord.py botがテキスト投稿「Ping at」を監視し、ボイスへ短時間接続して音声再生後に切断。
- systemdのkeylocker unitがscreen、runKey.sh、fat JARを起動。tee追記ログとlogrotate copytruncateをユーザーが設定。
- `uhubctl` でリーダー接続ポート `1-1.1:2` を電源サイクルする運用を試した。
- ビルド・配布の手順は `./gradlew shadowJar`、JARをscp、Piで `sudo systemctl restart keylocker`。

## 到達点（貼付出力で確認できること）
- JVM backendとshadowJarのビルド成功通知があった。Piでの正常動作を意味しない。
- 手動JAR起動時にPiGpio `PI_INIT_FAILED`、native SIGSEGVを観測。pigpiod停止だけでは初期化エラーは解消しなかった。
- systemd起動後にHTTP 200を確認した一方、UI上では開錠でもモータ不動という報告があった。別ログではサーボ角度指令とOFFが出ていた。
- thread dumpに同期USB転送完了待ち（`DefaultUsbIrp.waitUntilComplete`、`Pipe.syncSubmit`）があった。
- FeliCaの応答なし検知（約15–19秒）、USB電源サイクル、reader reopened、poll統計が後日ログに現れた。平均は約17ms、通常らしい最大約22–27ms、観測された大きな最大値473ms。RF故障時との比較は未取得。
- 60分アイドル電源サイクルが1時間間隔で繰り返され、reopenedが複数回出る期間があった。再オープン競合は仮説で未確定。
- 磁気readerはある試験時にevdevイベント、magID、解錠判定が記録された。長期状態は未確定。
- 2026-08-28のjournalctl抜粋では、keylocker unitが約25秒差で二度stop/start。これはサービス再起動であり、Pi rebootの証拠ではない。ユーザーの記憶でもPiを二度再起動しておらず、pgrepはJava一つ。
- 貼付ログに未来日付らしい時刻が混在。Pi時計変更・ログ混在などが考えられるが未確認。

## 未確認
FeliCa故障の物理／ソフト層、poll時間でRF故障を識別できるか、電源サイクル後のUSBハンドル再生成、磁気readerの入力停止層、GPIO指令とモータ不動の物理原因、常時接続botの過去ループ原因、Pi本番ファイルとGit作業ツリーの一致。

## 継続時のレビュー要件
ユーザーは直近デプロイ後の不調について、Codexに変更レビューも引き継ぐよう求めていた。今回取得できた情報には電子錠リポジトリの作業ツリー、デプロイ直前のdiff、JARとcommitの対応、Pi上のJAR checksumがないため、コードレビュー自体は未実施。次の担当者は正しいIoTouchDoor作業コピーを開き、まず `git status` とbranch／commitを確認し、未コミット変更を保護したうえで、デプロイされた版とのdiffをレビューする。リポジトリや基準版が特定できないまま原因を断定したり、コード変更・再デプロイをしない。