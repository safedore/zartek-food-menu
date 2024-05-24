// ignore_for_file: use_build_context_synchronously

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:zartek/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LoginPage(),
      theme: ThemeData(
        colorScheme: const ColorScheme(
          background: Color(0xFF99FFFF),
          brightness: Brightness.light,
          primary: Color(0xC6282828),
          onPrimary: Color(0xA5D6A7A7),
          onSecondary: Color(0xA5D6A7A7),
          secondary: Color(0xC6282828),
          error: Colors.redAccent,
          onError: Colors.redAccent,
          onBackground: Colors.greenAccent,
          surface: Colors.greenAccent,
          onSurface: Colors.green,
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LoginPage extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn();

  LoginPage({super.key});

  Future<UserCredential> _signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleAccount = await googleSignIn.signIn();
      final GoogleSignInAuthentication googleAuth =
          await googleAccount!.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      if (kDebugMode) {
        print('Google sign-in failed: $e');
      }
      rethrow;
    }
  }

  Future<void> _signInWithPhone(BuildContext context) async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PhoneAuthPage()),
    );
    if (kDebugMode) {
      print('Phone authentication coming soon!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome!'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () async {
                try {
                  UserCredential userCredential =
                      await _signInWithGoogle(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              HomeScreen(user: userCredential.user!)));
                } catch (e) {
                  if (kDebugMode) {
                    print('Google sign-in failed: $e');
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.blue,
                backgroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                  side: const BorderSide(color: Colors.blue),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/google_logo.png',
                    height: 30,
                    width: 30,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Google Login',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () async {
                try {
                  await _signInWithPhone(context);
                } catch (e) {
                  if (kDebugMode) {
                    print('Phone sign-in failed: $e');
                  }
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                side: const BorderSide(color: Colors.blue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Phone Login',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final User? user;

  const HomeScreen({super.key, this.user});

  @override
  // ignore: library_private_types_in_public_api
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> _categories = [];
  List<dynamic> tableList = [];
  final Map<String, int> _cart = {};
  double _totalAmount = 0;

  int catCount_ = 0;

  Future<void> fetchData() async {
    final response = await http.get(Uri.parse(
        'https://run.mocky.io/v3/eed9349e-db58-470c-ae8c-a12f6f46c207'));
    if (response.statusCode == 200) {
      setState(() {
        _categories = json.decode(response.body);
        catCount_ = _categories.length;
        tableList = _categories[0]['table_menu_list'];
        _tabController = TabController(length: tableList.length, vsync: this);
      });
    } else {
      throw Exception('Failed to load data');
    }
  }

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  void _addToCart(String dishName, double price, String dishImage) {
    setState(() {
      if (_cart.containsKey(dishName)) {
        _cart[dishName] = _cart[dishName]! + 1;
      } else {
        _cart[dishName] = 1;
      }
      _totalAmount += price;
    });
  }

  void _removeFromCart(String dishName, double price, String dishImage) {
    setState(() {
      if (_cart.containsKey(dishName)) {
        if (_cart[dishName]! > 1) {
          _cart[dishName] = _cart[dishName]! - 1;
        } else {
          _cart.remove(dishName);
        }
        _totalAmount -= price;
      }
    });
  }

  int index = 0;

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> category = {};
    if (_categories.isNotEmpty) {
      setState(() {
        category = _categories[0];
      });
    }
    List categories = category['table_menu_list'] ?? [];
    return WillPopScope(
      onWillPop: () async {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit'),
            actions: [
              TextButton(
                onPressed: () {
                  SystemNavigator.pop(animated: true);
                },
                child: const Text('Yes'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('No'),
              ),
            ],
          ),
        );
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Home'),
          actions: [
            IconButton(
              icon: const Icon(Icons.shopping_cart),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => CheckoutScreen(
                            cart: _cart,
                            totalAmount: _totalAmount,
                            user: widget.user!)));
              },
            ),
          ],
          bottom: _categories.isEmpty
              ? const PreferredSize(preferredSize: Size(0, 0), child: Text(''))
              : TabBar(
                  controller: _tabController,
                  tabs: List.generate(
                      tableList.length,
                      (index) => Tab(
                            text: tableList[index]['menu_category'],
                          )),
                  onTap: (value) => setState(() {
                    index = value;
                  }),
                ),
        ),
        drawer: Drawer(
          child: Container(
            color: Colors.grey[900],
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: Colors.brown[800],
                    image: const DecorationImage(
                      image: AssetImage('assets/logo.png'),
                      colorFilter: ColorFilter.srgbToLinearGamma(),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text(
                        'User Info',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        widget.user?.displayName != null
                            ? 'Name: ${widget.user?.displayName ?? 'N/A'}'
                            : 'Phone: ${widget.user!.phoneNumber ?? 'N/A'}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      widget.user?.displayName != null
                          ? Text(
                              'Email: ${widget.user?.email ?? 'N/A'}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            )
                          : SizedBox(),
                      Text(
                        'UID: ${widget.user?.uid}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: Icon(
                    Icons.logout,
                    color: Colors.white,
                  ),
                  title: Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  onTap: () {
                    FirebaseAuth.instance.signOut();
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                ),
              ],
            ),
          ),
        ),
        body: _categories.isEmpty
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : TabBarView(
                controller: _tabController,
                children: List.generate(
                  tableList.length,
                  (index) => SingleChildScrollView(
                    child: Column(
                      children: List.generate(
                        categories[index]['category_dishes'].length,
                        (dishIndex) {
                          Map<String, dynamic> dish =
                              categories[index]['category_dishes'][dishIndex];
                          return ExpansionTile(
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width / 2.5,
                                    child: Text(dish['dish_name'])),
                                Text(
                                  'INR ${dish['dish_price']}',
                                  style: const TextStyle(color: Colors.green),
                                ),
                              ],
                            ),
                            subtitle: dish['addonCat'].length != 0
                                ? GestureDetector(
                                    child: const Text(
                                      'Customizations available',
                                      style: TextStyle(color: Colors.blue),
                                    ),
                                    onTap: () {
                                      showModalBottomSheet(
                                        context: context,
                                        builder: (context) => BottomSheet(
                                          onClosing: () {},
                                          builder: (context) => ListTile(
                                            title:
                                                const Text('Customizations:'),
                                            subtitle: Column(
                                              children: [
                                                for (int i = 0;
                                                    i < dish['addonCat'].length;
                                                    i++) ...{
                                                  Text(
                                                    dish['addonCat'][i]
                                                        ['addon_category'],
                                                    style: const TextStyle(
                                                      color: Colors.orange,
                                                      fontSize: 15,
                                                    ),
                                                  )
                                                },
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                : null,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: () => _removeFromCart(
                                    dish['dish_name'],
                                    dish['dish_price'],
                                    dish['dish_image'],
                                  ),
                                ),
                                Text('${_cart[dish['dish_name']] ?? 0}'),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () => _addToCart(
                                    dish['dish_name'],
                                    dish['dish_price'],
                                    dish['dish_image'],
                                  ),
                                ),
                              ],
                            ),
                            children: [
                              Image.network(
                                dish['dish_image'],
                                height:
                                    MediaQuery.of(context).size.height / 3.5,
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(dish['dish_description']),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class CheckoutScreen extends StatelessWidget {
  final Map<String, int> cart;
  final double totalAmount;
  final User user;

  const CheckoutScreen(
      {super.key,
      required this.cart,
      required this.totalAmount,
      required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Summary')),
      body: cart.isNotEmpty
          ? ListView.builder(
              itemCount: cart.length,
              itemBuilder: (context, index) {
                String dishName = cart.keys.toList()[index];
                int quantity = cart.values.toList()[index];
                return ListTile(
                  title: Text(dishName),
                  subtitle: Text('Quantity: $quantity'),
                );
              },
            )
          : Center(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.shopping_cart,
                      size: 100,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Your Cart is Empty',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Start adding items to your cart',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        // backgroundColor: Colors.blueGrey,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text('Start Shopping'),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: BottomAppBar(
        child: cart.isNotEmpty
            ? SizedBox(
                height: 50,
                child: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      _placeOrder(context);
                    },
                    child: Text('Place Order $totalAmount'),
                  ),
                ),
              )
            : null,
      ),
    );
  }

  void _placeOrder(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Order Placed'),
          content: const Text('Your order has been successfully placed!'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                cart.clear();
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HomeScreen(
                        user: user,
                      ),
                    ));
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

class PhoneAuthPage extends StatefulWidget {
  const PhoneAuthPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _PhoneAuthPageState createState() => _PhoneAuthPageState();
}

class _PhoneAuthPageState extends State<PhoneAuthPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late String _verificationId;

  final phoneController = TextEditingController();
  final codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isVerifying = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phone Authentication'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextFormField(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Mobile: +91 89009xxxxx',
                    prefixText: '+91 ',
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 10,
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Cannot be empty';
                    }
                    return null;
                  },
                  controller: phoneController,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  enabled: _isVerifying,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Verification Code',
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  controller: codeController,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      if (codeController.text.isNotEmpty) {
                        _verifyPhoneNumber('+91${phoneController.text}',
                            smsCode: codeController.text);
                      } else {
                        _verifyPhoneNumber('+91${phoneController.text}');
                      }
                    }
                  },
                  child: const Text('Verify Phone Number'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _verifyPhoneNumber(String phoneNumber, {String? smsCode}) async {
    PhoneAuthCredential credential;

    if (smsCode != null) {
      credential = PhoneAuthProvider.credential(
          verificationId: _verificationId, smsCode: smsCode);
    } else {
      try {
        await _auth.verifyPhoneNumber(
          phoneNumber: phoneNumber,
          verificationCompleted: (PhoneAuthCredential credential) async {
            UserCredential credentials =
                await _auth.signInWithCredential(credential);
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => HomeScreen(user: credentials.user)),
            );
          },
          verificationFailed: (FirebaseAuthException e) {
            if (kDebugMode) {
              print('Phone verification failed: ${e.message}');
            }
          },
          codeSent: (String verificationId, int? resendToken) {
            setState(() {
              _isVerifying = true;
              _verificationId = verificationId;
            });
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            if (kDebugMode) {
              print('Auto retrieval timed out');
            }
          },
        );
        return;
      } catch (e) {
        if (kDebugMode) {
          print('Error sending verification code: $e');
        }

        return;
      }
    }

    try {
      UserCredential credentials = await _auth.signInWithCredential(credential);
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => HomeScreen(user: credentials.user)),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Phone verification failed: $e');
      }
      setState(() {
        _isVerifying = false;
      });
    }
  }

  @override
  void dispose() {
    phoneController.dispose();
    codeController.dispose();
    super.dispose();
  }
}
