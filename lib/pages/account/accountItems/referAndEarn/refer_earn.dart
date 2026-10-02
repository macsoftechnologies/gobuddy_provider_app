import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../components/button.dart';
import 'package:share_plus/share_plus.dart';

class ReferAndEarnPage extends StatefulWidget {
  const ReferAndEarnPage({super.key});

  @override
  _ReferAndEarnPageState createState() => _ReferAndEarnPageState();
}

class _ReferAndEarnPageState extends State<ReferAndEarnPage> {
  String? referralCode;

  void _shareReferral() {
    String message = (referralCode != null && referralCode!.isNotEmpty)
        ? "Join GoBuddy Provider app with my referral code: $referralCode to receive exclusive jobs and earn more! Download now."
        : "Join GoBuddy Provider app to receive exclusive jobs and earn more! Download now.";
    Share.share(message);
  }



@override
void didChangeDependencies() {
  super.didChangeDependencies();

  final args =
      ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

  if (args != null && args.containsKey('referral_code')) {
    referralCode = args['referral_code'];
    print("Your Referal code is $referralCode");
  }
}


  @override
  Widget build(BuildContext context) {
    final double deviceHeight = MediaQuery.of(context).size.height;
    final double deviceWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Refer & Earn"),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Image.asset("assets/images/referAndEarn.png", height: 200),
            SizedBox(height: 30),
            Row(
              children: [
                Icon(Icons.looks_one),
                SizedBox(width: 10),
                Expanded(child: Text("Refer a friend or family member")),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.looks_two),
                SizedBox(width: 10),
                Expanded(
                    child: Text(
                        "When they register or order:\nA. You receive 5 GB coins\nB. They get ₹100 off")),
              ],
            ),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(referralCode ?? "", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {
                      if (referralCode != null && referralCode!.isNotEmpty) {
                        Clipboard.setData(ClipboardData(text: referralCode!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Referral code copied to clipboard!"),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    child: const Text("Copy"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            GradientButton(
              onPressed: () {
                _shareReferral();
              },
              child: Text(
                'Refer Now',
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
      ),
    );
  }
}
