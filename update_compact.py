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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: AppTheme.radiusLarge,
        boxShadow: AppTheme.floatingShadow,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.auto_graph_rounded,
              color: Colors.white.withValues(alpha: 0.1),
              size: 110,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Icon(Icons.storefront_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Garden Finance',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15),
                        ),
                        Text(
                          data.user == null
                              ? 'Dashboard Bisnis'
                              : '${data.user!.name} • ${data.user!.role.label}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text('Live', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Total Pendapatan Bulan Ini',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w700, fontSize: 12),
              ),
              Text(
                CurrencyFormatter.format(data.totalPendapatan),
                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.wallet_rounded, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Bagian capster', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w600, fontSize: 12)),
                    ),
                    Text(CurrencyFormatter.format(data.totalBagianCapster), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
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
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: AppTheme.radiusLarge,
        boxShadow: AppTheme.floatingShadow,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -10,
            bottom: -20,
            child: Icon(
              Icons.account_balance_wallet_rounded,
              size: 110,
              color: Colors.white.withValues(alpha: 0.08),
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
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Icon(Icons.content_cut_rounded, color: Colors.white, size: 24),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Finance Control',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'Garden Barbershop',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
              ),
              const SizedBox(height: 4),
              Text(
                'Pantau pendapatan, kas, operasional, dan pembagian hasil dalam satu aplikasi.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12.5, fontWeight: FontWeight.w500, height: 1.3),
              ),
            ],
          ),
        ],
      ),
    """

contentLogin = contentLogin[:start_idx] + new_login_banner + contentLogin[end_idx:]
with open(pathLogin, 'w', encoding='utf-8') as f:
    f.write(contentLogin)

print("Banners updated to compact versions")
