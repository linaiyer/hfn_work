import 'package:flutter/material.dart';
import 'package:hfn_work/auth_screen/login.dart';
import 'package:hfn_work/auth_screen/create_account.dart';

class welcome extends StatefulWidget {
  @override
  _welcome createState() => _welcome();
}

class _welcome extends State<welcome> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0x330F75BC), // 20% top
              Color(0x33073656), // 20% bottom
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 32.0,
                vertical: 48.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Welcome title
                  Text(
                    'Welcome to',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontFamily: 'WorkSans',
                      fontWeight: FontWeight.w700,
                      fontSize: 30, // increased size
                      color: Color(0xFF485370),
                    ),
                  ),
                  SizedBox(height: 24),

                  // Logo with shadow
                  PhysicalModel(
                    color: Colors.transparent,
                    shadowColor: Colors.black.withOpacity(0.1),
                    elevation: 4,
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                      height: 100,
                    ),
                  ),
                  SizedBox(height: 32),

                  // Tagline
                  Text(
                    'The Real Work Happens in Silence.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontFamily: 'WorkSans',
                      fontWeight: FontWeight.w400,
                      fontSize: 18,
                      color: Color(0xFF485370).withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 32),

                  // Create account button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => create_account()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF0F75BC),
                      foregroundColor: Color(0xFFFBFBFB),
                      textStyle: TextStyle(
                        fontFamily: 'WorkSans',
                        fontWeight: FontWeight.w700,
                        fontSize: 20, // button text size
                      ),
                      minimumSize: Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                        side: BorderSide(color: Color(0xFF485370), width: 2),
                      ),
                      elevation: 2,
                    ),
                    child: Text('Create an account'),
                  ),
                  SizedBox(height: 24),

                  // Log in button
                  OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => login()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Color(0xFFFBFBFB),
                      foregroundColor: Color(0xFF485370),
                      textStyle: TextStyle(
                        fontFamily: 'WorkSans',
                        fontWeight: FontWeight.w400,
                        fontSize: 20, // login text size
                      ),
                      minimumSize: Size(double.infinity, 56),
                      side: BorderSide(color: Color(0xFF485370), width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 1,
                    ),
                    child: Text('Log in'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}