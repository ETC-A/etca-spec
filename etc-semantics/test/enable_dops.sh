set -u
./scripts/test.sh "$1" "$2" "$3" "test/enable_dops.bin" 16384
./scripts/test.sh "$1" "$2" "$3" "test/enable_dops.bin" 49152
