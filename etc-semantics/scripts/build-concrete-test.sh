set -euxo pipefail

asm_file="$1"

exec 6< "$asm_file" # create fd feeding lines of the asm file

head -c 1 >/dev/null <&6 # read and skip the semicolon
IFS=" " read -ra ETC_AS_OPTS <&6
head -c 1 >/dev/null <&6 # read and skip the semicolon
IFS="," read -ra CPUIDS      <&6
if [ ${#CPUIDS[@]} -eq 0 ] ; then
  CPUIDS=(0)
fi

exec 6<&-

# assemble the file
bin_file="${asm_file%.s}.bin"
etc-as.py "$asm_file" -mformat=binary -o "$bin_file" "${ETC_AS_OPTS[@]}"

# construct the runner script
script_file="${asm_file%.s}.sh"
echo 'set -eu' > $script_file
for cpuid in ${CPUIDS[@]}; do
  echo "./scripts/test.sh \"\$1\" \"\$2\" \"$bin_file\" $cpuid" >> $script_file
done
chmod +x $script_file
