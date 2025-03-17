import 'dart:math';

import 'package:advanced_calculator_3/models/custom_class.dart';
import 'package:advanced_calculator_3/models/custom_evaluator.dart';
import 'package:advanced_calculator_3/models/custom_function.dart';
import 'package:advanced_calculator_3/models/custom_instance.dart';

void main() async {
  final global = {
    "sqrt": sqrt,
    "pow": pow,
    "str": (x) => x.toString(),
  };

  final classes = {
    "Class1": const CustomClass("Class1", ["a", "b"],
        {"method1": CustomFunction("4 * a + b", [])}, {}, {}),
    "Vector": const CustomClass("Vector", [
      "x",
      "y"
    ], {
      "add": CustomFunction(
          "Vector(this.x + other.x, this.y + other.y)", ["other"]),
      "neg": CustomFunction("Vector(-this.x, -this.y)", []),
      "mul": CustomFunction(
          "Vector(this.x * scalar, this.y * scalar)", ["scalar"]),
      "magnitude": CustomFunction("sqrt(pow(this.x, 2) + pow(this.y, 2))", []),
      "cmp": CustomFunction("this.magnitude() - other.magnitude()", ["other"]),
    }, {
      "up": CustomInstance("Vector", [0, 1])
    }, {}),
    "VectorPair": const CustomClass("VectorPair", ["v1", "v2"], {}, {}, {}),
  };
  classes["Vector"] = classes["Vector"]!
      .addStaticVariable("right", const CustomInstance("Vector", [1, 0]));

  final functions = {
    "funct1": const CustomFunction("2*x + 1", ["x"]),
  };

  final variables = {
    "instance1": const CustomInstance("Class1", [1, 2]),
    "v1": const CustomInstance("Vector", [1, 2]),
    "v2": const CustomInstance("Vector", [3, 4]),
  };
  variables["vp"] =
      CustomInstance("VectorPair", [variables["v1"], variables["v2"]]);

  final context = <String, dynamic>{}
    ..addAll(global)
    ..addAll(classes)
    ..addAll(functions)
    ..addAll(variables);

  print(CustomEvaluator.evaluate('Vector(1,2) * 2', context));
}
