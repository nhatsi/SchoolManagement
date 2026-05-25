import 'package:cloud_firestore/cloud_firestore.dart';

class SeedData {
  static final FirebaseFirestore db = FirebaseFirestore.instance;

  static Future<void> seedAll() async {
    await seedStudents();
    await seedTeachers();
    await seedSubjects();
    await seedProfiles();
    await seedTimetables();
    await seedAttendance();
    await seedGrades();
    await seedFees();
    await seedLibrary();
    await seedLeaveRequests();
    await seedNotifications();
    await seedSupportTickets();
    await seedBuses();
     await seedStudentRecords();
     await seedExams();
     await seedHealthRecords();
  }

  static Future<void> seedStudents() async {
    final students = [
      ['HS001', 'Nguyễn Văn An', '12A1', 'Nam', 'student@gmail.com', '0901000001', 'Quận 1, TP.HCM', 'Nguyễn Văn Bình', '0911000001'],
      ['HS002', 'Trần Thị Bảo Ngọc', '12A1', 'Nữ', 'ngoc12a1@gmail.com', '0901000002', 'Quận 3, TP.HCM', 'Trần Văn Nam', '0911000002'],
      ['HS003', 'Lê Minh Khang', '12A1', 'Nam', 'khang12a1@gmail.com', '0901000003', 'Bình Thạnh, TP.HCM', 'Lê Thị Hạnh', '0911000003'],
      ['HS004', 'Phạm Gia Hân', '12A1', 'Nữ', 'han12a1@gmail.com', '0901000004', 'Phú Nhuận, TP.HCM', 'Phạm Minh Đức', '0911000004'],
      ['HS005', 'Võ Hoàng Phúc', '11A1', 'Nam', 'phuc11a1@gmail.com', '0901000005', 'Gò Vấp, TP.HCM', 'Võ Thị Thu', '0911000005'],
      ['HS006', 'Đặng Thảo Vy', '11A1', 'Nữ', 'vy11a1@gmail.com', '0901000006', 'Tân Bình, TP.HCM', 'Đặng Quốc Huy', '0911000006'],
      ['HS007', 'Bùi Nhật Minh', '10A1', 'Nam', 'minh10a1@gmail.com', '0901000007', 'Quận 7, TP.HCM', 'Bùi Thanh Tùng', '0911000007'],
      ['HS008', 'Hoàng Mai Linh', '10A1', 'Nữ', 'linh10a1@gmail.com', '0901000008', 'Thủ Đức, TP.HCM', 'Hoàng Kim Oanh', '0911000008'],
      ['HS009', 'Đỗ Quốc Bảo', '10A2', 'Nam', 'bao10a2@gmail.com', '0901000009', 'Quận 5, TP.HCM', 'Đỗ Văn Cường', '0911000009'],
      ['HS010', 'Ngô Khánh Linh', '10A2', 'Nữ', 'khanhlinh10a2@gmail.com', '0901000010', 'Quận 10, TP.HCM', 'Ngô Thị Mai', '0911000010'],
      ['HS011', 'Huỳnh Đức Anh', '11A2', 'Nam', 'ducanh11a2@gmail.com', '0901000011', 'Bình Tân, TP.HCM', 'Huỳnh Quốc Việt', '0911000011'],
      ['HS012', 'Mai Phương Anh', '11A2', 'Nữ', 'phuonganh11a2@gmail.com', '0901000012', 'Nhà Bè, TP.HCM', 'Mai Thanh Sơn', '0911000012'],
    ];

    for (final s in students) {
      await db.collection('students').doc(s[0]).set({
        'id': s[0],
        'studentId': s[0],
        'name': s[1],
        'className': s[2],
        'gender': s[3],
        'email': s[4],
        'phone': s[5],
        'address': s[6],
        'parentName': s[7],
        'parentPhone': s[8],
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  static Future<void> seedTeachers() async {
    final teachers = [
      ['GV001', 'Nguyễn Thị Thu Hà', 'Toán', '0982000001', 'teacher@gmail.com', 'Tổ Tự nhiên'],
      ['GV002', 'Trần Quốc Hưng', 'Vật lý', '0982000002', 'hung.physics@gmail.com', 'Tổ Tự nhiên'],
      ['GV003', 'Lê Thanh Mai', 'Hóa học', '0982000003', 'mai.chem@gmail.com', 'Tổ Tự nhiên'],
      ['GV004', 'Phạm Minh Tuấn', 'Ngữ văn', '0982000004', 'tuan.literature@gmail.com', 'Tổ Xã hội'],
      ['GV005', 'Vũ Thị Hồng Nhung', 'Tiếng Anh', '0982000005', 'nhung.english@gmail.com', 'Tổ Ngoại ngữ'],
      ['GV006', 'Đỗ Nhật Nam', 'Tin học', '0982000006', 'nam.it@gmail.com', 'Tổ Công nghệ'],
    ];

    for (final t in teachers) {
      await db.collection('teachers').doc(t[0]).set({
        'id': t[0],
        'name': t[1],
        'subject': t[2],
        'phone': t[3],
        'email': t[4],
        'department': t[5],
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  static Future<void> seedSubjects() async {
    final subjects = [
      ['MH001', 'Toán 12', 'Nguyễn Thị Thu Hà', 'P.301'],
      ['MH002', 'Vật lý 12', 'Trần Quốc Hưng', 'P.302'],
      ['MH003', 'Hóa học 12', 'Lê Thanh Mai', 'P.303'],
      ['MH004', 'Ngữ văn 12', 'Phạm Minh Tuấn', 'P.201'],
      ['MH005', 'Tiếng Anh 12', 'Vũ Thị Hồng Nhung', 'P.202'],
      ['MH006', 'Tin học ứng dụng', 'Đỗ Nhật Nam', 'Lab 01'],
      ['MH007', 'Lịch sử', 'Phạm Minh Tuấn', 'P.204'],
      ['MH008', 'Địa lý', 'Phạm Minh Tuấn', 'P.205'],
    ];

    for (final s in subjects) {
      await db.collection('subjects').doc(s[0]).set({
        'id': s[0],
        'name': s[1],
        'teacher': s[2],
        'room': s[3],
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  static Future<void> seedProfiles() async {
    final students = await db.collection('students').get();

    for (final doc in students.docs) {
      final s = doc.data();
      final sid = s['studentId']?.toString() ?? doc.id;

      await db.collection('profiles').doc(sid).set({
        'id': sid,
        'studentId': sid,
        'name': s['name'] ?? '',
        'className': s['className'] ?? '',
        'gender': s['gender'] ?? '',
        'address': s['address'] ?? '',
        'email': s['email'] ?? '',
        'phone': s['phone'] ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  static Future<void> seedTimetables() async {
    final rows = [
      ['TKB001', '12A1', 'Thứ 2', 'Toán 12', '07:00 - 08:30'],
      ['TKB002', '12A1', 'Thứ 2', 'Vật lý 12', '08:45 - 10:15'],
      ['TKB003', '12A1', 'Thứ 3', 'Ngữ văn 12', '07:00 - 08:30'],
      ['TKB004', '12A1', 'Thứ 3', 'Tiếng Anh 12', '08:45 - 10:15'],
      ['TKB005', '11A1', 'Thứ 4', 'Hóa học 12', '07:00 - 08:30'],
      ['TKB006', '11A1', 'Thứ 4', 'Tin học ứng dụng', '08:45 - 10:15'],
      ['TKB007', '10A1', 'Thứ 5', 'Tiếng Anh 12', '13:30 - 15:00'],
      ['TKB008', '10A2', 'Thứ 6', 'Toán 12', '13:30 - 15:00'],
    ];

    for (final r in rows) {
      await db.collection('timetables').doc(r[0]).set({
        'id': r[0],
        'className': r[1],
        'day': r[2],
        'subject': r[3],
        'time': r[4],
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  static Future<void> seedAttendance() async {
    final rows = [
      ['AT001', 'HS001', 'Nguyễn Văn An', '12A1', '2026-05-20', 'Có mặt', ''],
      ['AT002', 'HS002', 'Trần Thị Bảo Ngọc', '12A1', '2026-05-20', 'Có mặt', ''],
      ['AT003', 'HS003', 'Lê Minh Khang', '12A1', '2026-05-20', 'Đi muộn', 'Kẹt xe'],
      ['AT004', 'HS004', 'Phạm Gia Hân', '12A1', '2026-05-20', 'Có mặt', ''],
      ['AT005', 'HS005', 'Võ Hoàng Phúc', '11A1', '2026-05-20', 'Vắng', 'Không phép'],
      ['AT006', 'HS006', 'Đặng Thảo Vy', '11A1', '2026-05-20', 'Có mặt', ''],
      ['AT007', 'HS001', 'Nguyễn Văn An', '12A1', '2026-05-21', 'Nghỉ có phép', 'Ốm'],
      ['AT008', 'HS007', 'Bùi Nhật Minh', '10A1', '2026-05-21', 'Có mặt', ''],
      ['AT009', 'HS008', 'Hoàng Mai Linh', '10A1', '2026-05-21', 'Đi muộn', 'Xe đưa đón đến trễ'],
    ];

    for (final r in rows) {
      await db.collection('attendance').doc(r[0]).set({
        'id': r[0],
        'studentId': r[1],
        'studentName': r[2],
        'className': r[3],
        'date': r[4],
        'status': r[5],
        'reason': r[6],
        'createdBy': 'teacher@gmail.com',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  static Future<void> seedGrades() async {
    final items = [
      ['GI_TOAN_12A1_TX1', 'Toán 12', '12A1', 'Kiểm tra thường xuyên 1', 1],
      ['GI_TOAN_12A1_GK', 'Toán 12', '12A1', 'Kiểm tra giữa kỳ', 2],
      ['GI_TOAN_12A1_CK', 'Toán 12', '12A1', 'Kiểm tra cuối kỳ', 3],
      ['GI_ANH_12A1_TX1', 'Tiếng Anh 12', '12A1', 'Speaking Test', 1],
      ['GI_VAN_12A1_GK', 'Ngữ văn 12', '12A1', 'Bài viết giữa kỳ', 2],
    ];

    for (final i in items) {
      await db.collection('grade_items').doc(i[0].toString()).set({
        'id': i[0],
        'subject': i[1],
        'className': i[2],
        'name': i[3],
        'weight': i[4],
        'semester': 'HK1',
        'schoolYear': '2025-2026',
        'createdBy': 'teacher@gmail.com',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    final grades = [
      ['GR001', 'GI_TOAN_12A1_TX1', 'HS001', 'Nguyễn Văn An', '12A1', 'Toán 12', 8.5],
      ['GR002', 'GI_TOAN_12A1_GK', 'HS001', 'Nguyễn Văn An', '12A1', 'Toán 12', 7.8],
      ['GR003', 'GI_TOAN_12A1_CK', 'HS001', 'Nguyễn Văn An', '12A1', 'Toán 12', 8.2],
      ['GR004', 'GI_ANH_12A1_TX1', 'HS001', 'Nguyễn Văn An', '12A1', 'Tiếng Anh 12', 9.0],
      ['GR005', 'GI_VAN_12A1_GK', 'HS001', 'Nguyễn Văn An', '12A1', 'Ngữ văn 12', 7.5],
      ['GR006', 'GI_TOAN_12A1_TX1', 'HS002', 'Trần Thị Bảo Ngọc', '12A1', 'Toán 12', 9.1],
      ['GR007', 'GI_TOAN_12A1_GK', 'HS002', 'Trần Thị Bảo Ngọc', '12A1', 'Toán 12', 8.7],
      ['GR008', 'GI_TOAN_12A1_CK', 'HS002', 'Trần Thị Bảo Ngọc', '12A1', 'Toán 12', 9.3],
      ['GR009', 'GI_TOAN_12A1_TX1', 'HS003', 'Lê Minh Khang', '12A1', 'Toán 12', 7.2],
      ['GR010', 'GI_TOAN_12A1_GK', 'HS003', 'Lê Minh Khang', '12A1', 'Toán 12', 7.9],
      ['GR011', 'GI_TOAN_12A1_TX1', 'HS004', 'Phạm Gia Hân', '12A1', 'Toán 12', 8.0],
      ['GR012', 'GI_ANH_12A1_TX1', 'HS004', 'Phạm Gia Hân', '12A1', 'Tiếng Anh 12', 8.6],
    ];

    for (final g in grades) {
      await db.collection('grades').doc(g[0].toString()).set({
        'id': g[0],
        'gradeItemId': g[1],
        'studentId': g[2],
        'studentName': g[3],
        'className': g[4],
        'subject': g[5],
        'score': g[6],
        'createdBy': 'teacher@gmail.com',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  static Future<void> seedFees() async {
    final feeItems = [
      ['FEE_12A1_202605', 'Học phí tháng 05/2026', 1500000, '12A1', '2026-05-31'],
      ['FEE_12A1_CSVC', 'Phí cơ sở vật chất HK2', 800000, '12A1', '2026-06-05'],
      ['FEE_11A1_202605', 'Học phí tháng 05/2026', 1400000, '11A1', '2026-05-31'],
      ['FEE_10A1_202605', 'Học phí tháng 05/2026', 1350000, '10A1', '2026-05-31'],
    ];

    final studentsSnap = await db.collection('students').get();

    for (final f in feeItems) {
      await db.collection('fee_items').doc(f[0].toString()).set({
        'id': f[0],
        'name': f[1],
        'amount': f[2],
        'className': f[3],
        'dueDate': f[4],
        'schoolYear': '2025-2026',
        'createdBy': 'admin@gmail.com',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      for (final sDoc in studentsSnap.docs) {
        final s = sDoc.data();
        if (s['className'] != f[3]) continue;

        final sid = s['studentId']?.toString() ?? sDoc.id;

        int paid = 0;
        String status = 'unpaid';
        String method = '';
        String note = '';

        if (sid == 'HS001' && f[0] == 'FEE_12A1_202605') {
          paid = 1500000;
          status = 'paid';
          method = 'Chuyển khoản';
          note = 'Đã xác nhận thanh toán.';
        } else if (sid == 'HS002' && f[0] == 'FEE_12A1_202605') {
          paid = 750000;
          status = 'partial';
          method = 'Tiền mặt';
          note = 'Đã đóng trước 50%.';
        } else if (sid == 'HS003' && f[0] == 'FEE_12A1_202605') {
          status = 'overdue';
          note = 'Quá hạn, cần liên hệ phụ huynh.';
        }

        final id = '${f[0]}_$sid';

        await db.collection('student_fees').doc(id).set({
          'id': id,
          'feeItemId': f[0],
          'feeName': f[1],
          'studentId': sid,
          'studentName': s['name'] ?? '',
          'className': f[3],
          'amount': f[2],
          'paidAmount': paid,
          'status': status,
          'dueDate': f[4],
          'schoolYear': '2025-2026',
          'paymentMethod': method,
          'note': note,
          'paidAt': status == 'paid' ? FieldValue.serverTimestamp() : null,
          'createdBy': 'admin@gmail.com',
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    }
  }

  static Future<void> seedLibrary() async {
    final books = [
      ['BOOK001', 'Tư Duy Nhanh Và Chậm', 'Daniel Kahneman', 'Kỹ năng tư duy', 5, 4],
      ['BOOK002', 'Nhà Giả Kim', 'Paulo Coelho', 'Văn học', 7, 6],
      ['BOOK003', 'Đắc Nhân Tâm', 'Dale Carnegie', 'Kỹ năng sống', 4, 4],
      ['BOOK004', 'Lược Sử Thời Gian', 'Stephen Hawking', 'Khoa học', 3, 2],
      ['BOOK005', 'Oxford Word Skills', 'Oxford University Press', 'Tiếng Anh', 6, 5],
      ['BOOK006', 'Toán Nâng Cao 12', 'NXB Giáo dục', 'Học tập', 8, 8],
    ];

    for (final b in books) {
      await db.collection('books').doc(b[0].toString()).set({
        'id': b[0],
        'title': b[1],
        'author': b[2],
        'category': b[3],
        'quantity': b[4],
        'availableQuantity': b[5],
        'note': 'Dữ liệu mẫu thư viện.',
        'createdBy': 'admin@gmail.com',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    final borrows = [
      ['BR001', 'BOOK001', 'Tư Duy Nhanh Và Chậm', 'Daniel Kahneman', 'HS001', 'Nguyễn Văn An', '12A1', '2026-05-18', '2026-05-19', '2026-05-26', '', 'borrowing', 0, 'Đang mượn.'],
      ['BR002', 'BOOK004', 'Lược Sử Thời Gian', 'Stephen Hawking', 'HS002', 'Trần Thị Bảo Ngọc', '12A1', '2026-05-20', '', '', '', 'pending', 0, 'Chờ admin duyệt.'],
      ['BR003', 'BOOK005', 'Oxford Word Skills', 'Oxford University Press', 'HS004', 'Phạm Gia Hân', '12A1', '2026-05-10', '2026-05-11', '2026-05-18', '', 'overdue', 0, 'Quá hạn trả sách.'],
      ['BR004', 'BOOK002', 'Nhà Giả Kim', 'Paulo Coelho', 'HS005', 'Võ Hoàng Phúc', '11A1', '2026-05-02', '2026-05-03', '2026-05-10', '2026-05-09', 'returned', 0, 'Trả đúng hạn.'],
    ];

    for (final b in borrows) {
      await db.collection('borrow_records').doc(b[0].toString()).set({
        'id': b[0],
        'bookId': b[1],
        'bookTitle': b[2],
        'bookAuthor': b[3],
        'studentId': b[4],
        'studentName': b[5],
        'className': b[6],
        'requestDate': b[7],
        'borrowDate': b[8],
        'dueDate': b[9],
        'returnDate': b[10],
        'status': b[11],
        'fineAmount': b[12],
        'note': b[13],
        'createdBy': 'student@gmail.com',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  static Future<void> seedLeaveRequests() async {
    final leaves = [
      ['LEAVE001', 'HS001', 'Nguyễn Văn An', '12A1', '2026-05-21', '2026-05-21', 'Em bị sốt, xin phép nghỉ một buổi để đi khám.', 'approved', 'Đã duyệt, theo dõi sức khỏe.', 'student@gmail.com', 'teacher@gmail.com'],
      ['LEAVE002', 'HS002', 'Trần Thị Bảo Ngọc', '12A1', '2026-05-24', '2026-05-25', 'Gia đình có việc riêng.', 'pending', '', 'ngoc12a1@gmail.com', ''],
      ['LEAVE003', 'HS005', 'Võ Hoàng Phúc', '11A1', '2026-05-23', '2026-05-23', 'Đi thi học sinh giỏi cấp quận.', 'approved', 'Đã xác nhận lịch thi.', 'phuc11a1@gmail.com', 'teacher@gmail.com'],
      ['LEAVE004', 'HS008', 'Hoàng Mai Linh', '10A1', '2026-05-22', '2026-05-22', 'Xin nghỉ không rõ lý do.', 'rejected', 'Cần phụ huynh xác nhận.', 'linh10a1@gmail.com', 'teacher@gmail.com'],
    ];

    for (final l in leaves) {
      await db.collection('leave_requests').doc(l[0]).set({
        'id': l[0],
        'studentId': l[1],
        'studentName': l[2],
        'className': l[3],
        'fromDate': l[4],
        'toDate': l[5],
        'reason': l[6],
        'status': l[7],
        'teacherNote': l[8],
        'createdBy': l[9],
        'createdAt': FieldValue.serverTimestamp(),
        'approvedBy': l[10],
        'approvedAt': l[10] == '' ? null : FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  static Future<void> seedNotifications() async {
    final rows = [
      ['NT001', 'Lịch kiểm tra giữa kỳ HK2', 'Nhà trường thông báo lịch kiểm tra giữa kỳ HK2 sẽ bắt đầu từ ngày 27/05/2026.', 'all', '', 'admin@gmail.com', 'admin'],
      ['NT002', 'Họp giáo viên chủ nhiệm', 'Kính mời giáo viên chủ nhiệm các lớp tham dự cuộc họp lúc 15:30 tại phòng hội đồng.', 'role', 'teacher', 'admin@gmail.com', 'admin'],
      ['NT003', 'Thông báo lớp 12A1', 'Lớp 12A1 nộp hồ sơ đăng ký thi thử trước thứ Sáu tuần này.', 'class', '12A1', 'teacher@gmail.com', 'teacher'],
      ['NT004', 'Nhắc đóng học phí', 'Học sinh HS003 vui lòng hoàn tất học phí tháng 05/2026 trước ngày 31/05.', 'student', 'HS003', 'admin@gmail.com', 'admin'],
      ['NT005', 'CLB Tiếng Anh tuyển thành viên', 'CLB Tiếng Anh mở đơn đăng ký thành viên mới. Học sinh quan tâm đăng ký tại văn phòng đoàn.', 'all', '', 'teacher@gmail.com', 'teacher'],
    ];

    for (final r in rows) {
      await db.collection('notifications').doc(r[0]).set({
        'id': r[0],
        'title': r[1],
        'content': r[2],
        'targetType': r[3],
        'targetValue': r[4],
        'createdBy': r[5],
        'createdRole': r[6],
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await db.collection('notification_reads').doc('NT001_student@gmail.com').set({
      'id': 'NT001_student@gmail.com',
      'notificationId': 'NT001',
      'userEmail': 'student@gmail.com',
      'studentId': 'HS001',
      'role': 'student',
      'readAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> seedSupportTickets() async {
    final tickets = [
      ['SP001', 'Cần kiểm tra lại điểm Toán giữa kỳ', 'Em thấy điểm giữa kỳ môn Toán trên hệ thống là 7.8 nhưng bài em được trả là 8.0. Mong thầy cô kiểm tra giúp em.', 'Điểm số', 'pending', '', 'student@gmail.com', 'student', 'Nguyễn Văn An', 'HS001', '12A1', ''],
      ['SP002', 'Thắc mắc học phí tháng 05', 'Phụ huynh đã chuyển khoản học phí nhưng hệ thống vẫn hiển thị chưa đóng đủ.', 'Học phí', 'processing', 'Nhà trường đang đối soát giao dịch với bộ phận kế toán.', 'ngoc12a1@gmail.com', 'student', 'Trần Thị Bảo Ngọc', 'HS002', '12A1', 'admin@gmail.com'],
      ['SP003', 'Đề xuất thêm sách tham khảo', 'Thư viện nên bổ sung thêm sách ôn thi THPT môn Vật lý và Tiếng Anh.', 'Thư viện', 'resolved', 'Nhà trường đã ghi nhận và sẽ bổ sung trong đợt mua sách tháng tới.', 'teacher@gmail.com', 'teacher', 'Nguyễn Thị Thu Hà', '', '', 'admin@gmail.com'],
      ['SP004', 'Không xem được thông báo lớp', 'Em không thấy thông báo dành cho lớp 10A1 trong mục thông báo của tôi.', 'Tài khoản', 'rejected', 'Tài khoản chưa liên kết đúng lớp. Vui lòng cập nhật hồ sơ học sinh.', 'linh10a1@gmail.com', 'student', 'Hoàng Mai Linh', 'HS008', '10A1', 'admin@gmail.com'],
    ];

    for (final t in tickets) {
      await db.collection('support_tickets').doc(t[0]).set({
        'id': t[0],
        'title': t[1],
        'content': t[2],
        'category': t[3],
        'status': t[4],
        'adminReply': t[5],
        'createdBy': t[6],
        'createdRole': t[7],
        'senderName': t[8],
        'studentId': t[9],
        'className': t[10],
        'handledBy': t[11],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'handledAt': t[11] == '' ? null : FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  static Future<void> seedBuses() async {
    final buses = [
      ['BUS01', 'Tuyến Quận 1 - Quận 3 - Trung tâm', 'Chú Minh', '0977000001', 'Đang hoạt động'],
      ['BUS02', 'Tuyến Gò Vấp - Bình Thạnh - Trung tâm', 'Chú Hòa', '0977000002', 'Đang hoạt động'],
      ['BUS03', 'Tuyến Thủ Đức - Bình Tân - Trung tâm', 'Chú Sơn', '0977000003', 'Bảo trì cuối tuần'],
    ];

    for (final b in buses) {
      await db.collection('buses').doc(b[0]).set({
        'id': b[0],
        'route': b[1],
        'driver': b[2],
        'phone': b[3],
        'status': b[4],
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }
static Future<void> seedStudentRecords() async {
  final records = [
    [
      'SR001',
      'HS001',
      'Nguyễn Văn An',
      '12A1',
      'reward',
      'Học sinh tích cực trong học tập',
      'Có nhiều tiến bộ trong môn Toán, tích cực phát biểu xây dựng bài.',
      '2026-05-12',
      'Cấp lớp',
      'teacher@gmail.com',
    ],
    [
      'SR002',
      'HS002',
      'Trần Thị Bảo Ngọc',
      '12A1',
      'reward',
      'Đạt thành tích cao kiểm tra giữa kỳ',
      'Đạt điểm xuất sắc trong bài kiểm tra giữa kỳ môn Toán và Tiếng Anh.',
      '2026-05-14',
      'Cấp trường',
      'teacher@gmail.com',
    ],
    [
      'SR003',
      'HS003',
      'Lê Minh Khang',
      '12A1',
      'discipline',
      'Nhắc nhở đi học muộn',
      'Đi học muộn 2 lần trong tuần, cần khắc phục trong thời gian tới.',
      '2026-05-16',
      'Nhắc nhở',
      'teacher@gmail.com',
    ],
    [
      'SR004',
      'HS004',
      'Phạm Gia Hân',
      '12A1',
      'reward',
      'Hỗ trợ hoạt động lớp',
      'Tích cực hỗ trợ giáo viên trong hoạt động ngoại khóa của lớp.',
      '2026-05-18',
      'Cấp lớp',
      'teacher@gmail.com',
    ],
    [
      'SR005',
      'HS005',
      'Võ Hoàng Phúc',
      '11A1',
      'discipline',
      'Chưa hoàn thành bài tập',
      'Không nộp bài tập đúng hạn nhiều lần, giáo viên đã nhắc nhở.',
      '2026-05-19',
      'Nhắc nhở',
      'teacher@gmail.com',
    ],
  ];

  for (final r in records) {
    await db.collection('student_records').doc(r[0]).set({
      'id': r[0],
      'studentId': r[1],
      'studentName': r[2],
      'className': r[3],
      'type': r[4],
      'title': r[5],
      'content': r[6],
      'date': r[7],
      'level': r[8],
      'createdBy': r[9],
      'createdRole': 'teacher',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
static Future<void> seedExams() async {
  final exams = [
    [
      'EX001',
      'Kiểm tra giữa kỳ HK2',
      'Toán 12',
      '12A1',
      '2026-05-27',
      '07:30',
      '09:00',
      'P.301',
      'Mang máy tính cầm tay, không sử dụng tài liệu.',
    ],
    [
      'EX002',
      'Kiểm tra giữa kỳ HK2',
      'Tiếng Anh 12',
      '12A1',
      '2026-05-28',
      '09:15',
      '10:30',
      'P.202',
      'Gồm phần trắc nghiệm và tự luận.',
    ],
    [
      'EX003',
      'Thi thử THPT lần 1',
      'Ngữ văn 12',
      '12A1',
      '2026-06-02',
      '07:00',
      '09:00',
      'P.201',
      'Học sinh chuẩn bị giấy thi theo quy định.',
    ],
    [
      'EX004',
      'Kiểm tra định kỳ',
      'Tin học ứng dụng',
      '11A1',
      '2026-05-29',
      '13:30',
      '15:00',
      'Lab 01',
      'Thực hành trực tiếp trên máy.',
    ],
  ];

  for (final e in exams) {
    await db.collection('exam_schedules').doc(e[0]).set({
      'id': e[0],
      'examName': e[1],
      'subject': e[2],
      'className': e[3],
      'examDate': e[4],
      'startTime': e[5],
      'endTime': e[6],
      'room': e[7],
      'note': e[8],
      'createdBy': 'teacher@gmail.com',
      'createdRole': 'teacher',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  final results = [
    [
      'EX001_HS001',
      'EX001',
      'Kiểm tra giữa kỳ HK2',
      'Toán 12',
      '2026-05-27',
      'HS001',
      'Nguyễn Văn An',
      '12A1',
      8.5,
      'Làm bài tốt, cần trình bày rõ hơn.',
    ],
    [
      'EX001_HS002',
      'EX001',
      'Kiểm tra giữa kỳ HK2',
      'Toán 12',
      '2026-05-27',
      'HS002',
      'Trần Thị Bảo Ngọc',
      '12A1',
      9.2,
      'Bài làm xuất sắc.',
    ],
    [
      'EX002_HS001',
      'EX002',
      'Kiểm tra giữa kỳ HK2',
      'Tiếng Anh 12',
      '2026-05-28',
      'HS001',
      'Nguyễn Văn An',
      '12A1',
      8.8,
      'Kỹ năng đọc hiểu tốt.',
    ],
    [
      'EX002_HS003',
      'EX002',
      'Kiểm tra giữa kỳ HK2',
      'Tiếng Anh 12',
      '2026-05-28',
      'HS003',
      'Lê Minh Khang',
      '12A1',
      7.4,
      'Cần luyện thêm phần viết.',
    ],
  ];

  for (final r in results) {
    await db.collection('exam_results').doc(r[0].toString()).set({
      'id': r[0],
      'examId': r[1],
      'examName': r[2],
      'subject': r[3],
      'examDate': r[4],
      'studentId': r[5],
      'studentName': r[6],
      'className': r[7],
      'score': r[8],
      'comment': r[9],
      'createdBy': 'teacher@gmail.com',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
static Future<void> seedHealthRecords() async {
  final healthRecords = [
    {
      'id': 'HS001',
      'studentId': 'HS001',
      'studentName': 'Nguyễn Văn An',
      'className': '12A1',
      'heightCm': 170.0,
      'weightKg': 62.0,
      'bloodType': 'O',
      'allergies': 'Không',
      'chronicDiseases': 'Không',
      'emergencyContact': 'Nguyễn Văn Bình - 0901000001',
      'note': 'Sức khỏe ổn định, tham gia thể thao tốt.',
      'lastCheckDate': '2026-05-20',
    },
    {
      'id': 'HS002',
      'studentId': 'HS002',
      'studentName': 'Trần Thị Bảo Ngọc',
      'className': '12A1',
      'heightCm': 162.0,
      'weightKg': 50.0,
      'bloodType': 'A',
      'allergies': 'Hải sản',
      'chronicDiseases': 'Không',
      'emergencyContact': 'Trần Minh Đức - 0901000002',
      'note': 'Cần lưu ý dị ứng hải sản khi tổ chức bán trú hoặc ngoại khóa.',
      'lastCheckDate': '2026-05-20',
    },
    {
      'id': 'HS003',
      'studentId': 'HS003',
      'studentName': 'Lê Minh Khang',
      'className': '12A1',
      'heightCm': 174.0,
      'weightKg': 68.0,
      'bloodType': 'B',
      'allergies': 'Không',
      'chronicDiseases': 'Viêm mũi dị ứng',
      'emergencyContact': 'Lê Thanh Hải - 0901000003',
      'note': 'Dễ bị viêm mũi khi thời tiết thay đổi.',
      'lastCheckDate': '2026-05-21',
    },
    {
      'id': 'HS004',
      'studentId': 'HS004',
      'studentName': 'Phạm Gia Hân',
      'className': '12A1',
      'heightCm': 158.0,
      'weightKg': 47.0,
      'bloodType': 'AB',
      'allergies': 'Phấn hoa',
      'chronicDiseases': 'Không',
      'emergencyContact': 'Phạm Thu Hà - 0901000004',
      'note': 'Cần hạn chế tiếp xúc phấn hoa khi hoạt động ngoài trời.',
      'lastCheckDate': '2026-05-21',
    },
    {
      'id': 'HS005',
      'studentId': 'HS005',
      'studentName': 'Võ Hoàng Phúc',
      'className': '11A1',
      'heightCm': 168.0,
      'weightKg': 72.0,
      'bloodType': 'O',
      'allergies': 'Không',
      'chronicDiseases': 'Không',
      'emergencyContact': 'Võ Văn Thành - 0901000005',
      'note': 'BMI hơi cao, nên tăng cường vận động.',
      'lastCheckDate': '2026-05-22',
    },
    {
      'id': 'HS006',
      'studentId': 'HS006',
      'studentName': 'Đặng Minh Anh',
      'className': '11A1',
      'heightCm': 160.0,
      'weightKg': 45.0,
      'bloodType': 'A',
      'allergies': 'Không',
      'chronicDiseases': 'Thiếu máu nhẹ',
      'emergencyContact': 'Đặng Thị Mai - 0901000006',
      'note': 'Cần theo dõi chế độ dinh dưỡng.',
      'lastCheckDate': '2026-05-22',
    },
  ];

  for (final h in healthRecords) {
    await db.collection('health_records').doc(h['id'].toString()).set({
      ...h,
      'updatedBy': 'teacher@gmail.com',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  final medicalChecks = [
    {
      'id': 'MC001',
      'studentId': 'HS001',
      'studentName': 'Nguyễn Văn An',
      'className': '12A1',
      'checkDate': '2026-04-10',
      'heightCm': 169.0,
      'weightKg': 61.0,
      'bmi': '21.4 - Bình thường',
      'vision': '10/10',
      'dental': 'Tốt',
      'bloodPressure': '110/70',
      'conclusion': 'Sức khỏe tốt',
      'recommendation': 'Duy trì vận động thể thao.',
    },
    {
      'id': 'MC002',
      'studentId': 'HS001',
      'studentName': 'Nguyễn Văn An',
      'className': '12A1',
      'checkDate': '2026-05-20',
      'heightCm': 170.0,
      'weightKg': 62.0,
      'bmi': '21.5 - Bình thường',
      'vision': '10/10',
      'dental': 'Tốt',
      'bloodPressure': '112/72',
      'conclusion': 'Sức khỏe ổn định',
      'recommendation': 'Tiếp tục duy trì chế độ sinh hoạt hiện tại.',
    },
    {
      'id': 'MC003',
      'studentId': 'HS002',
      'studentName': 'Trần Thị Bảo Ngọc',
      'className': '12A1',
      'checkDate': '2026-05-20',
      'heightCm': 162.0,
      'weightKg': 50.0,
      'bmi': '19.1 - Bình thường',
      'vision': '9/10',
      'dental': 'Tốt',
      'bloodPressure': '105/68',
      'conclusion': 'Sức khỏe tốt',
      'recommendation': 'Lưu ý dị ứng hải sản.',
    },
    {
      'id': 'MC004',
      'studentId': 'HS003',
      'studentName': 'Lê Minh Khang',
      'className': '12A1',
      'checkDate': '2026-05-21',
      'heightCm': 174.0,
      'weightKg': 68.0,
      'bmi': '22.5 - Bình thường',
      'vision': '10/10',
      'dental': 'Cần theo dõi',
      'bloodPressure': '115/75',
      'conclusion': 'Sức khỏe ổn định',
      'recommendation': 'Khám răng định kỳ, theo dõi viêm mũi dị ứng.',
    },
    {
      'id': 'MC005',
      'studentId': 'HS004',
      'studentName': 'Phạm Gia Hân',
      'className': '12A1',
      'checkDate': '2026-05-21',
      'heightCm': 158.0,
      'weightKg': 47.0,
      'bmi': '18.8 - Bình thường',
      'vision': '10/10',
      'dental': 'Tốt',
      'bloodPressure': '104/66',
      'conclusion': 'Sức khỏe tốt',
      'recommendation': 'Tránh tiếp xúc phấn hoa trong mùa dị ứng.',
    },
    {
      'id': 'MC006',
      'studentId': 'HS005',
      'studentName': 'Võ Hoàng Phúc',
      'className': '11A1',
      'checkDate': '2026-05-22',
      'heightCm': 168.0,
      'weightKg': 72.0,
      'bmi': '25.5 - Thừa cân',
      'vision': '9/10',
      'dental': 'Tốt',
      'bloodPressure': '118/76',
      'conclusion': 'Cần tăng vận động',
      'recommendation': 'Giảm đồ ngọt, tăng hoạt động thể chất.',
    },
    {
      'id': 'MC007',
      'studentId': 'HS006',
      'studentName': 'Đặng Minh Anh',
      'className': '11A1',
      'checkDate': '2026-05-22',
      'heightCm': 160.0,
      'weightKg': 45.0,
      'bmi': '17.6 - Thiếu cân',
      'vision': '10/10',
      'dental': 'Tốt',
      'bloodPressure': '100/65',
      'conclusion': 'Thiếu cân nhẹ',
      'recommendation': 'Bổ sung dinh dưỡng, theo dõi tình trạng thiếu máu.',
    },
  ];

  for (final m in medicalChecks) {
    await db.collection('medical_checks').doc(m['id'].toString()).set({
      ...m,
      'createdBy': 'teacher@gmail.com',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
}