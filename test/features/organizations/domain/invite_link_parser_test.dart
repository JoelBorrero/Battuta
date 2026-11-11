import 'package:battuta/features/organizations/domain/services/invite_link_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const token =
      '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';

  group('parseInviteInput', () {
    test('reads battuta://join/<token>', () {
      expect(parseInviteInput('battuta://join/$token'), token);
      expect(parseInviteInput('BATTUTA://JOIN/$token'), token);
      expect(parseInviteInput('battuta://join/$token/'), token);
      expect(parseInviteInput('battuta:///join/$token'), token);
    });

    test('accepts a bare token and ignores surrounding whitespace', () {
      expect(parseInviteInput(token), token);
      expect(parseInviteInput('  \n$token\t '), token);
      expect(parseInviteInput('  battuta://join/$token  '), token);
    });

    test('rejects other schemes, hosts and free text', () {
      expect(parseInviteInput('https://example.com/join/$token'), isNull);
      expect(parseInviteInput('com.battuta.battuta://join/$token'), isNull);
      expect(parseInviteInput('battuta://login-callback/$token'), isNull);
      expect(parseInviteInput('battuta://join'), isNull);
      expect(parseInviteInput('battuta://join/'), isNull);
      expect(parseInviteInput('battuta://join/short'), isNull);
      expect(parseInviteInput('hello there'), isNull);
      expect(parseInviteInput('short'), isNull);
      expect(parseInviteInput(''), isNull);
      expect(parseInviteInput('   '), isNull);
      expect(parseInviteInput(null), isNull);
    });
  });

  test('inviteLinkFor round trips through the parser', () {
    final link = inviteLinkFor(token);
    expect(link, 'battuta://join/$token');
    expect(parseInviteInput(link), token);
    expect(inviteTokenFromUri(Uri.parse(link)), token);
  });

  test('inviteTokenFromUri ignores the auth callback', () {
    expect(
      inviteTokenFromUri(Uri.parse('battuta://login-callback#access_token=x')),
      isNull,
    );
  });
}
