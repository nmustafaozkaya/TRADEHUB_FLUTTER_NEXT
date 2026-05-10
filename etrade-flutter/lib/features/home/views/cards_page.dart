import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
      return InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.black12),
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
              decoration: modernInput(
                label: 'Card number',
                icon: Icons.numbers_rounded,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: cardHolderController,
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: const Text('No card saved yet.'),
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
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.black12),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 19,
                                backgroundColor: Colors.indigo.shade50,
                                child: const Icon(
                                  Icons.credit_card,
                                  color: Colors.indigo,
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
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${card.cardHolder} • ${card.expMonth.toString().padLeft(2, '0')}/${card.expYear.toString().substring(2)}',
                                      style: const TextStyle(
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () =>
                                    widget.controller.removeCard(card.id),
                                icon: const Icon(Icons.delete_outline),
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