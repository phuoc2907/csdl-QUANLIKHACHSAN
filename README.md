# csdl-QUANLIKHACHSAN
DỰ ÁN QUẢN LÝ KHÁCH SẠN (BỘ PHẬN LỄ TÂN)
Giới thiệu chung

    Dự án tập trung xây dựng cơ sở dữ liệu (CSDL) để quản lý các hoạt động nghiệp vụ tại bộ phận lễ tân của một khách sạn. Hệ thống hỗ trợ quản lý thông tin khách hàng, tình trạng phòng, sử dụng dịch vụ và tự động hóa quy trình thanh toán.

Các tính năng chính

    Quản lý danh mục: Khách hàng (trong và ngoài nước), Phòng (Đơn, Đôi, VIP), Dịch vụ.

    Tự động hóa (Triggers): * Tự động cập nhật trạng thái phòng thành "Đã có khách" khi Check-in.

    Tự động giải phóng phòng về trạng thái "Trống" khi khách Check-out.

Nghiệp vụ (Procedures):

    Thủ tục thêm mới khách hàng nhanh chóng.

    Tự động tính toán hóa đơn tổng hợp (Tiền phòng + Tiền dịch vụ) dựa trên loại khách (Việt Nam/Nước ngoài).

    Quản lý đặt phòng: Lưu vết tiền đặt cọc và ngày hẹn của khách.

Công nghệ sử dụng

    Hệ quản trị CSDL: Microsoft SQL Server

    Ngôn ngữ: SQL

Thành viên thực hiện

    Nguyễn Duy Phước: Trưởng nhóm - Phân tích hệ thống & Báo cáo.

    Nguyễn Hà Phong: Thiết kế cấu trúc Database & Tables.

    Nguyễn Đức Nam: Lập trình Triggers tự động hóa.

    Bùi Quốc Việt: Xây dựng Stored Procedures & Logic tính toán.

    Trần Khắc Lân: Kiểm thử nghiệp vụ & Dữ liệu mẫu.

Hướng dẫn cài đặt

    Mở phần mềm SQL Server Management Studio (SSMS).

    Mở file QuanLyKhachSan.sql.

    Nhấn F5 (hoặc nút Execute) để khởi tạo toàn bộ Database, Bảng, Triggers, Procedures và dữ liệu mẫu.

Xem kết quả demo ở phần tin nhắn hệ thống (Messages) và các bảng dữ liệu.
