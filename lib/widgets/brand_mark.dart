import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Logo : un disque corail suivi du nom de l'application
class BrandMark extends StatelessWidget {
  final double size;
  final bool showName;
  final Color textColor;
  const BrandMark({
    super.key,
    this.size = 30,
    this.showName = true,
    this.textColor = AppColors.ink,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: AppColors.coral,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.shopping_bag_rounded,
              size: size * 0.52, color: AppColors.ink),
        ),
        if (showName) ...[
          SizedBox(width: size * 0.3),
          Text(
            kAppName,
            style: TextStyle(
              fontSize: size * 0.9,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: -0.8,
            ),
          ),
        ],
      ],
    );
  }
}