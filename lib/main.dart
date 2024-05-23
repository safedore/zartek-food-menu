import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:zartek/firebase_options.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn();

  Future<UserCredential> _signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleAccount = await googleSignIn.signIn();
      final GoogleSignInAuthentication googleAuth = await googleAccount!.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print('Google sign-in failed: $e');
      throw e;
    }
  }

  Future<void> _signInWithPhone(BuildContext context) async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PhoneAuthPage()),
    );
    print('Phone authentication coming soon!');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Welcome!')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () async {
                try {
                  UserCredential userCredential = await _signInWithGoogle(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => HomeScreen(user: userCredential.user!)));
                } catch (e) {
                  print('Google sign-in failed: $e');
                }
              },
              child: Text('Google Login'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _signInWithPhone(context);
                } catch (e) {
                  print('Phone sign-in failed: $e');
                }
              },
              child: Text('Phone Login'),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final User? user;

  HomeScreen({this.user});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  List<dynamic> _categories = [];
  List<dynamic> tableList = [];
  Map<String, int> _cart = {};
  double _totalAmount = 0;

  int catCount_ = 0;

  Future<void> fetchData() async {
    final response = await http.get(Uri.parse('https://run.mocky.io/v3/eed9349e-db58-470c-ae8c-a12f6f46c207'));
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

  void _addToCart(String dishName, double price) {
    setState(() {
      if (_cart.containsKey(dishName)) {
        _cart[dishName] = _cart[dishName]! + 1;
      } else {
        _cart[dishName] = 1;
      }
      _totalAmount += price;
    });
  }

  void _removeFromCart(String dishName, double price) {
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
    if (_categories.isNotEmpty){
      setState(() {
        category = _categories[0];
      });
    }
    List categories = category['table_menu_list']??[];
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => CheckoutScreen(cart: _cart, totalAmount: _totalAmount)));
            },
          ),
        ],
        bottom: _categories.isEmpty
            ?const PreferredSize(preferredSize: Size(0, 0), child: Text(''))
            :TabBar(
          controller: _tabController,
          tabs: List.generate(tableList.length, (index) => Tab(text: tableList[index]['menu_category'],)),
          onTap: (value) => setState(() {
            index = value;
          }),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'User Info',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Name: ${widget.user?.displayName ?? 'N/A'}',
                    style: TextStyle(color: Colors.white),
                  ),
                  Text(
                    'Email: ${widget.user?.email ?? 'N/A'}',
                    style: TextStyle(color: Colors.white),
                  ),
                  Text(
                    'UID: ${widget.user?.uid}',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            ListTile(
              title: Text('Logout'),
              onTap: () {
                FirebaseAuth.instance.signOut();
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: _categories.isEmpty
          ?Center(child: CircularProgressIndicator())
            :TabBarView(
        controller: _tabController,
              children: List.generate(tableList.length, (index) => SingleChildScrollView(
                child: Column(
                  children: List.generate(
                    categories[index]['category_dishes'].length,
                        (dishIndex) {
                      Map<String, dynamic> dish = categories[index]['category_dishes'][dishIndex];
                      return ExpansionTile(
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(dish['dish_name']),
                            Text(
                              'INR ${dish['dish_price']}',
                              style: TextStyle(color: Colors.green),
                            ),
                          ],
                        ),
                        subtitle: dish['addonCat'] != null
                            ? Text('Customizations available')
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove),
                              onPressed: () => _removeFromCart(dish['dish_name'], dish['dish_price']),
                            ),
                            Text('${_cart[dish['dish_name']] ?? 0}'),
                            IconButton(
                              icon: Icon(Icons.add),
                              onPressed: () => _addToCart(dish['dish_name'], dish['dish_price']),
                            ),
                          ],
                        ),
                        children: [
                          Image.network(dish['dish_image'], height: MediaQuery.of(context).size.height/3.5,),
                          Text(dish['dish_description']),
                        ],
                      );
                    },
                  ),
                ),
              )),
            ),    );
  }
}

class CheckoutScreen extends StatelessWidget {
  final Map<String, int> cart;
  final double totalAmount;

  CheckoutScreen({required this.cart, required this.totalAmount});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Order Summary')),
      body: ListView.builder(
        itemCount: cart.length,
        itemBuilder: (context, index) {
          String dishName = cart.keys.toList()[index];
          int quantity = cart.values.toList()[index];
          return ListTile(
            title: Text(dishName),
            subtitle: Text('Quantity: $quantity'),
          );
        },
      ),
      bottomNavigationBar: BottomAppBar(
        child: Container(
          height: 50,
          child: Center(
            child: ElevatedButton(
              onPressed: () {
                _placeOrder(context);
              },
              child: Text('Place Order'),
            ),
          ),
        ),
      ),
    );
  }

  void _placeOrder(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Order Placed'),
          content: Text('Your order has been successfully placed!'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pop(context);
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

class PhoneAuthPage extends StatefulWidget {
  @override
  _PhoneAuthPageState createState() => _PhoneAuthPageState();
}

class _PhoneAuthPageState extends State<PhoneAuthPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late String _verificationId;

  void _verifyPhoneNumber(String phoneNumber) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
        Navigator.push(context, MaterialPageRoute(builder: (context) => HomeScreen()));
      },
      verificationFailed: (FirebaseAuthException e) {
        print('Phone verification failed: ${e.message}');
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _verificationId = verificationId;
        });
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        print(verificationId);
        if(verificationId == _verificationId) {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => HomeScreen(),));
        }
      },
    );
  }
  final phoneController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Phone Authentication'),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              validator: (value) {
                if(value!.isEmpty){
                  return 'Cannot be empty';
                }return null;
              },
              controller: phoneController,
            ),
            ElevatedButton(
              onPressed: () {
                if(_formKey.currentState!.validate()){
                  _verifyPhoneNumber(phoneController.text);

                }
              },
              child: Text('Verify Phone Number'),
            ),
          ],
        ),
      ),
    );
  }
}