import 'dart:math';

import 'package:advanced_calculator_3/models/app_state.dart';
import 'package:advanced_calculator_3/models/constants.dart';
import 'package:advanced_calculator_3/models/custom_class.dart';
import 'package:advanced_calculator_3/models/custom_evaluator.dart';
import 'package:advanced_calculator_3/models/custom_function.dart';
import 'package:advanced_calculator_3/models/custom_instance.dart';
import 'package:advanced_calculator_3/pages/widgets_lib.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class KeyboardKey {
  final Widget label;
  final String key;
  final bool isFunction;
  final bool isMember;
  final CustomClass? parent;

  const KeyboardKey(this.label, this.key,
      {this.isFunction = false, this.isMember = false, this.parent});

  int getCategoryCompareValue() {
    final isFunctionValue = isFunction ? 0 : 1;
    final isMemberValue = isMember ? 0 : 1;
    final isStaticValue = parent != null ? 1 : 0;
    return (isFunctionValue << 2) + (isMemberValue << 1) + isStaticValue;
  }

  int compare(KeyboardKey other) {
    final thisValue = getCategoryCompareValue();
    final otherValue = other.getCategoryCompareValue();
    if (thisValue != otherValue) return thisValue - otherValue;
    return key.compareTo(other.key);
  }
}

class KeyboardInputState {
  List<String> input;
  int cursorPosition;

  KeyboardInputState(this.input, this.cursorPosition);

  KeyboardInputState copy() =>
      KeyboardInputState(List.from(input), cursorPosition);

  @override
  String toString() {
    return "Input: $input, Position: $cursorPosition";
  }
}

class KeyboardFunctionData {
  final CustomFunction function;
  final bool isMember;
  final CustomClass? parent;

  const KeyboardFunctionData(this.function,
      {this.isMember = false, required this.parent});
}

class CustomKeyboard extends StatefulWidget {
  final void Function(String input, dynamic output) onSubmit;
  final KeyboardFunctionData? function;
  final String? initialValue;
  final bool readOnly;
  final String initialView;

  const CustomKeyboard(
      {super.key,
      required this.onSubmit,
      this.function,
      this.initialValue,
      this.readOnly = false,
      this.initialView = "default"});

  @override
  State<CustomKeyboard> createState() => _CustomKeyboardState();
}

GlobalKey<_CustomKeyboardState> createGlobalKey() =>
    GlobalKey<_CustomKeyboardState>();

class _CustomKeyboardState extends State<CustomKeyboard> {
  final List<KeyboardInputState> inputStates = [KeyboardInputState([], 0)];
  final int maxStates = 20;
  double cursorDragValue = 0;
  late String currentView;
  final inputScrollController = ScrollController();
  final cursorGlobalKey = GlobalKey();

  KeyboardInputState get currentState => inputStates.last;
  List<String> get input => currentState.input;
  set input(List<String> x) => currentState.input = x;
  int get cursorPosition => currentState.cursorPosition;
  set cursorPosition(int x) => currentState.cursorPosition = x;

  void recordState() {
    if (inputStates.length >= maxStates) inputStates.removeAt(0);
    inputStates.add(currentState.copy());
  }

  void undo() {
    if (inputStates.length < 2) return;
    inputStates.removeLast();
  }

  void writeToInput(KeyboardKey key) {
    setState(() {
      switch (key.key) {
        case "(":
          recordState();
          final openCount = input.where((e) => e == "(").length;
          final closedCount = input.where((e) => e == ")").length;
          if (openCount == closedCount) {
            if (cursorPosition < input.length) {
              final nextKey = input[cursorPosition];
              if (isNameOrNumber(nextKey) || nextKey == "(") {
                input.insert(cursorPosition, "(");
                cursorPosition++;
                break;
              }
            }
            input.insert(cursorPosition, "(");
            input.insert(cursorPosition + 1, ")");
            cursorPosition++;
            break;
          } else if (openCount > closedCount) {
            if (cursorPosition > 0) {
              final prevKey = input[cursorPosition - 1];
              if (isNameOrNumber(prevKey) || ["(", ")"].contains(prevKey)) {
                input.insert(cursorPosition, ")");
                cursorPosition++;
                break;
              }
            }
            input.insert(cursorPosition, "(");
            cursorPosition++;
            break;
          } else // if openCount < closedCount
          {
            input.insert(cursorPosition, "(");
            cursorPosition++;
            break;
          }
        case "<-":
          if (cursorPosition > 0) cursorPosition--;
          break;
        case "->":
          if (cursorPosition < input.length) cursorPosition++;
          break;
        case "delete":
          if (cursorPosition > 0) {
            recordState();

            // Parenthesis state variables
            final isOpeningParenthesis = input[cursorPosition - 1] == "(";
            final openCount = input.where((e) => e == "(").length;
            final closedCount = input.where((e) => e == ")").length;

            input.removeAt(cursorPosition - 1);
            cursorPosition--;

            if (isOpeningParenthesis &&
                openCount == closedCount &&
                cursorPosition < input.length &&
                input[cursorPosition] == ")") {
              input.removeAt(cursorPosition);
            }
          }
          break;
        case "undo":
          undo();
          break;
        case "radDeg":
          context.read<AppCubit>().toggleRadDeg();
          break;
        case "floatInt":
          context.read<AppCubit>().toggleFloatInt();
          break;
        case "pow":
          recordState();
          final leftEnd = leftEndCursorPosition();
          if (leftEnd != null) {
            input.insert(leftEnd, "pow");
            input.insert(leftEnd + 1, "(");
            input.insert(cursorPosition + 2, ",");
            input.insert(cursorPosition + 3, ")");
            cursorPosition += 3;
          } else {
            _defaultCase(key);
          }
          break;
        case _:
          recordState();
          _defaultCase(key);
          break;
      }
    });
  }

  void _defaultCase(KeyboardKey key) {
    final usingCalculus = cursorPosition >= 2 &&
        input[cursorPosition - 1] == "(" &&
        ["slope", "area"].contains(input[cursorPosition - 2]) &&
        !key.isMember;
    if (key.parent != null) {
      if (key.isMember) {
        if (cursorPosition <= 0 ||
            (input[cursorPosition - 1] != "." &&
                !isName(input[cursorPosition - 1]))) {
          input.insert(cursorPosition, "this");
          cursorPosition++;
        }
      } else {
        if (cursorPosition <= 0 ||
            ![key.parent!.name, "."].contains(input[cursorPosition - 1])) {
          input.insert(cursorPosition, key.parent!.name);
          cursorPosition++;
        }
      }
    }
    if (key.isMember || key.parent != null) {
      if (cursorPosition <= 0 || input[cursorPosition - 1] != ".") {
        input.insert(cursorPosition, ".");
        cursorPosition++;
      }
    }
    input.insert(cursorPosition, key.key);
    cursorPosition++;
    if (!usingCalculus && key.isFunction) {
      if (cursorPosition >= input.length || input[cursorPosition] != "(") {
        final rightEnd = rightEndCursorPosition() ?? cursorPosition;
        input.insert(cursorPosition, "(");
        input.insert(rightEnd + 1, ")");
        cursorPosition = rightEnd + 1;
      }
    }
  }

  String mergeInput() => input.join("");

  int? leftEndCursorPositionHelper([int? cursorPosition]) {
    cursorPosition ??= this.cursorPosition;
    if (cursorPosition <= 0) return null;
    final prevKey = input[cursorPosition - 1];
    if (nameRegex.hasMatch(prevKey)) return cursorPosition - 1;
    if (numberRegex.hasMatch(prevKey)) {
      int i;
      for (i = cursorPosition - 2; i >= 0; i--) {
        if (!numberRegex.hasMatch(input[i])) break;
      }
      return i + 1;
    }
    if (prevKey == ")") {
      int parenthesisToClose = 1;
      for (int i = cursorPosition - 2; i >= 0; i--) {
        if (input[i] == ")") parenthesisToClose++;
        if (input[i] == "(") parenthesisToClose--;
        if (parenthesisToClose == 0) {
          if (i > 0 && nameRegex.hasMatch(input[i - 1])) return i - 1;
          return i;
        }
      }
    }
    return null;
  }

  int? leftEndCursorPosition([int? cursorPosition]) {
    cursorPosition ??= this.cursorPosition;
    cursorPosition++;
    do {
      cursorPosition = cursorPosition! - 1;
      cursorPosition = leftEndCursorPositionHelper(cursorPosition);
    } while (cursorPosition != null &&
        cursorPosition > 0 &&
        input[cursorPosition - 1] == ".");
    return cursorPosition;
  }

  int? rightEndCursorPositionHelper([int? cursorPosition]) {
    cursorPosition ??= this.cursorPosition;
    if (cursorPosition >= input.length) return null;
    var nextKey = input[cursorPosition];
    if (numberRegex.hasMatch(nextKey)) {
      int i;
      for (i = cursorPosition + 1; i < input.length; i++) {
        if (!numberRegex.hasMatch(input[i])) break;
      }
      return i;
    }
    int newCursorPosition = cursorPosition;
    if (nameRegex.hasMatch(nextKey)) {
      if (cursorPosition + 1 >= input.length ||
          input[cursorPosition + 1] != "(") return cursorPosition + 1;
      newCursorPosition = cursorPosition + 1;
      nextKey = input[newCursorPosition];
    }
    if (nextKey == "(") {
      int parenthesisToClose = 1;
      for (int i = newCursorPosition + 1; i < input.length; i++) {
        if (input[i] == ")") parenthesisToClose--;
        if (input[i] == "(") parenthesisToClose++;
        if (parenthesisToClose == 0) return i + 1;
      }
    }
    return null;
  }

  int? rightEndCursorPosition([int? cursorPosition]) {
    cursorPosition ??= this.cursorPosition;
    cursorPosition--;
    do {
      cursorPosition = cursorPosition! + 1;
      cursorPosition = rightEndCursorPositionHelper(cursorPosition);
    } while (cursorPosition != null &&
        cursorPosition < input.length &&
        input[cursorPosition] == ".");
    return cursorPosition;
  }

  List<String>? convertResultToInput(dynamic result) {
    if (result is CustomFunction ||
        result is Function ||
        result is CustomClass ||
        result == null) {
      return null;
    }
    final characters = result.toString().characters;
    final input = <String>[];
    int? nameStart;
    for (var char in characters.indexed) {
      if (nameRegex.hasMatch(char.$2)) {
        nameStart ??= char.$1;
      }
      if (nameStart != null) {
        final currentName =
            characters.getRange(nameStart, char.$1 + 1).join("");
        if (isName(currentName)) continue;
        input.add(characters.getRange(nameStart, char.$1).join(""));
        nameStart = null;
      }
      input.add(char.$2);
    }
    if (nameStart != null) {
      input.add(characters.getRange(nameStart, characters.length).join(""));
    }
    return input;
  }

  List<KeyboardKey> getParentInstanceQuickActions(CustomClass parent) {
    final showThis =
        (widget.function?.isMember ?? false) && widget.function?.parent != null;
    return parent.fields
            .map((e) => KeyboardKey(Text(e), e,
                isFunction: false,
                isMember: true,
                parent: showThis ? parent : null))
            .toList() +
        parent.functions.keys
            .where((e) => !CustomInstance.isSpecialFunction(e))
            .map((e) => KeyboardKey(Text(e), e,
                isFunction: true,
                isMember: true,
                parent: showThis ? parent : null))
            .toList();
  }

  List<KeyboardKey> getParentStaticQuickActions(CustomClass parent) {
    return parent.staticVariables.keys
            .map((e) => KeyboardKey(Text(e), e,
                isFunction: false, isMember: false, parent: parent))
            .toList() +
        parent.staticFunctions.keys
            .map((e) => KeyboardKey(Text(e), e,
                isFunction: true, isMember: false, parent: parent))
            .toList();
  }

  List<KeyboardKey> getParentQuickActions(CustomClass parent) {
    return getParentInstanceQuickActions(parent) +
        getParentStaticQuickActions(parent);
  }

  void setView(String view) {
    setState(() {
      currentView = view;
    });
  }

  void setInputFromString(String string) {
    setState(() {
      input = convertResultToInput(string) ?? input;
      cursorPosition = input.length;
    });
  }

  double adjustSigFigs(double num, int sigFigs) {
    if (num == 0) return 0;
    double scale =
        pow(10, sigFigs - 1 - (log(num.abs()) / ln10).floor()).toDouble();
    return (num * scale).round() / scale;
  }

  @override
  void initState() {
    super.initState();

    if (widget.initialValue != null) {
      setInputFromString(widget.initialValue!);
    }

    setView(widget.initialView);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(builder: (context, state) {
      final cubit = context.read<AppCubit>();

      final Map<String, Widget> functionWidgets = {
        "default": DefaultFunctionsView(writeToInput: writeToInput),
        "logic": LogicFunctionsView(writeToInput: writeToInput),
        "variables": MyVariablesView(
          writeToInput: writeToInput,
          readOnly: widget.readOnly,
          initialView: currentView,
        ),
        "functions": MyFunctionsView(
          writeToInput: writeToInput,
          readOnly: widget.readOnly,
          initialView: currentView,
        ),
      }..addAll(state.myClasses.map((k, v) => MapEntry(
          k,
          MyClassView(
            writeToInput: writeToInput,
            setView: setView,
            className: k,
            readOnly: widget.readOnly,
            initialView: currentView,
            function: widget.function,
          ))));

      const double outputFontSize = 32;

      late final dynamic result;
      final mergedInput = mergeInput();
      if (widget.function != null) {
        result = mergedInput;
      } else {
        dynamic tempResult =
            CustomEvaluator.evaluate(mergedInput, cubit.context);
        result = tempResult != null &&
                tempResult is! Function &&
                tempResult is! CustomFunction &&
                tempResult is! CustomClass &&
                tempResult is! InstanceFunctionPair &&
                (tempResult is! num ||
                    (!tempResult.isNaN && tempResult.isFinite))
            ? (!state.floatInt && tempResult is double
                ? adjustSigFigs(tempResult, 4)
                : tempResult)
            : null;
      }

      List<KeyboardKey> quickActions = [];
      if (widget.function != null) {
        quickActions = [
              if (widget.function!.isMember)
                const KeyboardKey(Text("this"), "this")
            ] +
            widget.function!.function.parameters
                .where((e) => e.isNotEmpty)
                .map((e) => KeyboardKey(Text(e), e))
                .toList() +
            [
              if (widget.function!.function.function.isNotEmpty)
                KeyboardKey(Text(widget.function!.function.function),
                    widget.function!.function.function,
                    isFunction: true,
                    isMember: widget.function!.isMember,
                    parent: widget.function!.parent)
            ] // Use function.function to obtain name
            +
            (widget.function!.parent != null
                ? getParentInstanceQuickActions(widget.function!.parent!)
                : []);
      } else if (cursorPosition > 1 && input[cursorPosition - 1] == ".") {
        final leftEnd = leftEndCursorPosition(cursorPosition - 1);
        if (leftEnd != null) {
          final left = CustomEvaluator.evaluate(
              input.getRange(leftEnd, cursorPosition - 1).join(""),
              cubit.context);
          if (left is CustomInstance) {
            final parent = cubit.context[left.className] as CustomClass;
            quickActions = getParentInstanceQuickActions(parent);
          }
          if (left is CustomClass) {
            quickActions = getParentStaticQuickActions(left);
          }
        }
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final box =
            cursorGlobalKey.currentContext?.findRenderObject() as RenderBox?;
        final scrollBox = inputScrollController.position.context.storageContext
            .findRenderObject() as RenderBox?;

        if (box == null || scrollBox == null) return;

        final position = box.localToGlobal(Offset.zero, ancestor: scrollBox);
        final widgetWidth = box.size.width;
        final scrollViewWidth = scrollBox.size.width;
        final scrollOffset = inputScrollController.offset;
        final maxScrollExtent = inputScrollController.position.maxScrollExtent;

        // Define the 10-80-10 safe zone
        final leftSafeZone = scrollViewWidth * 0.1; // Left 10% area
        final rightSafeZone = scrollViewWidth * 0.9; // Right 90% area

        final leftEdge = position.dx;
        final rightEdge = position.dx + widgetWidth;

        if (leftEdge < leftSafeZone) {
          inputScrollController.animateTo(
            (scrollOffset + leftEdge - leftSafeZone).clamp(0, maxScrollExtent),
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
          );
        } else if (rightEdge > rightSafeZone) {
          inputScrollController.animateTo(
            (scrollOffset + (rightEdge - rightSafeZone))
                .clamp(0, maxScrollExtent),
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
          );
        }
      });

      return Expanded(
        // height: 512,
        child: Column(
          children: [
            SizedBox(
              height: 96,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                      child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          cursorPosition = input.length;
                        });
                      },
                      child: SingleChildScrollView(
                        controller: inputScrollController,
                        scrollDirection: Axis.horizontal,
                        child: Center(
                            child: Row(
                                children: List.generate(
                                        input.length + 1, (i) => i).map((i) {
                                      final afterCursor = i >= cursorPosition;
                                      final index = afterCursor ? i - 1 : i;
                                      return i == cursorPosition
                                          ? SizedBox(
                                              key: cursorGlobalKey,
                                              height: outputFontSize,
                                              child: const VerticalDivider(
                                                width: 0,
                                                color: Colors.black87,
                                              ))
                                          : GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  cursorPosition = index;
                                                });
                                              },
                                              child: Text(
                                                input[index],
                                                style: TextStyle(
                                                  fontSize: outputFontSize,
                                                  color: Colors.grey[800],
                                                ),
                                              ),
                                            );
                                    }).toList() +
                                    [
                                      const SizedBox(
                                        width: 8,
                                      )
                                    ])),
                      ),
                    ),
                  )),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: IconButton(
                          onPressed: () {
                            setState(() {
                              if (input.isNotEmpty) {
                                recordState();
                                input.clear();
                                cursorPosition = 0;
                              }
                            });
                          },
                          icon: const Icon(Icons.close)),
                    ),
                  ),
                ],
              ),
            ),
            const HeightlessDivider(),
            SizedBox(
              height: 48,
              width: double.infinity,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: quickActions.isEmpty
                    ? Row(
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              result != null && widget.function == null
                                  ? result.toString()
                                  : "Nothing to show here yet...",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[500],
                              ),
                            ),
                          )
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: separateWidgets(
                            quickActions
                                .map((e) => TextButton(
                                    onPressed: () => writeToInput(e),
                                    child: e.label))
                                .toList(),
                            const WidthlessVerticalDivider())),
              ),
            ),
            const HeightlessDivider(),
            Expanded(
                flex: 14,
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      const SizedBox(
                        height: 48,
                        child: TabBar(
                          labelPadding: EdgeInsets.zero,
                          tabs: [
                            Tab(
                              child: Icon(Icons.numbers),
                            ),
                            Tab(
                              child: Icon(Icons.functions),
                            )
                          ],
                        ),
                      ),
                      const HeightlessDivider(),
                      Expanded(
                        flex: 5,
                        child: TabBarView(
                          physics: const CustomTabBarViewScrollPhysics(),
                          // physics: const NeverScrollableScrollPhysics(),
                          children: [
                            NumPad(writeToInput: writeToInput),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                    flex: 3,
                                    child: functionWidgets[currentView] ??
                                        functionWidgets["default"]!),
                                const WidthlessVerticalDivider(),
                                Expanded(
                                  flex: 1,
                                  child: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: separateWidgets(
                                          padWidgets(
                                              <Widget>[
                                                    CategoryButton(
                                                        onPressed: () =>
                                                            setView("default"),
                                                        text: "Default"),
                                                    CategoryButton(
                                                        onPressed: () =>
                                                            setView("logic"),
                                                        text: "Logic"),
                                                    CategoryButton(
                                                        onPressed: () =>
                                                            setView(
                                                                "variables"),
                                                        text: "Variables"),
                                                    CategoryButton(
                                                        onPressed: () =>
                                                            setView(
                                                                "functions"),
                                                        text: "Functions"),
                                                  ] +
                                                  state.myClasses.keys
                                                      .map((e) =>
                                                          CategoryButton(
                                                              onPressed: () =>
                                                                  setView(e),
                                                              text: e))
                                                      .toList() +
                                                  [
                                                    if (!widget.readOnly)
                                                      IconButton(
                                                          onPressed: () =>
                                                              createClass(
                                                                  context,
                                                                  cubit),
                                                          icon: const Icon(
                                                              Icons.add)),
                                                  ],
                                              const EdgeInsets.all(4.0)),
                                          const HeightlessDivider()),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const HeightlessDivider(),
                      Expanded(
                        flex: 1,
                        child: GestureDetector(
                          onHorizontalDragUpdate: (update) {
                            cursorDragValue += update.delta.dx;
                            if (cursorDragValue.abs() < 10) return;
                            if (cursorDragValue < 0) {
                              writeToInput(
                                  const KeyboardKey(Placeholder(), "<-"));
                            } else {
                              writeToInput(
                                  const KeyboardKey(Placeholder(), "->"));
                            }
                            cursorDragValue = 0;
                          },
                          child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                    const KeyboardKey(
                                        Icon(Icons.arrow_back), "<-"),
                                    const KeyboardKey(
                                        Icon(Icons.arrow_forward), "->"),
                                    const KeyboardKey(Icon(Icons.undo), "undo"),
                                  ]
                                      .map((e) => NumpadKey(e, writeToInput))
                                      .toList()
                                      .cast<Widget>() +
                                  [
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(3.0),
                                        child: ElevatedButton(
                                            onPressed: () async {
                                              setState(() {
                                                widget.onSubmit(
                                                    mergedInput, result);
                                                final converted =
                                                    convertResultToInput(
                                                        result);
                                                if (converted != null) {
                                                  recordState();
                                                  input = converted;
                                                  cursorPosition = input.length;
                                                }
                                              });
                                            },
                                            child: Icon(widget.readOnly
                                                ? Icons.send
                                                : CupertinoIcons.equal)),
                                      ),
                                    )
                                  ]),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      );
    });
  }
}

class NumPad extends StatelessWidget {
  final void Function(KeyboardKey) writeToInput;

  const NumPad({super.key, required this.writeToInput});

  @override
  Widget build(BuildContext context) {
    final buttons = [
      [
        const KeyboardKey(NumpadText("√"), "sqrt", isFunction: true),
        const KeyboardKey(NumpadText("^"), "pow", isFunction: true),
        const KeyboardKey(NumpadText("( )"), "("),
        const KeyboardKey(Icon(Icons.backspace), "delete"),
      ],
      [
        const KeyboardKey(NumpadText("7"), "7"),
        const KeyboardKey(NumpadText("8"), "8"),
        const KeyboardKey(NumpadText("9"), "9"),
        const KeyboardKey(Icon(CupertinoIcons.divide), "/"),
      ],
      [
        const KeyboardKey(NumpadText("4"), "4"),
        const KeyboardKey(NumpadText("5"), "5"),
        const KeyboardKey(NumpadText("6"), "6"),
        const KeyboardKey(Icon(CupertinoIcons.multiply), "*"),
      ],
      [
        const KeyboardKey(NumpadText("1"), "1"),
        const KeyboardKey(NumpadText("2"), "2"),
        const KeyboardKey(NumpadText("3"), "3"),
        const KeyboardKey(Icon(CupertinoIcons.minus), "-"),
      ],
      [
        const KeyboardKey(NumpadText("0"), "0"),
        const KeyboardKey(NumpadText(","), ","),
        const KeyboardKey(NumpadText("."), "."),
        const KeyboardKey(Icon(CupertinoIcons.plus), "+"),
      ],
    ];

    return Column(
        children: buttons
            .map((row) => Expanded(
                    child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: row.map((e) => NumpadKey(e, writeToInput)).toList(),
                )))
            .toList());
  }
}

class KeyboardKeyTable extends StatelessWidget {
  final List<KeyboardKey> keys;
  final List<KeyboardKey>? specialKeys;
  final void Function(KeyboardKey) writeToInput;
  final void Function(KeyboardKey)? onLongPress;
  final bool groupKeys;

  const KeyboardKeyTable(
      {super.key,
      required this.keys,
      this.specialKeys,
      required this.writeToInput,
      this.onLongPress,
      this.groupKeys = true});

  List<Widget> generateGroupRows(List<KeyboardKey> keys) {
    const cols = 2;
    final rows = (keys.length / cols).ceil();
    return separateWidgets(
        List.generate(rows, (i) => i)
            .map((i) => Row(
                  children: expandWidgets(padWidgets(
                      List.generate(cols, (j) => j).map((j) {
                        final index = i * cols + j;
                        if (index >= keys.length) {
                          return Container();
                        }
                        final key = keys[i * cols + j];
                        return GestureDetector(
                          onLongPress: () {
                            if (onLongPress != null) onLongPress!(key);
                          },
                          child: CategoryButton(
                            onPressed: () {
                              writeToInput(key);
                            },
                            text:
                                "${key.isMember ? "." : ""}${key.key}${key.isFunction ? "( )" : ""}",
                            center: true,
                          ),
                        );
                      }).toList(),
                      const EdgeInsets.all(4.0))),
                ))
            .toList(),
        const HeightlessDivider(thickness: 0.35));
  }

  @override
  Widget build(BuildContext context) {
    late final List<List<KeyboardKey>> groupedKeys;
    if (groupKeys) {
      final keyGroups = <int, List<KeyboardKey>>{};
      for (final key in keys) {
        final value = key.getCategoryCompareValue();
        if (!keyGroups.containsKey(value)) keyGroups[value] = [];
        keyGroups[value]!.add(key);
      }

      final sortedGroups = keyGroups.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      groupedKeys = sortedGroups.map((e) => e.value).toList();
    } else {
      groupedKeys = [keys];
    }

    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
              Row(
                  children: (specialKeys ?? [])
                      .map((e) => Expanded(
                              child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: TextButton(
                                onPressed: () => writeToInput(e),
                                child: e.label),
                          )))
                      .toList()),
              const HeightlessDivider(),
            ] +
            groupedKeys
                .expand((e) =>
                    generateGroupRows(e) +
                    [if (e != groupedKeys.last) const HeightlessDivider()])
                .toList(),
      ),
    );
  }
}

class DefaultFunctionsView extends StatelessWidget {
  final void Function(KeyboardKey) writeToInput;

  const DefaultFunctionsView({super.key, required this.writeToInput});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(builder: (context, state) {
      final defaultFunctions = state.defaultFunctions;
      return KeyboardKeyTable(
          keys: defaultFunctions
              .map((e) =>
                  KeyboardKey(Text(e.name), e.name, isFunction: e.isFunction))
              .toList(),
          specialKeys: [
            KeyboardKey(
                Text(state.radDeg ? "RAD" : "DEG",
                    style: const TextStyle(fontSize: 18)),
                "radDeg"),
            KeyboardKey(
                Text(state.floatInt ? "FULL" : "ROUND",
                    style: const TextStyle(fontSize: 18)),
                "floatInt")
          ],
          writeToInput: writeToInput,
          onLongPress: (key) {
            final item = defaultFunctions.firstWhere((e) => e.name == key.key);
            showDialog(
                context: context,
                useRootNavigator: false,
                builder: (context) => AlertDialog(
                      title: Text(
                          "${item.name}${item.isFunction ? "(${item.parameters.join(",")})" : ""}"),
                      content: Text(item.description,
                          style:
                              TextStyle(fontSize: 16, color: Colors.grey[800])),
                    ));
          });
    });
  }
}

class LogicFunctionsView extends StatelessWidget {
  final void Function(KeyboardKey) writeToInput;

  const LogicFunctionsView({super.key, required this.writeToInput});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(builder: (context, state) {
      const logicFunctions = AppState.logicFunctions;
      return KeyboardKeyTable(
          keys: logicFunctions
              .map((e) =>
                  KeyboardKey(Text(e.name), e.value, isFunction: e.isFunction))
              .toList(),
          groupKeys: false,
          writeToInput: writeToInput,
          onLongPress: (key) {
            final item = logicFunctions.firstWhere((e) => e.name == key.key);
            showDialog(
                context: context,
                useRootNavigator: false,
                builder: (context) => AlertDialog(
                      title: Text(
                          "${item.name}${item.isFunction ? "(${item.parameters.join(",")})" : ""}"),
                      content: Text(item.description,
                          style:
                              TextStyle(fontSize: 16, color: Colors.grey[800])),
                    ));
          });
    });
  }
}

class MyVariablesView extends StatelessWidget {
  final void Function(KeyboardKey) writeToInput;
  final bool readOnly;
  final String initialView;

  const MyVariablesView(
      {super.key,
      required this.writeToInput,
      this.readOnly = false,
      required this.initialView});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AppCubit>();

    return BlocBuilder<AppCubit, AppState>(builder: (context, state) {
      return Stack(
        alignment: Alignment.bottomRight,
        children: [
          SizedBox(
            height: double.infinity,
            child: KeyboardKeyTable(
              keys: state.myVariables.entries
                  .map((e) => KeyboardKey(Text(e.key), e.key))
                  .toList(),
              writeToInput: writeToInput,
              onLongPress: readOnly
                  ? null
                  : (key) async {
                      final answer = await getConfirmation(
                          "Remove ${key.key}?", context,
                          content:
                              "${key.key} = ${state.myVariables[key.key]}");
                      if (!answer) return;
                      cubit.remove(key.key);
                    },
            ),
          ),
          if (!readOnly)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: IconButton(
                  onPressed: () async {
                    final variable =
                        await createVariable(context, cubit, initialView);
                    if (variable == null) return;
                    cubit.addVariable(variable.$1, variable.$2);
                  },
                  icon: const Icon(
                    Icons.add,
                    size: 24,
                  )),
            )
        ],
      );
    });
  }
}

class MyFunctionsView extends StatelessWidget {
  final void Function(KeyboardKey) writeToInput;
  final bool readOnly;
  final String initialView;

  const MyFunctionsView(
      {super.key,
      required this.writeToInput,
      this.readOnly = false,
      required this.initialView});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AppCubit>();

    return BlocBuilder<AppCubit, AppState>(builder: (context, state) {
      return Stack(
        alignment: Alignment.bottomRight,
        children: [
          SizedBox(
            height: double.infinity,
            child: KeyboardKeyTable(
              keys: state.myFunctions.entries
                  .map((e) => KeyboardKey(Text(e.key), e.key, isFunction: true))
                  .toList(),
              writeToInput: writeToInput,
              onLongPress: readOnly
                  ? null
                  : (key) async {
                      final answer = await getConfirmation(
                          "Remove ${key.key}?", context,
                          content: state.myFunctions[key.key].toString());
                      if (!answer) return;
                      cubit.remove(key.key);
                    },
            ),
          ),
          if (!readOnly)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: IconButton(
                  onPressed: () async {
                    final function =
                        await createFunction(context, cubit, initialView);
                    if (function == null) return;
                    cubit.addFunction(function.$1, function.$2);
                  },
                  icon: const Icon(
                    Icons.add,
                    size: 24,
                  )),
            )
        ],
      );
    });
  }
}

class MyClassView extends StatelessWidget {
  final void Function(KeyboardKey) writeToInput;
  final void Function(String) setView;
  final String className;
  final bool readOnly;
  final String initialView;
  final KeyboardFunctionData? function;

  const MyClassView(
      {super.key,
      required this.writeToInput,
      required this.setView,
      required this.className,
      this.readOnly = false,
      required this.initialView,
      required this.function});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AppCubit>();

    return BlocBuilder<AppCubit, AppState>(builder: (context, state) {
      final parent = state.myClasses[className]!;
      final showThis =
          (function?.isMember ?? false) && function?.parent != null;

      final keys = parent.functions.entries
              .map((e) => KeyboardKey(Text(e.key), e.key,
                  isMember: true,
                  isFunction: true,
                  parent: showThis ? parent : null))
              .toList() +
          parent.staticVariables.entries
              .map((e) => KeyboardKey(Text(e.key), e.key,
                  isMember: false, isFunction: false, parent: parent))
              .toList() +
          parent.staticFunctions.entries
              .map((e) => KeyboardKey(Text(e.key), e.key,
                  isMember: false, isFunction: true, parent: parent))
              .toList();

      return Stack(
        alignment: Alignment.bottomRight,
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: SizedBox(
                  width: double.infinity,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                            TextButton(
                                onPressed: () => writeToInput(KeyboardKey(
                                    Container(), className, isFunction: true)),
                                child: Text(className,
                                    style: const TextStyle(fontSize: 18))),
                            const Text("(", style: TextStyle(fontSize: 18))
                          ] +
                          separateWidgets(
                              parent.fields
                                  .map((e) => TextButton(
                                      onPressed: () => writeToInput(KeyboardKey(
                                          Container(), e,
                                          isMember: true,
                                          isFunction: false,
                                          parent: showThis ? parent : null)),
                                      child: Text(e,
                                          style:
                                              const TextStyle(fontSize: 18))))
                                  .toList(),
                              const Text(",", style: TextStyle(fontSize: 18))) +
                          [const Text(")", style: TextStyle(fontSize: 18))],
                    ),
                  ),
                ),
              ),
              const HeightlessDivider(),
              Expanded(
                child: KeyboardKeyTable(
                  keys: keys,
                  writeToInput: writeToInput,
                  onLongPress: (key) {
                    String alertTitle = "";
                    String alertContent = "";
                    if (parent.functions.containsKey(key.key)) {
                      final function = parent.functions[key.key]!;
                      alertTitle =
                          "${key.key}(${function.parameters.join(",")})";
                      alertContent = function.function;
                    } else if (parent.staticVariables.containsKey(key.key)) {
                      final variable = parent.staticVariables[key.key]!;
                      alertTitle = key.key;
                      alertContent = "$variable";
                    } else if (parent.staticFunctions.containsKey(key.key)) {
                      final function = parent.staticFunctions[key.key]!;
                      alertTitle =
                          "${key.key}(${function.parameters.join(",")})";
                      alertContent = function.function;
                    }
                    showDialog(
                        context: context,
                        useRootNavigator: false,
                        builder: (context) => AlertDialog(
                              title: Text(alertTitle),
                              content: Text(
                                alertContent,
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey[800]),
                              ),
                            ));
                  },
                ),
              )
            ],
          ),
          if (!readOnly)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: IconButton(
                  onPressed: () => editClass(
                      className, context, cubit, initialView, setView),
                  icon: const Icon(Icons.edit)),
            ),
        ],
      );
    });
  }
}
