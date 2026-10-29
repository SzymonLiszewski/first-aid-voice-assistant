import 'package:flutter/material.dart';

import '../themes/theme.dart';

class DemoBanner extends StatelessWidget {
  const DemoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Informacja o wersji demonstracyjnej',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.demoBackground,
          border: Border.all(color: AppColors.demoBorder),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFF8A5300)),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WERSJA DEMONSTRACYJNA',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      color: AppColors.demoText,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Prototyp badawczy z pracy magisterskiej. Nie jest wyrobem '
                    'medycznym i nie zastępuje pogotowia ratunkowego.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: Color(0xFF5A3A00),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DemoBadge extends StatelessWidget {
  const DemoBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.demoBackground,
        border: Border.all(color: AppColors.demoBorder),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'DEMO',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
          color: AppColors.demoText,
        ),
      ),
    );
  }
}
