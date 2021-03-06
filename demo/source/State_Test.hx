package ;
import djA.ArrayExecSync;
import djFlixel.D;
import djFlixel.gfx.BoxScroller;
import djFlixel.gfx.PanelPop;
import djFlixel.gfx.SpriteEffects;
import djFlixel.gfx.StaticNoise;
import djFlixel.gfx.TextScroller;
import djFlixel.gfx.TextBouncer;
import djFlixel.gfx.BoxFader;
import djFlixel.gfx.FilterFader;
import djFlixel.gfx.pal.Pal_CPCBoy;
import djFlixel.ui.UIButton;
import flash.display.BitmapData;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.math.FlxRect;
import flixel.system.FlxAssets;
import flixel.text.FlxText;
import lime.system.System;
import openfl.geom.Rectangle;


/** 
 * This state is for development-testing only
 */

class State_Test extends FlxState
{
	
	var upd:Void->Void;

	override public function create() 
	{
		super.create();
		
		bgColor = Pal_CPCBoy.COL[5];
		//sub_testPixelFader();
		//sub_testLetterBounce();
		//sub_testLetterScroll();
		//sub_staticNoise();
		//sub_spriteeffects();
		//sub_slice9();
		sub_panelpop();
		//sub_buttons();
	}//---------------------------------------------------
	
	override public function update(elapsed:Float):Void 
	{
		super.update(elapsed);
		if (upd != null) upd();
	}//---------------------------------------------------;
	
	function sub_buttons()
	{
		var b = new UIButton(64, 16, 64, 32);
		add(b);
		
		add(new UIButton(100, 64, 20, 20));
		add(new UIButton(132, 64, 20, 32));
	}//---------------------------------------------------;
	
	
	
	// OK WORKS
	function sub_panelpop()
	{
		var p = new PanelPop(200, 200);
		add(D.align.screen(p));
		p.start(()->{trace("first panel complete"); return; });
		add(D.align.screen(new PanelPop(52, 50,{colorBG:Pal_CPCBoy.COL[9]}).start(), 'l', 'b', 32));
		add(D.align.screen(new PanelPop(42, 90,{colorBG:Pal_CPCBoy.COL[9]}).start(), 'r', 't', 32));
	}//---------------------------------------------------;
	
	// OK WORKS
	function sub_slice9()
	{
		bgColor = Pal_CPCBoy.COL[5];
		
		var t = System.getTimer();
		var spr1:BitmapData = null;
		for (i in 0...500) {
			spr1 = D.bmu.scale9(D.ui.atlas.get_bn('panel'), new Rectangle(8, 8, 8, 8), 32 * 3, 32 * 3 ,true);
			spr1.floodFill(9, 9, 0xFF554433);
		}
		// Normal : ~260
		// No Center : ~140
		// No Center + flood : ~300
		trace("TIME :: " + (System.getTimer() - t));
		add(new FlxSprite(100, 64, spr1));
	}//---------------------------------------------------;
	
	
	// OK WORKS
	function sub_spriteeffects()
	{
		var effects = ['dissolve', 'wave', 'split', 'noiseline', 'noisebox', 'mask', 'blink'];
		var c = -1;
		var sp = new SpriteEffects('im/HAXELOGO.png');
		add(sp);
		add(D.text.get('Press [SPACE] to cycle between effects', 32, 220));
		var name:FlxText = cast add(D.text.get('', 32, 180, {c:Pal_CPCBoy.COL[7]}));
		
		upd = ()->{
			if (FlxG.keys.justPressed.SPACE)
			{
				if (++c >= effects.length) c = 0;
				sp.removeEffectID('all');
				trace("Adding effect" , effects[c]);
				name.text = effects[c];
				sp.addEffect(effects[c]);
			}
		}
	}//---------------------------------------------------;
	
	
	// OK WORKS
	function sub_staticNoise()
	{
		var st = new StaticNoise(20, 20, 90, 90);
		st.color_custom([0xFF334455, 0xFF998899]);
		add(st);
	}//---------------------------------------------------;

	// OK WORKS
	function sub_testLetterScroll()
	{
		var ts = new TextScroller("DJFLIXEL DEMO", 
			{f:'fnt/mozart.ttf', s:16, bc:Pal_CPCBoy.COL[2]},
			{y:100,speed:2,sHeight:8,w1:0.06,w0:4});
		add(ts);
	}//---------------------------------------------------;
	
	// OK WORKS
	function sub_testLetterBounce()
	{
		var lb = new TextBouncer("HELLO WORLD", 100, 200, {f:'fnt/mozart.ttf', s:16, bc:Pal_CPCBoy.COL[2]}, {time:2, timeL:0.5});
		add(lb);
		lb.start(()->{
			trace("Bounce complete");
			return;
		});
	}//---------------------------------------------------;
	
	// OK WORKS
	function sub_testPixelFader()
	{
		add(new FlxSprite("im/HAXELOGO.png"));
		var st = new FilterFader(false,()->{
			trace("Filter complete");
			return;
		});
	}//---------------------------------------------------;
	
}// --