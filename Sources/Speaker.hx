package;

import kha.Sound;
import kha.audio1.Audio;
import kha.audio1.AudioChannel;

class Speaker {
    private var audioChannel: AudioChannel;

    public function new() {}

    public function play(sound: Sound) {
        audioChannel = Audio.play(sound, false);
    }

    public function stop() {
        if (audioChannel != null)
            audioChannel.stop();
    }

    public function pause() {
        audioChannel.pause();
    }
}