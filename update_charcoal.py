import os

path = r'c:\laragon\www\garden barbershop\garden_barbershop_finance\lib\screens\dashboard_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

start_str = "  Widget _primaryBalance(_DashboardData data) {"
end_str = "    );\n  }\n\n  List<Widget> _mainActions"

start_idx = content.find(start_str)
end_idx = content.find(end_str)

new_methods = """  Widget _primaryBalance(_DashboardData data) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.charcoal, Color(0xFF0F172A)], // Slate 800 to Slate 900
        ),
        borderRadius: AppTheme.radiusLarge,
        boxShadow: AppTheme.premiumShadow,
        border: Border.all(color: AppColors.brass.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.cut_rounded,
              color: AppColors.brass.withValues(alpha: 0.05),
              size: 140,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.brass.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.brass.withValues(alpha: 0.3)),
                    ),
                    child: const Center(
                      child: Icon(Icons.storefront_rounded, color: AppColors.brass, size: 24),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'GARDEN FINANCE',
                          style: TextStyle(
                            color: AppColors.brass, 
                            fontWeight: FontWeight.w900, 
                            fontSize: 14,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          data.user == null
                              ? 'Admin Dashboard'
                              : '${data.user!.name}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.brass,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      data.user?.role.label.toUpperCase() ?? 'LIVE', 
                      style: const TextStyle(color: AppColors.charcoal, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.0)
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                'PENDAPATAN BULAN INI',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1.5),
              ),
              const SizedBox(height: 4),
              Text(
                CurrencyFormatter.format(data.totalPendapatan),
                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -0.5),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.brass.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.brass, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('Bagian Capster', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                    Text(CurrencyFormatter.format(data.totalBagianCapster), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    """

content = content[:start_idx] + new_methods + content[end_idx:]

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)


pathLogin = r'c:\laragon\www\garden barbershop\garden_barbershop_finance\lib\screens\login_screen.dart'
with open(pathLogin, 'r', encoding='utf-8') as f:
    contentLogin = f.read()

start_idx = contentLogin.find("  Widget _brandHero() {")
end_idx = contentLogin.find("    );\n  }\n\n  Widget _loginCard() {")

new_login_banner = """  Widget _brandHero() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.charcoal, Color(0xFF0F172A)],
        ),
        borderRadius: AppTheme.radiusLarge,
        boxShadow: AppTheme.premiumShadow,
        border: Border.all(color: AppColors.brass.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.content_cut_rounded,
              size: 130,
              color: AppColors.brass.withValues(alpha: 0.05),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.brass.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.brass.withValues(alpha: 0.3)),
                    ),
                    child: const Center(
                      child: Icon(Icons.content_cut_rounded, color: AppColors.brass, size: 26),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.brass,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'FINANCE',
                      style: TextStyle(color: AppColors.charcoal, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'GARDEN\nBARBERSHOP',
                style: TextStyle(
                  color: Colors.white, 
                  fontSize: 26, 
                  fontWeight: FontWeight.w900, 
                  letterSpacing: 1.0,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Manajemen pendapatan, kas, dan pembagian hasil kelas premium.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.w500, height: 1.4),
              ),
            ],
          ),
        ],
      ),
    """

contentLogin = contentLogin[:start_idx] + new_login_banner + contentLogin[end_idx:]
with open(pathLogin, 'w', encoding='utf-8') as f:
    f.write(contentLogin)

print("Banners updated to Charcoal & Brass")
