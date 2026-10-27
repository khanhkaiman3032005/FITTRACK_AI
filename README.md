# FITTRACK AI

Ứng dụng theo dõi luyện tập, dinh dưỡng và sức khỏe sử dụng Flutter (Android/Web), Supabase và các tính năng AI.

> **Trạng thái:** Dự án học tập/đang phát triển. Các chức năng AI hỗ trợ luyện tập không thay thế tư vấn y tế. Tính năng phân tích tư thế AI Camera Rep Counter chạy trên Android/iOS; Web dùng chế độ đếm thủ công.

## Chức năng

- Tài khoản: đăng ký, đăng nhập, Google Login, quản lý hồ sơ; lưu dữ liệu tách theo tài khoản.
- Dashboard, workout 6 bài (Squat, Push Up, Lunge, Plank, Jumping Jack, Shoulder Press), nhật ký và calories ước tính.
- Health Guardian: sàng lọc trước tập, phiếu sức khỏe theo ngày, cảnh báo khi tập, đánh giá RPE sau tập.
- AI Camera Rep Counter: dùng ML Kit trên Android/iOS để ước lượng tư thế và đếm rep/giữ Plank. Độ chính xác phụ thuộc khung hình, ánh sáng và góc camera.
- Dinh dưỡng, AI Food Camera, AI Coach Hybrid, lịch sử chat.
- Recommendation Engine và Exercise Safety Engine nội bộ.

## 1. Yêu cầu môi trường

- Flutter SDK và Dart tương thích với `pubspec.yaml` trong repo; chạy `flutter doctor` để kiểm tra.
- VS Code + Flutter/Dart extensions.
- Google Chrome để chạy Flutter Web.
- Android Studio + Android SDK + thiết bị Android/emulator để thử AI Camera.
- Python và pip để chạy backend FastAPI (phiên bản phải đối chiếu với backend thực tế).
- Một Supabase project riêng cho người kiểm thử, có schema/RLS/policies tương thích. Không dùng database chứa dữ liệu cá nhân thật để demo.

## 2. Lấy mã nguồn

```bash
git clone https://github.com/<OWNER>/FITTRACK_AI.git
cd FITTRACK_AI
flutter pub get
flutter doctor
```

Thay `<OWNER>` bằng tài khoản GitHub chứa repo. Nếu clone ra tên thư mục khác, `cd` tới thư mục chứa `pubspec.yaml`.

## 3. Cấu hình Flutter / Supabase

Tạo file **`config/dev.json`** trên máy của bạn (file này KHÔNG được commit):

```json
{
  "SUPABASE_URL": "https://YOUR_PROJECT.supabase.co",
  "SUPABASE_ANON_KEY": "YOUR_SUPABASE_PUBLISHABLE_OR_ANON_KEY"
}
```

Dùng URL và publishable/anon key của **Supabase project dành cho demo**. **Không** cho `service_role`/secret key, mật khẩu database, Gemini API key hoặc token khác vào Flutter hay GitHub. Anon key không phải quyền truy cập tự do: Supabase phải bật RLS và policies thích hợp.

**Lưu ý:** có key chưa đủ để chạy toàn bộ: Supabase cần các bảng/schema, trigger, RLS, cấu hình Auth (và Google OAuth nếu dùng). Người duy trì dự án phải cung cấp migration/schema và hướng dẫn khởi tạo trong thư mục ví dụ `supabase/migrations/` (chưa xác minh có trong bản repo hiện tại). Không chạy SQL xóa bảng/dữ liệu trên project đang hoạt động.

## 4. Chạy Flutter Web

```bash
flutter run -d chrome --web-port 8080 --dart-define-from-file=config/dev.json
```

Ứng dụng mở tại `http://localhost:8080`. Chạy backend mục 6 nếu muốn sử dụng Gemini hoặc AI Food Camera. AI Camera Rep Counter bằng ML Kit không chạy trực tiếp trên Web; hãy dùng chế độ thủ công.

## 5. Chạy Flutter Android

Mở emulator bằng Android Studio (hoặc cắm điện thoại bật USB debugging):

```bash
flutter devices
flutter run -d emulator-5554 --dart-define-from-file=config/dev.json
```

Nếu `flutter devices` hiển thị ID khác, thay `emulator-5554` bằng ID thực tế. Quyền sử dụng camera cần được cấp khi thử AI Camera. Đặt máy cố định và lấy hình toàn thân khi đếm Squat.

Trong VS Code, có thể chọn Run and Debug > `FITTRACK Android` hoặc `FITTRACK Web`, nếu `.vscode/launch.json` đã được cấu hình trên máy clone.

## 6. Chạy backend Python / FastAPI (Gemini + AI Food)

Theo mã Flutter hiện tại, ứng dụng gọi các endpoint:

- `POST /api/gemini`
- `POST /api/analyze-food`

Backend dự kiến chạy ở cổng `8000`:

- Web: `http://127.0.0.1:8000`
- Android Emulator: `http://10.0.2.2:8000` (địa chỉ truy cập máy host từ emulator Android)

**Quan trọng:** `lib/` và `test/` không chứa đầy đủ code backend hoặc file phụ thuộc nên chưa xác minh được module FastAPI để chạy. Sau khi đưa thư mục `backend/` lên repo, người duy trì cần cập nhật tên entrypoint, gói Python, biến môi trường và lệnh uvicorn thật tại đây. Khung thao tác thông thường:

```bash
cd backend
python -m venv .venv
```

Kích hoạt môi trường trên Windows PowerShell:

```powershell
.\.venv\Scripts\Activate.ps1
```

Hoặc trên Git Bash:

```bash
source .venv/Scripts/activate
```

Sau đó cài **đúng file requirements** nếu dự án có:

```bash
pip install -r requirements.txt
```

Tạo file cấu hình backend cục bộ (`.env`) theo `.env.example` do chủ dự án cung cấp. **Không commit API key**. Lệnh khởi động cần lấy từ cấu trúc thực tế, thường có dạng `uvicorn <MODULE>:<APP_OBJECT> --reload --host 0.0.0.0 --port 8000` — đây là **cú pháp mẫu**, không phải lệnh đã xác nhận cho dự án này.

Với **điện thoại Android thật**, địa chỉ `10.0.2.2` sẽ không hoạt động; cần cấu hình URL backend tới IP máy trong cùng Wi‑Fi hoặc máy chủ HTTPS và kiểm tra firewall. Code Flutter hiện tại hard-code địa chỉ Web/emulator, nên cần chỉnh riêng nếu chạy điện thoại thật.

## 7. Assets mô hình

`lib/services/trained_intent_classifier.dart` đọc `assets/ai/intent_nb.json`. Kiểm tra file này tồn tại trong repo và được khai báo trong `pubspec.yaml` trước khi thử chức năng phân loại ý định. Không đưa tập dữ liệu cá nhân hoặc video của người tham gia lên GitHub khi chưa có sự đồng ý.

## 8. Kiểm thử

```bash
flutter pub get
flutter analyze
flutter test
```

Kiểm thử thực tế: đăng nhập, tạo phiếu Health Guardian, cập nhật trạng thái cùng ngày, lịch sử cảnh báo và khóa an toàn; hoàn thành bài tập và RPE; AI Coach đọc dữ liệu đúng tài khoản và giữ lịch sử; trên Android thử 6 bài AI Camera (đúng rep, không đếm khi mất khớp/ra khung, dừng tập an toàn).

Test tự động đạt không chứng minh độ chính xác ngoài đời 100%; không bỏ qua cảnh báo sức khỏe để thử camera.

## 9. Xử lý sự cố

- **Thiếu `SUPABASE_URL`/`SUPABASE_ANON_KEY`:** kiểm tra `config/dev.json` và `--dart-define-from-file`.
- **Đăng nhập/lưu dữ liệu lỗi:** xác minh schema, RLS, auth settings và kết nối Supabase demo.
- **AI Coach/AI Food không trả lời:** kiểm tra backend ở cổng 8000, API key backend, và endpoint.
- **Android emulator không chạy:** `flutter devices`, `flutter doctor`; thử cold boot emulator.
- **Camera đếm sai:** đảm bảo nhìn thấy toàn thân và khớp liên quan, đủ ánh sáng, hạn chế rung.
- **`flutter analyze` báo lỗi:** gửi tên file/dòng lỗi thay vì sửa hàng loạt.

## 10. An toàn khi chia sẻ mã nguồn

Không commit `config/dev.json`, `.env`, token, mật khẩu, service-role key, dữ liệu bệnh lý/người dùng thật, file backup DB hoặc log nhạy cảm. Nếu từng commit bí mật vào Git history, xóa file ở commit mới không đủ: hãy thu hồi/đổi khóa và xử lý lịch sử Git.

**Giấy phép:** chưa công bố giấy phép mã nguồn; quyền sử dụng thuộc người sở hữu dự án. Bạn có thể đặt repository ở chế độ **Private** và mời bạn bè qua GitHub Collaborators để thử trước.
