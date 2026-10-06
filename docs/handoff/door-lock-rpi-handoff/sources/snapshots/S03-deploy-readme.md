# ラズパイ側の設定ファイル

`<PI-HOST>` に置いてある設定の控え。これらは本来ラズパイ上にしか存在せず、
SDカードが飛ぶと失われるのでここに複製してある。
**ここを編集しても実機には反映されない**ので、実機を直したらこちらも更新すること。

| ファイル | 配置先 | 状態 |
|---|---|---|
| `runKey.sh` | `/home/<PI-USER>/runKey.sh` | 適用済み |
| `keylocker.service` | `/etc/systemd/system/keylocker.service` | 適用済み |
| `discordbot.service` | `/etc/systemd/system/discordbot.service` | 適用済み |
| `usb-power-fix.service` | `/etc/systemd/system/usb-power-fix.service` | 適用済み |
| `logrotate-keylocker` | `/etc/logrotate.d/keylocker` | 適用済み |
| `50-usb-power.rules` | `/etc/udev/rules.d/50-usb-power.rules` | **未適用(推奨)** |
| `application.conf.example` | `/home/<PI-USER>/keylocker/application.conf` | 実ファイルはgit管理外 |

git管理外のものが他にもある。

- `/home/<PI-USER>/keylocker/application.conf` — トークンを含むため
- `/home/<PI-USER>/keylocker/keylocker2.db` — カード登録とログのSQLite
- `/home/<PI-USER>/bot.py` と `/home/<PI-USER>/chime.mp3` — Discordのチャイム再生側
- `/home/<PI-USER>/bot_env/` — bot.py用のPython venv

## 前提

```
sudo apt install pigpio uhubctl
sudo systemctl stop pigpiod
sudo systemctl disable pigpiod
```

`pigpiod` は**必ず無効化しておくこと**。pi4jの`pi4j-plugin-pigpio`はGPIOを直接掴む
方式なので、デーモンが起動しているとGPIOを奪い合って`PI_INIT_FAILED`で起動失敗する。

`uhubctl` はFeliCaリーダーが3回連続でフリーズしたときのUSBポート電源断に使う。

## 残っている改善案

- `keylocker.service` に `Restart=always` / `RestartSec=5` を足す。
  クラッシュしても自力で復帰するようになる
- `Application.kt` のデバッグ用 `readLine()` ループを `?: break` にする。
  これで `screen` が不要になり、systemd unit を素直な `java -jar` にできて
  ログも journald に任せられる
- `50-usb-power.rules` の適用
