import 'dart:async';
import 'dart:convert';

import 'package:advanced_calculator_3/models/app_state.dart';
import 'package:advanced_calculator_3/models/custom_class.dart';
import 'package:advanced_calculator_3/models/custom_function.dart';
import 'package:advanced_calculator_3/pages/custom_keyboard.dart';
import 'package:advanced_calculator_3/pages/custom_keyboard_input_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as services;
import 'package:flutter_bloc/flutter_bloc.dart';

class HeightlessDivider extends StatelessWidget {
  final double? thickness;

  const HeightlessDivider({super.key, this.thickness});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 0,
      thickness: thickness,
    );
  }
}

class WidthlessVerticalDivider extends StatelessWidget {
  const WidthlessVerticalDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const VerticalDivider(
      width: 0,
    );
  }
}

class CategoryButton extends StatelessWidget {
  final void Function() onPressed;
  final String text;
  final bool center;

  const CategoryButton(
      {super.key,
      required this.onPressed,
      required this.text,
      this.center = false});

  @override
  Widget build(BuildContext context) {
    return TextButton(
        onPressed: onPressed,
        child: SizedBox(
          width: double.infinity,
          child: Text(
            text,
            textAlign: center ? TextAlign.center : TextAlign.left,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 18),
          ),
        ));
  }
}

class NumpadText extends StatelessWidget {
  final String text;

  const NumpadText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 20),
      maxLines: 1,
    );
  }
}

class OutputText extends StatelessWidget {
  final String text;
  final int cursorPosition;
  final void Function(int) onTap;

  const OutputText(this.text,
      {super.key, required this.cursorPosition, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(cursorPosition),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 20,
          fontStyle: FontStyle.italic,
          color: Colors.grey[800],
        ),
      ),
    );
  }
}

class NumpadKey extends StatefulWidget {
  final KeyboardKey keyboardKey;
  final void Function(KeyboardKey) writeToInput;
  final Duration interval;

  const NumpadKey(this.keyboardKey, this.writeToInput,
      {super.key, this.interval = const Duration(milliseconds: 100)});

  @override
  State<NumpadKey> createState() => _NumpadKeyState();
}

class _NumpadKeyState extends State<NumpadKey> {
  Timer? _timer;
  bool _isHolding = false;

  void _onPressed() => widget.writeToInput(widget.keyboardKey);

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _onStart() {
    _isHolding = true;
    _onPressed();
    _timer = Timer.periodic(
        widget.interval, (_) => _isHolding ? _onPressed() : _stopTimer());
  }

  void _onStop() {
    _isHolding = false;
    _stopTimer();
  }

  @override
  void dispose() {
    super.dispose();
    _stopTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(3.0),
        child: GestureDetector(
          onLongPress: () => _onStart(),
          onLongPressEnd: (_) => _onStop(),
          onLongPressCancel: () => _onStop(),
          child: ElevatedButton(
            onPressed: () => _onPressed(),
            child: widget.keyboardKey.label,
          ),
        ),
      ),
    );
  }
}

class TwoSidedText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final void Function() onLeft;
  final void Function() onRight;

  const TwoSidedText(this.text,
      {super.key, this.style, required this.onLeft, required this.onRight});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return GestureDetector(
          onTapDown: (event) {
            event.localPosition.dx < constraints.maxHeight / 2
                ? onLeft()
                : onRight();
          },
          child: Text(
            text,
            style: style,
          ));
    });
  }
}

class CustomTabBarViewScrollPhysics extends ScrollPhysics {
  const CustomTabBarViewScrollPhysics({super.parent});

  @override
  CustomTabBarViewScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return CustomTabBarViewScrollPhysics(parent: buildParent(ancestor)!);
  }

  @override
  SpringDescription get spring => const SpringDescription(
        mass: 50,
        stiffness: 100,
        damping: 10,
      );
}

class IconButtonWithLongPress extends StatelessWidget {
  final void Function()? onLongPress;
  final void Function()? onPressed;
  final Icon icon;

  const IconButtonWithLongPress(
      {super.key,
      required this.onLongPress,
      required this.onPressed,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: IconButton(onPressed: onPressed, icon: icon),
    );
  }
}

class ConfirmationDialog extends StatelessWidget {
  final String question;
  final String? content;

  const ConfirmationDialog({super.key, required this.question, this.content});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(question),
      content: content != null
          ? Text(
              content!,
              style: TextStyle(fontSize: 16, color: Colors.grey[800]),
            )
          : null,
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("No")),
        TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Yes")),
      ],
    );
  }
}

Future<bool> getConfirmation(String question, BuildContext context,
    {String? content}) async {
  final answer = await showDialog(
      context: context,
      useRootNavigator: false,
      builder: (context) =>
          ConfirmationDialog(question: question, content: content));
  return answer ?? false;
}

Future<(String, dynamic)?> createVariable(
    BuildContext context, AppCubit cubit, String initialView) async {
  final nameController = TextEditingController();
  dynamic value;

  return await showDialog(
      context: context,
      useRootNavigator: false,
      builder: (context) => AlertDialog(
            title: const Text("Create Variable"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: "Name"),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: CustomKeyboardInputField(
                    cubit: cubit,
                    onSubmitted: (v) => value = v,
                    decoration: const InputDecoration(labelText: "Value"),
                    initialView: initialView,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                  onPressed: () {
                    final variable = cubit.getValidVariable(
                        nameController.text.trim(), value);
                    if (variable == null) return;
                    Navigator.pop(context, variable);
                  },
                  icon: const Icon(Icons.send))
            ],
          ));
}

Future<(String, CustomFunction)?> createFunction(
    BuildContext context, AppCubit cubit, String initialView,
    {bool isMember = false, CustomClass? parent}) async {
  final nameController = TextEditingController();
  String functionValue = "";
  final parameterControllers = <TextEditingController>[];

  return await showDialog(
      context: context,
      useRootNavigator: false,
      builder: (context) => StatefulBuilder(builder: (context, stfSetState) {
            return AlertDialog(
              title: const Text("Create Function"),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: "Name"),
                    ),
                    const Divider(),
                    Row(
                      children: [
                        const Expanded(
                            child: Text(
                          "Parameters",
                          style: TextStyle(fontSize: 16),
                        )),
                        IconButton(
                            onPressed: () {
                              stfSetState(() {
                                parameterControllers
                                    .add(TextEditingController());
                              });
                            },
                            icon: const Icon(Icons.add)),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        children: parameterControllers.indexed
                            .map((e) => Row(
                                  children: [
                                    Expanded(
                                        child: TextField(
                                      controller: e.$2,
                                      onChanged: (_) => stfSetState(() {}),
                                    )),
                                    IconButton(
                                        onPressed: () {
                                          stfSetState(() {
                                            parameterControllers.removeAt(e.$1);
                                          });
                                        },
                                        icon: const Icon(
                                          Icons.close,
                                          size: 16,
                                        ))
                                  ],
                                ))
                            .toList(),
                      ),
                    ),
                    const Divider(),
                    CustomKeyboardInputField(
                      cubit: cubit,
                      decoration:
                          const InputDecoration(labelText: "Definition"),
                      onSubmitted: (value) {
                        stfSetState(() {
                          functionValue = value.toString();
                        });
                      },
                      function: KeyboardFunctionData(
                        CustomFunction(
                            "",
                            parameterControllers
                                .map((e) => e.text.trim())
                                .toList()),
                        isMember: isMember,
                        parent: parent,
                      ),
                      initialView: initialView,
                    ),
                  ],
                ),
              ),
              actions: [
                IconButton(
                    onPressed: () {
                      final validFunction = cubit.getValidFunction(
                          nameController.text.trim(),
                          functionValue,
                          parameterControllers
                              .map((e) => e.text.trim())
                              .toList());
                      if (validFunction == null) return;
                      Navigator.pop(context, validFunction);
                    },
                    icon: const Icon(Icons.send))
              ],
            );
          }));
}

Future<void> createClass(BuildContext context, AppCubit cubit) async {
  final nameController = TextEditingController();
  final fieldControllers = <TextEditingController>[];

  return await showDialog(
      context: context,
      useRootNavigator: false,
      builder: (context) => StatefulBuilder(builder: (context, stfSetState) {
            return AlertDialog(
              title: Row(
                children: [
                  const Expanded(child: Text("Create Class")),
                  IconButton(
                      onPressed: () async {
                        final clipboardData =
                            await services.Clipboard.getData('text/plain');
                        if (!context.mounted) return;
                        final controller =
                            TextEditingController(text: clipboardData?.text);
                        showDialog(
                            context: context,
                            useRootNavigator: false,
                            builder: (context) => AlertDialog(
                                  title: const Text("Import Class"),
                                  content: TextField(
                                    controller: controller,
                                    decoration: const InputDecoration(
                                        labelText: "Encoded Class"),
                                  ),
                                  actions: [
                                    IconButton(
                                        onPressed: () {
                                          try {
                                            final importedClass =
                                                CustomClass.fromJson(jsonDecode(
                                                    controller.text.trim()));
                                            final result = cubit.addClass(
                                                importedClass.name,
                                                importedClass.fields,
                                                importedClass.functions,
                                                importedClass.staticVariables,
                                                importedClass.staticFunctions);
                                            if (!result) return;
                                            Navigator.of(context)
                                              ..pop()
                                              ..pop();
                                          } catch (_) {}
                                        },
                                        icon: const Icon(Icons.download)),
                                  ],
                                ));
                      },
                      icon: const Icon(Icons.download))
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: "Name"),
                    ),
                    const Divider(),
                    Row(
                      children: [
                        const Expanded(
                            child: Text(
                          "Fields",
                          style: TextStyle(fontSize: 16),
                        )),
                        IconButton(
                            onPressed: () {
                              stfSetState(() {
                                fieldControllers.add(TextEditingController());
                              });
                            },
                            icon: const Icon(Icons.add)),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        children: fieldControllers.indexed
                            .map((e) => Row(
                                  children: [
                                    Expanded(
                                        child: TextField(
                                      controller: e.$2,
                                      onChanged: (_) => stfSetState(() {}),
                                    )),
                                    IconButton(
                                        onPressed: () {
                                          stfSetState(() {
                                            fieldControllers.removeAt(e.$1);
                                          });
                                        },
                                        icon: const Icon(
                                          Icons.close,
                                          size: 16,
                                        ))
                                  ],
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                IconButton(
                    onPressed: () {
                      final result = cubit.addClass(
                          nameController.text.trim(),
                          fieldControllers.map((e) => e.text.trim()).toList(),
                          {},
                          {},
                          {});
                      if (!result) return;
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.send))
              ],
            );
          }));
}

Future<void> editClass(String name, BuildContext context, AppCubit cubit,
    String initialView, void Function(String) setView) async {
  return await showDialog(
      context: context,
      useRootNavigator: false,
      builder: (context) => BlocProvider.value(
            value: cubit,
            child: BlocBuilder<AppCubit, AppState>(builder: (context, state) {
              final original = state.myClasses[name];
              if (original == null) {
                return Center(child: Text("$name does not exist"));
              }
              final fields = original.fields;
              final functions = original.functions;
              final staticVariables = original.staticVariables;
              final staticFunctions = original.staticFunctions;

              return AlertDialog(
                title: Text("Edit ${original.name}"),
                content: SingleChildScrollView(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Text(
                            "Fields",
                            style: TextStyle(fontSize: 16),
                          ),
                          IconButton(
                              onPressed: () async {
                                final fieldControllers = original.fields
                                    .map((e) => TextEditingController(text: e))
                                    .toList();
                                showDialog(
                                    context: context,
                                    useRootNavigator: false,
                                    builder: (context) => StatefulBuilder(
                                            builder: (context, stfSetState) {
                                          return AlertDialog(
                                            title: Row(
                                              children: [
                                                const Expanded(
                                                    child: Text("Fields")),
                                                IconButton(
                                                    onPressed: () {
                                                      stfSetState(() {
                                                        fieldControllers.add(
                                                            TextEditingController());
                                                      });
                                                    },
                                                    icon:
                                                        const Icon(Icons.add)),
                                              ],
                                            ),
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: fieldControllers.indexed
                                                  .map((e) => Row(
                                                        children: [
                                                          Expanded(
                                                              child: TextField(
                                                            controller: e.$2,
                                                            onChanged: (_) =>
                                                                stfSetState(
                                                                    () {}),
                                                          )),
                                                          IconButton(
                                                              onPressed: () {
                                                                stfSetState(() {
                                                                  fieldControllers
                                                                      .removeAt(
                                                                          e.$1);
                                                                });
                                                              },
                                                              icon: const Icon(
                                                                Icons.close,
                                                                size: 16,
                                                              ))
                                                        ],
                                                      ))
                                                  .toList(),
                                            ),
                                            actions: [
                                              IconButton(
                                                  onPressed: () {
                                                    final fields =
                                                        fieldControllers
                                                            .map((e) =>
                                                                e.text.trim())
                                                            .toList();
                                                    final result =
                                                        cubit.addClass(
                                                            name,
                                                            fields,
                                                            functions,
                                                            staticVariables,
                                                            staticFunctions);
                                                    if (!result) return;
                                                    Navigator.pop(context);
                                                  },
                                                  icon: const Icon(Icons.send))
                                            ],
                                          );
                                        }));
                              },
                              icon: const Icon(Icons.edit, size: 16)),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(
                          children: [
                            Text(fields.join(", ")),
                          ],
                        ),
                      ),
                      const Divider(),
                      Row(
                        children: [
                          const Expanded(
                              child: Text(
                            "Functions",
                            style: TextStyle(fontSize: 16),
                          )),
                          IconButton(
                              onPressed: () async {
                                final function = await createFunction(
                                    context, cubit, initialView,
                                    isMember: true, parent: original);
                                if (function == null) return;
                                cubit.addClass(
                                    name,
                                    fields,
                                    functions
                                      ..addAll({function.$1: function.$2}),
                                    staticVariables,
                                    staticFunctions);
                              },
                              icon: const Icon(Icons.add)),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Column(
                          children: functions.entries
                              .map((e) => Row(
                                    children: [
                                      Expanded(
                                          child: Text(
                                              "${e.key}(${e.value.parameters.join(",")}) = ${e.value.function}")),
                                      IconButton(
                                          onPressed: () {
                                            cubit.addClass(
                                                name,
                                                fields,
                                                functions..remove(e.key),
                                                staticVariables,
                                                staticFunctions);
                                          },
                                          icon: const Icon(
                                            Icons.close,
                                            size: 16,
                                          ))
                                    ],
                                  ))
                              .toList(),
                        ),
                      ),
                      const Divider(),
                      Row(
                        children: [
                          const Expanded(
                              child: Text(
                            "Static Variables",
                            style: TextStyle(fontSize: 16),
                          )),
                          IconButton(
                              onPressed: () async {
                                final variable = await createVariable(
                                    context, cubit, initialView);
                                if (variable == null) return;
                                cubit.addClass(
                                    name,
                                    fields,
                                    functions,
                                    staticVariables
                                      ..addAll({variable.$1: variable.$2}),
                                    staticFunctions);
                              },
                              icon: const Icon(Icons.add)),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Column(
                          children: staticVariables.entries
                              .map((e) => Row(
                                    children: [
                                      Expanded(
                                          child: Text("${e.key} = ${e.value}")),
                                      IconButton(
                                          onPressed: () {
                                            cubit.addClass(
                                                name,
                                                fields,
                                                functions,
                                                staticVariables..remove(e.key),
                                                staticFunctions);
                                          },
                                          icon: const Icon(
                                            Icons.close,
                                            size: 16,
                                          ))
                                    ],
                                  ))
                              .toList(),
                        ),
                      ),
                      const Divider(),
                      Row(
                        children: [
                          const Expanded(
                              child: Text(
                            "Static Functions",
                            style: TextStyle(fontSize: 16),
                          )),
                          IconButton(
                              onPressed: () async {
                                final function = await createFunction(
                                    context, cubit, initialView,
                                    parent: original);
                                if (function == null) return;
                                cubit.addClass(
                                    name,
                                    fields,
                                    functions,
                                    staticVariables,
                                    staticFunctions
                                      ..addAll({function.$1: function.$2}));
                              },
                              icon: const Icon(Icons.add)),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Column(
                          children: staticFunctions.entries
                              .map((e) => Row(
                                    children: [
                                      Expanded(
                                          child: Text(
                                              "${e.key}(${e.value.parameters.join(",")}) = ${e.value.function}")),
                                      IconButton(
                                          onPressed: () {
                                            cubit.addClass(
                                                name,
                                                fields,
                                                functions,
                                                staticVariables,
                                                staticFunctions..remove(e.key));
                                          },
                                          icon: const Icon(
                                            Icons.close,
                                            size: 16,
                                          ))
                                    ],
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  IconButton(
                      onPressed: () {
                        final jsonString = jsonEncode(original.toJson());
                        services.Clipboard.setData(
                                services.ClipboardData(text: jsonString))
                            .then((_) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(SnackBar(
                                content: Text(
                                    "Copied serialized ${original.name}")));
                          Navigator.pop(context);
                        });
                      },
                      icon: const Icon(Icons.upload)),
                  IconButton(
                      onPressed: () async {
                        final answer =
                            await getConfirmation("Delete $name?", context);
                        if (!answer) return;
                        cubit.remove(name);
                        setView("default");
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                      icon: const Icon(Icons.delete))
                ],
              );
            }),
          ));
}

List<Widget> separateWidgets(List<Widget> widgets, Widget separator) {
  return widgets.expand((w) => [w, if (w != widgets.last) separator]).toList();
}

List<Widget> padWidgets(List<Widget> widgets, EdgeInsets padding) {
  return widgets.map((w) => Padding(padding: padding, child: w)).toList();
}

List<Widget> expandWidgets(List<Widget> widgets) {
  return widgets.map((w) => Expanded(child: w)).toList();
}
