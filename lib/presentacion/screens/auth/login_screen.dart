import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/authenticated_provider.dart';
import '../components/app_icon_widget.dart';
import '../components/message_widget.dart';
import '../interfaces/authenticated_screen_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> implements AuthenticatedScreenState {

  Future<void> initLogin() async {
    // Initialize the login process
    await context.read<AuthenticatedProvider>().login(this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade300,
              Colors.blue.shade700,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 8.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: context.read<AuthenticatedProvider>().formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // cargar el icono de la aplicación
                        AppIconWidget(),
                        const SizedBox(height: 5),
                        Column(
                          children: [
                            Text(
                              'RentChain',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E5BA8), // Azul del icono
                              ),
                            ),
                            Text(
                              'Bolivia',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF26C6B8), // Verde claro del icono
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Inicia sesión para continuar',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 30),
                        if (context.watch<AuthenticatedProvider>().message != null)
                          MessageWidget(
                            message: context.watch<AuthenticatedProvider>().message!,
                            type: context.watch<AuthenticatedProvider>().messageType,
                          ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: context.watch<AuthenticatedProvider>().emailController,
                          focusNode: context.watch<AuthenticatedProvider>().emailFocusNode,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) {
                            FocusScope.of(context).requestFocus(context.read<AuthenticatedProvider>().passwordFocusNode);
                          },
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: context.watch<AuthenticatedProvider>().passwordController,
                          focusNode: context.watch<AuthenticatedProvider>().passwordFocusNode,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) {
                            initLogin();
                          },
                          obscureText: !context.watch<AuthenticatedProvider>().isPasswordVisible,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock),
                            border: OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(Icons.visibility),
                              onPressed: () => context.read<AuthenticatedProvider>().isPasswordVisible = !context.read<AuthenticatedProvider>().isPasswordVisible,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: context.watch<AuthenticatedProvider>().isLoading ? null : initLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            child: context.watch<AuthenticatedProvider>().isLoading
                                ? const CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  )
                                : const Text(
                                    'Iniciar Sesión',
                                    style: TextStyle(fontSize: 16),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "¿No tienes cuenta?",
                              style: TextStyle(fontSize: 14),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pushReplacementNamed('/register');
                              },
                              child: const Text(
                                'Regístrate aquí',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              height: 1,
                              width: 40,
                              color: Colors.grey.shade400,
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                'o',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            Container(
                              height: 1,
                              width: 40,
                              color: Colors.grey.shade400,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacementNamed('/homeVisitante');
                          },
                          child: const Text(
                            'continuar como invitado',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  @override
  Future<void> navigateToHomeCliente() async {
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    // Navegar a la pantalla de inmuebles disponibles para que el cliente pueda ver y alquilar
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Future<void> navigateToHomePropietario() async {
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    // Simply navigate to home screen without actual authentication
    Navigator.of(context).pushReplacementNamed('/homePropietario');
  }
}
