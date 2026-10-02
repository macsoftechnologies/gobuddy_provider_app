import 'package:flutter/material.dart';

// import '../../utilites/custombackbutton.dart';
import '../../../../components/custom_back_button.dart';
import 'create_package_screen.dart';

class CreateSubscriptionScreen extends StatefulWidget {
  const CreateSubscriptionScreen({super.key});

  @override
  State<CreateSubscriptionScreen> createState() =>
      _CreateSubscriptionScreenState();
}

class _CreateSubscriptionScreenState extends State<CreateSubscriptionScreen> {
  @override
  Widget build(BuildContext context) {
    final deviceHeight = MediaQuery.of(context).size.height;
    final deviceWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SizedBox(
          height: deviceHeight,
          width: deviceWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              /// Top Bar
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: deviceWidth * 0.04,
                  vertical: deviceHeight * 0.015,
                ),
                child: Row(
                  children: [
                    CustomBackButton(),
                    SizedBox(width: deviceWidth * 0.02),
                    const Text(
                      "Create My Subscription",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: deviceHeight * 0.05),

              /// Illustration
              SizedBox(
                height: deviceHeight * 0.25,
                child: Image.asset(
                  "assets/images/subscription.png", 
                  fit: BoxFit.contain,
                ),
              ),

              SizedBox(height: deviceHeight * 0.05),

              /// English Text
              Padding(
                padding: EdgeInsets.symmetric(horizontal: deviceWidth * 0.08),
                child: _buildText(
                  "Select your Service Category/Type and add prices to the services you want to provide to create the package.",
                ),
              ),

              SizedBox(height: deviceHeight * 0.015),

              /// Telugu Text
              Padding(
                padding: EdgeInsets.symmetric(horizontal: deviceWidth * 0.08),
                child: _buildText(
                  "మీ చెక్కౌట్ క్యాటగిరీ/రకాన్ని ఎంచుకుని, మీరు అందించాలనుకుంటున్న సర్వీస్ ఆర్డర్లకు ధరలను ఇన్పుట్ చేసిన ప్యాకేజీని సృష్టించండి.",
                ),
              ),

              SizedBox(height: deviceHeight * 0.04),

              /// Footer text
              Padding(
                padding: EdgeInsets.symmetric(horizontal: deviceWidth * 0.08),
                child: _buildText(
                  'Watch "How to Create Subscription Package" video in tutorials for detailed assistance.',
                ),
              ),

              const Spacer(),

              /// Button
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: deviceWidth * 0.08,
                  vertical: deviceHeight * 0.03,
                ),
                child: _buildYellowButton(
                  title: "Get Started",
                  onPressed: () {
                    // Navigation or action
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                          //OTPScreen(phone: _phoneController.text),
                          CreatePackageScreen()
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Reusable Back Button
  Widget _buildBackButton() {
    return Container(
      height: 40,
      width: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF7ED957), // green gradient placeholder
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.arrow_back_ios_new,
        color: Colors.white,
        size: 18,
      ),
    );
  }

  /// Reusable Text
  Widget _buildText(String text) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 14,
        color: Colors.black87,
        height: 1.4,
      ),
    );
  }

  /// Reusable Button
  Widget _buildYellowButton({required String title, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFD731), // Yellow
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}
