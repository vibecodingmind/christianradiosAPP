import 'package:flutter_test/flutter_test.dart';
import 'package:christian_radios_app/core/models/station.dart';

void main() {
  group('Station Model Tests', () {
    test('fromJson deserializes station JSON correctly', () {
      final json = {
        'id': 'stn_1',
        'name': 'Gospel Light Radio',
        'slug': 'gospel-light',
        'tagline': 'Light for your path',
        'description': '24/7 Gospel Music and Ministry',
        'logoUrl': 'https://example.com/logo.png',
        'countryCode': 'US',
        'language': 'English',
        'genre': 'Gospel',
        'categoryId': 'cat_1',
        'streamUrl': 'https://example.com/stream.mp3',
        'backupStreamUrl': 'https://example.com/backup.mp3',
        'streamType': 'MP3',
        'isFeatured': true,
        'streamStatus': 'ONLINE',
        'playCount': 1500,
        'favoriteCount': 320,
        'accessType': 'FREE',
        'createdAt': '2026-01-01T00:00:00Z',
      };

      final station = Station.fromJson(json);

      expect(station.id, equals('stn_1'));
      expect(station.name, equals('Gospel Light Radio'));
      expect(station.isLive, isTrue);
      expect(station.isFree, isTrue);
      expect(station.isFeatured, isTrue);
    });

    test('fromJson reads nested country and alternate bitrate fields', () {
      final json = {
        'id': 'awr_1',
        'name': 'Radio Stereo Adventista',
        'genre': 'teaching',
        'format': 'mp3',
        'country': {'code': 'SV', 'name': 'El Salvador', 'flagEmoji': '🇸🇻'},
        'logoUrl': 'https://example.com/logo.png',
        'category': {'id': 'cat_awr', 'name': 'Adventist World Radios'},
        'streamUrl': 'https://example.com/stream.mp3',
        'bitrate': 128,
        'listenerCount': 755,
        'streamStatus': 'ONLINE',
        'isFeatured': true,
      };

      final station = Station.fromJson(json);
      expect(station.countryCode, 'SV');
      expect(station.countryName, 'El Salvador');
      expect(station.categoryId, 'cat_awr');
      expect(station.bitrateKbps, 128);
      expect(station.currentListenersCount, 755);
      expect(station.streamType, 'MP3');
      expect(station.locationLabel, contains('El Salvador'));
    });

    test('toJson serializes station correctly', () {
      const station = Station(
        id: 'stn_2',
        name: 'Praise FM',
        slug: 'praise-fm',
        description: 'Praise music',
        logoUrl: 'https://example.com/praise.png',
        countryCode: 'CA',
        language: 'English',
        genre: 'Praise',
        categoryId: 'cat_2',
        streamUrl: 'https://example.com/praise.mp3',
        streamType: 'MP3',
        isFeatured: false,
        streamStatus: 'OFFLINE',
        playCount: 50,
        favoriteCount: 10,
        createdAt: '2026-02-01T00:00:00Z',
      );

      final json = station.toJson();

      expect(json['id'], equals('stn_2'));
      expect(json['name'], equals('Praise FM'));
      expect(station.isLive, isFalse);
    });

    test('operator == compares station by id', () {
      const s1 = Station(
        id: '123',
        name: 'Station A',
        slug: 'a',
        description: '',
        logoUrl: '',
        countryCode: 'US',
        language: 'EN',
        genre: 'Gospel',
        categoryId: 'cat_1',
        streamUrl: 'http://stream',
        streamType: 'MP3',
        isFeatured: false,
        streamStatus: 'ONLINE',
        playCount: 0,
        favoriteCount: 0,
        createdAt: '',
      );

      const s2 = Station(
        id: '123',
        name: 'Station B',
        slug: 'b',
        description: '',
        logoUrl: '',
        countryCode: 'US',
        language: 'EN',
        genre: 'Gospel',
        categoryId: 'cat_1',
        streamUrl: 'http://stream2',
        streamType: 'MP3',
        isFeatured: false,
        streamStatus: 'ONLINE',
        playCount: 0,
        favoriteCount: 0,
        createdAt: '',
      );

      expect(s1, equals(s2));
    });
  });
}
