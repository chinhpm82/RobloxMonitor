# Chỉnh sửa & Nâng cấp MoniGuard

## [1.1.0] - 2026-04-07
### Thêm mới
- Thêm tài liệu hướng dẫn luồng ứng dụng chi tiết trong `docs/app_flow.md` bao gồm sơ đồ Mermaid cho các quy trình:
    - Khởi động (Startup).
    - Vòng lặp giám sát (Monitoring Loop).
    - Chế độ macOS Screenshot.
    - Cấu trúc SQLite.
- Tạo tệp `CHANGELOG.md` để theo dõi lịch sử thay đổi của dự án.

### Thay đổi
- Xây dựng bản build macOS và thực hiện ký mã nguồn (codesign) bằng chứng chỉ Apple Development kèm theo tệp `Release.entitlements`.
- Sửa lỗi cấp quyền chụp màn hình macOS bằng cách nhúng đúng entitlements vào bản build.
- Cung cấp bộ cài đặt định dạng `.pkg` dành cho tất cả người dùng trên macOS.
- Tối ưu hóa sơ đồ luồng hoạt động của ứng dụng.
