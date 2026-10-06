# FeliCa 無反応の観測手順（O1）

すべて **Raspberry Pi に SSH でログインした bash** で実行する（Windows の PowerShell ではない）。
1つずつ貼り付けて実行し、出力をそのまま貼って送ってください。Webhook URL やトークンが出力に含まれていたら、その部分は伏せてください。
どのコマンドも読み取りだけで、状態は変えない（例外は 3-6 の SIGQUIT。下に説明あり）。

## 1. サービスを特定する（平常時に1回）

1-1. 電子錠らしいサービスを探す
```
systemctl list-units --type=service --all | grep -i -E 'lock|door|felica|nfc|key'
```
見えたサービス名を、以下の `<SERVICE>` に入れる。

1-2. 実行ユーザーと起動コマンドを見る
```
systemctl cat <SERVICE>
```
`User=` の行（なければ root）、`ExecStart=`（jar の場所）、`Restart=` を見る。

1-3. 既存の定期処理（定期再起動・USB リセットなどの保険）を洗い出す
```
systemctl list-timers --all
```
```
sudo crontab -l
```
```
crontab -l
```
ここで見つかった処理は、役割が分かるまで消さない。

## 2. 平常時の基準を取る（平常時に1回）

2-1. リーダーの USB 上の見え方
```
lsusb
```
2-2. 電源の状態（0x0 なら低電圧・スロットリングの記録なし）
```
vcgencmd get_throttled
```
2-3. 関係しそうなカーネルモジュール
```
lsmod | grep -i -E 'port100|pn533|nfc'
```
2-4. 起動してからの時間と、OS の起動履歴
```
uptime
```
```
journalctl --list-boots | tail -n 5
```

## 3. 無反応が起きたとき（USB を抜く前に）

USB を抜く前に、次をこの順で取る。抜き差しすると、この状態の観測は二度と取れない。
入室を急ぐ場合は 3-1〜3-3 だけでもよい。

3-1. 時刻
```
date
```
3-2. USB 上にリーダーが見えているか（2-1 と比べる）
```
lsusb
```
3-3. カーネルのログ（切断・再接続・低電圧・エラー）
```
sudo dmesg -T | tail -n 80
```
3-4. 電源の状態
```
vcgencmd get_throttled
```
3-5. アプリのログ（直近1時間）
```
sudo journalctl -u <SERVICE> --since "1 hour ago" --no-pager | tail -n 200
```
3-6. アプリのスレッドダンプ（読み取りスレッドが固まっていないか）
まずプロセス番号を見る：
```
systemctl show -p MainPID <SERVICE>
```
次に、その番号に SIGQUIT を送る。Java（HotSpot）はこれで**終了せず**、スレッドの一覧をサービスのログに出す。
```
sudo kill -3 <MainPID の番号>
```
出力を見る：
```
sudo journalctl -u <SERVICE> --since "2 min ago" --no-pager
```
（起動オプションに `-Xrs` があると SIGQUIT で止まる可能性がある。1-2 の ExecStart に `-Xrs` があれば 3-6 は飛ばす）

3-7. 可能なら、USB を抜く前に**アプリだけ再起動**して直るかを見る（直ればアプリ側、直らなければリーダー/USB 側の手がかり）
```
sudo systemctl restart <SERVICE>
```
直らなければ、いつも通り USB を抜き差しする。

## 4. 抜き差しの後

4-1. 再接続がどう見えたか
```
sudo dmesg -T | tail -n 30
```
