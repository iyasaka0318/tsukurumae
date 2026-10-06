// ドローン フレーム v0.1（仮モデル）  2026-10-06
// ※ 本番ではない。値の多くは「仮」。実測値が来たら下の変数を差し替える。
// ※ OpenSCAD でのレンダリング・印刷・組み立ては未確認。
//
// 座標: +X が前、+Y が左、Z=0 がプレート下面。
// 配置（仮決定）:
//   上面: 前から ESC → GY-521 と MINI360（中央付近）→ Pico W（ピン下向き・USB は後ろ）
//   下面: 電池をベルトで留める。ベルトは下面のループ（ラグ）に通し、上面の部品を押さない（R9）
//
// PART を切り替えて出力:
//   "frame"       : フレーム（仮）
//   "motor_gauge" : モーター取付穴の試験片（今すぐ印刷してよい）
//   "preview"     : フレーム＋部品の占有範囲＋プロペラ円（確認用。印刷しない）
PART = "preview";

// ===== 未確認・仮の値（状態は台帳を参照） =====
PROP_D  = 65;     // 仮。プロペラ径（Q3）
PROP_GAP = 6;     // 仮。プロペラ同士、プロペラと本体の余裕
PROP_PLANE_H = 12;// 仮。プレート上面からプロペラ下面まで（モーター高さで決まる）

MOTOR_HOLE_SPACING = 9;   // 仮。1104 の取付穴の間隔（要確認・試験片で確かめる）
MOTOR_HOLE_D   = 2.2;     // 仮。M2 用の通し穴
MOTOR_CENTER_D = 5.5;     // 仮。軸と C クリップの逃げ
MOTOR_PAD_D    = 16;      // 仮。モーター台の径

ESC_BOARD = 27;           // 仮。ESC 外形（正方形と仮定）（Q5）
ESC_HOLE_SPACING = 20;    // 仮。ESC 取付穴の間隔（Q5）
ESC_HOLE_D = 2.2;         // 仮
ESC_STANDOFF_H = 3;       // 仮。ESC 裏面の部品逃げ
ESC_H = 6;                // 仮。ESC 部品込みの厚さ

PICO_L = 51;  PICO_W = 21;            // メーカー公称（要照合）
PICO_HOLE_DX = 47; PICO_HOLE_DY = 11.4; // メーカー公称（要照合）
PICO_HOLE_D  = 1.8;       // 仮。M2 セルフタップ用の下穴（試験片で確かめる）
PICO_UNDER_H = 12;        // 仮。ピン下向き＋ジャンパー線込みの下方向の高さ（Q6）
PICO_TOP_H   = 4;         // 仮。部品面の上の高さ
USB_PLUG_L   = 30;        // 仮。USB プラグ＋ケーブルの曲げに必要な長さ

GY_L = 21; GY_W = 16; GY_UP_H = 14;      // 仮。GY-521 外形と、ピン上向き＋ジャンパー込みの高さ（Q9）
M360_L = 18; M360_W = 12; M360_UP_H = 14;// 仮。MINI360（Q9）

BATT_L = 60; BATT_W = 31; BATT_H = 15;   // 仮。電池（Q7）
STRAP_W = 10; STRAP_T = 2;               // 仮。ベルト（Q7）

// ===== 構造（仮） =====
PLATE_T = 3;
ARM_T   = 4;
ARM_W   = 8;
GAP     = 3;      // 部品どうしの間隔
EDGE    = 3;      // 部品の外側の縁

// ===== 本体の配置（計算） =====
ROW_MID_W = GY_L + GAP + M360_L;                 // 中段（Y 方向の幅）
BODY_W = max(ESC_BOARD, ROW_MID_W, PICO_W) + 2*EDGE;
X_ESC_FRONT = 0;  // 後で中心合わせ
LEN_ESC  = ESC_BOARD;
LEN_MID  = max(GY_W, M360_W);
LEN_PICO = PICO_L;
BODY_L_RAW = LEN_ESC + GAP + LEN_MID + GAP + LEN_PICO + 2*EDGE;
// 中段（IMU）が原点に来るように並べる
X_MID  = 0;
X_ESC  = X_MID + LEN_MID/2 + GAP + LEN_ESC/2;
X_PICO = X_MID - LEN_MID/2 - GAP - LEN_PICO/2;
BODY_FRONT = X_ESC + LEN_ESC/2 + EDGE;
BODY_REAR  = X_PICO - LEN_PICO/2 - EDGE;

// ===== モーター位置（計算・保守的） =====
// プロペラ円が本体の矩形に重ならない（高さを考慮しない保守的な条件）
R = PROP_D/2;
MOTOR_DY = 2*(BODY_W/2 + R + PROP_GAP);          // 左右のモーター間
MOTOR_DX = max(PROP_D + PROP_GAP, BODY_FRONT - BODY_REAR - 2*R); // 前後のモーター間
MX = MOTOR_DX/2; MY = MOTOR_DY/2;
X_OFF = (BODY_FRONT + BODY_REAR)/2;               // モーター中心を本体の中心に合わせる

echo(str("[仮] 本体 L=", BODY_FRONT-BODY_REAR, " W=", BODY_W,
         "  モーター間 前後=", MOTOR_DX, " 左右=", MOTOR_DY,
         " 対角=", sqrt(MOTOR_DX*MOTOR_DX+MOTOR_DY*MOTOR_DY)));
if (MOTOR_DX < PROP_D + PROP_GAP) echo("警告: 前後のプロペラが干渉");
if (max(PICO_UNDER_H + PICO_TOP_H, GY_UP_H, M360_UP_H, ESC_STANDOFF_H + ESC_H) > PROP_PLANE_H)
    echo("注意: 本体の部品がプロペラ面より高い（プロペラ円が本体に重ならない配置なので干渉はしないが、プロペラ径を変えたら再確認）");

$fn = 40;

// ---------- 部品 ----------
module motor_holes(d=MOTOR_HOLE_D) {
    s = MOTOR_HOLE_SPACING/2;
    for (x=[-s,s], y=[-s,s]) translate([x,y,-1]) cylinder(d=d, h=50);
    translate([0,0,-1]) cylinder(d=MOTOR_CENTER_D, h=50);
}

module body_plate() {
    translate([BODY_REAR, -BODY_W/2, 0]) cube([BODY_FRONT-BODY_REAR, BODY_W, PLATE_T]);
}

module arms() {
    for (sx=[-1,1], sy=[-1,1])
        hull() {
            translate([X_OFF, 0, 0]) cylinder(d=ARM_W, h=ARM_T);
            translate([X_OFF + sx*MX, sy*MY, 0]) cylinder(d=MOTOR_PAD_D, h=ARM_T);
        }
}

module esc_standoffs() {
    s = ESC_HOLE_SPACING/2;
    for (x=[-s,s], y=[-s,s])
        translate([X_ESC + x, y, PLATE_T]) cylinder(d=5, h=ESC_STANDOFF_H);
}
module esc_holes() {
    s = ESC_HOLE_SPACING/2;
    for (x=[-s,s], y=[-s,s]) translate([X_ESC + x, y, -1]) cylinder(d=ESC_HOLE_D, h=50);
}

module pico_standoffs() {
    for (x=[-PICO_HOLE_DX/2, PICO_HOLE_DX/2], y=[-PICO_HOLE_DY/2, PICO_HOLE_DY/2])
        translate([X_PICO + x, y, PLATE_T]) cylinder(d=4.5, h=PICO_UNDER_H);
}
module pico_holes() {
    for (x=[-PICO_HOLE_DX/2, PICO_HOLE_DX/2], y=[-PICO_HOLE_DY/2, PICO_HOLE_DY/2])
        translate([X_PICO + x, y, PLATE_T + 1]) cylinder(d=PICO_HOLE_D, h=50);
}

// GY-521・MINI360 は両面テープ＋結束バンドで固定（取付穴は未確認のため）
Y_GY   =  ROW_MID_W/2 - GY_L/2;
Y_M360 = -ROW_MID_W/2 + M360_L/2;
module tie_slots(xc, yc, len) {
    for (dy=[-len/2-2, len/2+2]) translate([xc-1.5, yc+dy-1, -1]) cube([3, 2, 50]);
}

// 電池ベルトのループ（下面）。ベルトはループと電池の上面の間を通る
module strap_lugs() {
    lug_y = BATT_W/2 + 2;
    for (sy=[-1,1])
        translate([X_OFF - (STRAP_W+6)/2, sy*lug_y - 2, -(STRAP_T+3)])
            difference() {
                cube([STRAP_W+6, 4, STRAP_T+3]);
                translate([3, -1, 1.5]) cube([STRAP_W+0.8, 6, STRAP_T+0.6]);
            }
}

module frame() {
    difference() {
        union() {
            body_plate();
            arms();
            esc_standoffs();
            pico_standoffs();
            strap_lugs();
        }
        for (sx=[-1,1], sy=[-1,1]) translate([X_OFF + sx*MX, sy*MY, 0]) motor_holes();
        esc_holes();
        pico_holes();
        tie_slots(X_MID, Y_GY, GY_L);
        tie_slots(X_MID, Y_M360, M360_L);
    }
}

// ---------- 確認用の占有範囲（印刷しない） ----------
module keepouts() {
    // ESC
    color("orange", 0.4) translate([X_ESC-ESC_BOARD/2, -ESC_BOARD/2, PLATE_T+ESC_STANDOFF_H]) cube([ESC_BOARD, ESC_BOARD, ESC_H]);
    // Pico W（下のジャンパー空間＋基板＋上）
    color("green", 0.3) translate([X_PICO-PICO_L/2, -PICO_W/2, PLATE_T]) cube([PICO_L, PICO_W, PICO_UNDER_H + 1 + PICO_TOP_H]);
    // USB プラグ（後ろ向き）
    color("blue", 0.3) translate([X_PICO-PICO_L/2-USB_PLUG_L, -6, PLATE_T+PICO_UNDER_H-2]) cube([USB_PLUG_L, 12, 8]);
    // GY-521, MINI360（ピン上向き＋ジャンパー）
    color("purple", 0.3) translate([X_MID-GY_W/2, Y_GY-GY_L/2, PLATE_T]) cube([GY_W, GY_L, GY_UP_H]);
    color("red", 0.3)    translate([X_MID-M360_W/2, Y_M360-M360_L/2, PLATE_T]) cube([M360_W, M360_L, M360_UP_H]);
    // 電池（下面）
    color("gray", 0.3) translate([X_OFF-BATT_L/2, -BATT_W/2, -(STRAP_T+3)-BATT_H]) cube([BATT_L, BATT_W, BATT_H]);
    // プロペラ円
    for (sx=[-1,1], sy=[-1,1])
        color("yellow", 0.2) translate([X_OFF + sx*MX, sy*MY, PLATE_T+PROP_PLANE_H]) cylinder(d=PROP_D, h=1);
}

// ---------- 試験片：モーター取付穴とPico W の下穴 ----------
GAUGE_DS = [2.0, 2.2, 2.4];
module motor_gauge() {
    difference() {
        cube([len(GAUGE_DS)*22 + 4, 26, ARM_T]);
        for (i=[0:len(GAUGE_DS)-1]) {
            translate([12 + i*22, 12, 0]) motor_holes(GAUGE_DS[i]);
            translate([12 + i*22 - 6, 21, ARM_T-0.6])
                linear_extrude(1) text(str(GAUGE_DS[i]), size=3.5);
        }
    }
}

if (PART == "frame") frame();
else if (PART == "motor_gauge") motor_gauge();
else { frame(); %keepouts(); }
