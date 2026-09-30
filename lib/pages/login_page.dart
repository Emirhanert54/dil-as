import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'student_home.dart';
import 'teacher_home.dart';
import 'parent_home.dart' as parent;
import '../services/session_flow_service.dart';

class LoginPalette {
  static const Color primary = Color(0xFF3F51B5);
  static const Color secondary = Color(0xFF4454D6);
  static const Color deepSpace = Color(0xFF172033);
  static const Color nightBlue = Color(0xFF233052);
  static const Color cardBg = Color(0xFFF8FAFF);
  static const Color softText = Color(0xFF667085);
  static const Color darkText = Color(0xFF172033);
  static const Color accentPink = Color(0xFF6D3BEA);
  static const Color accentBlue = Color(0xFF4F8CFF);

  static const List<Color> bgGradient = [
    Color(0xFF172033),
    Color(0xFF233052),
    Color(0xFF3F51B5),
  ];

  static const List<Color> buttonGradient = [
    Color(0xFF172033),
    Color(0xFF3F51B5),
  ];

  static const List<Color> parentGradient = [
    Color(0xFF172033),
    Color(0xFF3F51B5),
  ];

  static const List<Color> teacherGradient = [
    Color(0xFF172033),
    Color(0xFF4454D6),
  ];
}

class LoginPage extends StatefulWidget {
  final bool showBackToStudent;

  const LoginPage({
    super.key,
    this.showBackToStudent = false,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _hidePassword = true;
  bool _hideConfirmPassword = true;

  String _userType = 'teacher';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _surnameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final auth = FirebaseAuth.instance;
      final firestore = FirebaseFirestore.instance;

      if (_isLogin) {
        await auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        if (_passwordController.text.trim() !=
            _confirmPasswordController.text.trim()) {
          throw FirebaseAuthException(
            code: 'pass-error',
            message: 'Şifreler eşleşmiyor!',
          );
        }

        final userCredential = await auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        final uid = userCredential.user!.uid;

        await firestore.collection('users').doc(uid).set({
          'name': _nameController.text.trim(),
          'surname': _surnameController.text.trim(),
          'email': _emailController.text.trim(),
          'role': _userType,
          'accountType': _userType,
          'uid': uid,
          'createdAt': FieldValue.serverTimestamp(),
          if (_userType == 'teacher') ...{
            'classNames': [],
            'linkedStudentIds': [],
            'panelType': 'teacher',
          },
          if (_userType == 'parent') ...{
            'childIds': [],
            'linkedStudentIds': [],
            'panelType': 'parent',
          },
        });
      }

      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'Kullanıcı bulunamadı.',
        );
      }

      final doc = await firestore.collection('users').doc(currentUser.uid).get();

      if (!doc.exists) {
        throw FirebaseAuthException(
          code: 'user-doc-not-found',
          message: 'Kullanıcı profili bulunamadı.',
        );
      }

      final data = doc.data() as Map<String, dynamic>;
      final role = (data['role'] ?? '').toString();

      if (!mounted) return;

      if (role == 'teacher') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const TeacherHome(),
          ),
        );
      } else if (role == 'parent') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const parent.ParentHome(),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const StudentHome(),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_friendlyAuthError(e)),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Bir hata oluştu. Lütfen tekrar dene."),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendPasswordResetEmail() async {
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();

    if (email.isEmpty || !email.contains("@")) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Önce geçerli bir e-posta adresi yaz."),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "Şifre sıfırlama bağlantısı e-posta adresine gönderildi.",
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_friendlyAuthError(e)),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'pass-error':
        return "⚠️ Şifreler eşleşmiyor!";
      case 'invalid-email':
        return "Geçerli bir e-posta adresi gir.";
      case 'user-not-found':
        return "Bu e-posta ile kayıtlı kullanıcı bulunamadı.";
      case 'wrong-password':
      case 'invalid-credential':
        return "E-posta veya şifre yanlış.";
      case 'email-already-in-use':
        return "Bu e-posta zaten kullanılıyor.";
      case 'weak-password':
        return "Şifre en az 6 karakter olmalı.";
      case 'user-doc-not-found':
        return "Kullanıcı profili bulunamadı.";
      default:
        return e.message ?? "Bir hata oluştu.";
    }
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _hidePassword = true;
      _hideConfirmPassword = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = _isLogin ? "Kontrol Paneli" : "Yetişkin Hesabı Oluştur";
    final subtitle = _isLogin
        ? "Öğretmen veya ebeveyn hesabınla giriş yap."
        : "Bu alana sadece ebeveyn veya öğretmen kayıt olur.";

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: LoginPalette.bgGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            const _SpaceBackground(),

            if (widget.showBackToStudent)
              Positioned(
                top: 0,
                left: 0,
                child: _LoginBackButton(
                  onTap: () {
                    SessionFlowService.allowChildAutoStart();

                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                      return;
                    }

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const StudentHome(),
                      ),
                    );
                  },
                ),
              ),

            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
                  child: Column(
                    children: [
                      const _BrandArea(),

                      const SizedBox(height: 16),

                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 430),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: LoginPalette.cardBg.withOpacity(0.96),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.55),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.22),
                              blurRadius: 30,
                              offset: const Offset(0, 16),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              _ModeSwitcher(
                                isLogin: _isLogin,
                                onLoginTap: () {
                                  if (!_isLogin) _toggleMode();
                                },
                                onRegisterTap: () {
                                  if (_isLogin) _toggleMode();
                                },
                              ),

                              const SizedBox(height: 14),

                              Text(
                                title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: LoginPalette.darkText,
                                  fontSize: 25,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),

                              const SizedBox(height: 7),

                              Text(
                                subtitle,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: LoginPalette.softText,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  height: 1.35,
                                ),
                              ),

                              const SizedBox(height: 12),

                              if (!_isLogin) ...[
                                Row(
                                  children: [
                                    Expanded(
                                      child: _SpaceInput(
                                        controller: _nameController,
                                        icon: Icons.person_rounded,
                                        hint: "Ad",
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return "Ad gerekli";
                                          }

                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _SpaceInput(
                                        controller: _surnameController,
                                        icon: Icons.badge_rounded,
                                        hint: "Soyad",
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return "Soyad gerekli";
                                          }

                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                _RoleSelector(
                                  selectedRole: _userType,
                                  onChanged: (role) {
                                    setState(() => _userType = role);
                                  },
                                ),

                                const SizedBox(height: 10),

                                _ChildInfoNote(
                                  selectedRole: _userType,
                                ),

                                const SizedBox(height: 12),
                              ],

                              _SpaceInput(
                                controller: _emailController,
                                icon: Icons.email_rounded,
                                hint: "E-posta",
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  final email = value?.trim() ?? "";

                                  if (email.isEmpty) {
                                    return "E-posta gerekli";
                                  }

                                  if (!email.contains("@")) {
                                    return "Geçerli e-posta gir";
                                  }

                                  return null;
                                },
                              ),

                              const SizedBox(height: 12),

                              _SpaceInput(
                                controller: _passwordController,
                                icon: Icons.lock_rounded,
                                hint: "Şifre",
                                obscureText: _hidePassword,
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _hidePassword = !_hidePassword;
                                    });
                                  },
                                  icon: Icon(
                                    _hidePassword
                                        ? Icons.visibility_rounded
                                        : Icons.visibility_off_rounded,
                                    color: LoginPalette.softText,
                                  ),
                                ),
                                validator: (value) {
                                  final password = value?.trim() ?? "";

                                  if (password.isEmpty) {
                                    return "Şifre gerekli";
                                  }

                                  if (password.length < 6) {
                                    return "En az 6 karakter gir";
                                  }

                                  return null;
                                },
                              ),

                              if (_isLogin) ...[
                                const SizedBox(height: 4),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: _isLoading
                                        ? null
                                        : _sendPasswordResetEmail,
                                    icon: const Icon(
                                      Icons.help_outline_rounded,
                                      size: 17,
                                    ),
                                    label: const Text("Şifremi unuttum"),
                                    style: TextButton.styleFrom(
                                      foregroundColor: LoginPalette.primary,
                                      textStyle: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ],

                              if (!_isLogin) ...[
                                const SizedBox(height: 12),
                                _SpaceInput(
                                  controller: _confirmPasswordController,
                                  icon: Icons.verified_user_rounded,
                                  hint: "Şifre Tekrar",
                                  obscureText: _hideConfirmPassword,
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _hideConfirmPassword =
                                        !_hideConfirmPassword;
                                      });
                                    },
                                    icon: Icon(
                                      _hideConfirmPassword
                                          ? Icons.visibility_rounded
                                          : Icons.visibility_off_rounded,
                                      color: LoginPalette.softText,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return "Şifre tekrarı gerekli";
                                    }

                                    if (value.trim() !=
                                        _passwordController.text.trim()) {
                                      return "Şifreler aynı değil";
                                    }

                                    return null;
                                  },
                                ),
                              ],

                              const SizedBox(height: 20),

                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: LoginPalette.buttonGradient,
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: LoginPalette.primary
                                            .withOpacity(0.35),
                                        blurRadius: 16,
                                        offset: const Offset(0, 9),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _submit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      disabledBackgroundColor:
                                      Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 3,
                                      ),
                                    )
                                        : Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _isLogin
                                              ? Icons.login_rounded
                                              : Icons
                                              .admin_panel_settings_rounded,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _isLogin
                                              ? "GİRİŞ YAP"
                                              : "YETİŞKİN HESABI OLUŞTUR",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14.2,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 14),

                              TextButton(
                                onPressed: _isLoading ? null : _toggleMode,
                                child: Text(
                                  _isLogin
                                      ? "Yetişkin hesabın yok mu? Kayıt ol"
                                      : "Zaten hesabın var mı? Giriş yap",
                                  style: const TextStyle(
                                    color: LoginPalette.darkText,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      Text(
                        "Çocuklar e-posta/şifre kullanmaz • Oyuncu ID ile eşleşir",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.88),
                          fontSize: 11.8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ParentHomePlaceholder extends StatelessWidget {
  const ParentHomePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LoginPalette.deepSpace,
      appBar: AppBar(
        title: const Text(
          "Ebeveyn Kontrolü",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        foregroundColor: Colors.white,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: LoginPalette.parentGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();

              if (!context.mounted) return;

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => const LoginPage(),
                ),
                    (route) => false,
              );
            },
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: LoginPalette.bgGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(22),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.94),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.family_restroom_rounded,
                  size: 64,
                  color: LoginPalette.primary,
                ),
                const SizedBox(height: 16),
                const Text(
                  "Ebeveyn Paneli Hazırlandı",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: LoginPalette.darkText,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Bir sonraki adımda buraya çocuk ekleme, Oyuncu ID ile eşleşme ve gelişim takibi ekranlarını ekleyeceğiz.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: LoginPalette.softText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandArea extends StatelessWidget {
  const _BrandArea();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: LoginPalette.buttonGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.35),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.22),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.admin_panel_settings_rounded,
              color: Colors.white,
              size: 42,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          "DİL-AS Kontrol",
          style: TextStyle(
            color: Colors.white,
            fontSize: 29,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          "Ebeveyn ve öğretmen yönetim alanı",
          style: TextStyle(
            color: Colors.white.withOpacity(0.92),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ModeSwitcher extends StatelessWidget {
  final bool isLogin;
  final VoidCallback onLoginTap;
  final VoidCallback onRegisterTap;

  const _ModeSwitcher({
    required this.isLogin,
    required this.onLoginTap,
    required this.onRegisterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFFE8ECF8),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeButton(
              label: "Giriş",
              selected: isLogin,
              onTap: onLoginTap,
            ),
          ),
          Expanded(
            child: _ModeButton(
              label: "Kayıt",
              selected: !isLogin,
              onTap: onRegisterTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
              colors: LoginPalette.buttonGradient,
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            )
                : null,
            color: selected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : LoginPalette.darkText,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleSelector extends StatelessWidget {
  final String selectedRole;
  final ValueChanged<String> onChanged;

  const _RoleSelector({
    required this.selectedRole,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFE8ECF8),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: _RoleCard(
              emoji: "👩‍🏫",
              title: "Öğretmen",
              selected: selectedRole == 'teacher',
              gradient: LoginPalette.teacherGradient,
              onTap: () => onChanged('teacher'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _RoleCard(
              emoji: "👨‍👩‍👧",
              title: "Ebeveyn",
              selected: selectedRole == 'parent',
              gradient: LoginPalette.parentGradient,
              onTap: () => onChanged('parent'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String emoji;
  final String title;
  final bool selected;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _RoleCard({
    required this.emoji,
    required this.title,
    required this.selected,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            gradient: selected
                ? LinearGradient(
              colors: gradient,
            )
                : null,
            color: selected ? null : Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? Colors.white : LoginPalette.darkText,
                    fontWeight: FontWeight.w900,
                    fontSize: 12.5,
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

class _ChildInfoNote extends StatelessWidget {
  final String selectedRole;

  const _ChildInfoNote({
    required this.selectedRole,
  });

  @override
  Widget build(BuildContext context) {
    final isParent = selectedRole == 'parent';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: isParent
            ? LoginPalette.accentPink.withOpacity(0.12)
            : LoginPalette.primary.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isParent
              ? LoginPalette.accentPink.withOpacity(0.22)
              : LoginPalette.primary.withOpacity(0.18),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isParent ? Icons.family_restroom_rounded : Icons.school_rounded,
            color: isParent ? LoginPalette.accentPink : LoginPalette.primary,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              isParent
                  ? "Ebeveyn hesabı çocukları Oyuncu ID ile eşleştirecek."
                  : "Öğretmen hesabı öğrencileri Oyuncu ID veya sınıf kodu ile eşleştirecek.",
              style: const TextStyle(
                color: LoginPalette.darkText,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpaceInput extends StatelessWidget {
  final TextEditingController controller;
  final IconData icon;
  final String hint;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const _SpaceInput({
    required this.controller,
    required this.icon,
    required this.hint,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 14,
        color: LoginPalette.darkText,
      ),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: LoginPalette.primary),
        suffixIcon: suffixIcon,
        hintText: hint,
        hintStyle: const TextStyle(
          color: LoginPalette.softText,
          fontWeight: FontWeight.w700,
        ),
        filled: true,
        fillColor: const Color(0xFFF3F6FC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        errorMaxLines: 2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: LoginPalette.primary.withOpacity(0.10),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: LoginPalette.primary,
            width: 1.6,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: Colors.redAccent,
            width: 1.4,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: Colors.redAccent,
            width: 1.6,
          ),
        ),
      ),
    );
  }
}

class _SpaceBackground extends StatelessWidget {
  const _SpaceBackground();

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;

    return IgnorePointer(
      child: Stack(
        children: [
          const Positioned(
            top: 70,
            left: 28,
            child: _GlowCircle(
              size: 70,
              color: Color(0x33FFFFFF),
            ),
          ),

          const Positioned(
            top: 145,
            right: 32,
            child: _GlowCircle(
              size: 52,
              color: Color(0x22FFFFFF),
            ),
          ),

          const Positioned(
            bottom: 150,
            left: 22,
            child: _GlowCircle(
              size: 86,
              color: Color(0x18FFFFFF),
            ),
          ),

          const Positioned(
            bottom: 90,
            right: 30,
            child: _GlowCircle(
              size: 64,
              color: Color(0x16FFFFFF),
            ),
          ),

          ...List.generate(22, (i) {
            final top = 34.0 + ((i * 37) % screen.height);
            final left = 18.0 + ((i * 31) % screen.width);
            final starSize = i % 4 == 0 ? 3.2 : 2.1;

            return Positioned(
              top: top,
              left: left,
              child: Container(
                width: starSize,
                height: starSize,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.70),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.22),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowCircle({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.35),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }
}

class _LoginBackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _LoginBackButton({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(
          left: 12,
          top: 10,
        ),
        child: Material(
          color: Colors.white.withOpacity(0.16),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.25),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
