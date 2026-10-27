import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(const TwistApp());

class TwistApp extends StatelessWidget {
  const TwistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'تويست',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF070B14),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00FF88),
          brightness: Brightness.dark,
        ),
      ),
      home: const TwistLoginScreen(),
    );
  }
}

// 1. شاشة تسجيل الدخول (إدخال رقم الهاتف)
class TwistLoginScreen extends StatefulWidget {
  const TwistLoginScreen({super.key});

  @override
  State<TwistLoginScreen> createState() => _TwistLoginScreenState();
}

class _TwistLoginScreenState extends State<TwistLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Map<String, String> _getBaseHeaders() {
    return {
      'User-Agent': "Twist-Mobile/11.2.9 (Android; 14; RMX3630; music; ar-MA)",
      'Accept': "application/json",
      'Accept-Encoding': "gzip",
      'Content-Type': "application/json",
      'app_version': "11.2.9",
      'channel': "mobileapp",
      'platform': "android",
      'accept-language': "ar",
      'device_id': "UKQ1.230924.001",
    };
  }

  Future<void> _sendOtpCode() async {
    String rawPhone = _phoneController.text.trim();
    if (rawPhone.isEmpty) {
      setState(() {
        _errorMessage = "⚠️ يرجى إدخال رقم الهاتف بشكل صحيح.";
      });
      return;
    }

    String phone = rawPhone.replaceAll("+", "").replaceAll(" ", "").replaceAll("-", "");
    if (phone.startsWith("01") && phone.length == 11) {
      phone = "2" + phone;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse("https://api.twistmena.com/music/Dlogin/sendCode"),
        headers: _getBaseHeaders(),
        body: jsonEncode({"dial": phone}),
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TwistOtpScreen(phone: phone, headers: _getBaseHeaders()),
          ),
        );
      } else {
        setState(() {
          _errorMessage = "❌ فشل إرسال الكود من الخادم.";
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "❌ خطأ في الاتصال: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تويست - تسجيل الدخول', style: TextStyle(fontSize: 16)),
        backgroundColor: const Color(0xFF111827),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF00FF88).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF00FF88).withOpacity(0.3)),
                ),
                child: const Icon(Icons.phone_android_rounded, color: Color(0xFF00FF88), size: 48),
              ),
              const SizedBox(height: 20),
              const Text(
                'تطبيق تويست',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'رقم الهاتف (مثال: 01xxxxxxxxx)',
                        labelStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                        prefixIcon: const Icon(Icons.phone, color: Color(0xFF00FF88)),
                        filled: true,
                        fillColor: const Color(0xFF030712),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _sendOtpCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00FF88),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _isLoading
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                            : const Text('إرسال كود التحقق (OTP)', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 14),
                      Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 12), textAlign: TextAlign.center),
                    ]
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 2. شاشة تأكيد رمز الـ OTP
class TwistOtpScreen extends StatefulWidget {
  final String phone;
  final Map<String, String> headers;
  const TwistOtpScreen({super.key, required this.phone, required this.headers});

  @override
  State<TwistOtpScreen> createState() => _TwistOtpScreenState();
}

class _TwistOtpScreenState extends State<TwistOtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _verifyOtp() async {
    String code = _otpController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse("https://api.twistmena.com/music/Dlogin/verify"),
        headers: widget.headers,
        body: jsonEncode({
          "dial": widget.phone,
          "verifyCode": code,
          "socialServiceName": "",
          "socialServiceToken": ""
        }),
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String? token = data['token'] ?? data['authorization'];
        if (token != null) {
          Map<String, String> userHeaders = Map.from(widget.headers);
          userHeaders['authorization'] = 'Bearer ${token.replaceAll('Bearer ', '')}';
          userHeaders['access-token'] = data['accessToken'] ?? '';

          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => TwistDashboardScreen(headers: userHeaders),
            ),
          );
          return;
        }
      }
      setState(() {
        _errorMessage = "❌ كود التحقق غير صحيح أو انتهت صلاحيته.";
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "❌ خطأ في التحقق: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تويست - تأكيد رمز OTP'), backgroundColor: const Color(0xFF111827)),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 20, letterSpacing: 5),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: 'أدخل الكود المكون من أرقام',
                hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14, letterSpacing: 0),
                filled: true,
                fillColor: const Color(0xFF111827),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00FF88),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                    : const Text('تحقق ودخول الحساب', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 14),
              Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
            ]
          ],
        ),
      ),
    );
  }
}

// 3. لوحة التحكم (Dashboard) لعرض الرصيد وسحب الوحدات
class TwistDashboardScreen extends StatefulWidget {
  final Map<String, String> headers;
  const TwistDashboardScreen({super.key, required this.headers});

  @override
  State<TwistDashboardScreen> createState() => _TwistDashboardScreenState();
}

class _TwistDashboardScreenState extends State<TwistDashboardScreen> {
  int balance = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBalance();
  }

  Future<void> _fetchBalance() async {
    try {
      final r = await http.get(
        Uri.parse('https://api.twistmena.com/music/user/loyalty/balance/details'),
        headers: widget.headers,
      );
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        setState(() {
          balance = int.tryParse(data['balance'].toString()) ?? 0;
          isLoading = false;
        });
        return;
      }
    } catch (_) {}
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _redeemUnits(String redeemId, int unitsCount) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('⏳ جاري تنفيذ عملية السحب...')),
    );
    try {
      final res = await http.post(
        Uri.parse("https://api.twistmena.com/music/loyalty/redeem/$redeemId"),
        headers: widget.headers,
      );
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ تم سحب $unitsCount وحدة بنجاح!')),
        );
        _fetchBalance();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ فشل السحب، تأكد من كفاية الرصيد.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ خطأ: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تويست - لوحة التحكم VIP'),
        backgroundColor: const Color(0xFF111827),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00FF88)))
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111827),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF00FF88).withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        const Text('رصيد الكوينز الحالي', style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 8),
                        Text('$balance كوينز', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF00FF88))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  const Text('الباقات المتاحة للسحب:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  Expanded(
                    child: ListView(
                      children: [
                        _buildRedeemButton(50, 100, "EAND_50_UNITS_ID_9"),
                        _buildRedeemButton(100, 200, "EAND_100_UNITS_ID_10"),
                        _buildRedeemButton(150, 300, "EAND_150_UNITS_ID_11"),
                        _buildRedeemButton(300, 600, "EAND_300_UNITS_ID_12"),
                        _buildRedeemButton(500, 1000, "EAND_500_UNITS_ID_13"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildRedeemButton(int units, int coinsCost, String stringId) {
    bool canAfford = balance >= coinsCost;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton(
        onPressed: canAfford ? () => _redeemUnits(stringId, units) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canAfford ? const Color(0xFF059669) : Colors.grey.shade800,
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('🎯 سحب $units وحدة', style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
            Text('التكلفة: $coinsCost كوينز', style: TextStyle(fontSize: 13, color: canAfford ? Colors.white70 : Colors.grey)),
          ],
        ),
      ),
    );
  }
}
