import 'package:flutter/material.dart';
import 'package:my_reflection_app/services/quote_service.dart';

class QuoteCard extends StatefulWidget {
  final PageController pageController;
  final int index;

  const QuoteCard({
    super.key,
    required this.pageController,
    required this.index,
  });
  @override
  State<QuoteCard> createState() => _QuoteCardState();
}

class _QuoteCardState extends State<QuoteCard> {
  static const double _kVerticalDragVelocity = 200.0;
  late final List<Quote> _quotes;
  final PageController _quotePageController = PageController();
  int _currentQuoteIndex = 0;

  @override
  void initState() {
    super.initState();
    _quotes = QuoteService().getShuffledQuotes();
    _quotePageController.addListener(() {
      if (_quotePageController.page?.round() != _currentQuoteIndex) {
        setState(() {
          _currentQuoteIndex = _quotePageController.page!.round();
        });
      }
    });
  }

  @override
  void dispose() {
    _quotePageController.dispose();
    super.dispose();
  }

  // Helper method to calculate the parallax effect based on the parent PageController.
  double _getParallaxHorizontalShift() {
    // Ensure the controller is attached before accessing its page property.
    if (!widget.pageController.hasClients || widget.pageController.page == null) {
      return 0.0;
    }
    double page = widget.pageController.page!;
    double value = page - widget.index;
    const parallaxFactor = 0.2;
    return value * parallaxFactor;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cardBorderRadius = BorderRadius.circular(12);

    // Handle the case where no quotes are available to prevent errors.
    if (_quotes.isEmpty) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: cardBorderRadius),
        child: const Center(
          child: Text('Цитаты не найдены.'),
        ),
      );
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: cardBorderRadius),
      color: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      child: AnimatedBuilder(
        animation: widget.pageController,
        builder: (context, child) {
          final horizontalShift = _getParallaxHorizontalShift();

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.tertiary.withOpacity(0.7),
                  colorScheme.surfaceVariant.withOpacity(0.9),
                ],
                begin: Alignment(-1.0 - horizontalShift, -1.0),
                end: Alignment(1.0 - horizontalShift, 1.0),
              ),
            ),
            child: child,
          );
        },
        child: GestureDetector(
          onVerticalDragEnd: (details) {
            // Определяем направление свайпа и переключаем страницу
            if (details.primaryVelocity! < -_kVerticalDragVelocity) { // Свайп вверх
              _quotePageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
            } else if (details.primaryVelocity! > _kVerticalDragVelocity) { // Свайп вниз
              _quotePageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
            }
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              PageView.builder(
                controller: _quotePageController,
                scrollDirection: Axis.vertical,
                physics: const NeverScrollableScrollPhysics(), // Отключаем стандартный скролл, чтобы управлять им через GestureDetector
                itemCount: _quotes.length,
                itemBuilder: (context, quoteIndex) {
                  final quote = _quotes[quoteIndex];
                  return Padding( // Убираем вертикальный padding для идеального центрирования
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(Icons.format_quote, size: 48, color: colorScheme.onTertiaryContainer),
                        const SizedBox(height: 24),
                        Expanded(
                          child: Center(
                            child: Text(
                              quote.text,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontStyle: FontStyle.italic),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                        Text('— ${quote.author}', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70), textAlign: TextAlign.right),
                      ],
                    ),
                  );
                },
              ),
              if (_currentQuoteIndex > 0)
                Positioned(
                  top: 15,
                  child: Icon(Icons.keyboard_arrow_up, color: Colors.white.withOpacity(0.5), size: 32),
                ),
              if (_currentQuoteIndex < _quotes.length - 1)
                Positioned(
                  bottom: 15,
                  child: Icon(Icons.keyboard_arrow_down, color: Colors.white.withOpacity(0.5), size: 32),
                ),
            ],
          ),
        ),
      ),
    );
  }
}