import 'package:flutter/material.dart';

import '../../../../components/button.dart';

class TermsAndConditionsScreen extends StatefulWidget {
  const TermsAndConditionsScreen({Key? key}) : super(key: key);

  @override
  State<TermsAndConditionsScreen> createState() =>
      _TermsAndConditionsScreenState();
}

class _TermsAndConditionsScreenState extends State<TermsAndConditionsScreen> {
  @override
  Widget build(BuildContext context) {
    // Device dimensions
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Terms & Conditions"),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFC8BB47), // Golden Yellow
                Color(0xFF25AC2C),], // 👈 Gradient colors
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: width * 0.05,
            vertical: height * 0.02,
          ),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    '''
GoBuddy Provider App – Terms & Conditions

1. Acceptance of Terms
By using the GoBuddy Provider App, you agree to abide by these Terms & Conditions. If you do not agree, you may not use our services.

2. Eligibility
Service Providers must be at least 18 years old and legally able to enter contracts in their jurisdiction.

3. Subscription Plans
Providers are required to purchase subscription plans to receive customer orders. Subscription fees are non-refundable.

4. Service Standards
Providers must maintain high service quality and comply with all applicable laws and regulations.

5. Payments
Payments will be processed as per the agreed terms. Any disputes should be raised within 7 working days.

6. Account Termination
We reserve the right to suspend or terminate accounts found violating policies.

7. Liability
GoBuddy is a platform that connects customers and service providers. We are not responsible for any damages or disputes arising between parties.

8. Updates to Terms
GoBuddy reserves the right to update these Terms & Conditions. Continued usage means acceptance of the new terms.

For further details, contact us at: support@gobuddy.com
                    ''',
                    style: TextStyle(
                      fontSize: width * 0.04,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              SizedBox(height: height * 0.02),
              GradientButton(
                onPressed: () {
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(builder: (_) => InstructionsTwo()),
                  // );
                },
                child: Text(
                  'Accept & Continue',
                  style: TextStyle(
                    fontFamily: 'Urbanist',
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: width * 0.04,
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
