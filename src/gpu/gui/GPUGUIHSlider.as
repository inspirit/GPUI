package gpu.gui 
{
	/**
     * ...
     * @author Eugene Zatepyakin
     */
    public class GPUGUIHSlider extends GPUGUIControl
    {
        protected var _min:Number;
        protected var _max:Number;
        protected var _value:Number;
        protected var _normValue:Number;

        protected var _drawBack:Boolean;

        internal var _bgColor:uint;
        internal var _darkColor:uint;
        internal var _lightColor:uint;

        internal var _label:GPUGUILabel;
        internal var _bg:GPUGUIFillRect;
        internal var _bgSlider:GPUGUIFillRect;
        internal var _bgValue:GPUGUIFillRect;

        internal var _paddX:Number;
        internal var _paddY:Number;

        public function GPUGUIHSlider(min:Number, max:Number, value:Number, options:Object)
        {
            options = parseOptions(options);

            name = options.label;

            _x = options.x;
            _y = options.y;
            _width = options.width;
            _height = options.height;

            _bgColor = options.bgColor;
            _lightColor = options.lightColor;
            _darkColor = options.darkColor;
            _paddX = GPUGUIStyle._paddX;
            _paddY = GPUGUIStyle._paddY;

            _min = min;
            _max = max;
            _value = value;
            _normValue = (value - min) / (max - min);

            _drawBack = options.drawBackground;
            options.drawBackground = false;

            if(_drawBack)
            {
                _bg = new GPUGUIFillRect(options);
                _bg.name = name + '_slider_bg';
            }

            if(name.length)
            {
                _label = new GPUGUILabel(name, options);
                _label.name = name + '_slider_label';
            }

            _bgSlider = new GPUGUIFillRect(options);
            _bgValue = new GPUGUIFillRect(options);

            _bgSlider.name = name + '_slider_bar';
            _bgValue.name = name + '_slider_value_bar';

            _dirty = 1 << 2;
            _dirty |= 1 << 4;
        }
        
        override public function onMouseDown(sx:int, sy:int):void
        {
            onMouseDrag(sx,  sy);
        }
        
        override public function onMouseDrag(sx:int, sy:int):void
        {
            // get norm value
            var val:Number = (sx - _act_left) / (_act_right - _act_left);
            // clamp
            var tmp:Number = Number(val < 1.0);
            val = val * tmp +(1.0 - tmp);
            //
            tmp = Number(val > 0.0);
            val = val * tmp;
            //
            // set norm value
            _normValue = val;
            // set real value
            val = _min + val * (_max - _min);
            _dirty |= int(val != _value) << 5;
            _value = val;
        }

        override public function setup(gui:GPUGUI):void
        {
            this.gui = gui;

            if(_drawBack)
            {
                _bg.setup(gui);
                _bg.color = _bgColor;
            }

            _bgSlider.setup(gui);
            _bgValue.setup(gui);

            _bgSlider.color = _darkColor;
            _bgValue.color = _lightColor;

            // add label now so it will render above
            if(_label)
            {
                _label.setup(gui);
            }
        }
        override public function updateBatch(vertices:Vector.<Number>, indices:Vector.<uint>):void
        {
            
            // verts update
            if (_dirty & 4)
            {
                _dirty &= ~(1 << 2);

                var offx:int = globalX,  offy:int = globalY;
                var label_off_y:int = 0;

                if(_label)
                {
                    _label.x = offx;
                    _label.y = offy;
                    label_off_y = _label.height + _paddY;

                    _label.updateBatch(vertices, indices);
                }

                // calc active area
                _act_left = offx;
                _act_top = offy + label_off_y;
                _act_right = _act_left + _width;
                _act_bottom = _act_top + _height;
                //

                if(_drawBack)
                {
                    _bg.x = offx - _paddX;
                    _bg.y = offy - _paddY;
                    _bg.width = _width + _paddX*2;
                    _bg.height = _height + label_off_y + _paddY*2;

                    _bg.updateBatch(vertices, indices);
                }

                _bgSlider.x = _act_left;
                _bgSlider.y = _act_top;
                _bgSlider.width = _width;
                _bgSlider.height = _height;

                _bgValue.x = _act_left;
                _bgValue.y = _act_top;
                _bgValue.width = _width * _normValue;
                _bgValue.height = _height;

                _bgSlider.updateBatch(vertices, indices);
                _bgValue.updateBatch(vertices, indices);
                
                // let gui know we need reupload
                gui._dirty |= 1 << 2;
            }
            
            // if value updated
            if (_dirty & 32)
            {
                _dirty &= ~(1 << 5);

                _bgValue.width = _width * _normValue;
                _bgValue.updateBatch(vertices, indices);

                gui._dirty |= 1 << 2;

                // callback
                if(null != _target)
                {
                    _target[_property] = _value;
                }
                else if(null != _callback)
                {
                    _callback.apply(null, [_value]);
                }
            }
            
            // rgba update
            if (_dirty & 16)
            {
                _dirty &= ~(1 << 4);

                if(_drawBack)
                {
                    _bg.color = _bgColor;
                    _bg.updateBatch(vertices,indices);
                }

                _bgSlider.color = _darkColor;
                _bgValue.color = _lightColor;

                _bgSlider.updateBatch(vertices,indices);
                _bgValue.updateBatch(vertices,indices);
                
                // let gui know we need reupload
                gui._dirty |= 1 << 2;
            }
        }

        public function get value():Number { return _value; }
        public function set value(value:Number):void
        {
            _dirty |= int(value != _value) << 5;

            _value = value;
            _normValue = (value - _min) / (_max - _min);
        }

        public function get normalizedValue():Number { return _normValue; }
        public function set normalizedValue(value:Number):void
        {
            _normValue = value;
            value = _min + value * (_max - _min);
            _dirty |= int(value != _value) << 5;
            _value = value;
        }

        public function get bgColor():uint { return _bgColor; }
        public function set bgColor(value:uint):void
        {
            _dirty |= int(value != _bgColor) << 4;
            _bgColor = value;
        }

        public function get darkColor():uint { return _darkColor; }
        public function set darkColor(value:uint):void
        {
            _dirty |= int(value != _darkColor) << 4;
            _darkColor = value;
        }

        public function get lightColor():uint{ return _lightColor; }
        public function set lightColor(value:uint):void
        {
            _dirty |= int(value != _lightColor) << 4;
            _lightColor = value;
        }
    }

}