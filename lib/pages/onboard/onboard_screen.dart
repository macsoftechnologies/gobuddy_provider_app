import 'package:flutter/material.dart';
import 'package:gobuddy/pages/authentication/login/login_screen.dart';


import '../../components/gradient_button.dart';
import '../../utils/config.dart';

// import 'package:providerapp_gobuddy/utilites/button.dart';
//
// import 'loginscreen.dart';

class OnBoardScreenOne extends StatelessWidget {
  const OnBoardScreenOne({super.key});

  @override
  Widget build(BuildContext context) {
    final double deviceHeight = MediaQuery.of(context).size.height;
    final double deviceWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: deviceWidth * 0.05,
          vertical: deviceHeight * 0.045,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: deviceHeight * 0.025),

            // Top illustration image
            Center(
              child: Image.asset(
                'assets/images/instruction.png',
                height: deviceHeight * 0.25,
              ),
            ),
            SizedBox(height: deviceHeight * 0.025),

            // Title
            Center(
              child: Text(
                'Steps to Onboard and Receive Jobs',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: deviceWidth * 0.045,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: deviceHeight * 0.005),
            Center(
              child: Text(
                'ఆన్‌బోర్డ్ కావడానికి మరియు జాబ్స్ పొందడానికి స్టెప్స్',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: deviceWidth * 0.038),
              ),
            ),
            SizedBox(height: deviceHeight * 0.03),

            // Steps
            StepItem(
              image: 'assets/images/checkbox.png',
              title: '1. Register by entering your name and number',
              subtitle: 'మీ పేరు మరియు నంబర్ నమోదు చేయండి',
              deviceHeight: deviceHeight,
              deviceWidth: deviceWidth,
            ),
            StepItem(
              image: 'assets/images/checkbox.png',
              title: '2. Provide details for eKYC',
              subtitle: 'e-KYC వివరాలను నమోదు చేయండి',
              deviceHeight: deviceHeight,
              deviceWidth: deviceWidth,
            ),
            StepItem(
              image: 'assets/images/payment.png',
              title: '3. Pay one-time registration fee of ₹300/-',
              subtitle: 'రూ. 300/- రిజిస్ట్రేషన్ చార్జ్ చెల్లించండి',
              deviceHeight: deviceHeight,
              deviceWidth: deviceWidth,
            ),

            Spacer(),

            // Bottom Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  child: Text(
                    'Skip',
                    style: TextStyle(fontSize: deviceWidth * 0.035, color: Colors.black),
                  ),
                ),
                GradientButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => OnBoardScreenTwo()),
                    );
                  },
                  child: Text(
                    'Next',
                    style: TextStyle(
                      fontFamily: 'Urbanist',
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: deviceWidth * 0.04,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class StepItem extends StatelessWidget {
  final String image;
  final String title;
  final String subtitle;
  final double deviceHeight;
  final double deviceWidth;

  const StepItem({super.key, 
    required this.image,
    required this.title,
    required this.subtitle,
    required this.deviceHeight,
    required this.deviceWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: deviceHeight * 0.03),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            image,
            height: deviceHeight * 0.06,
            width: deviceHeight * 0.06,
          ),
          SizedBox(width: deviceWidth * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: deviceWidth * 0.04,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: deviceHeight * 0.007),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: deviceWidth * 0.038),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// OnBoard Screen Two
class OnBoardScreenTwo extends StatelessWidget {
  const OnBoardScreenTwo({super.key});

  @override
  Widget build(BuildContext context) {
    final double deviceHeight = MediaQuery.of(context).size.height;
    final double deviceWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: deviceWidth * 0.05,
          vertical: deviceHeight * 0.045,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: deviceHeight * 0.025),

            Center(
              child: Image.asset(
                'assets/images/InstructionTwo.png',
                height: deviceHeight * 0.25,
              ),
            ),
            SizedBox(height: deviceHeight * 0.025),

            Center(
              child: Text(
                'Steps to Onboard and Receive Jobs',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: deviceWidth * 0.045,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: deviceHeight * 0.007),
            Center(
              child: Text(
                'ఆన్‌బోర్డ్ కావడానికి మరియు జాబ్స్ పొందడానికి స్టెప్స్',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: deviceWidth * 0.035),
              ),
            ),
            SizedBox(height: deviceHeight * 0.02),

            StepItem(
              image: 'assets/images/check.png',
              title: '4. Complete background check to purchase subscription',
              subtitle: 'మీ పేరు మరియు నంబర్ నమోదు చేయండి',
              deviceHeight: deviceHeight,
              deviceWidth: deviceWidth,
            ),
            StepItem(
              image: 'assets/images/subscribe.png',
              title: '5. Purchase Subscription',
              subtitle: 'e-KYC వివరాలను నమోదు చేయండి',
              deviceHeight: deviceHeight,
              deviceWidth: deviceWidth,
            ),
            StepItem(
              image: 'assets/images/financial-statement.png',
              title: '6. Start receiving your jobs and increase your earnings',
              subtitle: 'రూ. 300/- రిజిస్ట్రేషన్ చార్జ్ చెల్లించండి',
              deviceHeight: deviceHeight,
              deviceWidth: deviceWidth,
            ),

            Spacer(),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                     Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  child: Text(
                    'Skip',
                    style: TextStyle(fontSize: deviceWidth * 0.035, color: Colors.black),
                  ),
                ),
                GradientButton(
                  onPressed: () {
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(builder: (_) => LoginScreen()),
                    // );
                    Navigator.of(context).pushReplacementNamed(
                      Config.loginRouteName,
                    );


                  },
                  child: Text(
                    'Get Started',
                    style: TextStyle(
                      fontFamily: 'Urbanist',
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: deviceWidth * 0.04,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}