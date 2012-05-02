package gpu.gui 
{
    import com.adobe.utils.AGALMiniAssembler;

import flash.display.BitmapData;
import flash.display.Stage;
    import flash.display3D.Context3D;
    import flash.display3D.Context3DBlendFactor;
    import flash.display3D.Context3DCompareMode;
    import flash.display3D.Context3DProgramType;
    import flash.display3D.Context3DVertexBufferFormat;
    import flash.display3D.IndexBuffer3D;
    import flash.display3D.Program3D;
    import flash.display3D.VertexBuffer3D;
import flash.events.MouseEvent;
import flash.geom.Rectangle;
import flash.geom.Rectangle;
import flash.text.AntiAliasType;
import flash.text.TextField;
    import flash.text.TextFormat;
	/**
     * ...
     * @author Eugene Zatepyakin
     */
    public final class GPUGUI
    {
        internal const FLOAT2_FORMAT:String = Context3DVertexBufferFormat.FLOAT_2;
        internal const FLOAT4_FORMAT:String = Context3DVertexBufferFormat.FLOAT_4;
        
        protected const VERTEX_TYPE:String = Context3DProgramType.VERTEX;
        protected const FRAGMENT_TYPE:String = Context3DProgramType.FRAGMENT;
        
        protected const DEFAULT_VERTEX_SHADER_CODE:String = "mov vt0, va0\n"+
                                                            "mul vt0.xy, vt0.xy, vc1.zw\n"+ // scale
                                                            "add vt0.xy, vt0.xy, vc1.xy\n"+ // translate
                                                            "mul vt0.xy, vt0.xy, vc0.xy\n"+ // map to -1.0 1.0
                                                            "add vt0.xy, vt0.xy, vc0.zw\n"+
                                                            "mov op, vt0\n"+
                                                            "mov v0, va1\n"+ // pass UV
                                                            "mov v1, va2"; // pass RGBA
        protected const TEXTURE_FRAGMENT_SHADER_CODE:String = "tex ft0, v0, fs0 <2d,linear,mipnone,clamp>\n"+
                                                              "mul oc, ft0, v1";
        
        internal var _stage:Stage;
        internal var _context:Context3D;
        internal var _viewRect:Rectangle;

        internal var _indexBuffer:IndexBuffer3D;
        internal var _vertexBuffer:VertexBuffer3D;

        protected var _program:Program3D;
        protected var _programParams:Vector.<Number>;

        // triangles indices
        internal var _indexData:Vector.<uint>;
        // x,y, u,v, r,g,b,a
        internal var _vertexData:Vector.<Number>;

        internal var _textureAtlas:GPUGUITextureAtlas;
        internal var _colorTextureRect:Rectangle;

        // basic transform
        internal var _dirty:int;
        internal var _x:Number = 0;
        internal var _y:Number = 0;
        internal var _scaleX:Number = 1;
        internal var _scaleY:Number = 1;

        protected var _controls:GPUGUIControl;
        
        public function GPUGUI(stage:Stage, context:Context3D, viewRect:Rectangle, textureAtlasSize:int = 512)
        {
            _stage = stage;
            _context = context;
            _viewRect = viewRect;
            
            _indexData = new Vector.<uint>();
            _vertexData = new Vector.<Number>();
            
            _indexBuffer = context.createIndexBuffer(6);
            _vertexBuffer = context.createVertexBuffer(4, 8); // x,y, u,v, r,g,b,a
            
            _controls = new GPUGUIControl();
            _controls.next = _controls;
            _controls.prev = _controls;

            _textureAtlas = new GPUGUITextureAtlas(textureAtlasSize, true, 0x0);
            _colorTextureRect = _textureAtlas.addBitmapData(new BitmapData(2, 2, false, 0xFFFFFF));
            _textureAtlas.uploadTexture(_context);
            _colorTextureRect.x *= _textureAtlas._step;
            _colorTextureRect.y *= _textureAtlas._step;
            _colorTextureRect.width *= _textureAtlas._step;
            _colorTextureRect.height *= _textureAtlas._step;

            // programs
            _program = _context.createProgram();
            var _asm:AGALMiniAssembler = new AGALMiniAssembler();
            _program.upload(_asm.assemble(VERTEX_TYPE, DEFAULT_VERTEX_SHADER_CODE), _asm.assemble(FRAGMENT_TYPE, TEXTURE_FRAGMENT_SHADER_CODE) );

            _programParams = new <Number>[2.0/viewRect.width, -2.0/viewRect.height, -1, 1,
                                          _x, _y, _scaleX, _scaleY];
            //
            // touch/mouse events
            setupMouseEvents();
        }

        public function setupMouseEvents():void
        {
            _stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
        }

        protected var _activeControl:GPUGUIControl;
        private function onMouseDown(e:MouseEvent):void
        {
            var chk:int;
            var head:GPUGUIControl = _controls;
            var node:GPUGUIControl = head.next;
            var px:int = e.stageX;
            var py:int = e.stageY;

            while(node != head)
            {
                chk = int(px < node._act_left)
                        | int(px > node._act_right)
                        | int(py < node._act_top)
                        | int(py > node._act_bottom);

                if(!chk)
                {
                    node.onMouseDown(px, py);
                    _activeControl = node;
                    _stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
                    _stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
                    break;
                }
                node = node.next;
            }
        }

        private function onMouseUp(e:MouseEvent):void
        {
            _stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
            _stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
            _activeControl.onMouseUp(e.stageX, e.stageY);
            _activeControl = null;
        }

        private function onMouseMove(e:MouseEvent):void
        {
            _activeControl.onMouseDrag(e.stageX, e.stageY);
        }
        
        public function draw():void
        {
            // init alpha blending
            _context.setBlendFactors(Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA);
            
            // update batch

            var head:GPUGUIControl = _controls;
            var node:GPUGUIControl = head.next;
            while(node != head)
            {
                if(node._dirty)
                {
                    node.updateBatch(_vertexData, _indexData);
                }
                node = node.next;
            }

            if (_dirty & 2)
            {
                _indexBuffer.dispose();
                _vertexBuffer.dispose();
                
                _indexBuffer = _context.createIndexBuffer(_indexData.length);
                _vertexBuffer = _context.createVertexBuffer(_vertexData.length / 8, 8);

                // we update it only on each component setup
                _indexBuffer.uploadFromVector(_indexData, 0, _indexData.length);
            }
            if (_dirty & 4)
            {
                _vertexBuffer.uploadFromVector(_vertexData, 0, _vertexData.length / 8);
            }

            _dirty = 0;
            
            // draw controls
            _context.setVertexBufferAt(0, _vertexBuffer, 0, FLOAT2_FORMAT);
            _context.setVertexBufferAt(1, _vertexBuffer, 2, FLOAT2_FORMAT);
            _context.setVertexBufferAt(2, _vertexBuffer, 4, FLOAT4_FORMAT);
            _context.setTextureAt(0, _textureAtlas._texture);
            _context.setProgram(_program);
            _context.setProgramConstantsFromVector(VERTEX_TYPE, 0, _programParams, 2);
            
            _context.drawTriangles(_indexBuffer, 0, _indexData.length / 3);
            //
            
            // reset
            _context.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
            _context.setTextureAt(0, null);
            _context.setVertexBufferAt(0, null, 0, FLOAT2_FORMAT);
            _context.setVertexBufferAt(1, null, 2, FLOAT2_FORMAT);
            _context.setVertexBufferAt(2, null, 4, FLOAT4_FORMAT);
        }

        public function addControl(control:GPUGUIControl):void
        {
            control.setup(this);
            //control.updateBatch(_vertexData, _indexData);

            // update textures if needed
            _textureAtlas.uploadTexture(_context);

            _dirty |= 1 << 1;
            _dirty |= 1 << 2;

            var prev:GPUGUIControl = _controls.prev;
			var next:GPUGUIControl = _controls;

			next.prev = control;
  			control.next = next;
			control.prev = prev;
			prev.next = control;
        }

        public function removeControl(control:GPUGUIControl):void
        {
            // remove from render list
            control.dispose();

            // force update all batches
            _vertexData.length = 0;
            _indexData.length = 0;

            var head:GPUGUIControl = _controls;
            var node:GPUGUIControl = head.next;
            while(node != head)
            {
                node.setup(this);
                node = node.next;
            }

            _dirty |= 1 << 1;
            _dirty |= 1 << 2;
        }
        
        public function dispose():void
        {
            _textureAtlas.dispose();
            _program.dispose();
            _vertexBuffer.dispose();
            _indexBuffer.dispose();
            _indexData.length = 0;
            _vertexData.length = 0;
        }

        public function get x():Number{return _x;}
        public function set x(value:Number):void
        {
            _x = value;
            _programParams[4] = value;
        }

        public function get y():Number{return _y;}
        public function set y(value:Number):void
        {
            _y = value;
            _programParams[5] = value;
        }

        public function get scaleX():Number{return _scaleX;}
        public function set scaleX(value:Number):void
        {
            _scaleX = value;
            _programParams[6] = value;
        }

        public function get scaleY():Number{return _scaleY;}
        public function set scaleY(value:Number):void
        {
            _scaleY = value;
            _programParams[7] = value;
        }
    }

}