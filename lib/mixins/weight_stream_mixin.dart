import 'dart:async';
import 'package:f16_balanza_electronica/models/weight_state.dart';
import 'package:flutter/material.dart';
import '../services/weight_service.dart';

mixin WeightStreamMixin<T extends StatefulWidget> on State<T> {
  final WeightService _weightService = WeightService();

  StreamSubscription? _weightSubscription;

  int adcRaw = 0;
  double adcFiltered = 0.0;
  bool hasData = false;

  void subscribeToWeightStream() {
    _weightSubscription = _weightService.weightStateStream.listen((WeightState state) {
      if (!mounted) return;
      setState(() {
        adcRaw = state.adcRaw;
        adcFiltered = state.adcFiltered ?? state.adcRaw.toDouble();
        hasData = adcRaw != 0;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    subscribeToWeightStream();
  }

  @override
  void dispose() {
    _weightSubscription?.cancel();
    super.dispose();
  }
}
