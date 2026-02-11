import 'package:flutter/foundation.dart';

import 'package:rpi_eyes/app/core/enums.dart';

class EmotionController extends ChangeNotifier {
  EmotionController([this._emotion = Emotion.idle]);

  Emotion _emotion;

  Emotion get emotion => _emotion;

  set emotion(Emotion value) {
    if (_emotion != value) {
      _emotion = value;
      notifyListeners();
    }
  }

  void setEmotion(Emotion emotion) {
    this.emotion = emotion;
  }
}
