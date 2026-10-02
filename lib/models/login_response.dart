class LoginResponse {
  Status? status;
  Data? data;

  LoginResponse({this.status, this.data});

  LoginResponse.fromJson(Map<String, dynamic> json) {
    status =
    json['status'] != null ? Status.fromJson(json['status']) : null;
    if(json['status']['type'] == "Success"){
      data = json['data'] != null ? Data.fromJson(json['data']) : null;

    }else{
      data = null;

    }

  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (status != null) {
      data['status'] = status!.toJson();
    }
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Status {
  String? type;
  String? message;
  int? code;
  String? error;

  Status({this.type, this.message, this.code, this.error});

  Status.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    message = json['message'];
    code = json['code'];
    error = json['error'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['type'] = type;
    data['message'] = message;
    data['code'] = code;
    data['error'] = error;
    return data;
  }
}

class Data {
  String? status;
  UserL? user;

  Data({this.status, this.user});

  Data.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    user = json['user'] != null ? UserL.fromJson(json['user']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    if (user != null) {
      data['user'] = user!.toJson();
    }
    return data;
  }
}

class UserL {
  int? id;
  String? name;
  int? plan;
  String? referralCode;
  String? plan_name;
  int? referredBy;
  String? mobile;
  String? countryCode;
  String? profilePic;
  String? email;
  String? password;
  int? passwordChanged;
  String? app_security_key;
  String? user_security_key;
  int? percentage;

  UserL(
      { this.password,
        this.id,
        this.name,
        this.plan,
        this.plan_name,
        this.referralCode,
        this.referredBy,
        this.mobile,
        this.countryCode,
        this.profilePic,
        this.email,
        this.passwordChanged,
        this.app_security_key,
        this.user_security_key,
        this.percentage

      });

  UserL.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    plan = json['plan'];
    plan_name = json['plan_name'];
    referralCode = json['referral_code'];
    referredBy = json['referred_by'];
    mobile = json['mobile'];
    countryCode = json['country_code'];
    profilePic = json['profile_pic'];
    email = json['email'];
    passwordChanged = json['password_changed'];
    password = json['password'];
    app_security_key = json['app_security_key'];
    user_security_key = json['user_security_key'];
    percentage = json['percentage'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['plan'] = plan;
    data['plan_name'] = plan_name;
    data['referral_code'] = referralCode;
    data['referred_by'] = referredBy;
    data['mobile'] = mobile;
    data['country_code'] = countryCode;
    data['profile_pic'] = profilePic;
    data['email'] = email;
    data['password'] = password;
    data['password_changed'] = passwordChanged;
    data['app_security_key'] = app_security_key;
    data['user_security_key'] = user_security_key;
    data['percentage'] = percentage;
    return data;
  }
}