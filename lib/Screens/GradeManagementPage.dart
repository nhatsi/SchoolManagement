import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GradeManagementPage extends StatefulWidget {
  final String role;
  final String email;
  final String studentId;

  const GradeManagementPage({
    Key? key,
    required this.role,
    required this.email,
    required this.studentId,
  }) : super(key: key);

  @override
  State<GradeManagementPage> createState() => _GradeManagementPageState();
}

class _GradeManagementPageState extends State<GradeManagementPage> {
  final db = FirebaseFirestore.instance;

  bool get isAdmin => widget.role == 'admin';
  bool get isTeacher => widget.role == 'teacher';
  bool get isStudent => widget.role == 'student';

  String get currentStudentId {
    if (widget.studentId.trim().isNotEmpty) return widget.studentId.trim();
    return 'HS001';
  }

  String pageTitle() {
    if (isStudent) return 'Bảng điểm của tôi';
    return 'Quản lý điểm có hệ số';
  }

  String formatNumber(num value) {
    final fixed = value.toStringAsFixed(2);
    if (fixed.endsWith('.00')) return fixed.replaceAll('.00', '');
    return fixed;
  }

  double parseDouble(String value) {
    return double.tryParse(value.replaceAll(',', '.')) ?? 0;
  }

  void showMsg(String msg) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Stream<QuerySnapshot> gradeItemStream() {
    return db.collection('grade_items').snapshots();
  }

  Stream<QuerySnapshot> studentGradeStream() {
    return db
        .collection('grades')
        .where('studentId', isEqualTo: currentStudentId)
        .snapshots();
  }

  Future<List<QueryDocumentSnapshot>> loadStudentsByClass(String className) async {
    final snap = await db
        .collection('students')
        .where('className', isEqualTo: className)
        .get();

    final docs = snap.docs.toList();

    docs.sort((a, b) {
      final da = a.data() as Map<String, dynamic>;
      final dbb = b.data() as Map<String, dynamic>;
      return (da['name']?.toString() ?? '')
          .compareTo(dbb['name']?.toString() ?? '');
    });

    return docs;
  }

  Future<Map<String, Map<String, dynamic>>> loadGradesByItem(
    String gradeItemId,
  ) async {
    final snap = await db
        .collection('grades')
        .where('gradeItemId', isEqualTo: gradeItemId)
        .get();

    final result = <String, Map<String, dynamic>>{};

    for (final doc in snap.docs) {
      final data = doc.data();
      final studentId = data['studentId']?.toString() ?? '';
      if (studentId.isNotEmpty) {
        result[studentId] = data;
      }
    }

    return result;
  }

  void openCreateGradeItemDialog() {
    final classController = TextEditingController();
    final subjectController = TextEditingController();
    final nameController = TextEditingController();
    final weightController = TextEditingController(text: '1');
    final semesterController = TextEditingController(text: 'HK1');
    bool creating = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> createItem() async {
              final className = classController.text.trim();
              final subject = subjectController.text.trim();
              final name = nameController.text.trim();
              final weight = parseDouble(weightController.text.trim());
              final semester = semesterController.text.trim();

              if (className.isEmpty) {
                showMsg('Vui lòng nhập lớp');
                return;
              }

              if (subject.isEmpty) {
                showMsg('Vui lòng nhập môn học');
                return;
              }

              if (name.isEmpty) {
                showMsg('Vui lòng nhập tên cột điểm');
                return;
              }

              if (weight <= 0) {
                showMsg('Hệ số phải lớn hơn 0');
                return;
              }

              if (semester.isEmpty) {
                showMsg('Vui lòng nhập học kỳ');
                return;
              }

              setDialogState(() {
                creating = true;
              });

              try {
                await db.collection('grade_items').add({
                  'className': className,
                  'subject': subject,
                  'name': name,
                  'weight': weight,
                  'semester': semester,
                  'createdBy': widget.email,
                  'createdAt': FieldValue.serverTimestamp(),
                });

                if (!mounted) return;
                Navigator.pop(context);
                showMsg('Đã tạo cột điểm');
              } catch (_) {
                showMsg('Không tạo được cột điểm');
              }

              if (mounted) {
                setDialogState(() {
                  creating = false;
                });
              }
            }

            return AlertDialog(
              title: const Text('Tạo cột điểm'),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(
                        controller: classController,
                        decoration: const InputDecoration(
                          labelText: 'Lớp, ví dụ 12A1',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.class_),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: subjectController,
                        decoration: const InputDecoration(
                          labelText: 'Môn học, ví dụ Toán',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.menu_book),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Tên cột điểm, ví dụ Giữa kỳ',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.grade),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: weightController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Hệ số, ví dụ 1, 2, 3',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calculate),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: semesterController,
                        decoration: const InputDecoration(
                          labelText: 'Học kỳ, ví dụ HK1',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_month),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: creating ? null : () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                ElevatedButton.icon(
                  onPressed: creating ? null : createItem,
                  icon: creating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(creating ? 'Đang lưu...' : 'Lưu'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> openInputScoresDialog(DocumentSnapshot itemDoc) async {
    final item = itemDoc.data() as Map<String, dynamic>;

    final className = item['className']?.toString() ?? '';
    final subject = item['subject']?.toString() ?? '';
    final itemName = item['name']?.toString() ?? '';
    final semester = item['semester']?.toString() ?? '';
    final weightRaw = item['weight'];
    final weight = weightRaw is num ? weightRaw.toDouble() : parseDouble('$weightRaw');

    if (className.isEmpty) {
      showMsg('Cột điểm chưa có lớp');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return FutureBuilder<List<dynamic>>(
          future: Future.wait([
            loadStudentsByClass(className),
            loadGradesByItem(itemDoc.id),
          ]),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const AlertDialog(
                content: SizedBox(
                  height: 90,
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            final students = snap.data![0] as List<QueryDocumentSnapshot>;
            final oldGrades = snap.data![1] as Map<String, Map<String, dynamic>>;

            if (students.isEmpty) {
              return AlertDialog(
                title: const Text('Nhập điểm'),
                content: Text('Không tìm thấy học sinh thuộc lớp $className'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Đóng'),
                  ),
                ],
              );
            }

            final scoreControllers = <String, TextEditingController>{};
            final commentControllers = <String, TextEditingController>{};

            for (final studentDoc in students) {
              final student = studentDoc.data() as Map<String, dynamic>;
              final sid = student['studentId']?.toString().isNotEmpty == true
                  ? student['studentId'].toString()
                  : student['id']?.toString() ?? studentDoc.id;

              final oldGrade = oldGrades[sid];

              scoreControllers[sid] = TextEditingController(
                text: oldGrade == null ? '' : oldGrade['score']?.toString() ?? '',
              );

              commentControllers[sid] = TextEditingController(
                text: oldGrade == null ? '' : oldGrade['comment']?.toString() ?? '',
              );
            }

            bool saving = false;

            return StatefulBuilder(
              builder: (context, setDialogState) {
                Future<void> saveScores() async {
                  setDialogState(() {
                    saving = true;
                  });

                  try {
                    final batch = db.batch();

                    for (final studentDoc in students) {
                      final student = studentDoc.data() as Map<String, dynamic>;

                      final sid =
                          student['studentId']?.toString().isNotEmpty == true
                              ? student['studentId'].toString()
                              : student['id']?.toString() ?? studentDoc.id;

                      final studentName = student['name']?.toString() ?? '';
                      final scoreText = scoreControllers[sid]!.text.trim();
                      final comment = commentControllers[sid]!.text.trim();

                      if (scoreText.isEmpty) continue;

                      final score = parseDouble(scoreText);

                      if (score < 0 || score > 10) {
                        showMsg('Điểm của $studentName phải từ 0 đến 10');
                        setDialogState(() {
                          saving = false;
                        });
                        return;
                      }

                      final gradeId = '${itemDoc.id}_$sid';
                      final gradeRef = db.collection('grades').doc(gradeId);

                      batch.set(
                        gradeRef,
                        {
                          'id': gradeId,
                          'gradeItemId': itemDoc.id,
                          'studentId': sid,
                          'studentName': studentName,
                          'className': className,
                          'subject': subject,
                          'gradeItemName': itemName,
                          'semester': semester,
                          'weight': weight,
                          'score': score,
                          'comment': comment,
                          'updatedBy': widget.email,
                          'updatedAt': FieldValue.serverTimestamp(),
                        },
                        SetOptions(merge: true),
                      );
                    }

                    await batch.commit();

                    if (!mounted) return;
                    Navigator.pop(context);
                    showMsg('Đã lưu điểm');
                  } catch (_) {
                    showMsg('Không lưu được điểm');
                  }

                  if (mounted) {
                    setDialogState(() {
                      saving = false;
                    });
                  }
                }

                return AlertDialog(
                  title: Text('Nhập điểm - $className'),
                  content: SizedBox(
                    width: 620,
                    height: 520,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$subject - $itemName - Hệ số ${formatNumber(weight)} - $semester',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: ListView.builder(
                            itemCount: students.length,
                            itemBuilder: (context, i) {
                              final student =
                                  students[i].data() as Map<String, dynamic>;

                              final sid =
                                  student['studentId']?.toString().isNotEmpty ==
                                          true
                                      ? student['studentId'].toString()
                                      : student['id']?.toString() ??
                                          students[i].id;

                              final studentName =
                                  student['name']?.toString() ?? sid;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 170,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              studentName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              sid,
                                              style: const TextStyle(
                                                color: Colors.black54,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      SizedBox(
                                        width: 90,
                                        child: TextField(
                                          controller: scoreControllers[sid],
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            labelText: 'Điểm',
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: TextField(
                                          controller: commentControllers[sid],
                                          decoration: const InputDecoration(
                                            labelText: 'Nhận xét',
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: saving ? null : () => Navigator.pop(context),
                      child: const Text('Đóng'),
                    ),
                    ElevatedButton.icon(
                      onPressed: saving ? null : saveScores,
                      icon: saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
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
      },
    );
  }

  Future<void> deleteGradeItem(DocumentSnapshot doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Xóa cột điểm'),
          content: const Text(
            'Bạn có chắc muốn xóa cột điểm này không? Điểm đã nhập vẫn còn trong collection grades.',
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
      await db.collection('grade_items').doc(doc.id).delete();
      showMsg('Đã xóa cột điểm');
    }
  }

  Widget buildTeacherAdminView() {
    return StreamBuilder<QuerySnapshot>(
      stream: gradeItemStream(),
      builder: (context, snap) {
        if (snap.hasError) {
          return const Center(child: Text('Lỗi tải danh sách cột điểm'));
        }

        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data!.docs.toList();

        docs.sort((a, b) {
          final da = a.data() as Map<String, dynamic>;
          final dbb = b.data() as Map<String, dynamic>;

          final classA = da['className']?.toString() ?? '';
          final classB = dbb['className']?.toString() ?? '';

          final subjectA = da['subject']?.toString() ?? '';
          final subjectB = dbb['subject']?.toString() ?? '';

          final c = classA.compareTo(classB);
          if (c != 0) return c;

          return subjectA.compareTo(subjectB);
        });

        if (docs.isEmpty) {
          return const Center(child: Text('Chưa có cột điểm nào'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final doc = docs[i];
            final data = doc.data() as Map<String, dynamic>;

            final className = data['className']?.toString() ?? '';
            final subject = data['subject']?.toString() ?? '';
            final name = data['name']?.toString() ?? '';
            final semester = data['semester']?.toString() ?? '';
            final weightRaw = data['weight'];
            final weight =
                weightRaw is num ? weightRaw : parseDouble('$weightRaw');

            return Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$subject - $name',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              Chip(label: Text('Lớp: $className')),
                              Chip(label: Text('Hệ số: ${formatNumber(weight)}')),
                              Chip(label: Text('Học kỳ: $semester')),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: () => openInputScoresDialog(doc),
                      icon: const Icon(Icons.edit),
                      label: const Text('Nhập điểm'),
                    ),
                    const SizedBox(width: 8),
                    if (isAdmin)
                      IconButton(
                        onPressed: () => deleteGradeItem(doc),
                        icon: const Icon(Icons.delete, color: Colors.red),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Map<String, List<Map<String, dynamic>>> groupGradesBySubject(
    List<QueryDocumentSnapshot> docs,
  ) {
    final result = <String, List<Map<String, dynamic>>>{};

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final subject = data['subject']?.toString() ?? 'Khác';

      result.putIfAbsent(subject, () => []);
      result[subject]!.add(data);
    }

    return result;
  }

  double averageOf(List<Map<String, dynamic>> grades) {
    double total = 0;
    double totalWeight = 0;

    for (final grade in grades) {
      final scoreRaw = grade['score'];
      final weightRaw = grade['weight'];

      final score = scoreRaw is num ? scoreRaw.toDouble() : parseDouble('$scoreRaw');
      final weight =
          weightRaw is num ? weightRaw.toDouble() : parseDouble('$weightRaw');

      total += score * weight;
      totalWeight += weight;
    }

    if (totalWeight == 0) return 0;

    return total / totalWeight;
  }

  Widget buildStudentView() {
    return StreamBuilder<QuerySnapshot>(
      stream: studentGradeStream(),
      builder: (context, snap) {
        if (snap.hasError) {
          return const Center(child: Text('Lỗi tải bảng điểm'));
        }

        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data!.docs.toList();

        docs.sort((a, b) {
          final da = a.data() as Map<String, dynamic>;
          final dbb = b.data() as Map<String, dynamic>;

          final subjectA = da['subject']?.toString() ?? '';
          final subjectB = dbb['subject']?.toString() ?? '';

          return subjectA.compareTo(subjectB);
        });

        if (docs.isEmpty) {
          return const Center(child: Text('Bạn chưa có điểm nào'));
        }

        final grouped = groupGradesBySubject(docs);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ...grouped.entries.map((entry) {
              final subject = entry.key;
              final grades = entry.value;
              final average = averageOf(grades);

              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.only(bottom: 14),
                child: ExpansionTile(
                  initiallyExpanded: true,
                  leading: CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Text(
                      formatNumber(average),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    subject,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Điểm trung bình hệ số: ${formatNumber(average)}',
                  ),
                  children: grades.map((grade) {
                    final itemName = grade['gradeItemName']?.toString() ?? '';
                    final semester = grade['semester']?.toString() ?? '';
                    final scoreRaw = grade['score'];
                    final weightRaw = grade['weight'];
                    final comment = grade['comment']?.toString() ?? '';

                    final score = scoreRaw is num
                        ? scoreRaw
                        : parseDouble('$scoreRaw');

                    final weight = weightRaw is num
                        ? weightRaw
                        : parseDouble('$weightRaw');

                    return ListTile(
                      title: Text('$itemName - $semester'),
                      subtitle: Text(
                        comment.isEmpty
                            ? 'Hệ số: ${formatNumber(weight)}'
                            : 'Hệ số: ${formatNumber(weight)} | Nhận xét: $comment',
                      ),
                      trailing: Text(
                        formatNumber(score),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.blue,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final canManage = isAdmin || isTeacher;

    return Scaffold(
      appBar: AppBar(
        title: Text(pageTitle()),
        backgroundColor: Colors.blue,
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: openCreateGradeItemDialog,
              icon: const Icon(Icons.add),
              label: const Text('Tạo cột điểm'),
            )
          : null,
      body: canManage ? buildTeacherAdminView() : buildStudentView(),
    );
  }
}