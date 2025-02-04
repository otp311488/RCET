  import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

  import 'package:google_maps_flutter/google_maps_flutter.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'dart:convert';
  import 'package:http/http.dart' as http;
import 'package:rcet_shuttle_bus/login_screen.dart';
  

  class StudentDashboard extends StatefulWidget {
    const StudentDashboard({Key? key}) : super(key: key);

    @override
    _StudentDashboardState createState() => _StudentDashboardState();
  }

  class _StudentDashboardState extends State<StudentDashboard> {
    final Map<String, Marker> _busMarkers = {};
    final Map<String, Marker> _stopMarkers = {};
    final Set<Polyline> _polylines = {};
    bool _isLoading = true;
    bool _isRouteAvailable = true;

    final LatLng initialMapCenter = const LatLng(32.1617, 74.1883); // Default map center
    final LatLng uetRcetLocation = const LatLng(32.3610, 74.2079);
    List<String> busList = ["Pindi Bypass", "Sheikhupura Mor", "Chanda Qila", "KSK"];
    String? selectedBus; // Changed to single string instead of list
    List<Map<String, dynamic>> routeABusStops = [];
    String busETA = ""; // To store ETA message
    String busMessage = " No message yet"; // To store status or message for the selected bus
    String statusbus = "";


    @override
    void initState() {
      super.initState();
      fetchBusLocations();
    }

    // Method to update route based on selected bus
    void updateRouteBasedOnBus(String busNumber) {
      switch (busNumber) {
        case "Pindi Bypass":
          routeABusStops = [
            {"name": "Pindi Bypass", "location": LatLng(32.204598, 74.175831), "time": "7:56"},
            {"name": "DC Colony", "location": LatLng(32.2341588, 74.1669396
            ), "time": "8:00"},
            {"name": "Rahwali", "location": LatLng(32.247349, 74.163242), "time": "8:05"},
            {"name": "Ghakhar", "location": LatLng(32.300642, 74.148702), "time": "8:13"},
            {"name": "Ojla Pull", "location": LatLng(32.343580, 74.137254), "time": "8:17"},
            {"name": "Kot Inayat Khan", "location": LatLng(32.348751, 74.163647), "time": "8:22"},
          ];
          break;
        case "Sheikhupura Mor":
          routeABusStops = [
            {"name": "Sheikhupura Mor", "location": LatLng(32.147764, 74.191447), "time": "7:40"},
            {"name": "Sheranwala Bagh", "location": LatLng(32.155627, 74.190230), "time": "7:42"},
            {"name": "Sialkoti Gate", "location": LatLng(32.158364, 74.189411), "time": "7:43"},
            {"name": "Gondlanwala Adda", "location": LatLng(32.148600, 74.191227), "time": "7:45"},
            {"name": "Larri Adda", "location": LatLng(32.172418, 74.185506), "time": "7:48"},
            {"name": "Sharifpura", "location": LatLng(32.151198, 74.190636), "time": "7:52"},
            {"name": "Shaheenabad", "location": LatLng(32.188198, 74.180812), "time": "7:54"},
            {"name": "Pindi Bypass", "location": LatLng(32.204598, 74.175831), "time": "7:56"},
            {"name": "DC Colony", "location": LatLng(32.2341588, 74.1669396
            ), "time": "8:00"},
            {"name": "Rahwali", "location": LatLng(32.247349, 74.163242), "time": "8:05"},
            {"name": "Ghakhar", "location": LatLng(32.300642, 74.148702), "time": "8:13"},
            {"name": "Ojla Pull", "location": LatLng(32.343580, 74.137254), "time": "8:17"},
            {"name": "Kot Inayat Khan", "location": LatLng(32.348751, 74.163647), "time": "8:22"},
          ];
          break;
        case "Chanda Qila":
          routeABusStops = [
            {"name": "Chanda Qila", "location": LatLng(32.093955, 74.200944), "time": "6:45"},
            {"name": "Mall of Gujranwala", "location": LatLng(32.109582, 74.197754), "time": "7:35"},
            {"name": "NADRA", "location": LatLng(32.137150, 74.193246), "time": "7:37"},
            {"name": "Sheikhupura Mor", "location": LatLng(32.147764, 74.191447), "time": "7:40"},
            {"name": "Sheranwala Bagh", "location": LatLng(32.155627, 74.190230), "time": "7:42"},
            {"name": "Sialkoti Gate", "location": LatLng(32.158364, 74.189411), "time": "7:43"},
            {"name": "Gondlanwala Adda", "location": LatLng(32.148600, 74.191227), "time": "7:45"},
            {"name": "Larri Adda", "location": LatLng(32.172418, 74.185506), "time": "7:48"},
            {"name": "Sharifpura", "location": LatLng(32.151198, 74.190636), "time": "7:52"},
            {"name": "Shaheenabad", "location": LatLng(32.188198, 74.180812), "time": "7:54"},
            {"name": "Pindi Bypass", "location": LatLng(32.204598, 74.175831), "time": "7:56"},
            {"name": "DC Colony", "location": LatLng(32.2341588, 74.1669396), "time": "8:00"},
            {"name": "Rahwali", "location": LatLng(32.247349, 74.163242), "time": "8:05"},
            {"name": "Ghakhar", "location": LatLng(32.300642, 74.148702), "time": "8:13"},
            {"name": "Ojla Pull", "location": LatLng(32.343580, 74.137254), "time": "8:17"},
            {"name": "Kot Inayat Khan", "location": LatLng(32.348751, 74.163647), "time": "8:22"},
          ];
          break;
        case "ksk":
          routeABusStops = [
            {"name": " Uet ksk", "location": LatLng(31.691408, 74.248625), "time": "6:45"},
            {"name": "Chanda Qila", "location": LatLng(32.093955, 74.200944), "time": "6:45"},

          ];
          break;
      }
      addBusStopMarkers();
      fetchBusLocations();
    }



    void addBusStopMarkers() {
      setState(() {
        _stopMarkers.clear();
        for (var stop in routeABusStops) {
          final marker = Marker(
            markerId: MarkerId(stop['name']),
            position: stop['location'],
            infoWindow: InfoWindow(
              title: stop['name'],
              snippet: "Time: ${stop['time']}",
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          );
          _stopMarkers[stop['name']] = marker;
        }
      });
    }
    void fetchBusLocations() async {
      setState(() => _isLoading = true);

      final currentTime = DateTime.now();
      final threeHoursAgo = currentTime.subtract(const Duration(hours: 3));

      FirebaseFirestore.instance
          .collection('bus_locations')
          .where('timestamp', isGreaterThanOrEqualTo: threeHoursAgo)
          .snapshots()
          .listen((snapshot) {
        setState(() {
          _busMarkers.clear();
          _polylines.clear();


          _busMarkers['UETRCET'] = Marker(
            markerId: MarkerId('UETRCET'),
            position: uetRcetLocation,
            infoWindow: InfoWindow(
              title: 'UETRCET',
              snippet: 'University of Engineering and Technology',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          );

          if (snapshot.docs.isEmpty || selectedBus == null) {
            _isRouteAvailable = false;
          }
          else {
            _isRouteAvailable = true;

            busETA = "";
            busMessage = "";
            statusbus = "";

            for (var doc in snapshot.docs) {
              final data = doc.data();

              // Check if the bus matches the selected bus and isSharing is true
              if (data['busId'] == selectedBus && (data['isSharing'] ?? false)) {
                final LatLng driverPosition = LatLng(
                  data['location'].latitude,
                  data['location'].longitude,
                );

                // Add bus marker
                final marker = Marker(
                  markerId: MarkerId(data['busId']),
                  position: driverPosition,
                  infoWindow: InfoWindow(
                    title: data['busId'],
                    snippet: "Status: ${data['status'] ?? 'Unknown'}",
                  ),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                );
                _busMarkers[data['busId']] = marker;

                // Update ETA, message, and status based on the selected bus
                busETA = data['eta'] ?? 'Not Available';
                busMessage = data['message'] ?? 'No message available';
                statusbus = data['status'] ?? 'No message available';

                // Fetch OSRM route and draw polyline
                fetchOsrmRoute(driverPosition, data['status'] ?? 'Unknown');

                // Calculate ETA based on distance and current position
                calculateETA(driverPosition, data['status'] ?? 'Unknown');

              }
            }
          }
          _isLoading = false;
        });
      });
    }


Future<void> calculateETA(LatLng driverPosition, String status) async {
  LatLng finalDestination = getFinalDestination(status);

  final String url =
      'http://router.project-osrm.org/route/v1/driving/${driverPosition.longitude},${driverPosition.latitude};${finalDestination.longitude},${finalDestination.latitude}?overview=false';

  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final route = data['routes'][0];
      final durationSeconds = route['duration']; // Duration in seconds
      final etaMinutes = (durationSeconds / 60).toStringAsFixed(0);

      busETA = "$etaMinutes minutes"; // Use OSRM-calculated duration
    }
  } catch (e) {
    print("Error calculating ETA: $e");
  }
}

LatLng getFinalDestination(String status) {
  if (status == "Arriving") return uetRcetLocation;

  switch (selectedBus) {
    case "Pindi Bypass":
      return LatLng(32.204598, 74.175831);
    case "Sheikhupura Mor":
      return LatLng(32.147764, 74.191447);
    case "Chanda Qila":
      return LatLng(32.093955, 74.200944);
    case "KSK":
      return LatLng(31.691408, 74.248625);
    default:
      return uetRcetLocation;
  }
}

void fetchOsrmRoute(LatLng driverPosition, String status) async {
  LatLng finalDestination = getFinalDestination(status);

  final String url =
      'http://router.project-osrm.org/route/v1/driving/${driverPosition.longitude},${driverPosition.latitude};${finalDestination.longitude},${finalDestination.latitude}?overview=full&geometries=polyline';

  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final route = data['routes'][0];
      final encodedPolyline = route['geometry'];
      final List<LatLng> polylinePoints = decodePolyline(encodedPolyline);

      setState(() {
        _polylines.clear(); // Clear previous routes
        _polylines.add(Polyline(
          polylineId: const PolylineId("bus_route"),
          points: polylinePoints,
          color: Colors.blue,
          width: 5,
        ));
      });
    }
  } catch (e) {
    print("Error fetching OSRM route: $e");
  }
}


List<LatLng> decodePolyline(String encoded) {
  List<LatLng> points = [];
  int index = 0, len = encoded.length;
  int lat = 0, lng = 0;

  while (index < len) {
    int shift = 0, result = 0;
    int byte;
    do {
      byte = encoded.codeUnitAt(index++) - 63;
      result |= (byte & 0x1F) << shift;
      shift += 5;
    } while (byte >= 0x20);
    int deltaLat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
    lat += deltaLat;

    shift = 0;
    result = 0;
    do {
      byte = encoded.codeUnitAt(index++) - 63;
      result |= (byte & 0x1F) << shift;
      shift += 5;
    } while (byte >= 0x20);
    int deltaLng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
    lng += deltaLng;

    points.add(LatLng(lat / 1E5, lng / 1E5));
  }

  return points;
}

    void _showBottomSheet() {
      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  height: 5.0,
                  width: 40.0,
                
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                ),
                const Text(
                  'Select a Route',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: busList.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: const Icon(Icons.directions_bus, color: Colors.black),
                        title: Text(busList[index],style: TextStyle(),),
                        onTap: () {
                          setState(() {
                            selectedBus = busList[index];
                            updateRouteBasedOnBus(selectedBus!);
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
    }

    @override
    Widget build(BuildContext context) {
      return WillPopScope(
          onWillPop: () async {
            return false;
          },
      child:  Scaffold(
        appBar: AppBar(
          // Remove the app bar title
          title: null,
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  if (selectedBus != null) // Show selected bus name
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Text(
                        selectedBus!,
                        style: const TextStyle(fontSize:16),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.directions_bus),
                    onPressed: _showBottomSheet,
                  ),
                ],
              ),
            ),
          ],
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
          ),
        ),

        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(color: Color(0xFF1A237E)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Welcome!',
                      style: TextStyle(color: Colors.white, fontSize: 24),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Student Dashboard',
                      style: TextStyle(color: Colors.white70, fontSize: 18),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Signout'),
                onTap: () async {
                  try {
                    // Sign out the user from Firebase Authentication
                    await FirebaseAuth.instance.signOut();

                    // Navigate to the WelcomeScreen and clear the navigation stack
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>  LoginScreen(),
                      ),
                          (route) => false, // Remove all previous routes
                    );
                  } catch (e) {
                    // Handle errors, if any
                    print('Error signing out: $e');
                  }
                },
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              flex: 8,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ClipRRect(
                borderRadius: BorderRadius.circular(16.0),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: initialMapCenter,
                    zoom: 12,
                  ),
                  markers: selectedBus == null
                      ? {} // Don't show markers if no bus is selected
                      : {..._busMarkers.values, ..._stopMarkers.values},
                  polylines: selectedBus == null ? {} : _polylines,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  elevation: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: SingleChildScrollView(
                      child: IntrinsicHeight(
                        child: Center(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: Center(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Bus : $selectedBus',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 22,
                                        ),
                                      ),
                                      Text(
                                        'ETA: $busETA',
                                        style: const TextStyle(
                                            color: Colors.green, fontSize: 18),
                                      ),
                                       Text(
                                        'Status: $statusbus',
                                        style: const TextStyle(
                                            color: Colors.red, fontSize: 16),
                                      ),
                                      Text(
                                        'Message: $busMessage',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                     
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      );
    }
  }