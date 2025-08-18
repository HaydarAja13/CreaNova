import 'package:flutter/material.dart';

void main() {
  runApp(
    // MaterialApp adalah widget dasar untuk aplikasi Anda.
    const MaterialApp(
      // home adalah layar pertama yang akan ditampilkan.
      home: Scaffold(
        // Center akan memposisikan widget anaknya (child) ke tengah layar.
        body: Center(
          child: Text('Tukar.in'),
        ),
      ),
    ),
  );
}