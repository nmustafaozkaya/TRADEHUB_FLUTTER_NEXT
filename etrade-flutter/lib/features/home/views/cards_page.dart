import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/tradehub_theme.dart';
import '../controllers/home_controller.dart';
import 'home_shared_widgets.dart';

class CardsPage extends StatefulWidget {
  const CardsPage({required this.controller, super.key});

  final HomeController controller;

  @override
  State<CardsPage> createState() => _CardsPageState();
}

class _CardsPageState extends State<CardsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.refreshCards();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cardNumberController = TextEditingController();
    final cardHolderController = TextEditingController();
    final cardMonthController = TextEditingController();
    final cardYearController = TextEditingController();
    InputDecoration modernInput({
      required String label,
      required IconData icon,
    }) {
      final border = OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
      );
      return InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: TradeHubColors.textMuted),
        prefixIcon: Icon(icon, color: TradeHubColors.textMuted),
        filled: true,
        fillColor: TradeHubColors.surface2,
        border: border,
        enabledBorder: border,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: TradeHubColors.accent, width: 1.5),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Cards')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            FadeSlideIn(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                  ),
                ),
                child: const Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.white24,
                      child: Icon(
                        Icons.credit_card_rounded,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Saved Cards',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Use your cards faster at checkout',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: cardNumberController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: TradeHubColors.textPrimary),
              cursorColor: TradeHubColors.accent,
              decoration: modernInput(
                label: 'Card number',
                icon: Icons.numbers_rounded,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: cardHolderController,
              style: const TextStyle(color: TradeHubColors.textPrimary),
              cursorColor: TradeHubColors.accent,
              decoration: modernInput(
                label: 'Card holder',
                icon: Icons.person_outline,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: cardMonthController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: TradeHubColors.textPrimary),
                    cursorColor: TradeHubColors.accent,
                    decoration: modernInput(
                      label: 'MM',
                      icon: Icons.date_range_outlined,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: cardYearController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: TradeHubColors.textPrimary),
                    cursorColor: TradeHubColors.accent,
                    decoration: modernInput(
                      label: 'YYYY',
                      icon: Icons.event_outlined,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await widget.controller.addCard(
                    cardNo: cardNumberController.text,
                    cardHolder: cardHolderController.text,
                    expMonth: cardMonthController.text,
                    expYear: cardYearController.text,
                  );
                  cardNumberController.clear();
                  cardHolderController.clear();
                  cardMonthController.clear();
                  cardYearController.clear();
                },
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.add_card_rounded),
                label: const Text('Save card'),
              ),
            ),
            const SizedBox(height: 10),
            Obx(
              () => widget.controller.savedCards.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: TradeHubColors.surface2,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: const Text(
                        'No card saved yet.',
                        style: TextStyle(color: TradeHubColors.textMuted),
                      ),
                    )
                  : ListView.separated(
                      itemCount: widget.controller.savedCards.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, index) {
                        final card = widget.controller.savedCards[index];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: TradeHubColors.surface2,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 19,
                                backgroundColor: TradeHubColors.primary
                                    .withValues(alpha: 0.22),
                                child: const Icon(
                                  Icons.credit_card,
                                  color: TradeHubColors.primary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${card.brand} •••• ${card.last4}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: TradeHubColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${card.cardHolder} • ${card.expMonth.toString().padLeft(2, '0')}/${card.expYear.toString().substring(2)}',
                                      style: const TextStyle(
                                        color: TradeHubColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () =>
                                    widget.controller.removeCard(card.id),
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: TradeHubColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}