import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models.dart';

class ApiException implements Exception {
  final String message;
  final int? status;
  final Map<String, String> fields;
  ApiException(this.message, {this.status, this.fields = const {}});
  @override
  String toString() => message;
}

class AuthResult {
  final String token;
  final AppUser? user;
  AuthResult(this.token, this.user);
}

class ApiClient {
  SupabaseClient get _client => Supabase.instance.client;
  User? get _authUser => _client.auth.currentUser;

  Future<T> _run<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ApiException {
      rethrow;
    } on AuthException catch (e) {
      throw ApiException(e.message, status: int.tryParse(e.statusCode ?? ''));
    } on PlatformException catch (e) {
      throw ApiException(e.message ?? e.code);
    } on PostgrestException catch (e) {
      throw ApiException(e.message, status: int.tryParse(e.code ?? ''));
    } on StorageException catch (e) {
      throw ApiException(e.message, status: int.tryParse(e.statusCode ?? ''));
    } on TimeoutException {
      throw ApiException(
          'The server took too long to respond. Please try again.');
    }
  }

  ApiException _invalid(String message, {String? field}) => ApiException(
        message,
        status: 422,
        fields: field == null ? const {} : {field: message},
      );

  Future<int> _profileId() async {
    final user = _authUser;
    if (user == null) throw ApiException('Please log in again', status: 401);
    final profile = await _client
        .from('profiles')
        .select('id')
        .eq('user_id', user.id)
        .maybeSingle();
    if (profile == null) {
      throw ApiException(
        'Your profile is missing. Apply the Supabase schema and try again.',
      );
    }
    return (profile['id'] as num).toInt();
  }

  Future<int> _unreadCount() async =>
      ((await _client.rpc('get_unread_notification_count')) as num).toInt();

  Map<String, dynamic> _userJson(Map<String, dynamic> row, int unreadCount) => {
        'id': row['id'],
        'fullName': row['full_name'],
        'email': row['email'],
        'phone': row['phone'],
        'role': row['role'],
        'isDonor': row['is_donor'],
        'verificationStatus': row['verification_status'] ?? 'none',
        'unreadCount': unreadCount,
      };

  Future<AuthResult> _authResult(AuthResponse response) async {
    final session = response.session;
    if (session == null) return AuthResult('', null);
    return AuthResult(session.accessToken, await me());
  }

  // ---------- auth ----------
  Future<AuthResult> login(String identifier, String password) =>
      _run(() async {
        final email = identifier.trim();
        if (!email.contains('@')) {
          throw ApiException(
            'Sign in with the email address used to create your account.',
            status: 422,
            fields: const {'identifier': 'Enter your email address'},
          );
        }
        final response = await _client.auth.signInWithPassword(
          email: email,
          password: password,
        );
        final result = await _authResult(response);
        if (result.user == null) {
          throw ApiException('Login did not create an authenticated session.');
        }
        return result;
      });

  Future<AuthResult> signup(String fullName, String email, String password) =>
      _run(() async {
        final response = await _client.auth.signUp(
          email: email.trim(),
          password: password,
          data: {'full_name': fullName.trim()},
        );
        final result = await _authResult(response);
        if (result.user == null) {
          throw ApiException(
            'Email confirmation is enabled in Supabase. Disable email confirmations in the Supabase Auth settings, then try again.',
          );
        }
        return result;
      });

  Future<void> loginWithGoogle() => _run(() async {
        final launched = await _client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: kIsWeb ? null : 'io.supabase.flutter://login-callback/',
        );
        if (!launched) {
          throw ApiException('Could not start Google sign-in.');
        }
      });

  /// Sends Supabase's recovery email. Configure its template to include the
  /// six-digit token used by the app's recovery form.
  Future<String?> forgotPassword(String email) => _run(() async {
        await _client.auth.resetPasswordForEmail(email.trim());
        return null;
      });

  Future<void> resetPassword(String email, String code, String newPassword) =>
      _run(() async {
        await _client.auth.verifyOTP(
          email: email.trim(),
          token: code.trim(),
          type: OtpType.recovery,
        );
        await _client.auth.updateUser(UserAttributes(password: newPassword));
      });

  Future<void> logout() => _run(() => _client.auth.signOut());

  Future<AppUser> me() => _run(() async {
        final profileId = await _profileId();
        final rows = await _client
            .from('profiles')
            .select('id, full_name, email, phone, role, is_donor')
            .eq('id', profileId)
            .single();
        final verification = await _client
            .from('donor_verifications')
            .select('status')
            .eq('user_id', profileId)
            .order('id', ascending: false)
            .limit(1)
            .maybeSingle();
        final json = _userJson(
          {...rows, 'verification_status': verification?['status']},
          await _unreadCount(),
        );
        return AppUser.fromJson(json);
      });

  // ---------- appointments ----------
  Future<List<Slot>> availability(String date) => _run(() async {
        final rows = await _client.rpc(
          'get_appointment_availability',
          params: {'p_date': date},
        ) as List<dynamic>;
        return rows.map((row) {
          final item = Map<String, dynamic>.from(row as Map);
          return Slot(
            (item['slot_time'] as String).substring(0, 5),
            (item['remaining'] as num).toInt(),
          );
        }).toList();
      });

  Map<String, dynamic> _appointmentJson(Map<String, dynamic> row) => {
        'id': row['id'],
        'fullName': row['full_name'],
        'phone': row['phone'],
        'date': row['preferred_date'],
        'time': (row['preferred_time'] as String).substring(0, 5),
        'status': row['status'],
        'note': row['note'],
        'createdAt': row['created_at'],
      };

  Future<List<Appointment>> appointments() => _run(() async {
        final rows = await _client
            .from('appointments')
            .select()
            .order('preferred_date', ascending: false)
            .order('preferred_time', ascending: false);
        return rows
            .map((row) => Appointment.fromJson(_appointmentJson(row)))
            .toList();
      });

  Future<Appointment> bookAppointment({
    required String fullName,
    required String phone,
    required String date,
    required String time,
  }) =>
      _run(() async {
        final row = await _client.rpc(
          'book_appointment',
          params: {
            'p_full_name': fullName,
            'p_phone': phone,
            'p_date': date,
            'p_time': time,
          },
        ) as Map<String, dynamic>;
        return Appointment.fromJson(_appointmentJson(row));
      });

  Future<void> cancelAppointment(int id) => _run(() async {
        await _client.rpc('cancel_appointment', params: {'p_id': id});
      });

  // ---------- blood requests ----------
  Map<String, dynamic> _bloodRequestJson(Map<String, dynamic> row) => {
        'id': row['id'],
        'patientName': row['patient_name'],
        'bloodGroup': row['blood_group'],
        'city': row['city'],
        'status': row['status'],
        'urgency': row['urgency'],
        'units': row['units'],
        'hospital': row['hospital'],
        'createdAt': row['created_at'],
      };

  Future<List<BloodRequest>> bloodRequests() => _run(() async {
        final rows = await _client
            .from('blood_requests')
            .select()
            .order('id', ascending: false);
        return rows
            .map((row) => BloodRequest.fromJson(_bloodRequestJson(row)))
            .toList();
      });

  Future<BloodRequest> createBloodRequest(Map<String, dynamic> body) =>
      _run(() async {
        final row = await _client.rpc(
          'create_blood_request',
          params: {
            'p_patient_name': body['patientName'],
            'p_contact_person': body['contactPerson'],
            'p_contact_number': body['contactNumber'],
            'p_blood_group': body['bloodGroup'],
            'p_units': body['units'] ?? 1,
            'p_hospital': body['hospital'],
            'p_address': body['address'],
            'p_city': body['city'],
            'p_urgency': body['urgency'] ?? 'emergency',
            'p_notes': body['notes'],
          },
        ) as Map<String, dynamic>;
        return BloodRequest.fromJson(_bloodRequestJson(row));
      });

  Future<void> cancelBloodRequest(int id) => _run(() async {
        await _client.rpc('cancel_blood_request', params: {'p_id': id});
      });

  // ---------- donor verification ----------
  Future<DonorVerification?> donorVerification() => _run(() async {
        final profileId = await _profileId();
        final row = await _client
            .from('donor_verifications')
            .select()
            .eq('user_id', profileId)
            .order('id', ascending: false)
            .limit(1)
            .maybeSingle();
        if (row == null) return null;
        return DonorVerification.fromJson({
          'id': row['id'],
          'status': row['status'],
          'note': row['note'],
          'createdAt': row['created_at'],
        });
      });

  Uint8List _decodeIdImage(String field, String dataUrl) {
    final encoded = dataUrl.replaceFirst(
      RegExp(r'^data:image/(?:jpeg|jpg|png);base64,'),
      '',
    );
    late final Uint8List bytes;
    try {
      bytes = base64Decode(encoded);
    } on FormatException {
      throw _invalid('Upload a valid JPG or PNG image.', field: field);
    }
    if (bytes.length > 6 * 1024 * 1024) {
      throw _invalid('Image is too large (max 6 MB).', field: field);
    }
    final isJpeg = bytes.length >= 3 &&
        bytes[0] == 0xff &&
        bytes[1] == 0xd8 &&
        bytes[2] == 0xff;
    final isPng = bytes.length >= 4 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4e &&
        bytes[3] == 0x47;
    if (!isJpeg && !isPng) {
      throw _invalid('Only JPG or PNG images are accepted.', field: field);
    }
    return bytes;
  }

  Future<String> _uploadId(String field, String dataUrl, String userId) async {
    final bytes = _decodeIdImage(field, dataUrl);
    final isPng = bytes[0] == 0x89;
    final extension = isPng ? 'png' : 'jpg';
    final mimeType = isPng ? 'image/png' : 'image/jpeg';
    final suffix = Random.secure().nextInt(1 << 32).toRadixString(16);
    final path =
        '$userId/${DateTime.now().microsecondsSinceEpoch}_$suffix.$extension';
    await _client.storage.from('donor-ids').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: mimeType, upsert: false),
        );
    return path;
  }

  Future<DonorVerification> submitDonorVerification(
    Map<String, dynamic> body,
  ) async {
    final uploaded = <String>[];
    try {
      return await _run(() async {
        final userId = _authUser?.id;
        if (userId == null) {
          throw ApiException('Please log in again', status: 401);
        }
        final profileId = await _profileId();
        final front =
            await _uploadId('idFront', body['idFront'] as String, userId);
        uploaded.add(front);
        final back =
            await _uploadId('idBack', body['idBack'] as String, userId);
        uploaded.add(back);
        final row = await _client
            .from('donor_verifications')
            .insert({
              'user_id': profileId,
              'full_name': body['fullName'],
              'birth_date': body['birthDate'],
              'phone': body['phone'],
              'address': body['address'],
              'id_front_path': front,
              'id_back_path': back,
            })
            .select()
            .single();
        return DonorVerification.fromJson({
          'id': row['id'],
          'status': row['status'],
          'note': row['note'],
          'createdAt': row['created_at'],
        });
      });
    } on ApiException catch (e) {
      if (uploaded.isNotEmpty) {
        try {
          await _run(() async {
            await _client.storage.from('donor-ids').remove(uploaded);
          });
        } on ApiException catch (cleanupError) {
          throw ApiException(
            '${e.message} ID upload cleanup also failed: ${cleanupError.message}',
            status: e.status,
            fields: e.fields,
          );
        }
      }
      rethrow;
    }
  }

  // ---------- cards ----------
  Future<List<CardType>> cardTypes() => _run(() async {
        final rows =
            await _client.from('card_types').select().order('sort_order');
        return rows
            .map((row) => CardType.fromJson({
                  'code': row['code'],
                  'name': row['name'],
                  'price': row['price'],
                  'color': row['color'],
                  'benefits': row['benefits'],
                }))
            .toList();
      });

  Future<List<CardRequest>> cardRequests() => _run(() async {
        final rows = await _client
            .from('card_requests')
            .select('*, card_types(name)')
            .order('id', ascending: false);
        return rows.map((row) {
          final cardType = row['card_types'] as Map<String, dynamic>;
          return CardRequest.fromJson({
            'id': row['id'],
            'cardCode': row['card_code'],
            'cardName': cardType['name'],
            'status': row['status'],
            'note': row['note'],
            'createdAt': row['created_at'],
          });
        }).toList();
      });

  Future<CardRequest> createCardRequest(Map<String, dynamic> body) =>
      _run(() async {
        final profileId = await _profileId();
        final row = await _client
            .from('card_requests')
            .insert({
              'user_id': profileId,
              'card_code': body['cardCode'],
              'full_name': body['fullName'],
              'birth_date': body['birthDate'],
              'mobile': body['mobile'],
              'email': body['email'],
            })
            .select('*, card_types(name)')
            .single();
        final cardType = row['card_types'] as Map<String, dynamic>;
        return CardRequest.fromJson({
          'id': row['id'],
          'cardCode': row['card_code'],
          'cardName': cardType['name'],
          'status': row['status'],
          'note': row['note'],
          'createdAt': row['created_at'],
        });
      });

  // ---------- notifications ----------
  Future<List<AppNotification>> notifications() => _run(() async {
        final profileId = await _profileId();
        final rows = await _client
            .from('notifications')
            .select()
            .or('user_id.is.null,user_id.eq.$profileId')
            .order('id', ascending: false)
            .limit(50);
        final reads = await _client
            .from('notification_reads')
            .select('notification_id')
            .eq('user_id', profileId);
        final readIds = reads.map((row) => row['notification_id']).toSet();
        return rows
            .map((row) => AppNotification.fromJson({
                  'id': row['id'],
                  'type': row['type'],
                  'title': row['title'],
                  'body': row['body'],
                  'read': readIds.contains(row['id']),
                  'createdAt': row['created_at'],
                }))
            .toList();
      });

  Future<int> markRead(int id) => _run(() async {
        final profileId = await _profileId();
        await _client.from('notification_reads').upsert(
          {'user_id': profileId, 'notification_id': id},
          onConflict: 'user_id,notification_id',
          ignoreDuplicates: true,
        );
        return _unreadCount();
      });

  Future<void> markAllRead() => _run(() async {
        await _client.rpc('mark_all_notifications_read');
      });
}
