import 'package:flutter/material.dart';

class MainDrawer extends StatefulWidget {
  @override
  _MainDrawerState createState() => _MainDrawerState();
}

class _MainDrawerState extends State<MainDrawer> {
  void openPage(String title, List<String> data) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminDemoPage(title: title, data: data),
      ),
    );
  }

  void comingSoon(String title) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$title đang phát triển')),
    );
  }

  Widget item(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title, style: TextStyle(fontSize: 16)),
      onTap: onTap,
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
                  Text(
                    'ADMIN',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text('Hệ thống quản lý trường học'),
                ],
              ),
            ),

            item('Trang chủ', Icons.home, () => Navigator.pop(context)),

            Divider(),

            item('Quản lý học sinh', Icons.people, () {
              openPage('Quản lý học sinh', [
                'HS001 - Nguyễn Văn An - Lớp 12A1',
                'HS002 - Trần Thị Bình - Lớp 12A1',
                'HS003 - Lê Văn Cường - Lớp 12A2',
              ]);
            }),

            item('Quản lý giáo viên', Icons.school, () {
              openPage('Quản lý giáo viên', [
                'GV001 - Nguyễn Thị Lan - Toán',
                'GV002 - Phạm Văn Minh - Tin học',
                'GV003 - Hoàng Thị Mai - Tiếng Anh',
              ]);
            }),

            item('Quản lý môn học', Icons.menu_book, () {
              openPage('Quản lý môn học', [
                'MH001 - Toán - Phòng P101',
                'MH002 - Tin học - Phòng P202',
                'MH003 - Tiếng Anh - Phòng P303',
              ]);
            }),

            item('Điểm danh', Icons.checklist, () {
              openPage('Điểm danh', [
                'HS001 - Có mặt',
                'HS002 - Có mặt',
                'HS003 - Vắng',
              ]);
            }),

            item('Kết quả thi', Icons.grade, () {
              openPage('Kết quả thi', [
                'Nguyễn Văn An - Toán - 8.5',
                'Trần Thị Bình - Tin học - 9.0',
                'Lê Văn Cường - Tiếng Anh - 7.5',
              ]);
            }),

            Divider(),

            item('Hồ sơ', Icons.person, () => comingSoon('Hồ sơ')),
            item('Học phí', Icons.payments, () => comingSoon('Học phí')),
            item('Thời khóa biểu', Icons.calendar_month, () => comingSoon('Thời khóa biểu')),
            item('Thư viện', Icons.local_library, () => comingSoon('Thư viện')),
            item('Theo dõi xe', Icons.directions_bus, () => comingSoon('Theo dõi xe')),
            item('Thông báo', Icons.notifications, () => comingSoon('Thông báo')),
          ],
        ),
      ),
    );
  }
}

class AdminDemoPage extends StatelessWidget {
  final String title;
  final List<String> data;

  const AdminDemoPage({
    Key? key,
    required this.title,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.blue,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: data.length,
        itemBuilder: (context, index) {
          return Card(
            elevation: 3,
            margin: EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(child: Text('${index + 1}')),
              title: Text(data[index]),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
            ),
          );
        },
      ),
    );
  }
}
