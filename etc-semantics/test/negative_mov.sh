set -u
./scripts/test.sh "$1" "$2" "$3" "test/negative_mov.bin" 0
./scripts/test.sh "$1" "$2" "$3" "test/negative_mov.bin" 8
./scripts/test.sh "$1" "$2" "$3" "test/negative_mov.bin" 16384
./scripts/test.sh "$1" "$2" "$3" "test/negative_mov.bin" 32768
