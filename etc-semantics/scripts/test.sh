set -euo pipefail

KETC="$1"
mode="$2"
backend="$3"
runfile="$4"
cpuid1="$5"
cpuid2=0 #"$6"
feat=0   #"$7"

test_name="${runfile%.bin}.$cpuid1"

run_test() {
  "$KETC" run "$runfile" --cpuid1 $cpuid1 --cpuid2 $cpuid2 --feat $feat --backend "$backend" > "$test_name.actual"
  if ! cmp "$test_name.actual" "$test_name.expected" >/dev/null ; then
    echo "Output for $test_name does not match!"
    exit 1
  fi
  rm "$test_name.actual"
}

update_test() {
  "$KETC" run "$runfile" --cpuid1 $cpuid1 --cpuid2 $cpuid2 --feat $feat > "$test_name.expected"
}

case "$mode" in
  run)    run_test    ;;
  update) update_test ;;
  *) echo "Unknown mode: $mode"; exit 1;;
esac
