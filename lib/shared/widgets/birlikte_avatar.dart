import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Yuvarlak avatar (Figma: `avatar` 80x80, radius 999).
///
/// Figma'da yerine örnek bir portre fotoğrafı konmuş; gerçek uygulamada bu
/// kullanıcının profil fotoğrafı. Fotoğraf yoksa ya da yüklenemezse marka
/// zeminde baş harflere düşer — stok fotoğraf uygulamaya gömülmedi.
class BirlikteAvatar extends StatelessWidget {
  const BirlikteAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 80,
  });

  final String name;
  final String? imageUrl;
  final double size;

  /// "Ayşe Yılmaz" → "AY", tek kelimeyse "A".
  String get _initials {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    if (words.isEmpty) return '';
    final letters = words.take(2).map((w) => w.characters.first.toUpperCase());
    return letters.join();
  }

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox.square(
        dimension: size,
        child: switch (imageUrl) {
          final url? when url.isNotEmpty => CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            placeholder: (_, _) => _Initials(text: _initials, size: size),
            errorWidget: (_, _, _) => _Initials(text: _initials, size: size),
          ),
          _ => _Initials(text: _initials, size: size),
        },
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.text, required this.size});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surfaceBrand,
      child: Center(
        child: Text(
          text,
          style: AppTypography.h3.copyWith(
            color: AppColors.textBrand,
            // Baş harfler avatarın çapına göre ölçeklenir.
            fontSize: size * 0.34,
          ),
        ),
      ),
    );
  }
}
