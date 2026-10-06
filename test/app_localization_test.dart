import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:word_tiles_flutter/services/app_localization.dart';
import 'package:word_tiles_flutter/services/game_storage.dart';
import 'package:word_tiles_flutter/services/level_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppLocalization unit tests', () {
    test('Maps device language codes correctly to game supported languages', () {
      expect(AppLocalization.codeToLanguage('de'), 'german');
      expect(AppLocalization.codeToLanguage('fr'), 'french');
      expect(AppLocalization.codeToLanguage('it'), 'italian');
      expect(AppLocalization.codeToLanguage('es'), 'spanish');
      expect(AppLocalization.codeToLanguage('pt'), 'portuguese');
      expect(AppLocalization.codeToLanguage('ru'), 'russian');
      expect(AppLocalization.codeToLanguage('tr'), 'turkish');
      expect(AppLocalization.codeToLanguage('en'), 'english');
    });

    test('Defaults unsupported or unknown language codes to english', () {
      expect(AppLocalization.codeToLanguage('vi'), 'english');
      expect(AppLocalization.codeToLanguage('zh'), 'english');
      expect(AppLocalization.codeToLanguage('ja'), 'english');
      expect(AppLocalization.codeToLanguage('ko'), 'english');
      expect(AppLocalization.codeToLanguage('unknown'), 'english');
    });

    test('Maps game languages back to ISO language codes', () {
      expect(AppLocalization.languageToCode('german'), 'de');
      expect(AppLocalization.languageToCode('french'), 'fr');
      expect(AppLocalization.languageToCode('italian'), 'it');
      expect(AppLocalization.languageToCode('spanish'), 'es');
      expect(AppLocalization.languageToCode('portuguese'), 'pt');
      expect(AppLocalization.languageToCode('russian'), 'ru');
      expect(AppLocalization.languageToCode('turkish'), 'tr');
      expect(AppLocalization.languageToCode('english'), 'en');
    });

    test('Translates keys across all 8 supported languages', () {
      for (final lang in LevelLoader.supportedLanguages) {
        expect(AppLocalization.tr('play', language: lang), isNotEmpty);
        expect(AppLocalization.tr('settings', language: lang), isNotEmpty);
        expect(AppLocalization.tr('music', language: lang), isNotEmpty);
        expect(AppLocalization.tr('sound', language: lang), isNotEmpty);
        expect(AppLocalization.tr('vibration', language: lang), isNotEmpty);
        expect(AppLocalization.tr('language', language: lang), isNotEmpty);
        expect(AppLocalization.tr('exit_title', language: lang), isNotEmpty);
        expect(AppLocalization.tr('exit_confirm', language: lang), isNotEmpty);
        expect(AppLocalization.tr('exit_reassurance', language: lang), isNotEmpty);
        expect(AppLocalization.tr('confirm', language: lang), isNotEmpty);
        expect(AppLocalization.tr('cancel', language: lang), isNotEmpty);
        expect(AppLocalization.tr('shop', language: lang), isNotEmpty);
        expect(AppLocalization.tr('level', language: lang), isNotEmpty);
      }
    });

    test('Formats arguments properly in translations', () {
      expect(AppLocalization.tr('level_n', args: [5], language: 'english'), 'Level 5');
      expect(AppLocalization.tr('level_n', args: [5], language: 'french'), 'Niveau 5');
      expect(AppLocalization.tr('level_n', args: [5], language: 'german'), 'Level 5');
      expect(AppLocalization.tr('level_n', args: [5], language: 'russian'), 'Уровень 5');
      expect(AppLocalization.tr('level_n', args: [5], language: 'turkish'), 'Seviye 5');
    });
  });

  group('GameStorage Language & Localization integration tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await GameStorage.init();
    });

    test('Initializes with supported language or detected language', () async {
      final lang = GameStorage.getSelectedLanguage();
      expect(LevelLoader.supportedLanguages.contains(lang), isTrue);
    });

    test('Changing language updates storage and notifies listeners', () async {
      String? notifiedLang;
      void listener() {
        notifiedLang = GameStorage.languageNotifier.value;
      }

      GameStorage.languageNotifier.addListener(listener);

      await GameStorage.setSelectedLanguage('german');
      expect(GameStorage.getSelectedLanguage(), 'german');
      expect(notifiedLang, 'german');

      await GameStorage.setSelectedLanguage('french');
      expect(GameStorage.getSelectedLanguage(), 'french');
      expect(notifiedLang, 'french');

      GameStorage.languageNotifier.removeListener(listener);
    });
  });
}
