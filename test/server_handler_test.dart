// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'test_util.dart';

void main() {
  test("passes the URL to the server", () {
    var serverHandler = new ServerHandler(LOCALHOST_URI);
    expect(serverHandler.server.url, equals(LOCALHOST_URI));
  });

  test("pipes a request from ServerHandler.handler to a mounted handler",
      () async {
    var serverHandler = new ServerHandler(LOCALHOST_URI);
    serverHandler.server.mount(asyncHandler);

    var response = await makeSimpleRequest(serverHandler.handler);
    expect(response.statusCode, equals(200));
    expect(response.readAsString(), completion(equals('Hello from /')));
  });

  test("waits until the server's handler is mounted to service a request",
      () async {
    var serverHandler = new ServerHandler(LOCALHOST_URI);
    var future = makeSimpleRequest(serverHandler.handler);
    await new Future.delayed(Duration.ZERO);

    serverHandler.server.mount(syncHandler);
    var response = await future;
    expect(response.statusCode, equals(200));
    expect(response.readAsString(), completion(equals('Hello from /')));
  });

  test("stops servicing requests after Server.close is called", () {
    var serverHandler = new ServerHandler(LOCALHOST_URI);
    serverHandler.server.mount(expectAsync1((_) {}, count: 0));
    serverHandler.server.close();

    expect(makeSimpleRequest(serverHandler.handler), throwsStateError);
  });

  test("calls onClose when Server.close is called", () async {
    var onCloseCalled = false;
    var completer = new Completer();
    var serverHandler = new ServerHandler(LOCALHOST_URI, onClose: () {
      onCloseCalled = true;
      return completer.future;
    });

    var closeDone = false;
    serverHandler.server.close().then((_) {
      closeDone = true;
    });
    expect(onCloseCalled, isTrue);
    await new Future.delayed(Duration.ZERO);

    expect(closeDone, isFalse);
    completer.complete();
    await new Future.delayed(Duration.ZERO);

    expect(closeDone, isTrue);
  });

  test("doesn't allow Server.mount to be called multiple times", () {
    var serverHandler = new ServerHandler(LOCALHOST_URI);
    serverHandler.server.mount((_) {});
    expect(() => serverHandler.server.mount((_) {}), throwsStateError);
    expect(() => serverHandler.server.mount((_) {}), throwsStateError);
  });
}
