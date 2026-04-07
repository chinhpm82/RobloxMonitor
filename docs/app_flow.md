# Luồng Hoạt động của MoniGuard (Phiên bản macOS)

Tài liệu này mô tả chi tiết luồng hoạt động của ứng dụng MoniGuard, từ lúc khởi động cho đến các vòng lặp kiểm soát và tương tác người dùng.

## 1. Luồng Khởi động (Startup Flow)

Khi máy tính khởi động hoặc người dùng mở ứng dụng:

```mermaid
graph TD
    A[Bắt đầu] --> B{Hệ điều hành?}
    B -- macOS --> C[Cài đặt/Kiểm tra LaunchAgent .plist]
    C --> D[Khởi tạo Flutter & WindowManager]
    B -- Windows --> D
    D --> E[Khởi tạo AppState & Nạp dữ liệu từ SQLite]
    E --> F[Khởi tạo SystemTrayManager]
    F --> G[Bắt đầu Vòng lặp Giám sát 1s/lần]
    G --> H[Hiển thị Cửa sổ chính nếu cần]
```

---

## 2. Vòng lặp Giám sát (Monitoring Loop)

Đây là quy trình cốt lõi chạy ngầm mỗi giây để kiểm soát việc sử dụng máy tính.

```mermaid
graph TD
    Start((Bắt đầu vòng lặp 1s)) --> Enabled{Giám sát bật?}
    Enabled -- Không --> End((Kết thúc))
    Enabled -- Có --> Check[Kiểm tra Process & Browser]
    
    Check --> AppDetect{Phát hiện App/Web bị chặn?}
    
    AppDetect -- Không --> Reset[Reset đếm ngược vi phạm]
    Reset --> Log[Ghi lại thời gian chơi nếu hợp lệ]
    Log --> Screenshot{Chế độ Screenshot 5p?}
    Screenshot -- Có --> SendTG[Chụp màn hình & Gửi Telegram]
    Screenshot -- Không --> End
    
    AppDetect -- Có --> Schedule{Trong giờ cho phép?}
    
    Schedule -- Có --> Log
    
    Schedule -- Không --> Violation[Tăng bộ đếm vi phạm]
    Violation --> Warning{Đạt Warning Delay?}
    Warning -- Có --> ShowWarn[Hiển thị Banner Cảnh báo]
    ShowWarn --> Overlay{Đạt Overlay Delay?}
    
    Overlay -- Có --> ShowOverlay[Hiển thị Overlay chặn màn hình]
    ShowOverlay --> Kill{Đạt Kill Delay?}
    
    Kill -- Có --> Terminate[Kill Process / Đóng Browser]
    Terminate --> AlertTG[Gửi cảnh báo Telegram]
    
    Warning -- Không --> End
    Overlay -- Không --> End
    Kill -- Không --> End
    AlertTG --> End
```

---

## 3. Chế độ macOS Screenshot (macOS Specific Flow)

Trên macOS, khi ứng dụng ở chế độ "Screenshot Mode", nó hoạt động như một công cụ giám sát từ xa thay vì chặn cứng.

```mermaid
sequenceDiagram
    participant OS as macOS System
    participant App as MoniGuard App
    participant TG as Telegram Bot
    
    Loop Mỗi 5 phút (nếu đang chơi trong giờ cho phép)
        App->>OS: Yêu cầu chụp ảnh màn hình
        OS-->>App: Trả về file ảnh (.png)
        App->>TG: Gửi ảnh kèm thông tin (Thời gian, Nội dung đang xem)
        TG-->>Người giám sát: Thông báo tin nhắn
    End
```

---

## 4. Cấu trúc Dữ liệu & Lưu trữ

Ứng dụng sử dụng SQLite để lưu trữ cấu hình và lịch sử:

*   **Bảng `settings`**: Lưu Token Telegram, ChatID, mật khẩu app, các mốc thời gian delay, danh sách từ khóa và ứng dụng bị chặn.
*   **Bảng `logs`**: Lưu lịch sử chơi (Thời gian bắt đầu, Kết thúc, Tổng thời lượng, Tên ứng dụng/Web).
*   **Bảng `system_events`**: Lưu các sự kiện hệ thống (Khởi động, Lỗi, Cài đặt LaunchAgent).

---

## 5. Tương tác Người dùng (User Interaction)

*   **Tray Icon (Thanh trạng thái)**:
    *   Xem nhanh trạng thái giám sát và thời lượng sử dụng trong phiên hiện tại.
    *   Nút mở cửa sổ **Settings** hoặc **Thoát ứng dụng** (Yêu cầu mật khẩu nếu đã cài đặt).
*   **Cửa sổ Cấu hình (Settings Window)**:
    *   **Tab Giám sát (Monitoring)**: Thiết lập lịch trình cho phép/chặn (Schedule) theo tuần.
    *   **Tab Thống kê (Statistics)**: Biểu đồ thời gian sử dụng thực tế.
    *   **Tab Lịch sử (History)**: Danh sách chi tiết các phiên truy cập Web/App bị hạn chế.
    *   **Tab Cài đặt (Settings)**: Cấu hình Telegram Bot, mốc thời gian cảnh báo (Delays), mật khẩu và danh sách từ khóa.
