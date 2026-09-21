import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isRegistering = false;
  bool loading = false;
  String? error;

  UserRole registerRole = UserRole.CUSTOMER;
  VehicleType vehicleType = VehicleType.TOKTOK;

  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      loading = true;
      error = null;
    });
    final fb = FirebaseService.instance;
    try {
      if (isRegistering) {
        final cred = await fb.register(emailCtrl.text.trim(), passwordCtrl.text.trim());
        final user = AppUser(
          id: cred.user!.uid,
          email: emailCtrl.text.trim(),
          phone: phoneCtrl.text.trim(),
          name: nameCtrl.text.trim(),
          role: registerRole,
          status: registerRole == UserRole.DRIVER
              ? UserStatus.PENDING_APPROVAL
              : UserStatus.APPROVED,
          vehicleType: registerRole == UserRole.DRIVER ? vehicleType : null,
        );
        await fb.createUserDoc(cred.user!.uid, user);
      } else {
        await fb.signIn(emailCtrl.text.trim(), passwordCtrl.text.trim());
      }
      // التنقل بعد النجاح بيتم تلقائيًا عبر AuthGate اللي بيستمع لـ authStateChanges
    } on FirebaseAuthException catch (e) {
      setState(() => error = _mapAuthError(e.code));
    } catch (e) {
      setState(() => error = 'حدث خطأ غير متوقع، حاول مرة أخرى');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'الحساب غير موجود';
      case 'wrong-password':
      case 'invalid-credential':
        return 'كلمة السر أو البريد غير صحيح';
      case 'email-already-in-use':
        return 'البريد الإلكتروني مستخدم بالفعل';
      case 'weak-password':
        return 'كلمة السر ضعيفة، استخدم 6 أحرف على الأقل';
      default:
        return 'حدث خطأ: $code';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: const Icon(Icons.pedal_bike, color: Colors.white, size: 56),
              ),
              const SizedBox(height: 20),
              Text(
                'وصلها',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                isRegistering ? 'إنشاء حساب جديد' : 'تسجيل الدخول',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      if (isRegistering) ...[
                        // اختيار الدور: عميل أو سائق
                        Row(
                          children: [
                            Expanded(
                              child: _RoleChip(
                                label: 'عميل',
                                selected: registerRole == UserRole.CUSTOMER,
                                onTap: () =>
                                    setState(() => registerRole = UserRole.CUSTOMER),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _RoleChip(
                                label: 'كابتن',
                                selected: registerRole == UserRole.DRIVER,
                                onTap: () =>
                                    setState(() => registerRole = UserRole.DRIVER),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (registerRole == UserRole.DRIVER)
                          DropdownButtonFormField<VehicleType>(
                            value: vehicleType,
                            decoration: const InputDecoration(labelText: 'نوع المركبة'),
                            items: const [
                              DropdownMenuItem(
                                  value: VehicleType.TOKTOK, child: Text('توكتوك')),
                              DropdownMenuItem(
                                  value: VehicleType.MOTORCYCLE, child: Text('موتوسيكل')),
                              DropdownMenuItem(value: VehicleType.CAR, child: Text('عربية')),
                            ],
                            onChanged: (v) => setState(() => vehicleType = v!),
                          ),
                        if (registerRole == UserRole.DRIVER) const SizedBox(height: 14),
                        TextFormField(
                          controller: nameCtrl,
                          decoration: const InputDecoration(labelText: 'الاسم بالكامل'),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'من فضلك اكتب الاسم'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(labelText: 'رقم الموبايل'),
                          validator: (v) => (v == null || v.trim().length < 10)
                              ? 'رقم موبايل غير صحيح'
                              : null,
                        ),
                        const SizedBox(height: 14),
                      ],
                      TextFormField(
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
                        validator: (v) => (v == null || !v.contains('@'))
                            ? 'بريد إلكتروني غير صحيح'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: passwordCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'كلمة السر'),
                        validator: (v) =>
                            (v == null || v.length < 6) ? '6 أحرف على الأقل' : null,
                      ),
                      if (error != null) ...[
                        const SizedBox(height: 12),
                        Text(error!, style: const TextStyle(color: Colors.red)),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: loading ? null : _submit,
                          child: loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : Text(isRegistering ? 'إنشاء الحساب' : 'دخول'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => setState(() => isRegistering = !isRegistering),
                        child: Text(
                          isRegistering
                              ? 'عندك حساب بالفعل؟ سجّل دخول'
                              : 'مستخدم جديد؟ أنشئ حساب',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _RoleChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.bg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
