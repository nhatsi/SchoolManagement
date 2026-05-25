import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SupportTicketPage extends StatefulWidget {
  final String role;
  final String email;
  final String studentId;

  const SupportTicketPage({
    Key? key,
    required this.role,
    required this.email,
    required this.studentId,
  }) : super(key: key);

  @override
  State<SupportTicketPage> createState() => _SupportTicketPageState();
}

class _SupportTicketPageState extends State<SupportTicketPage> {
  final db = FirebaseFirestore.instance;

  bool get isAdmin => widget.role == 'admin';
  bool get isTeacher => widget.role == 'teacher';
  bool get isStudent => widget.role == 'student';

  String get currentStudentId {
    if (widget.studentId.trim().isNotEmpty) return widget.studentId.trim();
    return 'HS001';
  }

  String pageTitle() {
    if (isAdmin) return 'Quản lý phản hồi';
    return 'Phản hồi / Hỗ trợ';
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

  String statusText(String status) {
    switch (status) {
      case 'pending':
        return 'Chờ xử lý';
      case 'processing':
        return 'Đang xử lý';
      case 'resolved':
        return 'Đã giải quyết';
      case 'rejected':
        return 'Từ chối';
      default:
        return status;
    }
  }

  Color statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Stream<QuerySnapshot> ticketStream() {
    if (isAdmin) {
      return db.collection('support_tickets').snapshots();
    }

    return db
        .collection('support_tickets')
        .where('createdBy', isEqualTo: widget.email)
        .snapshots();
  }

  Future<Map<String, String>> loadSenderInfo() async {
    if (!isStudent) {
      return {
        'senderName': widget.email,
        'className': '',
      };
    }

    String senderName = '';
    String className = '';

    try {
      final studentDoc = await db.collection('students').doc(currentStudentId).get();

      if (studentDoc.exists && studentDoc.data() != null) {
        final data = studentDoc.data()!;
        senderName = data['name']?.toString() ?? '';
        className = data['className']?.toString() ?? '';
      } else {
        final profileSnap = await db
            .collection('profiles')
            .where('studentId', isEqualTo: currentStudentId)
            .limit(1)
            .get();

        if (profileSnap.docs.isNotEmpty) {
          final data = profileSnap.docs.first.data();
          senderName = data['name']?.toString() ?? '';
          className = data['className']?.toString() ?? '';
        }
      }
    } catch (_) {}

    if (senderName.trim().isEmpty) {
      senderName = widget.email;
    }

    return {
      'senderName': senderName,
      'className': className,
    };
  }

  void openCreateTicketDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    String selectedCategory = 'Điểm số';
    bool creating = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> createTicket() async {
              final title = titleController.text.trim();
              final content = contentController.text.trim();

              if (title.isEmpty) {
                showMsg('Vui lòng nhập tiêu đề');
                return;
              }

              if (content.isEmpty) {
                showMsg('Vui lòng nhập nội dung phản hồi');
                return;
              }

              setDialogState(() {
                creating = true;
              });

              try {
                final info = await loadSenderInfo();

                await db.collection('support_tickets').add({
                  'title': title,
                  'content': content,
                  'category': selectedCategory,
                  'status': 'pending',
                  'adminReply': '',
                  'createdBy': widget.email,
                  'createdRole': widget.role,
                  'senderName': info['senderName'] ?? widget.email,
                  'studentId': isStudent ? currentStudentId : '',
                  'className': info['className'] ?? '',
                  'createdAt': FieldValue.serverTimestamp(),
                  'updatedAt': FieldValue.serverTimestamp(),
                  'handledBy': '',
                  'handledAt': null,
                });

                if (!mounted) return;
                Navigator.pop(context);
                showMsg('Đã gửi phản hồi');
              } catch (_) {
                showMsg('Không gửi được phản hồi');
              }

              if (mounted) {
                setDialogState(() {
                  creating = false;
                });
              }
            }

            return AlertDialog(
              title: const Text('Gửi phản hồi / yêu cầu hỗ trợ'),
              content: SizedBox(
                width: 460,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Loại phản hồi',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Điểm số',
                            child: Text('Điểm số'),
                          ),
                          DropdownMenuItem(
                            value: 'Điểm danh',
                            child: Text('Điểm danh'),
                          ),
                          DropdownMenuItem(
                            value: 'Học phí',
                            child: Text('Học phí'),
                          ),
                          DropdownMenuItem(
                            value: 'Thư viện',
                            child: Text('Thư viện'),
                          ),
                          DropdownMenuItem(
                            value: 'Tài khoản',
                            child: Text('Tài khoản'),
                          ),
                          DropdownMenuItem(
                            value: 'Khác',
                            child: Text('Khác'),
                          ),
                        ],
                        onChanged: creating
                            ? null
                            : (value) {
                                if (value != null) {
                                  setDialogState(() {
                                    selectedCategory = value;
                                  });
                                }
                              },
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
                        minLines: 5,
                        maxLines: 8,
                        decoration: const InputDecoration(
                          labelText: 'Nội dung',
                          hintText: 'Ví dụ: Em muốn hỏi lại điểm giữa kỳ môn Toán...',
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
                  onPressed: creating ? null : () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                ElevatedButton.icon(
                  onPressed: creating ? null : createTicket,
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

  void openHandleTicketDialog(DocumentSnapshot doc) {
    if (!isAdmin) return;

    final data = doc.data() as Map<String, dynamic>;

    final replyController = TextEditingController(
      text: data['adminReply']?.toString() ?? '',
    );

    String selectedStatus = data['status']?.toString() ?? 'pending';

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> saveHandle() async {
              final reply = replyController.text.trim();

              await db.collection('support_tickets').doc(doc.id).update({
                'status': selectedStatus,
                'adminReply': reply,
                'handledBy': widget.email,
                'handledAt': FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
              });

              if (!mounted) return;
              Navigator.pop(context);
              showMsg('Đã cập nhật xử lý phản hồi');
            }

            return AlertDialog(
              title: const Text('Xử lý phản hồi'),
              content: SizedBox(
                width: 460,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Trạng thái xử lý',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.info),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'pending',
                          child: Text('Chờ xử lý'),
                        ),
                        DropdownMenuItem(
                          value: 'processing',
                          child: Text('Đang xử lý'),
                        ),
                        DropdownMenuItem(
                          value: 'resolved',
                          child: Text('Đã giải quyết'),
                        ),
                        DropdownMenuItem(
                          value: 'rejected',
                          child: Text('Từ chối'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedStatus = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: replyController,
                      minLines: 4,
                      maxLines: 7,
                      decoration: const InputDecoration(
                        labelText: 'Phản hồi của admin',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.reply),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                ElevatedButton.icon(
                  onPressed: saveHandle,
                  icon: const Icon(Icons.save),
                  label: const Text('Lưu xử lý'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> deleteTicket(DocumentSnapshot doc) async {
    if (!isAdmin) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Xóa phản hồi'),
          content: const Text('Bạn có chắc muốn xóa phản hồi này không?'),
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
      await db.collection('support_tickets').doc(doc.id).delete();
      showMsg('Đã xóa phản hồi');
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

  Widget buildTicketCard(DocumentSnapshot doc, int index) {
    final data = doc.data() as Map<String, dynamic>;

    final title = data['title']?.toString() ?? '';
    final content = data['content']?.toString() ?? '';
    final category = data['category']?.toString() ?? '';
    final status = data['status']?.toString() ?? 'pending';
    final adminReply = data['adminReply']?.toString() ?? '';
    final createdBy = data['createdBy']?.toString() ?? '';
    final createdRole = data['createdRole']?.toString() ?? '';
    final senderName = data['senderName']?.toString() ?? '';
    final studentId = data['studentId']?.toString() ?? '';
    final className = data['className']?.toString() ?? '';
    final createdAt = formatDateTime(data['createdAt']);
    final handledBy = data['handledBy']?.toString() ?? '';
    final handledAt = formatDateTime(data['handledAt']);

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: statusColor(status),
          child: Text(
            '${index + 1}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            Chip(
              label: Text(statusText(status)),
              backgroundColor: statusColor(status).withOpacity(0.15),
              labelStyle: TextStyle(
                color: statusColor(status),
                fontWeight: FontWeight.bold,
              ),
            ),
            if (category.isNotEmpty)
              Chip(
                label: Text(category),
                backgroundColor: Colors.blue.withOpacity(0.12),
              ),
            if (createdAt.isNotEmpty)
              Chip(
                label: Text(createdAt),
                backgroundColor: Colors.grey.withOpacity(0.15),
              ),
          ],
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const Divider(),
          infoRow('Người gửi', senderName.isNotEmpty ? senderName : createdBy),
          infoRow('Email', createdBy),
          infoRow('Vai trò', createdRole),
          infoRow('Mã học sinh', studentId),
          infoRow('Lớp', className),
          infoRow('Loại', category),
          infoRow('Nội dung', content),
          if (adminReply.isNotEmpty) infoRow('Admin trả lời', adminReply),
          infoRow('Ngày gửi', createdAt),
          infoRow('Người xử lý', handledBy),
          infoRow('Ngày xử lý', handledAt),
          if (isAdmin) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => openHandleTicketDialog(doc),
                    icon: const Icon(Icons.edit),
                    label: const Text('Xử lý'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => deleteTicket(doc),
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

  Widget buildSummary(List<QueryDocumentSnapshot> docs) {
    final pending = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['status'] == 'pending';
    }).length;

    final processing = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['status'] == 'processing';
    }).length;

    final resolved = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['status'] == 'resolved';
    }).length;

    final rejected = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['status'] == 'rejected';
    }).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Row(
        children: [
          summaryBox('Tổng', docs.length.toString(), Colors.blue),
          const SizedBox(width: 8),
          summaryBox('Chờ', pending.toString(), Colors.orange),
          const SizedBox(width: 8),
          summaryBox('Đang xử lý', processing.toString(), Colors.blue),
          const SizedBox(width: 8),
          summaryBox('Xong', resolved.toString(), Colors.green),
          const SizedBox(width: 8),
          summaryBox('Từ chối', rejected.toString(), Colors.red),
        ],
      ),
    );
  }

  Widget summaryBox(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canCreate = !isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: Text(pageTitle()),
        backgroundColor: Colors.blue,
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: openCreateTicketDialog,
              icon: const Icon(Icons.add),
              label: const Text('Gửi phản hồi'),
            )
          : null,
      body: StreamBuilder<QuerySnapshot>(
        stream: ticketStream(),
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(child: Text('Lỗi tải danh sách phản hồi'));
          }

          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs.toList();

          docs.sort((a, b) {
            final da = a.data() as Map<String, dynamic>;
            final dbb = b.data() as Map<String, dynamic>;

            final ta = da['createdAt'];
            final tb = dbb['createdAt'];

            final ma = ta is Timestamp ? ta.millisecondsSinceEpoch : 0;
            final mb = tb is Timestamp ? tb.millisecondsSinceEpoch : 0;

            return mb.compareTo(ma);
          });

          if (docs.isEmpty) {
            return Center(
              child: Text(
                isAdmin
                    ? 'Chưa có phản hồi nào'
                    : 'Bạn chưa gửi phản hồi nào',
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
                    return buildTicketCard(docs[i], i);
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