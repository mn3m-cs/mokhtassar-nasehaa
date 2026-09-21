import 'package:alazkar/app.dart';
import 'package:alazkar/error_screen.dart';
import 'package:alazkar/services.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ErrorWidget.builder = (FlutterErrorDetails details) => ErrorScreen(
        details: details,
      );

  try {
    await initServices();
    runApp(const MyApp());
  } catch (error, stackTrace) {
    runApp(
      MaterialApp(
        home: ErrorScreen(
          details: FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
          ),
        ),
      ),
    );
  }
}
