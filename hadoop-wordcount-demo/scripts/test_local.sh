set -euo pipefail

INPUT=${1:-data/sample.txt}

cat "$INPUT" \
  | bash src/run_py.sh src/mapper.py \
  | LC_ALL=C sort -t$'\t' -k1,1 \
  | bash src/run_py.sh src/reducer.py \
  | sort -t$'\t' -k2,2nr \
  | head -20
