import 'package:flutter/material.dart';
import 'package:school_management/Widgets/MainDrawer.dart';

class MyHomePage extends StatefulWidget {
  final String title;

  const MyHomePage({Key? key, required this.title}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  void openCrud(String title, String collectionName, List<String> fields) {
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

  Widget adminCard(String title, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 45, color: Colors.blue),
              SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: MainDrawer(),
      appBar: AppBar(
        title: Text('Bảng điều khiển Admin'),
        backgroundColor: Colors.blue,
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: MediaQuery.of(context).size.width > 900 ? 3 : 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            adminCard('Quản lý học sinh', Icons.people, () {
              openCrud('Quản lý học sinh', 'students', ['id','name','className','phone','email']);
            }),
            adminCard('Quản lý giáo viên', Icons.school, () {
              openCrud('Quản lý giáo viên', 'teachers', ['id','name','subject','phone']);
            }),
            adminCard('Quản lý môn học', Icons.menu_book, () {
              openCrud('Quản lý môn học', 'subjects', ['id','name','teacher','room']);
            }),
            adminCard('Điểm danh', Icons.checklist, () {
              openCrud('Điểm danh', 'attendance', ['id','studentId','date','status']);
            }),
            adminCard('Kết quả thi', Icons.grade, () {
              openCrud('Kết quả thi', 'exams', ['id','studentId','subject','score']);
            }),
            adminCard('Hồ sơ', Icons.person, () {
              openCrud('Hồ sơ', 'profiles', ['id','name','className','gender','address']);
            }),
            adminCard('Học phí', Icons.payments, () {
              openCrud('Học phí', 'fees', ['id','studentId','amount','status']);
            }),
            adminCard('Thời khóa biểu', Icons.calendar_month, () {
              openCrud('Thời khóa biểu', 'timetables', ['id','className','day','subject','time']);
            }),
            adminCard('Thư viện', Icons.local_library, () {
              openCrud('Thư viện', 'library', ['id','title','type','status']);
            }),
            adminCard('Theo dõi xe', Icons.directions_bus, () {
              openCrud('Theo dõi xe', 'buses', ['id','route','driver','phone']);
            }),
            adminCard('Thông báo', Icons.notifications, () {
              openCrud('Thông báo', 'notifications', ['id','title','content']);
            }),
          ],
        ),
      ),
    );
  }
}

class Home extends MyHomePage {
  const Home({Key? key}) : super(key: key, title: '');
}
