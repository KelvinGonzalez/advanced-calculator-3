import 'custom_evaluator.dart';

class CustomFunction {
  final String function;
  final List<String> parameters;

  const CustomFunction(this.function, this.parameters);

  dynamic call(List<dynamic> arguments, [Map<String, dynamic>? context]) {
    if (arguments.length != parameters.length) {
      throw Exception("Arguments and parameters are not the same size");
    }
    final mappedArguments = {
      for (int i = 0; i < arguments.length; i++) parameters[i]: arguments[i]
    };
    return CustomEvaluator.evaluate(
        function, Map.from(context ?? {})..addAll(mappedArguments));
  }

  Map<String, dynamic> toJson() => {
        "function": function,
        "parameters": parameters,
      };

  static CustomFunction fromJson(Map<String, dynamic> json) =>
      CustomFunction(json["function"], List<String>.from(json["parameters"]));

  @override
  String toString() => "f(${parameters.join(",")}) = $function";
}
