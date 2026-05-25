import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopsnports/services/currency_converter.dart';

/// Currency selector widget with flag dropdown
class CurrencySelector extends ConsumerStatefulWidget {
  final double? iconSize;
  final TextStyle? textStyle;
  final EdgeInsets? padding;

  const CurrencySelector({
    super.key,
    this.iconSize = 24,
    this.textStyle,
    this.padding,
  });

  @override
  ConsumerState<CurrencySelector> createState() => _CurrencySelectorState();
}

class _CurrencySelectorState extends ConsumerState<CurrencySelector> {
  final GlobalKey _dropdownKey = GlobalKey();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _initializeConverter();
  }

  Future<void> _initializeConverter() async {
    await CurrencyConverter().initialize();
    if (mounted) setState(() {});
  }

  void _showDropdown() {
    final RenderBox renderBox =
        _dropdownKey.currentContext?.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: () {
          _hideDropdown();
        },
        child: Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              // Backdrop
              Positioned.fill(
                child: Container(
                  color: Colors.black26,
                ),
              ),
              // Dropdown
              Positioned(
                left: offset.dx,
                top: offset.dy + size.height + 4,
                width: size.width + 150,
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                  child: _buildDropdownList(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildDropdownList(BuildContext context) {
    final converter = CurrencyConverter();
    final currencies = SupportedCurrencies.all;
    final currentCurrency = SupportedCurrencies.byCode(converter.baseCurrency);

    return SizedBox(
      height: 400,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.currency_exchange, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  'Select Currency',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                if (converter.lastUpdated != null)
                  Text(
                    'Updated: ${_formatTime(converter.lastUpdated!)}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          // Search bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search currency...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              onChanged: (value) {
                setState(() {}); // Rebuild to filter
              },
            ),
          ),
          // Currency list
          Expanded(
            child: StreamBuilder<Map<String, double>>(
              stream: Stream.value(converter.rates),
              builder: (context, snapshot) {
                final filteredCurrencies = currencies.where((currency) {
                  // This is a simple filter - in a real app, you'd have state for search
                  return true;
                }).toList();

                return ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: filteredCurrencies.length,
                  itemBuilder: (context, index) {
                    final currency = filteredCurrencies[index];
                    final isSelected = currency.code == currentCurrency.code;
                    final rate = converter.getRateDisplay(currency.code);

                    return Material(
                      color: isSelected
                          ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                          : Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          _selectCurrency(currency.code);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              // Flag
                              Text(
                                currency.flag,
                                style: TextStyle(fontSize: widget.iconSize),
                              ),
                              const SizedBox(width: 12),
                              // Currency info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      currency.code,
                                      style: TextStyle(
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        fontSize: 15,
                                      ),
                                    ),
                                    Text(
                                      currency.name,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              // Symbol and rate
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    currency.symbol,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    '1 NGN = $rate ${currency.code}',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  color: Theme.of(context).primaryColor,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Refresh button
          Padding(
            padding: const EdgeInsets.all(12),
            child: OutlinedButton.icon(
              onPressed: () async {
                _hideDropdown();
                await converter.refreshRates();
                setState(() {});
                _showDropdown(); // Show dropdown again
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh Rates'),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Future<void> _selectCurrency(String code) async {
    _hideDropdown();
    await CurrencyConverter().fetchRates(base: code);
    setState(() {});
  }

  @override
  void dispose() {
    _hideDropdown();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final converter = CurrencyConverter();
    final currentCurrency = SupportedCurrencies.byCode(converter.baseCurrency);

    return GestureDetector(
      key: _dropdownKey,
      onTap: () {
        if (_overlayEntry == null) {
          _showDropdown();
        } else {
          _hideDropdown();
        }
      },
      child: Container(
        padding: widget.padding ??
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currentCurrency.flag,
              style: TextStyle(fontSize: widget.iconSize),
            ),
            const SizedBox(width: 8),
            Text(
              currentCurrency.code,
              style: widget.textStyle ??
                  TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              color: Theme.of(context).primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact currency badge for use in headers
class CurrencyBadge extends StatelessWidget {
  final String currencyCode;
  final double? iconSize;
  final bool showCode;

  const CurrencyBadge({
    super.key,
    required this.currencyCode,
    this.iconSize = 20,
    this.showCode = true,
  });

  @override
  Widget build(BuildContext context) {
    final currency = SupportedCurrencies.byCode(currencyCode);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            currency.flag,
            style: TextStyle(fontSize: iconSize),
          ),
          if (showCode) ...[
            const SizedBox(width: 6),
            Text(
              currency.code,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}