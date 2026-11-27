# Demo WordCount trên Hadoop (MapReduce + HDFS + YARN)

Demo minh họa Chương 25 – *Big Data Technologies Based on MapReduce and Hadoop*
(Elmasri & Navathe, 2016): đưa một cuốn truyện lên HDFS, chạy job MapReduce đếm
tần suất từ trên YARN, rồi đọc kết quả.

## 1. Kiến trúc cụm

Cụm gồm 4 container Docker, dùng image `apache/hadoop:3.4.1`:

| Container | Tiến trình | Vai trò | Cổng web |
| --- | --- | --- | --- |
| namenode | HDFS NameNode | Quản lý không gian tên, siêu dữ liệu | 9870 |
| datanode | HDFS DataNode | Lưu các khối dữ liệu | – |
| resourcemanager | YARN ResourceManager | Cấp phát tài nguyên; nơi gửi job | 8088 |
| nodemanager | YARN NodeManager | Chạy các container Map/Reduce | – |

Tệp `docker-compose.yaml` và `config` dựa trên cấu hình chính thức của Apache Hadoop
(nhánh `docker-hadoop-3`: https://github.com/apache/hadoop/tree/docker-hadoop-3).

## 2. Cấu trúc thư mục

```
hadoop-wordcount-demo/
├── docker-compose.yaml        # Định nghĩa cụm 4 container
├── config                     # Cấu hình Hadoop (core-site, hdfs-site, mapred-site, yarn-site)
├── src/
│   ├── run_py.sh              # Chọn python3 hoặc python có sẵn trên node
│   ├── mapper.py              # Hàm map: dòng văn bản -> (từ, 1)
│   └── reducer.py             # Hàm reduce (kiêm combiner): (từ, [1,1,...]) -> (từ, tổng)
├── data/
│   ├── sample.txt             # Dữ liệu mẫu nhỏ để kiểm thử cục bộ
│   └── alice.txt              # (tự tải, xem bước 3.2)
├── scripts/
│   ├── test_local.sh          # Kiểm thử mapper/reducer không cần Hadoop
│   ├── run_wordcount.sh       # Chạy job Python (Hadoop Streaming) trên cụm
│   └── run_example_wordcount.sh  # Chạy WordCount Java có sẵn của Hadoop
└── screenshots/               # Ảnh chụp kết quả chạy thật (nhóm tự bổ sung)
```

## 3. Cài đặt và chạy

### 3.1. Yêu cầu
- Docker Desktop (Windows/macOS) hoặc Docker Engine + Docker Compose (Linux).
- Python 3 (chỉ cần cho bước kiểm thử cục bộ).
- Máy nên có từ 8 GB RAM trở lên.
- Máy Mac chip Apple (M1, M2, M3, M4…): image `apache/hadoop` chỉ có bản `linux/amd64`, nên `docker-compose.yaml` đã khai báo `platform: linux/amd64` và Docker Desktop sẽ chạy qua giả lập. Bật tùy chọn dùng Rosetta trong Settings của Docker Desktop (nếu có) để chạy nhanh hơn.

### 3.2. Tải dữ liệu
Dữ liệu là truyện *Alice in Wonderland* (Lewis Carroll), bản văn bản thuần của Project Gutenberg
lưu trên Oxford Text Archive (giấy phép CC BY-NC-SA 3.0):
http://hdl.handle.net/20.500.12024/1476

1. Mở link trên, ở dòng tệp `alice28-1476.txt` bấm **Download file**.
2. Đổi tên tệp thành `alice.txt` và đặt vào thư mục `data/`.
3. Kiểm tra tệp nặng khoảng 150 KB và là chữ của truyện:

```bash
ls -lh data/
head -20 data/alice.txt
```

### 3.3. Kiểm thử cục bộ (không cần Hadoop)
```bash
bash scripts/test_local.sh                              # với data/sample.txt
bash scripts/test_local.sh data/alice.txt               # với cả cuốn truyện
```
Lệnh `sort` trong script đóng vai trò pha Shuffle & Sort của Hadoop.

### 3.4. Khởi động cụm
```bash
docker compose up -d
docker compose ps        # 4 container phải ở trạng thái "running"
```
Mở trình duyệt:
- NameNode (HDFS): http://localhost:9870
- ResourceManager (YARN): http://localhost:8088

### 3.5. Lưu ý về Python
Image `apache/hadoop` không có `python3`, chỉ có `python` (Python 2.7). Vì vậy:
- `mapper.py` và `reducer.py` được viết để chạy được trên **cả Python 2.7 và Python 3**.
- Script `src/run_py.sh` tự chọn `python3` nếu có, nếu không thì dùng `python`.
- Kiểm tra trình thông dịch trên node:
```bash
docker compose exec nodemanager python --version
```

### 3.6. Chạy job WordCount bằng Python (Hadoop Streaming)
```bash
docker compose exec resourcemanager bash /opt/demo/scripts/run_wordcount.sh
```
Script sẽ: đưa sách lên HDFS (`/demo/input`) → chạy job với 2 Reducer và có Combiner
→ liệt kê 2 tệp kết quả `part-00000`, `part-00001` → in 20 từ xuất hiện nhiều nhất.

### 3.7. (Đối chiếu) Chạy WordCount Java có sẵn của Hadoop
```bash
docker compose exec resourcemanager bash /opt/demo/scripts/run_example_wordcount.sh
```

### 3.8. Dừng cụm
```bash
docker compose down
```

## 4. Thiết kế job MapReduce

| Giai đoạn | Đầu vào | Đầu ra | Thành phần |
| --- | --- | --- | --- |
| Map | (vị trí dòng, nội dung dòng) | (từ, 1) | `mapper.py` |
| Combiner | (từ, [1, 1, ...]) trên cùng một Mapper | (từ, tổng cục bộ) | `reducer.py` |
| Shuffle & Sort | các cặp (từ, số) | gom theo từ, chia cho 2 Reducer | Hadoop tự thực hiện |
| Reduce | (từ, [số đếm...]) | (từ, tổng) | `reducer.py` |

## 5. Ảnh chụp kết quả
Nhóm chụp và lưu vào thư mục `screenshots/`:
1. `docker compose ps` với 4 container đang chạy.
2. Giao diện NameNode (cổng 9870): Datanodes đang hoạt động, tệp trong `/demo/input`.
3. Giao diện ResourceManager (cổng 8088): job `WordCount-Streaming-Demo` ở trạng thái FINISHED / SUCCEEDED.
4. Màn hình terminal khi job chạy (tiến trình map %, reduce %) và bảng counters.
5. Danh sách `part-00000`, `part-00001` và 20 từ xuất hiện nhiều nhất.

## 6. Tài liệu tham khảo
- Elmasri, R., & Navathe, S. B. (2016). *Fundamentals of database systems* (7th ed.). Pearson.
- Apache Software Foundation. (2023). *Hadoop: Setting up a single node cluster*. https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-common/SingleCluster.html
- Apache Software Foundation. (n.d.). *Hadoop streaming*. https://hadoop.apache.org/docs/stable/hadoop-streaming/HadoopStreaming.html
- Apache Software Foundation. (n.d.). *apache/hadoop* [Docker image]. Docker Hub. https://hub.docker.com/r/apache/hadoop
- Carroll, L. (1991). *Alice in Wonderland* [Plain text file]. Oxford Text Archive. http://hdl.handle.net/20.500.12024/1476 (Original work published 1865)
