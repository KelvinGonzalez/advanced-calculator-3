import 'package:advanced_calculator_3/models/app_state.dart';
import 'package:advanced_calculator_3/pages/custom_keyboard.dart';
import 'package:advanced_calculator_3/pages/widgets_lib.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final keyboardGlobalKey = createGlobalKey();

  void writeBatchStringToInput(String batch,
      [bool encloseInParenthesis = false]) {
    keyboardGlobalKey.currentState
        ?.writeBatchStringToInput(batch, encloseInParenthesis);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(builder: (context, state) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Home"),
          scrolledUnderElevation: 0,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
        ),
        endDrawer: SafeArea(
          child: Drawer(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text("Logs", style: TextStyle(fontSize: 24)),
                  const SizedBox(height: 8),
                  const HeightlessDivider(),
                  if (state.logs.isEmpty) const Text("No logs yet..."),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: separateWidgets(
                              state.logs.reversed
                                  .map((e) => Row(
                                        children: [
                                          Expanded(
                                              child: TextButton(
                                                  onPressed: () =>
                                                      writeBatchStringToInput(
                                                          e.$1, true),
                                                  child: Text(e.$1,
                                                      style: const TextStyle(
                                                          fontSize: 16)))),
                                          const Text("="),
                                          Expanded(
                                              child: TextButton(
                                                  onPressed: () =>
                                                      writeBatchStringToInput(
                                                          e.$2),
                                                  child: Text(e.$2,
                                                      style: const TextStyle(
                                                          fontSize: 16)))),
                                        ],
                                      ))
                                  .toList(),
                              const HeightlessDivider(thickness: 0.35))),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            CustomKeyboard(
                key: keyboardGlobalKey,
                onSubmit: (input, output) {
                  if (output == null) return;
                  final cubit = context.read<AppCubit>();
                  cubit.addLog(input, output.toString());
                }),
          ],
        ),
      );
    });
  }
}
