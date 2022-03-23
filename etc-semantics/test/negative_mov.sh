set -eu
./scripts/test.sh "$1" "$2" "$3" "test/negative_mov.bin" 0
./scripts/test.sh "$1" "$2" "$3" "test/negative_mov.bin" 16
./scripts/test.sh "$1" "$2" "$3" "test/negative_mov.bin" 64
./scripts/test.sh "$1" "$2" "$3" "test/negative_mov.bin" 128
