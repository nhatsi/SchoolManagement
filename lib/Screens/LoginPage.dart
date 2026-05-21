import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_management/Screens/RoleDashboard.dart';

class MyHomePage extends StatefulWidget {
  final String title;

  const MyHomePage({Key? key, required this.title}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;

  Future<void> login() async {
    final email = emailController.text.trim().toLowerCase();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showMsg('Vui lòng nhập email và mật khẩu');
      return;
    }

    setState(() => loading = true);

    try {
      await FirebaseAuth.instance.signOut();

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RoleRouter(forceEmail: email),
        ),
      );
    } on FirebaseAuthException catch (e) {
      showMsg(getLoginError(e.code));
    } catch (e) {
      showMsg('Đăng nhập thất bại');
    }

    if (mounted) setState(() => loading = false);
  }

  String getLoginError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Tài khoản không tồn tại';
      case 'wrong-password':
        return 'Sai mật khẩu';
      case 'invalid-email':
        return 'Email không hợp lệ';
      case 'invalid-credential':
        return 'Email hoặc mật khẩu không đúng';
      default:
        return 'Đăng nhập thất bại: $code';
    }
  }

  void showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<void> showForgotPasswordDialog() async {
    final resetEmailController = TextEditingController(
      text: emailController.text.trim().toLowerCase(),
    );

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Quên mật khẩu'),
          content: TextField(
            controller: resetEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Nhập email cần đặt lại mật khẩu',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.send),
              label: const Text('Gửi email'),
              onPressed: () async {
                final email = resetEmailController.text.trim().toLowerCase();

                if (email.isEmpty) {
                  showMsg('Vui lòng nhập email');
                  return;
                }

                try {
                  await FirebaseAuth.instance.sendPasswordResetEmail(
                    email: email,
                  );

                  if (!mounted) return;
                  Navigator.pop(context);

                  showMsg('Đã gửi email đặt lại mật khẩu tới $email');
                } on FirebaseAuthException catch (e) {
                  showMsg('Không gửi được email: ${e.code}');
                } catch (e) {
                  showMsg('Không gửi được email đặt lại mật khẩu');
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> showRegisterDialog() async {
    final regEmailController = TextEditingController();
    final regPasswordController = TextEditingController();
    final regNameController = TextEditingController();
    final regStudentIdController = TextEditingController();

    String selectedRole = 'student';

    await showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Tạo tài khoản'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: regEmailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: regPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Mật khẩu',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: regNameController,
                      decoration: const InputDecoration(
                        labelText: 'Họ tên',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Vai trò',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.admin_panel_settings),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'admin',
                          child: Text('Admin'),
                        ),
                        DropdownMenuItem(
                          value: 'teacher',
                          child: Text('Giáo viên'),
                        ),
                        DropdownMenuItem(
                          value: 'student',
                          child: Text('Học sinh'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedRole = value;
                          });
                        }
                      },
                    ),
                    if (selectedRole == 'student') ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: regStudentIdController,
                        decoration: const InputDecoration(
                          labelText: 'Mã học sinh, ví dụ HS001',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.badge),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.person_add),
                  label: const Text('Tạo'),
                  onPressed: () async {
                    final email = regEmailController.text.trim().toLowerCase();
                    final password = regPasswordController.text.trim();
                    final name = regNameController.text.trim();
                    final studentId = regStudentIdController.text.trim();

                    if (email.isEmpty || password.isEmpty || name.isEmpty) {
                      showMsg('Vui lòng nhập đủ email, mật khẩu, họ tên');
                      return;
                    }

                    if (selectedRole == 'student' && studentId.isEmpty) {
                      showMsg('Học sinh phải có mã học sinh');
                      return;
                    }

                    try {
                      final credential = await FirebaseAuth.instance
                          .createUserWithEmailAndPassword(
                        email: email,
                        password: password,
                      );

                      final uid = credential.user!.uid;

                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .set({
                        'uid': uid,
                        'email': email,
                        'name': name,
                        'role': selectedRole,
                        'studentId': selectedRole == 'student' ? studentId : '',
                      });

                      if (selectedRole == 'student') {
                        await FirebaseFirestore.instance
                            .collection('students')
                            .doc(studentId)
                            .set({
                          'id': studentId,
                          'name': name,
                          'email': email,
                          'className': '12A1',
                          'phone': '',
                        }, SetOptions(merge: true));

                        await FirebaseFirestore.instance
                            .collection('profiles')
                            .doc(studentId)
                            .set({
                          'id': studentId,
                          'studentId': studentId,
                          'name': name,
                          'email': email,
                          'className': '12A1',
                          'gender': '',
                          'address': '',
                        }, SetOptions(merge: true));
                      }

                      await FirebaseAuth.instance.signOut();

                      if (!mounted) return;
                      Navigator.pop(context);

                      showMsg('Tạo tài khoản thành công: $email');
                    } on FirebaseAuthException catch (e) {
                      showMsg('Không tạo được tài khoản: ${e.code}');
                    } catch (e) {
                      showMsg('Không tạo được tài khoản');
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget input({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType:
          label.toLowerCase().contains('email') ? TextInputType.emailAddress : null,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: Center(
        child: Container(
          width: 460,
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                blurRadius: 22,
                color: Colors.black12,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.school, size: 74, color: Colors.blue),
              const SizedBox(height: 12),
              const Text(
                'Đăng nhập hệ thống',
                style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 28),
              input(
                controller: emailController,
                label: 'Email',
                icon: Icons.email,
              ),
              const SizedBox(height: 16),
              input(
                controller: passwordController,
                label: 'Mật khẩu',
                icon: Icons.lock,
                obscure: true,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.login),
                  onPressed: loading ? null : login,
                  label: loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Đăng nhập'),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: showForgotPasswordDialog,
                      icon: const Icon(Icons.lock_reset),
                      label: const Text('Quên mật khẩu'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: showRegisterDialog,
                      icon: const Icon(Icons.person_add),
                      label: const Text('Tạo tài khoản'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
            ],
          ),
        ),
      ),
    );
  }
}

