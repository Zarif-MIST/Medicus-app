import 'package:flutter/material.dart';
class MTextTheme{
  MTextTheme._();
  static TextTheme lightTextTheme = TextTheme(
    headlineLarge: TextStyle().copyWith(
      fontSize: 32.0,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    ),
    headlineMedium: TextStyle().copyWith(
      fontSize: 24.0,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    ),
    headlineSmall: TextStyle().copyWith(
      fontSize: 20.0,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    ),
    titleLarge: TextStyle().copyWith(
      fontSize: 18.0,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    ),
    titleMedium: TextStyle().copyWith(
      fontSize: 16.0,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    ),
    titleSmall: TextStyle().copyWith(
      fontSize: 14.0,     
      fontWeight: FontWeight.bold,
      color: Colors.black,
    ), 
    bodyLarge: TextStyle().copyWith(
      fontSize: 16.0,
      color: Colors.black,
    ),
    bodyMedium: TextStyle().copyWith(
      fontSize: 14.0,     
      color: Colors.black,
    ),
    bodySmall: TextStyle().copyWith(
      fontSize: 12.0,     
      color: Colors.black,
    ),
    labelLarge: TextStyle().copyWith(
      fontSize: 14.0,     
      color: Colors.black,
    ),
    labelMedium: TextStyle().copyWith(
      fontSize: 12.0,     
      color: Colors.black,      
    ),

  );

  static TextTheme darkTextTheme = TextTheme(
    headlineLarge: TextStyle().copyWith(
      fontSize: 32.0,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
    headlineMedium: TextStyle().copyWith(
      fontSize: 24.0,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
    headlineSmall: TextStyle().copyWith(
      fontSize: 20.0,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
    titleLarge: TextStyle().copyWith(
      fontSize: 18.0,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
    titleMedium: TextStyle().copyWith(
      fontSize: 16.0,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
    titleSmall: TextStyle().copyWith(
      fontSize: 14.0,     
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ), 
    bodyLarge: TextStyle().copyWith(
      fontSize: 16.0,
      color: Colors.white,
    ),      
    bodyMedium: TextStyle().copyWith(
      fontSize: 14.0,     
      color: Colors.white,
    ),
    bodySmall: TextStyle().copyWith(
      fontSize: 12.0,     
      color: Colors.white,
    ),
    labelLarge: TextStyle().copyWith(
      fontSize: 14.0,     
      color: Colors.white,
    ),    
    labelMedium: TextStyle().copyWith(
      fontSize: 12.0,     
      color: Colors.white,      
    ),  
  );
}