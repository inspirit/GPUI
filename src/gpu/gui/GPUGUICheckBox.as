package gpu.gui
{
    public class GPUGUICheckBox extends GPUGUIControl
    {
        protected var _drawBack:Boolean;
        protected var _checked:Boolean;
        protected var _boxSize:int;

        internal var _label:GPUGUILabel;
        internal var _bg:GPUGUIFillRect;
        internal var _bgFace:GPUGUIFillRect;

        internal var _textColor:uint;
        internal var _bgColor:uint;
        internal var _darkColor:uint;
        internal var _lightColor:uint;
        internal var _paddX:Number;
        internal var _paddY:Number;

        public function GPUGUICheckBox(options:Object)
        {
            options = parseOptions(options);

            name = options.label;

            _x = options.x;
            _y = options.y;

            _height = (_boxSize = options.boxSize);
            _width = options.width;

            _drawBack = options.drawBackground;
            _checked = options.checked;
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
            _bgFace.color = _checked ? _lightColor : _darkColor;

            if(_drawBack)
            {
                _bg = new GPUGUIFillRect(options);
            }

            _dirty = 1 << 2;
        }

        public function get checked():Boolean {return _checked;}
        public function set checked(value:Boolean):void
        {
            _dirty |= int(_checked != value) << 5;
            _checked = value;
        }

        override public function onMouseDown(sx:int, sy:int):void
        {
            if(groupID > -1)
            {
                updateGroup();
            } else
            {
                _checked = !_checked;
                _dirty |= 32;
            }
        }

        protected function updateGroup():void
        {
            var id:int = groupID;
            if(null == parent)
            {
                var head:GPUGUIControl = this;
                var node:GPUGUIControl = head.next;
                while(node != head)
                {
                    if(node.groupID == id)
                    {
                        GPUGUICheckBox(node).checked = false;
                    }
                    node = node.next;
                }
            } else {
                var list:Vector.<GPUGUIControl> = GPUGUIControlGroup(parent)._controls;
                var n:int = GPUGUIControlGroup(parent)._numControls;
                for(var i:int = 0; i < n; ++i)
                {
                    var control:GPUGUIControl = list[i];
                    if(control.groupID == id)
                    {
                        GPUGUICheckBox(control).checked = false;
                    }
                }
            }
            checked = true;
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
                _height = _boxSize = Math.max(_boxSize, _label.height + _paddY);
                _width = Math.max(_width, _label.width + _boxSize + _paddX*3);
            }

            _bgFace.color = _darkColor;
        }

        override public function updateBatch(vertices:Vector.<Number>, indices:Vector.<uint>):void
        {

            if (_dirty & 4)
            {
                _dirty &= ~(1 << 2);

                var gx:int = globalX,  gy:int = globalY;

                // calc active area
                _act_left = gx;
                _act_top = gy;
                _act_right = _act_left + _boxSize;
                _act_bottom = _act_top + _boxSize;
                //

                if(_label)
                {
                    _label.x = gx + _boxSize + _paddX*2;
                    _label.y = gy + (_boxSize - _label.height) * 0.5 + 0.5;

                    _label.updateBatch(vertices, indices);
                }

                if(_drawBack)
                {
                    _bg.x = gx - _paddX;
                    _bg.y = gy - _paddY;
                    _bg.width = _width + _paddX*2;
                    _bg.height = _boxSize + _paddY*2;

                    _bg.updateBatch(vertices, indices);
                }

                _bgFace.x = gx;
                _bgFace.y = gy;
                _bgFace.width = _boxSize;
                _bgFace.height = _boxSize;

                _bgFace.updateBatch(vertices, indices);

                gui._dirty |= 1 << 2;
            }

            if(_dirty & 32)
            {
                _dirty &= ~(1 << 5);

                _bgFace.color = _checked ? _lightColor : _darkColor;

                _bgFace.updateBatch(vertices, indices);

                gui._dirty |= 1 << 2;

                // callback
                if(null != _target)
                {
                    _target[_property] = _checked;
                }
                else if(null != _callback)
                {
                    _callback.apply(null, [_checked]);
                }
            }
        }
    }
}
