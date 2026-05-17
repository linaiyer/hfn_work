import 'package:flutter/material.dart';
import 'package:hfn_work/auth_screen/login.dart';
import 'package:hfn_work/auth_screen/create_account.dart';
import 'package:hfn_work/bottom_shet/bottom_navigation.dart';

class welcome extends StatefulWidget {
  @override
  _welcome createState() => _welcome();
}

class _welcome extends State<welcome> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: h,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x330F75BC), Color(0x33073656)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 32.0,
                    vertical: h * 0.05,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Welcome to',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontFamily: 'WorkSans',
                          fontWeight: FontWeight.w700,
                          fontSize: (h * 0.038).clamp(22.0, 34.0),
                          color: const Color(0xFF485370),
                        ),
                      ),
                      SizedBox(height: h * 0.025),

                      PhysicalModel(
                        color: Colors.transparent,
                        shadowColor: Colors.black.withOpacity(0.1),
                        elevation: 4,
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                          height: (h * 0.14).clamp(70.0, 140.0),
                        ),
                      ),
                      SizedBox(height: h * 0.035),

                      Text(
                        'The Real Work Happens in Silence.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontFamily: 'WorkSans',
                          fontWeight: FontWeight.w400,
                          fontSize: (h * 0.022).clamp(14.0, 20.0),
                          color: const Color(0xFF485370).withOpacity(0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: h * 0.04),

                      ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => create_account()),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F75BC),
                          foregroundColor: const Color(0xFFFBFBFB),
                          textStyle: TextStyle(
                            fontFamily: 'WorkSans',
                            fontWeight: FontWeight.w700,
                            fontSize: (h * 0.024).clamp(15.0, 22.0),
                          ),
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                            side: const BorderSide(
                                color: Color(0xFF485370), width: 2),
                          ),
                          elevation: 2,
                        ),
                        child: const Text('Create an account'),
                      ),
                      SizedBox(height: h * 0.02),

                      OutlinedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => login()),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xFFFBFBFB),
                          foregroundColor: const Color(0xFF485370),
                          textStyle: TextStyle(
                            fontFamily: 'WorkSans',
                            fontWeight: FontWeight.w400,
                            fontSize: (h * 0.024).clamp(15.0, 22.0),
                          ),
                          minimumSize: const Size(double.infinity, 52),
                          side: const BorderSide(
                              color: Color(0xFF485370), width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 1,
                        ),
                        child: const Text('Log in'),
                      ),
                      SizedBox(height: h * 0.01),

                      TextButton(
                        onPressed: () => Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (_) => bottom_navigation()),
                          (route) => false,
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor:
                              const Color(0xFF485370).withOpacity(0.7),
                          textStyle: TextStyle(
                            fontFamily: 'WorkSans',
                            fontWeight: FontWeight.w400,
                            fontSize: (h * 0.021).clamp(13.0, 19.0),
                            decoration: TextDecoration.underline,
                          ),
                          minimumSize: const Size(double.infinity, 44),
                        ),
                        child: const Text('Continue as Guest'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
