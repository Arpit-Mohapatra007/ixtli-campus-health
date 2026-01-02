import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends HookConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    
    final isLogin = useState(true); 
    final isLoading = useState(false);
   
    Future<void> handleSubmit() async {
      isLoading.value = true;
      try {
        final auth = ref.read(authServiceProvider);
        
        if (isLogin.value) {
          await auth.signIn(
            emailController.text.trim(), 
            passwordController.text.trim()
          );
        } else {
          await auth.signUp(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );
        }
      } catch (e) {
        if (context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red)
           );
        }
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(isLogin.value ? "Login" : "Register")),
      body: Center( 
        child: SingleChildScrollView( 
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               TextField(
                controller: emailController, 
                decoration: const InputDecoration(
                  labelText: "College Email",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                )
              ),
              const SizedBox(height: 15),
              TextField(
                controller: passwordController, 
                decoration: const InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ), 
                obscureText: true
              ),
              const SizedBox(height: 25),
              
              isLoading.value 
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: handleSubmit, 
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        isLogin.value ? "Sign In" : "Create Account",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      )
                    ),
                  ),

              const SizedBox(height: 15),

              TextButton(
                onPressed: () => isLogin.value = !isLogin.value,
                child: Text(isLogin.value 
                  ? "New here? Register with College ID" 
                  : "Have an account? Login"),
              )
            ],
          ),
        ),
      ),
    );
  }
}