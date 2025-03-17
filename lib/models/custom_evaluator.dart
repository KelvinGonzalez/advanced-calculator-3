import 'package:advanced_calculator_3/models/custom_class.dart';
import 'package:advanced_calculator_3/models/custom_function.dart';
import 'package:advanced_calculator_3/models/custom_instance.dart';
import 'package:expressions/expressions.dart';

class CustomEvaluator extends ExpressionEvaluator {
  const CustomEvaluator();

  static dynamic evaluate(String expression, Map<String, dynamic> context) {
    try {
      return const CustomEvaluator()
          .eval(Expression.parse(expression), context);
    } catch (_) {
      return null;
    }
  }

  @override
  dynamic evalMemberExpression(
      MemberExpression expression, Map<String, dynamic> context) {
    final obj = eval(expression.object, context);
    final propertyName = expression.property.name;
    if (obj is CustomInstance) {
      return obj.get(propertyName, context[obj.className]);
    }
    if (obj is CustomClass) {
      return obj.get(propertyName);
    }
    return getMember(obj, propertyName);
  }

  @override
  evalUnaryExpression(
      UnaryExpression expression, Map<String, dynamic> context) {
    var argument = eval(expression.argument, context);
    if (argument is CustomInstance) {
      final result = argument.operatorCall(
          expression.operator, context[argument.className],
          context: context);
      if (result != null) return result;
    }
    return super.evalUnaryExpression(expression, context);
  }

  @override
  evalBinaryExpression(
      BinaryExpression expression, Map<String, dynamic> context) {
    var left = eval(expression.left, context);
    right() => eval(expression.right, context);
    if (left is CustomInstance) {
      final result = left.operatorCall(
          expression.operator, context[left.className],
          other: right(), context: context);
      if (result != null) return result;
    }
    return super.evalBinaryExpression(expression, context);
  }

  @override
  evalCallExpression(CallExpression expression, Map<String, dynamic> context) {
    var callee = eval(expression.callee, context);
    var arguments = expression.arguments.map((e) => eval(e, context)).toList();
    if (callee is CustomFunction) {
      return callee.call(arguments, context);
    }
    if (callee is InstanceFunctionPair) {
      return callee.call(
          arguments, context[callee.instance.className], context);
    }
    if (callee is CustomClass) {
      return callee.create(arguments);
    }
    return Function.apply(callee, arguments);
  }
}
