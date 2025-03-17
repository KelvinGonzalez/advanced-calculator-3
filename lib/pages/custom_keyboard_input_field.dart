import 'package:advanced_calculator_3/models/app_state.dart';
import 'package:advanced_calculator_3/pages/custom_keyboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CustomKeyboardInputField extends StatefulWidget {
  final AppCubit cubit;
  final InputDecoration? decoration;
  final void Function(dynamic)? onSubmitted;
  final KeyboardFunctionData? function;
  final String initialView;

  const CustomKeyboardInputField(
      {super.key,
      required this.cubit,
      this.onSubmitted,
      this.decoration,
      this.function,
      required this.initialView});

  @override
  State<CustomKeyboardInputField> createState() =>
      _CustomKeyboardInputFieldState();
}

class _CustomKeyboardInputFieldState extends State<CustomKeyboardInputField> {
  String text = "";

  @override
  Widget build(BuildContext context) {
    return TextField(
      readOnly: true,
      controller: TextEditingController(text: text),
      decoration: widget.decoration,
      onTap: () async {
        final value = await showDialog(
            context: context,
            useRootNavigator: false,
            builder: (context) {
              return CustomKeyboardPopUp(
                cubit: widget.cubit,
                initialValue: text,
                function: widget.function,
                initialView: widget.initialView,
              );
            });
        if (value == null) return;
        setState(() {
          text = value.toString();
          if (widget.onSubmitted != null) widget.onSubmitted!(value);
        });
      },
    );
  }
}

class CustomKeyboardPopUp extends StatelessWidget {
  final AppCubit cubit;
  final String? initialValue;
  final KeyboardFunctionData? function;
  final String initialView;

  const CustomKeyboardPopUp(
      {super.key,
      required this.cubit,
      this.initialValue,
      this.function,
      required this.initialView});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cubit,
      child: FractionallySizedBox(
        heightFactor: 0.8,
        widthFactor: 0.8,
        child: Card(
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(24))),
          child: Column(
            children: [
              CustomKeyboard(
                onSubmit: (_, result) {
                  Navigator.pop(context, result);
                },
                initialValue: initialValue,
                function: function,
                readOnly: true,
                initialView: initialView,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
