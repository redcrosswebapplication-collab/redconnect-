import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../core/api.dart';
import '../core/models.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../widgets/common.dart';

class DonorVerificationScreen extends StatefulWidget {
  const DonorVerificationScreen({super.key});
  @override
  State<DonorVerificationScreen> createState() => _DonorVerificationScreenState();
}

class _DonorVerificationScreenState extends State<DonorVerificationScreen> with FormErrors {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  final _address = TextEditingController();
  final _dobText = TextEditingController();
  DateTime? _dob;
  Uint8List? _front, _back;
  bool _frontErr = false, _backErr = false, _busy = false;

  Future<DonorVerification?>? _status;
  DonorVerification? _submitted;

  @override
  void initState() {
    super.initState();
    final u = context.read<AppState>().user!;
    _name = TextEditingController(text: u.fullName);
    _phone = TextEditingController(text: u.phone ?? '');
    _status = context.read<AppState>().api.donorVerification();
  }

  void _load() {
    final f = context.read<AppState>().api.donorVerification();
    setState(() {
      _status = f;
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _dobText.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final latest = DateTime(now.year - 18, now.month, now.day);
    final d = await showDatePicker(
      context: context,
      initialDate: _dob ?? latest,
      firstDate: DateTime(now.year - 65, now.month, now.day),
      lastDate: latest,
      helpText: 'Date of birth (18 to 65)',
    );
    if (d != null) {
      setState(() {
        _dob = d;
        _dobText.text = fmtDate(d);
        srv.remove('birthDate');
      });
    }
  }

  Future<void> _pickImage(bool front) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: const Icon(Icons.photo_camera_rounded), title: const Text('Take a photo'), onTap: () => Navigator.pop(c, ImageSource.camera)),
          ListTile(leading: const Icon(Icons.photo_library_rounded), title: const Text('Choose from gallery'), onTap: () => Navigator.pop(c, ImageSource.gallery)),
        ]),
      ),
    );
    if (source == null) return;
    try {
      final x = await ImagePicker().pickImage(source: source, maxWidth: 1600, imageQuality: 75);
      if (x == null) return;
      final bytes = await x.readAsBytes();
      if (!mounted) return;
      setState(() {
        if (front) {
          _front = bytes;
          _frontErr = false;
          srv.remove('idFront');
        } else {
          _back = bytes;
          _backErr = false;
          srv.remove('idBack');
        }
      });
    } catch (_) {
      if (mounted) toast(context, 'Could not open the camera or gallery. Check app permissions.', error: true);
    }
  }

  String _dataUrl(Uint8List b) => 'data:image/jpeg;base64,${base64Encode(b)}';

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final valid = _form.currentState!.validate();
    setState(() {
      _frontErr = _front == null;
      _backErr = _back == null;
    });
    if (!valid || _front == null || _back == null) {
      toast(context, 'Please complete your details and upload both sides of your ID.', error: true);
      return;
    }
    final state = context.read<AppState>();
    setState(() => _busy = true);
    try {
      final v = await state.api.submitDonorVerification({
        'fullName': _name.text.trim(),
        'birthDate': ymd(_dob!),
        'phone': _phone.text.trim(),
        'address': _address.text.trim(),
        'idFront': _dataUrl(_front!),
        'idBack': _dataUrl(_back!),
      });
      if (!mounted) return;
      setState(() => _submitted = v);
      state.refreshUser();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => applyApiError(e));
      toast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.deepRed,
      appBar: redAppBar(context, 'VERIFY IDENTITY', color: C.deepRed),
      body: SafeArea(
        child: _submitted != null
            ? _StatusView(v: _submitted!, justSubmitted: true)
            : FutureBuilder<DonorVerification?>(
                future: _status,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) return const LoadingView(color: Colors.white);
                  if (snap.hasError) {
                    final m = snap.error is ApiException ? (snap.error as ApiException).message : 'Could not load your status.';
                    return ErrorRetry(message: m, onRetry: _load, dark: true);
                  }
                  final v = snap.data;
                  if (v != null && v.status != 'rejected') return _StatusView(v: v);
                  return _formView(rejected: v);
                },
              ),
      ),
    );
  }

  Widget _formView({DonorVerification? rejected}) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 24),
      child: Form(
        key: _form,
        child: Column(children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Text(
              rejected == null
                  ? 'Submit your Identity Documents to become a verified Donor'
                  : 'Your last submission was not approved${(rejected.note ?? '').isEmpty ? '' : ': ${rejected.note}'}. Please resubmit with clear photos.',
              style: const TextStyle(fontSize: 17, color: Color(0xFF504A4A), height: 1.3),
            ),
          ),
          const SizedBox(height: 14),
          WhiteCard(
            title: 'Personal Details',
            child: Column(children: [
              AppTextField(hint: 'Complete Name', controller: _name, capitalization: TextCapitalization.words, textInputAction: TextInputAction.next, validator: V.minLen('Name', 2), serverError: srv['fullName'], onChanged: (_) => clearErr('fullName')),
              const SizedBox(height: 10),
              AppTextField(hint: 'Date of Birth', controller: _dobText, readOnly: true, onTap: _pickDob, suffix: const Icon(Icons.calendar_month_rounded, color: C.muted), validator: (_) => _dob == null ? 'Date of birth is required' : null, serverError: srv['birthDate']),
              const SizedBox(height: 10),
              AppTextField(hint: 'Phone Number', controller: _phone, keyboardType: TextInputType.phone, textInputAction: TextInputAction.next, validator: V.phone(label: 'Phone number'), serverError: srv['phone'], onChanged: (_) => clearErr('phone')),
              const SizedBox(height: 10),
              AppTextField(hint: 'Current Address', controller: _address, textInputAction: TextInputAction.done, validator: V.minLen('Address', 5), serverError: srv['address'], onChanged: (_) => clearErr('address')),
            ]),
          ),
          const SizedBox(height: 14),
          WhiteCard(
            title: 'Uploads Document (National ID)',
            child: Column(children: [
              _UploadTile(title: 'ID Card (Front Side)', bytes: _front, error: _frontErr || srv['idFront'] != null, onTap: () => _pickImage(true)),
              const SizedBox(height: 12),
              _UploadTile(title: 'ID Card (Back Side)', bytes: _back, error: _backErr || srv['idBack'] != null, onTap: () => _pickImage(false)),
              const SizedBox(height: 10),
              const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.lock_outline_rounded, size: 16, color: C.muted),
                SizedBox(width: 6),
                Expanded(child: Text('Your ID photos are stored securely and only used to verify you.', style: TextStyle(fontSize: 12, color: C.muted))),
              ]),
            ]),
          ),
          const SizedBox(height: 18),
          PrimaryButton(label: 'Submit Verification', onPressed: _submit, loading: _busy, color: C.darkRed),
        ]),
      ),
    );
  }
}

class _UploadTile extends StatelessWidget {
  final String title;
  final Uint8List? bytes;
  final bool error;
  final VoidCallback onTap;
  const _UploadTile({required this.title, required this.bytes, required this.error, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final has = bytes != null;
    return Material(
      color: const Color(0xFFF1EFEF),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: error ? const Color(0xFFB3261E) : const Color(0xFFBA1616), width: error ? 2 : 1)),
          child: Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: has
                  ? Image.memory(bytes!, width: 64, height: 64, fit: BoxFit.cover)
                  : Container(width: 64, height: 64, color: Colors.white, child: const Icon(Icons.photo_camera_outlined, color: C.deepRed, size: 32)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: Colors.black)),
                const SizedBox(height: 3),
                Row(children: [
                  if (has) const Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 16)),
                  Text(has ? 'Tap to change' : (error ? 'Required: tap to upload' : 'Tap to Upload'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: error && !has ? const Color(0xFFB3261E) : const Color(0xFF777070))),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _StatusView extends StatelessWidget {
  final DonorVerification v;
  final bool justSubmitted;
  const _StatusView({required this.v, this.justSubmitted = false});

  @override
  Widget build(BuildContext context) {
    final approved = v.status == 'approved';
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: WhiteCard(
          padding: const EdgeInsets.fromLTRB(24, 30, 24, 26),
          child: Column(children: [
            Icon(approved ? Icons.verified_rounded : Icons.hourglass_top_rounded, size: 70, color: approved ? const Color(0xFF2E7D32) : const Color(0xFFB7791F)),
            const SizedBox(height: 14),
            Text(approved ? "You're a verified donor" : (justSubmitted ? 'Verification submitted' : 'Verification under review'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: C.ink)),
            const SizedBox(height: 8),
            Text(
              approved
                  ? 'Thank you for stepping up. Watch your notifications for blood requests that match you.'
                  : "We're checking your documents. You'll get a notification as soon as a decision is made.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: C.muted, height: 1.4),
            ),
            if ((v.note ?? '').isNotEmpty) ...[const SizedBox(height: 10), Text('Note: ${v.note}', style: const TextStyle(color: C.ink, fontWeight: FontWeight.w600))],
            const SizedBox(height: 18),
            StatusChip(v.status),
            const SizedBox(height: 22),
            PrimaryButton(label: 'Done', onPressed: () => Navigator.of(context).maybePop(), color: C.deepRed),
          ]),
        ),
      ),
    );
  }
}
