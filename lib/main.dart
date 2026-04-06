import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/watchlist_provider.dart';
import 'providers/notes_provider.dart';
import 'screens/watchlist_screen.dart';
import 'screens/notes_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiProvider is used to avoid nested providers and keep code clean
    // Provider is very useful in this app as it requires data to be shared across
    // multiple screens, it saves number of API calls (VERY critical)
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WatchlistProvider()),
        ChangeNotifierProvider(create: (_) => NotesProvider()),
      ],
      child: MaterialApp(
        title: 'Stock Research',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const MainScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: const TabBarView(
          children: [
            WatchlistScreen(),
            NotesScreen(),
          ],
        ),
        bottomNavigationBar: const Material(
          color: Colors.white,
          child: TabBar(
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(icon: Icon(Icons.list_alt), text: "Watchlist"),
              Tab(icon: Icon(Icons.notes), text: "Notes"),
            ],
          ),
        ),
      ),
    );
  }
}