import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import '../services/api_service.dart';
import 'send_points_screen.dart';
import 'my_qr_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? profile;
  bool isLoading = true;

  bool useBiometrics = false;
  final LocalAuthentication auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    _loadBiometricSettings();
  }

  Future<void> _loadBiometricSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      useBiometrics = prefs.getBool('use_biometric_transfer') ?? false;
    });
  }

  Future<void> _toggleBiometrics(bool value) async {
    if (value) {
      bool canCheck = await auth.canCheckBiometrics;
      if (!canCheck) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Biometrics not available on this device.')));
        return;
      }
      bool authenticated = await auth.authenticate(
        localizedReason: 'Authenticate to enable biometric transfers',
      );
      if (authenticated) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('use_biometric_transfer', true);
        setState(() => useBiometrics = true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Biometrics enabled!')));
      }
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('use_biometric_transfer', false);
      setState(() => useBiometrics = false);
    }
  }

  Future<void> _changeLoginPassword() async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Login Password'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(hintText: 'New Password (min 6 chars)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.length < 6) return;
              final res = await ApiService.updateLoginPassword(controller.text);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Password changed')));
            },
            child: const Text('Save'),
          ),
        ],
      )
    );
  }

  Future<void> _setTransactionPassword() async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Transaction PIN'),
        content: TextField(
          controller: controller,
          obscureText: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'New PIN (min 4 digits)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.length < 4) return;
              final res = await ApiService.setTransactionPassword(controller.text);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'PIN updated')));
            },
            child: const Text('Save'),
          ),
        ],
      )
    );
  }

  Future<void> _fetchProfile() async {
    try {
      final res = await ApiService.getProfile();
      if (res['success'] == true) {
        setState(() => profile = res['data']);
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              child: Icon(Icons.person, size: 50),
            ),
            const SizedBox(height: 24),
            Text(profile?['first_name'] ?? 'User', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(profile?['phone_number'] ?? '', style: const TextStyle(fontSize: 16, color: Colors.grey)),
            
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Color(0xFFA7F3D0))
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Loyalty Points:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('${profile?['loyalty_points'] ?? 0} pts', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: profile == null ? null : () => Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (_) => MyQrScreen(phoneNumber: profile!['phone_number'], name: profile!['first_name']))
                    ),
                    icon: const Icon(Icons.qr_code),
                    label: const Text('My QR'),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SendPointsScreen())),
                    icon: const Icon(Icons.send),
                    label: const Text('Send Points'),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            const Align(alignment: Alignment.centerLeft, child: Text('Security Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Change Login Password'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _changeLoginPassword,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.pin_outlined),
              title: const Text('Set Transaction PIN'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _setTransactionPassword,
            ),
            const Divider(),
            SwitchListTile(
              secondary: const Icon(Icons.fingerprint),
              title: const Text('Use Biometrics for Transfers'),
              subtitle: const Text('Send points without typing PIN'),
              value: useBiometrics,
              onChanged: _toggleBiometrics,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _logout, 
                icon: const Icon(Icons.logout), 
                label: const Text('Logout', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16)
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
