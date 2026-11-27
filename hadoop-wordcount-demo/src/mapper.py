# -*- coding: utf-8 -*-
"""
Mapper cho bài toán WordCount (Hadoop Streaming).

Đầu vào : từng dòng văn bản từ HDFS (stdin), do Hadoop đọc từ các InputSplit.
Đầu ra  : các cặp key-value trung gian dạng "từ<TAB>1" (stdout).

Tương ứng lý thuyết: map(K1, V1) -> List[(K2, V2)]
  - K1: vị trí dòng trong tệp (Hadoop Streaming không đưa vào stdin)
  - V1: nội dung dòng
  - K2: một từ (đã chuyển chữ thường)
  - V2: số 1

"""
from __future__ import unicode_literals

import io
import re
import sys

# Lấy các chuỗi chữ cái Unicode (không lấy số, dấu câu, gạch dưới),
# nên dùng được cho cả tiếng Anh lẫn tiếng Việt có dấu.
WORD_PATTERN = re.compile(r"[^\W\d_]+", re.UNICODE)


def main():
    # Đọc/ghi theo UTF-8 giống nhau trên Python 2 và Python 3
    stdin = io.open(sys.stdin.fileno(), "r", encoding="utf-8",
                    errors="replace", closefd=False)
    stdout = io.open(sys.stdout.fileno(), "w", encoding="utf-8",
                     closefd=False)
    for line in stdin:
        for word in WORD_PATTERN.findall(line.lower()):
            stdout.write("%s\t1\n" % word)
    stdout.flush()


if __name__ == "__main__":
    main()
