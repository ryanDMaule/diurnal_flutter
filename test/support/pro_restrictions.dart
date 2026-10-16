import 'package:flutter_test/flutter_test.dart';

import 'package:diurnul/config/pro_restrictions.dart';

void useRestrictedProMode() {
  setUp(() => ProRestrictions.setTestOverride(true));
  tearDown(() => ProRestrictions.setTestOverride(null));
}
