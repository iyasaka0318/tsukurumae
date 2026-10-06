// ESC 単体・モーター1個の回転試験ファーム（プロペラなし専用）
// 対象: Raspberry Pi Pico W（初代, RP2040）/ Pico SDK
// 版: esc_test v0.1（2026-10-06）
//
// 動作:
//   - 起動直後から 50Hz・停止パルス(STOP_US)を出し続ける
//   - RUN_PIN を GND につなぐと、RAMP_MS かけて MAX_US まで上げる
//   - RUN_PIN を GND から離すと、即座に STOP_US に戻す
//   - 起動時に RUN_PIN が既に GND なら、一度離されるまで回さない（起動直後の誤回転防止）
//   - RUN_PIN は内部プルアップ。ジャンパーが抜けたら HIGH = 停止
//
// 注意: MAX_US=1100 は、ESC が回り始める値に届いていない可能性がある（未確認）。
//       回らなかった場合は、値を上げる前に ESC の設定・プロトコルを確認する。

#include <stdio.h>
#include "pico/stdlib.h"
#include "hardware/pwm.h"
#include "hardware/clocks.h"

// ---- 試験の変数（ここだけ変えれば済むようにしてある） ----
#define ESC_PIN        10      // ESC M1 信号へ（物理ピン14）。仮割当 design/wiring_plan.md
#define RUN_PIN        15      // GND につなぐと回す（物理ピン20）
#define PWM_HZ         50
#define STOP_US        1000    // 停止
#define MAX_US         1100    // 上限（ユーザー指定）
#define RAMP_MS        1000    // STOP_US -> MAX_US に上げる時間。0 なら即座に MAX_US
#define LOOP_MS        10
#define PRINT_MS       200
// --------------------------------------------------------

static uint slice, chan;

static void set_pulse_us(uint32_t us) {
    if (us < STOP_US) us = STOP_US;
    if (us > MAX_US)  us = MAX_US;    // 上限を超える値は出さない
    pwm_set_chan_level(slice, chan, us); // 1 カウント = 1us に設定済み
}

int main(void) {
    // 停止パルスを最初に出す（stdio の初期化より先）
    gpio_set_function(ESC_PIN, GPIO_FUNC_PWM);
    slice = pwm_gpio_to_slice_num(ESC_PIN);
    chan  = pwm_gpio_to_channel(ESC_PIN);

    pwm_config cfg = pwm_get_default_config();
    // システムクロックを 1MHz（1us/カウント）に分周
    float div = (float)clock_get_hz(clk_sys) / 1000000.0f;
    pwm_config_set_clkdiv(&cfg, div);
    pwm_config_set_wrap(&cfg, (1000000 / PWM_HZ) - 1); // 50Hz -> 19999
    pwm_init(slice, &cfg, false);
    set_pulse_us(STOP_US);
    pwm_set_enabled(slice, true);

    gpio_init(RUN_PIN);
    gpio_set_dir(RUN_PIN, GPIO_IN);
    gpio_pull_up(RUN_PIN);

    stdio_init_all();

    bool armed = false;          // 一度 RUN_PIN が HIGH（離れた状態）を見てから true
    uint32_t pulse = STOP_US;
    uint32_t t_print = 0;

    while (true) {
        bool run_req = !gpio_get(RUN_PIN);  // GND で true

        if (!run_req) armed = true;

        if (run_req && armed) {
            if (RAMP_MS == 0) {
                pulse = MAX_US;
            } else {
                uint32_t step = ((MAX_US - STOP_US) * LOOP_MS + RAMP_MS - 1) / RAMP_MS;
                pulse = (pulse + step > MAX_US) ? MAX_US : pulse + step;
            }
        } else {
            pulse = STOP_US;                 // 離したら即停止
        }
        set_pulse_us(pulse);

        uint32_t now = to_ms_since_boot(get_absolute_time());
        if (now - t_print >= PRINT_MS) {
            t_print = now;
            printf("pin=%s armed=%d pulse_us=%lu\n",
                   run_req ? "GND" : "open", armed, (unsigned long)pulse);
        }
        sleep_ms(LOOP_MS);
    }
}
