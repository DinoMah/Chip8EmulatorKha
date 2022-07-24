package;

import kha.input.KeyCode;

class Keyboard {
    public var _keymap: Map<Int, Int>;
    public var _keysPressed: Array<Bool>;
    public var _onNextKeyPress: KeyCode->Void;

    public function new() {
        _keymap = new Map<Int, Int>();
        _keymap[49] = 0x1;
        _keymap[50] = 0x2;
        _keymap[51] = 0x3;
        _keymap[52] = 0xC;
        _keymap[81] = 0x4;
        _keymap[87] = 0x5;
        _keymap[69] = 0x6;
        _keymap[82] = 0xD;
        _keymap[65] = 0x7;
        _keymap[83] = 0x8;
        _keymap[68] = 0x9;
        _keymap[70] = 0xE;
        _keymap[90] = 0xA;
        _keymap[88] = 0x0;
        _keymap[67] = 0xB;
        _keymap[86] = 0xF;

        _keysPressed = new Array<Bool>();

        _onNextKeyPress = null;

        kha.input.Keyboard.get().notify(onKeyDown, onKeyUp);
    }

    public function isKeyPressed(keyCode: KeyCode): Bool {
        return _keysPressed[keyCode];
    }

    public function onKeyDown(key: KeyCode) {
        var keyPressed = this._keymap[key];
        _keysPressed[keyPressed] = true;

        if (_onNextKeyPress != null && keyPressed != null) {
            _onNextKeyPress(cast(keyPressed, KeyCode));
            _onNextKeyPress = null;
        }
    }

    public function onKeyUp(key: KeyCode) {
        var keyPressed = _keymap[key];
        _keysPressed[keyPressed] = false;
    }
}