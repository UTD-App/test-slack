import 'package:equatable/equatable.dart';

class BoomRuleModel extends Equatable {
  final int id;
  final String rulesAr;
  final String rulesEn;
  final String content;

  const BoomRuleModel({
    required this.id,
    required this.rulesAr,
    required this.rulesEn,
    required this.content,
  });

  factory BoomRuleModel.fromJson(Map<String, dynamic> json) {
    return BoomRuleModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      rulesAr: json['rules_ar'] as String? ?? '',
      rulesEn: json['rules_en'] as String? ?? '',
      content: json['content'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [id];
}
