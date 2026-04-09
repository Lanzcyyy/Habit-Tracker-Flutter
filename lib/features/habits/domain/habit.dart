class Habit {
  Habit({
    required this.id,
    required this.name,
    required Set<String> completedDates,
    required Set<String> completionMoments,
    required Set<String> rewardedDates,
  }) : completedDates = Set<String>.from(completedDates),
       completionMoments = Set<String>.from(completionMoments),
       rewardedDates = Set<String>.from(rewardedDates);

  final String id;
  final String name;
  final Set<String> completedDates;
  final Set<String> completionMoments;
  final Set<String> rewardedDates;

  bool isCompletedOn(DateTime date) {
    return completedDates.contains(dayKey(date));
  }

  Habit copyWith({
    String? id,
    String? name,
    Set<String>? completedDates,
    Set<String>? completionMoments,
    Set<String>? rewardedDates,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      completedDates: completedDates ?? this.completedDates,
      completionMoments: completionMoments ?? this.completionMoments,
      rewardedDates: rewardedDates ?? this.rewardedDates,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'completedDates': completedDates.toList()..sort(),
      'completionMoments': completionMoments.toList()..sort(),
      'rewardedDates': rewardedDates.toList()..sort(),
    };
  }

  factory Habit.fromJson(Map<String, dynamic> json) {
    final rawDates = (json['completedDates'] as List<dynamic>? ?? <dynamic>[])
        .map((dynamic e) => e.toString())
        .toSet();
    final rawMoments =
        (json['completionMoments'] as List<dynamic>? ?? <dynamic>[])
            .map((dynamic e) => e.toString())
            .toSet();
    final rawRewardedDates =
        (json['rewardedDates'] as List<dynamic>? ?? <dynamic>[])
            .map((dynamic e) => e.toString())
            .toSet();

    return Habit(
      id: json['id'].toString(),
      name: json['name'].toString(),
      completedDates: rawDates,
      completionMoments: rawMoments,
      rewardedDates: rawRewardedDates,
    );
  }
}

String dayKey(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
