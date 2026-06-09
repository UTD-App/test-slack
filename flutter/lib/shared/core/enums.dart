/// Represents the state of an asynchronous request.
enum RequestState {
  idle,
  loading,
  loaded,
  error,
  offline,
  empty,
  banUser,
}

/// Supported language types.
enum LanguageType {
  ar,
  en,
  tr,
  ur,
  hi,
  id,
}

/// OTP verification flow type.
enum OtpType {
  register,
  resetPassword,
  passwordChange,
  verifyOldPhone,
  verifyNewPhone,
  bindAccount,
}
