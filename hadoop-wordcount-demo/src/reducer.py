# -*- coding: utf-8 -*-
"""
Reducer (đồng thời dùng làm Combiner) cho bài toán WordCount.

Đầu vào : các dòng "từ<TAB>số_đếm" ĐÃ ĐƯỢC SẮP XẾP theo từ (Hadoop lo việc
          sắp xếp trong pha Shuffle), nên các dòng cùng một từ nằm liền nhau.
Đầu ra  : "từ<TAB>tổng_số_lần_xuất_hiện".

Tương ứng lý thuyết: reduce(K2, List[V2]) -> List[(K3, V3)]
  - K2 = K3: một từ
  - List[V2]: danh sách các số đếm của từ đó
  - V3: tổng số lần xuất hiện

Vì phép cộng có tính giao hoán và kết hợp, cùng một tệp này dùng được làm
Combiner để cộng dồn sơ bộ ngay ở phía Map, giảm dữ liệu truyền qua Shuffle.
"""
from __future__ import unicode_literals

import io
import sys


def main():
    stdin = io.open(sys.stdin.fileno(), "r", encoding="utf-8",
                    errors="replace", closefd=False)
    stdout = io.open(sys.stdout.fileno(), "w", encoding="utf-8",
                     closefd=False)

    current_word = None
    current_count = 0

    for line in stdin:
        line = line.rstrip("\n")
        if not line:
            continue
        try:
            word, count = line.split("\t", 1)
            count = int(count)
        except ValueError:
            # Bỏ qua dòng sai định dạng thay vì làm hỏng cả tác vụ
            continue

        if word == current_word:
            current_count += count
        else:
            if current_word is not None:
                stdout.write("%s\t%d\n" % (current_word, current_count))
            current_word = word
            current_count = count

    if current_word is not None:
        stdout.write("%s\t%d\n" % (current_word, current_count))
    stdout.flush()


if __name__ == "__main__":
    main()
