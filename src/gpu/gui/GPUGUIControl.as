package gpu.gui 
{
    import flash.events.TouchEvent;
    import flash.geom.Point;
    import flash.geom.Rectangle;

import gpu.gui.GPUGUIControl;
import gpu.gui.GPUGUI;

/**
     * ...
     * @author Eugene Zatepyakin
     */
    internal class GPUGUIControl
    {
        internal var next:GPUGUIControl;
        internal var prev:GPUGUIControl;
        
        protected var _x:int;
        protected var _y:int;
        protected var _width:int;
        protected var _height:int;
        
        // active zone
        internal var _act_top:int = 2048;
        internal var _act_bottom:int = -2048;
        internal var _act_left:int = 2048;
        internal var _act_right:int = -2048;

        // target object
        internal var _target:* = null;
        internal var _property:String = null;
        internal var _callback:Function = null;
        
        public var type:int;
        public var name:String = null;
        public var gui:GPUGUI = null;
        public var parent:GPUGUIControl = null;
        public var groupID:int = -1;
        
        internal var vertexOffset:int;
        internal var indexOffset:int;
        internal var numTriangles:int = 2;
        internal var numVertices:int = 4;
        
        internal var _dirty:int;
        
        public function GPUGUIControl()
        {
            //
        }

        public function setup(gui:GPUGUI):void
        {

        }

        public function updateBatch(vertices:Vector.<Number>, indices:Vector.<uint>):void
        {
            
        }

        public function setTarget(target:*, property:String):void
        {
            if(_target.hasOwnProperty(property))
            {
                _target = target;
                _property = property;
            }
        }
        public function setCallBack(callBack:Function):void
        {
            _callback = callBack;
        }

        public function dispose():void
        {
            // just unlink from render list
			var _prev:GPUGUIControl = this.prev;
			var _next:GPUGUIControl = this.next;
			_next.prev = _prev;
			_prev.next = _next;
			this.next = null;
			this.prev = null;
        }
        
        public function onMouseDown(sx:int, sy:int):void
        {
            //
        }
        public function onMouseDrag(sx:int, sy:int):void
        {
            //
        }
        public function onMouseUp(sx:int, sy:int):void
        {
            //
        }

        protected function parseOptions(options:Object):Object
        {
            var res:Object = {
                x:0, y:0, width:GPUGUIStyle._controlWidth, height:GPUGUIStyle._controlHeight,
                label:'', cornerRadius:GPUGUIStyle._cornerRadius, drawBackground:false, checked:false,
                sliderHeight:GPUGUIStyle._controlHeight, boxSize:GPUGUIStyle._controlHeight, numSegmentsPerCorner:0,
                numSegments:0, textColor:GPUGUIStyle._textColor,
                bgColor:GPUGUIStyle._bgColor, lightColor:GPUGUIStyle._lightColor,
                darkColor:GPUGUIStyle._darkColor
            };
            if(null != options)
            {
                for(var p:String in res)
                {
                    if(options.hasOwnProperty(p)) res[p] = options[p];
                }
            }

            return res;
        }

        public function get globalX():int { return _x + (parent ? parent.globalX : 0); }
        public function get globalY():int { return _y + (parent ? parent.globalY : 0); }

        public function get x():int { return _x; }
        public function set x(value:int):void 
        {
            _dirty |= int(value != _x) << 2;
            _x = value;
        }
        public function get y():int { return _y; }
        public function set y(value:int):void 
        {
            _dirty |= int(value != _y) << 2;
            _y = value;
        }
        public function get width():int { return _width; }
        public function set width(value:int):void 
        {
            _dirty |= int(value != _width) << 2;
            _width = value;
        }
        public function get height():int { return _height; }
        public function set height(value:int):void 
        {
            _dirty |= int(value != _height) << 2;
            _height = value;
        }
        
    }

}