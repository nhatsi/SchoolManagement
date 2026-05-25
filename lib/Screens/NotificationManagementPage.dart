import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationManagementPage extends StatefulWidget {
  final String role;
  final String email;
  final String studentId;

  const NotificationManagementPage({
    Key? key,
    required this.role,
    required this.email,
    required this.studentId,
  }) : super(key: key);

  @override
  State<NotificationManagementPage> createState() =>
      _NotificationManagementPageState();
}

class _NotificationManagementPageState
    extends State<NotificationManagementPage> {
  final db = FirebaseFirestore.instance;

  bool get isAdmin => widget.role == 'admin';
  bool get isTeacher => widget.role == 'teacher';
  bool get isStudent => widget.role == 'student';

  String get currentStudentId {
    if (widget.studentId.trim().isNotEmpty) return widget.studentId.trim();
    return 'HS001';
  }

  String pageTitle() {
    if (isAdmin) return 'Quản lý thông báo';
    if (isTeacher) return 'Thông báo giáo viên';
    return 'Thông báo của tôi';
  }

  void showMsg(String msg) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  String formatDateTime(dynamic value) {
    if (value is Timestamp) {
      final d = value.toDate();
      final y = d.year.toString().padLeft(4, '0');
      final m = d.month.toString().padLeft(2, '0');
      final day = d.day.toString().padLeft(2, '0');
      final h = d.hour.toString().padLeft(2, '0');
      final min = d.minute.toString().padLeft(2, '0');
      return '$y-$m-$day $h:$min';
    }

    return '';
  }

  String targetText(String type, String value) {
    switch (type) {
      case 'all':
        return 'Toàn trường';
      case 'role':
        if (value == 'admin') return 'Theo vai trò: Admin';
        if (value == 'teacher') return 'Theo vai trò: Giáo viên';
        if (value == 'student') return 'Theo vai trò: Học sinh';
        return 'Theo vai trò: $value';
      case 'class':
        return 'Theo lớp: $value';
      case 'student':
        return 'Theo học sinh: $value';
      default:
        return '$type - $value';
    }
  }

  Stream<QuerySnapshot> notificationStream() {
    return db.collection('notifications').snapshots();
  }

  bool canSeeNotification(Map<String, dynamic> data) {
    final targetType = data['targetType']?.toString() ?? 'all';
    final targetValue = data['targetValue']?.toString() ?? '';

    if (isAdmin) return true;

    if (targetType == 'all') return true;

    if (targetType == 'role') {
      return targetValue == widget.role;
    }

    if (targetType == 'student') {
      return targetValue == currentStudentId;
    }

    if (targetType == 'class') {
      final className = data['targetValue']?.toString() ?? '';
      final userClass = data['receiverClass']?.toString() ?? '';

      return className == userClass;
    }

    return false;
  }

  Future<String> loadStudentClass() async {
    if (!isStudent) return '';

    try {
      final doc = await db.collection('students').doc(currentStudentId).get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        return data['className']?.toString() ?? '';
      }

      final profileSnap = await db
          .collection('profiles')
          .where('studentId', isEqualTo: currentStudentId)
          .limit(1)
          .get();

      if (profileSnap.docs.isNotEmpty) {
        return profileSnap.docs.first.data()['className']?.toString() ?? '';
      }
    } catch (_) {}

    return '';
  }

  Future<bool> isRead(String notificationId) async {
    final readId = '${notificationId}_${widget.email}';

    final doc = await db.collection('notification_reads').doc(readId).get();

    return doc.exists;
  }

  Future<void> markAsRead(String notificationId) async {
    final readId = '${notificationId}_${widget.email}';

    await db.collection('notification_reads').doc(readId).set({
      'id': readId,
      'notificationId': notificationId,
      'userEmail': widget.email,
      'studentId': isStudent ? currentStudentId : '',
      'role': widget.role,
      'readAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    showMsg('Đã đánh dấu đã đọc');

    if (mounted) {
      setState(() {});
    }
  }

  void openCreateNotificationDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final targetValueController = TextEditingController();

    String selectedTargetType = 'all';
    String selectedRole = 'student';

    bool creating = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> createNotification() async {
              final title = titleController.text.trim();
              final content = contentController.text.trim();

              String targetValue = '';

              if (selectedTargetType == 'role') {
                targetValue = selectedRole;
              } else if (selectedTargetType == 'class' ||
                  selectedTargetType == 'student') {
                targetValue = targetValueController.text.trim();
              }

              if (title.isEmpty) {
                showMsg('Vui lòng nhập tiêu đề');
                return;
              }

              if (content.isEmpty) {
                showMsg('Vui lòng nhập nội dung');
                return;
              }

              if (selectedTargetType != 'all' && targetValue.isEmpty) {
                showMsg('Vui lòng nhập đối tượng nhận');
                return;
              }

              setDialogState(() {
                creating = true;
              });

              try {
                await db.collection('notifications').add({
                  'title': title,
                  'content': content,
                  'targetType': selectedTargetType,
                  'targetValue': targetValue,
                  'createdBy': widget.email,
                  'createdRole': widget.role,
                  'createdAt': FieldValue.serverTimestamp(),
                });

                if (!mounted) return;
                Navigator.pop(context);
                showMsg('Đã tạo thông báo');
              } catch (_) {
                showMsg('Không tạo được thông báo');
              }

              if (mounted) {
                setDialogState(() {
                  creating = false;
                });
              }
            }

            return AlertDialog(
              title: const Text('Tạo thông báo'),
              content: SizedBox(
                width: 450,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
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
                          labelText: 'Nội dung',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.article),
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: selectedTargetType,
                        decoration: const InputDecoration(
                          labelText: 'Đối tượng nhận',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.group),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'all',
                            child: Text('Toàn trường'),
                          ),
                          DropdownMenuItem(
                            value: 'role',
                            child: Text('Theo vai trò'),
                          ),
                          DropdownMenuItem(
                            value: 'class',
                            child: Text('Theo lớp'),
                          ),
                          DropdownMenuItem(
                            value: 'student',
                            child: Text('Theo học sinh'),
                          ),
                        ],
                        onChanged: creating
                            ? null
                            : (value) {
                                if (value != null) {
                                  setDialogState(() {
                                    selectedTargetType = value;
                                  });
                                }
                              },
                      ),
                      if (selectedTargetType == 'role') ...[
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: selectedRole,
                          decoration: const InputDecoration(
                            labelText: 'Vai trò nhận',
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
                          onChanged: creating
                              ? null
                              : (value) {
                                  if (value != null) {
                                    setDialogState(() {
                                      selectedRole = value;
                                    });
                                  }
                                },
                        ),
                      ],
                      if (selectedTargetType == 'class') ...[
                        const SizedBox(height: 10),
                        TextField(
                          controller: targetValueController,
                          decoration: const InputDecoration(
                            labelText: 'Nhập lớp, ví dụ 12A1',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.class_),
                          ),
                        ),
                      ],
                      if (selectedTargetType == 'student') ...[
                        const SizedBox(height: 10),
                        TextField(
                          controller: targetValueController,
                          decoration: const InputDecoration(
                            labelText: 'Nhập mã học sinh, ví dụ HS001',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.badge),
                          ),
                        ),
                      ],
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
                  onPressed: creating ? null : createNotification,
                  icon: creating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send),
                  label: Text(creating ? 'Đang gửi...' : 'Gửi'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> deleteNotification(String docId) async {
    if (!isAdmin) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Xóa thông báo'),
          content: const Text('Bạn có chắc muốn xóa thông báo này không?'),
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
      await db.collection('notifications').doc(docId).delete();
      showMsg('Đã xóa thông báo');
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
            width: 120,
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

  Widget buildNotificationCard(
    DocumentSnapshot doc,
    Map<String, dynamic> data,
    int index,
  ) {
    final title = data['title']?.toString() ?? '';
    final content = data['content']?.toString() ?? '';
    final targetType = data['targetType']?.toString() ?? 'all';
    final targetValue = data['targetValue']?.toString() ?? '';
    final createdBy = data['createdBy']?.toString() ?? '';
    final createdRole = data['createdRole']?.toString() ?? '';
    final createdAt = formatDateTime(data['createdAt']);

    return FutureBuilder<bool>(
      future: isRead(doc.id),
      builder: (context, readSnap) {
        final read = readSnap.data ?? false;

        return Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: read ? Colors.grey : Colors.blue,
              child: Icon(
                read ? Icons.mark_email_read : Icons.notifications,
                color: Colors.white,
              ),
            ),
            title: Text(
              title,
              style: TextStyle(
                fontWeight: read ? FontWeight.normal : FontWeight.bold,
              ),
            ),
            subtitle: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                Chip(
                  label: Text(read ? 'Đã đọc' : 'Chưa đọc'),
                  backgroundColor:
                      (read ? Colors.grey : Colors.blue).withOpacity(0.15),
                ),
                Chip(
                  label: Text(targetText(targetType, targetValue)),
                  backgroundColor: Colors.orange.withOpacity(0.12),
                ),
                if (createdAt.isNotEmpty)
                  Chip(
                    label: Text(createdAt),
                    backgroundColor: Colors.green.withOpacity(0.12),
                  ),
              ],
            ),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              const Divider(),
              infoRow('Nội dung', content),
              infoRow('Người gửi', createdBy),
              infoRow('Vai trò gửi', createdRole),
              infoRow('Đối tượng', targetText(targetType, targetValue)),
              infoRow('Ngày gửi', createdAt),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (!read)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => markAsRead(doc.id),
                        icon: const Icon(Icons.done),
                        label: const Text('Đánh dấu đã đọc'),
                      ),
                    ),
                  if (isAdmin) ...[
                    if (!read) const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => deleteNotification(doc.id),
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: const Text(
                          'Xóa thông báo',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<List<QueryDocumentSnapshot>> filterNotifications(
    List<QueryDocumentSnapshot> docs,
  ) async {
    final userClass = await loadStudentClass();

    final result = <QueryDocumentSnapshot>[];

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;

      final targetType = data['targetType']?.toString() ?? 'all';
      final targetValue = data['targetValue']?.toString() ?? '';

      bool visible = false;

      if (isAdmin) {
        visible = true;
      } else if (targetType == 'all') {
        visible = true;
      } else if (targetType == 'role') {
        visible = targetValue == widget.role;
      } else if (targetType == 'student') {
        visible = targetValue == currentStudentId;
      } else if (targetType == 'class') {
        visible = userClass.isNotEmpty && targetValue == userClass;
      }

      if (visible) {
        result.add(doc);
      }
    }

    result.sort((a, b) {
      final da = a.data() as Map<String, dynamic>;
      final dbb = b.data() as Map<String, dynamic>;

      final ta = da['createdAt'];
      final tb = dbb['createdAt'];

      final ma = ta is Timestamp ? ta.millisecondsSinceEpoch : 0;
      final mb = tb is Timestamp ? tb.millisecondsSinceEpoch : 0;

      return mb.compareTo(ma);
    });

    return result;
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
              onPressed: openCreateNotificationDialog,
              icon: const Icon(Icons.add),
              label: const Text('Tạo thông báo'),
            )
          : null,
      body: StreamBuilder<QuerySnapshot>(
        stream: notificationStream(),
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(child: Text('Lỗi tải thông báo'));
          }

          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return FutureBuilder<List<QueryDocumentSnapshot>>(
            future: filterNotifications(snap.data!.docs),
            builder: (context, filterSnap) {
              if (!filterSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = filterSnap.data!;

              if (docs.isEmpty) {
                return const Center(child: Text('Chưa có thông báo phù hợp'));
              }

              return ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 80),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final doc = docs[i];
                  final data = doc.data() as Map<String, dynamic>;

                  return buildNotificationCard(doc, data, i);
                },
              );
            },
          );
        },
      ),
    );
  }
}