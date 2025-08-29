// ignore_for_file: public_member_api_docs
typedef JsonMap = Map<String, dynamic>;

class PaginatedResponse<T> {
  final List<T> content;
  final int totalElements;
  final int totalPages;
  final int number;
  final int size;
  final bool first;
  final bool last;
  final int numberOfElements;

  const PaginatedResponse({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.number,
    required this.size,
    required this.first,
    required this.last,
    required this.numberOfElements,
  });

  factory PaginatedResponse.fromJson(
      JsonMap json,
      T Function(JsonMap) fromJsonT,
      ) {
    final rawContent = (json['content'] as List?) ?? const [];
    return PaginatedResponse<T>(
      content: rawContent
          .map((item) => fromJsonT(item as JsonMap))
          .toList(growable: false),
      totalElements: _asInt(json['totalElements']),
      totalPages: _asInt(json['totalPages']),
      number: _asInt(json['number']),
      size: _asInt(json['size']),
      first: _asBool(json['first'], defaultValue: true),
      last: _asBool(json['last'], defaultValue: true),
      numberOfElements: _asInt(json['numberOfElements']),
    );
  }

  PaginatedResponse<T> copyWith({
    List<T>? content,
    int? totalElements,
    int? totalPages,
    int? number,
    int? size,
    bool? first,
    bool? last,
    int? numberOfElements,
  }) {
    return PaginatedResponse<T>(
      content: content ?? this.content,
      totalElements: totalElements ?? this.totalElements,
      totalPages: totalPages ?? this.totalPages,
      number: number ?? this.number,
      size: size ?? this.size,
      first: first ?? this.first,
      last: last ?? this.last,
      numberOfElements: numberOfElements ?? this.numberOfElements,
    );
  }

  static int _asInt(Object? v, {int defaultValue = 0}) {
    if (v == null) return defaultValue;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? defaultValue;
    return defaultValue;
  }

  static bool _asBool(Object? v, {bool defaultValue = false}) {
    if (v == null) return defaultValue;
    if (v is bool) return v;
    if (v is String) {
      final s = v.toLowerCase();
      if (s == 'true') return true;
      if (s == 'false') return false;
    }
    return defaultValue;
  }
}
