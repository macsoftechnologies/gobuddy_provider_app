import 'package:flutter/material.dart';
import 'package:gobuddy/utils/config.dart';

class CustomBackButton extends StatelessWidget {
  final VoidCallback? onBack;
  final String? fallbackRoute;

  const CustomBackButton({super.key, this.onBack, this.fallbackRoute});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 45, // ✅ increased size
      height: 45,
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.orange, Colors.green],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(5), // Square with slight rounding
      ),
      child: Center(
        child: IconButton(
          onPressed: () {
            if (onBack != null) {
              onBack!();
              return;
            }
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else if (fallbackRoute != null) {
              Navigator.of(context).pushReplacementNamed(fallbackRoute!);
            } else {
              Navigator.of(context).pushReplacementNamed(Config.dashboardcRouteName);
            }
          },
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          padding: const EdgeInsets.only(left: 5.0),
        ),
      ),
    );
  }
}


//
// Container(
// width: 40, // ✅ increased size
// height: 40,
// margin: EdgeInsets.all(10),
// decoration: BoxDecoration(
// gradient: LinearGradient(
// colors: [Colors.orange, Colors.green],
// begin: Alignment.topLeft,
// end: Alignment.bottomRight,
// ),
// borderRadius: BorderRadius.circular(5), // Square with slight rounding
// ),
// child: Center(
// child: IconButton(
// onPressed: () => Navigator.of(context).pop(),
// icon: Icon(Icons.arrow_back_ios, color: Colors.white,size: 20,),
// padding: EdgeInsets.zero,
// //constraints: BoxConstraints.tight(Size(20, 20)), // Fix size
// //iconSize: 20,
// )
// ),
// );