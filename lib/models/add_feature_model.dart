// lib/models/add_feature_model.dart

/// A single parameter definition.
/// Mirrors the one in your sheet, but lives in models so both UI & provider share it.
class ParamDefinition {
  String name;
  String type;      // “Text”, “Number”, or “Dropdown”
  String options;   // comma‑separated, only for dropdown

  ParamDefinition({
    required this.name,
    required this.type,
    required this.options,
  });

  ParamDefinition.fromJson(Map<String,dynamic> json)
      : name = json['name'],
        type = json['type'],
        options = json['options'];

  Map<String,dynamic> toJson() => {
    'name': name,
    'type': type,
    'options': options,
  };
}

/// One “feature” / category that you dynamically add:
class FeatureCategory {
  String name;
  List<ParamDefinition> params;

  FeatureCategory({ required this.name, required this.params });

  FeatureCategory.fromJson(Map<String,dynamic> json)
      : name = json['name'],
        params = (json['params'] as List)
            .map((e) => ParamDefinition.fromJson(e))
            .toList();

  Map<String,dynamic> toJson() => {
    'name': name,
    'params': params.map((e) => e.toJson()).toList(),
  };
}


