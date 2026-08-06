import os

path = r'c:\laragon\www\garden barbershop\garden_barbershop_finance\lib\screens\dashboard_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

start_str = "  Widget _dashboardBackground({required Widget child}) {"
end_str = "    );\n  }\n\n  List<Widget> _mainActions"

start_idx = content.find(start_str)
end_idx = content.find(end_str)

if start_idx == -1 or end_idx == -1:
    print("Could not find blocks to replace.")
    exit(1)

original_methods = """  Widget _dashboardBackground({required Widget child}) {
    return Stack(
      children: [
        Positioned(
          top: -120,
          right: -90,
          child: _ambientGlow(240, AppColors.teal.withValues(alpha: 0.13)),
        ),
        Positioned(
          top: 220,
          left: -120,
          child: _ambientGlow(210, AppColors.brass.withValues(alpha: 0.11)),
        ),
        Positioned(
          bottom: -150,
          right: -80,
          child: _ambientGlow(260, AppColors.blue.withValues(alpha: 0.07)),
        ),
        child,
      ],
    );
  }

  Widget _ambientGlow(double size, Color color) {
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

  Widget _primaryBalance(_DashboardData data) {
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
            right: -22,
            top: -24,
            child: Icon(
              Icons.auto_graph_rounded,
              color: Colors.white.withValues(alpha: 0.09),
              size: 150,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.22)),
                    ),
                    child: const Center(
                      child: Text(
                        'G',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Garden Finance',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 16),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          data.user == null
                              ? 'Dashboard bisnis'
                              : '${data.user!.name} • ${data.user!.role.label}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.76),
                              fontWeight: FontWeight.w700,
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Live',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              Text(
                'Total Pendapatan Bulan Ini',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w700,
                    fontSize: 12),
              ),
              const SizedBox(height: 5),
              Text(
                CurrencyFormatter.format(data.totalPendapatan),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 31,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.1,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(18),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.16)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_rounded,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Bagian capster',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.78),
                            fontWeight: FontWeight.w700,
                            fontSize: 12),
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(data.totalBagianCapster),
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    """

content = content[:start_idx] + original_methods + content[end_idx:]

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Dashboard banner reverted successfully.")
