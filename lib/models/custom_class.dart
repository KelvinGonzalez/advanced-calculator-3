import 'package:advanced_calculator_3/models/custom_function.dart';
import 'package:advanced_calculator_3/models/custom_instance.dart';

class CustomClass {
  final String name;
  final List<String> fields;
  final Map<String, CustomFunction> functions;
  final Map<String, dynamic> staticVariables;
  final Map<String, CustomFunction> staticFunctions;

  const CustomClass(this.name, this.fields, this.functions,
      this.staticVariables, this.staticFunctions);

  CustomInstance create(List<dynamic> fieldValues) {
    if (fields.length != fieldValues.length) {
      throw Exception("Fields and values length are not the same");
    }
    return CustomInstance(name, fieldValues);
  }

  dynamic get(String name) {
    if (staticVariables.containsKey(name)) return staticVariables[name];
    if (staticFunctions.containsKey(name)) return staticFunctions[name];
    throw Exception("Name does not exist");
  }

  CustomClass addFunction(String name, CustomFunction function) {
    final c = copy();
    c.functions[name] = function;
    return c;
  }

  CustomClass addStaticVariable(String name, dynamic value) {
    final c = copy();
    c.staticVariables[name] = value;
    return c;
  }

  CustomClass addStaticFunction(String name, CustomFunction function) {
    final c = copy();
    c.staticFunctions[name] = function;
    return c;
  }

  Map<String, dynamic> toJson() => {
        "name": name,
        "fields": fields,
        "functions": functions.map((k, v) => MapEntry(k, v.toJson())),
        "staticVariables": staticVariables.map((k, v) {
          if (v is CustomInstance) {
            return MapEntry(k, v.toJson());
          }
          return MapEntry(k, v);
        }),
        "staticFunctions":
            staticFunctions.map((k, v) => MapEntry(k, v.toJson())),
      };

  static CustomClass fromJson(Map<String, dynamic> json) {
    final customClass = CustomClass(
      json["name"],
      List<String>.from(json["fields"]),
      Map<String, CustomFunction>.from(json["functions"]
          .map((k, v) => MapEntry(k, CustomFunction.fromJson(v)))),
      Map<String, dynamic>.from(json["staticVariables"]
          .map((k, v) => MapEntry(k, CustomInstance.fromJsonValue(v)))),
      Map<String, CustomFunction>.from(json["staticFunctions"]
          .map((k, v) => MapEntry(k, CustomFunction.fromJson(v)))),
    );
    return customClass;
  }

  CustomClass copy() => CustomClass.fromJson(toJson());

  @override
  String toString() => "$name(${fields.join(",")})";
}
