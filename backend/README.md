# NAFNet FastAPI Backend

Backend này kết nối trực tiếp với repo NAFNet đã clone sẵn trong:

```text
backend/NAFNet/NAFNet-main
```

Không cần clone lại và không cần di chuyển folder.

## Cấu trúc quan trọng

```text
backend/
├── app/
├── NAFNet/
│   └── NAFNet-main/
│       ├── basicsr/
│       ├── options/
│       └── setup.py
├── weights/
├── uploads/
├── outputs/
├── requirements.txt
└── run.py
```

## Cài thư viện

Chạy tại thư mục `backend`, không chạy trong `backend/NAFNet`:

```powershell
cd c:\Users\Admin\Documents\Nam3_Ky2\CV\Final\backend
pip install -r requirements.txt
```

Bạn đã cài requirements của NAFNet trong `NAFNet/NAFNet-main` rồi thì vẫn nên chạy lệnh trên để cài thêm FastAPI.

## Checkpoint

Đặt checkpoint vào:

```text
backend/weights/nafnet_sidd_width32.pth
backend/weights/nafnet_sidd_width64.pth
backend/weights/nafnet_custom.pth
```

Nếu chưa có checkpoint hoặc NAFNet lỗi, backend sẽ tự fallback sang mock denoise để không crash.

## Chạy API

Chạy tại thư mục `backend`:

```powershell
python run.py
```

Mở Swagger:

```text
http://127.0.0.1:8000/docs
```

## API endpoints

```text
GET  /api/health
GET  /api/models
POST /api/denoise
POST /api/denoise-json
GET  /api/outputs/{filename}
```

## Test curl

Trả file ảnh trực tiếp:

```bash
curl -X POST "http://127.0.0.1:8000/api/denoise" \
  -F "file=@test.jpg" \
  --output output.png
```

Trả JSON:

```bash
curl -X POST "http://127.0.0.1:8000/api/denoise-json" \
  -F "file=@test.jpg" \
  -F "model_name=nafnet_sidd_width32"
```

## Flutter base URL

Flutter Web Chrome:

```text
http://127.0.0.1:8000
```

Android Emulator:

```text
http://10.0.2.2:8000
```

Điện thoại thật cùng WiFi:

```text
http://IP_LAN_CUA_MAY_TINH:8000
```
