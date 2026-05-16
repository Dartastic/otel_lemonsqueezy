// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_lemonsqueezy/otel_lemonsqueezy.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_lemonsqueezy-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('checkouts.create records CLIENT span', () async {
    await tracedLemonsqueezy<String>(
      resource: 'checkouts',
      action: 'create',
      storeId: 'store-1',
      customerId: 'cus-1',
      invoke: () async => 'co-1',
    );
    final a = attrsOf(
      spans.findSpanByName('lemonsqueezy checkouts.create')!,
    );
    expect(a['lemonsqueezy.resource'], 'checkouts');
    expect(a['lemonsqueezy.action'], 'create');
    expect(a['lemonsqueezy.operation'], 'checkouts.create');
    expect(a['lemonsqueezy.store.id'], 'store-1');
    expect(a['lemonsqueezy.customer.id'], 'cus-1');
  });

  test('suppression skips spans', () async {
    await runWithoutLemonsqueezyInstrumentationAsync(() async {
      await tracedLemonsqueezy<String>(
        resource: 'checkouts',
        action: 'create',
        invoke: () async => 'c',
      );
    });
    expect(spans.findSpansStartingWith('lemonsqueezy '), isEmpty);
  });
}
