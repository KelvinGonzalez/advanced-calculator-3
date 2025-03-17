import 'dart:math';

import 'package:advanced_calculator_3/models/constants.dart';
import 'package:advanced_calculator_3/models/custom_class.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'custom_function.dart';
import 'custom_instance.dart';

class AppState {
  final Map<String, dynamic> myVariables;
  final Map<String, CustomFunction> myFunctions;
  final Map<String, CustomClass> myClasses;
  final bool radDeg;
  final bool floatInt;
  final List<(String, String)> logs;

  static const toDeg = 180 / pi;
  static const toRad = pi / 180;

  const AppState(
      {required this.myVariables,
      required this.myFunctions,
      required this.myClasses,
      required this.radDeg,
      required this.floatInt,
      required this.logs});

  Map<String, dynamic> get defaultFunctions => {
        "sqrt": sqrt,
        "pow": pow,
        "mod": (x, b) => x % b,
        "floor": (double x) => x.floor(),
        "ceil": (double x) => x.ceil(),
        "round": (double x) => x.round(),
        "ln": log,
        "log": (x) => log(x) / log(10),
        "cos": (x) => cos(radDeg ? x : x * toRad),
        "sin": (x) => sin(radDeg ? x : x * toRad),
        "tan": (x) => tan(radDeg ? x : x * toRad),
        "acos": (x) => acos(x) * (radDeg ? 1 : toDeg),
        "asin": (x) => asin(x) * (radDeg ? 1 : toDeg),
        "atan": (x) => atan(x) * (radDeg ? 1 : toDeg),
        "pi": pi,
        "e": e,
      };

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

  static AppState loadFromPreferences(SharedPreferences preferences) {
    return AppState(
      myVariables: readVariables(preferences),
      myFunctions: readFunctions(preferences),
      myClasses: readClasses(preferences),
      radDeg: readRadDeg(preferences),
      floatInt: readFloatInt(preferences),
      logs: [],
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
        logs: logs ?? state.logs));
    await saveAppState();
  }

  Map<String, dynamic> get context {
    return {}
      ..addAll(state.defaultFunctions)
      ..addAll(state.myVariables)
      ..addAll(state.myFunctions)
      ..addAll(state.myClasses);
  }

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
