import 'dart:math';

import 'package:advanced_calculator_3/models/constants.dart';
import 'package:advanced_calculator_3/models/custom_class.dart';
import 'package:calculus/calculus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase/supabase.dart';
import 'package:uuid/v4.dart';
import 'dart:convert';

import 'custom_function.dart';
import 'custom_instance.dart';

class DefaultFunction {
  final String name;
  final dynamic value;
  final String description;
  final List<String> parameters;

  bool get isFunction => value is Function || parameters.isNotEmpty;

  const DefaultFunction(
      this.name, this.value, this.description, this.parameters);
}

class AppState {
  final Map<String, dynamic> myVariables;
  final Map<String, CustomFunction> myFunctions;
  final Map<String, CustomClass> myClasses;
  final bool radDeg;
  final bool floatInt;
  final List<(String, String)> logs;
  final String uuid;
  final SupabaseClient supabase;

  static const toDeg = 180 / pi;
  static const toRad = pi / 180;

  const AppState({
    required this.myVariables,
    required this.myFunctions,
    required this.myClasses,
    required this.radDeg,
    required this.floatInt,
    required this.logs,
    required this.uuid,
    required this.supabase,
  });

  Map<String, dynamic> get hiddenContext => {
        "cond": const CustomFunction("x ? a : b", ["x", "a", "b"]),
      };

  Map<String, dynamic> get contextWithoutCalculus => Map.from(context)
    ..remove("slope")
    ..remove("area");

  Map<String, dynamic> get context => {}
    ..addAll(
        {for (var function in defaultFunctions) function.name: function.value})
    ..addAll(hiddenContext)
    ..addAll(myVariables)
    ..addAll(myFunctions)
    ..addAll(myClasses);

  num slope(dynamic fn, num x) {
    num helper(num Function(num) fn, num x) {
      return (fn(x + 1e-5) - fn(x)) / (1e-5);
    }

    if (fn is num Function(num)) {
      return helper(fn, x);
    }
    if (fn is CustomFunction) {
      return helper((x) => fn.call([x], contextWithoutCalculus), x);
    }
    return double.nan;
  }

  num area(dynamic fn, num a, num b) {
    if (fn is num Function(num)) {
      return Calculus.integral(a, b, fn, 100);
    }
    if (fn is CustomFunction) {
      return Calculus.integral(
          a, b, (x) => fn.call([x], contextWithoutCalculus), 100);
    }
    return double.nan;
  }

  static int factorial(int n) {
    if (n < 0) {
      throw ArgumentError("Factorial is not defined for negative numbers");
    }
    int result = 1;
    for (int i = 2; i <= n; i++) {
      result *= i;
    }
    return result;
  }

  static int gcd(int a, int b) {
    while (b != 0) {
      int temp = b;
      b = a % b;
      a = temp;
    }
    return a.abs();
  }

  List<DefaultFunction> get defaultFunctions => [
        const DefaultFunction("sqrt", sqrt, "Find the square root of x", ["x"]),
        const DefaultFunction(
            "pow", pow, "Elevate x to the power of b", ["x", "b"]),
        DefaultFunction("mod", (x, b) => x % b,
            "Find the remainder when x is divided by b", ["x", "b"]),
        const DefaultFunction(
            "fact", factorial, "Find the factorial of n", ["n"]),
        DefaultFunction("floor", (double x) => x.floor(),
            "Round to the leftmost integer", ["x"]),
        DefaultFunction("ceil", (double x) => x.ceil(),
            "Round to the rightmost integer", ["x"]),
        DefaultFunction("round", (double x) => x.round(),
            "Round to the nearest integer", ["x"]),
        DefaultFunction(
            "abs", (num x) => x.abs(), "Find the absolute value of x", ["x"]),
        DefaultFunction("sign", (num x) => x == 0 ? 0 : x / x.abs(),
            "Find the signum of x", ["x"]),
        const DefaultFunction("gcd", gcd,
            "Find the greatest common denominator between a and b", ["a", "b"]),
        const DefaultFunction(
            "ln", log, "Find the natural logarithm of x", ["x"]),
        DefaultFunction("log", (x) => log(x) / log(10),
            "Find the common logarithm of x", ["x"]),
        DefaultFunction("cos", (x) => cos(radDeg ? x : x * toRad),
            "Find the cosine of x", ["x"]),
        DefaultFunction("sin", (x) => sin(radDeg ? x : x * toRad),
            "Find the sine of x", ["x"]),
        DefaultFunction("tan", (x) => tan(radDeg ? x : x * toRad),
            "Find the tangent of x", ["x"]),
        DefaultFunction("acos", (x) => acos(x) * (radDeg ? 1 : toDeg),
            "Find the arccosine of x", ["x"]),
        DefaultFunction("asin", (x) => asin(x) * (radDeg ? 1 : toDeg),
            "Find the arcsine of x", ["x"]),
        DefaultFunction(
            "atan",
            (x, [b]) =>
                (b == null ? atan(x) : atan2(x, b)) * (radDeg ? 1 : toDeg),
            "Find the arctangent of x\n\nFind the angle between the x-axis and <b, x> if b is provided",
            ["x", "b?"]),
        DefaultFunction("slope", slope,
            "Find the slope of fn(x) evaluated on x", ["fn", "x"]),
        DefaultFunction(
            "area",
            area,
            "Find the area under the curve of fn(x) from a to b",
            ["fn", "a", "b"]),
        const DefaultFunction("pi", pi, "Value of π", []),
        const DefaultFunction("e", e, "Value of e", []),
      ];

  static const List<DefaultFunction> logicFunctions = [
    DefaultFunction("false", "false", "Constant for false", []),
    DefaultFunction("true", "true", "Constant for true", []),
    DefaultFunction("!", "!", "Not operator", []),
    DefaultFunction("=", "=", "Double for equals, can pair with others", []),
    DefaultFunction("<", "<",
        "If single then less than, if double then left bit-shift", []),
    DefaultFunction(">", ">",
        "If single then greater than, if double then right bit-shift", []),
    DefaultFunction(
        "&", "&", "If single then bitwise AND, if double then logical AND", []),
    DefaultFunction(
        "|", "|", "If single then bitwise OR, if double then logical OR", []),
    DefaultFunction("^", "^", "Bitwise XOR operator", []),
    DefaultFunction("cond", "cond", "If x then a, else b", ["x", "a", "b"]),
  ];

  static Map<String, dynamic> readVariables(SharedPreferences preferences) {
    final decoded =
        jsonDecode(preferences.getString("myVariables") ?? emptyJson)
            as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, CustomInstance.fromJsonValue(v)));
  }

  static Map<String, CustomFunction> readFunctions(
      SharedPreferences preferences) {
    final decoded =
        jsonDecode(preferences.getString("myFunctions") ?? emptyJson)
            as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, CustomFunction.fromJson(v)));
  }

  static Map<String, CustomClass> readClasses(SharedPreferences preferences) {
    final decoded = jsonDecode(preferences.getString("myClasses") ?? emptyJson)
        as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, CustomClass.fromJson(v)));
  }

  static bool readRadDeg(SharedPreferences preferences) {
    return preferences.getBool("radDeg") ?? true;
  }

  static bool readFloatInt(SharedPreferences preferences) {
    return preferences.getBool("floatInt") ?? true;
  }

  static String readUuid(SharedPreferences preferences) {
    return preferences.getString("uuid") ?? const UuidV4().generate();
  }

  static AppState loadFromPreferences(SharedPreferences preferences) {
    final supabase = SupabaseClient(
        const String.fromEnvironment("SUPABASE_URL"),
        const String.fromEnvironment("SUPABASE_KEY"));
    return AppState(
      myVariables: readVariables(preferences),
      myFunctions: readFunctions(preferences),
      myClasses: readClasses(preferences),
      radDeg: readRadDeg(preferences),
      floatInt: readFloatInt(preferences),
      logs: [],
      uuid: readUuid(preferences),
      supabase: supabase,
    );
  }
}

class AppCubit extends Cubit<AppState> {
  final SharedPreferences preferences;

  AppCubit(this.preferences) : super(AppState.loadFromPreferences(preferences));

  Future<void> saveAppState() async {
    await preferences.setString(
        "myVariables",
        jsonEncode(state.myVariables
            .map((k, v) => MapEntry(k, v is CustomInstance ? v.toJson() : v))));
    await preferences.setString("myFunctions",
        jsonEncode(state.myFunctions.map((k, v) => MapEntry(k, v.toJson()))));
    await preferences.setString("myClasses",
        jsonEncode(state.myClasses.map((k, v) => MapEntry(k, v.toJson()))));
    await preferences.setBool("radDeg", state.radDeg);
    await preferences.setBool("floatInt", state.floatInt);
    await preferences.setString("uuid", state.uuid);
  }

  Future<void> update(
      {Map<String, dynamic>? myVariables,
      Map<String, CustomFunction>? myFunctions,
      Map<String, CustomClass>? myClasses,
      Map<String, dynamic>? globalUtils,
      bool? radDeg,
      bool? floatInt,
      List<(String, String)>? logs}) async {
    emit(AppState(
      myVariables: myVariables ?? state.myVariables,
      myFunctions: myFunctions ?? state.myFunctions,
      myClasses: myClasses ?? state.myClasses,
      radDeg: radDeg ?? state.radDeg,
      floatInt: floatInt ?? state.floatInt,
      logs: logs ?? state.logs,
      uuid: state.uuid,
      supabase: state.supabase,
    ));
    await saveAppState();
  }

  Map<String, dynamic> get context => state.context;

  bool nameExists(String name) {
    return state.myVariables.containsKey(name) ||
        state.myFunctions.containsKey(name) ||
        state.myClasses.containsKey(name);
  }

  (String, dynamic)? getValidVariable(String name, dynamic value) {
    if (!isName(name) || value == null) return null;
    if (nameExists(name) && !state.myVariables.containsKey(name)) return null;
    return (name, value);
  }

  void addVariable(String name, dynamic value) {
    update(myVariables: state.myVariables..addAll({name: value}));
  }

  (String, CustomFunction)? getValidFunction(
      String name, String function, List<String> parameters) {
    if (!isName(name) ||
        function.isEmpty ||
        parameters.any((e) => !isName(e))) {
      return null;
    }
    if (nameExists(name) && !state.myFunctions.containsKey(name)) return null;
    return (name, CustomFunction(function, parameters));
  }

  void addFunction(String name, CustomFunction function) {
    update(myFunctions: state.myFunctions..addAll({name: function}));
  }

  bool addClass(
      String name,
      List<String> fields,
      Map<String, CustomFunction> functions,
      Map<String, dynamic> staticVariables,
      Map<String, CustomFunction> staticFunctions) {
    if (!isName(name) || fields.any((e) => !isName(e))) return false;
    if (nameExists(name) && !state.myClasses.containsKey(name)) return false;
    update(
        myClasses: state.myClasses
          ..addAll({
            name: CustomClass(
                name, fields, functions, staticVariables, staticFunctions)
          }));
    return true;
  }

  bool remove(String name) {
    if (!nameExists(name)) return false;
    if (state.myVariables.containsKey(name)) {
      update(myVariables: state.myVariables..remove(name));
    }
    if (state.myFunctions.containsKey(name)) {
      update(myFunctions: state.myFunctions..remove(name));
    }
    if (state.myClasses.containsKey(name)) {
      update(myClasses: state.myClasses..remove(name));
    }
    return true;
  }

  void toggleRadDeg() {
    update(radDeg: !state.radDeg);
  }

  void toggleFloatInt() {
    update(floatInt: !state.floatInt);
  }

  void addLog(String expression, String result) {
    if (state.logs.length >= 100) {
      state.logs.removeAt(0);
    }
    update(logs: state.logs..add((expression, result)));
  }
}
