import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FeeManagementPage extends StatefulWidget {
  final String role;
  final String email;
  final String studentId;

  const FeeManagementPage({
    Key? key,
    required this.role,
    required this.email,
    required this.studentId,
  }) : super(key: key);

  @override
  State<FeeManagementPage> createState() => _FeeManagementPageState();
}

class _FeeManagementPageState extends State<FeeManagementPage> {
  final db = FirebaseFirestore.instance;

  bool get isAdmin => widget.role == 'admin';
  bool get isTeacher => widget.role == 'teacher';
  bool get isStudent => widget.role == 'student';

  String get currentStudentId {
    if (widget.studentId.trim().isNotEmpty) return widget.studentId.trim();
    return 'HS001';
  }

  String pageTitle() {
    if (isStudent) return 'Học phí của tôi';
    return 'Quản lý học phí';
  }

  void showMsg(String msg) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  double parseMoney(String value) {
    final clean = value.replaceAll(',', '').replaceAll('.', '');
    return double.tryParse(clean) ?? 0;
  }

  String moneyText(dynamic value) {
    final number = value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
    return number.toStringAsFixed(0);
  }

  String statusText(String status) {
    switch (status) {
      case 'unpaid':
        return 'Chưa đóng';
      case 'paid':
        return 'Đã đóng';
      case 'partial':
        return 'Đóng một phần';
      case 'overdue':
        return 'Quá hạn';
      default:
        return status;
    }
  }

  Color statusColor(String status) {
    switch (status) {
      case 'paid':
        return Colors.green;
      case 'partial':
        return Colors.blue;
      case 'overdue':
        return Colors.red;
      case 'unpaid':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Stream<QuerySnapshot> feeItemStream() {
    return db.collection('fee_items').snapshots();
  }

  Stream<QuerySnapshot> studentFeeStream() {
    if (isStudent) {
      return db
          .collection('student_fees')
          .where('studentId', isEqualTo: currentStudentId)
          .snapshots();
    }

    return db.collection('student_fees').snapshots();
  }

  Future<List<QueryDocumentSnapshot>> loadStudentsByClass(String className) async {
    final snap = await db
        .collection('students')
        .where('className', isEqualTo: className)
        .get();

    return snap.docs;
  }

  void openCreateFeeItemDialog() {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final classController = TextEditingController();
    final dueDateController = TextEditingController();
    final schoolYearController = TextEditingController(text: '2025-2026');

    bool creating = false;

    String formatDate(DateTime date) {
      final y = date.year.toString().padLeft(4, '0');
      final m = date.month.toString().padLeft(2, '0');
      final d = date.day.toString().padLeft(2, '0');
      return '$y-$m-$d';
    }

    Future<void> pickDueDate() async {
      final picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
      );

      if (picked != null) {
        dueDateController.text = formatDate(picked);
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> createFeeItem() async {
              final name = nameController.text.trim();
              final amount = parseMoney(amountController.text.trim());
              final className = classController.text.trim();
              final dueDate = dueDateController.text.trim();
              final schoolYear = schoolYearController.text.trim();

              if (name.isEmpty) {
                showMsg('Vui lòng nhập tên khoản thu');
                return;
              }

              if (amount <= 0) {
                showMsg('Số tiền phải lớn hơn 0');
                return;
              }

              if (className.isEmpty) {
                showMsg('Vui lòng nhập lớp');
                return;
              }

              if (dueDate.isEmpty) {
                showMsg('Vui lòng chọn hạn đóng');
                return;
              }

              setDialogState(() {
                creating = true;
              });

              try {
                final students = await loadStudentsByClass(className);

                if (students.isEmpty) {
                  setDialogState(() {
                    creating = false;
                  });
                  showMsg('Không tìm thấy học sinh thuộc lớp $className');
                  return;
                }

                final feeItemRef = db.collection('fee_items').doc();
                final batch = db.batch();

                batch.set(feeItemRef, {
                  'id': feeItemRef.id,
                  'name': name,
                  'amount': amount,
                  'className': className,
                  'dueDate': dueDate,
                  'schoolYear': schoolYear,
                  'createdBy': widget.email,
                  'createdAt': FieldValue.serverTimestamp(),
                });

                for (final studentDoc in students) {
                  final student = studentDoc.data() as Map<String, dynamic>;

                  final sid = student['studentId']?.toString().isNotEmpty == true
                      ? student['studentId'].toString()
                      : student['id']?.toString() ?? studentDoc.id;

                  final studentName = student['name']?.toString() ?? '';

                  final studentFeeId = '${feeItemRef.id}_$sid';
                  final studentFeeRef =
                      db.collection('student_fees').doc(studentFeeId);

                  batch.set(studentFeeRef, {
                    'id': studentFeeId,
                    'feeItemId': feeItemRef.id,
                    'feeName': name,
                    'studentId': sid,
                    'studentName': studentName,
                    'className': className,
                    'amount': amount,
                    'paidAmount': 0,
                    'status': 'unpaid',
                    'dueDate': dueDate,
                    'schoolYear': schoolYear,
                    'paymentMethod': '',
                    'note': '',
                    'paidAt': null,
                    'createdBy': widget.email,
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                }

                await batch.commit();

                if (!mounted) return;
                Navigator.pop(context);
                showMsg('Đã tạo khoản thu và sinh học phí cho ${students.length} học sinh');
              } catch (_) {
                showMsg('Không tạo được khoản thu');
              }

              if (mounted) {
                setDialogState(() {
                  creating = false;
                });
              }
            }

            return AlertDialog(
              title: const Text('Tạo khoản thu học phí'),
              content: SizedBox(
                width: 430,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Tên khoản thu, ví dụ Học phí tháng 9',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.payments),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Số tiền',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                      ),
                      const SizedBox(height: 10),
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
                        controller: dueDateController,
                        readOnly: true,
                        onTap: pickDueDate,
                        decoration: const InputDecoration(
                          labelText: 'Hạn đóng',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_month),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: schoolYearController,
                        decoration: const InputDecoration(
                          labelText: 'Năm học',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.school),
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
                  onPressed: creating ? null : createFeeItem,
                  icon: creating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(creating ? 'Đang tạo...' : 'Tạo'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void openUpdatePaymentDialog(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final amountRaw = data['amount'];
    final amount = amountRaw is num ? amountRaw.toDouble() : double.tryParse('$amountRaw') ?? 0;

    final paidController = TextEditingController(
      text: moneyText(data['paidAmount'] ?? 0),
    );
    final methodController = TextEditingController(
      text: data['paymentMethod']?.toString() ?? '',
    );
    final noteController = TextEditingController(
      text: data['note']?.toString() ?? '',
    );

    String selectedStatus = data['status']?.toString() ?? 'unpaid';

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> savePayment() async {
              final paidAmount = parseMoney(paidController.text.trim());
              final method = methodController.text.trim();
              final note = noteController.text.trim();

              if (paidAmount < 0) {
                showMsg('Số tiền đã đóng không hợp lệ');
                return;
              }

              String finalStatus = selectedStatus;

              if (paidAmount >= amount) {
                finalStatus = 'paid';
              } else if (paidAmount > 0) {
                finalStatus = 'partial';
              }

              await db.collection('student_fees').doc(doc.id).update({
                'paidAmount': paidAmount,
                'status': finalStatus,
                'paymentMethod': method,
                'note': note,
                'paidAt': finalStatus == 'paid' ? FieldValue.serverTimestamp() : null,
                'updatedBy': widget.email,
                'updatedAt': FieldValue.serverTimestamp(),
              });

              if (!mounted) return;
              Navigator.pop(context);
              showMsg('Đã cập nhật thanh toán');
            }

            return AlertDialog(
              title: const Text('Cập nhật thanh toán'),
              content: SizedBox(
                width: 430,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${data['studentName'] ?? ''} - ${data['feeName'] ?? ''}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: paidController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Đã đóng / Tổng ${moneyText(amount)}',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.attach_money),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Trạng thái',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.info),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'unpaid', child: Text('Chưa đóng')),
                        DropdownMenuItem(value: 'partial', child: Text('Đóng một phần')),
                        DropdownMenuItem(value: 'paid', child: Text('Đã đóng')),
                        DropdownMenuItem(value: 'overdue', child: Text('Quá hạn')),
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
                      controller: methodController,
                      decoration: const InputDecoration(
                        labelText: 'Phương thức, ví dụ Tiền mặt/Chuyển khoản',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.account_balance_wallet),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: noteController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Ghi chú',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.note),
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
                  onPressed: savePayment,
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

  Future<void> deleteFeeItem(DocumentSnapshot doc) async {
    if (!isAdmin) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Xóa khoản thu'),
          content: const Text(
            'Chỉ xóa khoản thu gốc. Các học phí đã sinh cho học sinh vẫn còn trong student_fees.',
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
      await db.collection('fee_items').doc(doc.id).delete();
      showMsg('Đã xóa khoản thu');
    }
  }

  Widget buildFeeItemList() {
    return StreamBuilder<QuerySnapshot>(
      stream: feeItemStream(),
      builder: (context, snap) {
        if (snap.hasError) {
          return const Center(child: Text('Lỗi tải khoản thu'));
        }

        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data!.docs.toList();

        docs.sort((a, b) {
          final da = a.data() as Map<String, dynamic>;
          final dbb = b.data() as Map<String, dynamic>;
          return (dbb['createdAt']?.toString() ?? '').compareTo(da['createdAt']?.toString() ?? '');
        });

        if (docs.isEmpty) {
          return const Center(child: Text('Chưa có khoản thu nào'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final doc = docs[i];
            final data = doc.data() as Map<String, dynamic>;

            final name = data['name']?.toString() ?? '';
            final className = data['className']?.toString() ?? '';
            final amount = data['amount'];
            final dueDate = data['dueDate']?.toString() ?? '';
            final schoolYear = data['schoolYear']?.toString() ?? '';

            return Card(
              elevation: 3,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Lớp: $className | Số tiền: ${moneyText(amount)} | Hạn: $dueDate | Năm học: $schoolYear',
                ),
                trailing: isAdmin
                    ? IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => deleteFeeItem(doc),
                      )
                    : null,
              ),
            );
          },
        );
      },
    );
  }

  Widget buildStudentFeeList() {
    return StreamBuilder<QuerySnapshot>(
      stream: studentFeeStream(),
      builder: (context, snap) {
        if (snap.hasError) {
          return const Center(child: Text('Lỗi tải học phí'));
        }

        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data!.docs.toList();

        docs.sort((a, b) {
          final da = a.data() as Map<String, dynamic>;
          final dbb = b.data() as Map<String, dynamic>;
          return (da['studentName']?.toString() ?? '').compareTo(dbb['studentName']?.toString() ?? '');
        });

        if (docs.isEmpty) {
          return Center(
            child: Text(isStudent ? 'Bạn chưa có khoản học phí nào' : 'Chưa có học phí học sinh'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final doc = docs[i];
            final data = doc.data() as Map<String, dynamic>;

            final feeName = data['feeName']?.toString() ?? '';
            final studentName = data['studentName']?.toString() ?? '';
            final studentId = data['studentId']?.toString() ?? '';
            final className = data['className']?.toString() ?? '';
            final amount = data['amount'];
            final paidAmount = data['paidAmount'];
            final status = data['status']?.toString() ?? 'unpaid';
            final dueDate = data['dueDate']?.toString() ?? '';
            final method = data['paymentMethod']?.toString() ?? '';
            final note = data['note']?.toString() ?? '';

            return Card(
              elevation: 3,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: statusColor(status),
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(
                  isStudent ? feeName : '$studentName - $feeName',
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
                    Chip(label: Text('Tổng: ${moneyText(amount)}')),
                    Chip(label: Text('Đã đóng: ${moneyText(paidAmount)}')),
                    Chip(label: Text('Hạn: $dueDate')),
                  ],
                ),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  const Divider(),
                  infoRow('Mã học sinh', studentId),
                  infoRow('Tên học sinh', studentName),
                  infoRow('Lớp', className),
                  infoRow('Khoản thu', feeName),
                  infoRow('Số tiền', moneyText(amount)),
                  infoRow('Đã đóng', moneyText(paidAmount)),
                  infoRow('Trạng thái', statusText(status)),
                  infoRow('Hạn đóng', dueDate),
                  if (method.isNotEmpty) infoRow('Phương thức', method),
                  if (note.isNotEmpty) infoRow('Ghi chú', note),
                  if (isAdmin) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => openUpdatePaymentDialog(doc),
                        icon: const Icon(Icons.edit),
                        label: const Text('Cập nhật thanh toán'),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
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
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isStudent) {
      return Scaffold(
        appBar: AppBar(
          title: Text(pageTitle()),
          backgroundColor: Colors.blue,
        ),
        body: buildStudentFeeList(),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(pageTitle()),
          backgroundColor: Colors.blue,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.receipt_long), text: 'Khoản thu'),
              Tab(icon: Icon(Icons.people), text: 'Học sinh đóng phí'),
            ],
          ),
        ),
        floatingActionButton: isAdmin
            ? FloatingActionButton.extended(
                onPressed: openCreateFeeItemDialog,
                icon: const Icon(Icons.add),
                label: const Text('Tạo khoản thu'),
              )
            : null,
        body: TabBarView(
          children: [
            buildFeeItemList(),
            buildStudentFeeList(),
          ],
        ),
      ),
    );
  }
}