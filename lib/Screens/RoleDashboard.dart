import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_management/Screens/LoginPage.dart';
import 'package:school_management/Screens/GradeManagementPage.dart';
import 'package:school_management/Screens/FeeManagementPage.dart';
import 'package:school_management/Screens/NotificationManagementPage.dart';
import 'package:school_management/Screens/LibraryManagementPage.dart';
import 'package:school_management/Screens/SupportTicketPage.dart';
import 'package:school_management/Screens/StudentRecordPage.dart';
import 'package:school_management/Screens/HealthManagementPage.dart';

class RoleRouter extends StatelessWidget {
  final String forceEmail;

  const RoleRouter({
    Key? key,
    required this.forceEmail,
  }) : super(key: key);

  Future<RoleInfo> loadRole() async {
    final email = forceEmail.trim().toLowerCase();
    final user = FirebaseAuth.instance.currentUser;

    if (email == 'admin@gmail.com') {
      return RoleInfo(role: 'admin', email: email, studentId: '');
    }

    if (email == 'teacher@gmail.com') {
      return RoleInfo(role: 'teacher', email: email, studentId: '');
    }

    if (email == 'student@gmail.com') {
      return RoleInfo(role: 'student', email: email, studentId: 'HS001');
    }

    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        final data = doc.data();

        if (data != null) {
          return RoleInfo(
            role: data['role']?.toString() ?? 'student',
            email: email,
            studentId: data['studentId']?.toString() ?? '',
          );
        }
      } catch (_) {}
    }

    return RoleInfo(role: 'student', email: email, studentId: '');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<RoleInfo>(
      future: loadRole(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return RoleHome(info: snapshot.data!);
      },
    );
  }
}

class RoleInfo {
  final String role;
  final String email;
  final String studentId;

  RoleInfo({
    required this.role,
    required this.email,
    required this.studentId,
  });
}

class MenuAction {
  final String title;
  final IconData icon;
  final String collection;
  final List<String> fields;
  final bool canEdit;
  final String? filterField;
  final String? filterValue;
  final String type;

  MenuAction({
    required this.title,
    required this.icon,
    required this.collection,
    required this.fields,
    required this.canEdit,
    this.filterField,
    this.filterValue,
    this.type = 'crud',
  });
}

class DashboardStat {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  DashboardStat({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class DashboardSummary {
  final List<DashboardStat> stats;

  DashboardSummary({
    required this.stats,
  });
}

class RoleHome extends StatelessWidget {
  final RoleInfo info;

  const RoleHome({
    Key? key,
    required this.info,
  }) : super(key: key);

  FirebaseFirestore get db => FirebaseFirestore.instance;

  static const Color bg = Color(0xFFF4F7FB);
  static const Color navy = Color(0xFF0F172A);
  static const Color muted = Color(0xFF64748B);

  String get roleTitle {
    if (info.role == 'admin') return 'Admin - Quản trị hệ thống';
    if (info.role == 'teacher') return 'Giáo viên';
    return 'Học sinh';
  }

  String get roleName {
    if (info.role == 'admin') return 'ADMIN';
    if (info.role == 'teacher') return 'GIÁO VIÊN';
    return 'HỌC SINH';
  }

  String get roleBadgeText {
    if (info.role == 'admin') return 'Quản trị viên';
    if (info.role == 'teacher') return 'Tài khoản giáo viên';
    return 'Tài khoản học sinh';
  }

  Future<int> countCollection(String collection) async {
    try {
      final snap = await db.collection(collection).get();
      return snap.docs.length;
    } catch (_) {
      return 0;
    }
  }

  Future<int> countWhere(
    String collection,
    String field,
    dynamic value,
  ) async {
    try {
      final snap =
          await db.collection(collection).where(field, isEqualTo: value).get();
      return snap.docs.length;
    } catch (_) {
      return 0;
    }
  }

  Future<int> countStatus(
    String collection,
    List<String> statuses, {
    String statusField = 'status',
    String? studentId,
    String? createdBy,
  }) async {
    try {
      Query q = db.collection(collection);

      if (studentId != null && studentId.isNotEmpty) {
        q = q.where('studentId', isEqualTo: studentId);
      }

      if (createdBy != null && createdBy.isNotEmpty) {
        q = q.where('createdBy', isEqualTo: createdBy);
      }

      final snap = await q.get();

      return snap.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data[statusField]?.toString() ?? '';
        return statuses.contains(status);
      }).length;
    } catch (_) {
      return 0;
    }
  }

  Future<DashboardSummary> loadDashboardSummary() async {
    final sid = info.studentId.isEmpty ? 'HS001' : info.studentId;

    if (info.role == 'admin') {
      final totalStudents = await countCollection('students');
      final totalTeachers = await countCollection('teachers');
      final pendingLeaves = await countStatus('leave_requests', ['pending']);
      final unpaidFees = await countStatus(
        'student_fees',
        ['unpaid', 'partial', 'overdue'],
      );
      final activeBorrows = await countStatus(
        'borrow_records',
        ['pending', 'borrowing', 'overdue'],
      );
      final pendingTickets = await countStatus(
        'support_tickets',
        ['pending', 'processing'],
      );
      final studentRecords = await countCollection('student_records');
      final healthRecords = await countCollection('health_records');
      final medicalChecks = await countCollection('medical_checks');

      return DashboardSummary(
        stats: [
          DashboardStat(
            title: 'Học sinh',
            value: '$totalStudents',
            icon: Icons.people_alt_rounded,
            color: const Color(0xFF2563EB),
          ),
          DashboardStat(
            title: 'Giáo viên',
            value: '$totalTeachers',
            icon: Icons.school_rounded,
            color: const Color(0xFF4F46E5),
          ),
          DashboardStat(
            title: 'Đơn nghỉ chờ duyệt',
            value: '$pendingLeaves',
            icon: Icons.pending_actions_rounded,
            color: const Color(0xFFF59E0B),
          ),
          DashboardStat(
            title: 'Học phí chưa xong',
            value: '$unpaidFees',
            icon: Icons.account_balance_wallet_rounded,
            color: const Color(0xFFEF4444),
          ),
          DashboardStat(
            title: 'Sách đang xử lý',
            value: '$activeBorrows',
            icon: Icons.local_library_rounded,
            color: const Color(0xFF10B981),
          ),
          DashboardStat(
            title: 'Phản hồi cần xử lý',
            value: '$pendingTickets',
            icon: Icons.support_agent_rounded,
            color: const Color(0xFF9333EA),
          ),
          DashboardStat(
            title: 'Khen thưởng / kỷ luật',
            value: '$studentRecords',
            icon: Icons.emoji_events_rounded,
            color: const Color(0xFF14B8A6),
          ),
          DashboardStat(
            title: 'Hồ sơ sức khỏe',
            value: '$healthRecords',
            icon: Icons.medical_information_rounded,
            color: const Color(0xFFEC4899),
          ),
          DashboardStat(
            title: 'Lần khám sức khỏe',
            value: '$medicalChecks',
            icon: Icons.health_and_safety_rounded,
            color: const Color(0xFF06B6D4),
          ),
        ],
      );
    }

    if (info.role == 'teacher') {
      final totalStudents = await countCollection('students');
      final pendingLeaves = await countStatus('leave_requests', ['pending']);
      final gradeItems = await countCollection('grade_items');
      final notifications = await countCollection('notifications');
      final myTickets = await countStatus(
        'support_tickets',
        ['pending', 'processing', 'resolved', 'rejected'],
        createdBy: info.email,
      );

      return DashboardSummary(
        stats: [
          DashboardStat(
            title: 'Học sinh',
            value: '$totalStudents',
            icon: Icons.people_alt_rounded,
            color: const Color(0xFF2563EB),
          ),
          DashboardStat(
            title: 'Đơn nghỉ chờ duyệt',
            value: '$pendingLeaves',
            icon: Icons.pending_actions_rounded,
            color: const Color(0xFFF59E0B),
          ),
          DashboardStat(
            title: 'Cột điểm hệ số',
            value: '$gradeItems',
            icon: Icons.grade_rounded,
            color: const Color(0xFF10B981),
          ),
          DashboardStat(
            title: 'Thông báo',
            value: '$notifications',
            icon: Icons.notifications_active_rounded,
            color: const Color(0xFF9333EA),
          ),
          DashboardStat(
            title: 'Phản hồi của tôi',
            value: '$myTickets',
            icon: Icons.support_agent_rounded,
            color: const Color(0xFF4F46E5),
          ),
        ],
      );
    }

    final myLeaves = await countWhere('leave_requests', 'studentId', sid);
    final approvedLeaves = await countStatus(
      'leave_requests',
      ['approved'],
      studentId: sid,
    );
    final myUnpaidFees = await countStatus(
      'student_fees',
      ['unpaid', 'partial', 'overdue'],
      studentId: sid,
    );
    final myGrades = await countWhere('grades', 'studentId', sid);
    final myBorrows = await countStatus(
      'borrow_records',
      ['pending', 'borrowing', 'overdue'],
      studentId: sid,
    );
    final myTickets = await countStatus(
      'support_tickets',
      ['pending', 'processing', 'resolved', 'rejected'],
      createdBy: info.email,
    );
    final myStudentRecords = await countWhere('student_records', 'studentId', sid);
    final myMedicalChecks = await countWhere(
      'medical_checks',
      'studentId',
      sid,
    );

    return DashboardSummary(
      stats: [
        DashboardStat(
          title: 'Đơn nghỉ của tôi',
          value: '$myLeaves',
          icon: Icons.edit_calendar_rounded,
          color: const Color(0xFFF59E0B),
        ),
        DashboardStat(
          title: 'Đơn đã duyệt',
          value: '$approvedLeaves',
          icon: Icons.check_circle_rounded,
          color: const Color(0xFF10B981),
        ),
        DashboardStat(
          title: 'Học phí cần đóng',
          value: '$myUnpaidFees',
          icon: Icons.payments_rounded,
          color: const Color(0xFFEF4444),
        ),
        DashboardStat(
          title: 'Cột điểm',
          value: '$myGrades',
          icon: Icons.grade_rounded,
          color: const Color(0xFF2563EB),
        ),
        DashboardStat(
          title: 'Sách đang mượn',
          value: '$myBorrows',
          icon: Icons.local_library_rounded,
          color: const Color(0xFF9333EA),
        ),
        DashboardStat(
          title: 'Phản hồi đã gửi',
          value: '$myTickets',
          icon: Icons.support_agent_rounded,
          color: const Color(0xFF4F46E5),
        ),
        DashboardStat(
          title: 'Khen thưởng/kỷ luật của tôi',
          value: '$myStudentRecords',
          icon: Icons.emoji_events_rounded,
          color: const Color(0xFF14B8A6),
        ),
        DashboardStat(
          title: 'Lần khám sức khỏe',
          value: '$myMedicalChecks',
          icon: Icons.health_and_safety_rounded,
          color: const Color(0xFF06B6D4),
        ),
      ],
    );
  }

  List<MenuAction> actions() {
    if (info.role == 'admin') {
      return [
        MenuAction(
          title: 'Quản lý học sinh',
          icon: Icons.people_alt_rounded,
          collection: 'students',
          fields: ['id', 'name', 'className', 'phone', 'email'],
          canEdit: true,
        ),
        MenuAction(
          title: 'Quản lý giáo viên',
          icon: Icons.school_rounded,
          collection: 'teachers',
          fields: ['id', 'name', 'subject', 'phone'],
          canEdit: true,
        ),
        MenuAction(
          title: 'Quản lý môn học',
          icon: Icons.menu_book_rounded,
          collection: 'subjects',
          fields: ['id', 'name', 'teacher', 'room'],
          canEdit: true,
        ),
        MenuAction(
          title: 'Điểm danh',
          icon: Icons.fact_check_rounded,
          collection: 'attendance',
          fields: [
            'id',
            'studentId',
            'studentName',
            'className',
            'date',
            'status',
            'reason',
          ],
          canEdit: true,
        ),
        MenuAction(
          title: 'Ghi nhận học sinh',
          icon: Icons.emoji_events_rounded,
          collection: '',
          fields: [],
          canEdit: true,
          type: 'student_record',
        ),
        MenuAction(
          title: 'Quản lý điểm hệ số',
          icon: Icons.grade_rounded,
          collection: '',
          fields: [],
          canEdit: true,
          type: 'grade_weighted',
        ),
        MenuAction(
          title: 'Hồ sơ',
          icon: Icons.badge_rounded,
          collection: 'profiles',
          fields: ['id', 'studentId', 'name', 'className', 'gender', 'address'],
          canEdit: true,
        ),
        MenuAction(
          title: 'Hồ sơ sức khỏe',
          icon: Icons.medical_information_rounded,
          collection: '',
          fields: [],
          canEdit: true,
          type: 'health_management',
        ),
        MenuAction(
          title: 'Khen thưởng / Kỷ luật',
          icon: Icons.emoji_events_rounded,
          collection: '',
          fields: [],
          canEdit: true,
          type: 'student_record',
        ),
        MenuAction(
          title: 'Quản lý học phí',
          icon: Icons.account_balance_wallet_rounded,
          collection: '',
          fields: [],
          canEdit: true,
          type: 'fee_management',
        ),
        MenuAction(
          title: 'Thời khóa biểu',
          icon: Icons.calendar_month_rounded,
          collection: 'timetables',
          fields: ['id', 'className', 'day', 'subject', 'time'],
          canEdit: true,
        ),
        MenuAction(
          title: 'Quản lý thư viện',
          icon: Icons.local_library_rounded,
          collection: '',
          fields: [],
          canEdit: true,
          type: 'library_management',
        ),
        MenuAction(
          title: 'Theo dõi xe',
          icon: Icons.directions_bus_rounded,
          collection: 'buses',
          fields: ['id', 'route', 'driver', 'phone'],
          canEdit: true,
        ),
        MenuAction(
          title: 'Quản lý thông báo',
          icon: Icons.notifications_active_rounded,
          collection: '',
          fields: [],
          canEdit: true,
          type: 'notification_management',
        ),
        MenuAction(
          title: 'Quản lý phản hồi',
          icon: Icons.support_agent_rounded,
          collection: '',
          fields: [],
          canEdit: true,
          type: 'support_ticket',
        ),
        MenuAction(
          title: 'Duyệt đơn xin nghỉ',
          icon: Icons.assignment_turned_in_rounded,
          collection: '',
          fields: [],
          canEdit: true,
          type: 'leave',
        ),
      ];
    }

    if (info.role == 'teacher') {
      return [
        MenuAction(
          title: 'Danh sách học sinh',
          icon: Icons.people_alt_rounded,
          collection: 'students',
          fields: ['id', 'name', 'className', 'phone', 'email'],
          canEdit: false,
        ),
        MenuAction(
          title: 'Điểm danh',
          icon: Icons.fact_check_rounded,
          collection: 'attendance',
          fields: [
            'id',
            'studentId',
            'studentName',
            'className',
            'date',
            'status',
            'reason',
          ],
          canEdit: true,
        ),
        MenuAction(
          title: 'Theo dõi sức khỏe',
          icon: Icons.medical_information_rounded,
          collection: '',
          fields: [],
          canEdit: true,
          type: 'health_management',
        ),
        MenuAction(
          title: 'Nhập điểm hệ số',
          icon: Icons.grade_rounded,
          collection: '',
          fields: [],
          canEdit: true,
          type: 'grade_weighted',
        ),
        MenuAction(
          title: 'Duyệt đơn xin nghỉ',
          icon: Icons.assignment_turned_in_rounded,
          collection: '',
          fields: [],
          canEdit: true,
          type: 'leave',
        ),
        MenuAction(
          title: 'Xem học phí',
          icon: Icons.account_balance_wallet_rounded,
          collection: '',
          fields: [],
          canEdit: false,
          type: 'fee_management',
        ),
        MenuAction(
          title: 'Thư viện',
          icon: Icons.local_library_rounded,
          collection: '',
          fields: [],
          canEdit: false,
          type: 'library_management',
        ),
        MenuAction(
          title: 'Gửi phản hồi',
          icon: Icons.support_agent_rounded,
          collection: '',
          fields: [],
          canEdit: true,
          type: 'support_ticket',
        ),
        MenuAction(
          title: 'Thời khóa biểu',
          icon: Icons.calendar_month_rounded,
          collection: 'timetables',
          fields: ['id', 'className', 'day', 'subject', 'time'],
          canEdit: false,
        ),
        MenuAction(
          title: 'Thông báo',
          icon: Icons.notifications_active_rounded,
          collection: '',
          fields: [],
          canEdit: false,
          type: 'notification_management',
        ),
      ];
    }

    final sid = info.studentId.isEmpty ? 'HS001' : info.studentId;

    return [
      MenuAction(
        title: 'Hồ sơ cá nhân',
        icon: Icons.badge_rounded,
        collection: 'profiles',
        fields: ['id', 'studentId', 'name', 'className', 'gender', 'address'],
        canEdit: false,
        filterField: 'studentId',
        filterValue: sid,
      ),
      MenuAction(
        title: 'Sức khỏe của tôi',
        icon: Icons.medical_information_rounded,
        collection: '',
        fields: [],
        canEdit: false,
        type: 'health_management',
      ),
      MenuAction(
        title: 'Khen thưởng / Kỷ luật',
        icon: Icons.emoji_events_rounded,
        collection: '',
        fields: [],
        canEdit: false,
        type: 'student_record',
      ),
      MenuAction(
        title: 'Điểm danh',
        icon: Icons.fact_check_rounded,
        collection: 'attendance',
        fields: [
          'id',
          'studentId',
          'studentName',
          'className',
          'date',
          'status',
          'reason',
        ],
        canEdit: false,
        filterField: 'studentId',
        filterValue: sid,
      ),
      MenuAction(
        title: 'Bảng điểm hệ số',
        icon: Icons.grade_rounded,
        collection: '',
        fields: [],
        canEdit: false,
        type: 'grade_weighted',
      ),
      MenuAction(
        title: 'Học phí của tôi',
        icon: Icons.account_balance_wallet_rounded,
        collection: '',
        fields: [],
        canEdit: false,
        type: 'fee_management',
      ),
      MenuAction(
        title: 'Xin nghỉ học',
        icon: Icons.edit_calendar_rounded,
        collection: '',
        fields: [],
        canEdit: true,
        type: 'leave',
      ),
      MenuAction(
        title: 'Thư viện của tôi',
        icon: Icons.local_library_rounded,
        collection: '',
        fields: [],
        canEdit: false,
        type: 'library_management',
      ),
      MenuAction(
        title: 'Phản hồi / Hỗ trợ',
        icon: Icons.support_agent_rounded,
        collection: '',
        fields: [],
        canEdit: true,
        type: 'support_ticket',
      ),
      MenuAction(
        title: 'Thời khóa biểu',
        icon: Icons.calendar_month_rounded,
        collection: 'timetables',
        fields: ['id', 'className', 'day', 'subject', 'time'],
        canEdit: false,
      ),
      MenuAction(
        title: 'Thông báo của tôi',
        icon: Icons.notifications_active_rounded,
        collection: '',
        fields: [],
        canEdit: false,
        type: 'notification_management',
      ),
    ];
  }

  String actionDescription(MenuAction action) {
    switch (action.type) {
      case 'leave':
        return info.role == 'student'
            ? 'Tạo và theo dõi đơn xin nghỉ học'
            : 'Duyệt, từ chối và cập nhật điểm danh';
      case 'grade_weighted':
        return info.role == 'student'
            ? 'Xem điểm và điểm trung bình theo hệ số'
            : 'Tạo cột điểm, nhập điểm và tính trung bình';
      case 'fee_management':
        return info.role == 'student'
            ? 'Theo dõi khoản thu và trạng thái thanh toán'
            : 'Tạo khoản thu và cập nhật học phí';
      case 'notification_management':
        return 'Gửi và xem thông báo theo đối tượng nhận';
      case 'library_management':
        return info.role == 'student'
            ? 'Tra cứu sách và gửi yêu cầu mượn'
            : 'Quản lý sách, duyệt mượn và trả sách';
      case 'support_ticket':
        return info.role == 'admin'
            ? 'Xử lý phản hồi và yêu cầu hỗ trợ'
            : 'Gửi phản hồi, khiếu nại hoặc yêu cầu hỗ trợ';
      case 'student_record':
        return info.role == 'student'
            ? 'Xem hồ sơ khen thưởng và kỷ luật cá nhân'
            : 'Ghi nhận khen thưởng, nhắc nhở hoặc kỷ luật học sinh';
      case 'health_management':
        return info.role == 'student'
            ? 'Xem hồ sơ sức khỏe, BMI và lịch sử khám định kỳ'
            : 'Quản lý hồ sơ sức khỏe, BMI và lịch sử khám học sinh';
      default:
        if (action.collection == 'students') return 'Quản lý hồ sơ và thông tin học sinh';
        if (action.collection == 'teachers') return 'Quản lý thông tin giáo viên';
        if (action.collection == 'subjects') return 'Quản lý môn học, giáo viên và phòng học';
        if (action.collection == 'attendance') return 'Theo dõi trạng thái điểm danh';
        if (action.collection == 'profiles') return 'Xem và cập nhật hồ sơ cá nhân';
        if (action.collection == 'timetables') return 'Quản lý lịch học và thời khóa biểu';
        if (action.collection == 'buses') return 'Theo dõi tuyến xe và tài xế';
        return 'Mở chức năng nghiệp vụ';
    }
  }

  String actionMeta(MenuAction action) {
    if (action.canEdit) return 'Có quyền cập nhật';
    return 'Chỉ xem dữ liệu';
  }

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MyHomePage(title: '')),
      (route) => false,
    );
  }

  void openAction(BuildContext context, MenuAction action) {
    if (action.type == 'leave') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LeaveRequestPage(info: info),
        ),
      );
      return;
    }

    if (action.type == 'grade_weighted') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GradeManagementPage(
            role: info.role,
            email: info.email,
            studentId: info.studentId.isEmpty ? 'HS001' : info.studentId,
          ),
        ),
      );
      return;
    }

    if (action.type == 'fee_management') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FeeManagementPage(
            role: info.role,
            email: info.email,
            studentId: info.studentId.isEmpty ? 'HS001' : info.studentId,
          ),
        ),
      );
      return;
    }

    if (action.type == 'notification_management') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NotificationManagementPage(
            role: info.role,
            email: info.email,
            studentId: info.studentId.isEmpty ? 'HS001' : info.studentId,
          ),
        ),
      );
      return;
    }

    if (action.type == 'library_management') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LibraryManagementPage(
            role: info.role,
            email: info.email,
            studentId: info.studentId.isEmpty ? 'HS001' : info.studentId,
          ),
        ),
      );
      return;
    }

    if (action.type == 'support_ticket') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SupportTicketPage(
            role: info.role,
            email: info.email,
            studentId: info.studentId.isEmpty ? 'HS001' : info.studentId,
          ),
        ),
      );
      return;
    }

    if (action.type == 'student_record') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StudentRecordPage(
            role: info.role,
            email: info.email,
            studentId: info.studentId.isEmpty ? 'HS001' : info.studentId,
          ),
        ),
      );
      return;
    }

    if (action.type == 'health_management') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => HealthManagementPage(
            role: info.role,
            email: info.email,
            studentId: info.studentId.isEmpty ? 'HS001' : info.studentId,
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CrudPage(
          title: action.title,
          collection: action.collection,
          fields: action.fields,
          canEdit: action.canEdit,
          filterField: action.filterField,
          filterValue: action.filterValue,
        ),
      ),
    );
  }

  Widget drawerItem(BuildContext context, MenuAction action) {
    return ListTile(
      dense: true,
      leading: Icon(action.icon, color: const Color(0xFF2563EB)),
      title: Text(action.title),
      onTap: () {
        Navigator.pop(context);
        openAction(context, action);
      },
    );
  }

  Widget buildHero(BuildContext context, DashboardSummary? summary) {
    final mainNumber = summary == null || summary.stats.isEmpty
        ? '--'
        : summary.stats.first.value;

    final mainLabel = summary == null || summary.stats.isEmpty
        ? 'Đang tải dữ liệu'
        : summary.stats.first.title;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1D4ED8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D4ED8).withOpacity(0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth > 760;

          final left = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withOpacity(0.16)),
                ),
                child: Text(
                  roleBadgeText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                roleTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Trung tâm quản lý học sinh, điểm danh, sức khỏe, điểm số, học phí, thư viện, phản hồi và khen thưởng/kỷ luật.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.78),
                  fontSize: 15,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  heroChip(Icons.email_rounded, info.email),
                  if (info.role == 'student')
                    heroChip(
                      Icons.badge_rounded,
                      'Mã HS: ${info.studentId.isEmpty ? 'HS001' : info.studentId}',
                    ),
                ],
              ),
            ],
          );

          final right = Container(
            width: wide ? 230 : double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: Row(
              mainAxisSize: wide ? MainAxisSize.min : MainAxisSize.max,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.insights_rounded,
                    color: Color(0xFF1D4ED8),
                    size: 32,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mainNumber,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        mainLabel,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.76),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );

          if (wide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: left),
                const SizedBox(width: 24),
                right,
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              left,
              const SizedBox(height: 18),
              right,
            ],
          );
        },
      ),
    );
  }

  Widget heroChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white.withOpacity(0.82)),
          const SizedBox(width: 7),
          Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.86),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildStatCard(DashboardStat stat) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: stat.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              stat.icon,
              color: stat.color,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat.value,
                  style: TextStyle(
                    color: stat.color,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  stat.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: navy,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildStatGrid(List<DashboardStat> stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        int crossAxisCount = 2;
        if (width > 1120) {
          crossAxisCount = 4;
        } else if (width > 760) {
          crossAxisCount = 3;
        }

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: width > 760 ? 2.35 : 1.7,
          children: stats.map(buildStatCard).toList(),
        );
      },
    );
  }

  Widget buildActionCard(BuildContext context, MenuAction action) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => openAction(context, action),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.035),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    action.icon,
                    color: const Color(0xFF2563EB),
                    size: 25,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: muted.withOpacity(0.65),
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              action.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: navy,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            Expanded(
              child: Text(
                actionDescription(action),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: muted,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                actionMeta(action),
                style: const TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildActionGrid(BuildContext context, List<MenuAction> list) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        int crossAxisCount = 2;
        if (width > 1120) {
          crossAxisCount = 4;
        } else if (width > 760) {
          crossAxisCount = 3;
        }

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: width > 760 ? 1.6 : 1.2,
          children: list.map((e) => buildActionCard(context, e)).toList(),
        );
      },
    );
  }

  Widget buildTaskPanel(DashboardSummary summary) {
    List<DashboardStat> taskStats = summary.stats;

    if (info.role == 'admin') {
      taskStats = summary.stats.where((s) {
        return s.title.contains('chờ') ||
            s.title.contains('chưa') ||
            s.title.contains('xử lý') ||
            s.title.contains('Phản hồi');
      }).toList();
    }

    if (taskStats.isEmpty) {
      taskStats = summary.stats.take(4).toList();
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sectionHeader(
            'Việc cần chú ý',
            'Các mục nghiệp vụ đang cần theo dõi',
            Icons.task_alt_rounded,
          ),
          const SizedBox(height: 8),
          ...taskStats.map((s) => taskRow(s)).toList(),
        ],
      ),
    );
  }

  Widget taskRow(DashboardStat stat) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: stat.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(stat.icon, color: stat.color, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              stat.title,
              style: const TextStyle(
                color: navy,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: stat.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              stat.value,
              style: TextStyle(
                color: stat.color,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget sectionHeader(String title, String sub, IconData icon) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB).withOpacity(0.1),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: const Color(0xFF2563EB), size: 21),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: navy,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sub,
                style: const TextStyle(
                  color: muted,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget loadingSkeleton() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 2.35,
      children: List.generate(
        6,
        (index) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
        ),
      ),
    );
  }

  Widget buildHomeBody(BuildContext context, List<MenuAction> list) {
    return FutureBuilder<DashboardSummary>(
      future: loadDashboardSummary(),
      builder: (context, snapshot) {
        final summary = snapshot.data;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 26),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildHero(context, summary),
                  const SizedBox(height: 22),
                  sectionHeader(
                    'Tổng quan hệ thống',
                    'Số liệu được tổng hợp trực tiếp từ Firestore',
                    Icons.dashboard_rounded,
                  ),
                  const SizedBox(height: 14),
                  if (summary == null)
                    loadingSkeleton()
                  else
                    buildStatGrid(summary.stats),
                  const SizedBox(height: 22),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth > 980;

                      final functions = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          sectionHeader(
                            'Chức năng nghiệp vụ',
                            'Mở nhanh các phân hệ theo vai trò đăng nhập',
                            Icons.apps_rounded,
                          ),
                          const SizedBox(height: 14),
                          buildActionGrid(context, list),
                        ],
                      );

                      if (!wide || summary == null) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (summary != null) ...[
                              buildTaskPanel(summary),
                              const SizedBox(height: 22),
                            ],
                            functions,
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 7, child: functions),
                          const SizedBox(width: 18),
                          Expanded(flex: 3, child: buildTaskPanel(summary)),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = actions();

    return Scaffold(
      backgroundColor: bg,
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
                decoration: const BoxDecoration(
                  color: Color(0xFF0F172A),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      roleName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      info.email,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.72),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (info.role == 'student') ...[
                      const SizedBox(height: 6),
                      Text(
                        'Mã học sinh: ${info.studentId.isEmpty ? 'HS001' : info.studentId}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.72),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              ListTile(
                leading:
                    const Icon(Icons.home_rounded, color: Color(0xFF2563EB)),
                title: const Text('Trang chủ'),
                onTap: () => Navigator.pop(context),
              ),
              const Divider(height: 1),
              ...list.map((e) => drawerItem(context, e)).toList(),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: navy,
        surfaceTintColor: Colors.white,
        title: Text(
          roleTitle,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: navy,
          ),
        ),
        actions: [
          if (MediaQuery.of(context).size.width > 650)
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  info.email,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF334155),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          const SizedBox(width: 10),
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => logout(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: buildHomeBody(context, list),
    );
  }
}
class LeaveRequestPage extends StatefulWidget {
  final RoleInfo info;

  const LeaveRequestPage({
    Key? key,
    required this.info,
  }) : super(key: key);

  @override
  State<LeaveRequestPage> createState() => _LeaveRequestPageState();
}

class _LeaveRequestPageState extends State<LeaveRequestPage> {
  final db = FirebaseFirestore.instance;

  final TextEditingController reasonController = TextEditingController();
  final TextEditingController fromDateController = TextEditingController();
  final TextEditingController toDateController = TextEditingController();
  final TextEditingController studentNameController = TextEditingController();
  final TextEditingController classNameController = TextEditingController();

  bool loadingProfile = false;

  String get studentId {
    if (widget.info.studentId.isNotEmpty) return widget.info.studentId;
    return 'HS001';
  }

  bool get isStudent => widget.info.role == 'student';
  bool get isTeacher => widget.info.role == 'teacher';
  bool get isAdmin => widget.info.role == 'admin';

  @override
  void initState() {
    super.initState();

    if (isStudent) {
      fromDateController.text = formatDate(DateTime.now());
      toDateController.text = formatDate(DateTime.now());
      loadStudentInfo();
    }
  }

  @override
  void dispose() {
    reasonController.dispose();
    fromDateController.dispose();
    toDateController.dispose();
    studentNameController.dispose();
    classNameController.dispose();
    super.dispose();
  }

  String formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  DateTime parseDate(String value) {
    try {
      return DateTime.parse(value);
    } catch (_) {
      return DateTime.now();
    }
  }

  List<String> getDatesBetween(String fromDate, String toDate) {
    final start = DateTime.parse(fromDate);
    final end = DateTime.parse(toDate);

    final dates = <String>[];
    var current = start;

    while (!current.isAfter(end)) {
      dates.add(formatDate(current));
      current = current.add(const Duration(days: 1));
    }

    return dates;
  }

  Future<void> loadStudentInfo() async {
    setState(() {
      loadingProfile = true;
    });

    try {
      final studentDoc = await db.collection('students').doc(studentId).get();

      if (studentDoc.exists && studentDoc.data() != null) {
        final data = studentDoc.data()!;
        studentNameController.text = data['name']?.toString() ?? '';
        classNameController.text = data['className']?.toString() ?? '';
      } else {
        final profileQuery = await db
            .collection('profiles')
            .where('studentId', isEqualTo: studentId)
            .limit(1)
            .get();

        if (profileQuery.docs.isNotEmpty) {
          final data = profileQuery.docs.first.data();
          studentNameController.text = data['name']?.toString() ?? '';
          classNameController.text = data['className']?.toString() ?? '';
        }
      }

      if (studentNameController.text.trim().isEmpty) {
        studentNameController.text = widget.info.email;
      }
    } catch (_) {
      studentNameController.text = widget.info.email;
    }

    if (mounted) {
      setState(() {
        loadingProfile = false;
      });
    }
  }

  String pageTitle() {
    if (isStudent) return 'Xin nghỉ học';
    if (isTeacher) return 'Duyệt đơn xin nghỉ';
    return 'Quản lý đơn xin nghỉ';
  }

  Stream<QuerySnapshot> leaveStream() {
    Query q = db.collection('leave_requests');

    if (isStudent) {
      q = q.where('studentId', isEqualTo: studentId);
    }

    return q.snapshots();
  }

  String statusText(String status) {
    switch (status) {
      case 'pending':
        return 'Chờ duyệt';
      case 'approved':
        return 'Đã duyệt';
      case 'rejected':
        return 'Từ chối';
      default:
        return status;
    }
  }

  Color statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  int createdAtMillis(Map<String, dynamic> data) {
    final createdAt = data['createdAt'];

    if (createdAt is Timestamp) {
      return createdAt.millisecondsSinceEpoch;
    }

    return 0;
  }

  Future<void> pickDate(TextEditingController controller) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: parseDate(controller.text),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      controller.text = formatDate(picked);
    }
  }

  void clearForm() {
    reasonController.clear();
    fromDateController.text = formatDate(DateTime.now());
    toDateController.text = formatDate(DateTime.now());
  }

  Future<void> submitLeaveRequest() async {
    final reason = reasonController.text.trim();
    final fromDate = fromDateController.text.trim();
    final toDate = toDateController.text.trim();
    final studentName = studentNameController.text.trim();
    final className = classNameController.text.trim();

    if (studentName.isEmpty) {
      showMessage('Không tìm thấy tên học sinh trong hồ sơ');
      return;
    }

    if (className.isEmpty) {
      showMessage('Không tìm thấy lớp của học sinh trong hồ sơ');
      return;
    }

    if (fromDate.isEmpty || toDate.isEmpty) {
      showMessage('Vui lòng chọn ngày nghỉ');
      return;
    }

    if (reason.isEmpty) {
      showMessage('Vui lòng nhập lý do xin nghỉ');
      return;
    }

    final from = parseDate(fromDate);
    final to = parseDate(toDate);

    if (to.isBefore(from)) {
      showMessage('Ngày kết thúc không được nhỏ hơn ngày bắt đầu');
      return;
    }

    await db.collection('leave_requests').add({
      'studentId': studentId,
      'studentName': studentName,
      'className': className,
      'fromDate': fromDate,
      'toDate': toDate,
      'reason': reason,
      'status': 'pending',
      'teacherNote': '',
      'createdBy': widget.info.email,
      'createdAt': FieldValue.serverTimestamp(),
      'approvedBy': '',
      'approvedAt': null,
    });

    clearForm();

    if (mounted) {
      Navigator.pop(context);
      showMessage('Đã gửi đơn xin nghỉ');
    }
  }

  void openCreateLeaveDialog() {
    if (!isStudent) return;

    if (studentNameController.text.trim().isEmpty ||
        classNameController.text.trim().isEmpty) {
      showMessage(
        'Chưa tải được thông tin học sinh. Vui lòng kiểm tra hồ sơ học sinh.',
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Tạo đơn xin nghỉ học'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                readOnlyInfoField(
                  controller: studentNameController,
                  label: 'Tên học sinh',
                  icon: Icons.person,
                ),
                const SizedBox(height: 10),
                readOnlyInfoField(
                  controller: classNameController,
                  label: 'Lớp',
                  icon: Icons.class_,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: fromDateController,
                  readOnly: true,
                  onTap: () => pickDate(fromDateController),
                  decoration: const InputDecoration(
                    labelText: 'Nghỉ từ ngày',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.date_range),
                    suffixIcon: Icon(Icons.calendar_month),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: toDateController,
                  readOnly: true,
                  onTap: () => pickDate(toDateController),
                  decoration: const InputDecoration(
                    labelText: 'Nghỉ đến ngày',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.date_range),
                    suffixIcon: Icon(Icons.calendar_month),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: reasonController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Lý do xin nghỉ',
                    hintText: 'Ví dụ: Em bị ốm, gia đình có việc...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.edit_note),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.withOpacity(0.25)),
                  ),
                  child: const Text(
                    'Lưu ý: Tên học sinh và lớp được lấy từ hồ sơ, học sinh không được tự sửa trong đơn xin nghỉ.',
                    style: TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                clearForm();
                Navigator.pop(context);
              },
              child: const Text('Hủy'),
            ),
            ElevatedButton.icon(
              onPressed: submitLeaveRequest,
              icon: const Icon(Icons.send),
              label: const Text('Gửi đơn'),
            ),
          ],
        );
      },
    );
  }

  Widget readOnlyInfoField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      readOnly: true,
      enableInteractiveSelection: false,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.grey.withOpacity(0.12),
      ),
    );
  }

  Future<void> updateRequestStatus({
    required String docId,
    required String status,
    required String note,
    required Map<String, dynamic> leaveData,
  }) async {
    final batch = db.batch();

    final leaveRef = db.collection('leave_requests').doc(docId);

    batch.update(leaveRef, {
      'status': status,
      'teacherNote': note,
      'approvedBy': widget.info.email,
      'approvedAt': FieldValue.serverTimestamp(),
    });

    if (status == 'approved') {
      final studentIdValue = leaveData['studentId']?.toString() ?? '';
      final studentName = leaveData['studentName']?.toString() ?? '';
      final className = leaveData['className']?.toString() ?? '';
      final fromDate = leaveData['fromDate']?.toString() ?? '';
      final toDate = leaveData['toDate']?.toString() ?? '';
      final reason = leaveData['reason']?.toString() ?? '';

      if (studentIdValue.isNotEmpty &&
          fromDate.isNotEmpty &&
          toDate.isNotEmpty) {
        final dates = getDatesBetween(fromDate, toDate);

        for (final date in dates) {
          final attendanceId = '${docId}_${studentIdValue}_$date';
          final attendanceRef = db.collection('attendance').doc(attendanceId);

          batch.set(
            attendanceRef,
            {
              'id': attendanceId,
              'studentId': studentIdValue,
              'studentName': studentName,
              'className': className,
              'date': date,
              'status': 'Nghỉ có phép',
              'reason': reason,
              'leaveRequestId': docId,
              'source': 'leave_request',
              'createdBy': widget.info.email,
              'createdAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        }
      }
    }

    await batch.commit();

    if (status == 'approved') {
      showMessage('Đã duyệt đơn và cập nhật điểm danh nghỉ có phép');
    } else {
      showMessage('Đã từ chối đơn');
    }
  }

  void openApproveDialog({
    required String docId,
    required String status,
    required Map<String, dynamic> leaveData,
  }) {
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title:
              Text(status == 'approved' ? 'Duyệt đơn nghỉ' : 'Từ chối đơn nghỉ'),
          content: TextField(
            controller: noteController,
            minLines: 3,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: status == 'approved'
                  ? 'Ghi chú của giáo viên / admin'
                  : 'Lý do từ chối',
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                final note = noteController.text.trim();

                await updateRequestStatus(
                  docId: docId,
                  status: status,
                  note: note,
                  leaveData: leaveData,
                );

                if (mounted) {
                  Navigator.pop(context);
                }
              },
              child: Text(status == 'approved' ? 'Duyệt' : 'Từ chối'),
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteLeaveRequest(String docId) async {
    if (!isAdmin) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Xóa đơn xin nghỉ'),
          content: const Text('Bạn có chắc muốn xóa đơn này không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await db.collection('leave_requests').doc(docId).delete();
      showMessage('Đã xóa đơn');
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget buildCreateCard() {
    if (!isStudent) return const SizedBox.shrink();

    final studentName = studentNameController.text.trim();
    final className = classNameController.text.trim();

    return Card(
      elevation: 3,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(Icons.edit_calendar, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tạo đơn xin nghỉ học',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  if (loadingProfile)
                    const Text(
                      'Đang tải thông tin học sinh...',
                      style: TextStyle(color: Colors.black54),
                    )
                  else ...[
                    Text(
                      'Mã học sinh: $studentId',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    if (studentName.isNotEmpty)
                      Text(
                        'Họ tên: $studentName',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    if (className.isNotEmpty)
                      Text(
                        'Lớp: $className',
                        style: const TextStyle(color: Colors.black54),
                      ),
                  ],
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: loadingProfile ? null : openCreateLeaveDialog,
              icon: const Icon(Icons.add),
              label: const Text('Tạo đơn'),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildLeaveCard(DocumentSnapshot doc, int index) {
    final data = doc.data() as Map<String, dynamic>;
    final status = data['status']?.toString() ?? 'pending';

    final studentName = data['studentName']?.toString() ?? '';
    final sid = data['studentId']?.toString() ?? '';
    final className = data['className']?.toString() ?? '';
    final fromDate = data['fromDate']?.toString() ?? '';
    final toDate = data['toDate']?.toString() ?? '';
    final reason = data['reason']?.toString() ?? '';
    final teacherNote = data['teacherNote']?.toString() ?? '';
    final approvedBy = data['approvedBy']?.toString() ?? '';

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: statusColor(status),
          child: Text(
            '${index + 1}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          studentName.isNotEmpty ? studentName : sid,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              Chip(
                label: Text(statusText(status)),
                backgroundColor: statusColor(status).withOpacity(0.15),
                labelStyle: TextStyle(
                  color: statusColor(status),
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (className.isNotEmpty)
                Chip(
                  label: Text('Lớp: $className'),
                  backgroundColor: Colors.blue.withOpacity(0.12),
                ),
              Chip(
                label: Text('$fromDate → $toDate'),
                backgroundColor: Colors.grey.withOpacity(0.15),
              ),
            ],
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const Divider(),
          infoRow('Mã học sinh', sid),
          infoRow('Tên học sinh', studentName),
          infoRow('Lớp', className),
          infoRow('Thời gian nghỉ', '$fromDate đến $toDate'),
          infoRow('Lý do', reason),
          if (teacherNote.isNotEmpty) infoRow('Ghi chú xử lý', teacherNote),
          if (approvedBy.isNotEmpty) infoRow('Người xử lý', approvedBy),
          const SizedBox(height: 12),
          if ((isTeacher || isAdmin) && status == 'pending')
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => openApproveDialog(
                      docId: doc.id,
                      status: 'approved',
                      leaveData: data,
                    ),
                    icon: const Icon(Icons.check),
                    label: const Text('Duyệt'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => openApproveDialog(
                      docId: doc.id,
                      status: 'rejected',
                      leaveData: data,
                    ),
                    icon: const Icon(Icons.close),
                    label: const Text('Từ chối'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          if (isAdmin) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => deleteLeaveRequest(doc.id),
                icon: const Icon(Icons.delete, color: Colors.red),
                label: const Text(
                  'Xóa đơn',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget infoRow(String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget buildSummary(List<DocumentSnapshot> docs) {
    final pending = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['status'] == 'pending';
    }).length;

    final approved = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['status'] == 'approved';
    }).length;

    final rejected = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['status'] == 'rejected';
    }).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          summaryBox('Tổng', docs.length.toString(), Colors.blue),
          const SizedBox(width: 8),
          summaryBox('Chờ duyệt', pending.toString(), Colors.orange),
          const SizedBox(width: 8),
          summaryBox('Đã duyệt', approved.toString(), Colors.green),
          const SizedBox(width: 8),
          summaryBox('Từ chối', rejected.toString(), Colors.red),
        ],
      ),
    );
  }

  Widget summaryBox(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(pageTitle()),
        backgroundColor: Colors.blue,
      ),
      floatingActionButton: isStudent
          ? FloatingActionButton.extended(
              onPressed: loadingProfile ? null : openCreateLeaveDialog,
              icon: const Icon(Icons.add),
              label: const Text('Tạo đơn'),
            )
          : null,
      body: StreamBuilder<QuerySnapshot>(
        stream: leaveStream(),
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(child: Text('Lỗi tải danh sách đơn xin nghỉ'));
          }

          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs.toList();

          docs.sort((a, b) {
            final da = a.data() as Map<String, dynamic>;
            final dbb = b.data() as Map<String, dynamic>;
            return createdAtMillis(dbb).compareTo(createdAtMillis(da));
          });

          return Column(
            children: [
              buildCreateCard(),
              buildSummary(docs),
              Expanded(
                child: docs.isEmpty
                    ? Center(
                        child: Text(
                          isStudent
                              ? 'Bạn chưa có đơn xin nghỉ nào'
                              : 'Chưa có đơn xin nghỉ nào',
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: docs.length,
                        itemBuilder: (context, i) {
                          return buildLeaveCard(docs[i], i);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class CrudPage extends StatefulWidget {
  final String title;
  final String collection;
  final List<String> fields;
  final bool canEdit;
  final String? filterField;
  final String? filterValue;

  const CrudPage({
    Key? key,
    required this.title,
    required this.collection,
    required this.fields,
    required this.canEdit,
    this.filterField,
    this.filterValue,
  }) : super(key: key);

  @override
  State<CrudPage> createState() => _CrudPageState();
}

class _CrudPageState extends State<CrudPage> {
  final db = FirebaseFirestore.instance;

  String label(String f) {
    switch (f) {
      case 'id':
        return 'Mã';
      case 'name':
        return 'Tên';
      case 'className':
        return 'Lớp';
      case 'phone':
        return 'Số điện thoại';
      case 'email':
        return 'Email';
      case 'subject':
        return 'Môn học';
      case 'teacher':
        return 'Giáo viên';
      case 'room':
        return 'Phòng';
      case 'studentId':
        return 'Mã học sinh';
      case 'studentName':
        return 'Tên học sinh';
      case 'date':
        return 'Ngày';
      case 'status':
        return 'Trạng thái';
      case 'score':
        return 'Điểm';
      case 'amount':
        return 'Số tiền';
      case 'gender':
        return 'Giới tính';
      case 'address':
        return 'Địa chỉ';
      case 'day':
        return 'Ngày học';
      case 'time':
        return 'Thời gian';
      case 'title':
        return 'Tiêu đề';
      case 'type':
        return 'Loại';
      case 'route':
        return 'Tuyến xe';
      case 'driver':
        return 'Tài xế';
      case 'content':
        return 'Nội dung';
      case 'fromDate':
        return 'Từ ngày';
      case 'toDate':
        return 'Đến ngày';
      case 'reason':
        return 'Lý do';
      case 'teacherNote':
        return 'Ghi chú xử lý';
      case 'approvedBy':
        return 'Người xử lý';
      case 'approvedAt':
        return 'Ngày xử lý';
      case 'createdAt':
        return 'Ngày tạo';
      case 'leaveRequestId':
        return 'Mã đơn nghỉ';
      case 'source':
        return 'Nguồn';
      case 'createdBy':
        return 'Người tạo';
      default:
        return f;
    }
  }

  Query query() {
    Query q = db.collection(widget.collection);

    if (widget.filterField != null &&
        widget.filterValue != null &&
        widget.filterValue!.isNotEmpty) {
      q = q.where(widget.filterField!, isEqualTo: widget.filterValue);
    }

    return q;
  }

  String subtitle(Map<String, dynamic> data) {
    return widget.fields
        .where((f) => f != 'id' && data[f] != null)
        .map((f) => '${label(f)}: ${data[f]}')
        .join(' | ');
  }

  void openForm({DocumentSnapshot? doc}) {
    if (!widget.canEdit) return;

    final old =
        doc == null ? <String, dynamic>{} : doc.data() as Map<String, dynamic>;
    final ctrls = <String, TextEditingController>{};

    for (final f in widget.fields) {
      ctrls[f] = TextEditingController(text: old[f]?.toString() ?? '');
    }

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(doc == null ? 'Thêm dữ liệu' : 'Sửa dữ liệu'),
          content: SingleChildScrollView(
            child: Column(
              children: widget.fields.map((f) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextField(
                    controller: ctrls[f],
                    decoration: InputDecoration(
                      labelText: label(f),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                final data = <String, dynamic>{};

                for (final f in widget.fields) {
                  data[f] = ctrls[f]!.text.trim();
                }

                if (doc == null) {
                  final id = data['id']?.toString() ?? '';
                  if (id.isNotEmpty) {
                    await db.collection(widget.collection).doc(id).set(data);
                  } else {
                    await db.collection(widget.collection).add(data);
                  }
                } else {
                  await db.collection(widget.collection).doc(doc.id).update(data);
                }

                Navigator.pop(context);
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteDoc(String id) async {
    if (!widget.canEdit) return;
    await db.collection(widget.collection).doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.blue,
      ),
      floatingActionButton: widget.canEdit
          ? FloatingActionButton.extended(
              onPressed: () => openForm(),
              icon: const Icon(Icons.add),
              label: const Text('Thêm'),
            )
          : null,
      body: StreamBuilder<QuerySnapshot>(
        stream: query().snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(child: Text('Lỗi tải dữ liệu'));
          }

          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('Không có dữ liệu phù hợp'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final doc = docs[i];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text('${i + 1}')),
                  title: Text(
                    data['name']?.toString() ??
                        data['studentName']?.toString() ??
                        data['title']?.toString() ??
                        data['id']?.toString() ??
                        doc.id,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(subtitle(data)),
                  trailing: widget.canEdit
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.orange),
                              onPressed: () => openForm(doc: doc),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => deleteDoc(doc.id),
                            ),
                          ],
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}