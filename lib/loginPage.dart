import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './mapPage.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String uname;

  Future<bool> checkLogIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('isLoggedIn')) {
      if (prefs.getBool('isLoggedIn')) return true;
    } else
      return false;
  }

  @override
  void initState() {
    super.initState();
    checkLogIn().then((value) => {
          if (value)
            {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MapPage()),
              )
            }
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                "Traffic App",
                style: TextStyle(
                    fontSize: 32,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2),
              ),
              SizedBox(
                height: 90,
              ),
              TextField(
                style: TextStyle(color: Colors.white, fontSize: 18),
                onChanged: (String str) => uname = str,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Color.fromARGB(255, 30, 30, 30),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                    hoverColor: Colors.white,
                    hintText: "Username",
                    hintStyle: TextStyle(color: Colors.grey)),
              ),
              SizedBox(
                height: 30,
              ),
              TextField(
                obscureText: true,
                style: TextStyle(color: Colors.white, fontSize: 18),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Color.fromARGB(255, 30, 30, 30),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                    hintText: "Password",
                    hintStyle: TextStyle(color: Colors.grey)),
              ),
              SizedBox(
                height: 90,
              ),
              MaterialButton(
                onPressed: () async {
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  prefs.setString('username', uname);
                  prefs.setBool('isLoggedIn', true);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MapPage()),
                  );
                },
                shape: StadiumBorder(),
                color: Colors.blue,
                child: Padding(
                  padding: const EdgeInsets.only(
                      top: 12, bottom: 14, left: 32, right: 32),
                  child: Text(
                    "Login",
                    style: TextStyle(
                      fontSize: 22,
                      color: Colors.white
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
