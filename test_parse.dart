import 'package:intl/intl.dart';

void main() {
  try {
    final format = DateFormat("hh:mm a");
    print(format.parse("04:14 AM"));
    print(format.parse("12:04 PM"));
    print(format.parse("06:33 PM"));
    print("Success");
  } catch (e) {
    print("Error: $e");
  }
}
