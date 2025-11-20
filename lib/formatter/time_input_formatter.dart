import 'package:flutter/services.dart';

class TimeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {

    String text = newValue.text.replaceAll(":", "");

    // Rakam dışında giriş engelle
    if (!RegExp(r'^\d*$').hasMatch(text)) {
      return oldValue;
    }

    // Saat + dakika sınırlandırma
    if (text.length > 4) {
      return oldValue;
    }

    String formatted = "";

    if (text.length >= 1) {
      formatted += text.substring(0, 1);
    }
    if (text.length >= 2) {
      int hour = int.parse(text.substring(0, 2));
      if (hour > 23) {
        hour = 23; // max 23
      }
      formatted = hour.toString().padLeft(2, '0');
    }

    if (text.length >= 3) {
      formatted += ":";
      int minuteFirstDigit = int.parse(text.substring(2, 3));
      formatted += minuteFirstDigit.toString();
    }

    if (text.length == 4) {
      int minute = int.parse(text.substring(2, 4));
      if (minute > 59) {
        minute = 59; // max 59
      }
      formatted = formatted.substring(0, 3) +
          minute.toString().padLeft(2, '0');
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
