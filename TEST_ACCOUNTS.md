# PCM Mobile App - Test Accounts

## Tài khoản Admin
- **Username:** admin
- **Password:** admin123
- **Role:** Admin
- **Full Name:** Administrator
- **Wallet Balance:** 10,000,000 VNĐ
- **Tier:** Platinum

## Tài khoản User
### User 1
- **Username:** user1
- **Password:** user123
- **Role:** User
- **Full Name:** Nguyễn Văn A
- **Wallet Balance:** 500,000 VNĐ
- **Tier:** Silver

### User 2
- **Username:** user2
- **Password:** user123
- **Role:** User
- **Full Name:** Trần Thị B
- **Wallet Balance:** 750,000 VNĐ
- **Tier:** Gold

### User 3
- **Username:** user3
- **Password:** user123
- **Role:** User
- **Full Name:** Lê Văn C
- **Wallet Balance:** 300,000 VNĐ
- **Tier:** Bronze

## Sân bóng có sẵn (9 sân)
1. Sân 1 - 120,000 VNĐ/h
2. Sân 2 - 100,000 VNĐ/h
3. Sân 3 - 150,000 VNĐ/h
4. Sân Futsal A - 80,000 VNĐ/h
5. Sân Futsal B - 90,000 VNĐ/h
6. Sân VIP 1 - 200,000 VNĐ/h
7. Sân VIP 2 - 180,000 VNĐ/h
8. Sân Mini 1 - 70,000 VNĐ/h
9. Sân Mini 2 - 75,000 VNĐ/h

## Cách chạy ứng dụng

### Backend (ASP.NET Core)
```bash
cd PcmBackend
dotnet run
```

### Frontend (Flutter)
```bash
cd pcm_mobile
flutter run
```

## API Endpoints
- **Login:** POST /api/auth/login
- **Admin APIs:** /api/admin/* (cần JWT token với role Admin)
- **User APIs:** /api/* (cần JWT token)

## Lưu ý
- Database SQLite sẽ được tạo tự động khi chạy backend lần đầu
- Tất cả mật khẩu đều là plain text (chỉ dùng cho testing)
- Admin có thể tạo sân bóng, giải đấu và duyệt yêu cầu nạp tiền
- Users có thể đặt sân, tham gia giải đấu và nạp tiền