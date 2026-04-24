import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VerifyWorkersScreen extends StatelessWidget {
  const VerifyWorkersScreen({super.key});

  Future<void> _updateWorkerStatus(String uid, bool approve) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'isVerified': approve,
      'status': approve ? 'active' : 'rejected',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Phê duyệt Thợ')),
      body: StreamBuilder<QuerySnapshot>(
        // Lọc những người dùng có role là worker và chưa được xác minh
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'worker')
            .where('isVerified', isEqualTo: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final workers = snapshot.data!.docs;
          if (workers.isEmpty) return const Center(child: Text('Không có yêu cầu nào mới.'));

          return ListView.builder(
            itemCount: workers.length,
            itemBuilder: (context, index) {
              final worker = workers[index].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.all(10),
                child: ExpansionTile(
                  title: Text(worker['fullName'] ?? 'Thợ chưa đặt tên'),
                  subtitle: Text('Kỹ năng: ${worker['skills']?.join(", ")}'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        children: [
                          Text('Email: ${worker['email']}'),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                onPressed: () => _updateWorkerStatus(workers[index].id, true),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                child: const Text('PHÊ DUYỆT', style: TextStyle(color: Colors.white)),
                              ),
                              ElevatedButton(
                                onPressed: () => _updateWorkerStatus(workers[index].id, false),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                child: const Text('TỪ CHỐI', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          )
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}