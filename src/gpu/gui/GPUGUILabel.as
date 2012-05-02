package gpu.gui 
{
    import flash.display.BitmapData;
    import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.text.AntiAliasType;
import flash.text.Font;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.utils.Dictionary;

import gpu.gui.GPUGUILabel;

/**
     * ...
     * @author Eugene Zatepyakin
     */
    public final class GPUGUILabel extends GPUGUIControl
    {
        public static const TEXT_ALIGN_HORIZONTAL:String = 'horizontal';
        public static const TEXT_ALIGN_VERTICAL:String = 'vertical';

        internal static var _tf:TextField = new TextField();
        internal static var _labelCache:Dictionary = new Dictionary();
        {
            _tf.embedFonts = true;
            _tf.selectable = false;
            _tf.mouseEnabled = false;
            _tf.autoSize = 'left';
            _tf.textColor = 0xFFFFFF;
            _tf.defaultTextFormat = GPUGUIStyle.DEFAULT_TEXT_FORMAT;
        }
        
        public var textureRect:Rectangle;
        public var imgRect:Rectangle;

        protected var _drawBack:Boolean;

        internal var _text:String = '';
        internal var _textInvalid:Boolean = true;
        internal var _align:String = TEXT_ALIGN_HORIZONTAL;

        internal var _textColor:uint;
        internal var _bgColor:uint;
        internal var _paddX:Number;
        internal var _paddY:Number;
        internal var _bg:GPUGUIFillRect;

        public function GPUGUILabel(text:String, options:Object)
        {
            options = parseOptions(options);

            name = text;

            _text = text;
            // we dont have access to gui to create texture
            _textInvalid = true;
            
            numTriangles = 2;
            numVertices = 4;
            
            _x = options.x;
            _y = options.y;
            _width = options.width;
            _height = options.height;

            _textColor = options.textColor;
            _drawBack = options.drawBackground;
            _bgColor = options.bgColor;
            _paddX = GPUGUIStyle._paddX;
            _paddY = GPUGUIStyle._paddY;

            if(_drawBack)
            {
                _bg = new GPUGUIFillRect(options);
            }

            _dirty = 1 << 2;
            _dirty |= 1 << 3;
            _dirty |= 1 << 4;
        }

        public function get text():String {return _text;}
        public function set text(value:String):void
        {
            if(_text != value && null != gui)
            {
                _text = value;
                validateText();
            } else if(null == gui)
            {
                _text = value;
                _textInvalid = true;
            }
        }

        public function get textColor():uint {return _textColor;}
        public function set textColor(value:uint):void
        {
            _dirty |= int(_textColor != value) << 4;
            _textColor = value;
        }

        public function get align():String {return _align;}
        public function set align(value:String):void
        {
            _dirty |= int(_align != value) << 2;
            _align = value;
        }

        override public function setup(gui:GPUGUI):void
        {
            this.gui = gui;

            // first setup bg to draw text above it
            if(_drawBack)
            {
                _bg.setup(gui);
            }

            var vertices:Vector.<Number> = gui._vertexData;
            var indices:Vector.<uint> = gui._indexData;

            vertexOffset = vertices.length;
            indexOffset = indices.length;

            // enlarge data holders
            vertices.length += numVertices * 8; // x,y, u,v, r,g,b,a
            indices.length += numTriangles * 3;

            var off_tri:int;
            var off_ver:int;

            // indices update
            off_tri = indexOffset;
            off_ver = vertexOffset / 8; // number of points
            indices[off_tri++] = off_ver + 2;
            indices[off_tri++] = off_ver + 1;
            indices[off_tri++] = off_ver + 0;
            indices[off_tri++] = off_ver + 3;
            indices[off_tri++] = off_ver + 2;
            indices[off_tri++] = off_ver + 0;

            if(_textInvalid)
            {
                validateText();
            }
        }

        override public function updateBatch(vertices:Vector.<Number>, indices:Vector.<uint>):void
        {
            var off_ver:int;
            
            // verts update
            if (_dirty & 4)
            {
                _dirty &= ~(1 << 2);

                var _tlx:Number, _tly:Number, _trx:Number, _try:Number;
                var _blx:Number, _bly:Number, _brx:Number, _bry:Number;

                var offx:int = globalX,  offy:int = globalY;

                if(_drawBack)
                {
                    if(_align == TEXT_ALIGN_HORIZONTAL)
                    {
                        _bg.x = offx - _paddX;
                        _bg.y = offy - _paddY;
                        _bg.width = _width + _paddX*2;
                        _bg.height = _height + _paddY*2;
                    } else {
                        _bg.x = offx - _paddY;
                        _bg.y = offy - _width - _paddX;
                        _bg.width = _height + _paddY*2;
                        _bg.height = _width + _paddX*2;
                    }

                    _bg.updateBatch(vertices, indices);
                }

                
                off_ver = vertexOffset;
                if(_align == TEXT_ALIGN_HORIZONTAL)
                {
                    _tlx = offx;
                    _tly = offy;
                    _trx = offx + _width;
                    _try = _tly;
                    _brx = _trx;
                    _bry = offy + _height;
                    _blx = _tlx;
                    _bly = _bry;
                }
                else
                {
                    _tlx = offx;
                    _tly = offy;
                    _trx = offx;
                    _try = offy - _width;
                    _brx = offx + _height;
                    _bry = offy - _width;
                    _blx = offx + _height;
                    _bly = offy;
                }

                vertices[off_ver++] = _tlx;
                vertices[off_ver++] = _tly;
                off_ver += 6;
                vertices[off_ver++] = _trx;
                vertices[off_ver++] = _try;
                off_ver += 6;
                vertices[off_ver++] = _brx;
                vertices[off_ver++] = _bry;
                off_ver += 6;
                vertices[off_ver++] = _blx;
                vertices[off_ver++] = _bly;
                
                gui._dirty |= 1 << 2;
            }
            
            // uv update
            if (_dirty & 8)
            {
                _dirty &= ~(1 << 3);

                var tx:Number = textureRect.x;
                var ty:Number = textureRect.y;
                var tw:Number = textureRect.width;
                var th:Number = textureRect.height;
                
                off_ver = vertexOffset + 2;
                
                vertices[off_ver++] = tx;
                vertices[off_ver++] = ty;
                off_ver += 6;
                vertices[off_ver++] = tx + tw;
                vertices[off_ver++] = ty;
                off_ver += 6;
                vertices[off_ver++] = tx + tw;
                vertices[off_ver++] = ty + th;
                off_ver += 6;
                vertices[off_ver++] = tx;
                vertices[off_ver++] = ty + th;
                
                gui._dirty |= 1 << 2;
            }

            // rgba update
            if (_dirty & 16)
            {
                _dirty &= ~(1 << 4);

                off_ver = vertexOffset + 4;

                var _a:Number, _r:Number, _g:Number, _b:Number;

                _a = ((_textColor >> 24) & 0xFF) / 255.0;
                _r = ((_textColor >> 16) & 0xFF) / 255.0;
                _g = ((_textColor >> 8) & 0xFF) / 255.0;
                _b = (_textColor & 0xFF) / 255.0;

                vertices[off_ver++] = _r;
                vertices[off_ver++] = _g;
                vertices[off_ver++] = _b;
                vertices[off_ver++] = _a;
                off_ver += 4;
                vertices[off_ver++] = _r;
                vertices[off_ver++] = _g;
                vertices[off_ver++] = _b;
                vertices[off_ver++] = _a;
                off_ver += 4;
                vertices[off_ver++] = _r;
                vertices[off_ver++] = _g;
                vertices[off_ver++] = _b;
                vertices[off_ver++] = _a;
                off_ver += 4;
                vertices[off_ver++] = _r;
                vertices[off_ver++] = _g;
                vertices[off_ver++] = _b;
                vertices[off_ver++] = _a;

                gui._dirty |= 1 << 2;
            }
        }

        protected function validateText():void
        {
            _textInvalid = false;
            var cache:Rectangle = _labelCache[_text];
            var texture_step:Number = gui._textureAtlas._step;

            if (!cache)
            {
                _tf.text = _text;

                var bnd:BitmapData = new BitmapData(_tf.width, _tf.height, true, 0x0);
                bnd.draw(_tf);
                var bounds:Rectangle = bnd.getColorBoundsRect(0xFFFFFFFF, 0x000000, false);

                var shot:BitmapData = new BitmapData(bounds.width+2, bounds.height+2, true, 0x0);
                bounds.x -= 1; bounds.y -= 1;
                bounds.width += 2; bounds.height += 2;
                shot.copyPixels(bnd, bounds, new Point(), null, null, true);

                imgRect = gui._textureAtlas.addBitmapData(shot);

                textureRect = new Rectangle();
                textureRect.x = imgRect.x * texture_step;
                textureRect.y = imgRect.y * texture_step;
                textureRect.width = shot.width * texture_step;
                textureRect.height = shot.height * texture_step;

                imgRect.width = _width = shot.width;
                imgRect.height = _height = shot.height;

                bnd.dispose();
                shot.dispose();

                _labelCache[_text] = imgRect;
            }
            else
            {
                imgRect = cache;

                textureRect = new Rectangle();
                textureRect.x = imgRect.x * texture_step;
                textureRect.y = imgRect.y * texture_step;
                textureRect.width = imgRect.width * texture_step;
                textureRect.height = imgRect.height * texture_step;

                _width = imgRect.width;
                _height = imgRect.height;
            }
        }

        internal static function updateTextFormat(textFormat:TextFormat,
                                                    embedFonts:Boolean = true,
                                                    textAntiAlis:String = AntiAliasType.NORMAL):void
        {
            _tf.embedFonts = embedFonts;
            _tf.selectable = false;
            _tf.mouseEnabled = false;
            _tf.autoSize = 'left';
            _tf.textColor = 0xFFFFFF;
            _tf.defaultTextFormat = textFormat;

            _tf.antiAliasType = textAntiAlis;
        }
        
    }

}