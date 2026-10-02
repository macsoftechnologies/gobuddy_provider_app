import 'package:flutter/material.dart';

void showCustomDialog({
  required BuildContext context,
  required String message,
  String imagePath = 'assets/images/greentick.png',
}) {
  showDialog(
    context: context,
    barrierDismissible: false, // Prevent dismissing manually
    builder: (BuildContext context) {
      // Auto-close after 2 seconds


      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        insetPadding: EdgeInsets.symmetric(horizontal: 40),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                imagePath,
                height: 100,
                width: 100,
              ),
              SizedBox(height: 20),
              Text(
                message,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Urbanist',
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    },
  );
}
