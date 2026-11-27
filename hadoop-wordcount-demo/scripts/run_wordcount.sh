set -euo pipefail

INPUT_FILE=${INPUT_FILE:-/opt/demo/data/alice.txt}
HDFS_IN=/demo/input
HDFS_OUT=/demo/output
REDUCERS=${REDUCERS:-2}
SRC=/opt/demo/src

echo "== 0. Kiểm tra trước khi chạy =="
if [ ! -f "$INPUT_FILE" ]; then
  echo "LỖI: không thấy tệp $INPUT_FILE. Hãy tải sách vào thư mục data/." >&2
  exit 1
fi
SIZE=$(wc -c < "$INPUT_FILE")
echo "Dung lượng tệp dữ liệu: $SIZE byte"
if [ "$SIZE" -lt 10000 ]; then
  echo "LỖI: tệp dữ liệu quá nhỏ ($SIZE byte), có thể tải nhầm trang lỗi/HTML." >&2
  echo "Hãy tải lại bản Plain Text UTF-8 của sách rồi chạy lại." >&2
  exit 1
fi
echo -n "Trình thông dịch Python trên node: "
bash "$SRC/run_py.sh" -c "import sys; print(sys.version.split()[0])"

echo "== 1. Đưa dữ liệu lên HDFS =="
hdfs dfs -mkdir -p "$HDFS_IN"
hdfs dfs -put -f "$INPUT_FILE" "$HDFS_IN/"
hdfs dfs -ls "$HDFS_IN"

echo "== 2. Xóa thư mục kết quả cũ (nếu có) =="
hdfs dfs -rm -r -f "$HDFS_OUT"

echo "== 3. Chạy job MapReduce (Hadoop Streaming) =="
# -D và -files là tùy chọn chung (generic options) nên phải đứng TRƯỚC
# các tùy chọn streaming (-input, -output, -mapper, ...).
# run_py.sh tự chọn python3 hoặc python (Python 2.7) có sẵn trên node.
mapred streaming \
  -D mapreduce.job.name="WordCount-Streaming-Demo" \
  -D mapreduce.job.reduces="$REDUCERS" \
  -files "$SRC/run_py.sh,$SRC/mapper.py,$SRC/reducer.py" \
  -input "$HDFS_IN" \
  -output "$HDFS_OUT" \
  -mapper "bash run_py.sh mapper.py" \
  -combiner "bash run_py.sh reducer.py" \
  -reducer "bash run_py.sh reducer.py"

echo "== 4. Các tệp kết quả (mỗi Reducer ghi một tệp part-0000x) =="
hdfs dfs -ls "$HDFS_OUT"

echo "== 5. 20 từ xuất hiện nhiều nhất =="
hdfs dfs -cat "$HDFS_OUT"/part-* | sort -t$'\t' -k2,2nr | head -20
