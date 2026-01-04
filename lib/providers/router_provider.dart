import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../screens/auth/login_screen.dart' show LoginScreen;
import '../screens/chat/chat_screen.dart' show ChatScreen;
import '../screens/doctor/consultation_screen.dart' show ConsultationScreen;
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
        routes: [
              GoRoute(
            path: 'bookAppointment', 
            builder: (context, state) => const BookAppointmentScreen()
          ),
        ]
      ),
      GoRoute(
        path: '/doctor',
        builder: (context, state) => const DoctorHome(),
        routes: [
          GoRoute(
            path: 'consultation', 
            builder: (context, state) {
              final map = state.extra as Map<String, dynamic>;
              return ConsultationScreen(
                appointmentId: map['appointmentId'],
                appointmentData: map['appointmentData'],
              );
            },
          ),
          GoRoute(
            path: 'chat',
            builder: (context, state) {
              final map = state.extra as Map<String, dynamic>;
              return ChatScreen(
                chatId: map['chatId'],
                otherUserName: map['otherUserName'],
              );
            },
          ),
        ]
      ),
      GoRoute(
        path: '/driver',
        builder: (context, state) => const DriverHome(),
      ),
      GoRoute(
        path: '/splash',
        builder: (context, state) => const Scaffold(body: Center(child: CircularProgressIndicator())),
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