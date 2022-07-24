package;

import haxe.Exception;
import kha.Assets;
import kha.Framebuffer;
import kha.Scheduler;
import kha.System;

class Main {

	static inline var _scale = 20;
	
	private static var _renderer: Renderer;
	private static var _keyboard: Keyboard;
	private static var _speaker: Speaker;
	private static var _cpu: CPU;

	static function update(): Void {
		_cpu.cycle();
	}

	static function render(frames: Array<Framebuffer>): Void {
		var graphics = frames[0].g2;
		graphics.begin();
		// _renderer.testRender();
		_renderer.render(graphics);
		graphics.end();
	}

	public static function main() {
		System.start(
			{title: "Project", width: 64 * _scale, height: 32 * _scale}, 
			function (_) {
				_renderer = new Renderer(_scale);
				_keyboard  = new Keyboard();
				_speaker = new Speaker();
				_cpu  = new CPU(_renderer, _keyboard, _speaker);

				_cpu.loadSpritesIntoMemory();
				trace("Sprites loaded");

				_cpu.loadROM("C:\\Users\\dinoma\\Downloads\\Zero_Demo_[zeroZshadow,_2007].ch8");
				
				// Just loading everything is ok for small projects
				Assets.loadEverything(function () {
					// Avoid passing update/render directly,
					// so replacing them via code injection works
					Scheduler.addTimeTask(function () { update(); }, 0, 1000 / 120000);
					System.notifyOnFrames(function (frames) { render(frames); });
				});
			}
		);
	}
}
