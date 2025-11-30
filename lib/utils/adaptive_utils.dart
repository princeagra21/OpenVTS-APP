// utils/adaptive_utils.dart

class AdaptiveUtils {
  // Private checkers
  static bool _isVerySmallScreen(double screenWidth) => screenWidth < 360;
  static bool _isSmallScreen(double screenWidth) => screenWidth < 420;

  // Public boolean helpers (now available!)
  static bool isVerySmallScreen(double screenWidth) => _isVerySmallScreen(screenWidth);
  static bool isSmallScreen(double screenWidth) => _isSmallScreen(screenWidth);

  static double getBottomBarHeight(double screenWidth) {
    return _isVerySmallScreen(screenWidth)
        ? 60
        : _isSmallScreen(screenWidth)
            ? 70
            : 80;
  }

  static double getHorizontalPadding(double screenWidth) {
    return _isVerySmallScreen(screenWidth)
        ? 8
        : _isSmallScreen(screenWidth)
            ? 12
            : 16;
  }

  static double getIconSize(double screenWidth) {
    return _isVerySmallScreen(screenWidth)
        ? 16
        : _isSmallScreen(screenWidth)
            ? 18
            : 20;
  }

  static double getAvatarSize(double screenWidth) {
    return _isVerySmallScreen(screenWidth)
        ? 26
        : _isSmallScreen(screenWidth)
            ? 30
            : 32;
  }

  static double getButtonSize(double screenWidth) {
    return _isVerySmallScreen(screenWidth)
        ? 28
        : _isSmallScreen(screenWidth)
            ? 32
            : 36;
  }

  static double getTitleFontSize(double screenWidth) {
    return _isVerySmallScreen(screenWidth)
        ? 11
        : _isSmallScreen(screenWidth)
            ? 12
            : 13;
  }

  static double getSubtitleFontSize(double screenWidth) {
    return _isVerySmallScreen(screenWidth)
        ? 14
        : _isSmallScreen(screenWidth)
            ? 16
            : 18;
  }

  static double getLeftSectionSpacing(double screenWidth) {
    return _isVerySmallScreen(screenWidth)
        ? 6
        : _isSmallScreen(screenWidth)
            ? 8
            : 10;
  }

  static double getIconPaddingLeft(double screenWidth) {
    return _isVerySmallScreen(screenWidth)
        ? 6
        : _isSmallScreen(screenWidth)
            ? 8
            : 12;
  }

  static double getRightAvatarPaddingLeft(double screenWidth) {
    return _isVerySmallScreen(screenWidth)
        ? 8
        : _isSmallScreen(screenWidth)
            ? 10
            : 14;
  }

  static double getFsAvatarFontSize(double screenWidth) {
    return _isVerySmallScreen(screenWidth)
        ? 9
        : _isSmallScreen(screenWidth)
            ? 11
            : 12;
  }

  static double getBellNotificationFontSize(double screenWidth) {
    return _isVerySmallScreen(screenWidth) ? 9 : 10.5;
  }

  static double getRightAvatarRadius(double screenWidth) {
    return _isVerySmallScreen(screenWidth)
        ? 12
        : _isSmallScreen(screenWidth)
            ? 14
            : 16;
  }

  static double getRightAvatarFontSize(double screenWidth) {
    return _isVerySmallScreen(screenWidth)
        ? 9
        : _isSmallScreen(screenWidth)
            ? 11
            : 13;
  }
}