import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_management/Screens/LoginPage.dart';

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

  MenuAction({
    required this.title,
    required this.icon,
    required this.collection,
    required this.fields,
    required this.canEdit,
    this.filterField,
    this.filterValue,
  });
}

class RoleHome extends StatelessWidget {
  final RoleInfo info;

  const RoleHome({
    Key? key,
    required this.info,
  }) : super(key: key);

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

  List<MenuAction> actions() {
    if (info.role == 'admin') {
      return [
        MenuAction(title: 'Quản lý học sinh', icon: Icons.people, collection: 'students', fields: ['id','name','className','phone','email'], canEdit: true),
        MenuAction(title: 'Quản lý giáo viên', icon: Icons.school, collection: 'teachers', fields: ['id','name','subject','phone'], canEdit: true),
        MenuAction(title: 'Quản lý môn học', icon: Icons.menu_book, collection: 'subjects', fields: ['id','name','teacher','room'], canEdit: true),
        MenuAction(title: 'Điểm danh', icon: Icons.checklist, collection: 'attendance', fields: ['id','studentId','date','status'], canEdit: true),
        MenuAction(title: 'Kết quả thi', icon: Icons.grade, collection: 'exams', fields: ['id','studentId','subject','score'], canEdit: true),
        MenuAction(title: 'Hồ sơ', icon: Icons.person, collection: 'profiles', fields: ['id','studentId','name','className','gender','address'], canEdit: true),
        MenuAction(title: 'Học phí', icon: Icons.payments, collection: 'fees', fields: ['id','studentId','amount','status'], canEdit: true),
        MenuAction(title: 'Thời khóa biểu', icon: Icons.calendar_month, collection: 'timetables', fields: ['id','className','day','subject','time'], canEdit: true),
        MenuAction(title: 'Thư viện', icon: Icons.local_library, collection: 'library', fields: ['id','title','type','status'], canEdit: true),
        MenuAction(title: 'Theo dõi xe', icon: Icons.directions_bus, collection: 'buses', fields: ['id','route','driver','phone'], canEdit: true),
        MenuAction(title: 'Thông báo', icon: Icons.notifications, collection: 'notifications', fields: ['id','title','content'], canEdit: true),
      ];
    }

    if (info.role == 'teacher') {
      return [
        MenuAction(title: 'Danh sách học sinh', icon: Icons.people, collection: 'students', fields: ['id','name','className','phone','email'], canEdit: false),
        MenuAction(title: 'Điểm danh', icon: Icons.checklist, collection: 'attendance', fields: ['id','studentId','date','status'], canEdit: true),
        MenuAction(title: 'Kết quả thi', icon: Icons.grade, collection: 'exams', fields: ['id','studentId','subject','score'], canEdit: true),
        MenuAction(title: 'Thời khóa biểu', icon: Icons.calendar_month, collection: 'timetables', fields: ['id','className','day','subject','time'], canEdit: false),
        MenuAction(title: 'Thông báo', icon: Icons.notifications, collection: 'notifications', fields: ['id','title','content'], canEdit: false),
      ];
    }

    final sid = info.studentId.isEmpty ? 'HS001' : info.studentId;

    return [
      MenuAction(title: 'Hồ sơ cá nhân', icon: Icons.person, collection: 'profiles', fields: ['id','studentId','name','className','gender','address'], canEdit: false, filterField: 'studentId', filterValue: sid),
      MenuAction(title: 'Điểm danh', icon: Icons.checklist, collection: 'attendance', fields: ['id','studentId','date','status'], canEdit: false, filterField: 'studentId', filterValue: sid),
      MenuAction(title: 'Kết quả thi', icon: Icons.grade, collection: 'exams', fields: ['id','studentId','subject','score'], canEdit: false, filterField: 'studentId', filterValue: sid),
      MenuAction(title: 'Học phí', icon: Icons.payments, collection: 'fees', fields: ['id','studentId','amount','status'], canEdit: false, filterField: 'studentId', filterValue: sid),
      MenuAction(title: 'Thời khóa biểu', icon: Icons.calendar_month, collection: 'timetables', fields: ['id','className','day','subject','time'], canEdit: false),
      MenuAction(title: 'Thư viện', icon: Icons.local_library, collection: 'library', fields: ['id','title','type','status'], canEdit: false),
      MenuAction(title: 'Thông báo', icon: Icons.notifications, collection: 'notifications', fields: ['id','title','content'], canEdit: false),
    ];
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

  Widget dashboardCard(BuildContext context, MenuAction action) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => openAction(context, action),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(action.icon, size: 45, color: Colors.blue),
            const SizedBox(height: 12),
            Text(
              action.title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget drawerItem(BuildContext context, MenuAction action) {
    return ListTile(
      leading: Icon(action.icon, color: Colors.blue),
      title: Text(action.title),
      onTap: () {
        Navigator.pop(context);
        openAction(context, action);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = actions();

    return Scaffold(
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                decoration: const BoxDecoration(color: Color(0xFFF7F7FB)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.school, size: 42, color: Colors.blue),
                    const SizedBox(height: 14),
                    Text(
                      roleName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      info.email,
                      style: const TextStyle(fontSize: 15),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (info.role == 'student') ...[
                      const SizedBox(height: 6),
                      Text(
                        'Mã học sinh: ${info.studentId.isEmpty ? 'HS001' : info.studentId}',
                        style: const TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                    ],
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home, color: Colors.blue),
                title: const Text('Trang chủ'),
                onTap: () => Navigator.pop(context),
              ),
              const Divider(),
              ...list.map((e) => drawerItem(context, e)).toList(),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        title: Text(roleTitle),
        backgroundColor: Colors.blue,
        actions: [
          Center(
            child: Text(
              info.email,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => logout(context),
          ),
        ],
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: MediaQuery.of(context).size.width > 900 ? 3 : 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: list.map((e) => dashboardCard(context, e)).toList(),
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
      case 'id': return 'Mã';
      case 'name': return 'Tên';
      case 'className': return 'Lớp';
      case 'phone': return 'Số điện thoại';
      case 'email': return 'Email';
      case 'subject': return 'Môn học';
      case 'teacher': return 'Giáo viên';
      case 'room': return 'Phòng';
      case 'studentId': return 'Mã học sinh';
      case 'date': return 'Ngày';
      case 'status': return 'Trạng thái';
      case 'score': return 'Điểm';
      case 'amount': return 'Số tiền';
      case 'gender': return 'Giới tính';
      case 'address': return 'Địa chỉ';
      case 'day': return 'Ngày học';
      case 'time': return 'Thời gian';
      case 'title': return 'Tiêu đề';
      case 'type': return 'Loại';
      case 'route': return 'Tuyến xe';
      case 'driver': return 'Tài xế';
      case 'content': return 'Nội dung';
      default: return f;
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

    final old = doc == null ? <String, dynamic>{} : doc.data() as Map<String, dynamic>;
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
