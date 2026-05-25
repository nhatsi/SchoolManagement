import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HealthManagementPage extends StatefulWidget {
  final String role;
  final String email;
  final String studentId;

  const HealthManagementPage({
    Key? key,
    required this.role,
    required this.email,
    required this.studentId,
  }) : super(key: key);

  @override
  State<HealthManagementPage> createState() => _HealthManagementPageState();
}

class _HealthManagementPageState extends State<HealthManagementPage> {
  final db = FirebaseFirestore.instance;

  bool loadingProfile = false;
  String studentName = '';
  String studentClass = '';

  bool get isAdmin => widget.role == 'admin';
  bool get isTeacher => widget.role == 'teacher';
  bool get isStudent => widget.role == 'student';
  bool get canManage => isAdmin || isTeacher;

  String get currentStudentId {
    if (widget.studentId.trim().isNotEmpty) return widget.studentId.trim();
    return 'HS001';
  }

  @override
  void initState() {
    super.initState();

    if (isStudent) {
      loadStudentProfile();
    }
  }

  Future<void> loadStudentProfile() async {
    setState(() {
      loadingProfile = true;
    });

    try {
      final doc = await db.collection('students').doc(currentStudentId).get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        studentName = data['name']?.toString() ?? '';
        studentClass = data['className']?.toString() ?? '';
      } else {
        final snap = await db
            .collection('students')
            .where('studentId', isEqualTo: currentStudentId)
            .limit(1)
            .get();

        if (snap.docs.isNotEmpty) {
          final data = snap.docs.first.data();
          studentName = data['name']?.toString() ?? '';
          studentClass = data['className']?.toString() ?? '';
        }
      }
    } catch (_) {}

    if (studentName.trim().isEmpty) {
      studentName = widget.email;
    }

    if (studentClass.trim().isEmpty) {
      studentClass = '12A1';
    }

    if (mounted) {
      setState(() {
        loadingProfile = false;
      });
    }
  }

  String pageTitle() {
    if (isStudent) return 'Sức khỏe của tôi';
    if (isTeacher) return 'Theo dõi sức khỏe học sinh';
    return 'Hồ sơ sức khỏe học sinh';
  }

  void showMsg(String msg) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
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

  Stream<QuerySnapshot> healthRecordStream() {
    if (isStudent) {
      return db
          .collection('health_records')
          .where('studentId', isEqualTo: currentStudentId)
          .snapshots();
    }

    return db.collection('health_records').snapshots();
  }

  Stream<QuerySnapshot> medicalCheckStream() {
    if (isStudent) {
      return db
          .collection('medical_checks')
          .where('studentId', isEqualTo: currentStudentId)
          .snapshots();
    }

    return db.collection('medical_checks').snapshots();
  }

  Future<Map<String, String>?> findStudent(String studentId) async {
    try {
      final doc = await db.collection('students').doc(studentId).get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        return {
          'studentName': data['name']?.toString() ?? '',
          'className': data['className']?.toString() ?? '',
        };
      }

      final snap = await db
          .collection('students')
          .where('studentId', isEqualTo: studentId)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        final data = snap.docs.first.data();
        return {
          'studentName': data['name']?.toString() ?? '',
          'className': data['className']?.toString() ?? '',
        };
      }
    } catch (_) {}

    return null;
  }

  double parseNumber(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.')) ?? 0;
  }

  String bmiText(double heightCm, double weightKg) {
    if (heightCm <= 0 || weightKg <= 0) return 'Chưa đủ dữ liệu';

    final h = heightCm / 100;
    final bmi = weightKg / (h * h);

    String level = 'Bình thường';
    if (bmi < 18.5) {
      level = 'Thiếu cân';
    } else if (bmi >= 25) {
      level = 'Thừa cân';
    }

    return '${bmi.toStringAsFixed(1)} - $level';
  }

  Color bmiColor(double heightCm, double weightKg) {
    if (heightCm <= 0 || weightKg <= 0) return Colors.grey;

    final h = heightCm / 100;
    final bmi = weightKg / (h * h);

    if (bmi < 18.5) return Colors.orange;
    if (bmi >= 25) return Colors.red;
    return Colors.green;
  }

  void openHealthRecordDialog({DocumentSnapshot? doc}) {
    if (!canManage) return;

    final old = doc == null ? <String, dynamic>{} : doc.data() as Map<String, dynamic>;

    final studentIdController = TextEditingController(
      text: old['studentId']?.toString() ?? '',
    );
    final studentNameController = TextEditingController(
      text: old['studentName']?.toString() ?? '',
    );
    final classNameController = TextEditingController(
      text: old['className']?.toString() ?? '',
    );
    final heightController = TextEditingController(
      text: old['heightCm']?.toString() ?? '',
    );
    final weightController = TextEditingController(
      text: old['weightKg']?.toString() ?? '',
    );
    final bloodTypeController = TextEditingController(
      text: old['bloodType']?.toString() ?? '',
    );
    final allergyController = TextEditingController(
      text: old['allergies']?.toString() ?? '',
    );
    final chronicController = TextEditingController(
      text: old['chronicDiseases']?.toString() ?? '',
    );
    final emergencyController = TextEditingController(
      text: old['emergencyContact']?.toString() ?? '',
    );
    final noteController = TextEditingController(
      text: old['note']?.toString() ?? '',
    );

    bool loadingStudent = false;
    bool saving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> loadStudentInfo() async {
              final sid = studentIdController.text.trim();

              if (sid.isEmpty) {
                showMsg('Vui lòng nhập mã học sinh');
                return;
              }

              setDialogState(() {
                loadingStudent = true;
              });

              final student = await findStudent(sid);

              if (student == null) {
                showMsg('Không tìm thấy học sinh');
              } else {
                studentNameController.text = student['studentName'] ?? '';
                classNameController.text = student['className'] ?? '';
              }

              setDialogState(() {
                loadingStudent = false;
              });
            }

            Future<void> saveHealthRecord() async {
              final sid = studentIdController.text.trim();
              final studentNameValue = studentNameController.text.trim();
              final classNameValue = classNameController.text.trim();

              if (sid.isEmpty) {
                showMsg('Vui lòng nhập mã học sinh');
                return;
              }

              if (studentNameValue.isEmpty || classNameValue.isEmpty) {
                showMsg('Vui lòng bấm Tải học sinh trước khi lưu');
                return;
              }

              final height = parseNumber(heightController.text);
              final weight = parseNumber(weightController.text);

              if (height <= 0) {
                showMsg('Chiều cao không hợp lệ');
                return;
              }

              if (weight <= 0) {
                showMsg('Cân nặng không hợp lệ');
                return;
              }

              setDialogState(() {
                saving = true;
              });

              try {
                final id = sid;

                await db.collection('health_records').doc(id).set({
                  'id': id,
                  'studentId': sid,
                  'studentName': studentNameValue,
                  'className': classNameValue,
                  'heightCm': height,
                  'weightKg': weight,
                  'bloodType': bloodTypeController.text.trim(),
                  'allergies': allergyController.text.trim(),
                  'chronicDiseases': chronicController.text.trim(),
                  'emergencyContact': emergencyController.text.trim(),
                  'note': noteController.text.trim(),
                  'updatedBy': widget.email,
                  'updatedAt': FieldValue.serverTimestamp(),
                  'createdAt': old['createdAt'] ?? FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));

                if (!mounted) return;
                Navigator.pop(context);
                showMsg('Đã lưu hồ sơ sức khỏe');
              } catch (_) {
                showMsg('Không lưu được hồ sơ sức khỏe');
              }

              if (mounted) {
                setDialogState(() {
                  saving = false;
                });
              }
            }

            return AlertDialog(
              title: Text(doc == null ? 'Thêm hồ sơ sức khỏe' : 'Cập nhật hồ sơ sức khỏe'),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: studentIdController,
                              readOnly: doc != null,
                              decoration: const InputDecoration(
                                labelText: 'Mã học sinh',
                                hintText: 'Ví dụ: HS001',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.badge),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: doc != null || loadingStudent ? null : loadStudentInfo,
                            icon: loadingStudent
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.search),
                            label: Text(loadingStudent ? 'Tải...' : 'Tải'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: studentNameController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Tên học sinh',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: classNameController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Lớp',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.class_),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: heightController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Chiều cao cm',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.height),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: weightController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Cân nặng kg',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.monitor_weight),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: bloodTypeController,
                        decoration: const InputDecoration(
                          labelText: 'Nhóm máu',
                          hintText: 'Ví dụ: A, B, AB, O',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.bloodtype),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: allergyController,
                        decoration: const InputDecoration(
                          labelText: 'Dị ứng',
                          hintText: 'Ví dụ: Không, Hải sản, Phấn hoa...',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.warning_amber),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: chronicController,
                        decoration: const InputDecoration(
                          labelText: 'Bệnh nền',
                          hintText: 'Ví dụ: Không, Hen suyễn...',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.medical_information),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: emergencyController,
                        decoration: const InputDecoration(
                          labelText: 'Liên hệ khẩn cấp',
                          hintText: 'Tên phụ huynh - SĐT',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.contact_phone),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: noteController,
                        minLines: 3,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Ghi chú sức khỏe',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.note),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                ElevatedButton.icon(
                  onPressed: saving ? null : saveHealthRecord,
                  icon: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(saving ? 'Đang lưu...' : 'Lưu'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void openMedicalCheckDialog({
    DocumentSnapshot? healthDoc,
    DocumentSnapshot? checkDoc,
  }) {
    if (!canManage) return;

    final healthData =
        healthDoc == null ? <String, dynamic>{} : healthDoc.data() as Map<String, dynamic>;
    final old = checkDoc == null ? <String, dynamic>{} : checkDoc.data() as Map<String, dynamic>;

    final studentIdController = TextEditingController(
      text: old['studentId']?.toString() ?? healthData['studentId']?.toString() ?? '',
    );
    final studentNameController = TextEditingController(
      text: old['studentName']?.toString() ?? healthData['studentName']?.toString() ?? '',
    );
    final classNameController = TextEditingController(
      text: old['className']?.toString() ?? healthData['className']?.toString() ?? '',
    );
    final checkDateController = TextEditingController(
      text: old['checkDate']?.toString() ?? formatDate(DateTime.now()),
    );
    final heightController = TextEditingController(
      text: old['heightCm']?.toString() ?? healthData['heightCm']?.toString() ?? '',
    );
    final weightController = TextEditingController(
      text: old['weightKg']?.toString() ?? healthData['weightKg']?.toString() ?? '',
    );
    final visionController = TextEditingController(
      text: old['vision']?.toString() ?? '',
    );
    final dentalController = TextEditingController(
      text: old['dental']?.toString() ?? '',
    );
    final bloodPressureController = TextEditingController(
      text: old['bloodPressure']?.toString() ?? '',
    );
    final conclusionController = TextEditingController(
      text: old['conclusion']?.toString() ?? '',
    );
    final recommendationController = TextEditingController(
      text: old['recommendation']?.toString() ?? '',
    );

    bool loadingStudent = false;
    bool saving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> loadStudentInfo() async {
              final sid = studentIdController.text.trim();

              if (sid.isEmpty) {
                showMsg('Vui lòng nhập mã học sinh');
                return;
              }

              setDialogState(() {
                loadingStudent = true;
              });

              final student = await findStudent(sid);

              if (student == null) {
                showMsg('Không tìm thấy học sinh');
              } else {
                studentNameController.text = student['studentName'] ?? '';
                classNameController.text = student['className'] ?? '';
              }

              setDialogState(() {
                loadingStudent = false;
              });
            }

            Future<void> pickDate() async {
              final picked = await showDatePicker(
                context: context,
                initialDate: parseDate(checkDateController.text),
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );

              if (picked != null) {
                checkDateController.text = formatDate(picked);
              }
            }

            Future<void> saveCheck() async {
              final sid = studentIdController.text.trim();
              final studentNameValue = studentNameController.text.trim();
              final classNameValue = classNameController.text.trim();

              if (sid.isEmpty) {
                showMsg('Vui lòng nhập mã học sinh');
                return;
              }

              if (studentNameValue.isEmpty || classNameValue.isEmpty) {
                showMsg('Vui lòng bấm Tải học sinh trước khi lưu');
                return;
              }

              final height = parseNumber(heightController.text);
              final weight = parseNumber(weightController.text);

              if (height <= 0 || weight <= 0) {
                showMsg('Chiều cao / cân nặng không hợp lệ');
                return;
              }

              setDialogState(() {
                saving = true;
              });

              try {
                final ref = checkDoc == null
                    ? db.collection('medical_checks').doc()
                    : db.collection('medical_checks').doc(checkDoc.id);

                await ref.set({
                  'id': ref.id,
                  'studentId': sid,
                  'studentName': studentNameValue,
                  'className': classNameValue,
                  'checkDate': checkDateController.text.trim(),
                  'heightCm': height,
                  'weightKg': weight,
                  'bmi': bmiText(height, weight),
                  'vision': visionController.text.trim(),
                  'dental': dentalController.text.trim(),
                  'bloodPressure': bloodPressureController.text.trim(),
                  'conclusion': conclusionController.text.trim(),
                  'recommendation': recommendationController.text.trim(),
                  'createdBy': widget.email,
                  'createdAt': old['createdAt'] ?? FieldValue.serverTimestamp(),
                  'updatedAt': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));

                await db.collection('health_records').doc(sid).set({
                  'id': sid,
                  'studentId': sid,
                  'studentName': studentNameValue,
                  'className': classNameValue,
                  'heightCm': height,
                  'weightKg': weight,
                  'lastCheckDate': checkDateController.text.trim(),
                  'updatedBy': widget.email,
                  'updatedAt': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));

                if (!mounted) return;
                Navigator.pop(context);
                showMsg('Đã lưu lần khám sức khỏe');
              } catch (_) {
                showMsg('Không lưu được lần khám sức khỏe');
              }

              if (mounted) {
                setDialogState(() {
                  saving = false;
                });
              }
            }

            return AlertDialog(
              title: Text(checkDoc == null ? 'Thêm lần khám sức khỏe' : 'Sửa lần khám sức khỏe'),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: studentIdController,
                              readOnly: healthDoc != null || checkDoc != null,
                              decoration: const InputDecoration(
                                labelText: 'Mã học sinh',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.badge),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed:
                                healthDoc != null || checkDoc != null || loadingStudent
                                    ? null
                                    : loadStudentInfo,
                            icon: loadingStudent
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.search),
                            label: Text(loadingStudent ? 'Tải...' : 'Tải'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: studentNameController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Tên học sinh',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: classNameController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Lớp',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.class_),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: checkDateController,
                        readOnly: true,
                        onTap: pickDate,
                        decoration: const InputDecoration(
                          labelText: 'Ngày khám',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_month),
                          suffixIcon: Icon(Icons.date_range),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: heightController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Chiều cao cm',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.height),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: weightController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Cân nặng kg',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.monitor_weight),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: visionController,
                        decoration: const InputDecoration(
                          labelText: 'Thị lực',
                          hintText: 'Ví dụ: 10/10, cận nhẹ...',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.remove_red_eye),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: dentalController,
                        decoration: const InputDecoration(
                          labelText: 'Răng miệng',
                          hintText: 'Ví dụ: Tốt, sâu răng nhẹ...',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.health_and_safety),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: bloodPressureController,
                        decoration: const InputDecoration(
                          labelText: 'Huyết áp',
                          hintText: 'Ví dụ: 110/70',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.favorite),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: conclusionController,
                        decoration: const InputDecoration(
                          labelText: 'Kết luận',
                          hintText: 'Ví dụ: Sức khỏe tốt',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.fact_check),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: recommendationController,
                        minLines: 3,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Khuyến nghị',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.recommend),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                ElevatedButton.icon(
                  onPressed: saving ? null : saveCheck,
                  icon: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(saving ? 'Đang lưu...' : 'Lưu'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> deleteHealthRecord(DocumentSnapshot doc) async {
    if (!canManage) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Xóa hồ sơ sức khỏe'),
          content: const Text(
            'Bạn có chắc muốn xóa hồ sơ này không? Lịch sử khám sẽ không tự xóa.',
          ),
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
      await db.collection('health_records').doc(doc.id).delete();
      showMsg('Đã xóa hồ sơ sức khỏe');
    }
  }

  Future<void> deleteMedicalCheck(DocumentSnapshot doc) async {
    if (!canManage) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Xóa lần khám'),
          content: const Text('Bạn có chắc muốn xóa lần khám sức khỏe này không?'),
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
      await db.collection('medical_checks').doc(doc.id).delete();
      showMsg('Đã xóa lần khám');
    }
  }

  List<QueryDocumentSnapshot> checksForStudent(
    List<QueryDocumentSnapshot> checks,
    String studentId,
  ) {
    final list = checks.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['studentId']?.toString() == studentId;
    }).toList();

    list.sort((a, b) {
      final da = a.data() as Map<String, dynamic>;
      final dbb = b.data() as Map<String, dynamic>;

      return (dbb['checkDate']?.toString() ?? '')
          .compareTo(da['checkDate']?.toString() ?? '');
    });

    return list;
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
              style: TextStyle(color: color, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSummary({
    required List<QueryDocumentSnapshot> records,
    required List<QueryDocumentSnapshot> checks,
  }) {
    final allergyCount = records.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final allergy = data['allergies']?.toString().trim().toLowerCase() ?? '';
      return allergy.isNotEmpty && allergy != 'không' && allergy != 'khong';
    }).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Row(
        children: [
          summaryBox('Hồ sơ', records.length.toString(), Colors.blue),
          const SizedBox(width: 8),
          summaryBox('Lần khám', checks.length.toString(), Colors.green),
          const SizedBox(width: 8),
          summaryBox('Có dị ứng', allergyCount.toString(), Colors.orange),
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
            width: 125,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget buildCheckCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final checkDate = data['checkDate']?.toString() ?? '';
    final height = parseNumber(data['heightCm']?.toString() ?? '');
    final weight = parseNumber(data['weightKg']?.toString() ?? '');
    final bmi = data['bmi']?.toString() ?? bmiText(height, weight);
    final vision = data['vision']?.toString() ?? '';
    final dental = data['dental']?.toString() ?? '';
    final bloodPressure = data['bloodPressure']?.toString() ?? '';
    final conclusion = data['conclusion']?.toString() ?? '';
    final recommendation = data['recommendation']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.withOpacity(0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Colors.green,
                child: Icon(Icons.health_and_safety, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Khám ngày $checkDate',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              if (canManage) ...[
                IconButton(
                  onPressed: () => openMedicalCheckDialog(checkDoc: doc),
                  icon: const Icon(Icons.edit, color: Colors.orange),
                ),
                IconButton(
                  onPressed: () => deleteMedicalCheck(doc),
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
              ],
            ],
          ),
          infoRow('Chiều cao', '${height.toStringAsFixed(1)} cm'),
          infoRow('Cân nặng', '${weight.toStringAsFixed(1)} kg'),
          infoRow('BMI', bmi),
          infoRow('Thị lực', vision),
          infoRow('Răng miệng', dental),
          infoRow('Huyết áp', bloodPressure),
          infoRow('Kết luận', conclusion),
          infoRow('Khuyến nghị', recommendation),
        ],
      ),
    );
  }

  Widget buildHealthRecordCard({
    required DocumentSnapshot doc,
    required List<QueryDocumentSnapshot> allChecks,
  }) {
    final data = doc.data() as Map<String, dynamic>;

    final studentId = data['studentId']?.toString() ?? '';
    final studentName = data['studentName']?.toString() ?? '';
    final className = data['className']?.toString() ?? '';
    final height = parseNumber(data['heightCm']?.toString() ?? '');
    final weight = parseNumber(data['weightKg']?.toString() ?? '');
    final bloodType = data['bloodType']?.toString() ?? '';
    final allergies = data['allergies']?.toString() ?? '';
    final chronicDiseases = data['chronicDiseases']?.toString() ?? '';
    final emergencyContact = data['emergencyContact']?.toString() ?? '';
    final note = data['note']?.toString() ?? '';
    final lastCheckDate = data['lastCheckDate']?.toString() ?? '';

    final bmi = bmiText(height, weight);
    final checks = checksForStudent(allChecks, studentId);

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: bmiColor(height, weight),
          child: const Icon(Icons.medical_information, color: Colors.white),
        ),
        title: Text(
          studentName.isNotEmpty ? studentName : studentId,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              Chip(
                label: Text('Mã: $studentId'),
                backgroundColor: Colors.blue.withOpacity(0.12),
              ),
              Chip(
                label: Text('Lớp: $className'),
                backgroundColor: Colors.grey.withOpacity(0.12),
              ),
              Chip(
                label: Text('BMI: $bmi'),
                backgroundColor: bmiColor(height, weight).withOpacity(0.15),
                labelStyle: TextStyle(
                  color: bmiColor(height, weight),
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (lastCheckDate.isNotEmpty)
                Chip(
                  label: Text('Khám gần nhất: $lastCheckDate'),
                  backgroundColor: Colors.green.withOpacity(0.12),
                ),
            ],
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const Divider(),
          infoRow('Mã học sinh', studentId),
          infoRow('Tên học sinh', studentName),
          infoRow('Lớp', className),
          infoRow('Chiều cao', '${height.toStringAsFixed(1)} cm'),
          infoRow('Cân nặng', '${weight.toStringAsFixed(1)} kg'),
          infoRow('Nhóm máu', bloodType),
          infoRow('Dị ứng', allergies),
          infoRow('Bệnh nền', chronicDiseases),
          infoRow('Liên hệ khẩn cấp', emergencyContact),
          infoRow('Ghi chú', note),
          const SizedBox(height: 12),
          if (canManage)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => openMedicalCheckDialog(healthDoc: doc),
                    icon: const Icon(Icons.add_chart),
                    label: const Text('Thêm lần khám'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => openHealthRecordDialog(doc: doc),
                    icon: const Icon(Icons.edit),
                    label: const Text('Sửa hồ sơ'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => deleteHealthRecord(doc),
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text(
                      'Xóa',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Lịch sử khám sức khỏe (${checks.length})',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          if (checks.isEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('Chưa có lịch sử khám sức khỏe'),
            )
          else
            ...checks.map(buildCheckCard).toList(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isStudent && loadingProfile) {
      return Scaffold(
        appBar: AppBar(
          title: Text(pageTitle()),
          backgroundColor: Colors.blue,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(pageTitle()),
        backgroundColor: Colors.blue,
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => openHealthRecordDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Thêm hồ sơ'),
            )
          : null,
      body: StreamBuilder<QuerySnapshot>(
        stream: healthRecordStream(),
        builder: (context, recordSnap) {
          if (recordSnap.hasError) {
            return const Center(child: Text('Lỗi tải hồ sơ sức khỏe'));
          }

          if (!recordSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return StreamBuilder<QuerySnapshot>(
            stream: medicalCheckStream(),
            builder: (context, checkSnap) {
              if (checkSnap.hasError) {
                return const Center(child: Text('Lỗi tải lịch sử khám'));
              }

              if (!checkSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final records = recordSnap.data!.docs.toList();
              final checks = checkSnap.data!.docs.toList();

              records.sort((a, b) {
                final da = a.data() as Map<String, dynamic>;
                final dbb = b.data() as Map<String, dynamic>;

                return (da['studentName']?.toString() ?? '')
                    .compareTo(dbb['studentName']?.toString() ?? '');
              });

              return Column(
                children: [
                  buildSummary(records: records, checks: checks),
                  if (isStudent)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Học sinh: $studentName | Mã: $currentStudentId | Lớp: $studentClass',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  Expanded(
                    child: records.isEmpty
                        ? Center(
                            child: Text(
                              isStudent
                                  ? 'Bạn chưa có hồ sơ sức khỏe'
                                  : 'Chưa có hồ sơ sức khỏe nào',
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 80),
                            itemCount: records.length,
                            itemBuilder: (context, i) {
                              return buildHealthRecordCard(
                                doc: records[i],
                                allChecks: checks,
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}