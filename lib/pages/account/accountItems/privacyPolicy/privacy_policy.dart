import 'package:flutter/material.dart';

class PrivacyAndPolicyScreen extends StatefulWidget {
  const PrivacyAndPolicyScreen({Key? key}) : super(key: key);

  @override
  State<PrivacyAndPolicyScreen> createState() => _PrivacyAndPolicyScreenState();
}

class _PrivacyAndPolicyScreenState extends State<PrivacyAndPolicyScreen> {
  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;//"Privacy Policy",

    return Scaffold(
      appBar: AppBar(
        title: const Text("Privacy Policy"),
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
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.05,
            vertical: screenHeight * 0.02,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Text(
              //   "Improve Your Living",
              //   style: TextStyle(
              //     fontSize: screenWidth * 0.06,
              //     fontWeight: FontWeight.bold,
              //   ),
              // ),
              // SizedBox(height: screenHeight * 0.02),
              // Text(
              //   "Privacy Policy\n[GOBUDDY Mobile App & www.gobuddyindia.com]\nLast updated [July 20th, 2019]",
              //   style: TextStyle(
              //     fontSize: screenWidth * 0.04,
              //     fontWeight: FontWeight.w500,
              //   ),
              // ),
              //SizedBox(height: screenHeight * 0.03),
              _buildSectionTitle("PRIVACY POLICY", screenWidth),
              _buildParagraph(
                "We, GOBUDDY (A product of Nanosoft Solutions “Company”, “we”, “us”, or “our”) respect your privacy and are committed to protecting it through our compliance with this policy (the “Privacy Policy”).",
                screenWidth,
              ),
              _buildParagraph(
                "This section is used to inform visitors regarding our policies with the collection, use, and disclosure of Personal Information if anyone decided to use our Service.",
                screenWidth,
              ),
              _buildParagraph(
                "If you choose to use our Service, then you agree to the collection and use of information in relation to this policy. The Personal Information that we collect is used for providing and improving the Service. We will not use or share your information with anyone except as described in this Privacy Policy.",
                screenWidth,
              ),
              _buildSectionTitle("Information Collection and Use", screenWidth),
              _buildParagraph(
                "For a better experience, while using our Service, we may require you to provide us with certain personally identifiable information, including but not limited to name, email, phone, address, location. In some case we might also require to access your camera including but not limited to upload your profile picture, other KYC documents. The information that we request will be retained by us and used as described in this privacy policy.",
                screenWidth,
              ),
              _buildSectionTitle("Log Data", screenWidth),
              _buildParagraph(
                "We want to inform you that whenever you use our Service, in a case of an error in the app we collect data and information (through third party products) on your phone called Log Data. This Log Data may include information such as your device Internet Protocol (“IP”) address, device name, operating system version, the configuration of the app when utilizing our Service, the time and date of your use of the Service, and other statistics.",
                screenWidth,
              ),
              _buildSectionTitle("Location Information", screenWidth),
              _buildParagraph(
                "Subject to the provisions regarding the use of your Personal Information, above, we may use and store information about your location. We use this information for the purposes set out above, and specifically, to provide features of our Service, to improve and customize our Service. You can enable or disable location services when you use our Service at any time, through your mobile device settings.",
                screenWidth,
              ),
              _buildSectionTitle("Cookies", screenWidth),
              _buildParagraph(
                "Cookies are files with a small amount of data that are commonly used as anonymous unique identifiers. These are sent to your browser from the websites that you visit and are stored on your device's internal memory.",
                screenWidth,
              ),
              _buildSectionTitle("Service Providers", screenWidth),
              _buildParagraph(
                "We may employ third-party companies and individuals due to the following reasons:\n• To facilitate our Service;\n• To provide the Service on our behalf;\n• To perform Service-related services; or\n• To assist us in analyzing how our Service is used.",
                screenWidth,
              ),
              _buildSectionTitle("Disclosure of Your Information", screenWidth),
              _buildParagraph(
                "We may disclose aggregated information about our users, and information that does not identify any individual (including de-identified information), without restriction. We may also disclose Personal Information that we collect from you or you provide as described in this Privacy Policy for various business and legal purposes.",
                screenWidth,
              ),
              _buildSectionTitle("Security", screenWidth),
              _buildParagraph(
                "We value your trust in providing us your Personal Information, thus we are striving to use commercially acceptable means of protecting it. But remember that no method of transmission over the internet, or method of electronic storage is 100% secure and reliable, and we cannot guarantee its absolute security.",
                screenWidth,
              ),
              _buildSectionTitle("Children’s Privacy", screenWidth),
              _buildParagraph(
                "These Services do not address anyone under the age of 13. We do not knowingly collect personally identifiable information from children under 13. If discovered, we immediately delete such information.",
                screenWidth,
              ),
              _buildSectionTitle("Changes to This Privacy Policy", screenWidth),
              _buildParagraph(
                "We may update our Privacy Policy from time to time. Thus, you are advised to review this page periodically for any changes.",
                screenWidth,
              ),
              _buildSectionTitle("Contact Us", screenWidth),
              _buildParagraph(
                "If you have any questions or suggestions about our Privacy Policy, do not hesitate to contact us at support@gobuddyindia.com.",
                screenWidth,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, double screenWidth) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: screenWidth * 0.045,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildParagraph(String text, double screenWidth) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: screenWidth * 0.04,
          height: 1.5,
        ),
      ),
    );
  }
}
