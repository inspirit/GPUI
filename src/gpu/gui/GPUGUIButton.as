package gpu.gui
{
    public class GPUGUIButton extends GPUGUIControl
    {
        protected var _pressed:Boolean;
        protected var _drawBack:Boolean;

        internal var _label:GPUGUILabel;
        internal var _bg:GPUGUIFillRect;
        internal var _bgFace:GPUGUIFillRect;

        internal var _textColor:uint;
        internal var _bgColor:uint;
        internal var _darkColor:uint;
        internal var _lightColor:uint;
        internal var _paddX:Number;
        internal var _paddY:Number;

        public function GPUGUIButton(options:Object)
        {
            options = parseOptions(options);

            name = options.label;

            _x = options.x;
            _y = options.y;
            _width = options.width;
            _height = options.height;

            _drawBack = options.drawBackground;
            _pressed = false;
            _textColor = options.textColor;
            _bgColor = options.bgColor;
            _darkColor = options.darkColor;
            _lightColor = options.lightColor;
            _paddX = GPUGUIStyle._paddX;
            _paddY = GPUGUIStyle._paddY;

            options.drawBackground = false;

            if(name.length)
            {
                _label = new GPUGUILabel(name, options);
            }

            _bgFace = new GPUGUIFillRect(options);

            if(_drawBack)
            {
                _bg = new GPUGUIFillRect(options);
            }

            _dirty = 1 << 2;
        }

        override public function onMouseDown(sx:int, sy:int):void
        {
            _pressed = true;
            _dirty |= 32;
        }
        override public function onMouseUp(sx:int, sy:int):void
        {
            _pressed = false;
            _dirty |= 32;
        }

        override public function setup(gui:GPUGUI):void
        {
            this.gui = gui;

            if(_drawBack)
            {
                _bg.setup(gui);
            }

            _bgFace.setup(gui);

            if(_label)
            {
                _label.setup(gui);

                // make sure label will fit
                _width = Math.max(_width, _label.width + _paddX*4);
                _height = Math.max(_height, _label.height + _paddY);
            }

            _bgFace.color = _darkColor;
        }

        override public function updateBatch(vertices:Vector.<Number>, indices:Vector.<uint>):void
        {

            if (_dirty & 4)
            {
                _dirty &= ~(1 << 2);

                var gx:int = globalX,  gy:int = globalY;

                if(_drawBack)
                {
                    _bg.x = gx - _paddX;
                    _bg.y = gy - _paddY;
                    _bg.width = _width + _paddX*2;
                    _bg.height = _height + _paddY*2;

                    _bg.updateBatch(vertices, indices);
                }

                // calc active area
                _act_left = gx;
                _act_top = gy;
                _act_right = _act_left + _width;
                _act_bottom = _act_top + _height;

                _bgFace.x = gx;
                _bgFace.y = gy;
                _bgFace.width = _width;
                _bgFace.height = _height;

                if(_label)
                {
                    _label.x = gx + (_width - _label.width) * 0.5 + 0.5;
                    _label.y = gy + (_height - _label.height) * 0.5 + 0.5;

                    _label.updateBatch(vertices, indices);
                }

                _bgFace.updateBatch(vertices, indices);

                gui._dirty |= 1 << 2;
            }

            if(_dirty & 32)
            {
                _dirty &= ~(1 << 5);

                _bgFace.color = _pressed ? _lightColor : _darkColor;
                _bgFace.updateBatch(vertices, indices);

                if(_label)
                {
                    _label.textColor = _pressed ? _darkColor : _textColor;
                    _label.updateBatch(vertices, indices);
                }

                gui._dirty |= 1 << 2;

                // callback
                if(null != _callback)
                {
                    _callback.apply(null, [_pressed]);
                }
            }
        }

    }
}
