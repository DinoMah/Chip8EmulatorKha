package;

import kha.graphics2.Graphics;
import kha.Color;

class Renderer {
    private static inline var _cols = 64;
    private static inline var _rows = 32;
    private static inline var _area = _cols * _rows;

    public var _scale: Int;

    private var _display: Array<Int> = [for (i in 0..._area) 0];

    public function new(scale: Int) {
        _scale = scale;
    }

    public function setPixel(x, y: Int): Bool {
        if (x > _cols) x -= _cols;
        else if (x < 0) x += _cols;

        if (y > _rows) y -= _rows;
        else if (y < 0) y += _rows;

        var pixelLoc = x + (y * _cols);

        _display[pixelLoc] ^= 1;

        return !((_display[pixelLoc] == 0) ? false : true);
    }

    public function clear() {
        _display = [for (i in 0..._area) 0];
    }

    public function render(graphics: Graphics) {
        clearScreen(graphics);

        for (i in 0..._area) {
            var x = (i % _cols) * _scale;
            var y = Math.floor(i / _cols) * _scale;

            if (_display[i] == 1) {
                graphics.color = Color.Cyan;
                graphics.fillRect(x, y, _scale, _scale);
            }
        }
    }

    private function clearScreen(graphics: Graphics) {
        graphics.clear(Color.Black);
    }

    public function testRender() {
        setPixel(0, 0);
        setPixel(5, 2);
    }
}