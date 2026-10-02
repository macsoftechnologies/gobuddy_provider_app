class GetProfileModel {
  String status;
  String message;
  Profile? profile;
  int subscriptionCount;

  GetProfileModel({
    required this.status,
    required this.message,
    this.profile,
    required this.subscriptionCount,
  });

  // Factory constructor for creating an instance from JSON
  factory GetProfileModel.fromJson(Map<String, dynamic> json) {
    return GetProfileModel(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      profile: json['profile'] != null ? Profile.fromJson(json['profile']) : null,
      subscriptionCount: json['subscription_count'] ?? 0,
    );
  }

  // Convert model to JSON
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['status'] = status;
    data['message'] = message;
    if (profile != null) {
      data['profile'] = profile!.toJson();
    }
    data['subscription_count'] = subscriptionCount;
    return data;
  }
}

class Profile {
  String? id;
  String? name;
  String? email;
  String? phoneNumber;
  String? password;
  String? otp;
  dynamic forgotOtp;
  String? dob;
  String? address;
  String? customer;
  String? provider;
  String? termsAndConditions;
  String? otpVerified;
  String? latitude;
  String? longitude;
  String? placeId;
  String? landmark;
  String? adminApprovalProvider;
  String? adminApprovalCustomer;
  String? vacationMode;
  dynamic idNumber;
  String? profile;
  String? ekyc;
  String? token;
  String? viewAs;
  String? uniqueId;
  String? createdDate;
  dynamic updatedDate;
  String? status;
  String? preferredProvider;
  String? location;
  dynamic notes;
  String? workingCategory;
  String? companyName;
  String? teamCount;
  String? referralCode;
  String? alternatePhoneNumber;
  String? referralId;
  String? property;
  String? unique;
  String? deviceToken;
  String? walletBalance;
  String? ekycStatus;
  String? ekycStatusName;
  String? skills;

  Profile({
    this.id,
    this.name,
    this.email,
    this.phoneNumber,
    this.password,
    this.otp,
    this.forgotOtp,
    this.dob,
    this.address,
    this.customer,
    this.provider,
    this.termsAndConditions,
    this.otpVerified,
    this.latitude,
    this.longitude,
    this.placeId,
    this.landmark,
    this.adminApprovalProvider,
    this.adminApprovalCustomer,
    this.vacationMode,
    this.idNumber,
    this.profile,
    this.ekyc,
    this.token,
    this.viewAs,
    this.uniqueId,
    this.createdDate,
    this.updatedDate,
    this.status,
    this.preferredProvider,
    this.location,
    this.notes,
    this.workingCategory,
    this.companyName,
    this.teamCount,
    this.referralCode,
    this.alternatePhoneNumber,
    this.referralId,
    this.property,
    this.unique,
    this.deviceToken,
    this.walletBalance,
    this.ekycStatus,
    this.ekycStatusName,
    this.skills,
  });

  // Factory constructor for creating an instance from JSON
  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phoneNumber: json['phone_number'],
      password: json['password'],
      otp: json['otp'],
      forgotOtp: json['forgot_otp'],
      dob: json['dob'],
      address: json['address'],
      customer: json['customer'],
      provider: json['provider'],
      termsAndConditions: json['terms_and_conditions'],
      otpVerified: json['otp_verified'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      placeId: json['place_id'],
      landmark: json['landmark'],
      adminApprovalProvider: json['admin_approval_provider'],
      adminApprovalCustomer: json['admin_approval_customer'],
      vacationMode: json['vacation_mode'],
      idNumber: json['id_number'],
      profile: json['profile'],
      ekyc: json['ekyc'],
      token: json['token'],
      viewAs: json['view_as'],
      uniqueId: json['unique_id'],
      createdDate: json['created_date'],
      updatedDate: json['updated_date'],
      status: json['status'],
      preferredProvider: json['preferred_provider'],
      location: json['location'],
      notes: json['notes'],
      workingCategory: json['working_category'],
      companyName: json['company_name'],
      teamCount: json['team_count'],
      referralCode: json['referral_code'],
      alternatePhoneNumber: json['alternate_phone_number'],
      referralId: json['referral_id'],
      property: json['property'],
      unique: json['unique'],
      deviceToken: json['device_token'],
      walletBalance: json['wallet_balance'],
      ekycStatus: json['ekyc_status'],
      ekycStatusName: json['ekyc_status_name'],
      skills: json['skills'],
    );
  }

  // Convert model to JSON
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = id;
    data['name'] = name;
    data['email'] = email;
    data['phone_number'] = phoneNumber;
    data['password'] = password;
    data['otp'] = otp;
    data['forgot_otp'] = forgotOtp;
    data['dob'] = dob;
    data['address'] = address;
    data['customer'] = customer;
    data['provider'] = provider;
    data['terms_and_conditions'] = termsAndConditions;
    data['otp_verified'] = otpVerified;
    data['latitude'] = latitude;
    data['longitude'] = longitude;
    data['place_id'] = placeId;
    data['landmark'] = landmark;
    data['admin_approval_provider'] = adminApprovalProvider;
    data['admin_approval_customer'] = adminApprovalCustomer;
    data['vacation_mode'] = vacationMode;
    data['id_number'] = idNumber;
    data['profile'] = profile;
    data['ekyc'] = ekyc;
    data['token'] = token;
    data['view_as'] = viewAs;
    data['unique_id'] = uniqueId;
    data['created_date'] = createdDate;
    data['updated_date'] = updatedDate;
    data['status'] = status;
    data['preferred_provider'] = preferredProvider;
    data['location'] = location;
    data['notes'] = notes;
    data['working_category'] = workingCategory;
    data['company_name'] = companyName;
    data['team_count'] = teamCount;
    data['referral_code'] = referralCode;
    data['alternate_phone_number'] = alternatePhoneNumber;
    data['referral_id'] = referralId;
    data['property'] = property;
    data['unique'] = unique;
    data['device_token'] = deviceToken;
    data['wallet_balance'] = walletBalance;
    data['ekyc_status'] = ekycStatus;
    data['ekyc_status_name'] = ekycStatusName;
    data['skills'] = skills;
    return data;
  }
}