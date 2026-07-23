import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import 'storage_image.dart';

/// A tap-to-pick field that opens a bottom-sheet instead of a floating overlay.
/// Drop-in replacement for DropdownButtonFormField inside modals / bottom sheets.
class AppPickerField<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<AppPickerItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? prefixIcon;
  final String? helperText;

  const AppPickerField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.prefixIcon,
    this.helperText,
  });

  AppPickerItem<T>? get _selected =>
      items.where((i) => i.value == value).firstOrNull;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selected = _selected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => _open(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurfaceElevated : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? Colors.white24 : const Color(0xFFD0D5DD),
              ),
            ),
            child: Row(children: [
              if (prefixIcon != null) ...[
                Iconify(prefixIcon!, size: 20,
                    color: isDark ? Colors.white54 : Colors.black45),
                const SizedBox(width: 12),
              ],
              if (selected?.imagePath != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: _buildStoredImage(selected!, 18),
                ),
                const SizedBox(width: 10),
              ] else if (selected?.leadingIcon != null) ...[
                Iconify(selected!.leadingIcon!, size: 18, color: selected.iconColor),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white54 : Colors.black45,
                        fontWeight: FontWeight.w500,
                      )),
                    const SizedBox(height: 2),
                    Text(
                      selected?.label ?? 'Select…',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: selected == null
                            ? (isDark ? Colors.white38 : Colors.black38)
                            : (isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
              Iconify(AppIcons.caretDown,
                  size: 20,
                  color: isDark ? Colors.white38 : Colors.black38),
            ]),
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(helperText!,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white38 : Colors.black45,
              )),
          ),
        ],
      ],
    );
  }

  void _open(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 12),
          Center(child: Container(width: 40, height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(children: [
              Text(label,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              const Spacer(),
              IconButton(
                icon: Iconify(AppIcons.close, size: 20,
                    color: isDark ? Colors.white70 : Colors.black54),
                onPressed: () => Navigator.pop(context),
              ),
            ]),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
              itemCount: items.length,
              itemBuilder: (ctx, i) {
                final item = items[i];
                final isSelected = item.value == value;
                return InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    onChanged(item.value);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.brandPrimary.withOpacity(0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border.all(color: AppTheme.brandPrimary.withOpacity(0.4))
                          : null,
                    ),
                    child: Row(children: [
                      if (item.imagePath != null) ...[
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: (item.iconColor ?? AppTheme.brandPrimary).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: _buildStoredImage(item, 36),
                          ),
                        ),
                        const SizedBox(width: 14),
                      ] else if (item.leadingIcon != null) ...[
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: (item.iconColor ?? AppTheme.brandPrimary).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Iconify(item.leadingIcon!,
                            size: 18, color: item.iconColor ?? AppTheme.brandPrimary),
                        ),
                        const SizedBox(width: 14),
                      ],
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.label,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected
                                  ? AppTheme.brandPrimary
                                  : (isDark ? Colors.white.withOpacity(0.87) : Colors.black87),
                            )),
                          if (item.subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(item.subtitle!,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white38 : Colors.black45,
                              )),
                          ],
                        ],
                      )),
                      if (isSelected)
                        Iconify(AppIcons.checkCircle,
                          size: 18,
                          color: AppTheme.brandPrimary),
                    ]),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildStoredImage(AppPickerItem<T> item, double size) {
    final fallback = item.leadingIcon != null
        ? Iconify(
            item.leadingIcon!,
            size: 18,
            color: item.iconColor ?? AppTheme.brandPrimary,
          )
        : SizedBox(width: size, height: size);
    return StorageImage(
      stored: item.imagePath!,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback,
      placeholder: fallback,
    );
  }
}

class AppPickerItem<T> {
  final T value;
  final String label;
  final String? subtitle;
  final String? leadingIcon;
  final Color? iconColor;
  final String? imagePath;

  const AppPickerItem({
    required this.value,
    required this.label,
    this.subtitle,
    this.leadingIcon,
    this.iconColor,
    this.imagePath,
  });
}
