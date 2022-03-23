set -u
./scripts/test.sh "$1" "$2" "$3" "test/enable_dops.bin" 64
./scripts/test.sh "$1" "$2" "$3" "test/enable_dops.bin" 192
