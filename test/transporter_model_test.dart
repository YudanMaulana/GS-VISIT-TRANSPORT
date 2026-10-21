import 'package:flutter_test/flutter_test.dart';
import 'package:gs_visit_transport/src/models.dart';

void main() {
  group('Transporter ActiveGuestRow Tests', () {
    test('Parsing per-area queue and area information correctly', () {
      final jsonPlanned = {
        'plan_id': 105,
        'visitor_id': 50,
        'name': 'Budi Transporter',
        'company': 'PT Cepat Aman',
        'status': 'planned',
        'load_type': 'bongkar',
        'queue_number': null,
        'area_id': 1,
        'area_name': 'Garudafood',
        'area_code': 'GF',
      };

      final rowPlanned = ActiveGuestRow.fromJson(jsonPlanned);
      expect(rowPlanned.planId, 105);
      expect(rowPlanned.name, 'Budi Transporter');
      expect(rowPlanned.areaName, 'Garudafood');
      expect(rowPlanned.areaCode, 'GF');
      // Status planned belum terbit antrean
      expect(rowPlanned.queueNumber, isNull);

      final jsonCheckedIn = {
        'plan_id': 106,
        'visitor_id': 51,
        'name': 'Joko Truk',
        'company': 'PT Logistik Sejahtera',
        'status': 'checked_in',
        'load_type': 'muat',
        'queue_number': 1,
        'area_id': 2,
        'area_name': 'DC',
        'area_code': 'DC',
      };

      final rowCheckedIn = ActiveGuestRow.fromJson(jsonCheckedIn);
      expect(rowCheckedIn.queueNumber, 1);
      expect(rowCheckedIn.areaName, 'DC');
      expect(rowCheckedIn.areaCode, 'DC');
    });
  });
}
