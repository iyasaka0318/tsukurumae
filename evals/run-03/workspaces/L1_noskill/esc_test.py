# esc_test.py  ESC 単体・モーター 1 個の回転試験（プロペラなし）
# 対象: Raspberry Pi Pico W / MicroPython
#
# 動作:
#   - ESC 信号: 50Hz の PWM、パルス幅 1000us = 停止、上限 1100us
#   - 起動後しばらく 1000us を出し続けて ESC をアームさせる
#   - RUN_PIN のジャンパを GND につなぐと、上限までゆっくり上げて回す
#   - ジャンパを外すと即座に 1000us に戻す
#   - 起動時にジャンパが GND につながっていたら、外すまで回さない
#   - 例外・Ctrl-C で終了するときは 1000us に戻してから止める
#
# 配線（ピン番号は下の定数で変更可）:
#   GP2  -> ESC の M1 信号線
#   GND  -> ESC の GND（必ず共通にする）
#   GP16 -> ジャンパ（GND につなぐと回る）
#   Pico の電源はこの試験では USB のみ。MINI360 は VSYS につながない。

from machine import Pin, PWM
import time

# ---- 設定 ----
ESC_PIN = 2          # ESC 信号を出すピン (GP2)
RUN_PIN = 16         # 回転許可ジャンパのピン (GP16)
FREQ_HZ = 50
STOP_US = 1000       # 停止
MAX_US = 1100        # 上限（これを超える値は出さない）
ARM_TIME_S = 3       # 起動時に停止パルスを出し続ける時間
RAMP_TIME_S = 2.0    # 停止から上限まで上げる時間
LOOP_MS = 20         # 制御周期（50Hz の 1 周期）
DEBOUNCE_COUNT = 3   # ジャンパ判定の連続一致回数

assert STOP_US <= MAX_US <= 1100, "上限 1100us を超えないこと"

led = Pin("LED", Pin.OUT)   # Pico W の基板 LED
run_in = Pin(RUN_PIN, Pin.IN, Pin.PULL_UP)  # GND でオン（0）

esc = PWM(Pin(ESC_PIN))
esc.freq(FREQ_HZ)


def set_us(us):
    # 範囲外の値は必ず切り詰める
    if us < STOP_US:
        us = STOP_US
    if us > MAX_US:
        us = MAX_US
    esc.duty_ns(int(us * 1000))
    return us


def jumper_on():
    return run_in.value() == 0


def main():
    set_us(STOP_US)
    print("ESC アーム中: {} 秒間 {}us を出力".format(ARM_TIME_S, STOP_US))
    t_end = time.ticks_add(time.ticks_ms(), ARM_TIME_S * 1000)
    while time.ticks_diff(t_end, time.ticks_ms()) > 0:
        led.toggle()
        time.sleep_ms(100)
    led.off()

    # 起動時にジャンパがつながっていたら、外されるまで待つ
    if jumper_on():
        print("ジャンパが GND につながっています。外してください。")
        while jumper_on():
            led.toggle()
            time.sleep_ms(250)
        led.off()

    print("準備完了: ジャンパを GND につなぐと回ります（上限 {}us）".format(MAX_US))

    step = (MAX_US - STOP_US) * LOOP_MS / (RAMP_TIME_S * 1000)
    current = float(STOP_US)
    on_count = 0
    last_print = -1

    while True:
        if jumper_on():
            on_count += 1
        else:
            on_count = 0

        if on_count >= DEBOUNCE_COUNT:
            current = min(current + step, MAX_US)   # ゆっくり上げる
            led.on()
        else:
            current = STOP_US                       # 外したら即停止
            led.off()

        out = set_us(current)
        if int(out) != last_print and (int(out) % 10 == 0):
            print("出力: {}us".format(int(out)))
            last_print = int(out)

        time.sleep_ms(LOOP_MS)


try:
    main()
finally:
    # どんな終わり方でも停止パルスにしておく
    set_us(STOP_US)
    led.off()
    print("停止パルス {}us にしました。電池を外してから作業してください。".format(STOP_US))
