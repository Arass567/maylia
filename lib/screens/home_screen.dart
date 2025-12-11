import 'package:flutter/material.dart';
import 'inbox_screen.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    InboxScreen(), // Emails en premier (principal)
    ChatScreen(), // Assistant en second
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 📱 Responsive Design: Support tablettes et landscape
    return LayoutBuilder(
      builder: (context, constraints) {
        // Tablette (> 600dp): NavigationRail + Split view
        if (constraints.maxWidth > 600) {
          return Scaffold(
            body: Row(
              children: [
                // NavigationRail pour tablettes
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onItemTapped,
                  labelType: NavigationRailLabelType.all,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.mail_outlined),
                      selectedIcon: Icon(Icons.mail),
                      label: Text('Emails'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.auto_awesome_outlined),
                      selectedIcon: Icon(Icons.auto_awesome),
                      label: Text('Assistant'),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                // Contenu principal
                Expanded(
                  child: _screens[_selectedIndex],
                ),
              ],
            ),
          );
        }

        // Mobile: NavigationBar Material 3
        return Scaffold(
          body: _screens[_selectedIndex],
          // 🎨 Material 3 NavigationBar (au lieu de BottomNavigationBar)
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onItemTapped,
            animationDuration: const Duration(milliseconds: 300),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.mail_outlined),
                selectedIcon: Icon(Icons.mail),
                label: 'Emails',
                tooltip: 'Boîte de réception',
              ),
              NavigationDestination(
                icon: Icon(Icons.auto_awesome_outlined),
                selectedIcon: Icon(Icons.auto_awesome),
                label: 'Assistant',
                tooltip: 'Assistant IA',
              ),
            ],
          ),
        );
      },
    );
  }
}
