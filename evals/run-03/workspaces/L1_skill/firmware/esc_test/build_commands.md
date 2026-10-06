# ビルド（Pico SDK を入れた PC の bash で、1行ずつ）
前提：環境変数 PICO_SDK_PATH が設定済み。`$PICO_SDK_PATH/external/pico_sdk_import.cmake` をこのフォルダーにコピー済み。

    cd firmware/esc_test
    mkdir -p build
    cd build
    cmake ..
    make

できた `build/esc_test.uf2` を Pico W に書き込む。
