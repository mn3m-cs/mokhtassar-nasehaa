// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

enum ZikrTitleNodeType {
  category,
  content;

  static ZikrTitleNodeType fromDatabase(String value) {
    return ZikrTitleNodeType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => throw ArgumentError.value(
        value,
        'value',
        'Unsupported title node type',
      ),
    );
  }
}

class ZikrTitle extends Equatable {
  final int id;
  final int order;
  final String name;
  final String freq;
  final int? parentId;
  final ZikrTitleNodeType nodeType;

  const ZikrTitle({
    required this.id,
    required this.order,
    required this.name,
    required this.freq,
    this.parentId,
    this.nodeType = ZikrTitleNodeType.content,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'order': order,
      'name': name,
      'freq': freq,
      'parentId': parentId,
      'nodeType': nodeType.name,
    };
  }

  factory ZikrTitle.fromMap(Map<String, dynamic> map) {
    return ZikrTitle(
      id: map['id'] as int,
      order: map['order'] as int,
      name: map['name'] as String,
      freq: map['freq'] as String,
      parentId: map['parentId'] as int?,
      nodeType: ZikrTitleNodeType.fromDatabase(
        map['nodeType'] as String,
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory ZikrTitle.fromJson(String source) =>
      ZikrTitle.fromMap(json.decode(source) as Map<String, dynamic>);

  ZikrTitle copyWith({
    int? id,
    int? order,
    String? name,
    String? freq,
    int? parentId,
    bool clearParent = false,
    ZikrTitleNodeType? nodeType,
  }) {
    return ZikrTitle(
      id: id ?? this.id,
      order: order ?? this.order,
      name: name ?? this.name,
      freq: freq ?? this.freq,
      parentId: clearParent ? null : parentId ?? this.parentId,
      nodeType: nodeType ?? this.nodeType,
    );
  }

  @override
  List<Object?> get props => [id, order, name, freq, parentId, nodeType];
}
