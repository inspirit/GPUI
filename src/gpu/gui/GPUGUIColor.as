package gpu.gui
{
    public class GPUGUIColor extends GPUGUIControl
    {
        public static const COLOR_TYPE_RGB:uint = 3;
        public static const COLOR_TYPE_RGBA:uint = 4;

        protected var _drawBack:Boolean;
        protected var _colorType:uint;
        protected var _sliderHeight:int;

        internal var _paddX:Number;
        internal var _paddY:Number;

        internal var _label:GPUGUILabel;
        internal var _bg:GPUGUIFillRect;
        internal var _redsl:GPUGUIHSlider;
        internal var _greensl:GPUGUIHSlider;
        internal var _bluesl:GPUGUIHSlider;
        internal var _alphasl:GPUGUIHSlider;

        internal var _rval:Number;
        internal var _gval:Number;
        internal var _bval:Number;
        internal var _aval:Number;

        internal var _value:uint;

        public function GPUGUIColor(value:uint, colorType:uint, options:Object)
        {
            options = parseOptions(options);

            _x = options.x;
            _y = options.y;
            _width = options.width;
            _sliderHeight = options.sliderHeight;
            _colorType = colorType;
            _drawBack = options.drawBackground;
            _paddX = GPUGUIStyle._paddX;
            _paddY = GPUGUIStyle._paddY;

            options.drawBackground = false;

            _value = value;

            name = options.label;

            if(name.length)
            {
                _label = new GPUGUILabel(name, options);
            }

            options.label = '';

            _rval = ((value >> 16) & 0xFF) / 255.0;
            _gval = ((value >> 8) & 0xFF) / 255.0;
            _bval = (value & 0xFF) / 255.0;
            _aval = 1.0;

            options.height = options.sliderHeight;
            _redsl = new GPUGUIHSlider(0, 1, _rval, options);
            _greensl = new GPUGUIHSlider(0, 1, _gval, options);
            _bluesl = new GPUGUIHSlider(0, 1, _bval, options);

            if(colorType == COLOR_TYPE_RGBA)
            {
                _aval = ((value >> 24) & 0xFF) / 255.0;
                _alphasl = new GPUGUIHSlider(0, 1, _aval, options);
            }

            if(_drawBack)
            {
                _bg = new GPUGUIFillRect(options);
            }

            _dirty = 1 << 2;
        }

        protected var _activeChannel:GPUGUIHSlider;
        override public function onMouseDown(sx:int, sy:int):void
        {
            // get norm value
            var val:Number = (sy - _act_top) / (_act_bottom - _act_top);
            var tmp:Number = Number(val < 1.0);
            val = val * tmp +(1.0 - tmp);
            tmp = Number(val > 0.0);
            val = val * tmp;
            var ind:int = val * _colorType;

            if(ind == 0)
            {
                _activeChannel = _redsl;
            } else if(ind == 1){
                _activeChannel = _greensl;
            } else if(ind == 2){
                _activeChannel = _bluesl;
            } else if(ind == 3){
                _activeChannel = _alphasl;
            }
            onMouseDrag(sx,  sy);
        }

        override public function onMouseDrag(sx:int, sy:int):void
        {
            _activeChannel.onMouseDrag(sx,  sy);
            _dirty |= _activeChannel._dirty & 32;
        }

        override public function setup(gui:GPUGUI):void
        {
            this.gui = gui;

            // add all components
            // correct order required

            if(_drawBack)
            {
                _bg.setup(gui);
            }

            _redsl.setup(gui);
            _greensl.setup(gui);
            _bluesl.setup(gui);

            if(_colorType == COLOR_TYPE_RGBA)
            {
                _alphasl.setup(gui);
            }

            if(_label) _label.setup(gui);
        }

        override public function updateBatch(vertices:Vector.<Number>, indices:Vector.<uint>):void
        {

            if (_dirty & 4)
            {
                _dirty &= ~(1 << 2);

                var gx:int = globalX,  gy:int = globalY;
                var label_off_y:int = 0;

                if(_label)
                {
                    _label.x = gx;
                    _label.y = gy;
                    label_off_y = _label.height + _paddY;
                }

                // calc active area
                _act_left = gx;
                _act_top = gy + label_off_y;
                _act_right = _act_left + _width;
                _act_bottom = _act_top + _sliderHeight*3 + _paddY*3;
                if(_colorType == COLOR_TYPE_RGBA)
                {
                    _act_bottom += _sliderHeight + _paddY;
                }
                //

                _height = _act_bottom - gy;

                if(_drawBack)
                {
                    _bg.x = gx - _paddX;
                    _bg.y = gy - _paddY;
                    _bg.width = _width + _paddX*2;
                    _bg.height = _sliderHeight*3 + label_off_y + _paddY*4;
                    if(_colorType == COLOR_TYPE_RGBA)
                    {
                        _bg.height += _sliderHeight + _paddY;
                    }

                    _height = _bg.height;
                }

                _redsl.x = _act_left;
                _greensl.x = _act_left;
                _bluesl.x = _act_left;

                _redsl.y = _act_top;
                _greensl.y = _redsl.y + _redsl.height + _paddY;
                _bluesl.y = _greensl.y + _greensl.height + _paddY;

                if(_colorType == COLOR_TYPE_RGBA)
                {
                    _alphasl.y = _bluesl.y + _bluesl.height + _paddY;
                    _alphasl.x = _act_left;
                }

                gui._dirty |= 1 << 2;

                if(_label && _label._dirty)
                {
                    _label.updateBatch(vertices, indices);
                }

                if(_bg && _bg._dirty)_bg.updateBatch(vertices, indices);
                if(_redsl._dirty)_redsl.updateBatch(vertices, indices);
                if(_greensl._dirty)_greensl.updateBatch(vertices, indices);
                if(_bluesl._dirty)_bluesl.updateBatch(vertices, indices);
                if(_alphasl && _alphasl._dirty)_alphasl.updateBatch(vertices, indices);
            }

            if (_dirty & 32)
            {
                _dirty &= ~(1 << 5);

                if(_redsl._dirty)_redsl.updateBatch(vertices, indices);
                if(_greensl._dirty)_greensl.updateBatch(vertices, indices);
                if(_bluesl._dirty)_bluesl.updateBatch(vertices, indices);

                gui._dirty |= 1 << 2;

                _rval = _redsl.value;
                _gval = _greensl.value;
                _bval = _bluesl.value;

                if(_colorType == COLOR_TYPE_RGBA)
                {
                    if(_alphasl._dirty)_alphasl.updateBatch(vertices, indices);

                    _aval = _alphasl.value;
                    _value = ((_aval*0xFF) << 24) | ((_rval*0xFF) << 16) | ((_gval*0xFF) << 8) | (_bval*0xFF);
                } else {
                    _value = ((_rval*0xFF) << 16) | ((_gval*0xFF) << 8) | (_bval*0xFF);
                }

                // callback
                if(null != _target)
                {
                    _target[_property] = _value;
                }
                else if(null != _callback)
                {
                    _callback.apply(null, [_value, _rval, _gval, _bval, _aval]);
                }
            }
        }

        public function get red():Number { return _rval;}
        public function set red(value:Number):void
        {
            _rval = value;
            _redsl.value = value;
            _dirty |= _redsl._dirty & 32;
        }

        public function get green():Number { return _gval; }
        public function set green(value:Number):void
        {
            _gval = value;
            _greensl.value = value;
            _dirty |= _greensl._dirty & 32;
        }

        public function get blue():Number { return _bval; }
        public function set blue(value:Number):void
        {
            _bval = value;
            _bluesl.value = value;
            _dirty |= _bluesl._dirty & 32;
        }

        public function get alpha():Number { return _aval; }
        public function set alpha(value:Number):void
        {
            _aval = value;
            if(_alphasl)
            {
                _alphasl.value = _aval;
                _dirty |= _alphasl._dirty & 32;
            }
        }
    }
}
