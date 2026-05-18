// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_lemonsqueezy_suppression.dart';

const _tracerName = 'dartastic_otel_libs_lemonsqueezy';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

/// Wraps any Lemon Squeezy v1 API call in a CLIENT span. The verb
/// in `resource.action` form (e.g. `checkouts.create`,
/// `subscriptions.update`) feeds the span name and
/// `lemonsqueezy.operation`.
Future<T> tracedLemonsqueezy<T>({
  required String resource,
  required String action,
  required Future<T> Function() invoke,
  String? storeId,
  String? subscriptionId,
  String? customerId,
  String? orderId,
}) async {
  if (lemonsqueezyInstrumentationSuppressed()) {
    return invoke();
  }
  final m = <String, Object>{
    'lemonsqueezy.resource': resource,
    'lemonsqueezy.action': action,
    'lemonsqueezy.operation': '$resource.$action',
  };
  if (storeId != null) m['lemonsqueezy.store.id'] = storeId;
  if (subscriptionId != null) {
    m['lemonsqueezy.subscription.id'] = subscriptionId;
  }
  if (customerId != null) m['lemonsqueezy.customer.id'] = customerId;
  if (orderId != null) m['lemonsqueezy.order.id'] = orderId;

  final span = _tracer().startSpan(
    'lemonsqueezy $resource.$action',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    return await invoke();
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
