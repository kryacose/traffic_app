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
  BitmapDescriptor markerIcon;
  Set<Marker> _markers = {};
  double _zoom = 16.0;

  @override
  void initState() {
    super.initState();
    setCustomMapPin();
  }

  //Load custom Marker from assets, set size here
  void setCustomMapPin() async {
    Uint8List markerImage =
        await getBytesFromAsset('assets/circle.png', pow(_zoom,0.5).toInt()*30);
    markerIcon = BitmapDescriptor.fromBytes(markerImage);
  }

  void updateMarkers() {
    _markers.add(Marker(
        markerId: MarkerId("marker_id"), position: _center, icon: markerIcon,anchor: Offset(0.5,0.5)));
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
    return GoogleMap(
      onMapCreated: _onMapCreated,
      markers: _markers,
      initialCameraPosition: CameraPosition(
        target: _center,
        zoom: _zoom,
      ),
      myLocationButtonEnabled: true,
      myLocationEnabled: true,
      onCameraIdle: () {
        setState(() {
          mapController.getZoomLevel().then((value) {
            _zoom = value;
            setCustomMapPin();
            updateMarkers();
            print(_zoom);
          });
        });
      },
    );
  }
}
