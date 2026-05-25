import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentRecordPage extends StatefulWidget {
  final String role;
  final String email;
  final String studentId;

  const StudentRecordPage({
    Key? key,
    required this.role,
    required this.email,
    required this.studentId,
  }) : super(key: key);

  @override
  State<StudentRecordPage> createState() => _StudentRecordPageState();
}

class _StudentRecordPageState extends State<StudentRecordPage> {
  final db = FirebaseFirestore.instance;

  bool get isAdmin => widget.role == 'admin';
  bool get isTeacher => widget.role == 'teacher';
  bool get isStudent => widget.role == 'student';

  String get currentStudentId {
    if (widget.studentId.trim().isNotEmpty) return widget.studentId.trim();
    return 'HS001';
  }

  String pageTitle() {
    if (isStudent) return 'Hồ sơ khen thưởng / kỷ luật';
    if (isTeacher) return 'Ghi nhận học sinh';
    return 'Quản lý khen thưởng / kỷ luật';
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

  Stream<QuerySnapshot> recordStream() {
    if (isStudent) {
      return db
          .collection('student_records')
          .where('studentId', isEqualTo: currentStudentId)
          .snapshots();
    }

    return db.collection('student_records').snapshots();
  }

  String typeText(String type) {
    if (type == 'reward') return 'Khen thưởng';
    if (type == 'discipline') return 'Kỷ luật';
    return type;
  }

  Color typeColor(String type) {
    if (type == 'reward') return Colors.green;
    if (type == 'discipline') return Colors.red;
    return Colors.grey;
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

  void openCreateDialog() {
    if (isStudent) return;

    final studentIdController = TextEditingController();
    final studentNameController = TextEditingController();
    final classNameController = TextEditingController();
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final dateController = TextEditingController(text: formatDate(DateTime.now()));

    String selectedType = 'reward';
    String selectedLevel = 'Cấp lớp';
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
                initialDate: parseDate(dateController.text),
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );

              if (picked != null) {
                dateController.text = formatDate(picked);
              }
            }

            Future<void> saveRecord() async {
              final sid = studentIdController.text.trim();
              final studentName = studentNameController.text.trim();
              final className = classNameController.text.trim();
              final title = titleController.text.trim();
              final content = contentController.text.trim();
              final date = dateController.text.trim();

              if (sid.isEmpty) {
                showMsg('Vui lòng nhập mã học sinh');
                return;
              }

              if (studentName.isEmpty || className.isEmpty) {
                showMsg('Vui lòng bấm Tải học sinh trước khi lưu');
                return;
              }

              if (title.isEmpty) {
                showMsg('Vui lòng nhập tiêu đề');
                return;
              }

              if (content.isEmpty) {
                showMsg('Vui lòng nhập nội dung');
                return;
              }

              setDialogState(() {
                saving = true;
              });

              try {
                final ref = db.collection('student_records').doc();

                await ref.set({
                  'id': ref.id,
                  'studentId': sid,
                  'studentName': studentName,
                  'className': className,
                  'type': selectedType,
                  'title': title,
                  'content': content,
                  'date': date,
                  'level': selectedLevel,
                  'createdBy': widget.email,
                  'createdRole': widget.role,
                  'createdAt': FieldValue.serverTimestamp(),
                });

                if (!mounted) return;
                Navigator.pop(context);
                showMsg('Đã lưu ghi nhận học sinh');
              } catch (_) {
                showMsg('Không lưu được ghi nhận');
              }

              if (mounted) {
                setDialogState(() {
                  saving = false;
                });
              }
            }

            return AlertDialog(
              title: const Text('Tạo ghi nhận học sinh'),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Loại ghi nhận',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'reward',
                            child: Text('Khen thưởng'),
                          ),
                          DropdownMenuItem(
                            value: 'discipline',
                            child: Text('Kỷ luật'),
                          ),
                        ],
                        onChanged: saving
                            ? null
                            : (value) {
                                if (value != null) {
                                  setDialogState(() {
                                    selectedType = value;
                                  });
                                }
                              },
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: selectedLevel,
                        decoration: const InputDecoration(
                          labelText: 'Cấp độ',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.military_tech),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Cấp lớp',
                            child: Text('Cấp lớp'),
                          ),
                          DropdownMenuItem(
                            value: 'Cấp trường',
                            child: Text('Cấp trường'),
                          ),
                          DropdownMenuItem(
                            value: 'Cấp trung tâm',
                            child: Text('Cấp trung tâm'),
                          ),
                          DropdownMenuItem(
                            value: 'Nhắc nhở',
                            child: Text('Nhắc nhở'),
                          ),
                          DropdownMenuItem(
                            value: 'Nghiêm trọng',
                            child: Text('Nghiêm trọng'),
                          ),
                        ],
                        onChanged: saving
                            ? null
                            : (value) {
                                if (value != null) {
                                  setDialogState(() {
                                    selectedLevel = value;
                                  });
                                }
                              },
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: studentIdController,
                              decoration: const InputDecoration(
                                labelText: 'Mã học sinh, ví dụ HS001',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.badge),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: loadingStudent ? null : loadStudentInfo,
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
                        controller: dateController,
                        readOnly: true,
                        onTap: pickDate,
                        decoration: const InputDecoration(
                          labelText: 'Ngày ghi nhận',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_month),
                          suffixIcon: Icon(Icons.date_range),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Tiêu đề',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.title),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: contentController,
                        minLines: 4,
                        maxLines: 7,
                        decoration: const InputDecoration(
                          labelText: 'Nội dung / lý do',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.article),
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
                  onPressed: saving ? null : saveRecord,
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
                  label: Text(saving ? 'Đang lưu...' : 'Lưu'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void openEditDialog(DocumentSnapshot doc) {
    if (isStudent) return;

    final data = doc.data() as Map<String, dynamic>;

    final titleController = TextEditingController(
      text: data['title']?.toString() ?? '',
    );
    final contentController = TextEditingController(
      text: data['content']?.toString() ?? '',
    );
    final dateController = TextEditingController(
      text: data['date']?.toString() ?? formatDate(DateTime.now()),
    );

    String selectedType = data['type']?.toString() ?? 'reward';
    String selectedLevel = data['level']?.toString() ?? 'Cấp lớp';

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
              final title = titleController.text.trim();
              final content = contentController.text.trim();

              if (title.isEmpty || content.isEmpty) {
                showMsg('Vui lòng nhập đầy đủ tiêu đề và nội dung');
                return;
              }

              await db.collection('student_records').doc(doc.id).update({
                'type': selectedType,
                'title': title,
                'content': content,
                'date': dateController.text.trim(),
                'level': selectedLevel,
                'updatedBy': widget.email,
                'updatedAt': FieldValue.serverTimestamp(),
              });

              if (!mounted) return;
              Navigator.pop(context);
              showMsg('Đã cập nhật ghi nhận');
            }

            return AlertDialog(
              title: const Text('Sửa ghi nhận'),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Loại',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'reward',
                            child: Text('Khen thưởng'),
                          ),
                          DropdownMenuItem(
                            value: 'discipline',
                            child: Text('Kỷ luật'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              selectedType = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: selectedLevel,
                        decoration: const InputDecoration(
                          labelText: 'Cấp độ',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Cấp lớp', child: Text('Cấp lớp')),
                          DropdownMenuItem(value: 'Cấp trường', child: Text('Cấp trường')),
                          DropdownMenuItem(value: 'Cấp trung tâm', child: Text('Cấp trung tâm')),
                          DropdownMenuItem(value: 'Nhắc nhở', child: Text('Nhắc nhở')),
                          DropdownMenuItem(value: 'Nghiêm trọng', child: Text('Nghiêm trọng')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              selectedLevel = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: dateController,
                        readOnly: true,
                        onTap: pickDate,
                        decoration: const InputDecoration(
                          labelText: 'Ngày ghi nhận',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_month),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Tiêu đề',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: contentController,
                        minLines: 4,
                        maxLines: 7,
                        decoration: const InputDecoration(
                          labelText: 'Nội dung',
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

  Future<void> deleteRecord(DocumentSnapshot doc) async {
    if (isStudent) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Xóa ghi nhận'),
          content: const Text('Bạn có chắc muốn xóa ghi nhận này không?'),
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
      await db.collection('student_records').doc(doc.id).delete();
      showMsg('Đã xóa ghi nhận');
    }
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

  Widget buildSummary(List<QueryDocumentSnapshot> docs) {
    final rewards = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['type'] == 'reward';
    }).length;

    final disciplines = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['type'] == 'discipline';
    }).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Row(
        children: [
          summaryBox('Tổng', docs.length.toString(), Colors.blue),
          const SizedBox(width: 8),
          summaryBox('Khen thưởng', rewards.toString(), Colors.green),
          const SizedBox(width: 8),
          summaryBox('Kỷ luật', disciplines.toString(), Colors.red),
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
              style: TextStyle(color: color, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildRecordCard(DocumentSnapshot doc, int index) {
    final data = doc.data() as Map<String, dynamic>;

    final type = data['type']?.toString() ?? '';
    final studentId = data['studentId']?.toString() ?? '';
    final studentName = data['studentName']?.toString() ?? '';
    final className = data['className']?.toString() ?? '';
    final title = data['title']?.toString() ?? '';
    final content = data['content']?.toString() ?? '';
    final date = data['date']?.toString() ?? '';
    final level = data['level']?.toString() ?? '';
    final createdBy = data['createdBy']?.toString() ?? '';

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: typeColor(type),
          child: Icon(
            type == 'reward' ? Icons.emoji_events : Icons.warning,
            color: Colors.white,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              Chip(
                label: Text(typeText(type)),
                backgroundColor: typeColor(type).withOpacity(0.15),
                labelStyle: TextStyle(
                  color: typeColor(type),
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (level.isNotEmpty)
                Chip(
                  label: Text(level),
                  backgroundColor: Colors.blue.withOpacity(0.12),
                ),
              if (className.isNotEmpty)
                Chip(
                  label: Text('Lớp: $className'),
                  backgroundColor: Colors.grey.withOpacity(0.12),
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
          infoRow('Loại', typeText(type)),
          infoRow('Cấp độ', level),
          infoRow('Ngày', date),
          infoRow('Nội dung', content),
          infoRow('Người lập', createdBy),
          if (!isStudent) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => openEditDialog(doc),
                    icon: const Icon(Icons.edit),
                    label: const Text('Sửa'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => deleteRecord(doc),
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text(
                      'Xóa',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canCreate = isAdmin || isTeacher;

    return Scaffold(
      appBar: AppBar(
        title: Text(pageTitle()),
        backgroundColor: Colors.blue,
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: openCreateDialog,
              icon: const Icon(Icons.add),
              label: const Text('Thêm ghi nhận'),
            )
          : null,
      body: StreamBuilder<QuerySnapshot>(
        stream: recordStream(),
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(
              child: Text('Lỗi tải danh sách khen thưởng / kỷ luật'),
            );
          }

          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs.toList();

          docs.sort((a, b) {
            final da = a.data() as Map<String, dynamic>;
            final dbb = b.data() as Map<String, dynamic>;
            return (dbb['date']?.toString() ?? '')
                .compareTo(da['date']?.toString() ?? '');
          });

          if (docs.isEmpty) {
            return Center(
              child: Text(
                isStudent
                    ? 'Bạn chưa có hồ sơ khen thưởng / kỷ luật nào'
                    : 'Chưa có dữ liệu khen thưởng / kỷ luật',
              ),
            );
          }

          return Column(
            children: [
              buildSummary(docs),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    return buildRecordCard(docs[i], i);
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