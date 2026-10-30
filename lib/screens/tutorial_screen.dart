import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_colors.dart';

class TutorialScreen extends StatefulWidget {
  final bool isModal;

  const TutorialScreen({super.key, this.isModal = false});

  static Future<void> showAsModal(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => const SizedBox(
        height: 600,
        child: TutorialScreen(isModal: true),
      ),
    );
  }

  static Future<bool> shouldShowTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool('spicci_tutorial_completed') ?? false);
  }

  static Future<void> markTutorialCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('spicci_tutorial_completed', true);
  }

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_TutorialSlide> _slides = [
    _TutorialSlide(
      icon: Icons.monetization_on_rounded,
      iconColor: AppColors.goldCoin,
      title: 'Benvenuto in SpicciTrack!',
      subtitle: 'Segna le spese in un lampo',
      description:
          'Progettato per chi odia le app lente. Registri qualsiasi spesa in meno di 3 secondi, 100% offline e privato sul tuo telefono.',
    ),
    _TutorialSlide(
      icon: Icons.touch_app_rounded,
      iconColor: AppColors.purple,
      title: 'La Regola dei 3 Tocchi',
      subtitle: 'Velocità pura senza menu complicati',
      description:
          '1. Digiti la cifra sul tastierino integrato.\n2. Tocchi l\'icona della categoria.\n3. Premi "Segna" sotto il pollice.\nNiente tastiera che salta su coprendo lo schermo!',
    ),
    _TutorialSlide(
      icon: Icons.sell_rounded,
      iconColor: AppColors.cyan,
      title: 'Smart Tag: Addio Tastiera',
      subtitle: 'Note automatiche a bolla',
      description:
          'Toccando una categoria (es. Cibo), compaiono le bolle rapide: Bar, Supermercato, Ristorante, Delivery. Tocchi la bolla e la spesa è già etichettata.',
    ),
    _TutorialSlide(
      icon: Icons.safety_divider_rounded,
      iconColor: AppColors.amber,
      title: 'Calcolatrice Dividi Conto',
      subtitle: 'Tasto ÷ per cene e uscite',
      description:
          'Conto da 80€ diviso tra 4 amici? Digiti 80 ÷ 4 sul tastierino: SpicciTrack registra direttamente la tua quota di 20€ senza farti fare conti a mente alla cassa.',
    ),
    _TutorialSlide(
      icon: Icons.pie_chart_rounded,
      iconColor: AppColors.purpleLight,
      title: 'Budget Dinamico & Filtri',
      subtitle: 'Analisi visiva immediata',
      description:
          'SpicciTrack calcola quanto puoi spendere oggi. Con i due bottoni "Spese Fisse" e "Fuori Budget" (es. acquisto auto) puoi isolare o includere grandi spese senza alterare il tuo budget quotidiano!',
    ),
  ];

  void _finish() async {
    await TutorialScreen.markTutorialCompleted();
    if (mounted) {
      if (widget.isModal) {
        Navigator.pop(context);
      } else {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isModal ? Colors.transparent : AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: _finish,
            child: Text(
              'Salta',
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icona circolare
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: slide.iconColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: slide.iconColor.withValues(alpha: 0.4),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: slide.iconColor.withValues(alpha: 0.2),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(slide.icon, size: 52, color: slide.iconColor),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          slide.subtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.purpleLight,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCard,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            slide.description,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Indicatori a punti
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == i ? AppColors.purple : AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Pulsante Avanti / Inizia
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    shadowColor: AppColors.purple.withValues(alpha: 0.5),
                  ),
                  onPressed: () {
                    if (_currentPage < _slides.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      _finish();
                    }
                  },
                  child: Text(
                    _currentPage == _slides.length - 1 ? 'HO CAPITO, COMINCIAMO!' : 'Avanti',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
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

class _TutorialSlide {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String description;

  const _TutorialSlide({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.description,
  });
}
