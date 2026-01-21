set -u
./scripts/test.sh "$1" "$2" "$3" "test/movz.bin" 0
./scripts/test.sh "$1" "$2" "$3" "test/movz.bin" 8
./scripts/test.sh "$1" "$2" "$3" "test/movz.bin" 16392
./scripts/test.sh "$1" "$2" "$3" "test/movz.bin" 32776
