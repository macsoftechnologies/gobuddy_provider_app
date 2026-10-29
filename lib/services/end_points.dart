class EndPoints {
  //base_url
  static const String newbaseUrl = "https://dev.gobuddyindia.com/api/";
  //full_urls
  static const String newLoginApi = "${newbaseUrl}newlogin";
  static const String providerLoginApi = "${newbaseUrl}providerlogin";
  static const String providerRegisterApi = "${newbaseUrl}provider_register";
  static const String locaCatApi = "${newbaseUrl}locationbasedoncategories";
  static const String resendOtp = "${newbaseUrl}resend_login_otp";
  static const String verifyOtp = "${newbaseUrl}verify_otp";
  static const String ekycApi = "${newbaseUrl}ekyc";
  static const String onetimeregistrationApi =
      "${newbaseUrl}onetimeregistration";
  static const String getOneTimeRegistrationFee =
      "${newbaseUrl}getonetimeregistrationfee";
  static const String getReferralDetails =
      "${newbaseUrl}getreferraldetails";
  static const String newlogin = "${newbaseUrl}newlogin";
  static const String profile = "${newbaseUrl}profile";
    static const String dashboard = "${newbaseUrl}dashboard";
 static const String advertise = "${newbaseUrl}getprovideradvertisements";
 static const String getOderAlert = "${newbaseUrl}getProviderRecentOrders";
    
  static const String updateProfile = "${newbaseUrl}update_profile";
  static const String inactiveUser = "${newbaseUrl}inactiveuser";
  static const String tools = "${newbaseUrl}requesttools";
  static const String addrequesttool = "${newbaseUrl}addrequesttool";
  static const String getMyQrCode = "${newbaseUrl}get_qrcode_image";

  static const String catsubCat =
      "${newbaseUrl}categorybasedsubcategoryservices";
  static const String catAddons = "${newbaseUrl}categorybasedaddons";
  static const String upgradeSub = "${newbaseUrl}upgrade_provider_subscription";

  static const String servicesApi = "${newbaseUrl}services";
  static const String uploadQrCode = "${newbaseUrl}upload_qrcode_image";
  static const String getNotifications = "${newbaseUrl}getProviderNotifications";

  static const String packagesApi = "${newbaseUrl}getjobspackage";
  static const String addprovSubscriptionApi =
      "${newbaseUrl}add_provider_subscription";
  static const String getprovSubscriptionApi =
      "${newbaseUrl}get_provider_subscription";
  static const String deleteprovSubscriptionApi =
      "${newbaseUrl}delete_provider_subscription";

  static const String upadteprovSubscriptionApi =
      "${newbaseUrl}update_provider_subscription";

  static const String coupounApi = "${newbaseUrl}check_coupon";
  static const String subPayment = "${newbaseUrl}provider_subscription_payment";

       static const String subscriptionorders ="${newbaseUrl}get_provider_subscriptionorders";
       static const String getOrders = "${newbaseUrl}getMyOrders";
       static const String orderDetails = "${newbaseUrl}viewOrderDetails";
       static const String addImages = "${newbaseUrl}add_provider_gallery";
       static const String submitDetails = "${newbaseUrl}orderchargessubmitted";
       static const String updateCharges = "${newbaseUrl}update_order_charges";
       static const String verifyCode = "${newbaseUrl}verify_code";
       static const String cancelOrders = "${newbaseUrl}providercancelorder";
      static const String orderaccept = "${newbaseUrl}orderaccept";
      static const String getCalendarOverveiwDetails = "${newbaseUrl}get_calendar";



        //Profile
        static const String getProfileDetails = "${newbaseUrl}profile";
        static const String getAllCategories = "${newbaseUrl}categories";
        static const String getmyEarnings = "${newbaseUrl}dashboard";
        static const String getMySUbscriptonDashboard = "${newbaseUrl}get_provider_subscriptionorders";
        static const String updateprofile = "${newbaseUrl}update_profile";




        //Subscription
        static const String getSubscriptionsforProvider = "${newbaseUrl}locationbasedoncategories";
        static const String getplansforProviderSubscription = "${newbaseUrl}get_packages";
        static const String getSubcategoriesData = "${newbaseUrl}categorybasedsub_category";
        static const String getservices = "${newbaseUrl}services";
        static const String getAddons = "${newbaseUrl}categorybasedaddons";
        static const String getdropdown = "${newbaseUrl}get_planwise_packages";
        static const String addSubscriptionProvider = "${newbaseUrl}add_provider_subscription";
        static const String getproviderActiveSubscriptionbyId = "${newbaseUrl}get_provider_subscriptionorders";
        static const String updateProviderSubscription = "${newbaseUrl}update_provider_subscription";
        static const String getUpdateAddress = "${newbaseUrl}update_address";

        // Vacation & Calendar
        static const String setVacation = "${newbaseUrl}set_vacation";
        static const String setTime = "${newbaseUrl}set_time";
        static const String deleteVacation = "${newbaseUrl}delete_entry";
        static const String getDayDetails = "${newbaseUrl}get_day_details";

        // eKYC & Status
        static const String getEkycDetails = "${newbaseUrl}get_ekyc_details";
        static const String checkUserStatus = "${newbaseUrl}check_user_status";

        // Ratings & Cancel Reasons
        static const String providerRatingsReviews = "${newbaseUrl}provider_ratings_reviews";
        static const String getProviderCancelReasons = "${newbaseUrl}getprovidercancelreasons";
        static const String getProviderCategories = "${newbaseUrl}getprovidercategories";
        static const String sendMessage = "${newbaseUrl}send_message";
        static const String openOrders = "${newbaseUrl}openorders";
        static const String pendingOrders = "${newbaseUrl}pending_orders";
        static const String completeOrders = "${newbaseUrl}completeorders";
        static const String cancelOrdersList = "${newbaseUrl}cancelorders";
}
