import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LibraryManagementPage extends StatefulWidget {
  final String role;
  final String email;
  final String studentId;

  const LibraryManagementPage({
    Key? key,
    required this.role,
    required this.email,
    required this.studentId,
  }) : super(key: key);

  @override
  State<LibraryManagementPage> createState() => _LibraryManagementPageState();
}

class _LibraryManagementPageState extends State<LibraryManagementPage> {
  final db = FirebaseFirestore.instance;

  bool get isAdmin => widget.role == 'admin';
  bool get isTeacher => widget.role == 'teacher';
  bool get isStudent => widget.role == 'student';

  String get currentStudentId {
    if (widget.studentId.trim().isNotEmpty) return widget.studentId.trim();
    return 'HS001';
  }

  String pageTitle() {
    if (isStudent) return 'Thư viện của tôi';
    if (isTeacher) return 'Thư viện';
    return 'Quản lý thư viện';
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

  String todayText() {
    return formatDate(DateTime.now());
  }

  String defaultDueDateText() {
    return formatDate(DateTime.now().add(const Duration(days: 7)));
  }

  int parseInt(String value) {
    return int.tryParse(value.trim()) ?? 0;
  }

  double parseMoney(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.')) ?? 0;
  }

  String moneyText(dynamic value) {
    final number = value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
    return number.toStringAsFixed(0);
  }

  Stream<QuerySnapshot> bookStream() {
    return db.collection('books').snapshots();
  }

  Stream<QuerySnapshot> borrowStream() {
    if (isStudent) {
      return db
          .collection('borrow_records')
          .where('studentId', isEqualTo: currentStudentId)
          .snapshots();
    }

    return db.collection('borrow_records').snapshots();
  }

  String statusText(String status) {
    switch (status) {
      case 'pending':
        return 'Chờ duyệt';
      case 'borrowing':
        return 'Đang mượn';
      case 'returned':
        return 'Đã trả';
      case 'rejected':
        return 'Từ chối';
      case 'overdue':
        return 'Quá hạn';
      default:
        return status;
    }
  }

  Color statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'borrowing':
        return Colors.blue;
      case 'returned':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'overdue':
        return Colors.deepOrange;
      default:
        return Colors.grey;
    }
  }

  Future<Map<String, String>> loadStudentInfo() async {
    String studentName = '';
    String className = '';

    try {
      final studentDoc = await db.collection('students').doc(currentStudentId).get();

      if (studentDoc.exists && studentDoc.data() != null) {
        final data = studentDoc.data()!;
        studentName = data['name']?.toString() ?? '';
        className = data['className']?.toString() ?? '';
      } else {
        final profileSnap = await db
            .collection('profiles')
            .where('studentId', isEqualTo: currentStudentId)
            .limit(1)
            .get();

        if (profileSnap.docs.isNotEmpty) {
          final data = profileSnap.docs.first.data();
          studentName = data['name']?.toString() ?? '';
          className = data['className']?.toString() ?? '';
        }
      }
    } catch (_) {}

    if (studentName.trim().isEmpty) {
      studentName = widget.email;
    }

    return {
      'studentName': studentName,
      'className': className,
    };
  }

  Future<bool> hasActiveBorrow(String bookId) async {
    final snap = await db
        .collection('borrow_records')
        .where('studentId', isEqualTo: currentStudentId)
        .where('bookId', isEqualTo: bookId)
        .get();

    for (final doc in snap.docs) {
      final data = doc.data();
      final status = data['status']?.toString() ?? '';

      if (status == 'pending' || status == 'borrowing' || status == 'overdue') {
        return true;
      }
    }

    return false;
  }

  void openCreateBookDialog() {
    if (!isAdmin) return;

    final titleController = TextEditingController();
    final authorController = TextEditingController();
    final categoryController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    final noteController = TextEditingController();

    bool creating = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> createBook() async {
              final title = titleController.text.trim();
              final author = authorController.text.trim();
              final category = categoryController.text.trim();
              final quantity = parseInt(quantityController.text);
              final note = noteController.text.trim();

              if (title.isEmpty) {
                showMsg('Vui lòng nhập tên sách');
                return;
              }

              if (quantity <= 0) {
                showMsg('Số lượng sách phải lớn hơn 0');
                return;
              }

              setDialogState(() {
                creating = true;
              });

              try {
                final bookRef = db.collection('books').doc();

                await bookRef.set({
                  'id': bookRef.id,
                  'title': title,
                  'author': author,
                  'category': category,
                  'quantity': quantity,
                  'availableQuantity': quantity,
                  'note': note,
                  'createdBy': widget.email,
                  'createdAt': FieldValue.serverTimestamp(),
                });

                if (!mounted) return;
                Navigator.pop(context);
                showMsg('Đã thêm sách vào thư viện');
              } catch (_) {
                showMsg('Không thêm được sách');
              }

              if (mounted) {
                setDialogState(() {
                  creating = false;
                });
              }
            }

            return AlertDialog(
              title: const Text('Thêm sách'),
              content: SizedBox(
                width: 430,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Tên sách',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.menu_book),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: authorController,
                        decoration: const InputDecoration(
                          labelText: 'Tác giả',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: categoryController,
                        decoration: const InputDecoration(
                          labelText: 'Thể loại',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Số lượng',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.numbers),
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
              ),
              actions: [
                TextButton(
                  onPressed: creating ? null : () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                ElevatedButton.icon(
                  onPressed: creating ? null : createBook,
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
                  label: Text(creating ? 'Đang lưu...' : 'Lưu'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> requestBorrow(DocumentSnapshot bookDoc) async {
    if (!isStudent) return;

    final book = bookDoc.data() as Map<String, dynamic>;

    final title = book['title']?.toString() ?? '';
    final availableRaw = book['availableQuantity'];
    final available = availableRaw is num ? availableRaw.toInt() : parseInt('$availableRaw');

    if (available <= 0) {
      showMsg('Sách này hiện đã hết');
      return;
    }

    final active = await hasActiveBorrow(bookDoc.id);

    if (active) {
      showMsg('Bạn đang có yêu cầu mượn hoặc đang mượn sách này');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Yêu cầu mượn sách'),
          content: Text('Bạn có muốn gửi yêu cầu mượn sách "$title" không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Gửi yêu cầu'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      final info = await loadStudentInfo();

      await db.collection('borrow_records').add({
        'bookId': bookDoc.id,
        'bookTitle': title,
        'bookAuthor': book['author']?.toString() ?? '',
        'studentId': currentStudentId,
        'studentName': info['studentName'] ?? '',
        'className': info['className'] ?? '',
        'requestDate': todayText(),
        'borrowDate': '',
        'dueDate': '',
        'returnDate': '',
        'status': 'pending',
        'fineAmount': 0,
        'note': '',
        'createdBy': widget.email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      showMsg('Đã gửi yêu cầu mượn sách');
    } catch (_) {
      showMsg('Không gửi được yêu cầu mượn');
    }
  }

  Future<void> approveBorrow(DocumentSnapshot borrowDoc) async {
    if (!isAdmin) return;

    final data = borrowDoc.data() as Map<String, dynamic>;
    final bookId = data['bookId']?.toString() ?? '';

    if (bookId.isEmpty) {
      showMsg('Không tìm thấy mã sách');
      return;
    }

    final dueController = TextEditingController(text: defaultDueDateText());

    await showDialog(
      context: context,
      builder: (_) {
        Future<void> saveApprove() async {
          final dueDate = dueController.text.trim();

          if (dueDate.isEmpty) {
            showMsg('Vui lòng nhập hạn trả');
            return;
          }

          try {
            final bookRef = db.collection('books').doc(bookId);
            final borrowRef = db.collection('borrow_records').doc(borrowDoc.id);

            await db.runTransaction((transaction) async {
              final bookSnap = await transaction.get(bookRef);

              if (!bookSnap.exists || bookSnap.data() == null) {
                throw Exception('book-not-found');
              }

              final bookData = bookSnap.data() as Map<String, dynamic>;
              final availableRaw = bookData['availableQuantity'];
              final available = availableRaw is num
                  ? availableRaw.toInt()
                  : parseInt('$availableRaw');

              if (available <= 0) {
                throw Exception('no-book-left');
              }

              transaction.update(bookRef, {
                'availableQuantity': available - 1,
              });

              transaction.update(borrowRef, {
                'status': 'borrowing',
                'borrowDate': todayText(),
                'dueDate': dueDate,
                'approvedBy': widget.email,
                'approvedAt': FieldValue.serverTimestamp(),
              });
            });

            if (!mounted) return;
            Navigator.pop(context);
            showMsg('Đã duyệt yêu cầu mượn sách');
          } catch (_) {
            showMsg('Không duyệt được. Có thể sách đã hết.');
          }
        }

        return AlertDialog(
          title: const Text('Duyệt mượn sách'),
          content: TextField(
            controller: dueController,
            decoration: const InputDecoration(
              labelText: 'Hạn trả, ví dụ 2026-05-31',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.calendar_month),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton.icon(
              onPressed: saveApprove,
              icon: const Icon(Icons.check),
              label: const Text('Duyệt'),
            ),
          ],
        );
      },
    );
  }

  Future<void> rejectBorrow(DocumentSnapshot borrowDoc) async {
    if (!isAdmin) return;

    final noteController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) {
        Future<void> saveReject() async {
          await db.collection('borrow_records').doc(borrowDoc.id).update({
            'status': 'rejected',
            'note': noteController.text.trim(),
            'rejectedBy': widget.email,
            'rejectedAt': FieldValue.serverTimestamp(),
          });

          if (!mounted) return;
          Navigator.pop(context);
          showMsg('Đã từ chối yêu cầu mượn');
        }

        return AlertDialog(
          title: const Text('Từ chối yêu cầu mượn'),
          content: TextField(
            controller: noteController,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Lý do từ chối',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton.icon(
              onPressed: saveReject,
              icon: const Icon(Icons.close),
              label: const Text('Từ chối'),
            ),
          ],
        );
      },
    );
  }

  Future<void> returnBook(DocumentSnapshot borrowDoc) async {
    if (!isAdmin) return;

    final data = borrowDoc.data() as Map<String, dynamic>;
    final bookId = data['bookId']?.toString() ?? '';

    final fineController = TextEditingController(text: '0');
    final noteController = TextEditingController(text: data['note']?.toString() ?? '');

    await showDialog(
      context: context,
      builder: (_) {
        Future<void> saveReturn() async {
          final fine = parseMoney(fineController.text);
          final note = noteController.text.trim();

          try {
            final bookRef = db.collection('books').doc(bookId);
            final borrowRef = db.collection('borrow_records').doc(borrowDoc.id);

            await db.runTransaction((transaction) async {
              final bookSnap = await transaction.get(bookRef);

              if (bookSnap.exists && bookSnap.data() != null) {
                final bookData = bookSnap.data() as Map<String, dynamic>;

                final availableRaw = bookData['availableQuantity'];
                final quantityRaw = bookData['quantity'];

                final available = availableRaw is num
                    ? availableRaw.toInt()
                    : parseInt('$availableRaw');

                final quantity = quantityRaw is num
                    ? quantityRaw.toInt()
                    : parseInt('$quantityRaw');

                final newAvailable =
                    available + 1 > quantity ? quantity : available + 1;

                transaction.update(bookRef, {
                  'availableQuantity': newAvailable,
                });
              }

              transaction.update(borrowRef, {
                'status': 'returned',
                'returnDate': todayText(),
                'fineAmount': fine,
                'note': note,
                'returnedBy': widget.email,
                'returnedAt': FieldValue.serverTimestamp(),
              });
            });

            if (!mounted) return;
            Navigator.pop(context);
            showMsg('Đã trả sách');
          } catch (_) {
            showMsg('Không cập nhật trả sách được');
          }
        }

        return AlertDialog(
          title: const Text('Trả sách'),
          content: SizedBox(
            width: 430,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: fineController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Tiền phạt nếu có',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.money),
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton.icon(
              onPressed: saveReturn,
              icon: const Icon(Icons.assignment_return),
              label: const Text('Xác nhận trả'),
            ),
          ],
        );
      },
    );
  }

  Future<void> markOverdue(DocumentSnapshot borrowDoc) async {
    if (!isAdmin) return;

    await db.collection('borrow_records').doc(borrowDoc.id).update({
      'status': 'overdue',
      'updatedBy': widget.email,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    showMsg('Đã chuyển trạng thái quá hạn');
  }

  Future<void> deleteBook(DocumentSnapshot bookDoc) async {
    if (!isAdmin) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Xóa sách'),
          content: const Text('Bạn có chắc muốn xóa sách này không?'),
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
      await db.collection('books').doc(bookDoc.id).delete();
      showMsg('Đã xóa sách');
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

  Widget buildBookList() {
    return StreamBuilder<QuerySnapshot>(
      stream: bookStream(),
      builder: (context, snap) {
        if (snap.hasError) {
          return const Center(child: Text('Lỗi tải danh sách sách'));
        }

        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data!.docs.toList();

        docs.sort((a, b) {
          final da = a.data() as Map<String, dynamic>;
          final dbb = b.data() as Map<String, dynamic>;
          return (da['title']?.toString() ?? '')
              .compareTo(dbb['title']?.toString() ?? '');
        });

        if (docs.isEmpty) {
          return const Center(child: Text('Chưa có sách nào trong thư viện'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final doc = docs[i];
            final data = doc.data() as Map<String, dynamic>;

            final title = data['title']?.toString() ?? '';
            final author = data['author']?.toString() ?? '';
            final category = data['category']?.toString() ?? '';
            final quantityRaw = data['quantity'];
            final availableRaw = data['availableQuantity'];

            final quantity = quantityRaw is num ? quantityRaw.toInt() : parseInt('$quantityRaw');
            final available =
                availableRaw is num ? availableRaw.toInt() : parseInt('$availableRaw');

            return Card(
              elevation: 3,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: available > 0 ? Colors.blue : Colors.grey,
                  child: Text(
                    '${i + 1}',
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
                    if (author.isNotEmpty) Chip(label: Text('Tác giả: $author')),
                    if (category.isNotEmpty) Chip(label: Text('Loại: $category')),
                    Chip(label: Text('Còn: $available/$quantity')),
                  ],
                ),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  const Divider(),
                  infoRow('Tên sách', title),
                  infoRow('Tác giả', author),
                  infoRow('Thể loại', category),
                  infoRow('Số lượng', '$quantity'),
                  infoRow('Còn lại', '$available'),
                  const SizedBox(height: 12),
                  if (isStudent)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: available > 0 ? () => requestBorrow(doc) : null,
                        icon: const Icon(Icons.library_add),
                        label: Text(available > 0 ? 'Yêu cầu mượn' : 'Đã hết sách'),
                      ),
                    ),
                  if (isAdmin)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => deleteBook(doc),
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: const Text(
                          'Xóa sách',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget buildBorrowList() {
    return StreamBuilder<QuerySnapshot>(
      stream: borrowStream(),
      builder: (context, snap) {
        if (snap.hasError) {
          return const Center(child: Text('Lỗi tải danh sách mượn sách'));
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
              isStudent
                  ? 'Bạn chưa có yêu cầu mượn sách nào'
                  : 'Chưa có yêu cầu mượn sách nào',
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final doc = docs[i];
            final data = doc.data() as Map<String, dynamic>;

            final bookTitle = data['bookTitle']?.toString() ?? '';
            final author = data['bookAuthor']?.toString() ?? '';
            final studentId = data['studentId']?.toString() ?? '';
            final studentName = data['studentName']?.toString() ?? '';
            final className = data['className']?.toString() ?? '';
            final requestDate = data['requestDate']?.toString() ?? '';
            final borrowDate = data['borrowDate']?.toString() ?? '';
            final dueDate = data['dueDate']?.toString() ?? '';
            final returnDate = data['returnDate']?.toString() ?? '';
            final status = data['status']?.toString() ?? 'pending';
            final fine = data['fineAmount'];
            final note = data['note']?.toString() ?? '';

            return Card(
              elevation: 3,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: statusColor(status),
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(
                  isStudent ? bookTitle : '$studentName - $bookTitle',
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
                    if (className.isNotEmpty) Chip(label: Text('Lớp: $className')),
                    if (dueDate.isNotEmpty) Chip(label: Text('Hạn trả: $dueDate')),
                  ],
                ),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  const Divider(),
                  infoRow('Tên sách', bookTitle),
                  infoRow('Tác giả', author),
                  infoRow('Mã học sinh', studentId),
                  infoRow('Tên học sinh', studentName),
                  infoRow('Lớp', className),
                  infoRow('Ngày yêu cầu', requestDate),
                  infoRow('Ngày mượn', borrowDate),
                  infoRow('Hạn trả', dueDate),
                  infoRow('Ngày trả', returnDate),
                  infoRow('Trạng thái', statusText(status)),
                  infoRow('Tiền phạt', moneyText(fine)),
                  infoRow('Ghi chú', note),
                  if (isAdmin && status == 'pending') ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => approveBorrow(doc),
                            icon: const Icon(Icons.check),
                            label: const Text('Duyệt'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => rejectBorrow(doc),
                            icon: const Icon(Icons.close),
                            label: const Text('Từ chối'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (isAdmin && (status == 'borrowing' || status == 'overdue')) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => returnBook(doc),
                            icon: const Icon(Icons.assignment_return),
                            label: const Text('Trả sách'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (status == 'borrowing')
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => markOverdue(doc),
                              icon: const Icon(Icons.warning, color: Colors.deepOrange),
                              label: const Text(
                                'Quá hạn',
                                style: TextStyle(color: Colors.deepOrange),
                              ),
                            ),
                          ),
                      ],
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

  @override
  Widget build(BuildContext context) {
    if (isStudent) {
      return DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: Text(pageTitle()),
            backgroundColor: Colors.blue,
            bottom: const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.menu_book), text: 'Sách'),
                Tab(icon: Icon(Icons.history), text: 'Mượn của tôi'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              buildBookList(),
              buildBorrowList(),
            ],
          ),
        ),
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
              Tab(icon: Icon(Icons.menu_book), text: 'Sách'),
              Tab(icon: Icon(Icons.assignment), text: 'Mượn/Trả'),
            ],
          ),
        ),
        floatingActionButton: isAdmin
            ? FloatingActionButton.extended(
                onPressed: openCreateBookDialog,
                icon: const Icon(Icons.add),
                label: const Text('Thêm sách'),
              )
            : null,
        body: TabBarView(
          children: [
            buildBookList(),
            buildBorrowList(),
          ],
        ),
      ),
    );
  }
}