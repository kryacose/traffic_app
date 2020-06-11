import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class InfoPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text("About"),
      ),
      backgroundColor: Color.fromARGB(255, 20, 20, 20),
      body: Padding(
        padding: EdgeInsets.only(top: 28, right: 20, left: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text("This project aims to provide its users with real-time traffic information. This app collects, aggregates and analyzes your location and sensor data to give you detailed maps of current road traffic, pedestrian traffic and road quality.",
            style: TextStyle(color: Colors.white, fontSize: 20, height: 1.5),),
            SizedBox(height: 30,),
            Text("The following information is collected from your device:\n    Gyroscope data\n    Accelerometer data\n    Speed\n    Heading\n    Location\nYou can change your data collection options in the Settings page.",
            style: TextStyle(color: Colors.white, fontSize: 20, height: 1.5),),
            SizedBox(height: 30,),
            RichText(
              text: TextSpan(children: [
                TextSpan(
                  text: "To view the source code for the app ",
                  style: TextStyle(color: Colors.white, fontSize: 20, height: 1.5),),
                  TextSpan(
                  text: "Click Here",
                  style: TextStyle(color: Colors.blue, fontSize: 20, height: 1.5, ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = (){
                        launch('https://github.com/kryacose/traffic_app');
                    }
                   
                  ),
                  
              ]),
            ),
            SizedBox(height: 30,),
            Text("Created by:\n    Amruth Chand\n    Kuriakose Eldho\n    L Bharath Kumar",
            style: TextStyle(color: Colors.white, fontSize: 20, height: 1.5, ),),
        ],),
      ),
    );
  }
}