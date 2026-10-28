import 'package:flutter_test/flutter_test.dart';
import 'package:gs_visit_transport/src/models.dart';

void main() {
  group('Transporter ActiveGuestRow & 3-Area Grouping Tests', () {
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
      expect(rowPlanned.areaCategory, PlantAreaCategory.garudafood);
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
      expect(rowCheckedIn.areaCategory, PlantAreaCategory.dc);
    });

    test('Categorizes into 3 areas: GARUDAFOOD, DC, and MBR accurately', () {
      // 1. Garudafood / GF
      expect(PlantAreaCategory.fromCodeOrName('GF', 'Garudafood'),
          PlantAreaCategory.garudafood);
      expect(PlantAreaCategory.fromCodeOrName('gf', 'Plant GF'),
          PlantAreaCategory.garudafood);
      expect(PlantAreaCategory.fromCodeOrName('', 'Garudafood Sumedang'),
          PlantAreaCategory.garudafood);

      // 2. DC / Distribution Center
      expect(PlantAreaCategory.fromCodeOrName('DC', 'DC'),
          PlantAreaCategory.dc);
      expect(PlantAreaCategory.fromCodeOrName('dc', 'Distribution Center'),
          PlantAreaCategory.dc);
      expect(PlantAreaCategory.fromCodeOrName('', 'Gudang Distribusi DC'),
          PlantAreaCategory.dc);

      // 3. MBR
      expect(PlantAreaCategory.fromCodeOrName('MBR', 'MBR'),
          PlantAreaCategory.mbr);
      expect(PlantAreaCategory.fromCodeOrName('mbr', 'Area MBR'),
          PlantAreaCategory.mbr);

      // Fallback
      expect(PlantAreaCategory.fromCodeOrName(null, null),
          PlantAreaCategory.garudafood);
    });

    test('PlantArea model parses JSON correctly from /api/areas', () {
      final jsonAreaGF = {
        'id': 1,
        'branch_id': 1,
        'code': 'GF',
        'name': 'Garudafood',
        'active': true,
        'sort_order': 0,
      };
      final areaGF = PlantArea.fromJson(jsonAreaGF);
      expect(areaGF.id, 1);
      expect(areaGF.code, 'GF');
      expect(areaGF.name, 'Garudafood');
      expect(areaGF.category, PlantAreaCategory.garudafood);

      final jsonAreaDC = {
        'id': 2,
        'branch_id': 1,
        'code': 'DC',
        'name': 'DC',
        'active': true,
        'sort_order': 1,
      };
      final areaDC = PlantArea.fromJson(jsonAreaDC);
      expect(areaDC.id, 2);
      expect(areaDC.category, PlantAreaCategory.dc);

      final jsonAreaMBR = {
        'id': 3,
        'branch_id': 1,
        'code': 'MBR',
        'name': 'MBR',
        'active': true,
        'sort_order': 2,
      };
      final areaMBR = PlantArea.fromJson(jsonAreaMBR);
      expect(areaMBR.id, 3);
      expect(areaMBR.category, PlantAreaCategory.mbr);
    });

    test('MBR transporter row is mapped to PlantAreaCategory.mbr', () {
      final jsonMBR = {
        'plan_id': 108,
        'visitor_id': 60,
        'name': 'Sopir MBR',
        'company': 'PT MBR Logistik',
        'status': 'checked_in',
        'load_type': 'bongkar',
        'queue_number': 3,
        'area_id': 3,
        'area_name': 'MBR',
        'area_code': 'MBR',
        'is_active': false,
      };
      final rowMBR = ActiveGuestRow.fromJson(jsonMBR);
      expect(rowMBR.queueNumber, 3);
      expect(rowMBR.areaCode, 'MBR');
      expect(rowMBR.areaCategory, PlantAreaCategory.mbr);
      expect(rowMBR.isActive, isFalse);
    });

    test('TransporterDriver model parses JSON and calculates SIM status', () {
      final driverActive = TransporterDriver.fromJson({
        'id': 15,
        'visitor_code': 'V-0015',
        'full_name': 'Budi Santoso',
        'company': 'PT Sumber Rejeki',
        'phone': '081234567890',
        'sim_number': 'SIM-12345',
        'sim_expires_at': DateTime.now().add(const Duration(days: 60)).toIso8601String(),
        'is_active': true,
        'total_trips': 12,
        'last_visit': '2026-10-21',
      });

      expect(driverActive.id, 15);
      expect(driverActive.fullName, 'Budi Santoso');
      expect(driverActive.isActive, isTrue);
      expect(driverActive.isSimExpired, isFalse);
      expect(driverActive.isSimExpiringSoon, isFalse);
      expect(driverActive.totalTrips, 12);
      expect(driverActive.matches('budi'), isTrue);
      expect(driverActive.matches('rejeki'), isTrue);
      expect(driverActive.matches('sim-123'), isTrue);
      expect(driverActive.matches('tidak-ada'), isFalse);

      final driverExpired = TransporterDriver.fromJson({
        'id': 16,
        'visitor_code': 'V-0016',
        'full_name': 'Ahmad Fauzi',
        'company': 'PT Cepat Logistik',
        'phone': '08987654321',
        'sim_number': 'SIM-99999',
        'sim_expires_at': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
        'is_active': false,
      });

      expect(driverExpired.id, 16);
      expect(driverExpired.isActive, isFalse);
      expect(driverExpired.isSimExpired, isTrue);

      // Skenario sopir baru mendaftar dari /api/visitors (belum ada trip/bongkar muat & is_active null)
      final newRegisteredDriver = TransporterDriver.fromJson({
        'id': 20,
        'visitor_code': 'V-000020',
        'visitor_type': 'transporter',
        'full_name': 'YUDAN',
        'company': 'PT VELTRIX TECH',
        'phone': '08986244418',
        'sim_number': '1234567890987',
        'sim_expires_at': '2026-10-31',
        'created_at': '2026-10-22T07:40:43.519112+00:00',
        'photo_url': '/photos/register/V-000020_c7731bf8.jpg',
      });

      expect(newRegisteredDriver.id, 20);
      expect(newRegisteredDriver.visitorCode, 'V-000020');
      expect(newRegisteredDriver.fullName, 'YUDAN');
      expect(newRegisteredDriver.company, 'PT VELTRIX TECH');
      expect(newRegisteredDriver.isActive, isTrue);
      expect(newRegisteredDriver.totalTrips, 0);
      expect(newRegisteredDriver.matches('veltrix'), isTrue);
    });

    test('ActiveGuestRow parses goods data (data barang) and computes goodsSummary', () {
      final jsonWithGoods = {
        'plan_id': 201,
        'visitor_id': 60,
        'name': 'Agus Sopir',
        'company': 'PT Cepat Logistik',
        'status': 'checked_in',
        'load_type': 'bongkar',
        'first_shipment_no': 'SJ-10029',
        'first_goods_name': 'Kacang Kulit Garuda',
        'first_quantity': '10 Pallet (5 Ton)',
        'load_count': 2,
        'checkin_at': '2026-10-28T03:30:00Z',
      };

      final row = ActiveGuestRow.fromJson(jsonWithGoods);
      expect(row.firstShipmentNo, 'SJ-10029');
      expect(row.firstGoodsName, 'Kacang Kulit Garuda');
      expect(row.firstQuantity, '10 Pallet (5 Ton)');
      expect(row.goodsSummary, 'Kacang Kulit Garuda (10 Pallet (5 Ton))');
      expect(row.loadCount, 2);
    });
  });
}

