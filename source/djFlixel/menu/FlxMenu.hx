/**
 * FlxMenu
 * ==============
 * @author JohnDimi, twitter: @jondmt
 *
 * Very simple menu system, made for the FutureKnight game.
 * But customizable enough to use for other projects as well
 * 
 * -------------------------------------------------------
 * Features:
 * --------
 * 
 * . Easy menu creation and navigation
 * . Simple user callbacks, 
 * . Sliders
 * . Toggles
 * . Selecting one of many
 * 
 =============================================================*/

 
/**===========================
   = Use Examples:
   = ------------ 
   
	# Ask a question
	-----------------------------
	
	page = menu.addPage("delete");
	page.optionCallback = function(a:string,b:Dynamic){
		a:"ask_delete"
		b:0 for false, 1 for true
	}
	page.custom = { ask:"Delete save, are you sure?", sid:"ask_delete" };
   
	
	# Conditional Options
	------------------------------

	// If the condition parameter function returns TRUE the option will be displayed

	page.add("CondOption","link",{data:"@target",
					condition:function() { 
						return (Math.random() >=0.5);
					}
	});
	
	
	# onStatus
	-----------------
	tick  - Highlight selection changed
	back  - The menu went back a page
	enter - The menu entered a page
	select - An option was selected, or a question
	open - The menu was just opened
	close - The menu was just closed
	
	

----------------------------------------------------------------*/
package djFlixel.menu;

import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import djFlixel.menu.MenuData;
import openfl.display.InterpolationMethod;



// --
// Entry for the Page History queue
typedef HistoryState = 
{ 
	sid:String, 	// Page SID
	ind:Int			// Cursor Index
};


// -----
// All menu parameters to a class, so that it can be customized easily
// -----
class FlxMenuScheme
{
	// --
	// Default Values 
	
	public var font:String = null;	 // Font path, e.g. "assets\arial.ttf";
	public var fontSize(default, set):Int;    // Default font size
	
	// -- Colors
	public var color_def:Int 		= 0xFFE8E8E8;
	public var color_high:Int 		= 0xFFFFFF00;
	public var color_border:Int 	= 0xFF662244;
	public var color_secondary:Int	= 0xFFF5BB0A;
	public var color_header:Int  	= 0xFF0080FF;	// unused
	
	// -- Flags
	public var useBorder:Bool = true;
	public var useCursorAlpha:Bool = false;		// Mainly for cursor
	public var useTweenOption:Bool = true;	// Unused for now
	public var useTweenMenu:Bool = true;

	// Options Pad at fontSize, + this value
	public var padding_option_y:Int = 2;
	// Display all elements of a page in this much time.
	//  e.g. If it's 1 element, it will take 0.4 seconds to animate
	//		 If there are 3 elements, they will all appear in 0.4s , 0.4/3s for each one.
	public var timing_pageTotal:Float = 0.33;
	// Autogenerated
	// Where to start an element's y when animating in
	public var tweenOffset_Y:Int; // Autogenerated unless specified
	

	// How long the option will tween for
	public var optionHighlight_time:Float = 0.15;
	// How much on the x axis to position an option when highlighted
	public var optionHighlight_pad:Int;
	
	
	//---------------------------------------------------;	
	public function new() 
	{ 
		// By calling this, some values are autogenerated also
		fontSize = 16;
	}//---------------------------------------------------;
	// --
	public function set_fontSize(val:Int):Int
	{
		fontSize = val;
		tweenOffset_Y = Std.int(val / 3);
		optionHighlight_pad = Std.int(val * 0.33);
		return val;
	}//---------------------------------------------------;
	// --
	public function getStyledText(text:String):FlxText
	{
		var t = new FlxText(0, 0, 0, text, fontSize);
			if (font != null) t.font = font;
			if (useBorder)
			{
				t.borderColor = color_border;
				t.borderQuality = 1;
				t.borderStyle = FlxTextBorderStyle.SHADOW;
			}
		return t;
	}//---------------------------------------------------;
}//-------------------------------------------------------;


// --
// The main Object
// NOTE:
// Updates when visible.
class FlxMenu extends FlxGroup
{
	// World Coordinates to draw this menu to
	var pos_x:Float;
	var pos_y:Float;
	
	//---------------------------------------------------;
	// User set parameters

	// Simple callbacks triggering on menu changes.
	// callback ( SID of option , Value );
	// UNLESS: option is link and then it returns ("linkData","link");
	public var callback_option:String->Dynamic->Void = null;
	// Callback to handle sounds and other effects [tick,back,enter,error,open,close,select]
	public var onStatus:String->Void = null;
	// Add a Quick call to the callback
	public function __onStatus(s:String) { if (onStatus != null) onStatus(s); }
	
	// You can replace or modify the existing scheme
	public var scheme:FlxMenuScheme;	
	// -----
	
	
	// Store all the pages data here, (PageID->Pagedata);
	var hash_pages:Map<String,MenuPageData>;
	
	var isAnimating:Bool = false;
	var hasFocus:Bool = false;
	
	// Store the option elements
	var pageElements_options:Array<MenuOptionElement>;
	
	@:allow(djFlixel.menu.MenuOptionElement)
	var pageCurrent:MenuPageData = null;
	var pageTotalElements:Int;
	
	// What is the active highlighted option index in the pageElements_links array
	var pointIndex:Int;
	var pointIndex_last:Int;
	
	// Pointer to the currently selected menudata
	var optionCurrent:MenuOptionData;	
	
	// Store a simple page History
	var history:Array<HistoryState>;
	
	// -- Cursor Graphic is optional,
	// This is something that is placed beside the highlighted menu option
	var cursor:FlxSprite;
	var hasCursor:Bool = false;
	var tweenCursor:FlxTween;	// Keep the tween in case I want to cancel it
	//---------------------------------------------------;
	// When going back at menus, remember the pointer position
	var flag_keep_pointer_index:Bool = true;
	// Don't allow the cursor to move up or down
	var _flag_lock_vertical:Bool = false;

	
	//---------------------------------------------------;
	public function new(posX:Float = 0, posY:Float = 0) 
	{
		super();
		scheme = new FlxMenuScheme();
		pos_x = posX;
		pos_y = posY;
		hash_pages = new Map();
		pageElements_options = [];
		history = [];
	
		this.visible = false;
	}//---------------------------------------------------;
	
	// --
	override public function destroy():Void 
	{
		super.destroy();
		
		hash_pages = null;
		pageCurrent = null;
		
		if (pageElements_options != null)
		
		for (i in pageElements_options)
		{
			i.destroy();
			i = null;
		}
	
		pageElements_options = null;
		
		history = null;
		if (cursor != null) { cursor.destroy(); cursor = null; }
		
		if (tweenCursor != null) tweenCursor.destroy();
	
	}//---------------------------------------------------;
	
	
	// --
	// Because this is a FlxGroup, I am creating a custom
	public function setPos(x:Float, y:Float)
	{
		var deltaX = x - pos_x;
		var deltaY = y - pos_y;
		var spr:FlxSprite;
		
		for (i in members)
		{
			spr = cast i;
			spr.x += deltaX;
			spr.y += deltaY;
			spr.scrollFactor.set(0, 0);
		}
		
		pos_x = x;
		pos_y = y;
	}//---------------------------------------------------;
	
	// #OVERRIDABLE
	// If you want a different cursor
	public function createCursor(customString:String = ">")
	{
		var t = scheme.getStyledText(customString);
		t.color = scheme.color_high;
		cursor = t;
		hasCursor = true;
		cursor.visible = false;
		cursor.width = scheme.fontSize;
		cursor.cameras = [camera];
		cursor.scrollFactor.set(0, 0);
		add(cursor);
	}//---------------------------------------------------;
	
	// Set the menu cursor to be an flx sprite.
	// - Implying the font size is already set by now.
	// - Yoffset, fix the y positionin, until I can do this automatically
	public function createCursorUsingSprite(spr:FlxSprite,Yoffset:Int)
	{
		cursor = spr;
		
		cursor.offset.y = Yoffset;
		cursor.offset.x = cursor.width * 0.35;
		
		hasCursor = true;
		cursor.visible = false;
		cursor.cameras = [camera];
		cursor.scrollFactor.set(0, 0);
		add(cursor);
	}//---------------------------------------------------;
	

	/**
	 * Call this before a show() to force to show that menu
	 * Cleans history
	 */
	public function resetData()
	{
		history = [];
		pageCurrent = null;
		optionCurrent = null;
		hasFocus = false;
	}//---------------------------------------------------;
	
	// --
	// Shows a page and auto pushes the previous one to the history
	public function show(SID:String, ?IN_pointIndex:Int, ?onComplete:Void->Void)
	{		
		if (isAnimating) return; // Warn?
		
		// -- Don't go to the same page
		if (pageCurrent != null && pageCurrent.SID == SID) {
			trace('Warning: Requested to go to the same Page with SID=$SID.');
			return;
		}
		
		// -- Safeguard for null
		if (!hash_pages.exists(SID)) {
			trace('Error: Page with SID=$SID does not exist');
			return;
		}
		
		// -- Delete, fadeout, Previous elements
		for (i in pageElements_options) {
			remove(i.group);
			i.destroy(); i = null;
		}
		pageElements_options = [];
			
		// --
		// Push the current point index to the history
		if (flag_keep_pointer_index && history.length > 0) {
			history[history.length - 1].ind = pointIndex;
		}

		
		// -- Get new page data
		pageCurrent = hash_pages.get(SID);
		isAnimating = true;
		hasFocus = false;
		
		if (hasCursor) 
		{
			cursor.visible = false;
		}
	
		if (IN_pointIndex != null)
		{
			pointIndex = IN_pointIndex;
		}
		else 
		{
			pointIndex = 0;
		}
		
		pointIndex_last = -1;
		
		var quickAddOption = function(optData:MenuOptionData) {
			pageElements_options.push(_createOptionElement(optData));
		};

		// -- Special occation, create a question menu.
		// - -This is a dumb hacky way, but it works.. :-/
		var isQuestion:Bool = false;
		if (pageCurrent.custom != null)
		if (pageCurrent.custom.ask != null)
		if (pageCurrent.custom.sid != null)
		{
			_flag_lock_vertical = true;
			pointIndex = 1;
			isQuestion = true;
			
			// Add a question type menu
			quickAddOption( new MenuOptionData(cast pageCurrent.custom.ask));
			
			// And the slave
			var mm = new MenuOptionData("");
				mm.SID = pageCurrent.custom.sid;
				mm.slave.type = "oneof";
				mm.slave.pool = ["yes", "no"];
				mm.slave.current = 1;
				
			quickAddOption(mm);
			
			// Modify the "oneof" option a bit to make it question type
			var opt:MenuOption_OneOf = cast pageElements_options[pageElements_options.length - 1];
			opt.flag_question_mode = true;
			if (pageCurrent.custom.autoclose != null)
			opt.flag_question_autoclose = pageCurrent.custom.autoclose;
			
		}// ------------- end question
		
		// -- Add all the page options data as flixel objects
		for (i in pageCurrent.collection) 
		{
			if (i.conditional != null)
			{
				if (i.conditional())
					quickAddOption(i);
			}else
			{
				quickAddOption(i);
			}
		}//---------------------------------------------------;
	
		
		pageTotalElements = pageElements_options.length;
		
		//--  Add and animate the elements
		var delayTime:Float = scheme.timing_pageTotal / pageTotalElements;
		var transitionTime:Float = delayTime * 0.5;	//#param
		var next_y_start:Float = pos_y;
		var cc:Int = 0;
		for (i in pageElements_options)
		{
			i.group.setPosition(pos_x, next_y_start);
			
			if (scheme.useTweenMenu)
			{
				i.group.y -= scheme.tweenOffset_Y;
				i.group.alpha = 0.001;
				FlxTween.tween(	i.group, { alpha:1, y:i.group.y + scheme.tweenOffset_Y }, 
								transitionTime, { type:FlxTween.ONESHOT, startDelay:cc * delayTime } );
			}else
			{
				// i.group.x -= scheme.tweenOffset_Y;
				// FlxTween.tween(	i.group, { x:i.group.x + scheme.tweenOffset_Y }, 
				// transitionTime, { type:FlxTween.ONESHOT, startDelay:cc * delayTime*4 } );
			}
			
			i.group.scrollFactor.set(0, 0);
			i.group.cameras = [camera];
			add(i.group);
			
			cc++;
			
			// Todo: What if some elements are taller than fontSize?
			next_y_start += scheme.fontSize + scheme.padding_option_y;
		}
		

		// -- Because some options might be conditional
		// Check the pointer index
		if (pointIndex > pageTotalElements - 1) {
			pointIndex = pageTotalElements - 1;
		}
		
		// -- Push ALL HISTORY!
		history.push( { sid:pageCurrent.SID, ind:pointIndex } );

		// Auto set to visible
		if (visible == false)
		{
			visible = true;
			__onStatus("open");
		}
		
		// -- Finally when all elements tween in:
		
		var __onTweenComplete = function(e:FlxTimer) {
			isAnimating = false;
			if (!isQuestion) {
				focus();
			}else {
				hasFocus = true;
				pageElements_options[pointIndex].setHighlight(true);
				// Lock input to the second element
				// no cursor
			}
		};//--
		
		if (scheme.useTweenMenu) {
			new FlxTimer().start(cc * delayTime, __onTweenComplete);
		}else {	
			__onTweenComplete(null);
		}//--
		
	}//---------------------------------------------------;	
	
	
	// Search the index of an option with SID == sid
	public function getIndexOfOptionSID(sid:String):Int
	{
		var i = 0;
		for (i in 0...pageElements_options.length)
		{
			if (pageElements_options[i].opt.SID == sid)
			{
				return i;
			}
		}
		// Not found
		return -1;
	}//---------------------------------------------------;
	
	// --
	public function focus()
	{
		if (hasFocus) return;
		_flag_lock_vertical = false;
		hasFocus = true;
		if (pointIndex_last > -1)
		{
			pointIndex = pointIndex_last;
			pointIndex_last = -1;
		}
		updatePointerPos();
		if (hasCursor) cursor.visible = true;
	}//---------------------------------------------------;
	
	// --
	public function unfocus()
	{
		if (!hasFocus) return;
		hasFocus = false;
		pointIndex_last = pointIndex;
		pointIndex = -1;
		updatePointerPos();
		if (hasCursor) cursor.visible = false;
	}//---------------------------------------------------;
	
	
	// --
	// Go back one state in the history
	// NEW: does not send "back" status
	public function goBack()
	{
		if (history.length <= 1)
		{
			trace("Warning: Nowhere to go back to");
			// new: Send a menu back signal
			if (callback_option != null)
			{
				// Notify user that back was requested anyway
				callback_option("#back","");
			}
			return;
		}
		
		history.pop();	// The very last element is the current page, Skip it.
		
		var state = history.pop();
		show(state.sid, state.ind);
		
	}//---------------------------------------------------;
	

	// --
	// Just re-render the menu to update the cursor pointer
	function updatePointerPos()
	{
		if (pointIndex == pointIndex_last) return;
		
		// -- Turn of the previous option
		if (pointIndex_last >= 0)
		{
			FlxTween.tween(pageElements_options[pointIndex_last].group, { x:pos_x }, scheme.optionHighlight_time, { type:FlxTween.ONESHOT } );
			pageElements_options[pointIndex_last].setHighlight(false);
		}
		
		// -- Turn of the current option
		if (pointIndex >= 0)
		{
			FlxTween.tween(pageElements_options[pointIndex].group, { x:pos_x + scheme.optionHighlight_pad }, scheme.optionHighlight_time, { type:FlxTween.ONESHOT } );
			pageElements_options[pointIndex].setHighlight(true);
		}

		
		if (hasCursor && hasFocus) // # Position cursor
		{
			cursor.y = pageElements_options[pointIndex].group.y;
			cursor.x = pos_x - (cursor.width * 0.33) - scheme.optionHighlight_pad;
			
			if (scheme.useCursorAlpha)
			{
				cursor.alpha = 0.3;
			}
			
			if (tweenCursor != null)
			{
				tweenCursor.cancel();
			}
			
			tweenCursor = FlxTween.tween(cursor, { x:pos_x - scheme.optionHighlight_pad, alpha:1 }, scheme.optionHighlight_time, { type:FlxTween.ONESHOT } );
		}
		
		if (hasFocus)
		{
			optionCurrent = pageCurrent.collection[pointIndex];	// The indexes are the same
			pointIndex_last = pointIndex;
		}else
		{
			optionCurrent = null;
		}
	
	}//---------------------------------------------------;
	
	public function close()
	{
		unfocus();
		resetData();
		
		// Don't trigger events on precautionary close
		if (visible)
		{
			visible = false;
			__onStatus("close");
		}
	}//---------------------------------------------------;
	
	
	override public function update(elapsed:Float):Void 
	{
		super.update(elapsed);
		
		if (!hasFocus) return;
		if (!visible) return;
		
		if (Controls.CURSOR_START())
		{
			pageElements_options[pointIndex].pushControl("select");
		}else
		if (Controls.CURSOR_CANCEL())
		{
			__onStatus("back");	// devnote: Don't put the status inside goback()
			goBack();
		}
		else switch(Controls.CURSOR_DIR()) {
			case Controls.DOWN:
			if (_flag_lock_vertical) return;
			if (pointIndex < pageTotalElements - 1)
			{
				pointIndex_last = pointIndex;
				pointIndex++;
				updatePointerPos();
				__onStatus("tick");
			}
			case Controls.UP:
			if (_flag_lock_vertical) return;
			if (pointIndex > 0)
			{
				pointIndex_last = pointIndex;
				pointIndex--;
				updatePointerPos();
				__onStatus("tick");
				
			}
			case Controls.LEFT:
				pageElements_options[pointIndex].pushControl("left");
				/// TODO: if the slave rejects the key, handle the keypress on a function
			case Controls.RIGHT:
				pageElements_options[pointIndex].pushControl("right");
				/// TODO: if the slave rejects the key, handle the keypress on a function
		}
	}//---------------------------------------------------;
	
	
	// --
	// Create the proper SlaveObject depending on data type
	function _createOptionElement(option:MenuOptionData):MenuOptionElement
	{
		switch(option.slave.type)
		{
			case "link": return new MenuOption_Link(this, option);
			case "toggle": return new MenuOption_Toggle(this, option);
			case "slider": return new MenuOption_Slider(this, option);
			case "oneof": return new MenuOption_OneOf(this, option); 
		case null:
				trace("info: Creating Bare Option");
				var m = new MenuOptionElement(this, option);
				return m;
			//return 
			default: trace("Error: Invalid slave type"); return null;
		}
	}//---------------------------------------------------;
	
	// --
	// 
	public function addPage(pageSID:String, ?pageName:String):MenuPageData
	{
		var page = new MenuPageData(pageSID, pageName);
		
		// - Safeguard, check for duplicate
		#if debug
		if (hash_pages.exists(pageSID)) {
			trace('Error: Page with SID,$pageSID already exists');
		}
		#end
		
		hash_pages.set(pageSID, page);
		return page;
	}//---------------------------------------------------;
	
}// end --------------------------------------------------;




//====================================================;
// Menu Slave Controllers
//====================================================;

// --
// 
class MenuOption_OneOf extends MenuOptionElement
{
	var textArr:Array<FlxText>;
	var lastIndex:Int = -1;
	var total:Int;
	var activeColor:Int;

	
	// If true, it doesn't send events on change, 
	// but only at selection.
	public var flag_question_mode:Bool = false;
	// Go back if something is selected
	public var flag_question_autoclose:Bool = true;
	
	override public function destroy():Void 
	{
		super.destroy();
		textArr = null;
	}//---------------------------------------------------;
	
	override public function pushControl(control:String):Void 
	{
		if (!opt.isEnabled) return;
		
		if (control == "left")
		{
			if (opt.slave.current > 0)
			{
				lastIndex = cast opt.slave.current;
				opt.slave.current--;
				parentMenu.__onStatus("tick");
				if (!flag_question_mode) userCallback();
				update();
			}
		}else
		if (control == "right")
		{
			if (opt.slave.current < total - 1)
			{
				lastIndex = cast opt.slave.current;
				opt.slave.current++;
				parentMenu.__onStatus("tick");
				if (!flag_question_mode) userCallback();
				update();
			}
		}else
		if (control == "select")
		{
			if (flag_question_mode)
			{
				userCallback("select");
				if (flag_question_autoclose)
				parentMenu.goBack();
			}
		}
	}//---------------------------------------------------;
	// --
	override function createSlave():Void 
	{
		textArr = [];
		var p:Array<String> = cast opt.slave.pool;
		var lastwidth = 0.0;
		for (i in p)
		{
			var t = parentMenu.scheme.getStyledText(cast(i, String));
			t.color = parentMenu.scheme.color_def;
			t.x = slave_offset_x + lastwidth;
			lastwidth += t.width + 4;
			textArr.push(t);
			group.add(t);
		}
		
		lastIndex = cast opt.slave.current;
		total = cast opt.slave.pool.length;
		
		setHighlight(false);
	}//---------------------------------------------------;
	// --
	function update()
	{
		if (lastIndex > -1)
			textArr[lastIndex].color = parentMenu.scheme.color_def;
			
		textArr[Std.int(opt.slave.current)].color = activeColor;
	}//---------------------------------------------------;
	
	override public function setHighlight(state:Bool) 
	{
		super.setHighlight(state);
		
		//activeColor = parentMenu.scheme.color_high;
		// TO THINK ABOUT:
		
		if (state)
		{
			activeColor = parentMenu.scheme.color_high;
		}else
		{
			activeColor = parentMenu.scheme.color_secondary;
		}
		
		update();
	}//---------------------------------------------------;
	
}//-------------------------------------------------------;




// --
// 
class MenuOption_Slider extends MenuOptionElement
{
	var text:FlxText;
	
	override public function pushControl(control:String):Void 
	{
		if (!opt.isEnabled) return;
		
		if (control == "left")
		{
			if (Std.int(opt.slave.current) > Std.int(opt.slave.pool[0]))
			{
				opt.slave.current--;
				userCallback("tick");
				update();
			}
			
		}else
		if (control == "right")
		{
			if (Std.int(opt.slave.current) < Std.int(opt.slave.pool[1]))
			{
				opt.slave.current++;
				userCallback("tick");
				update();
			}
		}
		
	}//---------------------------------------------------;
	// --
	override function createSlave():Void 
	{
		text = parentMenu.scheme.getStyledText("");
		text.color = parentMenu.scheme.color_secondary;
		text.x = slave_offset_x;
		group.add(text);
		update();
	}//---------------------------------------------------;
	// --
	function update()
	{
		text.text = opt.slave.current;	
	}//---------------------------------------------------;
	
	override public function setHighlight(state:Bool) 
	{
		super.setHighlight(state);
		
		if (state)
		{
			text.color = parentMenu.scheme.color_high;
		}else
		{
			text.color = parentMenu.scheme.color_secondary;
		}
	}//---------------------------------------------------;
}//-------------------------------------------------------;






// --
// 
class MenuOption_Toggle extends MenuOptionElement
{
	var text:FlxText;
	
	override public function pushControl(control:String):Void
	{
		if (!opt.isEnabled) return;
		
		if (control == "select")
		{
			opt.slave.current = !opt.slave.current;
		} else
		
		if (control == "left")
		{
			// Avoid triggering a callback for the same value
			if (opt.slave.current == false) return;
			opt.slave.current = false;
		} else
		
		if (control == "right")
		{
			// Avoid triggering a callback for the same value
			if (opt.slave.current == true ) return;
			opt.slave.current = true;
		}
		
		userCallback("tick");
		update();
	}//---------------------------------------------------;
	// --
	override function createSlave():Void 
	{
		text = parentMenu.scheme.getStyledText("");
		text.color = parentMenu.scheme.color_secondary;
		text.x = slave_offset_x;
		group.add(text);
		update();
	}//---------------------------------------------------;
	// --
	function update()
	{
		if (opt.slave.current == false)
		{
			text.text = opt.slave.pool[0];
		}else
		{
			text.text = opt.slave.pool[1];
		}
		
	}//---------------------------------------------------;
	
	override public function setHighlight(state:Bool) 
	{
		super.setHighlight(state);
		
		if (state)
		{
			text.color = parentMenu.scheme.color_high;
		}else
		{
			text.color = parentMenu.scheme.color_secondary;
		}
	}//---------------------------------------------------;
}//-------------------------------------------------------;




// --
// 
class MenuOption_Link extends MenuOptionElement
{
	override public function pushControl(control:String):Void
	{
		if (!opt.isEnabled) return;
		if (control == "select") {
			var s:String = opt.slave.pool;
			// User Action			
			if (s.charAt(0) == "!")
			{	
				parentMenu.__onStatus("select");
				
				if (parentMenu.pageCurrent.optionCallback != null) 
				{
					parentMenu.pageCurrent.optionCallback(s, "link");
				}else 
				{
					if (parentMenu.callback_option != null) parentMenu.callback_option(s, "link");
				}
			}else
			// Go to another page
			if (s.charAt(0) == "@") {
				parentMenu.__onStatus("enter");
				parentMenu.show(s.substr(1));
			}else
			if (s == "#back")
			{
				parentMenu.__onStatus("back");
				parentMenu.goBack();
			}else
			{
				trace('Error: Unhandled link action($s)');
			}
		}
	}//---------------------------------------------------;
	override function createSlave():Void 
	{
		 //if (opt.slave.pool == "#back") return;
		 //var t = new FlxText(0, 0, 0, " ..", 8);
		 //t.color = parentMenu.scheme.color_def;
		 //t.alpha = 0.9;
		 //t.x += slave_offset_x;
		//group.add(t);
	}//---------------------------------------------------;
}//-------------------------------------------------------;



// --
// 
class MenuOptionElement
{
	// The slave portion starts at this X offset next to the label
	var slave_offset_x:Float;
	// Separetor for master and slave
	var option_separator:String = " .";
	// The lefthand label
	var masterText:FlxText;
	// A pointer to the parent menu system
	var parentMenu:FlxMenu;
	// --
	var isHighlighted:Bool;
	
	// A pointer to the slave data
	public var opt:MenuOptionData = null;
	
	// Holds all the elements
	public var group(default,null):FlxSpriteGroup;
	
	// Skip selecting this, if true
	// public var skip:Bool = false;
	
	public var height(default, null):Float;
	//----------------------------------------------------;

	// Constructor
	public function new(parent:FlxMenu, data:MenuOptionData)
	{
		parentMenu = parent;
		opt = data;
		group = new FlxSpriteGroup();
		
		isHighlighted = false;
		
		// The master label
		masterText = parent.scheme.getStyledText(data.label);
		if (parent.pageCurrent.custom != null)
		if (parent.pageCurrent.custom.fontsize != null)
		{
			masterText.size = cast parent.pageCurrent.custom.fontsize;
		}
		
		if (opt.slave.type != null && opt.slave.type != "link")
		{
			if (opt.label.length > 0)
				masterText.text += option_separator;
		}
		
		// Experiment, auto header text
		if (opt.slave.type == null)
		{
			masterText.color = parent.scheme.color_secondary;
		}else
		{
			masterText.color = parent.scheme.color_def;
		}
		
		slave_offset_x = masterText.width + 4;
		height = masterText.height;
		
		group.add(masterText);
		
		// ----
		createSlave();
	}//---------------------------------------------------;
	// Do some cleanup
	public function destroy():Void 
	{ 
		group.destroy();
		opt = null;
		parentMenu = null;
	}//---------------------------------------------------;
	
	// -- 
	// Called whenever this needs to be highlighted
	public function setHighlight(state:Bool) 
	{ 
		if (isHighlighted == state) return;
		
		isHighlighted = state;
		
		if (isHighlighted)
		{
			masterText.color = parentMenu.scheme.color_high;
		}
		else
		{
			masterText.color = parentMenu.scheme.color_def;
		}
	}//---------------------------------------------------;
	
	// Quick way to callback to user
	// Called whenever the slave option changes, and triggers
	// the use callback if present
	function userCallback(?status:String)
	{
		// also sound FX
		if (status != null) parentMenu.__onStatus(status);
		
		if (parentMenu.pageCurrent.optionCallback != null)
		{
			parentMenu.pageCurrent.optionCallback(opt.SID, opt.slave.current);
		}else
		if (parentMenu.callback_option != null)
		{
			parentMenu.callback_option(opt.SID, opt.slave.current);
		}
		
	}//---------------------------------------------------;
	
	// Create whatever you need, 
	function createSlave():Void { }; // #OVERRIDE THIS
	//----------------------------------------------------;
	// Trigger controls
	// ["select","left","right"], Note: only these 3 can be triggered
	public function pushControl(control:String):Void { } // #OVERRIDE THIS
	//----------------------------------------------------;
	
}//-------------------------------------------------------;