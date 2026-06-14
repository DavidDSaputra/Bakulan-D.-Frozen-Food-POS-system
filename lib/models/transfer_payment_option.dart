import 'package:flutter/material.dart';

class TransferPaymentOption {
  const TransferPaymentOption({
    required this.id,
    required this.name,
    required this.shortName,
    required this.logoText,
    required this.typeLabel,
    required this.accountNumber,
    required this.accountName,
    required this.color,
    required this.foreground,
  });

  final String id;
  final String name;
  final String shortName;
  final String logoText;
  final String typeLabel;
  final String accountNumber;
  final String accountName;
  final Color color;
  final Color foreground;
}

const virtualAccountOptions = [
  TransferPaymentOption(
    id: 'bca_va',
    name: 'BCA',
    shortName: 'BCA VA',
    logoText: 'BCA',
    typeLabel: 'Virtual Account',
    accountNumber: '88081234567890',
    accountName: 'Bakulan D Frozen',
    color: Color(0xFF005BAA),
    foreground: Colors.white,
  ),
  TransferPaymentOption(
    id: 'bri_va',
    name: 'BRI',
    shortName: 'BRI VA',
    logoText: 'BRI',
    typeLabel: 'Virtual Account',
    accountNumber: '888101234567890',
    accountName: 'Bakulan D Frozen',
    color: Color(0xFF00529C),
    foreground: Colors.white,
  ),
  TransferPaymentOption(
    id: 'bsi_va',
    name: 'BSI',
    shortName: 'BSI VA',
    logoText: 'BSI',
    typeLabel: 'Virtual Account',
    accountNumber: '90011234567890',
    accountName: 'Bakulan D Frozen',
    color: Color(0xFF00A39B),
    foreground: Colors.white,
  ),
  TransferPaymentOption(
    id: 'bni_va',
    name: 'BNI',
    shortName: 'BNI VA',
    logoText: 'BNI',
    typeLabel: 'Virtual Account',
    accountNumber: '98881234567890',
    accountName: 'Bakulan D Frozen',
    color: Color(0xFFF15A24),
    foreground: Colors.white,
  ),
];

const eWalletOptions = [
  TransferPaymentOption(
    id: 'dana',
    name: 'DANA',
    shortName: 'DANA',
    logoText: 'DANA',
    typeLabel: 'E-Wallet',
    accountNumber: '085712345678',
    accountName: 'Bakulan D Frozen',
    color: Color(0xFF108EE9),
    foreground: Colors.white,
  ),
  TransferPaymentOption(
    id: 'gopay',
    name: 'GoPay',
    shortName: 'GoPay',
    logoText: 'GoPay',
    typeLabel: 'E-Wallet',
    accountNumber: '085712345678',
    accountName: 'Bakulan D Frozen',
    color: Color(0xFF00AED6),
    foreground: Colors.white,
  ),
  TransferPaymentOption(
    id: 'ovo',
    name: 'OVO',
    shortName: 'OVO',
    logoText: 'OVO',
    typeLabel: 'E-Wallet',
    accountNumber: '085712345678',
    accountName: 'Bakulan D Frozen',
    color: Color(0xFF4C2A86),
    foreground: Colors.white,
  ),
  TransferPaymentOption(
    id: 'shopeepay',
    name: 'ShopeePay',
    shortName: 'ShopeePay',
    logoText: 'SPay',
    typeLabel: 'E-Wallet',
    accountNumber: '085712345678',
    accountName: 'Bakulan D Frozen',
    color: Color(0xFFEE4D2D),
    foreground: Colors.white,
  ),
];
