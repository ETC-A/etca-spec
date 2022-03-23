set -u
./scripts/test.sh "$1" "$2" "$3" "test/movz.bin" 0
./scripts/test.sh "$1" "$2" "$3" "test/movz.bin" 16
./scripts/test.sh "$1" "$2" "$3" "test/movz.bin" 80
./scripts/test.sh "$1" "$2" "$3" "test/movz.bin" 144
