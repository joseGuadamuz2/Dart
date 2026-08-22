import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';

class WhatsappButton extends StatefulWidget {
  final String? link;
  final String label;
  final bool compact;

  const WhatsappButton({
    super.key,
    required this.label,
    this.link,
    this.compact = false,
  });

  @override
  State<WhatsappButton> createState() => _WhatsappButtonState();
}

class _WhatsappButtonState extends State<WhatsappButton> {
  bool _pressed = false;

  bool get _enabled => widget.link != null && widget.link!.isNotEmpty;

  Future<void> _open() async {
    final link = widget.link;
    if (link == null || link.isEmpty) return;
    final uri = Uri.parse(link);
    final messenger = ScaffoldMessenger.of(context);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      messenger.showSnackBar(
        const SnackBar(content: Text("No se pudo abrir WhatsApp")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final compact = widget.compact;
    return GestureDetector(
      onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: _enabled ? _open : null,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        height: compact ? 36 : 52,
        decoration: BoxDecoration(
          color: _enabled ? AppColors.whatsappGreen : AppColors.border,
          borderRadius: BorderRadius.circular(compact ? 10 : 14),
        ),
        padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat,
              size: compact ? 16 : 20,
              color: _enabled ? Colors.white : AppColors.textMuted,
            ),
            SizedBox(width: compact ? 7 : 10),
            Flexible(
              child: Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: compact ? 13 : 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                  color: _enabled ? Colors.white : AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
