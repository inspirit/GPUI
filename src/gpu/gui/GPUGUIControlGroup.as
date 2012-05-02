package gpu.gui
{
    public final class GPUGUIControlGroup extends GPUGUIControl
    {
        internal var _controls:Vector.<GPUGUIControl>;
        internal var _numControls:int;

        public function GPUGUIControlGroup(x:int,  y:int, name:String = '')
        {
            _controls = new <GPUGUIControl>[];
            _numControls = 0;
            _dirty = 1<<6; // we always update groups

            this.x = x;
            this.y = y;

            this.name = name;
        }

        public function addControl(control:GPUGUIControl):void
        {
            _controls.push(control);
            control.parent = this;
            control._dirty |= 4;
            _numControls++;
        }

        public function removeControl(control:GPUGUIControl):void
        {
            var ind:int = _controls.indexOf(control);
            if(ind > -1)
            {
                _controls.splice(ind, 1);
                control.parent = null;
                _numControls--;
                updateActiveBounds();
            }
        }

        override public function setup(gui:GPUGUI):void
        {
            var n:int = _numControls;
            for(var i:int = 0; i < n; ++i)
            {
                _controls[i].setup(gui);
            }
        }

        override public function updateBatch(vertices:Vector.<Number>, indices:Vector.<uint>):void
        {
            var n:int = _numControls;
            var control:GPUGUIControl;
            var needUpdate:Boolean = false;
            for(var i:int = 0; i < n; ++i)
            {
                control = _controls[i];
                if(control._dirty)
                {
                    control.updateBatch(vertices, indices);
                    needUpdate = true;
                }
            }
            if(needUpdate) updateActiveBounds();
        }

        protected var _activeControl:GPUGUIControl;
        override public function onMouseDown(sx:int, sy:int):void
        {
            var n:int = _numControls;
            var control:GPUGUIControl;
            var chk:int;
            for(var i:int = 0; i < n; ++i)
            {
                control = _controls[i];
                chk = int(sx < control._act_left)
                        | int(sx > control._act_right)
                        | int(sy < control._act_top)
                        | int(sy > control._act_bottom);

                if(!chk)
                {
                    control.onMouseDown(sx,  sy);
                    _activeControl = control;
                    break;
                }
            }
        }
        override public function onMouseDrag(sx:int, sy:int):void
        {
            _activeControl.onMouseDrag(sx, sy);
        }
        override public function onMouseUp(sx:int, sy:int):void
        {
            if (_activeControl)
            {
                _activeControl.onMouseUp(sx, sy);
                _activeControl = null;
            }
        }

        internal function updateActiveBounds():void
        {
            var n:int = _numControls;
            var control:GPUGUIControl;
            _act_left = 2048;
            _act_right = -2048;
            _act_top = 2048;
            _act_bottom = -2048;
            for(var i:int = 0; i < n; ++i)
            {
                control = _controls[i];
                _act_left = Math.min(control._act_left, _act_left);
                _act_right = Math.max(control._act_right, _act_right);
                _act_top = Math.min(control._act_top, _act_top);
                _act_bottom = Math.max(control._act_bottom, _act_bottom);
            }
        }

        public function clearGroup():void
        {
            // in groups we dont have links inside
            // so simply clear vector
            _controls.length = 0;
            _numControls = 0;
        }

        override public function set x(value:int):void
        {
            if(value != _x)
            {
                var n:int = _numControls;
                for(var i:int = 0; i < n; ++i)
                {
                    _controls[i]._dirty |= 4;
                }
                _x = value;
            }
        }

        override public function set y(value:int):void
        {
            if(value != _y)
            {
                var n:int = _numControls;
                for(var i:int = 0; i < n; ++i)
                {
                    _controls[i]._dirty |= 4;
                }
                _y = value;
            }
        }
    }
}
