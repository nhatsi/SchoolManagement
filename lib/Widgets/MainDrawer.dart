import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MainDrawer extends StatefulWidget {
  @override
  _MainDrawerState createState() => _MainDrawerState();
}

class _MainDrawerState extends State<MainDrawer> {
  Widget item(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }

  void openCrud(String title, String collectionName, List<String> fields) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminCrudPage(
          title: title,
          collectionName: collectionName,
          fields: fields,
        ),
      ),
    );
  }

  void comingSoon(String title) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$title đang phát triển')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            DrawerHeader(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.admin_panel_settings, size: 45, color: Colors.blue),
                  SizedBox(height: 10),
                  Text('ADMIN', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text('Quản lý trường học'),
                ],
              ),
            ),

            item('Trang chủ', Icons.home, () => Navigator.pop(context)),

            Divider(),

            item('Quản lý học sinh', Icons.people, () {
              openCrud('Quản lý học sinh', 'students', [
                'id',
                'name',
                'className',
                'phone',
                'email',
              ]);
            }),

            item('Quản lý giáo viên', Icons.school, () {
              openCrud('Quản lý giáo viên', 'teachers', [
                'id',
                'name',
                'subject',
                'phone',
              ]);
            }),

            item('Quản lý môn học', Icons.menu_book, () {
              openCrud('Quản lý môn học', 'subjects', [
                'id',
                'name',
                'teacher',
                'room',
              ]);
            }),

            item('Điểm danh', Icons.checklist, () {
              openCrud('Điểm danh', 'attendance', [
                'id',
                'studentId',
                'date',
                'status',
              ]);
            }),

            item('Kết quả thi', Icons.grade, () {
              openCrud('Kết quả thi', 'exams', [
                'id',
                'studentId',
                'subject',
                'score',
              ]);
            }),

            Divider(),

            item('Hồ sơ', Icons.person, () { openCrud('Hồ sơ', 'profiles', ['id','name','className','gender','address']); }),
            item('Học phí', Icons.payments, () { openCrud('Học phí', 'fees', ['id','studentId','amount','status']); }),
            item('Thời khóa biểu', Icons.calendar_month, () { openCrud('Thời khóa biểu', 'timetables', ['id','className','day','subject','time']); }),
            item('Thư viện', Icons.local_library, () { openCrud('Thư viện', 'library', ['id','title','type','status']); }),
            item('Theo dõi xe', Icons.directions_bus, () { openCrud('Theo dõi xe', 'buses', ['id','route','driver','phone']); }),
            item('Thông báo', Icons.notifications, () { openCrud('Thông báo', 'notifications', ['id','title','content']); }),
          ],
        ),
      ),
    );
  }
}

class AdminCrudPage extends StatefulWidget {
  final String title;
  final String collectionName;
  final List<String> fields;

  const AdminCrudPage({
    Key? key,
    required this.title,
    required this.collectionName,
    required this.fields,
  }) : super(key: key);

  @override
  State<AdminCrudPage> createState() => _AdminCrudPageState();
}

class _AdminCrudPageState extends State<AdminCrudPage> {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  String label(String field) {
    switch (field) {
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
      case 'date':
        return 'Ngày';
      case 'status':
        return 'Trạng thái';
      case 'score':
        return 'Điểm';
      default:
        return field;
    }
  }

  void openForm({DocumentSnapshot? doc}) {
    final Map<String, dynamic> oldData =
        doc == null ? {} : doc.data() as Map<String, dynamic>;

    final controllers = <String, TextEditingController>{};

    for (final field in widget.fields) {
      controllers[field] = TextEditingController(
        text: oldData[field]?.toString() ?? '',
      );
    }

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(doc == null ? 'Thêm dữ liệu' : 'Sửa dữ liệu'),
          content: SingleChildScrollView(
            child: Column(
              children: widget.fields.map((field) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: TextField(
                    controller: controllers[field],
                    decoration: InputDecoration(
                      labelText: label(field),
                      border: OutlineInputBorder(),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                final data = <String, dynamic>{};

                for (final field in widget.fields) {
                  data[field] = controllers[field]!.text.trim();
                }

                if (doc == null) {
                  final customId = data['id']?.toString() ?? '';

                  if (customId.isNotEmpty) {
                    await db.collection(widget.collectionName).doc(customId).set(data);
                  } else {
                    await db.collection(widget.collectionName).add(data);
                  }
                } else {
                  await db.collection(widget.collectionName).doc(doc.id).update(data);
                }

                Navigator.pop(context);
              },
              child: Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteDoc(String id) async {
    await db.collection(widget.collectionName).doc(id).delete();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã xóa dữ liệu')),
    );
  }

  String buildSubtitle(Map<String, dynamic> data) {
    return widget.fields
        .where((f) => f != 'id' && data[f] != null)
        .map((f) => '${label(f)}: ${data[f]}')
        .join(' | ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.blue,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openForm(),
        icon: Icon(Icons.add),
        label: Text('Thêm'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: db.collection(widget.collectionName).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi tải dữ liệu'));
          }

          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Center(child: Text('Chưa có dữ liệu'));
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                elevation: 3,
                margin: EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text('${index + 1}'),
                  ),
                  title: Text(
                    data['name']?.toString() ??
                        data['id']?.toString() ??
                        doc.id,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(buildSubtitle(data)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.orange),
                        onPressed: () => openForm(doc: doc),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => deleteDoc(doc.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

