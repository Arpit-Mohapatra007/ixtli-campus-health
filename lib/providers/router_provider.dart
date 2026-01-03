import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../screens/auth/login_screen.dart' show LoginScreen;
import '../screens/doctor/doctor_home.dart' show DoctorHome;
import '../screens/driver/driver_home.dart' show DriverHome;
import '../screens/student/book_appointment_screen.dart' show BookAppointmentScreen;
import '../screens/student/student_home.dart' show StudentHome;
import 'auth_provider.dart';
import 'user_provider.dart';

final navigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final userProfileAsync = ref.watch(currentUserProfileProvider);

  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/login',
    debugLogDiagnostics: true, 

    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/student',
        builder: (context, state) => const StudentHome(),
      ),
      GoRoute(
        path: '/doctor',
        builder: (context, state) => const DoctorHome(),
      ),
      GoRoute(
        path: '/driver',
        builder: (context, state) => const DriverHome(),
      ),
      GoRoute(
        path: '/splash',
        builder: (context, state) => const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(
        path: '/student/book', 
        builder: (context, state) => const BookAppointmentScreen()
      ),
    ],

    redirect: (context, state) {
      final isLoading = authState.isLoading || userProfileAsync.isLoading;
      final hasError = authState.hasError || userProfileAsync.hasError;
      
      if (isLoading) return '/splash';
      if (hasError) return '/login'; 

      final isAuthenticated = authState.value != null;
      final userRole = userProfileAsync.value?.role;

      final isLoggingIn = state.uri.toString() == '/login';
      final isSplash = state.uri.toString() == '/splash';

      if (!isAuthenticated) {
        return isLoggingIn ? null : '/login';
      }

      if (isAuthenticated && userRole == null) {
         return '/splash';
      }

      if (isLoggingIn || isSplash) {
        switch (userRole) {
          case 'student': return '/student';
          case 'doctor': return '/doctor';
          case 'driver': return '/driver';
          case 'admin': return '/admin'; 
          default: return '/login';
        }
      }
      
      return null;
    },
  );
});