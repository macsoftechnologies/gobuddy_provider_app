import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gobuddy/data/preferences.dart';
import 'package:gobuddy/pages/dashboard/dashboardTab_screen.dart';
import 'package:gobuddy/pages/tutorials/my_tutorials.dart';
//mr
import '../account/account_screen.dart';
import '../orders/my_orders.dart';
// import 'package:providerapp_gobuddy/screens/accountpage.dart';
//
// import 'myOrders/my_orders.dart';
// import 'package:providerapp_gobuddy/screens/myorderscreen.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int currentIndex = 0;
  dynamic profileDetails = {};
  Color green = Color(0xFF4CAF50);
  dynamic userData = {};



  // JSON Data Structure for Dynamic Screen
  

  @override
  void initState() {
    super.initState();

    var userDataValue = Preferences.getUserDetails();
    if (userDataValue != null) {
      userData = json.decode(userDataValue);
    }

    
    //sk
    

    // Fallback in case currentMonth is not found
    
  }

    @override
  void dispose() {
  
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // If on another tab, go back to Home tab first
        if (currentIndex != 0) {
          setState(() {
            currentIndex = 0;
          });
          return;
        }

        // Show Exit confirmation dialog
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              "Exit App",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text("Are you sure you want to exit Go Buddy?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontSize: 15)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text("Exit", style: TextStyle(fontSize: 15)),
              ),
            ],
          ),
        );

        if (shouldExit == true) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.live_tv_outlined), label: 'Tutorials'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
        ],
        currentIndex: currentIndex,
        // ✅ Green color for selected item
        selectedItemColor: green,

        // ✅ Grey color for unselected items
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
      ),
      body: getBody(currentIndex),
      ),
    );
  }

  Widget getBody(int index) {
    switch (index) {
      case 0:
        return DashboardTabScreen();
      case 1:
        return MyOrdersScreen(
          onBackToHome: () {
            setState(() {
              currentIndex = 0;
            });
          },
        ); //MyOrdersScreen
      case 2:
        return MyTutorialsScreen();  
      case 3:
        return AccountPage(); //AccountPage
      default:
        return DashboardTabScreen();
    }
  }

  
}
