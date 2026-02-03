class UrlContainer {
  static const String domainUrl = 'https://merorides.com'; //YOUR WEBSITE DOMAIN URL HERE

  static const String baseUrl = '$domainUrl/api/';
  static const String dashBoardEndPoint = 'dashboard';
  static const String depositHistoryUrl = 'deposit/history';
  static const String depositMethodUrl = 'deposit/methods';
  static const String addMoneyUrl = 'add-money';

  static const String registrationEndPoint = 'register';
  static const String loginEndPoint = 'login';
  static const String socialLoginEndPoint = 'social-login';
  static const String logoutUrl = 'logout';

  static const String forgetPasswordEndPoint = 'password/email';
  static const String passwordVerifyEndPoint = 'password/verify-code';
  static const String resetPasswordEndPoint = 'password/reset';

  static const String verify2FAUrl = 'verify-g2fa';
  static const String otpVerify = 'otp-verify';
  static const String otpResend = 'otp-resend';

  static const String verifyEmailEndPoint = 'verify-email';
  static const String verifySmsEndPoint = 'verify-mobile';
  static const String resendVerifyCodeEndPoint = 'resend-verify/';
  static const String authorizationCodeEndPoint = 'authorization';
  static const String dashBoardUrl = 'dashboard';
  static const String paymentHistoryEndpoint = 'payment/history';

  static const String addWithdrawRequestUrl = 'withdraw-request';
  static const String withdrawMethodUrl = 'withdraw-method';
  static const String withdrawRequestConfirm = 'withdraw-request/confirm';
  static const String withdrawHistoryUrl = 'withdraw/history';
  static const String withdrawStoreUrl = 'withdraw/store/';
  static const String withdrawConfirmScreenUrl = 'withdraw/preview/';
  static const String kycFormUrl = 'kyc-form';
  static const String kycSubmitUrl = 'kyc-submit';
  static const String riderVerificationFormUrl = 'rider-verification';
  static const String riderAgreementUrl = 'rider-agreement';

  static const String generalSettingEndPoint = 'general-setting';
  static const String userDeleteEndPoint = 'delete-account';
  static const String privacyPolicyEndPoint = 'policies';
  static const String agreementsEndPoint = 'agreements';
  static const String getProfileEndPoint = 'user-info';
  static const String updateProfileEndPoint = 'profile-setting';
  static const String profileCompleteEndPoint = 'user-data-submit';
  static const String faq = "faq";

  static const String changePasswordEndPoint = 'change-password';
  static const String countryEndPoint = 'get-countries';
  static const String deviceTokenEndPoint = 'save-device-token';
  static const String languageUrl = 'language/';

  static const String ride = 'ride';
  static const String rideDetails = '$ride/details';
  static const String ridePayment = '$ride/payment';
  static const String rideFareAndDistance = '$ride/fare-and-distance';
  static const String createRide = '$ride/create';

  static const String reviewEndpoint = 'review';
  static const String reviewStoreEndpoint = 'review';
  static const String reviewRide = 'review'; // For backward compatibility
  static const String getDriverReviewEndpoint = 'get-driver-review';
  static const String getDriverReview = 'get-driver-review'; // For backward compatibility

  // Nearby Drivers
  static const String nearbyDriversEndpoint = 'nearby-drivers';
  static const String driverDetailsEndpoint = 'driver-details';
  static const String rideList = '$ride/list';

  static const String activeRide = '$ride/active';
  static const String completedRide = '$ride/completed';
  static const String canceledRide = '$ride/canceled';

  static const String sosRide = '$ride/sos';
  static const String rideMessageList = '$ride/messages';
  static const String sendMessage = '$ride/send/message';
  static const String rideBidList = '$ride/bids';
  static const String acceptBid = '$ride/accept';
  static const String rejectBid = '$ride/reject';
  static const String cancelBid = '$ride/cancel';

  // coupon

  static const String reference = 'reference';
  static const String couponList = 'coupons';
  static const String applyCoupon = 'apply-coupon';
  static const String removeCoupon = 'remove-coupon';

  static const String paymentGateways = 'payment-gateways';
  static const String submitPayment = 'payment';
  static const String paymentHistory = 'payment/history';
  static const String pusherAuthenticate = 'pusher/auth/';

  //support ticket
  static const String supportMethodsEndPoint = 'support/method';
  static const String supportListEndPoint = 'ticket';
  static const String storeSupportEndPoint = 'ticket/create';
  static const String supportViewEndPoint = 'ticket/view';
  static const String supportReplyEndPoint = 'ticket/reply';
  static const String supportCloseEndPoint = 'ticket/close';
  static const String supportDownloadEndPoint = 'ticket/download';

  // Package endpoints (legacy)
  static const String packageEndpoint = 'package';

  // Package Management endpoints (new)
  static const String packagesAvailableEndpoint = 'packages/available';
  static const String packagesActiveEndpoint = 'packages/active';
  static const String packagesHistoryEndpoint = 'packages/history';
  static const String packagesUsageEndpoint = 'packages/usage';

  // Package Schedule endpoints
  static const String packageScheduleDetailsEndpoint = 'package-schedule/details';
  static const String packageSchedulePurchaseEndpoint = 'package-schedule/purchase';
  static const String packageScheduleMySchedulesEndpoint = 'package-schedule/my-schedules';

  // Reservation endpoints
  static const String reservationEndpoint = 'reservations';
  static const String reservationsActiveEndpoint = 'reservations/active';
  static const String reservationsUpcomingEndpoint = 'reservations/upcoming';
  static const String reservationsHistoryEndpoint = 'reservations/history';
  static const String reservationSchedulesEndpoint = 'reservations/schedules';
  static const String reservationAvailableServicesEndpoint = 'reservations/available-services';

  static const String rideReceipt = "${baseUrl}ride/receipt";
  static const String supportImagePath = '$domainUrl/assets/support/';
  static const String userImagePath = '$domainUrl/assets/support/';
  static const String serviceImagePath = '$domainUrl/assets/images/service/';
  // others url
  static const String countryFlagImageLink = 'https://flagpedia.net/data/flags/h24/{countryCode}.webp';
  static const String googleMapLocationSearch = 'https://maps.googleapis.com/maps/api';
}
