import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String id;
  final String clientId;
  final String clientName;
  final String? workerId;
  final String? workerName;
  final String serviceName;
  final String address;
  final String description;
  final double price;
  final String status; // 'pending', 'accepted', 'completed', 'cancelled'
  final String paymentStatus; // 'unpaid', 'paid'
  final String date;
  final DateTime? createdAt;

  BookingModel({
    required this.id,
    required this.clientId,
    required this.clientName,
    this.workerId,
    this.workerName,
    required this.serviceName,
    required this.address,
    required this.description,
    required this.price,
    this.status = 'pending',
    this.paymentStatus = 'unpaid',
    required this.date,
    this.createdAt,
  });

  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return BookingModel(
      id: doc.id,
      clientId: data['clientId'] ?? '',
      clientName: data['clientName'] ?? '',
      workerId: data['workerId'],
      workerName: data['workerName'],
      serviceName: data['serviceName'] ?? '',
      address: data['address'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      status: data['status'] ?? 'pending',
      paymentStatus: data['paymentStatus'] ?? 'unpaid',
      date: data['date'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'clientId': clientId,
      'clientName': clientName,
      'workerId': workerId,
      'workerName': workerName,
      'serviceName': serviceName,
      'address': address,
      'description': description,
      'price': price,
      'status': status,
      'paymentStatus': paymentStatus,
      'date': date,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}