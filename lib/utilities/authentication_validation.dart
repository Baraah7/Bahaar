import '../l10n/app_localizations.dart';

class AuthenticationValidation {
  static String? validateName(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) {
      return l10n.validationEnterName;
    }
    if (value.trim().length < 2) {
      return l10n.validationNameTooShort;
    }
    return null;
  }

  static String? validateEmail(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) {
      return l10n.validationEnterEmail;
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return l10n.validationInvalidEmail;
    }
    return null;
  }

  static String? validatePassword(String? value, AppLocalizations l10n) {
    if (value == null || value.isEmpty) {
      return l10n.validationEnterPassword;
    }
    if (value.length < 6) {
      return l10n.validationPasswordTooShort;
    }
    return null;
  }

  static String? validateUsername(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) {
      return l10n.validationEnterUsername;
    }
    if (value.trim().length < 3) {
      return l10n.validationUsernameTooShort;
    }
    if (value.trim().length > 20) {
      return l10n.validationUsernameTooLong;
    }
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!usernameRegex.hasMatch(value.trim())) {
      return l10n.validationUsernameInvalidChars;
    }
    return null;
  }

  static String? Function(String?) validateConfirmPassword(
      String password, AppLocalizations l10n) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return l10n.validationConfirmPassword;
      }
      if (value != password) {
        return l10n.validationPasswordsNoMatch;
      }
      return null;
    };
  }
}
