// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for DartPad issue 881.

@pragma('dart2js:disableFinal')
void main() {
  String v = null;
  print('${v.hashCode}');
}
