import os

path = r'c:\laragon\www\garden barbershop\garden_barbershop_finance\lib\widgets\app_page_widgets.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Add import
content = content.replace("import '../theme/app_theme.dart';", "import '../theme/app_theme.dart';\nimport 'package:flutter_animate/flutter_animate.dart';")

# 1. AppPageHeader
content = content.replace("    return Container(\n      padding: const EdgeInsets.all(18),", "    return Container(\n      padding: const EdgeInsets.all(18),")
# Wait, it's easier to find the return and just append the .animate() at the end of the widget.
# Actually, I'll use regex to find the end of the return statement for each class.
# Alternatively, I can just use string replacement on specific lines.

# MobileInfoTile
content = content.replace("    return Material(\n      color: AppColors.paper,", "    return Material(\n      color: AppColors.paper,")
# Let's write a more robust replacement for the end of the widgets.

replacements = {
    # AppPageHeader
    "      ),\n    );\n  }\n}\n\nclass ResponsiveActionRow": "      ),\n    ).animate().fade(duration: 500.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad, delay: 100.ms);\n  }\n}\n\nclass ResponsiveActionRow",
    
    # PremiumSectionTitle
    "        if (action != null) action!,\n      ],\n    );\n  }\n}": "        if (action != null) action!,\n      ],\n    ).animate().fade(duration: 400.ms);\n  }\n}",
    
    # MobileInfoTile
    "            ],\n          ),\n        ),\n      ),\n    );\n  }\n}": "            ],\n          ),\n        ),\n      ),\n    ).animate().fade(duration: 400.ms).slideY(begin: 0.05, end: 0, curve: Curves.easeOutQuad);\n  }\n}",
    
    # CompactMetricCard
    "          ),\n        ],\n      ),\n    );\n  }\n}": "          ),\n        ],\n      ),\n    ).animate().fade(duration: 400.ms).scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1), curve: Curves.easeOutBack);\n  }\n}",
    
    # AppSectionCard
    "          ...children,\n        ],\n      ),\n    );\n  }\n}": "          ...children,\n        ],\n      ),\n    ).animate().fade(duration: 500.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad);\n  }\n}"
}

for old, new in replacements.items():
    content = content.replace(old, new)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Widgets updated with animations")
