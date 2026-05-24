import 'package:flutter_test/flutter_test.dart';

import 'package:bakulan_d_frozen/utils/validators.dart';

void main() {
  test('validasi angka positif menerima nilai lebih dari nol', () {
    expect(Validators.positiveNumber('5', field: 'Qty'), isNull);
  });

  test('validasi angka positif menolak nol', () {
    expect(Validators.positiveNumber('0', field: 'Qty'), isNotNull);
  });
}
