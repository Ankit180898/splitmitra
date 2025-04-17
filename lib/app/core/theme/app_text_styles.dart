import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:splitmitra/app/core/theme/color_schemes.dart';

class AppTextStyles {
  // Main Text Styles
  static final TextStyle headline1 = GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: -1.5,
    height: 1.2,
  );
  
  static final TextStyle headline2 = GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
    height: 1.3,
  );
  
  static final TextStyle headline3 = GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.3,
  );
  
  static final TextStyle headline4 = GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.25,
    height: 1.4,
  );
  
  static final TextStyle headline5 = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.4,
  );
  
  static final TextStyle headline6 = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
    height: 1.5,
  );
  
  static final TextStyle subtitle1 = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
    height: 1.5,
  );
  
  static final TextStyle subtitle2 = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.5,
  );
  
  static final TextStyle bodyText1 = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.5,
    height: 1.5,
  );
  
  static final TextStyle bodyText2 = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.25,
    height: 1.5,
  );
  
  static final TextStyle button = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.75,
    height: 1.0,
  );
  
  static final TextStyle caption = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.4,
    height: 1.3,
  );
  
  static final TextStyle overline = GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.normal,
    letterSpacing: 1.5,
    height: 1.0,
  );
  
  // Application-specific text styles
  static final TextStyle amount = GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: 0,
    height: 1.2,
  );
  
  static final TextStyle currencySymbol = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.2,
  );
  
  static final TextStyle expenseTitle = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
    height: 1.3,
  );
  
  static final TextStyle expenseCategory = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4,
    height: 1.2,
  );
  
  static final TextStyle expenseDate = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.4,
    height: 1.2,
  );
  
  static final TextStyle groupTitle = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
    height: 1.3,
  );
  
  static final TextStyle groupDescription = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.25,
    height: 1.4,
  );
  
  static final TextStyle memberName = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
    height: 1.3,
  );
  
  static final TextStyle memberEmail = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.25,
    height: 1.3,
  );
  
  static final TextStyle tabLabel = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.25,
    height: 1.0,
  );
  
  static final TextStyle bottomNavLabel = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.0,
  );
  
  // Helper method to get responsive text style
  static TextStyle getResponsiveHeadline1(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width > 1200) {
      return headline1.copyWith(fontSize: 40);
    } else if (width > 600) {
      return headline1;
    } else {
      return headline1.copyWith(fontSize: 28);
    }
  }
  
  static TextStyle getResponsiveHeadline2(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width > 1200) {
      return headline2.copyWith(fontSize: 34);
    } else if (width > 600) {
      return headline2;
    } else {
      return headline2.copyWith(fontSize: 24);
    }
  }
  
  // Utility methods for applying color to text styles
  static TextStyle withLightColor(TextStyle style) {
    return style.copyWith(color: AppColors.lightText);
  }
  
  static TextStyle withDarkColor(TextStyle style) {
    return style.copyWith(color: AppColors.darkText);
  }
  
  static TextStyle withPrimaryColor(TextStyle style) {
    return style.copyWith(color: AppColors.primary);
  }
  
  static TextStyle withSecondaryColor(TextStyle style) {
    return style.copyWith(color: AppColors.secondary);
  }
}