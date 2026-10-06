// frame.scad  Pico W ドローン用フレーム たたき台（OpenSCAD）
// 状態: 仮の寸法を含む草案。印刷前に [A] の値を実物で測って書き換えること。
// 単位: mm。原点 = 機体中心（モーター 4 個の中心）。+X = 前、+Y = 左。
//
// 配置（上から見て）:
//   前 : 4in1 ESC（板の上、穴止め）
//   後 : Pico W（板から立てた柱の上。ピン下向きのジャンパ線は柱の間に垂れる。USB は後ろの縁）
//   左 : MPU-6050（板の上、ピン上向き）
//   右 : MINI360（板の上、ピン上向き、結束バンドで固定）
//   下 : 電池（中央、ベルトを 2 つのスリットに通して巻く）

$fn = 40;

// ===== [A] 実測していない仮の値（必ず実測して書き換える） =====
prop_d         = 63.5;  // 仮: プロペラ直径（2.5 インチ）
motor_pcd      = 9.0;   // 仮: モーター取付ネジが並ぶ円の直径
motor_screw_d  = 2.2;   // 仮: M2 用
motor_hole_ang = 45;    // 仮: 取付ネジの角度
motor_center_d = 5.5;   // 仮: シャフト・クリップの逃げ穴
motor_pad_d    = 16;    // 仮: モーター台の直径（モーター底面より少し大きく）
esc_hole       = 20;    // 仮: ESC 取付穴ピッチ（20x20 か 16x16 か）
esc_screw_d    = 3.2;   // 仮: M3 用（M2 なら 2.2）
esc_board      = 27;    // 仮: ESC 基板の一辺
pico_pillar_h  = 30;    // 仮: Pico 下のピン＋ジャンパ端子＋線の曲げ代
mpu_l = 21; mpu_w = 16;                  // 仮: GY-521 基板寸法
mpu_holes   = [[-7.5, 5.5], [7.5, 5.5]]; // 仮: 基板中心から見た取付穴位置
mpu_screw_d = 3.2;                       // 仮
mini_l = 17; mini_w = 11;                // 仮: MINI360 基板寸法
batt_w  = 30;           // 仮: 電池の幅
strap_w = 10;           // 仮: ベルト幅
strap_t = 2;            // 仮: ベルト厚み

// ===== [B] データシート由来の値（Pico W、データシートで再確認すること） =====
pico_l = 51; pico_w = 21;
pico_hole_x = 47; pico_hole_y = 11.4;
pico_tap_d  = 1.8;      // M2 タッピングねじの下穴（印刷の具合で調整）

// ===== [C] 設計で決めた値（変えてよい） =====
body_l   = 84;          // 本体板の長さ（X）
body_w   = 60;          // 本体板の幅（Y）
plate_t  = 3;           // 本体板の厚み
arm_t    = 4;           // アームの厚み
arm_w    = 8;           // アームの幅
prop_gap = 6;           // プロペラと本体・隣のプロペラとのすき間
pillar_d = 5;           // Pico 用の柱の直径

// 配置
pico_cx = -body_l/2 + pico_l/2 + 1;           // USB 端を後ろの縁に寄せる
esc_cx  =  body_l/2 - esc_board/2 - 2;
mpu_c   = [-18,  body_w/2 - mpu_w/2 - 5];
mini_c  = [-18, -(body_w/2 - mini_w/2 - 5)];
strap_x = 0;
strap_y = batt_w/2 + strap_t + 1;

// ===== モーター位置の計算 =====
// 上から見て、プロペラの円が本体板（長方形）に prop_gap 以上離れる位置を求める。
// Pico が柱で高い位置にあるため、プロペラが本体の上を通る配置は避けている。
a = body_l/2; b = body_w/2; R = prop_d/2 + prop_gap;
m_body = ((a + b) + sqrt(pow(a + b, 2) - 2*(a*a + b*b - R*R))) / 2;
m_adj  = (prop_d + prop_gap) / 2;             // 隣どうしのプロペラが当たらない条件
m = max(m_body, m_adj);                       // モーター座標 (±m, ±m)

assert(m >= a && m >= b, "モーター位置の計算が前提から外れています");
echo(str("モーター中心 (±", m, ", ±", m, ")  対角軸間距離 = ", 2*sqrt(2)*m, " mm"));
echo("注意: [A] の値は仮です。実測値に置き換えてから印刷してください。");

// ===== 形状 =====
module rrect(l, w, r) { offset(r) offset(delta = -r) square([l, w], center = true); }

module body2d() { rrect(body_l, body_w, 4); }

module arms2d() {
  for (sx = [-1, 1], sy = [-1, 1])
    hull() {
      translate([sx*(a - 6), sy*(b - 6)]) circle(d = arm_w*1.5);
      translate([sx*m, sy*m]) circle(d = motor_pad_d);
    }
}

module holes2d() {
  // モーター
  for (sx = [-1, 1], sy = [-1, 1]) translate([sx*m, sy*m]) {
    circle(d = motor_center_d);
    for (k = [0:3]) rotate(motor_hole_ang + 90*k)
      translate([motor_pcd/2, 0]) circle(d = motor_screw_d);
  }
  // ESC
  for (sx = [-1, 1], sy = [-1, 1])
    translate([esc_cx + sx*esc_hole/2, sy*esc_hole/2]) circle(d = esc_screw_d);
  // MPU-6050
  for (h = mpu_holes) translate(mpu_c + h) circle(d = mpu_screw_d);
  // MINI360 用の結束バンド穴（基板の両脇）
  for (sy = [-1, 1])
    translate([mini_c[0], mini_c[1] + sy*(mini_w/2 + 2)]) square([4, 2], center = true);
  // 電池ベルトのスリット
  for (sy = [-1, 1])
    translate([strap_x, sy*strap_y]) square([strap_w + 1, strap_t + 1], center = true);
}

module pico_pillars() {
  for (sx = [-1, 1], sy = [-1, 1])
    translate([pico_cx + sx*pico_hole_x/2, sy*pico_hole_y/2, 0])
      cylinder(d = pillar_d, h = plate_t + pico_pillar_h);
}

module pico_taps() {
  for (sx = [-1, 1], sy = [-1, 1])
    translate([pico_cx + sx*pico_hole_x/2, sy*pico_hole_y/2, plate_t + pico_pillar_h - 8])
      cylinder(d = pico_tap_d, h = 10);
}

module frame() {
  difference() {
    union() {
      linear_extrude(plate_t) body2d();
      linear_extrude(arm_t) arms2d();
      pico_pillars();
    }
    translate([0, 0, -1]) linear_extrude(arm_t + 2) holes2d();
    pico_taps();
  }
}

frame();

// 配置確認用の部品の外形（印刷物には含まれない。F5 プレビューで半透明表示）
%translate([pico_cx, 0, plate_t + pico_pillar_h]) translate([-pico_l/2, -pico_w/2, 0]) cube([pico_l, pico_w, 1]);
%translate([esc_cx, 0, plate_t]) translate([-esc_board/2, -esc_board/2, 0]) cube([esc_board, esc_board, 1]);
%translate([mpu_c[0], mpu_c[1], plate_t]) translate([-mpu_l/2, -mpu_w/2, 0]) cube([mpu_l, mpu_w, 1]);
%translate([mini_c[0], mini_c[1], plate_t]) translate([-mini_l/2, -mini_w/2, 0]) cube([mini_l, mini_w, 1]);
%for (sx = [-1, 1], sy = [-1, 1]) translate([sx*m, sy*m, arm_t + 12]) cylinder(d = prop_d, h = 0.5);
