import 'package:flutter/material.dart';
import '../../shared/design_tokens/tokens.dart';

/// Accessible text input component with clear label, prefix/suffix icons,
/// and accessible helper/error text.
class LinguaTextInput extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? errorText;
  final IconData? prefixIcon;
  final bool isPassword;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;

  const LinguaTextInput({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.errorText,
    this.prefixIcon,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.focusNode,
  });

  @override
  State<LinguaTextInput> createState() => _LinguaTextInputState();
}

class _LinguaTextInputState extends State<LinguaTextInput> {
  late bool _obscured;

  @override
  void initState() {
    super.initState();
    _obscured = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      textField: true,
      label: widget.label,
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        keyboardType: widget.keyboardType,
        obscureText: _obscured,
        onChanged: widget.onChanged,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          errorText: widget.errorText,
          prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon) : null,
          suffixIcon: widget.isPassword
              ? IconButton(
                  icon: Icon(
                    _obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: LinguaTokens.inkMuted,
                  ),
                  tooltip: _obscured ? 'Show password' : 'Hide password',
                  onPressed: () => setState(() => _obscured = !_obscured),
                )
              : null,
        ),
      ),
    );
  }
}
