-- 1. Tạo các quan hệ và khai báo các khóa chính, khóa ngoại của quan hệ.
CREATE TABLE KHACHHANG
(
	MAKH CHAR(4),
	HOTEN VARCHAR(40),
	DCHI VARCHAR(50),
	SODT VARCHAR(20),
	NGSINH SMALLDATETIME,
	NGDK SMALLDATETIME,
	DOANHSO MONEY,
	CONSTRAINT PK_KHACHHANG PRIMARY KEY (MAKH)
)

-- Tạo bảng NHANVIEN
CREATE TABLE NHANVIEN
(
	MANV CHAR(4),
	HOTEN VARCHAR(40),
	SODT VARCHAR(20),
	NGVL SMALLDATETIME
	CONSTRAINT PK_NHANVIEN PRIMARY KEY (MANV)
)

-- Tạo bảng SANPHAM
CREATE TABLE SANPHAM
(
	MASP CHAR(4),
	TENSP VARCHAR(40),
	DVT VARCHAR(20),
	NUOCSX VARCHAR(40),
	GIA MONEY
	CONSTRAINT PK_SANPHAM PRIMARY KEY (MASP)
)

-- Tạo bảng HOADON
CREATE TABLE HOADON
(
	SOHD INT,
	NGHD SMALLDATETIME,
	MAKH CHAR(4),
	MANV CHAR(4),
	TRIGIA MONEY
	CONSTRAINT PK_HOADON PRIMARY KEY (SOHD)
)

-- Tạo bảng CTHD (Chi tiết hóa đơn)
CREATE TABLE CTHD
(
	SOHD INT,
	MASP CHAR(4),
	SL INT,
	CONSTRAINT PK_CTHD PRIMARY KEY (SOHD, MASP),
)

-- THÊM CÁC KHÓA NGOẠI
ALTER TABLE HOADON ADD  CONSTRAINT FK_MAKH FOREIGN KEY (MAKH) REFERENCES KHACHHANG(MAKH)
ALTER TABLE HOADON ADD CONSTRAINT FK_MANV FOREIGN KEY (MANV) REFERENCES NHANVIEN(MANV)
ALTER TABLE CTHD ADD CONSTRAINT FK_SOHD FOREIGN KEY (SOHD) REFERENCES HOADON(SOHD)
ALTER TABLE CTHD ADD CONSTRAINT FK_MASP FOREIGN KEY (MASP) REFERENCES SANPHAM(MASP)

-- I.2 Thêm vào thuộc tính GHICHU có kiểu dữ liệu varchar(20) cho quan hệ SANPHAM
ALTER TABLE SANPHAM ADD GHICHU VARCHAR(20)

-- I.3 Thêm vào thuộc tính LOAIKH có kiểu dữ liệu là tinyint cho quan hệ KHACHHANG
ALTER TABLE KHACHHANG ADD LOAIKH TINYINT

-- I.4 Sửa kiểu dữ liệu của thuộc tính GHICHU trong quan hệ SANPHAM thành varchar(100)
ALTER TABLE SANPHAM ALTER COLUMN GHICHU VARCHAR(100)

-- I.5 Xóa thuộc tính GHICHU trong quan hệ SANPHAM
ALTER TABLE SANPHAM DROP COLUMN GHICHU

-- I.6 Làm thế nào để thuộc tính LOAIKH trong quan hệ KHACHHANG có thể lưu các giá trị là: “Vang lai”, “Thuong xuyen”, “Vip”, … 
ALTER TABLE KHACHHANG ALTER COLUMN LOAIKH VARCHAR(12)
ALTER TABLE KHACHHANG ADD CONSTRAINT CHK_LOAIKH CHECK (LOAIKH IN ('Vang lai', 'Thuong xuyen', 'Vip'))

-- I.7 Đơn vị tính của sản phẩm chỉ có thể là (“cay”,”hop”,”cai”,”quyen”,”chuc”)
ALTER TABLE SANPHAM ADD CONSTRAINT CHK_DVT CHECK (DVT IN ('cay', 'hop', 'cai', 'quyen', 'chuc'))

-- I.8 Giá bán của sản phẩm từ 500 đồng trở lên
ALTER TABLE SANPHAM ADD CONSTRAINT CHK_GIA CHECK (GIA >= 500)

-- I.9 Mỗi lần mua hàng, khách hàng phải mua ít nhất 1 sản phẩm
ALTER TABLE HOADON ADD CONSTRAINT CHK_MUAHANG CHECK (TRIGIA > 0)

-- I.10 Ngày khách hàng đăng ký là khách hàng thành viên phải lớn hơn ngày sinh của người đó
ALTER TABLE KHACHHANG ADD CONSTRAINT CHK_NGDK CHECK (NGDK > NGSINH)

-- I.11 Ngày mua hàng (NGHD) của một khách hàng thành viên sẽ lớn hơn hoặc bằng ngày khách hàng đó đăng ký thành viên (NGDK).
-- Trigger: thêm và sửa NGHD của HOADON
CREATE TRIGGER trg_ins_udt_NgHD ON HoaDon
FOR Insert, Update
AS
BEGIN
	DECLARE @NgDK smalldatetime, @NgHD smalldatetime
	select @NgHD = NgHD from inserted
	select @NgDK = NgDK from KHACHHANG
	IF (EXISTS (SELECT * FROM KhachHang, inserted 
				WHERE KhachHang.MaKH = inserted.MaKH 
				AND KhachHang.NgDK > inserted.NgHD))
		BEGIN
			PRINT @NGDK
			PRINT @NGHD
			PRINT 'Error: NgDK PHAI LON HON NgHD'
			ROLLBACK TRANSACTION
		END
	ELSE
		BEGIN
			PRINT 'Them thanh cong'
		END
END

-- Trigger: sửa NgDK của KhachHang
CREATE TRIGGER trg_upd_NgDK ON KhachHang
FOR Update
AS
BEGIN
	DECLARE @NgDK smalldatetime, @NgHD smalldatetime
	select @NgHD = NgHD from HOADON
	select @NgDK = NgDK from inserted
	IF (EXISTS (SELECT * FROM HoaDon, inserted
				WHERE HoaDon.MaKH = inserted.MAKH
				AND HoaDon.NgHD < inserted.NgDK))
		BEGIN
			PRINT @NGDK
			PRINT @NGHD
			PRINT 'Error: NgDK PHAI LON HON NgHD'
			ROLLBACK TRANSACTION
		END
	ELSE
		BEGIN
			PRINT 'Sua thanh cong'
		END
END

-- I.12 Ngày bán hàng (NGHD) của một nhân viên phải lớn hơn hoặc bằng ngày nhân viên đó vào làm.

-- Trigger: thêm và sửa NgHD của HoaDon
CREATE TRIGGER trg_ins_udt_NgBH ON HoaDon
FOR Insert, Update
AS
BEGIN
	DECLARE @NgVL smalldatetime, @NgHD smalldatetime
	select @NgHD = NgHD from inserted
	select @NgVL = NgVL from NHANVIEN
	IF (EXISTS (SELECT * FROM NhanVien, inserted 
				WHERE NhanVien.MaNV = inserted.MaKH 
				AND NhanVien.NgVL > inserted.NgHD))
		BEGIN
			PRINT 'Error: NgDK PHAI LON HON NgHD'
			ROLLBACK TRANSACTION
		END
	ELSE
		BEGIN
			PRINT 'Them thanh cong'
		END
END

-- Trigger: sửa NGVL của NhanVien
CREATE TRIGGER trg_upd_NgVL ON NhanVien
FOR Update
AS
BEGIN
	DECLARE @NgVL smalldatetime, @NgHD smalldatetime
	select @NgHD = NgHD from HOADON
	select @NgVL = NgVL from inserted
	IF (EXISTS (SELECT * FROM HoaDon, inserted
				WHERE HoaDon.MaNV = inserted.MANV
				AND HoaDon.NgHD < inserted.NgVL))
		BEGIN
			PRINT 'Error: NgDK PHAI LON HON NgHD'
			ROLLBACK TRANSACTION
		END
	ELSE
		BEGIN
			PRINT 'Sua thanh cong'
		END
END

-- I.13 Mỗi một hóa đơn phải có ít nhất một chi tiết hóa đơn
-- Trigger: Thêm một hoá đơn 
CREATE TRIGGER trg_ins on HoaDon
FOR insert
AS
BEGIN
	DECLARE @count_CTHD int, @SOHD int
	SELECT @SOHD = SOHD from inserted
	SELECT @count_CTHD = count(SOHD) from CTHD where SOHD = @SOHD
	IF (@count_CTHD < 1)
		BEGIN
			print 'Error: Thêm không thành công'
			ROLLBACK TRANSACTION
		END
	ELSE
		BEGIN
			print 'Thêm thành công'
		END
END
-- Trigger: Xoá một CTHD
CREATE TRIGGER trg_del on CTHD
FOR delete
AS
BEGIN
	DECLARE @count_CTHD int, @SOHD int
	SELECT @SOHD = SOHD from HOADON
	SELECT @count_CTHD = count(SOHD) from inserted where SOHD = @SOHD
	IF (@count_CTHD < 1)
		BEGIN
			print 'Error: Thêm không thành công'
			ROLLBACK TRANSACTION
		END
	ELSE
		BEGIN
			print 'Thêm thành công'
		END
END

-- 14.	Trị giá của một hóa đơn là tổng thành tiền (số lượng*đơn giá) của các chi tiết thuộc hóa đơn đó.
CREATE TRIGGER TRG_CTHD ON CTHD FOR INSERT, DELETE
AS
BEGIN
	DECLARE @SOHD INT, @TONGGIATRI INT

	SELECT @TONGGIATRI = SUM(SL * GIA), @SOHD = SOHD 
	FROM INSERTED INNER JOIN SANPHAM
	ON INSERTED.MASP = SANPHAM.MASP
	GROUP BY SOHD

	UPDATE HOADON
	SET TRIGIA += @TONGGIATRI
	WHERE SOHD = @SOHD
END

CREATE TRIGGER TR_DEL_CTHD ON CTHD FOR DELETE
AS
BEGIN
	DECLARE @SOHD INT, @GIATRI INT

	SELECT @SOHD = SOHD, @GIATRI = SL * GIA 
	FROM DELETED INNER JOIN SANPHAM 
	ON SANPHAM.MASP = DELETED.MASP

	UPDATE HOADON
	SET TRIGIA -= @GIATRI
	WHERE SOHD = @SOHD
END

-- I.15 Doanh số của một khách hàng là tổng trị giá các hóa đơn mà khách hàng thành viên đó đã mua.

-- Trigger: Update DoanhSo của KhachHang
CREATE TRIGGER trg_upd_DoanhSo ON KhachHang
FOR Update
AS
BEGIN
	DECLARE @TongTriGia MONEY, @DoanhSo MONEY

	SELECT @TongTriGia = SUM(TriGia)
	FROM HoaDon, inserted
	WHERE HoaDon.MaKH = inserted.MaKH

	SELECT @DoanhSo = DoanhSo FROM inserted

	IF (@DoanhSo <> @TongTriGia)
	BEGIN
		PRINT('Doanh so cua mot khach hang la tong tri gia cac hoa don khach hang thanh vien do da mua')
		ROLLBACK TRANSACTION
	END
END

-- II.2 Tạo quan hệ SANPHAM1 chứa toàn bộ dữ liệu của quan hệ SANPHAM
-- Tạo quan hệ KHACHHANG1 chứa toàn bộ dữ liệu của quan hệ KHACHHANG
SELECT * INTO SANPHAM1 FROM SANPHAM
SELECT * INTO KHACHHANG1 FROM KHACHHANG

-- II.3 Cập nhật giá tăng 5% đối với những sản phẩm do “Thai Lan” sản xuất (cho quan hệ SANPHAM1)
UPDATE SANPHAM1
SET Gia = 1.05 * Gia
WHERE NuocSX = 'Thai Lan'

-- II.4 Cập nhật giá giảm 5% đối với những sản phẩm do “Trung Quoc” sản xuất có giá từ 10.000 trở xuống (cho quan hệ SANPHAM1)
UPDATE SANPHAM1
SET GIA = 0.95 * GIA
WHERE NUOCSX = 'Trung Quoc' AND GIA <= 10000


-- II.5 Cập nhật giá trị LOAIKH là “Vip” đối với những khách hàng đăng ký thành viên trước ngày 1/1/2007 có doanh số từ 10.000.000
-- trở lên hoặc khách hàng đăng ký thành viên từ 1/1/2007 trở về sau có doanh số từ 2.000.000 trở lên (cho quan hệ KHACHHANG1). 
UPDATE KHACHHANG1
SET LOAIKH = 'Vip'
WHERE (NGDK < '1/1/2007' AND DOANHSO >= 10000000)
OR (NGDK >= '1/1/2007' AND DOANHSO >= 2000000)

-- III.1 In ra danh sách các sản phẩm (MASP,TENSP) do “Trung Quoc” sản xuất
SELECT MaSP, TenSP
FROM SanPham
WHERE NuocSX = 'Trung Quoc'

-- III.2 In ra danh sách các sản phẩm (MASP, TENSP) có đơn vị tính là “cay”, ”quyen”
SELECT MaSP, TenSP
FROM SanPham
WHERE DVT IN ('cay', 'quyen')

-- III.3 In ra danh sách các sản phẩm (MASP,TENSP) có mã sản phẩm bắt đầu là “B” và kết thúc là “01”
SELECT MaSP, TenSP
FROM SanPham
WHERE MaSP LIKE 'B%01'

-- III.4 In ra danh sách các sản phẩm (MASP,TENSP) do “Trung Quốc” sản xuất có giá từ 30.000 đến 40.000
SELECT MaSP, TenSP
FROM SanPham
WHERE 
	NuocSX = 'Trung Quoc'
	AND Gia BETWEEN 30000 AND 40000

-- III.5 In ra danh sách các sản phẩm (MASP,TENSP) do “Trung Quoc” hoặc “Thai Lan” sản xuất có giá từ 30.000 đến 40.000
SELECT MaSP, TenSP
FROM SanPham
WHERE 
	NuocSX IN ('Trung Quoc', 'Thai Lan')
	AND Gia BETWEEN 30000 AND 40000

-- III.6 In ra các số hóa đơn, trị giá hóa đơn bán ra trong ngày 1/1/2007 và ngày 2/1/2007
SELECT SoHD, TriGia
FROM HoaDon
WHERE NgHD IN ('1/1/2007', '2/1/2007')

-- III.7 In ra các số hóa đơn, trị giá hóa đơn trong tháng 1/2007
-- sắp xếp theo ngày (tăng dần) và trị giá của hóa đơn (giảm dần)
SELECT SoHD, TriGia
FROM HoaDon
WHERE MONTH(NgHD) = 1 AND YEAR(NgHD) = 2007
ORDER BY NgHD ASC, TriGia DESC

-- III.8 In ra danh sách các khách hàng (MAKH, HOTEN) đã mua hàng trong ngày 1/1/2007
SELECT DISTINCT KhachHang.MaKH, HoTen
FROM KhachHang, HoaDon
WHERE 
	KhachHang.MaKH = HoaDon.MaKH 
	AND NgHD = '1/1/2007'

-- III.9 In ra số hóa đơn, trị giá các hóa đơn do nhân viên có tên “Nguyen Van B” lập trong ngày 28/10/2006
SELECT SoHD, TriGia
FROM HoaDon, NhanVien
WHERE
	HoaDon.MaNV = NhanVien.MaNV
	AND HoTen = 'Nguyen Van B'
	AND NgHD = '28/10/2006'

-- III.10 In ra danh sách các sản phẩm (MASP,TENSP) được khách hàng có tên “Nguyen Van A” mua trong tháng 10/2006
SELECT DISTINCT SanPham.MaSP, TenSP
FROM SanPham, CTHD, KhachHang, HoaDon
WHERE
	CTHD.MaSP = SanPham.MaSP
	AND CTHD.SoHD = HoaDon.SoHD
	AND HoaDon.MaKH = KhachHang.MaKH
	AND HoTen = 'Nguyen Van A'
	AND MONTH(NgHD) = 10 AND YEAR(NgHD) = 2006

-- III.11 Tìm các số hóa đơn đã mua sản phẩm có mã số “BB01” hoặc “BB02”.
SELECT DISTINCT SoHD
FROM CTHD
WHERE MaSP IN ('BB01', 'BB02')

-- III.12 Tìm các số hóa đơn đã mua sản phẩm có mã số “BB01” hoặc “BB02”, mỗi sản phẩm mua với số lượng từ 10 đến 20
SELECT DISTINCT SoHD
FROM CTHD
WHERE 
	MaSP IN ('BB01', 'BB02') 
	AND SL BETWEEN 10 AND 20

-- III.13 Tìm các số hóa đơn mua cùng lúc 2 sản phẩm có mã số “BB01” và “BB02”, mỗi sản phẩm mua với số lượng từ 10 đến 20
SELECT DISTINCT SoHD
FROM CTHD
WHERE MaSP = 'BB01' AND SL BETWEEN 10 AND 20
INTERSECT
(
	SELECT DISTINCT SoHD
	FROM CTHD
	WHERE MaSP = 'BB02' AND SL BETWEEN 10 AND 20
)

-- III.14 In ra danh sách các sản phẩm (MASP,TENSP) do “Trung Quoc” sản xuất
-- hoặc các sản phẩm được bán ra trong ngày 1/1/2007
SELECT DISTINCT SanPham.MaSP, TenSP
FROM HoaDon, SanPham, CTHD
WHERE
	HoaDon.SoHD = CTHD.SoHD
	AND CTHD.MaSP = SanPham.MaSP
	AND (NuocSX = 'Trung Quoc'
	OR NgHD = '1/1/2007')


-- III.15 In ra danh sách các sản phẩm (MASP,TENSP) không bán được
SELECT MaSP, TenSP
FROM SanPham
WHERE MaSP NOT IN (SELECT MaSP FROM CTHD)

-- III.16 In ra danh sách các sản phẩm (MASP,TENSP) không bán được trong năm 2006
SELECT MaSP, TenSP
FROM SanPham
WHERE MaSP NOT IN
(
	SELECT MaSP 
	FROM CTHD, HoaDon
	WHERE 
		CTHD.SoHD = HoaDon.SoHD
		AND YEAR(NgHD) = 2006
)


-- III.17 In ra danh sách các sản phẩm (MASP,TENSP) do “Trung Quoc” sản xuất không bán được trong năm 2006. 
SELECT MaSP, TenSP
FROM SanPham
WHERE
	NuocSX = 'Trung Quoc'
	AND MaSP NOT IN
	(
		SELECT MaSP 
		FROM CTHD, HoaDon
		WHERE 
			CTHD.SoHD = HoaDon.SoHD
			AND YEAR(NgHD) = 2006
	)

-- III.18 Tìm số hóa đơn đã mua tất cả các sản phẩm do Singapore sản xuất
SELECT SoHD
FROM HoaDon
WHERE NOT EXISTS
(
	SELECT *
	FROM SanPham
	WHERE NuocSX = 'Singapore'
	AND NOT EXISTS
	(
		SELECT *
		FROM CTHD
		WHERE CTHD.SoHD = HoaDon.SoHD
		AND CTHD.MaSP = SanPham.MaSP
	)
)

-- III.19 Tìm số hóa đơn trong năm 2006 đã mua ít nhất tất cả các sản phẩm do Singapore sản xuất
SELECT SoHD
FROM HoaDon
WHERE YEAR(NgHD) = 2006 
AND NOT EXISTS
(
	SELECT *
	FROM SanPham
	WHERE NuocSX = 'Singapore'
	AND NOT EXISTS
	(
		SELECT *
		FROM CTHD
		WHERE CTHD.SoHD = HoaDon.SoHD
		AND CTHD.MaSP = SanPham.MaSP
	)
)

-- III.20 Có bao nhiêu hóa đơn không phải của khách hàng đăng ký thành viên mua?
SELECT COUNT(*)
FROM HoaDon
WHERE MaKH IS NULL

-- III.21 Có bao nhiêu sản phẩm khác nhau được bán ra trong năm 2006
SELECT COUNT(DISTINCT MaSP)
FROM HoaDon, CTHD
WHERE
	HoaDon.SoHD = CTHD.SoHD
	AND YEAR(NgHD) = 2006

-- III.22 Cho biết trị giá hóa đơn cao nhất, thấp nhất là bao nhiêu ?
SELECT MIN(TriGia) Min_TriGia, MAX(TriGia) Max_TriGia
FROM HoaDon

-- III.23 Trị giá trung bình của tất cả các hóa đơn được bán ra trong năm 2006 là bao nhiêu
SELECT AVG(TriGia)
FROM HoaDon
WHERE YEAR(NgHD) = 2006

-- III.24 Tính doanh thu bán hàng trong năm 2006
SELECT SUM(TriGia)
FROM HoaDon
WHERE YEAR(NgHD) = 2006

-- III.25 Tìm số hóa đơn có trị giá cao nhất trong năm 2006
SELECT MAX(TriGia)
FROM HoaDon
WHERE YEAR(NgHD) = 2006

-- III.26 Tìm họ tên khách hàng đã mua hóa đơn có trị giá cao nhất trong năm 2006
SELECT DISTINCT HoTen
FROM KhachHang, HoaDon
WHERE 
	HoaDon.MaKH = KhachHang.MaKH
	AND YEAR(NgHD) = 2006
	AND TriGia = (SELECT MAX(TriGia) FROM HoaDon WHERE YEAR(NgHD) = 2006)

--  III.27 In ra danh sách 3 khách hàng (MAKH, HOTEN) có doanh số cao nhất
SELECT TOP 3 MaKH, HoTen
FROM KhachHang
ORDER BY DoanhSo DESC

-- III.28 In ra danh sách các sản phẩm (MASP, TENSP) có giá bán bằng 1 trong 3 mức giá cao nhất.
SELECT MaSP, TenSP
FROM SanPham
WHERE Gia IN (
	SELECT DISTINCT TOP 3 Gia
	FROM SanPham
	ORDER BY Gia DESC
)

-- III.29 In ra danh sách các sản phẩm (MASP, TENSP) do “Thai Lan” sản xuất có giá bằng 1 trong 3 mức giá cao nhất (của tất cả các sản phẩm)
SELECT MaSP, TenSP
FROM SanPham
WHERE NuocSX = 'Thai Lan'
AND Gia IN (
	SELECT DISTINCT TOP 3 Gia
	FROM SanPham
	ORDER BY Gia DESC
)

-- III.30 In ra danh sách các sản phẩm (MASP, TENSP) do “Trung Quoc” sản xuất có giá bằng 1 trong 3 mức giá cao nhất (của sản phẩm do “Trung Quoc” sản xuất)
SELECT MaSP, TenSP
FROM SanPham
WHERE NuocSX = 'Trung Quoc'
AND Gia IN (
	SELECT DISTINCT TOP 3 Gia
	FROM SanPham
	WHERE NuocSX = 'Trung Quoc'
	ORDER BY Gia DESC
)

-- III.31 In ra danh sách 3 khách hàng có doanh số cao nhất (sắp xếp theo kiểu xếp hạng)
SELECT TOP 3 *
FROM KhachHang
ORDER BY DoanhSo DESC

-- III.32 Tính tổng số sản phẩm do “Trung Quoc” sản xuất
SELECT COUNT(*)
FROM SanPham
WHERE NuocSX = 'Trung Quoc'

-- III.33 Tính tổng số sản phẩm của từng nước sản xuất
SELECT NuocSX, COUNT(*) SoSP
FROM SanPham
GROUP BY NuocSX

-- III.34 Với từng nước sản xuất, tìm giá bán cao nhất, thấp nhất, trung bình của các sản phẩm
SELECT NuocSX, MAX(Gia) Max_Gia, MIN(Gia) Min_Gia, AVG(Gia) TB_Gia
FROM SanPham
GROUP BY NuocSX

-- III.35 Tính doanh thu bán hàng mỗi ngày
SELECT NgHD, SUM(TriGia) DoanhThu
FROM HoaDon
GROUP BY NgHD

--- III.36 Tính tổng số lượng của từng sản phẩm bán ra trong tháng 10/2006
SELECT SanPham.MaSP, SUM(SL) SoLuongBan
FROM SanPham, HoaDon, CTHD
WHERE
	CTHD.MaSP = SanPham.MaSP
	AND CTHD.SoHD = HoaDon.SoHD
	AND MONTH(NgHD) = 10 AND YEAR(NgHD) = 2006
GROUP BY SanPham.MaSP

-- III.37 Tính doanh thu bán hàng của từng tháng trong năm 2006
SELECT MONTH(NgHD) Thang, SUM(TriGia) DoanhThu
FROM HoaDon
WHERE YEAR(NgHD) = 2006
GROUP BY MONTH(NgHD)

-- III.38 Tìm hóa đơn có mua ít nhất 4 sản phẩm khác nhau
SELECT SoHD
FROM CTHD
GROUP BY SoHD
HAVING COUNT(DISTINCT MaSP) >= 4

-- III.39 Tìm hóa đơn có mua 3 sản phẩm do “Viet Nam” sản xuất (3 sản phẩm khác nhau). 
SELECT SoHD
FROM CTHD, SanPham
WHERE
	CTHD.MaSP = SanPham.MaSP
	AND NuocSX = 'Viet Nam'
GROUP BY SoHD
HAVING COUNT(DISTINCT CTHD.MaSP) >= 3

-- III.40 Tìm khách hàng (MAKH, HOTEN) có số lần mua hàng nhiều nhất
SELECT KhachHang.MaKH, HoTen
FROM KhachHang, HoaDon
WHERE KhachHang.MaKH = HoaDon.MaKH
GROUP BY KhachHang.MaKH, HoTen
HAVING COUNT(*) >= ALL(SELECT COUNT(*) FROM HoaDon GROUP BY MaKH)

-- III.41 Tháng mấy trong năm 2006, doanh số bán hàng cao nhất
SELECT MONTH(NgHD)
FROM HoaDon
WHERE YEAR(NgHD) = 2006
GROUP BY MONTH(NgHD)
HAVING SUM(TriGia) >= ALL(SELECT SUM(TriGia) FROM HoaDON WHERE YEAR(NgHD) = 2006 GROUP BY MONTH(NgHD))

-- III.42 Tìm sản phẩm (MASP, TENSP) có tổng số lượng bán ra thấp nhất trong năm 2006
SELECT TOP 1 WITH TIES SanPham.MaSP, TenSP
FROM SanPham, CTHD, HoaDon
WHERE 
	SanPham.MaSP = CTHD.MaSP
	AND HoaDon.SoHD = CTHD.SoHD
	AND YEAR(NgHD) = 2006
GROUP BY SanPham.MaSP, TenSP
ORDER BY SUM(SL)

-- III.43 Mỗi nước sản xuất, tìm sản phẩm (MASP,TENSP) có giá bán cao nhất
SELECT NuocSX, MaSP, TenSP
FROM SanPham SP1
WHERE EXISTS
(
	SELECT NuocSX
	FROM SanPham SP2
	GROUP BY NuocSX
	HAVING SP1.NuocSX = SP2.NuocSX
	AND SP1.Gia = MAX(Gia)
)

-- III.44 Tìm nước sản xuất sản xuất ít nhất 3 sản phẩm có giá bán khác nhau
SELECT NuocSX
FROM SanPham
GROUP BY NUOCSX
HAVING COUNT(DISTINCT GIA) >= 3

-- III.45 Trong 10 khách hàng có doanh số cao nhất, tìm khách hàng có số lần mua hàng nhiều nhất
SELECT *
FROM KhachHang
WHERE MaKH IN
(
	SELECT TOP 1 WITH TIES HoaDon.MaKH
	FROM (SELECT TOP 10 MaKH FROM KhachHang ORDER BY DoanhSo DESC) AS A
	JOIN HoaDon ON A.MaKH = HoaDon.MaKH
	GROUP BY HoaDon.MaKH
	ORDER BY COUNT(*) DESC
)