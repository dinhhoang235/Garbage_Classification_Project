# EcoSort Backend Server

Hệ thống Backend cho ứng dụng phân loại rác EcoSort, sử dụng FastAPI, MySQL và TensorFlow.

## 🚀 Khởi chạy dự án (Docker)

Sử dụng Docker Compose để khởi chạy toàn bộ hệ thống (API, Database, MinIO, Nginx):

```bash
# Khởi chạy lần đầu hoặc khi có thay đổi cấu hình
docker compose up --build

# Khởi chạy chế độ chạy ngầm (background)
docker compose up -d

# Dừng toàn bộ hệ thống
docker compose down
```

## 🗄️ Quản lý Database (Alembic Migrations)

Chúng ta sử dụng Alembic để quản lý các thay đổi cấu hình bảng mà không làm mất dữ liệu.

**Lưu ý:** Tất cả lệnh này nên chạy bên trong container `fastapi_backend`.

```bash
# Truy cập vào terminal của container
docker exec -it fastapi_backend sh

# 1. Tạo bản nháp migration mới (khi bạn thay đổi Model trong code)
alembic revision --autogenerate -m "tên_mô_tả_thay_đổi"

# 2. Áp dụng thay đổi vào Database thực tế
alembic upgrade head

# 3. Xem lịch sử các bản migration
alembic history

# 4. Quay lại phiên bản trước đó (Rollback)
alembic downgrade -1
```

## 📁 Cấu trúc thư mục chính

- `app/models/`: Định nghĩa các bảng Database (SQLAlchemy).
- `app/routers/`: Các endpoints API (Auth, History, Predict...).
- `app/schemas/`: Định nghĩa kiểu dữ liệu Input/Output (Pydantic).
- `app/core/`: Cấu hình hệ thống, database, bảo mật.
- `app/main.py`: File chạy chính của ứng dụng.

## 🔗 Các đường dẫn quan trọng

- **API Documentation (Swagger):** [http://localhost:8000/docs](http://localhost:8000/docs)
- **MinIO Console (Storage):** [http://localhost:9001](http://localhost:9001) (User/Pass: admin/admin123)
- **Database Port:** `3306` (truy cập từ ngoài qua localhost:3306)

## 🛠️ Lệnh hữu ích khác

```bash
# Xem log của server theo thời gian thực
docker logs -f fastapi_backend

# Xóa toàn bộ dữ liệu database để làm mới (Cẩn thận!)
docker volume rm server_mysql-data
```
