import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ExamManagementPage extends StatefulWidget {
  final String role;
  final String email;
  final String studentId;

  const ExamManagementPage({
    Key? key,
    required this.role,
    required this.email,
    required this.studentId,
  }) : super(key: key);

  @override
  State<ExamManagementPage> createState() => _ExamManagementPageState();
}

class _ExamManagementPageState extends State<ExamManagementPage> {
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

    if (studentClass.trim().isEmpty) {
      studentClass = '12A1';
    }

    if (studentName.trim().isEmpty) {
      studentName = widget.email;
    }

    if (mounted) {
      setState(() {
        loadingProfile = false;
      });
    }
  }

  String pageTitle() {
    if (isStudent) return 'Lịch thi / Kết quả thi';
    if (isTeacher) return 'Quản lý lịch thi';
    return 'Quản lý lịch thi / kết quả';
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

  Stream<QuerySnapshot> examStream() {
    return db.collection('exam_schedules').snapshots();
  }

  Stream<QuerySnapshot> resultStream() {
    return db.collection('exam_results').snapshots();
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

  void openCreateExamDialog() {
    if (!canManage) return;

    final examNameController = TextEditingController();
    final subjectController = TextEditingController();
    final classController = TextEditingController(text: '12A1');
    final dateController = TextEditingController(text: formatDate(DateTime.now()));
    final startController = TextEditingController(text: '07:30');
    final endController = TextEditingController(text: '09:00');
    final roomController = TextEditingController(text: 'P.301');
    final noteController = TextEditingController();

    bool saving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickDate() async {
              final picked = await showDatePicker(
                context: context,
                initialDate: parseDate(dateController.text),
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );

              if (picked != null) {
                dateController.text = formatDate(picked);
              }
            }

            Future<void> saveExam() async {
              final examName = examNameController.text.trim();
              final subject = subjectController.text.trim();
              final className = classController.text.trim();
              final examDate = dateController.text.trim();
              final startTime = startController.text.trim();
              final endTime = endController.text.trim();
              final room = roomController.text.trim();
              final note = noteController.text.trim();

              if (examName.isEmpty) {
                showMsg('Vui lòng nhập tên kỳ thi / bài thi');
                return;
              }

              if (subject.isEmpty) {
                showMsg('Vui lòng nhập môn thi');
                return;
              }

              if (className.isEmpty) {
                showMsg('Vui lòng nhập lớp');
                return;
              }

              if (examDate.isEmpty || startTime.isEmpty || endTime.isEmpty) {
                showMsg('Vui lòng nhập đầy đủ ngày và thời gian thi');
                return;
              }

              setDialogState(() {
                saving = true;
              });

              try {
                final ref = db.collection('exam_schedules').doc();

                await ref.set({
                  'id': ref.id,
                  'examName': examName,
                  'subject': subject,
                  'className': className,
                  'examDate': examDate,
                  'startTime': startTime,
                  'endTime': endTime,
                  'room': room,
                  'note': note,
                  'createdBy': widget.email,
                  'createdRole': widget.role,
                  'createdAt': FieldValue.serverTimestamp(),
                });

                if (!mounted) return;
                Navigator.pop(context);
                showMsg('Đã tạo lịch thi');
              } catch (_) {
                showMsg('Không tạo được lịch thi');
              }

              if (mounted) {
                setDialogState(() {
                  saving = false;
                });
              }
            }

            return AlertDialog(
              title: const Text('Tạo lịch thi'),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(
                        controller: examNameController,
                        decoration: const InputDecoration(
                          labelText: 'Tên kỳ thi / bài thi',
                          hintText: 'Ví dụ: Kiểm tra giữa kỳ HK2',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.assignment),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: subjectController,
                        decoration: const InputDecoration(
                          labelText: 'Môn thi',
                          hintText: 'Ví dụ: Toán 12',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.menu_book),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: classController,
                        decoration: const InputDecoration(
                          labelText: 'Lớp',
                          hintText: 'Ví dụ: 12A1',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.class_),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: dateController,
                        readOnly: true,
                        onTap: pickDate,
                        decoration: const InputDecoration(
                          labelText: 'Ngày thi',
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
                              controller: startController,
                              decoration: const InputDecoration(
                                labelText: 'Bắt đầu',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.schedule),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: endController,
                              decoration: const InputDecoration(
                                labelText: 'Kết thúc',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.schedule),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: roomController,
                        decoration: const InputDecoration(
                          labelText: 'Phòng thi',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.meeting_room),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: noteController,
                        minLines: 3,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Ghi chú',
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
                  onPressed: saving ? null : saveExam,
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

  void openEditExamDialog(DocumentSnapshot doc) {
    if (!canManage) return;

    final data = doc.data() as Map<String, dynamic>;

    final examNameController = TextEditingController(
      text: data['examName']?.toString() ?? '',
    );
    final subjectController = TextEditingController(
      text: data['subject']?.toString() ?? '',
    );
    final classController = TextEditingController(
      text: data['className']?.toString() ?? '',
    );
    final dateController = TextEditingController(
      text: data['examDate']?.toString() ?? formatDate(DateTime.now()),
    );
    final startController = TextEditingController(
      text: data['startTime']?.toString() ?? '',
    );
    final endController = TextEditingController(
      text: data['endTime']?.toString() ?? '',
    );
    final roomController = TextEditingController(
      text: data['room']?.toString() ?? '',
    );
    final noteController = TextEditingController(
      text: data['note']?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickDate() async {
              final picked = await showDatePicker(
                context: context,
                initialDate: parseDate(dateController.text),
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );

              if (picked != null) {
                dateController.text = formatDate(picked);
              }
            }

            Future<void> saveEdit() async {
              final examName = examNameController.text.trim();
              final subject = subjectController.text.trim();
              final className = classController.text.trim();

              if (examName.isEmpty || subject.isEmpty || className.isEmpty) {
                showMsg('Vui lòng nhập đầy đủ tên kỳ thi, môn thi và lớp');
                return;
              }

              await db.collection('exam_schedules').doc(doc.id).update({
                'examName': examName,
                'subject': subject,
                'className': className,
                'examDate': dateController.text.trim(),
                'startTime': startController.text.trim(),
                'endTime': endController.text.trim(),
                'room': roomController.text.trim(),
                'note': noteController.text.trim(),
                'updatedBy': widget.email,
                'updatedAt': FieldValue.serverTimestamp(),
              });

              if (!mounted) return;
              Navigator.pop(context);
              showMsg('Đã cập nhật lịch thi');
            }

            return AlertDialog(
              title: const Text('Sửa lịch thi'),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(
                        controller: examNameController,
                        decoration: const InputDecoration(
                          labelText: 'Tên kỳ thi / bài thi',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: subjectController,
                        decoration: const InputDecoration(
                          labelText: 'Môn thi',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: classController,
                        decoration: const InputDecoration(
                          labelText: 'Lớp',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: dateController,
                        readOnly: true,
                        onTap: pickDate,
                        decoration: const InputDecoration(
                          labelText: 'Ngày thi',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_month),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: startController,
                              decoration: const InputDecoration(
                                labelText: 'Bắt đầu',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: endController,
                              decoration: const InputDecoration(
                                labelText: 'Kết thúc',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: roomController,
                        decoration: const InputDecoration(
                          labelText: 'Phòng thi',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: noteController,
                        minLines: 3,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Ghi chú',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                ElevatedButton.icon(
                  onPressed: saveEdit,
                  icon: const Icon(Icons.save),
                  label: const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void openResultDialog({
    required DocumentSnapshot examDoc,
    Map<String, dynamic>? oldResult,
  }) {
    if (!canManage) return;

    final exam = examDoc.data() as Map<String, dynamic>;

    final studentIdController = TextEditingController(
      text: oldResult?['studentId']?.toString() ?? '',
    );
    final studentNameController = TextEditingController(
      text: oldResult?['studentName']?.toString() ?? '',
    );
    final classNameController = TextEditingController(
      text: oldResult?['className']?.toString() ?? exam['className']?.toString() ?? '',
    );
    final scoreController = TextEditingController(
      text: oldResult?['score']?.toString() ?? '',
    );
    final commentController = TextEditingController(
      text: oldResult?['comment']?.toString() ?? '',
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

            Future<void> saveResult() async {
              final sid = studentIdController.text.trim();
              final studentNameValue = studentNameController.text.trim();
              final classNameValue = classNameController.text.trim();
              final scoreText = scoreController.text.trim();
              final comment = commentController.text.trim();

              if (sid.isEmpty) {
                showMsg('Vui lòng nhập mã học sinh');
                return;
              }

              if (studentNameValue.isEmpty || classNameValue.isEmpty) {
                showMsg('Vui lòng bấm Tải học sinh trước khi lưu');
                return;
              }

              if (scoreText.isEmpty) {
                showMsg('Vui lòng nhập điểm thi');
                return;
              }

              final score = double.tryParse(scoreText.replaceAll(',', '.'));

              if (score == null || score < 0 || score > 10) {
                showMsg('Điểm thi phải từ 0 đến 10');
                return;
              }

              setDialogState(() {
                saving = true;
              });

              try {
                final examId = examDoc.id;
                final resultId = '${examId}_$sid';

                await db.collection('exam_results').doc(resultId).set({
                  'id': resultId,
                  'examId': examId,
                  'examName': exam['examName']?.toString() ?? '',
                  'subject': exam['subject']?.toString() ?? '',
                  'examDate': exam['examDate']?.toString() ?? '',
                  'studentId': sid,
                  'studentName': studentNameValue,
                  'className': classNameValue,
                  'score': score,
                  'comment': comment,
                  'createdBy': widget.email,
                  'createdAt': FieldValue.serverTimestamp(),
                  'updatedAt': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));

                if (!mounted) return;
                Navigator.pop(context);
                showMsg('Đã lưu kết quả thi');
              } catch (_) {
                showMsg('Không lưu được kết quả thi');
              }

              if (mounted) {
                setDialogState(() {
                  saving = false;
                });
              }
            }

            return AlertDialog(
              title: const Text('Nhập kết quả thi'),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${exam['examName'] ?? ''} - ${exam['subject'] ?? ''}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: studentIdController,
                              readOnly: oldResult != null,
                              decoration: const InputDecoration(
                                labelText: 'Mã học sinh',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.badge),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: oldResult != null || loadingStudent
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
                        controller: scoreController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Điểm thi',
                          hintText: '0 - 10',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.grade),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: commentController,
                        minLines: 3,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Nhận xét',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.comment),
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
                  onPressed: saving ? null : saveResult,
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
                  label: Text(saving ? 'Đang lưu...' : 'Lưu điểm'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> deleteExam(DocumentSnapshot doc) async {
    if (!canManage) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Xóa lịch thi'),
          content: const Text(
            'Bạn có chắc muốn xóa lịch thi này không? Kết quả thi đã nhập sẽ không tự xóa.',
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
      await db.collection('exam_schedules').doc(doc.id).delete();
      showMsg('Đã xóa lịch thi');
    }
  }

  Future<void> deleteResult(String resultId) async {
    if (!canManage) return;

    await db.collection('exam_results').doc(resultId).delete();
    showMsg('Đã xóa kết quả thi');
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
    required List<QueryDocumentSnapshot> exams,
    required List<QueryDocumentSnapshot> results,
  }) {
    final visibleExams = filterExams(exams);
    final visibleResults = filterResults(results);

    final upcoming = visibleExams.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final date = data['examDate']?.toString() ?? '';
      return date.compareTo(formatDate(DateTime.now())) >= 0;
    }).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Row(
        children: [
          summaryBox('Lịch thi', visibleExams.length.toString(), Colors.blue),
          const SizedBox(width: 8),
          summaryBox('Sắp thi', upcoming.toString(), Colors.orange),
          const SizedBox(width: 8),
          summaryBox('Kết quả', visibleResults.length.toString(), Colors.green),
        ],
      ),
    );
  }

  List<QueryDocumentSnapshot> filterExams(List<QueryDocumentSnapshot> exams) {
    if (!isStudent) return exams;

    return exams.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['className']?.toString() == studentClass;
    }).toList();
  }

  List<QueryDocumentSnapshot> filterResults(List<QueryDocumentSnapshot> results) {
    if (!isStudent) return results;

    return results.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['studentId']?.toString() == currentStudentId;
    }).toList();
  }

  Map<String, dynamic>? resultForExam({
    required String examId,
    required List<QueryDocumentSnapshot> results,
  }) {
    final matched = results.where((doc) {
      final data = doc.data() as Map<String, dynamic>;

      if (data['examId']?.toString() != examId) return false;

      if (isStudent) {
        return data['studentId']?.toString() == currentStudentId;
      }

      return true;
    }).toList();

    if (matched.isEmpty) return null;

    return {
      ...matched.first.data() as Map<String, dynamic>,
      '_docId': matched.first.id,
    };
  }

  List<Map<String, dynamic>> resultsForExam({
    required String examId,
    required List<QueryDocumentSnapshot> results,
  }) {
    return results.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['examId']?.toString() == examId;
    }).map((doc) {
      return {
        ...doc.data() as Map<String, dynamic>,
        '_docId': doc.id,
      };
    }).toList();
  }

  Widget infoRow(String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 115,
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

  Widget buildResultMiniCard({
    required Map<String, dynamic> result,
    required DocumentSnapshot examDoc,
  }) {
    final score = result['score']?.toString() ?? '';
    final comment = result['comment']?.toString() ?? '';
    final studentNameValue = result['studentName']?.toString() ?? '';
    final studentIdValue = result['studentId']?.toString() ?? '';
    final resultId = result['_docId']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.withOpacity(0.22)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.green,
            child: Icon(Icons.grade, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$studentNameValue ($studentIdValue)',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('Điểm: $score'),
                if (comment.isNotEmpty) Text('Nhận xét: $comment'),
              ],
            ),
          ),
          if (canManage) ...[
            IconButton(
              onPressed: () => openResultDialog(
                examDoc: examDoc,
                oldResult: result,
              ),
              icon: const Icon(Icons.edit, color: Colors.orange),
            ),
            IconButton(
              onPressed: () => deleteResult(resultId),
              icon: const Icon(Icons.delete, color: Colors.red),
            ),
          ],
        ],
      ),
    );
  }

  Widget buildExamCard({
    required DocumentSnapshot doc,
    required List<QueryDocumentSnapshot> results,
  }) {
    final data = doc.data() as Map<String, dynamic>;

    final examName = data['examName']?.toString() ?? '';
    final subject = data['subject']?.toString() ?? '';
    final className = data['className']?.toString() ?? '';
    final examDate = data['examDate']?.toString() ?? '';
    final startTime = data['startTime']?.toString() ?? '';
    final endTime = data['endTime']?.toString() ?? '';
    final room = data['room']?.toString() ?? '';
    final note = data['note']?.toString() ?? '';
    final createdBy = data['createdBy']?.toString() ?? '';

    final myResult = resultForExam(examId: doc.id, results: results);
    final allResults = resultsForExam(examId: doc.id, results: results);

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: myResult == null ? Colors.blue : Colors.green,
          child: Icon(
            myResult == null ? Icons.event_note : Icons.grade,
            color: Colors.white,
          ),
        ),
        title: Text(
          examName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              Chip(
                label: Text(subject),
                backgroundColor: Colors.blue.withOpacity(0.12),
              ),
              Chip(
                label: Text('Lớp: $className'),
                backgroundColor: Colors.grey.withOpacity(0.12),
              ),
              Chip(
                label: Text('$examDate | $startTime - $endTime'),
                backgroundColor: Colors.orange.withOpacity(0.12),
              ),
              if (myResult != null)
                Chip(
                  label: Text('Điểm: ${myResult['score']}'),
                  backgroundColor: Colors.green.withOpacity(0.15),
                  labelStyle: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const Divider(),
          infoRow('Tên kỳ thi', examName),
          infoRow('Môn thi', subject),
          infoRow('Lớp', className),
          infoRow('Ngày thi', examDate),
          infoRow('Thời gian', '$startTime - $endTime'),
          infoRow('Phòng thi', room),
          infoRow('Ghi chú', note),
          infoRow('Người tạo', createdBy),
          const SizedBox(height: 12),
          if (isStudent) ...[
            if (myResult == null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Chưa có kết quả thi cho môn này'),
              )
            else
              buildResultMiniCard(result: myResult, examDoc: doc),
          ],
          if (canManage) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => openResultDialog(examDoc: doc),
                    icon: const Icon(Icons.grade),
                    label: const Text('Nhập điểm'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => openEditExamDialog(doc),
                    icon: const Icon(Icons.edit),
                    label: const Text('Sửa lịch'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => deleteExam(doc),
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text(
                      'Xóa',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
            if (allResults.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Kết quả đã nhập',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ...allResults.map((r) {
                return buildResultMiniCard(result: r, examDoc: doc);
              }).toList(),
            ],
          ],
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
              onPressed: openCreateExamDialog,
              icon: const Icon(Icons.add),
              label: const Text('Tạo lịch thi'),
            )
          : null,
      body: StreamBuilder<QuerySnapshot>(
        stream: examStream(),
        builder: (context, examSnap) {
          if (examSnap.hasError) {
            return const Center(child: Text('Lỗi tải lịch thi'));
          }

          if (!examSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return StreamBuilder<QuerySnapshot>(
            stream: resultStream(),
            builder: (context, resultSnap) {
              if (resultSnap.hasError) {
                return const Center(child: Text('Lỗi tải kết quả thi'));
              }

              if (!resultSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final allExams = examSnap.data!.docs.toList();
              final allResults = resultSnap.data!.docs.toList();

              final exams = filterExams(allExams);

              exams.sort((a, b) {
                final da = a.data() as Map<String, dynamic>;
                final dbb = b.data() as Map<String, dynamic>;

                return (da['examDate']?.toString() ?? '')
                    .compareTo(dbb['examDate']?.toString() ?? '');
              });

              return Column(
                children: [
                  buildSummary(exams: allExams, results: allResults),
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
                    child: exams.isEmpty
                        ? Center(
                            child: Text(
                              isStudent
                                  ? 'Lớp của bạn chưa có lịch thi'
                                  : 'Chưa có lịch thi nào',
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 80),
                            itemCount: exams.length,
                            itemBuilder: (context, i) {
                              return buildExamCard(
                                doc: exams[i],
                                results: allResults,
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