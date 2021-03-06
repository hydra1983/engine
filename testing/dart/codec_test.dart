// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:path/path.dart' as path;

void main() {

  test('Animation metadata', () async {
    Uint8List data = await _getSkiaResource('alphabetAnim.gif').readAsBytes();
    Completer<ui.Codec> completer = new Completer<ui.Codec>();
    expect(ui.instantiateImageCodec(data, completer.complete), null);
    ui.Codec codec = await completer.future;
    expect(codec.frameCount, 13);
    expect(codec.repetitionCount, 0);
    codec.dispose();

    data = await _getSkiaResource('test640x479.gif').readAsBytes();
    completer = new Completer<ui.Codec>();
    expect(ui.instantiateImageCodec(data, completer.complete), null);
    codec = await completer.future;
    expect(codec.frameCount, 4);
    expect(codec.repetitionCount, -1);
  });

  test('Fails when no callback provided', () async {
    Uint8List data = await _getSkiaResource('alphabetAnim.gif').readAsBytes();
    expect(ui.instantiateImageCodec(data, null), 'Callback must be a function');
  });

  test('Fails with invalid data', () async {
    Uint8List data = new Uint8List.fromList([1, 2, 3]);
    Completer<ui.Codec> completer = new Completer<ui.Codec>();
    expect(ui.instantiateImageCodec(data, completer.complete), null);
    ui.Codec codec = await completer.future;
    expect(codec, null);
  });

  test('nextFrame fails when no callback provided', () async {
    Uint8List data = await _getSkiaResource('alphabetAnim.gif').readAsBytes();
    Completer<ui.Codec> completer = new Completer<ui.Codec>();
    expect(ui.instantiateImageCodec(data, completer.complete), null);
    ui.Codec codec = await completer.future;
    expect(codec.getNextFrame(null), 'Callback must be a function');
  });

  test('nextFrame', () async {
    Uint8List data = await _getSkiaResource('test640x479.gif').readAsBytes();
    Completer<ui.Codec> completer = new Completer<ui.Codec>();
    expect(ui.instantiateImageCodec(data, completer.complete), null);
    ui.Codec codec = await completer.future;
    List<List<int>> decodedFrameInfos = [];
    for (int i = 0; i < 5; i++) {
      Completer<ui.FrameInfo> frameCompleter = new Completer<ui.FrameInfo>();
      codec.getNextFrame(frameCompleter.complete);
      ui.FrameInfo frameInfo = await frameCompleter.future;
      decodedFrameInfos.add([
        frameInfo.durationMillis,
        frameInfo.image.width,
        frameInfo.image.height,
      ]);
    }
    expect(decodedFrameInfos, equals([
      [200, 640, 479],
      [200, 640, 479],
      [200, 640, 479],
      [200, 640, 479],
      [200, 640, 479],
    ]));
  });

  test('non animated image', () async {
    Uint8List data = await _getSkiaResource('baby_tux.png').readAsBytes();
    Completer<ui.Codec> completer = new Completer<ui.Codec>();
    expect(ui.instantiateImageCodec(data, completer.complete), null);
    ui.Codec codec = await completer.future;
    List<List<int>> decodedFrameInfos = [];
    for (int i = 0; i < 2; i++) {
      Completer<ui.FrameInfo> frameCompleter = new Completer<ui.FrameInfo>();
      codec.getNextFrame(frameCompleter.complete);
      ui.FrameInfo frameInfo = await frameCompleter.future;
      decodedFrameInfos.add([
        frameInfo.durationMillis,
        frameInfo.image.width,
        frameInfo.image.height,
      ]);
    }
    expect(decodedFrameInfos, equals([
      [0, 240, 246],
      [0, 240, 246],
    ]));
  });
}

/// Returns a File handle to a file in the skia/resources directory.
File _getSkiaResource(String fileName) {
  // As Platform.script is not working for flutter_tester
  // (https://github.com/flutter/flutter/issues/12847), this is currently
  // assuming the curent working directory is engine/src.
  // This is fragile and should be changed once the Platform.script issue is
  // resolved.
  String assetPath =
    path.join('third_party', 'skia', 'resources', fileName);
  return new File(assetPath);
}
