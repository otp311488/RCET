import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rcet_shuttle_bus/login_screen.dart';


class Bus {
  final String name;
  final Icon icon;

  Bus(this.name, this.icon);
}

class DriverLocationMarker extends StatefulWidget {
  const DriverLocationMarker({Key? key}) : super(key: key);

  @override
  _DriverLocationMarkerState createState() => _DriverLocationMarkerState();
}

class _DriverLocationMarkerState extends State<DriverLocationMarker> {
  LatLng? currentPosition;
  String? selectedBus;
  final List<Bus> buses = [
    Bus("Pindi Bypass", Icon(Icons.directions_bus)),
    Bus("Sheikhupura Mor", Icon(Icons.directions_bus)),
    Bus("Chanda Qila", Icon(Icons.directions_bus)),
    Bus("KSK", Icon(Icons.directions_bus)),
  ];
  final LatLng finalDestination = LatLng(32.3610, 74.2079); // UET RCET location
  Timer? locationUpdateTimer;
  bool hasReachedDestination = false;
  BitmapDescriptor? customIcon;

  String status = "On The Way";
  String nextStop = "";
  String message = "";
  String title = "Announcement";
   bool isSharing = false;

  TextEditingController messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    _loadCustomMarker();
    initializeService();
    _getSharingStatusFromFirebase();
messageController.clear();

  }

  @override
  void dispose() {
    locationUpdateTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCustomMarker() async {
    final ByteData byteData = await rootBundle.load('assets/images/location.png');
    final Uint8List imageData = byteData.buffer.asUint8List();
    final Codec codec = await instantiateImageCodec(imageData, targetWidth: 80, targetHeight: 80);
    final FrameInfo frameInfo = await codec.getNextFrame();
    final ByteData? resizedImage = await frameInfo.image.toByteData(format: ImageByteFormat.png);
    if (resizedImage != null) {
      customIcon = BitmapDescriptor.fromBytes(resizedImage.buffer.asUint8List());
      setState(() {});
    }
  }

  Future<void> _checkLocationPermission() async {
    PermissionStatus status = await Permission.location.request();
    if (status.isGranted) {
      _getCurrentLocation();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Row(
          children: [
            Icon(Icons.directions_bus, color: Colors.white), // Red bus icon
            SizedBox(width: 8),
            Text("Location permission is required.",style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),),

          ],
        ),
          backgroundColor: Colors.red, // Red background for SnackBar
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // Rounded corners
          ),
          behavior: SnackBarBehavior.floating, // Floating effect for SnackBar
          margin: EdgeInsets.all(25), // Margin around SnackBar
        ),
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        currentPosition = LatLng(position.latitude, position.longitude);
      });
      _updateStatusAndNextStop();
      _updateFirebaseLocation();
    } catch (e) {
      print("Error fetching location: $e");
    }
  }
 void _updateStatusAndNextStop() async {
  if (currentPosition == null) return;

  double distanceToDestination = Geolocator.distanceBetween(
    currentPosition!.latitude,
    currentPosition!.longitude,
    finalDestination.latitude,
    finalDestination.longitude,
  );

  if (distanceToDestination < 20) { // Threshold for "reaching" destination
    status = "Arrived";
    hasReachedDestination = true;

    // Immediately update Firebase when the bus arrives
    if (selectedBus != null) {
      await FirebaseFirestore.instance
          .collection('bus_locations')
          .doc(selectedBus)
          .set({
        'status': "Arrived",
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print("Status updated to 'Arrived' in Firebase for $selectedBus.");
    }
  } else {
    status = currentPosition!.latitude < finalDestination.latitude
        ? "Arriving"
        : "Departing";
    hasReachedDestination = false;
  }

  setState(() {
    nextStop = "Unknown";
  });
}


  Future<void> _updateFirebaseLocation({bool updateMessage = false}) async {
    if (currentPosition == null || selectedBus == null) {
      print("Cannot update Firebase: Missing current position or selected bus.");
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('bus_locations')
          .doc(selectedBus)
          .set({
        'busId': selectedBus,
        'location': GeoPoint(currentPosition!.latitude, currentPosition!.longitude),
        'status': status,
        'nextStop': nextStop,
        if (updateMessage) 'message': message,
        if (updateMessage) 'title': title,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print("Firebase location updated for $selectedBus.");
      if (updateMessage) {
        print("Message broadcasted: $message");
      }
    } catch (e) {
      print("Error updating Firebase: $e");
    }
  }
  void startSharingLocation() async {
  if (selectedBus == null) {
    _showSnackBar(message: "Please select a bus first.", color: Colors.red, icon: Icons.info);
    return;
  }

  try {
    // Check if location sharing is already active
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('bus_locations')
        .doc(selectedBus)
        .get();

    if (snapshot.exists && snapshot['isSharing'] == true) {
      _showSnackBar(message: "Location sharing is already active.", color: Colors.orange, icon: Icons.location_on);
      return;
    }

    // Start location sharing if not active
    locationUpdateTimer?.cancel();
    locationUpdateTimer = Timer.periodic(Duration(seconds: 2), (timer) async {
      print("Fetching location...");
      await _getCurrentLocation();
      _updateStatusAndNextStop();
      await _updateFirebaseLocation(updateMessage: true);
    });

    await FirebaseFirestore.instance
        .collection('bus_locations')
        .doc(selectedBus)
        .set({'isSharing': true}, SetOptions(merge: true));

    _showSnackBar(message: "Location sharing started.", color: Colors.green, icon: Icons.location_on);

  } catch (e) {
    print("Error during location sharing: $e");
  }
}

  void stopLocationSharing() async {
    // Cancel the periodic timer
    locationUpdateTimer?.cancel();
    locationUpdateTimer = null;

    if (selectedBus != null) {
      try {
        // Update Firebase document to mark location sharing as stopped
        await FirebaseFirestore.instance
            .collection('bus_locations')
            .doc(selectedBus)
            .set({
          'isSharing': false, // Set sharing status to false
        }, SetOptions(merge: true)); // Merge to avoid overwriting other data

      
      } catch (e) {
        print("Error updating location sharing status: $e");
      }
    }

    // Remove the marker locally
    setState(() {
      currentPosition = null; // Reset the local marker
    });

  }

  void stopBackgroundService() {
    FlutterBackgroundService().invoke('stopService');

  }
  void startBackgroundService() {
    if (selectedBus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select a bus first.")),
      );
      return;
    }

    FlutterBackgroundService().invoke('setData', {'selectedBus': selectedBus});
    FlutterBackgroundService().startService();
  }
  Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    // Create the notification channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'my_foreground', // Channel ID
      'Bus Service Notifications', // Channel name
      description: 'This channel is used for bus tracking notifications.',
      importance: Importance.high, // Set the importance level
    );

    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        isForegroundMode: true,
        notificationChannelId: channel.id, // Use the created channel ID
        initialNotificationTitle: 'Bus Service',
        initialNotificationContent: 'Tracking location...',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        onForeground: onStart,
      ),
    );
    print("Background service initialized with notification channel.");
  }
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    service.on('setData').listen((event) {
      final bus = event?['selectedBus'];
      print('Bus $bus is being tracked');
    });

    Timer.periodic(Duration(seconds: 2), (timer) {
      service.invoke('update', {'message': 'Location updated at ${DateTime.now()}'});
    });
  }
  void _showSnackBar({
    required String message,
    required Color color,
    required IconData icon,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              icon,
              color: Colors.white,
            ),  // Icon with white color
            SizedBox(width: 8), // Space between icon and text
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: Colors.white), // White text color
                overflow: TextOverflow.ellipsis,  // Handle overflow with ellipsis
                maxLines: 2,  // Allow a maximum of 2 lines for text
              ),
            ),
          ],
        ),
        backgroundColor: color,  // Custom background color
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),  // Rounded corners with 20 radius
        ),
        behavior: SnackBarBehavior.floating,   // Floating behavior
        margin: EdgeInsets.all(10),            // Margin around SnackBar
      ),
    );
  }
Future<void> _getSharingStatusFromFirebase() async {
    final snapshot = await FirebaseFirestore.instance.collection('sharings').doc('sharing_status').get();
    if (snapshot.exists) {
      setState(() {
        isSharing = snapshot['isSharing'] ?? false; // Get the current sharing status
      });
    }
  }

  // Handle the button click to start/stop sharing
 Color _scaffoldBgColor = Colors.white; // Default background color

void _handleShareLocationButtonClick() async {
  if (selectedBus != null) {
    if (isSharing) {
      // Stop sharing
      stopLocationSharing();
      stopBackgroundService();
      setState(() {
        isSharing = false;
      });
      await FirebaseFirestore.instance.collection('sharings').doc('sharing_status').update({
        'isSharing': false, // Update sharing status in Firebase
      });
    } else {
      // Start sharing
      startSharingLocation();
      startBackgroundService();
      setState(() {
        isSharing = true;
        _scaffoldBgColor = Colors.red; // Set background to red
      });

      // Revert back to default after 1 second
      Future.delayed(Duration(seconds: 1), () {
        setState(() {
          _scaffoldBgColor = Colors.white; // Reset to default color
        });
      });

      await FirebaseFirestore.instance.collection('sharings').doc('sharing_status').update({
        'isSharing': true, // Update sharing status in Firebase
      });
    }
  } else {
    // Show a message if no bus is selected
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Please select a bus to share your location.',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red, // Set red background for warning
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: EdgeInsets.all(25),
      ),
    );
  }
}
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      backgroundColor: Colors.white,
      leading: Builder(
        builder: (context) {
          return IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          );
        },
      ),
      actions: [
        Row(
          children: [
            if (selectedBus != null) // Only show if a bus is selected
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Text(
                  selectedBus!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: 16.0,
                  ),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.directions_bus, color: Colors.black),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) {
                    return Container(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          const Text(
                            'Select a Route',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Expanded(
                            child: ListView.builder(
                              itemCount: buses.length,
                              itemBuilder: (context, i) {
                                bool isDisabled = selectedBus != null && selectedBus != buses[i].name;

                                return ListTile(
                                  leading: buses[i].icon,
                                  title: Text(
                                    buses[i].name,
                                    style: TextStyle(
                                      color: isDisabled ? Colors.grey : Colors.black, // Grey out disabled buses
                                      fontWeight: selectedBus == buses[i].name ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                  enabled: !isDisabled, // Disable tap on other buses
                                  onTap: isDisabled
                                      ? null
                                      : () {
                                          setState(() {
                                            selectedBus = buses[i].name;
                                          });
                                          Navigator.pop(context);
                                        },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ],
    ),
drawer: Drawer(
  child: ListView(
    padding: EdgeInsets.zero,
    children: <Widget>[
      DrawerHeader(
        decoration: const BoxDecoration(color: Color(0xFF1A237E)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Welcome!',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Driver Dashboard',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
          ],
        ),
      ),
      ListTile(
  leading: const Icon(Icons.refresh, color: Colors.blue),
  title: const Text('Select Another Bus'),
  onTap: () {
    if (isSharing) {
      _handleShareLocationButtonClick(); // Stop sharing if active
    }
    setState(() {
      selectedBus = null; // Reset the selected bus
    });
    Navigator.pop(context); // Close the drawer
  },
),

      ListTile(
        leading: const Icon(Icons.logout),
        title: const Text('Signout'),
        onTap: () async {
          try {
            await FirebaseAuth.instance.signOut();
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => LoginScreen(),
              ),
              (route) => false, // Remove all previous routes
            );
          } catch (e) {
            print('Error signing out: $e');
          }
        },
      ),
    ],
  ),
),

    body: Stack(
      children: [
        // Google Map
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: 230, // Adjust to leave space for buttons at the bottom
          child: GoogleMap(
            markers: {
              if (currentPosition != null)
                Marker(
                  markerId: MarkerId(selectedBus ?? "Unknown"),
                  position: currentPosition!,
                  icon: customIcon ?? BitmapDescriptor.defaultMarker,
                ),
              Marker(
                markerId: MarkerId('destination'),
                position: LatLng(32.3610, 74.2079), // Example destination
                infoWindow: InfoWindow(title: "UET RCET"),
              ),
            },
            initialCameraPosition: CameraPosition(
              target: currentPosition ?? LatLng(32.3610, 74.2079), // Default to destination if no current location
              zoom: 14,
            ),
          ),
        ),
        // Bottom Container with Buttons
        Align(
          alignment: Alignment.bottomCenter,
          child: ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30.0),
              topRight: Radius.circular(30.0),
            ),
            child: Container(
              color: Colors.white.withOpacity(0.8),
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Share Location Button (Start/Stop)
                  ElevatedButton(
                    onPressed: _handleShareLocationButtonClick,
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(150, 40),
                      backgroundColor: isSharing ? Colors.red : Color(0xFF1A237E), // Red when sharing, default otherwise
                    ),
                    child: Text(
                      isSharing ? "Stop Sharing" : "Start Sharing",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(height: 10),

                  // Share Message Button
                  ElevatedButton(
                   onPressed: () {
  if (selectedBus == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Please select a bus first."),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
  } else if (messageController.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Please enter a message before sending."),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
  } else {
    setState(() {
      message = messageController.text;
    });

    // Clear the message field after sending
    messageController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.message_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text(
              "Message Broadcast: $message",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(25),
      ),
    );
  }
},

                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(150, 40),
                      backgroundColor: Color(0xFF1A237E),
                    ),
                    child: Text(
                      "Share Message",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  SizedBox(height: 10),

                  // Message TextField
                  TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      labelText: 'Enter Message',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
}