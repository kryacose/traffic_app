import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:geolocator/geolocator.dart';



class MapPage extends StatefulWidget {
  MapPage({Key key}) : super(key: key);

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {

  // void _getCurrentLocation() {
  //   final Geolocator geolocator = Geolocator()..forceAndroidLocationManager;

  //   geolocator
  //       .getCurrentPosition(desiredAccuracy: LocationAccuracy.best)
  //       .then((Position position) {
  //     setState(() {
  //       print(position);
  //       _center =  LatLng(position.latitude, position.longitude);

  //     });
  //   }).catchError((e) {
  //     print(e);
  //   });
  // }

  GoogleMapController mapController;
  LatLng _center =  LatLng(10.02 , 76.35);
  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;

  }


  

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      onMapCreated: _onMapCreated,
      initialCameraPosition: CameraPosition(
        target: _center,
        zoom: 16.0,
      ),
      myLocationButtonEnabled: true,
      myLocationEnabled: true,
    );
  }
}

