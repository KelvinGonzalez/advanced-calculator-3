import 'package:advanced_calculator_3/models/custom_class.dart';
import 'package:advanced_calculator_3/models/custom_function.dart';

class CustomInstance {
  final String className;
  final List<dynamic> fieldValues;

  static const unary = {
    "-": "neg",
    "+": "pos",
    // "!": "not",
    // "~": "inv",
  };

  static const binary = {
    "+": "add",
    "-": "sub",
    "*": "mul",
    "/": "div",
    // "%": "mod",
    // "&": "and",
    // "|": "or",
    // "^": "xor",
  };

  static bool isSpecialFunction(String name) =>
      unary.values.contains(name) || binary.values.contains(name)
      // || ["cmp"].contains(name)
      ;

  const CustomInstance(this.className, this.fieldValues);

  dynamic get(String name, CustomClass parent) {
    var index = parent.fields.indexOf(name);
    if (index != -1) return fieldValues[index];
    var function = parent.functions[name];
    if (function != null) return InstanceFunctionPair(this, function);
    throw Exception("Name does not exist");
  }

  Map<String, dynamic> getAllFields(CustomClass parent) {
    return {
      for (int i = 0; i < parent.fields.length; i++)
        parent.fields[i]: fieldValues[i]
    };
  }

  dynamic operatorCall(String operator, CustomClass parent,
      {dynamic other, Map<String, dynamic>? context}) {
    // final cmp = {
    //   "==": (x) => x == 0,
    //   "!=": (x) => x != 0,
    //   ">": (x) => x > 0,
    //   "<": (x) => x < 0,
    //   ">=": (x) => x >= 0,
    //   "<=": (x) => x <= 0,
    // };

    if (other == null) {
      if (unary.containsKey(operator) &&
          parent.functions.containsKey(unary[operator])) {
        final function = parent.functions[unary[operator]]!;
        return InstanceFunctionPair(this, function).call([], parent, context);
      }
    } else {
      // if (cmp.containsKey(operator) && parent.functions.containsKey("cmp")) {
      //   final function = parent.functions["cmp"]!;
      //   return cmp[operator]!(InstanceFunctionPair(this, function)
      //       .call([other], parent, context));
      // }
      if (binary.containsKey(operator) &&
          parent.functions.containsKey(binary[operator])) {
        final function = parent.functions[binary[operator]]!;
        return InstanceFunctionPair(this, function)
            .call([other], parent, context);
      }
    }
    return null;
  }

  @override
  String toString() {
    return "$className(${fieldValues.join(",")})";
  }

  Map<String, dynamic> toJson() => {
        "className": className,
        "fieldValues": fieldValues.map((e) {
          if (e is CustomInstance) {
            return e.toJson();
          }
          return e;
        }).toList(),
      };

  static CustomInstance fromJson(Map<String, dynamic> json) {
    final className = json["className"];
    return CustomInstance(
        className, json["fieldValues"].map((e) => fromJsonValue(e)).toList());
  }

  static bool valueIsInstance(dynamic value) =>
      value is Map<String, dynamic> &&
      value.containsKey("className") &&
      value.containsKey("fieldValues");

  static dynamic fromJsonValue(dynamic value) =>
      valueIsInstance(value) ? fromJson(value) : value;
}

class InstanceFunctionPair {
  final CustomInstance instance;
  final CustomFunction function;

  const InstanceFunctionPair(this.instance, this.function);

  dynamic call(List<dynamic> arguments, CustomClass parent,
      [Map<String, dynamic>? context]) {
    final fields = instance.getAllFields(parent)..addAll(context ?? {});
    fields["this"] = instance;
    return function.call(arguments, fields);
  }
}
