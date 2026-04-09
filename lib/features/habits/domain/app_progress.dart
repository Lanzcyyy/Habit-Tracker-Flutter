import 'dart:math';

class AppProgress {
  const AppProgress({required this.totalXp, required this.shields});

  final int totalXp;
  final int shields;

  double get level {
    return sqrt(totalXp) * 0.1;
  }

  AppProgress copyWith({int? totalXp, int? shields}) {
    return AppProgress(
      totalXp: totalXp ?? this.totalXp,
      shields: shields ?? this.shields,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'totalXp': totalXp, 'shields': shields};
  }

  factory AppProgress.fromJson(Map<String, dynamic> json) {
    return AppProgress(
      totalXp: (json['totalXp'] as num? ?? 0).toInt(),
      shields: (json['shields'] as num? ?? 0).toInt(),
    );
  }

  static const AppProgress empty = AppProgress(totalXp: 0, shields: 0);
}
