import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/tradehub_theme.dart';
import '../controllers/home_controller.dart';
import 'home_shared_widgets.dart';

class AddressPage extends StatefulWidget {
  const AddressPage({required this.controller, super.key});

  final HomeController controller;

  @override
  State<AddressPage> createState() => _AddressPageState();
}

class _AddressPageState extends State<AddressPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.refreshAddresses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final addressController = TextEditingController();

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
      appBar: AppBar(title: const Text('Address')),
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
                    colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
                  ),
                ),
                child: const Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.white24,
                      child: Icon(
                        Icons.location_on_outlined,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Saved Addresses',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Manage delivery locations',
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
              controller: addressController,
              minLines: 2,
              maxLines: 3,
              style: const TextStyle(color: TradeHubColors.textPrimary),
              cursorColor: TradeHubColors.accent,
              decoration: modernInput(
                label: 'New address',
                icon: Icons.home_work_outlined,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await widget.controller.addAddress(addressController.text);
                  addressController.clear();
                },
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color(0xFF0D9488),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.add_location_alt_outlined),
                label: const Text('Add address'),
              ),
            ),
            const SizedBox(height: 10),
            Obx(
              () => widget.controller.addresses.isEmpty
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
                        'No address added yet.',
                        style: TextStyle(color: TradeHubColors.textMuted),
                      ),
                    )
                  : ListView.separated(
                      itemCount: widget.controller.addresses.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, index) {
                        final address = widget.controller.addresses[index];
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: TradeHubColors.success
                                    .withValues(alpha: 0.22),
                                child: const Icon(
                                  Icons.place_outlined,
                                  color: TradeHubColors.success,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      address.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: TradeHubColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      address.addressText,
                                      style: const TextStyle(
                                        color: TradeHubColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () =>
                                    widget.controller.removeAddress(address.id),
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
