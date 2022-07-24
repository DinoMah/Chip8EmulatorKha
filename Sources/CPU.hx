package;

import haxe.ds.Vector;
import sys.io.File;
import haxe.Exception;
import kha.Assets;
import kha.input.KeyCode;

class CPU {
    private var _renderer: Renderer;
    private var _keyboard: Keyboard;
    private var _speaker: Speaker;
    
    private var _memory: Vector<cpp.UInt8>;
    private var _v: Vector<cpp.UInt8>;
    private var _i: cpp.UInt16;
    private var _delayTimer: cpp.UInt8;
    private var _soundTimer: cpp.UInt8;
    private var _programCounter: cpp.UInt16;
    // There's a stack pointer (SP 8-bit) used for pointing the topmost item in the stack
    private var _stack: Array<cpp.UInt16>;
    private var _paused = false;
    private var _speed = 10;


    public function new(renderer: Renderer, keyboard: Keyboard, speaker: Speaker) {
        _renderer = renderer;
        _keyboard = keyboard;
        _speaker = speaker;
        _memory = new Vector<cpp.UInt8>(4096);
        _v = new Vector<cpp.UInt8>(16);
        _i = 0;
        _delayTimer = 0;
        _soundTimer = 0;
        _programCounter = 0x200;
        _stack = new Array<cpp.UInt16>();
    }

    public function loadSpritesIntoMemory() {
        var sprites = [
            0xF0, 0x90, 0x90, 0x90, 0xF0, // 0
            0x20, 0x60, 0x20, 0x20, 0x70, // 1
            0xF0, 0x10, 0xF0, 0x80, 0xF0, // 2
            0xF0, 0x10, 0xF0, 0x10, 0xF0, // 3
            0x90, 0x90, 0xF0, 0x10, 0x10, // 4
            0xF0, 0x80, 0xF0, 0x10, 0xF0, // 5
            0xF0, 0x80, 0xF0, 0x90, 0xF0, // 6
            0xF0, 0x10, 0x20, 0x40, 0x40, // 7
            0xF0, 0x90, 0xF0, 0x90, 0xF0, // 8
            0xF0, 0x90, 0xF0, 0x10, 0xF0, // 9
            0xF0, 0x90, 0xF0, 0x90, 0x90, // A
            0xE0, 0x90, 0xE0, 0x90, 0xE0, // B
            0xF0, 0x80, 0x80, 0x80, 0xF0, // C
            0xE0, 0x90, 0x90, 0x90, 0xE0, // D
            0xF0, 0x80, 0xF0, 0x80, 0xF0, // E
            0xF0, 0x80, 0xF0, 0x80, 0x80  // F
        ];

        for (i in 0...sprites.length) {
            _memory[i] = sprites[i];
        }
    }

    private function loadProgramIntoMemory(program: Array<cpp.UInt8>) {
        for (i in 0...program.length) {
            _memory[0x200 + i] = program[i];
        }
    }

    public function loadROM(romPath: String) { // Reading a file from disk
        var rom = File.read(romPath);
        rom.bigEndian = true;
        var program = new Array<cpp.UInt8>();
        trace("Init reading");
        
        try { while (!rom.eof()) program.push(rom.readByte()); }
        catch (_: Exception) {}

        trace("Reading finished");
        loadProgramIntoMemory(program);
        rom.close();
    }

    public function cycle() {
        if (!_paused) {

            // speed is how many instructions will be executed at every cycle
            for (i in 0..._speed) {
                var opcode = _memory[_programCounter] << 8 | _memory[_programCounter + 1];
                executeInstruction(opcode);
            }

            updateTimers();
        }

        playSound();
        //_renderer.render();
    }

    private function updateTimers() {
        if (_delayTimer > 0) _delayTimer -= 1;

        if (_soundTimer > 0) _soundTimer -= 1;
    }

    private function playSound() {
        if (_soundTimer > 0) _speaker.play(Assets.sounds.daybreaker64__retro_video_game_laser);
        else _speaker.stop();
    }

    private function executeInstruction(opcode: cpp.UInt16) {
        trace("Executing instruction: " + StringTools.hex(opcode, 4));
        _programCounter += 2;
        var x = (opcode & 0x0F00) >> 8;
        var y = (opcode & 0x00F0) >> 4;

        switch (opcode & 0xF000) {
            case 0x0000:
                switch (opcode) {
                    case 0x00E0: // Clears the display
                        _renderer.clear();
                    case 0x00EE: // Returns from the last subroutine
                        _programCounter = _stack.pop();
                }
            case 0x1000: // Set PC to the value stored in nnn
                _programCounter = opcode & 0xFFF;
            case 0x2000: // Increment SP to PC & save nnn to PC
                _stack.push(_programCounter);
                _programCounter = opcode & 0xFFF;
            case 0x3000: // Compares the value in Vx to kk (last byte of opcode), if equal skip the next instruction
                if (_v[x] == (opcode & 0xFF)) _programCounter += 2;
            case 0x4000: // The opposite to 0x3000
                if (_v[x] != (opcode & 0xFF)) _programCounter += 2;
            case 0x5000: // If Vx is equal to Vy skip the next instruction
                if (_v[x] == _v[y]) _programCounter += 2;
            case 0x6000: // Set value of Vx to kk
                _v[x] = opcode & 0xFF;
            case 0x7000: // Add kk to Vx
                _v[x] += opcode & 0xFF;
            case 0x8000:
                switch (opcode & 0xF) {
                    case 0x0:
                        _v[x] = _v[y];
                    case 0x1:
                        _v[x] |= _v[y];
                    case 0x2:
                        _v[x] &= _v[y];
                    case 0x3:
                        _v[x] ^= _v[y];
                    case 0x4:
                        var sum = _v[x] + _v[y];
                        _v[0xF] = 0;
                        if (sum > 0xFF) _v[0xF] = 1;
                        _v[x] = sum;
                    case 0x5:
                        _v[0xF] = 0;
                        if (_v[x] > _v[y]) _v[0xF] = 1;
                        _v[x] -= _v[y];
                    case 0x6:
                        _v[0xF] = _v[x] & 0x1;
                        _v[x] >>= 1;
                    case 0x7:
                        _v[0xF] = 0;
                        if (_v[y] > _v[x]) _v[0xF] = 1;
                        _v[x] = _v[y] - _v[x];
                    case 0xE:
                        _v[0xF] = _v[x] & 0x80;
                        _v[x] <<= 1;
                }
            case 0x9000:
                if (_v[x] != _v[y]) _programCounter += 2;
            case 0xA000:
                _i = opcode & 0xFFF;
            case 0xB000:
                _programCounter = (opcode & 0xFFF) + _v[0];
            case 0xC000:
                var rand = Math.floor(Math.random() * 0xFF);
                _v[x] = rand & (opcode & 0xFF);
            case 0xD000:
                trace("Drawing...");
                var width = 8;
                var height = opcode & 0xF;
                _v[0xF] = 0;

                for (row in 0...height) {
                    var sprite = _memory[_i + row];

                    for (col in 0...width) {
                        // If the bit (sprite) is not 0, render/erase the pixel
                        if ((sprite & 0x80) > 0)
                            // If setPixel returns 1, pixel was erased, set VF to 1
                            if (_renderer.setPixel(_v[x] + col, _v[y] + row)) _v[0xF] = 1;

                        // Shift the sprite left 1. This will move the next col/bit of the sprite
                        sprite <<= 1;
                    }
                }
            case 0xE000:
                switch (opcode & 0xFF) {
                    case 0x9E:
                        if (_keyboard.isKeyPressed(cast(_v[x], KeyCode))) _programCounter += 2;
                    case 0xA1:
                        if (!_keyboard.isKeyPressed(cast(_v[x], KeyCode))) _programCounter += 2;
                }
            case 0xF000:
                switch (opcode & 0xFF) {
                    case 0x07:
                        _v[x] = _delayTimer;
                    case 0x0A:
                        _paused = true;
                        _keyboard._onNextKeyPress = (key: KeyCode) -> {
                            _v[x] = key;
                            _paused = false;
                        }
                    case 0x15:
                        _delayTimer = _v[x];
                    case 0x18:
                        _soundTimer = _v[x];
                    case 0x1E:
                        _i = _v[x];
                    case 0x29:
                        _i = _v[x] * 5;
                    case 0x33:
                        _memory[_i] = Std.int(_v[x] / 100);
                        _memory[_i + 1] = Std.int((_v[x] % 100) / 10);
                        _memory[_i + 2] = Std.int(_v[x] % 10);
                    case 0x55:
                        for (reg in 0...x) {
                            _memory[_i + reg] = _v[reg];
                        }
                    case 0x65:
                        for (reg in 0...x) {
                            _v[reg] = _memory[_i + reg];
                        }
                }
            default:
                throw new Exception("Uknown code: " + opcode);
        }
    }
}