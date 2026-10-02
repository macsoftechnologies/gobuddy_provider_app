import 'package:shared_preferences/shared_preferences.dart';

class Preferences {
  static SharedPreferences? prefs;

  static const String authCode = 'authCode';
  static const String userID = 'userID';
  static const String name = 'name';
  static const String email = 'email';
  static const String phone = 'phone';
  static const String aadhar = 'aadhar';
  static const String location = 'location';
  static const String distance = 'distance';
  static const String status = 'status';
  static const String roleID = 'roleID';
  static const String refLink = 'refLink';


  static const String fcmToken = 'fcmToken';
  static const String userDetails = 'user';

  static Future initSharedPreference() async {
    prefs = await SharedPreferences.getInstance();
  }

  static void setFcmToken(String token) {
    prefs?.setString(fcmToken, token);
  }

  static String? getFcmToken() {
    return prefs?.getString(fcmToken);
  }

  static clearPreference() async {
    await prefs!.clear();
  }
  static void setUserDetails(String user) {
    prefs!.setString(userDetails, user);
  }
  static String? getUserDetails() {
    return prefs!.getString(userDetails);
  }
  static void setAuthCode(String authCodeNew) {
    prefs!.setString(authCode, authCodeNew);
  }

  static String? getAuthCode() {
    return prefs!.getString(authCode);
  }

  static void setUserID(String userIDNew) {
    prefs!.setString(userID, userIDNew);
  }

  static String? getUserID() {
    return prefs!.getString(userID);
  }

  static void setName(String nameNew) {
    prefs!.setString(name, nameNew);
  }

  static String? getName() {
    return prefs!.getString(name);
  }

  static void setEmail(String emailNew) {
    prefs!.setString(email, emailNew);
  }

  static String? getEmail() {
    return prefs!.getString(email);
  }

  static void setPhone(String phoneNew) {
    prefs!.setString(phone, phoneNew);
  }

  static String? getPhone() {
    return prefs!.getString(phone);
  }

  static void setAadhar(String aadharNew) {
    prefs!.setString(aadhar, aadharNew);
  }

  static String? getAadhar() {
    return prefs!.getString(aadhar);
  }

  static void setLocation(String locationNew) {
    prefs!.setString(location, locationNew);
  }

  static String? getLocation() {
    return prefs!.getString(location);
  }

  static void setDistance(String distanceNew) {
    prefs!.setString(distance, distanceNew);
  }

  static String? getDistance() {
    return prefs!.getString(distance);
  }

  static void setStatus(String statusNew) {
    prefs!.setString(status, statusNew);
  }

  static String? getStatus() {
    return prefs!.getString(status);
  }

  static void setRoleID(String roleIDNew) {
    prefs!.setString(roleID, roleIDNew);
  }

  static String? getRoleID() {
    return prefs!.getString(roleID);
  }
  static void setReferralLink(String link) {
    prefs!.setString(refLink, link);
  }

  static String? getReferralLink() {
    return prefs!.getString(refLink);
  }

}
