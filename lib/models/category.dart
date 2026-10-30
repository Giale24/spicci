import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final List<String> smartTags;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.smartTags,
  });

  static const List<Category> defaultCategories = [
    Category(
      id: 'cibo',
      name: 'Cibo',
      icon: Icons.restaurant_rounded,
      color: Color(0xFFFF9100), // Arancio caldo
      smartTags: ['Supermercato', 'Bar', 'Ristorante', 'Delivery', 'Pasticceria', 'Pranzo'],
    ),
    Category(
      id: 'trasporti',
      name: 'Trasporti',
      icon: Icons.directions_car_rounded,
      color: Color(0xFF40C4FF), // Azzurro
      smartTags: ['Carburante', 'Mezzi', 'Parcheggio', 'Treno', 'Pedaggio', 'Taxi'],
    ),
    Category(
      id: 'svago',
      name: 'Svago',
      icon: Icons.sports_esports_rounded,
      color: Color(0xFFB388FF), // Viola
      smartTags: ['Cinema', 'Uscita', 'Viaggi', 'Sport', 'Eventi', 'Hobby'],
    ),
    Category(
      id: 'casa',
      name: 'Casa',
      icon: Icons.home_rounded,
      color: Color(0xFF69F0AE), // Menta chiaro
      smartTags: ['Bollette', 'Affitto', 'Manutenzione', 'Spesa casa', 'Mobili'],
    ),
    Category(
      id: 'shopping',
      name: 'Shopping',
      icon: Icons.shopping_bag_rounded,
      color: Color(0xFFFF4081), // Rosa
      smartTags: ['Abbigliamento', 'Elettronica', 'Cura persona', 'Regali', 'Accessori'],
    ),
    Category(
      id: 'salute',
      name: 'Salute',
      icon: Icons.favorite_rounded,
      color: Color(0xFFFF5252), // Rosso
      smartTags: ['Farmacia', 'Visita medica', 'Dentista', 'Esami', 'Integratori'],
    ),
    Category(
      id: 'abbonamenti',
      name: 'Abbonamenti',
      icon: Icons.subscriptions_rounded,
      color: Color(0xFFFFD54F), // Ambra chiaro
      smartTags: ['Netflix', 'Spotify', 'Palestra', 'Cloud', 'Telefono'],
    ),
    Category(
      id: 'altro',
      name: 'Altro',
      icon: Icons.more_horiz_rounded,
      color: Color(0xFF90A4AE), // Grigio azzurrato
      smartTags: ['Generale', 'Commissioni', 'Prestito', 'Tasse'],
    ),
  ];

  static Category byId(String id) {
    return defaultCategories.firstWhere(
      (c) => c.id == id,
      orElse: () => defaultCategories.last,
    );
  }
}
