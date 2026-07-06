import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const routeName = '/';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  var _loading = false;
  var _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final success = await AuthService().login(
      _usernameController.text.trim(),
      _passwordController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (success) {
      Navigator.pushReplacementNamed(context, DashboardScreen.routeName);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username atau password salah')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE9FFF8), AppColors.linen, AppColors.paper],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -80,
              right: -70,
              child:
                  _ambientCircle(210, AppColors.teal.withValues(alpha: 0.13)),
            ),
            Positioned(
              top: 190,
              left: -90,
              child:
                  _ambientCircle(180, AppColors.brass.withValues(alpha: 0.12)),
            ),
            Positioned(
              bottom: -95,
              right: -40,
              child:
                  _ambientCircle(190, AppColors.blue.withValues(alpha: 0.08)),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _brandHero(),
                        const SizedBox(height: 18),
                        _loginCard(),
                        const SizedBox(height: 14),
                        _demoAccountHint(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ambientCircle(double size, Color color) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }

  Widget _brandHero() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: AppTheme.radiusLarge,
        boxShadow: AppTheme.floatingShadow,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -22,
            child: Icon(
              Icons.account_balance_wallet_rounded,
              size: 130,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.28)),
                    ),
                    child: const Icon(Icons.content_cut_rounded,
                        color: Colors.white, size: 31),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Finance Control',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              const Text(
                'Garden Barbershop',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Pantau pendapatan, kas, operasional, dan pembagian hasil dalam satu aplikasi.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.84),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _loginCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: AppTheme.radiusLarge,
        border: Border.all(color: AppColors.line),
        boxShadow: AppTheme.softShadow,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Masuk ke akun',
              style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  color: AppColors.charcoal),
            ),
            const SizedBox(height: 4),
            const Text(
              'Gunakan akun sesuai role untuk mulai mengelola data.',
              style: TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _usernameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Username',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (value) => Validators.required(value, 'Username'),
            ),
            const SizedBox(height: 13),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _login(),
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  tooltip: _obscurePassword
                      ? 'Tampilkan password'
                      : 'Sembunyikan password',
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) => Validators.required(value, 'Password'),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _loading ? null : _login,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.arrow_forward_rounded),
              label: const Text('Masuk Sekarang'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _demoAccountHint() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: AppTheme.radiusMedium,
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.16)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.tealDark),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Demo cepat: admin / admin123, senior / senior123, diva / capster123, pemilik / pemilik123.',
              style: TextStyle(
                  color: AppColors.tealDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                  height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
