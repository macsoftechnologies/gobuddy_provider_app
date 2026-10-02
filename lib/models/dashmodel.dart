class GetDashboardDetails {
  final String? status;
  final String? message;
  final Profile? profile;
  final int? subscriptionCount;

  GetDashboardDetails({
    this.status,
    this.message,
    this.profile,
    this.subscriptionCount,
  });

  factory GetDashboardDetails.fromJson(Map<String, dynamic> json) {
    return GetDashboardDetails(
      status: json['status']?.toString(),
      message: json['message'],
      profile:
          json['profile'] != null ? Profile.fromJson(json['profile']) : null,
      subscriptionCount: json['subscription_count'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'profile': profile?.toJson(),
      'subscription_count': subscriptionCount,
    };
  }
}

class Profile {
  final String? id;
  final String? name;
  final String? email;
  final String? phoneNumber;
  final String? password;
  final String? otp;
  final String? dob;
  final String? address;
  final String? customer;
  final String? provider;
  final String? termsAndConditions;
  final String? otpVerified;
  final String? latitude;
  final String? longitude;
  final String? placeId;
  final String? landmark;
  final String? adminApprovalProvider;
  final String? adminApprovalCustomer;
  final String? vacationMode;
  final String? profile;
  final String? token;
  final String? viewAs;
  final String? uniqueId;
  final String? createdDate;
  final String? status;
  final String? preferredProvider;
  final String? location;
  final String? workingCategory;
  final String? companyName;
  final String? teamCount;
  final String? referralCode;
  final String? referralId;
  final String? walletBalance;
  final String? ekycStatus;
  final String? ekycStatusName;
  final String? skills;

  Profile({
    this.id,
    this.name,
    this.email,
    this.phoneNumber,
    this.password,
    this.otp,
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
    this.profile,
    this.token,
    this.viewAs,
    this.uniqueId,
    this.createdDate,
    this.status,
    this.preferredProvider,
    this.location,
    this.workingCategory,
    this.companyName,
    this.teamCount,
    this.referralCode,
    this.referralId,
    this.walletBalance,
    this.ekycStatus,
    this.ekycStatusName,
    this.skills,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id']?.toString(),
      name: json['name'],
      email: json['email'],
      phoneNumber: json['phone_number'],
      password: json['password'],
      otp: json['otp'],
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
      profile: json['profile'],
      token: json['token'],
      viewAs: json['view_as'],
      uniqueId: json['unique_id'],
      createdDate: json['created_date'],
      status: json['status'],
      preferredProvider: json['preferred_provider'],
      location: json['location'],
      workingCategory: json['working_category'],
      companyName: json['company_name'],
      teamCount: json['team_count'],
      referralCode: json['referral_code'],
      referralId: json['referral_id'],
      walletBalance: json['wallet_balance'],
      ekycStatus: json['ekyc_status'],
      ekycStatusName: json['ekyc_status_name'],
      skills: json['skills'], // ✅ FIXED
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone_number': phoneNumber,
      'password': password,
      'otp': otp,
      'dob': dob,
      'address': address,
      'customer': customer,
      'provider': provider,
      'terms_and_conditions': termsAndConditions,
      'otp_verified': otpVerified,
      'latitude': latitude,
      'longitude': longitude,
      'place_id': placeId,
      'landmark': landmark,
      'admin_approval_provider': adminApprovalProvider,
      'admin_approval_customer': adminApprovalCustomer,
      'vacation_mode': vacationMode,
      'profile': profile,
      'token': token,
      'view_as': viewAs,
      'unique_id': uniqueId,
      'created_date': createdDate,
      'status': status,
      'preferred_provider': preferredProvider,
      'location': location,
      'working_category': workingCategory,
      'company_name': companyName,
      'team_count': teamCount,
      'referral_code': referralCode,
      'referral_id': referralId,
      'wallet_balance': walletBalance,
      'ekyc_status': ekycStatus,
      'ekyc_status_name': ekycStatusName,
      'skills': skills,
    };
  }
}