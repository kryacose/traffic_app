import 'package:flutter/material.dart';

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
          children: <Widget>[
            Text("This project aims to provide users with real-time traffic information. This app collects, aggregates and analyzes your location and sensor data to give you detailed maps of current road traffic, pedestrian traffic and road quality.",
            style: TextStyle(color: Colors.white, fontSize: 20, height: 1.5),),
            SizedBox(height: 60,),
            Text("Created by:\nAmruth Chand\nKuriakose Eldho\nL Bharath Kumar",
            style: TextStyle(color: Colors.white, fontSize: 20, height: 1.5, ),
            textAlign: TextAlign.center,)
        ],),
      ),
    );
  }
}