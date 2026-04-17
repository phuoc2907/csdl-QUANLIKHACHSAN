/* =============================================================
   DỰ ÁN: QUẢN LÝ KHÁCH SẠN (BỘ PHẬN LỄ TÂN)
   MỤC TIÊU: HOÀN THIỆN TOÀN BỘ CẤU TRÚC, NGHIỆP VỤ VÀ DỮ LIỆU
   ============================================================= */

USE master;
GO

IF DB_ID('QuanLyKhachSan') IS NOT NULL
BEGIN
    ALTER DATABASE QuanLyKhachSan SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE QuanLyKhachSan;
END
GO

CREATE DATABASE QuanLyKhachSan;
GO

USE QuanLyKhachSan;
GO

/* =========================================
   1. TẠO CẤU TRÚC BẢNG (TABLES)
========================================= */

-- Bảng danh mục Khách hàng
CREATE TABLE KhachHang (
    MaKH VARCHAR(10) PRIMARY KEY,
    HotenKH NVARCHAR(100) NOT NULL,
    Tel VARCHAR(15),
    Dc NVARCHAR(255),
    CCCD VARCHAR(15) UNIQUE, 
    Hochieu VARCHAR(20),
    PloaiKH NVARCHAR(50) CHECK (PloaiKH IN (N'Việt Nam', N'Nước ngoài'))
);
GO

-- Bảng danh mục Phòng (Đồng bộ dùng MaPh và LoaiPh)
CREATE TABLE Phong (
    MaPh VARCHAR(10) PRIMARY KEY,
    TenPh NVARCHAR(50) NOT NULL,
    LoaiPh NVARCHAR(50) CHECK (LoaiPh IN (N'Phòng đơn', N'Phòng đôi', N'Phòng VIP')),
    Trangthai NVARCHAR(50) DEFAULT N'Trống' CHECK (Trangthai IN (N'Trống', N'Đã có khách')),
    GiaVN DECIMAL(18,2) DEFAULT 0,
    GiaNN DECIMAL(18,2) DEFAULT 0
);
GO

-- Bảng danh mục Dịch vụ (Đồng bộ dùng giaVN, giaNN)
CREATE TABLE DichVu (
    MaDV VARCHAR(10) PRIMARY KEY,
    TenDV NVARCHAR(100) NOT NULL,
    giaVN DECIMAL(18,2) DEFAULT 0,
    giaNN DECIMAL(18,2) DEFAULT 0
);
GO

-- Bảng Hóa đơn thanh toán
CREATE TABLE HoaDon (
    MaHD VARCHAR(10) PRIMARY KEY,
    MaKH VARCHAR(10) NOT NULL,
    Sotien DECIMAL(18,2) DEFAULT 0,
    NgayTT DATE DEFAULT GETDATE(),
    HinhthucTT NVARCHAR(50) CHECK (HinhthucTT IN (N'Tiền mặt', N'Thẻ tín dụng', N'Chuyển khoản')),
    CONSTRAINT FK_HoaDon_KhachHang FOREIGN KEY (MaKH) REFERENCES KhachHang(MaKH)
);
GO

-- Bảng nghiệp vụ Thuê Phòng (Lưu vết lịch sử)
CREATE TABLE ThuePhong (
    MaKH VARCHAR(10),
    Ngayden DATE NOT NULL,
    Ngaydi DATE,
    Thanhtoan DECIMAL(18,2) DEFAULT 0,
    SoNgayO AS DATEDIFF(day, Ngayden, ISNULL(Ngaydi, GETDATE())), 
    PRIMARY KEY (MaKH, Ngayden),
    CONSTRAINT FK_ThuePhong_KhachHang FOREIGN KEY (MaKH) REFERENCES KhachHang(MaKH)
);
GO

-- Bảng nghiệp vụ Đặt Phòng
CREATE TABLE DatPhong (
    MaKH VARCHAR(10),
    Ngayden DATE NOT NULL,
    Tiendat DECIMAL(18,2) CHECK (Tiendat >= 0),
    PRIMARY KEY (MaKH, Ngayden),
    CONSTRAINT FK_DatPhong_KhachHang FOREIGN KEY (MaKH) REFERENCES KhachHang(MaKH)
);
GO

-- Bảng Sử dụng Dịch vụ
CREATE TABLE SuDungDV (
    MaKH VARCHAR(10),
    MaDV VARCHAR(10),
    NgaySD DATE DEFAULT GETDATE(),
    SoLuong INT DEFAULT 1 CHECK (SoLuong > 0),
    PRIMARY KEY (MaKH, MaDV, NgaySD),
    CONSTRAINT FK_SuDungDV_KhachHang FOREIGN KEY (MaKH) REFERENCES KhachHang(MaKH),
    CONSTRAINT FK_SuDungDV_DichVu FOREIGN KEY (MaDV) REFERENCES DichVu(MaDV)
);
GO

-- Bảng quản lý Phòng đang sử dụng (Đồng bộ dùng MaPh)
CREATE TABLE SuDungPhong (
    MaKH VARCHAR(10),
    MaPh VARCHAR(10),
    PRIMARY KEY (MaKH, MaPh),
    CONSTRAINT FK_SuDungPhong_KhachHang FOREIGN KEY (MaKH) REFERENCES KhachHang(MaKH),
    CONSTRAINT FK_SuDungPhong_Phong FOREIGN KEY (MaPh) REFERENCES Phong(MaPh)
);
GO

/* =========================================
   2. TỰ ĐỘNG HÓA (TRIGGERS)
========================================= */

-- Tự động chuyển trạng thái phòng sang 'Đã có khách' (Đồng bộ MaPh)
CREATE TRIGGER trg_CapNhatTrangThai_VaoO
ON SuDungPhong
AFTER INSERT
AS
BEGIN
    UPDATE Phong
    SET Trangthai = N'Đã có khách'
    FROM Phong p
    INNER JOIN inserted i ON p.MaPh = i.MaPh;
END;
GO

-- Tự động trả phòng về trạng thái 'Trống' (Đồng bộ MaPh)
CREATE TRIGGER trg_CapNhatTrangThai_TraPhong
ON SuDungPhong
AFTER DELETE
AS
BEGIN
    UPDATE Phong
    SET Trangthai = N'Trống'
    FROM Phong p
    INNER JOIN deleted d ON p.MaPh = d.MaPh;
END;
GO

/* =========================================
   3. CÁC THỦ TỤC NGHIỆP VỤ (PROCEDURES)
========================================= */

-- Thủ tục nhập thông tin khách hàng mới (Đồng bộ tham số @CCCD)
CREATE PROCEDURE sp_ThemKhachHang
    @MaKH VARCHAR(10), @Hoten NVARCHAR(100), @Tel VARCHAR(15), 
    @Dc NVARCHAR(255), @CCCD VARCHAR(15), @Loai NVARCHAR(50)
AS
BEGIN
    INSERT INTO KhachHang (MaKH, HotenKH, Tel, Dc, CCCD, PloaiKH)
    VALUES (@MaKH, @Hoten, @Tel, @Dc, @CCCD, @Loai);
END;
GO

-- Thủ tục tính toán hóa đơn chi tiết cho khách (Đồng bộ MaPh, giaVN/giaNN)
CREATE PROCEDURE sp_InBillThanhToan
    @MaKH VARCHAR(10)
AS
BEGIN
    DECLARE @TienPhong DECIMAL(18,2) = 0;
    DECLARE @TienDV DECIMAL(18,2) = 0;

    -- Lấy giá phòng dựa trên loại khách
    SELECT @TienPhong = tp.SoNgayO * (CASE WHEN kh.PloaiKH = N'Việt Nam' THEN p.GiaVN ELSE p.GiaNN END)
    FROM ThuePhong tp
    JOIN SuDungPhong sdp ON tp.MaKH = sdp.MaKH
    JOIN Phong p ON sdp.MaPh = p.MaPh
    JOIN KhachHang kh ON tp.MaKH = kh.MaKH
    WHERE tp.MaKH = @MaKH;

    -- Lấy tổng tiền dịch vụ
    SELECT @TienDV = ISNULL(SUM(sd.SoLuong * CASE WHEN kh.PloaiKH = N'Việt Nam' THEN dv.giaVN ELSE dv.giaNN END), 0)
    FROM SuDungDV sd
    JOIN DichVu dv ON sd.MaDV = dv.MaDV
    JOIN KhachHang kh ON sd.MaKH = kh.MaKH
    WHERE sd.MaKH = @MaKH;

    -- Hiển thị kết quả
    SELECT 
        kh.HotenKH AS [Khách Hàng],
        kh.PloaiKH AS [Loại Khách],
        ISNULL(@TienPhong, 0) AS [Tiền Phòng],
        @TienDV AS [Tiền Dịch Vụ],
        (ISNULL(@TienPhong, 0) + @TienDV) AS [Tổng Cộng]
    FROM KhachHang kh WHERE MaKH = @MaKH;
END;
GO

/* =========================================
   4. DỮ LIỆU MẪU & DEMO TÍNH NĂNG
========================================= */

PRINT N'======================================================';
PRINT N'PHẦN 1: NẠP DỮ LIỆU DANH MỤC (MASTER DATA)';
PRINT N'======================================================';

-- 1. Nạp danh mục Khách hàng
EXEC sp_ThemKhachHang 'KH001', N'Nguyễn Duy Phước', '0912345678', N'Hải Dương', '001204123456', N'Việt Nam';
EXEC sp_ThemKhachHang 'KH002', N'Nguyễn Hà Phong', '0922345678', N'Hà Nội', '001204654321', N'Việt Nam';
EXEC sp_ThemKhachHang 'KH003', N'Nguyễn Đức Nam', '0932345678', N'Hà Nội', '001204888999', N'Việt Nam';
EXEC sp_ThemKhachHang 'KH004', N'Bùi Quốc Việt', '0942345678', N'Hà Nội', '001204111222', N'Việt Nam';
EXEC sp_ThemKhachHang 'KH005', N'Trần Khắc Lân', '0952345678', N'Bắc Ninh', '001204333444', N'Việt Nam';
EXEC sp_ThemKhachHang 'KH006', N'Michael Johnson', '0962345678', N'Mỹ', 'US123456', N'Nước ngoài';

-- 2. Nạp danh mục Phòng (Đồng bộ MaPh, LoaiPh)
INSERT INTO Phong (MaPh, TenPh, LoaiPh, Trangthai, GiaVN, GiaNN) VALUES 
('P101', N'Phòng 101', N'Phòng đơn', N'Trống', 500000, 800000),
('P102', N'Phòng 102', N'Phòng đôi', N'Trống', 900000, 1400000),
('P201', N'Phòng 201', N'Phòng VIP', N'Trống', 2500000, 4000000),
('P202', N'Phòng 202', N'Phòng đơn', N'Trống', 500000, 800000),
('P301', N'Phòng 301', N'Phòng đôi', N'Trống', 900000, 1400000);

-- 3. Nạp danh mục Dịch vụ
INSERT INTO DichVu (MaDV, TenDV, giaVN, giaNN) VALUES 
('DV01', N'Giặt ủi', 50000, 80000),
('DV02', N'Buffet Sáng', 150000, 250000),
('DV03', N'Massage/Spa', 500000, 800000);


PRINT N'======================================================';
PRINT N'PHẦN 2: DEMO TÍNH NĂNG THEO LUỒNG NGHIỆP VỤ';
PRINT N'======================================================';

-- ► TÍNH NĂNG 1: ĐẶT PHÒNG TRƯỚC (RESERVATION)
INSERT INTO DatPhong (MaKH, Ngayden, Tiendat) VALUES 
('KH003', '2026-04-30', 500000),
('KH004', '2026-04-30', 1000000);

PRINT N'--- 1. DANH SÁCH KHÁCH ĐẶT CỌC TRƯỚC ---';
SELECT k.HotenKH, d.Ngayden, d.Tiendat 
FROM DatPhong d JOIN KhachHang k ON d.MaKH = k.MaKH;


-- ► TÍNH NĂNG 2: CHECK-IN & TRIGGER TỰ ĐỘNG KHÓA PHÒNG
INSERT INTO ThuePhong (MaKH, Ngayden) VALUES 
('KH001', '2026-04-10'), 
('KH002', '2026-04-12'),
('KH006', '2026-04-15');

-- Lễ tân xếp phòng (Đồng bộ MaPh)
INSERT INTO SuDungPhong (MaKH, MaPh) VALUES 
('KH001', 'P101'), 
('KH002', 'P201'), 
('KH006', 'P102'); 

PRINT N'--- 2. TRẠNG THÁI PHÒNG SAU KHI KHÁCH CHECK-IN (TRIGGER ĐÃ CHẠY) ---';
SELECT MaPh, TenPh, LoaiPh, Trangthai FROM Phong;


-- ► TÍNH NĂNG 3: KHÁCH SỬ DỤNG DỊCH VỤ 
INSERT INTO SuDungDV (MaKH, MaDV, NgaySD, SoLuong) VALUES 
('KH001', 'DV02', '2026-04-11', 2), 
('KH002', 'DV03', '2026-04-13', 1),
('KH006', 'DV01', '2026-04-16', 3);

PRINT N'--- 3. CHI TIẾT SỬ DỤNG DỊCH VỤ CỦA KHÁCH ---';
SELECT 
    k.HotenKH AS [Khách Hàng], 
    d.TenDV AS [Dịch Vụ], 
    s.SoLuong AS [Số lượng], 
    s.NgaySD AS [Ngày dùng]
FROM SuDungDV s
JOIN KhachHang k ON s.MaKH = k.MaKH
JOIN DichVu d ON s.MaDV = d.MaDV;


-- ► TÍNH NĂNG 4: IN HÓA ĐƠN TỰ ĐỘNG (PHÂN BIỆT GIÁ NỘI/NGOẠI)
PRINT N'--- 4A. BILL CỦA HÀ PHONG (GIÁ VIỆT NAM) ---';
EXEC sp_InBillThanhToan 'KH002';

PRINT N'--- 4B. BILL CỦA MICHAEL (GIÁ NƯỚC NGOÀI) ---';
EXEC sp_InBillThanhToan 'KH006';


-- ► TÍNH NĂNG 5: CHECK-OUT, LƯU HÓA ĐƠN & TRIGGER TRẢ PHÒNG
-- Khách Duy Phước thanh toán và rời đi
INSERT INTO HoaDon (MaHD, MaKH, Sotien, NgayTT, HinhthucTT) 
VALUES ('HD001', 'KH001', 1300000, GETDATE(), N'Tiền mặt');

-- Xóa dữ liệu sử dụng phòng (để Trigger kích hoạt)
DELETE FROM SuDungPhong WHERE MaKH = 'KH001';

-- Cập nhật ngày đi vào lịch sử thuê
UPDATE ThuePhong SET Ngaydi = GETDATE() WHERE MaKH = 'KH001';

PRINT N'--- 5. TRẠNG THÁI PHÒNG SAU KHI DUY PHƯỚC CHECK-OUT ---';
SELECT MaPh, TenPh, Trangthai FROM Phong;