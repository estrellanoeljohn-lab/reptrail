/// Formats a number with an explicit sign, using a real minus sign.
String signed(double value, [int digits = 1]) {
  final text = value.abs().toStringAsFixed(digits);
  if (double.parse(text) == 0) return text;
  return value < 0 ? '−$text' : '+$text';
}