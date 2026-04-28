import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../models/product_model.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Product product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _announceDetails();
  }

  Future<void> _announceDetails() async {
    final String announcement = 'Detailed Product View for ${widget.product.name}. Summary playing. '
        'Contains allergens: ${widget.product.allergens.join(', ')}. '
        'Ingredients: ${widget.product.ingredients}.';
    await _tts.speak(announcement);
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bgNavy = Color(0xFF0A192F);
    const surfaceNavy = Color(0xFF112240);
    const primaryAmber = Color(0xFFFFBF00);

    return Scaffold(
      backgroundColor: bgNavy,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: surfaceNavy.withAlpha(128))),
              ),
              child: Column(
                children: [
                  Text(
                    widget.product.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.product.brand.toUpperCase(),
                    style: TextStyle(
                      color: primaryAmber.withAlpha(200),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
            ),
            
            // Scrollable Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // Stop Summary button
                  Semantics(
                    label: 'Stop Summary',
                    button: true,
                    child: ElevatedButton(
                      onPressed: () => _tts.stop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryAmber,
                        foregroundColor: bgNavy,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        elevation: 8,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.stop_circle_rounded, size: 36),
                          SizedBox(width: 8),
                          Text(
                            'STOP SUMMARY',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Top Stats
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Calories',
                          value: widget.product.calories.toString(),
                          surfaceNavy: surfaceNavy,
                          primaryAmber: primaryAmber,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          label: 'Serving Size',
                          value: widget.product.servingSize.split(' ').first, // Naive split
                          subtext: widget.product.servingSize,
                          surfaceNavy: surfaceNavy,
                          primaryAmber: primaryAmber,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Nutrition Facts Grid
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.0),
                    child: Text(
                      'NUTRITION FACTS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 2.5,
                    ),
                    itemCount: widget.product.nutritionInfo.length,
                    itemBuilder: (context, index) {
                      final key = widget.product.nutritionInfo.keys.elementAt(index);
                      final value = widget.product.nutritionInfo.values.elementAt(index);
                      // Varying border alpha for that clinical staggered look
                      final alphas = [255, 128, 76, 204];
                      final alpha = alphas[index % alphas.length];
                      
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: surfaceNavy.withAlpha(150),
                          borderRadius: BorderRadius.circular(12),
                          border: Border(left: BorderSide(color: primaryAmber.withAlpha(alpha), width: 4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              key.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                            Text(
                              value,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // Ingredients List
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.0),
                    child: Text(
                      'FULL INGREDIENTS LIST',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: surfaceNavy,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withAlpha(25)),
                    ),
                    child: Text(
                      widget.product.ingredients,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Allergen Warning
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: surfaceNavy,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: primaryAmber, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: primaryAmber.withAlpha(25),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.warning_rounded, color: primaryAmber, size: 36),
                            SizedBox(width: 12),
                            Text(
                              'ALLERGEN WARNING',
                              style: TextStyle(
                                color: primaryAmber,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2.0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'CONTAINS: ${widget.product.allergens.join(", ").toUpperCase()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
            
            // Footer Navigation
            Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: primaryAmber.withAlpha(76),
                    blurRadius: 40,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: Semantics(
                label: 'Back to results',
                button: true,
                child: ElevatedButton(
                  onPressed: () {
                    _tts.stop();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryAmber,
                    foregroundColor: bgNavy,
                    minimumSize: const Size(double.infinity, 96),
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_back_rounded, size: 36),
                      SizedBox(width: 16),
                      Text(
                        'BACK',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ],
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

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subtext;
  final Color surfaceNavy;
  final Color primaryAmber;

  const _StatCard({
    required this.label,
    required this.value,
    this.subtext,
    required this.surfaceNavy,
    required this.primaryAmber,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceNavy,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(25)),
      ),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: primaryAmber.withAlpha(200),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtext != null) ...[
            const SizedBox(height: 2),
            Text(
              "($subtext)",
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
