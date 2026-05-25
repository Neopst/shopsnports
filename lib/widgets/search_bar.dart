// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../styles/colors.dart';

class SearchBarWidget extends StatelessWidget {
  const SearchBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Search products',
      textField: true,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: TextField(
          readOnly: true,
          onTap: () {
            Navigator.of(context).pushNamed('/search');
          },
          decoration: InputDecoration(
            labelText: 'Search',
            hintText: 'Search products...',
            hintStyle: const TextStyle(color: Colors.grey),
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide:
                  const BorderSide(color: Color.fromRGBO(10, 36, 99, 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide:
                  const BorderSide(color: Color.fromRGBO(10, 36, 99, 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide:
                  const BorderSide(color: AppColors.primaryColor, width: 2),
            ),
          ),
        ),
      ),
    );
  }
}
