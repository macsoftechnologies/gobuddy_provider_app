import 'package:flutter/material.dart';

import 'package:gobuddy/utils/config.dart';


// import '../dashboardpage.dart';

class SubscriptionSuccessPage extends StatelessWidget {
  const SubscriptionSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pushNamedAndRemoveUntil(
          Config.dashboardcRouteName,
          (route) => false,
        );
      },
      child: Scaffold(
        backgroundColor: Color(0xFFEBF3FA),
        body: SafeArea(
          child: Column(
            children: [
            // Top Illustration Section
            Container(
              width: double.infinity,
              height: screenHeight * 0.35,
              color: const Color(0xFFEBF3FA),
              child: Center(
                child: Image.asset(
                  'assets/images/congrulations.png', // replace with your illustration
                  height: screenHeight * 0.22,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // White Card Section
            Expanded(
              child: Container(
                width: double.infinity,
                margin: EdgeInsets.only(top: screenHeight * 0.02),
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.06,
                  vertical: screenHeight * 0.03,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      spreadRadius: 2,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      "Congratulations!",
                      style: TextStyle(
                        fontSize: screenWidth * 0.06,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                        color: Colors.green,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.008),
                    Text(
                      "We will get back to you",
                      style: TextStyle(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.025),
                    Text(
                      "Thank you for subscription. We will contact you as early as possible after validation of your information. Meanwhile, if any questions please contact us at 9177746889.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.025),
                    Text(
                      "చందా చేసినందుకు ధన్యవాదాలు! మీ సమాచారం ధృవీకరించిన తరువాత మేము వీలైనంత త్వరగా మిమ్మల్ని సంప్రదిస్తాము. అంతలో, ఏవైనా సందేహాలు ఉంటే దయచేసి 9177746889 కి ఫోన్ చేసి సంప్రదించండి.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                    const Spacer(),
                    // Ok Button
                    SizedBox(
                      width: double.infinity,
                      height: screenHeight * 0.06,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            Config.dashboardcRouteName,
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFd4c900), Color(0xFF00ad20)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            child: Text(
                              "Ok",
                              style: TextStyle(
                                fontSize: screenWidth * 0.045,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
