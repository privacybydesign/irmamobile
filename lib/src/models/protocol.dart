enum Protocol {
  irma,
  openid4vp,
  openid4vci,
}

String? protocolToStringOptional(Protocol? protocol) {
  if (protocol == null) {
    return null;
  }
  return protocolToString(protocol);
}

String protocolToString(Protocol protocol) {
  return switch (protocol) {
    Protocol.irma => 'irma',
    Protocol.openid4vp => 'openid4vp',
    Protocol.openid4vci => 'openid4vci',
  };
}

Protocol stringToProtocol(String protocol) {
  return switch (protocol) {
    'irma' => Protocol.irma,
    'openid4vp' => Protocol.openid4vp,
    'openid4vci' => Protocol.openid4vci,
    _ => throw Exception('invalid protocol: $protocol'),
  };
}
