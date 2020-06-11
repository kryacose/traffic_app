import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'package:sensors/sensors.dart';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
// import 'package:web_socket_channel/web_socket_channel.dart';
// import 'package:web_socket_channel/io.dart';
// import 'package:http/http.dart' as http;
import 'dart:ui' as ui;
import './infoPage.dart';

Settings settings = new Settings(true, false, 10);

class MapPage extends StatefulWidget {
  MapPage({Key key}) : super(key: key);

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  String mapType = "vehicle";
  BitmapDescriptor markerIcon;

  List<LatLng> markerLocations;

  List<LatLng> vehiclePoints = [
    LatLng(10.017560, 76.348831),
    LatLng(10.017660, 76.348571),
    LatLng(10.017610, 76.349001),
    LatLng(10.017610, 76.349050),
    LatLng(10.017915, 76.349197),
    LatLng(10.017935, 76.349297),
    LatLng(10.017935, 76.349347),
    LatLng(10.017955, 76.349497),
    LatLng(10.018067, 76.350797),
    LatLng(10.018067, 76.350897),
    LatLng(10.018067, 76.350997),
    LatLng(10.018067, 76.350497),
    LatLng(10.017164, 76.347274),
    LatLng(10.017164, 76.347274)
  ];

  List<LatLng> pedestrianPoints = [
    LatLng(10.017728, 76.348873),
    LatLng(10.017728, 76.348873),
    LatLng(10.017632, 76.348505),
    LatLng(10.017632, 76.348505),
    LatLng(10.017688, 76.348766),
    LatLng(10.017796, 76.349440),
    LatLng(10.017796, 76.349440),
    LatLng(10.017861, 76.349338),
    LatLng(10.017759, 76.349231),
    LatLng(10.017833, 76.349271),
    LatLng(10.017833, 76.349271),
    LatLng(10.017581, 76.349924),
    LatLng(10.017658, 76.349959),
    LatLng(10.017658, 76.349959),
    LatLng(10.017702, 76.350351),
    LatLng(10.017537, 76.349542),
    LatLng(10.017516, 76.349345),
  ];

  List<LatLng> roadQPoints = [
    LatLng(10.017803, 76.348886),
    LatLng(10.017843, 76.348936),
    LatLng(10.017803, 76.348886),
    LatLng(10.018104, 76.349712),
    LatLng(10.018086, 76.349603),
    LatLng(10.018046, 76.349489),
    LatLng(10.018046, 76.349489),
    LatLng(10.018027, 76.349582),
    LatLng(10.018044, 76.349679),
    LatLng(10.017857, 76.350377),
    LatLng(10.017857, 76.350377),
    LatLng(10.017843, 76.350514),
    LatLng(10.017787, 76.350581),
    LatLng(10.017901, 76.350189),
    LatLng(10.017901, 76.350189),
    LatLng(10.017943, 76.350455),
  ];

  List<LatLng> routePoints = [
    LatLng(10.017169, 76.347179),
    LatLng(10.017263, 76.347571),
    LatLng(10.017451, 76.348180),
    LatLng(10.017525, 76.348546),
    LatLng(10.017583, 76.348863),
    LatLng(10.017694, 76.349292),
    LatLng(10.017781, 76.349649),
    LatLng(10.017864, 76.350019),
    LatLng(10.017922, 76.350153),
    LatLng(10.017948, 76.350276),
    LatLng(10.017991, 76.350507),
    LatLng(10.018049, 76.350861),
    LatLng(10.018152, 76.351293),
    LatLng(10.018144, 76.351609),
    LatLng(10.018403, 76.351963),
    LatLng(10.018651, 76.352328),
    LatLng(10.018939, 76.352647),
    LatLng(10.018939, 76.352647),
    LatLng(10.019678, 76.353090),
    LatLng(10.019945, 76.353103),
    LatLng(10.020151, 76.353047),
    LatLng(10.020497, 76.352876),
    LatLng(10.020944, 76.352772),
    LatLng(10.020987, 76.352910),
    LatLng(10.020840, 76.353215),
    LatLng(10.020718, 76.353496),
    LatLng(10.021106, 76.353703),
  ];



  Set<Marker> _markers = {};
  double _zoom = 16.0;

  //Variables for the sensor data and shit
  List<StreamSubscription<dynamic>> _streamSubscriptions = new List(3);
  List<List<double>> gyroValues =
      List.generate(2, (_) => new List(3), growable: false);
  List<List<double>> accValues =
      List.generate(2, (_) => new List(3), growable: false);
  int gyroCount = 0, accCount = 0;

  //Variable for Isolate
  ReceivePort receivePort = ReceivePort();
  SendPort sendPort;

  @override
  void initState() {
    super.initState();
    getUname();
    setCustomMapPin('vehicle');
    markerLocations = vehiclePoints;
    loadIsolate();
  }

  @override
  void dispose(){
    super.dispose();
    for (StreamSubscription<dynamic> subscription in _streamSubscriptions) {
      subscription.cancel();
    }
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

        if (gyroCount >= settings.maxSensorCount) {
          sendPort.send([
            'gyro',
            [
              double.parse(
                  (gyroValues[1][0] - gyroValues[0][0]).toStringAsFixed(2)),
              double.parse(
                  (gyroValues[1][1] - gyroValues[0][1]).toStringAsFixed(2)),
              double.parse(
                  (gyroValues[1][2] - gyroValues[0][2]).toStringAsFixed(2))
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

        if (accCount >= settings.maxSensorCount) {
          sendPort.send([
            'acc',
            [
              double.parse(
                  (accValues[1][0] - accValues[0][0]).toStringAsFixed(2)),
              double.parse(
                  (accValues[1][1] - accValues[0][1]).toStringAsFixed(2)),
              double.parse(
                  (accValues[1][2] - accValues[0][2]).toStringAsFixed(2))
            ]
          ]);

          accCount = 0;
        }
      });

      _streamSubscriptions[2] = Geolocator()
          .getPositionStream(LocationOptions(
            accuracy: LocationAccuracy.high,
            // distanceFilter: 5
          ))
          .listen((position) {
            sendPort.send(['position', position]);
          });
    }
  }

  Future loadIsolate() async {
    await Isolate.spawn(isolateEntry, receivePort.sendPort);
    sendPort = await receivePort.first;
    // receivePort.close();

    trackDevice(true);
    sendPort.send(['name',settings.uname]);

    // receivePort.listen((message) {
    //   setState(() {
    //     markerLocations = message[mapType];
    //   });
    //  });
  }

  static isolateEntry(SendPort sendPort) async {
    ReceivePort receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);
    bool gyro = false, acc = false, pos = false;
    Packet packet = new Packet();
    // final channel = IOWebSocketChannel.connect('ws://192.168.0.1:8080');

    receivePort.listen((message) {
      // print(message.toString());

      if (message[0] == 'gyro') {
        packet.gyro = message[1];
        gyro = true;
      } else if (message[0] == 'acc') {
        packet.acc = message[1];
        acc = true;
      } else if (message[0] == 'position') {
        packet.latlng = [message[1].latitude, message[1].longitude];
        packet.speed = message[1].speed;
        packet.heading = message[1].heading;
        packet.timestamp = message[1].timestamp.toIso8601String();
        pos = true;
      } else if(message[0] == 'name'){
        packet.name = message[1];
      }

      if (gyro && acc && pos == true) {
        gyro = false;
        acc = false;
        pos = false;

        print(jsonEncode(packet));

        //Send Packet to server
        // http.post('192.168.0.1:8080 ',
        // headers: <String, String>{
        //   'Content-Type': 'application/json; charset=UTF-8',
        // },
        // body: jsonEncode(packet));

        // channel.sink.add(jsonEncode(packet));
      }
    });

    // channel.stream.listen((event) {
    //   sendPort.send(event);
    // });
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))
        .buffer
        .asUint8List();
  }

  //Load custom Marker from assets, set size here
  void setCustomMapPin(String name) async {
    Uint8List markerImage = await getBytesFromAsset('assets/' + name + '.png',
        _zoom < 10 ? 40 : 40 + (pow((_zoom - 10) * 4, 1.2)).toInt());
    markerIcon = BitmapDescriptor.fromBytes(markerImage);
    // print('recalculated');
  }

  void updateMarkers() {
    _markers = {};
    for (int i = 0; i < markerLocations.length; i++)
      _markers.add(Marker(
          markerId: MarkerId(i.toString()),
          position: markerLocations[i],
          icon: markerIcon,
          anchor: Offset(0.5, 0.5)));
  }

  void _showSnackBar(String str) {
    scaffoldKey.currentState.showSnackBar(SnackBar(
      content: Text(str),
      duration: Duration(seconds: 1),
    ));
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
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text("Traffic App"),
        actions: <Widget>[
          IconButton(
              icon: Icon(
                Icons.info_outline,
                color: Colors.white,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => InfoPage()),
                );
              })
        ],
      ),
      drawer: SettingsPage(trackDevice),
      body: Stack(
        children: <Widget>[
          GoogleMap(
            onMapCreated: _onMapCreated,
            markers: _markers,
            polylines: [
              Polyline(
                  points: routePoints,
                  polylineId: PolylineId('route'),
                  color: Colors.green,
                  width: 5,
                  visible: settings.showRoute),
            ].toSet(),
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
                  setCustomMapPin(mapType);
                  updateMarkers();
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
                          size: (mapType == "vehicle") ? 32 : 24,
                          color: (mapType == "vehicle")
                              ? Colors.blue
                              : Colors.grey,
                        ),
                        onPressed: () {
                          _showSnackBar("Vehicle Traffic Map");
                          setState(() {
                            mapType = "vehicle";
                            markerLocations = vehiclePoints;
                            setCustomMapPin(mapType);
                            updateMarkers();
                          });
                        }),
                    MaterialButton(
                        height: 50,
                        color: Colors.white,
                        child: Icon(
                          Icons.directions_walk,
                          size: (mapType == "pedestrian") ? 32 : 24,
                          color: (mapType == "pedestrian")
                              ? Colors.green
                              : Colors.grey,
                        ),
                        onPressed: () {
                          _showSnackBar("Pedestrian Traffic Map");
                          setState(() {
                            mapType = "pedestrian";
                            markerLocations = pedestrianPoints;
                            setCustomMapPin(mapType);
                            updateMarkers();
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
                          size: (mapType == "road") ? 32 : 24,
                          color: (mapType == "road") ? Colors.red : Colors.grey,
                        ),
                        onPressed: () {
                          _showSnackBar("Road Quality Map");
                          setState(() {
                            mapType = "road";
                            markerLocations = roadQPoints;
                            setCustomMapPin(mapType);
                            updateMarkers();
                          });
                        }),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

void getUname() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  // print("\n\nUSERNAME: " + settings.uname+"\n\n");
  String str = prefs.getString('username');
  settings.uname = str;
  print("\n\nUSERNAME: $str\n\n");
  // SendPort.send(['uname', settings.uname]);
}

class Settings {
  String uname;
  bool trackDevice, showRoute;
  int maxSensorCount;

  // Settings(this.trackDevice, this.maxSensorCount);
  Settings(this.trackDevice, this.showRoute, this.maxSensorCount);

  void setUname(String str){
    this.uname = str;
  }

  void switchTrack() {
    trackDevice = !trackDevice;
  }

  void switchRoute() {
    showRoute = !showRoute;
  }
}

class Packet {
  String name;
  List<double> gyro = new List(3);
  List<double> acc = new List(3);
  List<double> latlng = new List(2);
  double speed, heading;
  String timestamp;

  

  Map<String, dynamic> toJson() => {
        'name': name,
        'gyro': gyro,
        'acc': acc,
        'latlng': latlng,
        'speed' : speed,
        'heading' : heading,
        'timestamp' : timestamp,
      };
}

class SettingsPage extends StatefulWidget {
  final Function trackDevice;
  SettingsPage(this.trackDevice);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  double sliderVal = 2;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text("Settings"),
      ),
      backgroundColor: Color.fromARGB(255, 20, 20, 20),
      body: Padding(
        padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 24),
        child: Column(
          children: <Widget>[
            Row(children: [
              Text(
                "Track user data",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              Expanded(child: Container()),
              Switch(
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: Colors.grey,
                value: settings.trackDevice,
                onChanged: (value) {
                  setState(() {
                    settings.switchTrack();
                    widget.trackDevice(settings.trackDevice);
                  });
                },
              )
            ]),
            SizedBox(
              height: 18.0,
            ),
            Row(children: [
              Text(
                "Show route",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              Expanded(child: Container()),
              Switch(
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: Colors.grey,
                value: settings.showRoute,
                onChanged: (value) {
                  setState(() {
                    settings.switchRoute();
                  });
                },
              )
            ]),
            SizedBox(
              height: 18.0,
            ),
            Row(
              children: <Widget>[
                Text(
                  "Accuracy",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                Expanded(child: Container()),
                Slider(
                  max: 2,
                  min: 0,
                  divisions: 2,
                  value: sliderVal,
                  onChanged: (val) {
                    setState(() {
                      sliderVal = val;
                      settings.maxSensorCount = 10 + (2 - val.toInt()) * 12;
                    });
                  },
                  label: (sliderVal == 0)
                      ? "Low"
                      : (sliderVal == 1) ? "Medium" : "High",
                ),
              ],
            ),
            SizedBox(
              height: 50,
            ),
            MaterialButton(
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                prefs.setBool('isLoggedIn', false);
                dispose();
                Navigator.pop(context);
                Navigator.pop(context);
              },
              shape: StadiumBorder(),
              color: Colors.blue,
              child: Padding(
                padding: const EdgeInsets.only(
                    top: 8, bottom: 10, left: 24, right: 24),
                child: Text(
                  "Logout",
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
