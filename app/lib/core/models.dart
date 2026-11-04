import 'package:flutter/material.dart';

class AppUser {
  final int id;
  final String fullName;
  final String email;
  final String? phone;
  final bool isDonor;
  final String verificationStatus; // none | pending | approved | rejected
  final int unreadCount;

  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.isDonor = false,
    this.verificationStatus = 'none',
    this.unreadCount = 0,
  });

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'] as int,
        fullName: j['fullName'] as String,
        email: j['email'] as String,
        phone: j['phone'] as String?,
        isDonor: j['isDonor'] as bool? ?? false,
        verificationStatus: j['verificationStatus'] as String? ?? 'none',
        unreadCount: (j['unreadCount'] as num?)?.toInt() ?? 0,
      );

  AppUser withUnread(int n) => AppUser(
        id: id, fullName: fullName, email: email, phone: phone,
        isDonor: isDonor, verificationStatus: verificationStatus, unreadCount: n,
      );

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

class Slot {
  final String time;
  final int remaining;
  const Slot(this.time, this.remaining);
  factory Slot.fromJson(Map<String, dynamic> j) => Slot(j['time'] as String, (j['remaining'] as num).toInt());
}

class Appointment {
  final int id;
  final String fullName, phone, date, time, status;
  const Appointment({required this.id, required this.fullName, required this.phone, required this.date, required this.time, required this.status});
  factory Appointment.fromJson(Map<String, dynamic> j) => Appointment(
        id: j['id'] as int, fullName: j['fullName'] as String, phone: j['phone'] as String,
        date: j['date'] as String, time: j['time'] as String, status: j['status'] as String);
  bool get cancellable => status == 'pending' || status == 'confirmed';
}

class BloodRequest {
  final int id;
  final String patientName, bloodGroup, city, status, urgency;
  final int units;
  final String? hospital;
  final DateTime createdAt;
  const BloodRequest({required this.id, required this.patientName, required this.bloodGroup, required this.city, required this.status, required this.urgency, required this.units, this.hospital, required this.createdAt});
  factory BloodRequest.fromJson(Map<String, dynamic> j) => BloodRequest(
        id: j['id'] as int, patientName: j['patientName'] as String, bloodGroup: j['bloodGroup'] as String,
        city: j['city'] as String, status: j['status'] as String, urgency: j['urgency'] as String,
        units: (j['units'] as num).toInt(), hospital: j['hospital'] as String?,
        createdAt: DateTime.parse(j['createdAt'] as String));
}

class CardType {
  final String code, name;
  final int price;
  final Color color;
  final List<String> benefits;
  const CardType({required this.code, required this.name, required this.price, required this.color, required this.benefits});
  factory CardType.fromJson(Map<String, dynamic> j) => CardType(
        code: j['code'] as String, name: j['name'] as String, price: (j['price'] as num).toInt(),
        color: Color(int.parse((j['color'] as String).substring(1), radix: 16) | 0xFF000000),
        benefits: (j['benefits'] as List).map((e) => e.toString()).toList());
}

class CardRequest {
  final int id;
  final String cardCode, cardName, status;
  final String? note;
  final DateTime createdAt;
  const CardRequest({required this.id, required this.cardCode, required this.cardName, required this.status, this.note, required this.createdAt});
  factory CardRequest.fromJson(Map<String, dynamic> j) => CardRequest(
        id: j['id'] as int, cardCode: j['cardCode'] as String, cardName: j['cardName'] as String,
        status: j['status'] as String, note: j['note'] as String?, createdAt: DateTime.parse(j['createdAt'] as String));
}

class DonorVerification {
  final int id;
  final String status;
  final String? note;
  final DateTime createdAt;
  const DonorVerification({required this.id, required this.status, this.note, required this.createdAt});
  factory DonorVerification.fromJson(Map<String, dynamic> j) => DonorVerification(
        id: j['id'] as int, status: j['status'] as String, note: j['note'] as String?,
        createdAt: DateTime.parse(j['createdAt'] as String));
}

class AppNotification {
  final int id;
  final String type, title, body;
  final bool read;
  final DateTime createdAt;
  const AppNotification({required this.id, required this.type, required this.title, required this.body, required this.read, required this.createdAt});
  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: j['id'] as int, type: j['type'] as String, title: j['title'] as String, body: j['body'] as String,
        read: j['read'] as bool? ?? false, createdAt: DateTime.parse(j['createdAt'] as String));
  AppNotification asRead() => AppNotification(id: id, type: type, title: title, body: body, read: true, createdAt: createdAt);
}
