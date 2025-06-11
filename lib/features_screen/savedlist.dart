import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SavedListScreen extends StatefulWidget {
  const SavedListScreen({super.key});

  @override
  State<SavedListScreen> createState() => _SavedListScreenState();
}

class _SavedListScreenState extends State<SavedListScreen> {
  Future<List<Map<String, dynamic>>> getUserSavedTrips(String userId) async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('savedTrips')
            .orderBy('timestamp', descending: true)
            .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: Text("Saved Trips")),
        body: Center(child: Text("لم يتم تسجيل الدخول")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 70,
        centerTitle: true,
        title: const Text(
          'SavedList',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF2F1532),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              icon: const Icon(Icons.close, size: 28, color: Color(0xFFACA3CF)),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: getUserSavedTrips(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            final trips = snapshot.data!;
            return ListView.builder(
              itemCount: trips.length,
              itemBuilder: (context, index) {
                final trip = trips[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: Icon(Icons.directions),
                    title: Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              "From : ",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF8063cb),
                              ),
                            ),
                            SizedBox(width: 5),
                            Text(
                              " ${trip['from']} ",
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              "To : ",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF8063cb),
                              ),
                            ),
                            SizedBox(width: 5),
                            Text("${trip['to']}",style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),),
                          ],
                        ),
                      ],
                    ),
                    subtitle: Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              "TransportMode : ",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF8063cb),
                              ),
                            ),
                            Text("${trip['transportMode']}",style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              "Distance : ",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF8063cb),
                              ),
                            ),
                            Text("${trip['distanceKm']} Km",style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),),
                          ],
                        ),
                        Text("${trip['feedbackMessage']}",style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),),
                      ],
                    ),
                  ),
                );
              },
            );
          } else {
            return Center(child: Text("No Saved Trips",style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),));
          }
        },
      ),
    );
  }
}
