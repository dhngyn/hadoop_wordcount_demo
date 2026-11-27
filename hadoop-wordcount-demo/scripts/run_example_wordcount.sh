set -euo pipefail

INPUT_FILE=${INPUT_FILE:-/opt/demo/data/alice.txt}
HDFS_IN=/demo/input
HDFS_OUT=/demo/output-java
REDUCERS=${REDUCERS:-2}

echo "== 1. Đưa dữ liệu lên HDFS =="
hdfs dfs -mkdir -p "$HDFS_IN"
hdfs dfs -put -f "$INPUT_FILE" "$HDFS_IN/"
hdfs dfs -ls "$HDFS_IN"

echo "== 2. Xóa thư mục kết quả cũ (nếu có) =="
hdfs dfs -rm -r -f "$HDFS_OUT"

echo "== 3. Chạy job MapReduce (WordCount Java, có Combiner) =="
hadoop jar "$HADOOP_HOME"/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar \
  wordcount \
  -D mapreduce.job.name="WordCount-Java-Demo" \
  -D mapreduce.job.reduces="$REDUCERS" \
  "$HDFS_IN" "$HDFS_OUT"

echo "== 4. Các tệp kết quả (mỗi Reducer ghi một tệp part-r-0000x) =="
hdfs dfs -ls "$HDFS_OUT"

echo "== 5. 20 từ xuất hiện nhiều nhất =="
hdfs dfs -cat "$HDFS_OUT"/part-* | sort -t$'\t' -k2,2nr | head -20
