import 'dart:async';
import 'dart:isolate';
import 'package:sensors/sensors.dart';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:ui' as ui;
// import 'package:geolocator/geolocator.dart';

Future<Uint8List> getBytesFromAsset(String path, int width) async {
  ByteData data = await rootBundle.load(path);
  ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
      targetWidth: width);
  ui.FrameInfo fi = await codec.getNextFrame();
  return (await fi.image.toByteData(format: ui.ImageByteFormat.png))
      .buffer
      .asUint8List();
}

class MapPage extends StatefulWidget {
  MapPage({Key key}) : super(key: key);

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  String mapType = "vehicle";
  BitmapDescriptor markerIcon;
  List markerLocations = [
    [10.017560, 76.348831],
    [10.017660, 76.348571],
    [10.017610, 76.349001],
    [10.017610, 76.349050],
    [10.017915, 76.349197],
    [10.017935, 76.349297],
    [10.017935, 76.349347],
    [10.017955, 76.349497],
    [10.018067, 76.350797],
    [10.018067, 76.350897],
    [10.018067, 76.350997],
    [10.018067, 76.350497],
    [10.017164, 76.347274],
    [10.017164, 76.347274]
  ];
  Set<Marker> _markers = {};
  double _zoom = 16.0;

  //Variables for the sensor data and shit
  List<StreamSubscription<dynamic>> _streamSubscriptions = new List(2);
  List<List<double>> gyroValues =
      List.generate(2, (_) => new List(3), growable: false);
  List<List<double>> accValues =
      List.generate(2, (_) => new List(3), growable: false);
  int gyroCount = 0, accCount = 0, maxSensorCount = 10;
  bool _trackDevice = true;


  //Variable for Isolate
  ReceivePort receivePort = ReceivePort();
  SendPort sendPort;

  @override
  void initState() {
    super.initState();

    setCustomMapPin();

    loadIsolate();
  }

  void trackDevice(bool track) {
    if (track == false)
      for (StreamSubscription<dynamic> subscription in _streamSubscriptions)
        subscription.cancel();
    else {
      _streamSubscriptions[0] = gyroscopeEvents.listen((event) {
        if (gyroCount == 0) {
          gyroValues[0][0] = event.x;
          gyroValues[1][0] = event.x;
          gyroValues[0][1] = event.y;
          gyroValues[1][1] = event.y;
          gyroValues[0][2] = event.z;
          gyroValues[1][2] = event.z;
        } else {
          gyroValues[0][0] = min(gyroValues[0][0], event.x);
          gyroValues[0][1] = min(gyroValues[0][1], event.y);
          gyroValues[0][2] = min(gyroValues[0][2], event.z);

          gyroValues[1][0] = max(gyroValues[1][0], event.x);
          gyroValues[1][1] = max(gyroValues[1][1], event.y);
          gyroValues[1][2] = max(gyroValues[1][2], event.z);
        }
        gyroCount++;

        if (gyroCount >= maxSensorCount) {
          sendPort.send([
            'gyro',
            [
              gyroValues[1][0] - gyroValues[0][0],
              gyroValues[1][1] - gyroValues[0][1],
              gyroValues[1][2] - gyroValues[0][2]
            ]
          ]);

          gyroCount = 0;
        }
      });
      _streamSubscriptions[1] = userAccelerometerEvents.listen((event) {
        if (accCount == 0) {
          accValues[0][0] = event.x;
          accValues[1][0] = event.x;
          accValues[0][1] = event.y;
          accValues[1][1] = event.y;
          accValues[0][2] = event.z;
          accValues[1][2] = event.z;
        } else {
          accValues[0][0] = min(accValues[0][0], event.x);
          accValues[0][1] = min(accValues[0][1], event.y);
          accValues[0][2] = min(accValues[0][2], event.z);

          accValues[1][0] = max(accValues[1][0], event.x);
          accValues[1][1] = max(accValues[1][1], event.y);
          accValues[1][2] = max(accValues[1][2], event.z);
        }
        accCount++;

        if (accCount >= maxSensorCount) {
          sendPort.send([
            'acc',
            [
              accValues[1][0] - accValues[0][0],
              accValues[1][1] - accValues[0][1],
              accValues[1][2] - accValues[0][2]
            ]
          ]);

          accCount = 0;
        }
      });
    }
  }

  Future loadIsolate() async {
    await Isolate.spawn(isolateEntry, receivePort.sendPort);
    sendPort = await receivePort.first;

    trackDevice(true);
  }

  static isolateEntry(SendPort sendPort) async {
    ReceivePort receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);

    receivePort.listen((message) {
      // print(message.toString());
    });
  }

  //Load custom Marker from assets, set size here
  void setCustomMapPin() async {
    Uint8List markerImage = await getBytesFromAsset('assets/squaregradblue.png',
        _zoom < 10 ? 40 : 40 + (pow((_zoom - 10) * 4, 1.2)).toInt());
    markerIcon = BitmapDescriptor.fromBytes(markerImage);
    print('recalculated');
  }

  //
  void updateMarkers() {
    for (int i = 0; i < markerLocations.length; i++)
      _markers.add(Marker(
          markerId: MarkerId(i.toString()),
          position: LatLng(markerLocations[i][0], markerLocations[i][1]),
          icon: markerIcon,
          anchor: Offset(0.5, 0.5)));
  }

  void _showSnackBar(String str){
    scaffoldKey.currentState.showSnackBar(
      SnackBar(
        content: Text(str),
        duration: Duration(seconds: 1),

      )
    );
  }

  //Code to initialize the map
  GoogleMapController mapController;
  LatLng _center = LatLng(10.02, 76.35);
  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    setState(() {
      updateMarkers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: Scaffold(
          key: scaffoldKey,
          appBar: AppBar(
            backgroundColor: Colors.black,
            title: Text("Traffic App"),
            actions: <Widget>[
              Switch(
                // activeColor: Colors.green,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: Colors.grey,
                value: _trackDevice,
                onChanged: (value){
                  setState((){
                    _trackDevice = !_trackDevice;
                  });
                  _showSnackBar(_trackDevice?"Tracking turned ON":"Tracking turned OFF");
                },
              )
            ],
          ),
          body: Stack(
            children: <Widget>[
              GoogleMap(
                onMapCreated: _onMapCreated,
                markers: _markers,
                initialCameraPosition: CameraPosition(
                  target: _center,
                  zoom: _zoom,
                ),
                myLocationButtonEnabled: true,
                myLocationEnabled: true,
                zoomControlsEnabled: false,
                onCameraIdle: () {
                  setState(() {
                    mapController.getZoomLevel().then((value) {
                      _zoom = value;
                      setCustomMapPin();
                      updateMarkers();
                      sendPort.send("markers updated");
                      print(_zoom);
                    });
                  });
                },
              ),
              Column(
                children: <Widget>[
                  Expanded(child: Container()),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 48),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        MaterialButton(
                            height: 50,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(25),
                              topLeft: Radius.circular(25),
                            )),
                            color: Colors.white,
                            child: Icon(
                              Icons.directions_car,
                              size: (mapType == "vehicle") ? 36 : 24,
                              color: (mapType == "vehicle")
                                  ? Colors.blue
                                  : Colors.grey,
                            ),
                            onPressed: () {
                              _showSnackBar("Vehicle Traffic Map");
                              setState(() {
                                mapType = "vehicle";
                              });
                            }),
                        MaterialButton(
                            height: 50,
                            color: Colors.white,
                            child: Icon(
                              Icons.directions_walk,
                              size: (mapType == "pedestrian") ? 36 : 24,
                              color: (mapType == "pedestrian")
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                            onPressed: () {
                              _showSnackBar("Pedestrian Traffic Map");
                              setState(() {
                                mapType = "pedestrian";
                              });
                            }),
                        MaterialButton(
                            height: 50,
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.only(
                              bottomRight: Radius.circular(25),
                              topRight: Radius.circular(25),
                            )),
                            child: Icon(
                              Icons.traffic,
                              size: (mapType == "road") ? 36 : 24,
                              color: (mapType == "road")
                                  ? Colors.red
                                  : Colors.grey,
                            ),
                            onPressed: () {
                              _showSnackBar("Road Quality Map");
                              setState(() {
                                mapType = "road";
                              });
                            }),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ));
  }
}
