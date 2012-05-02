package gpu.gui
{
    public class GPUGUIFillRect extends GPUGUIControl
    {
        protected var _numSegmentsPerCorner:int;
        protected var _cornerRadius:Number;
        protected var _cornerRadius2:Number;
        protected var _precompRadiusOffset:Vector.<Number>;

        internal var _bgColor:uint;

        public function GPUGUIFillRect(options:Object)
        {
            options = parseOptions(options);

            if(options.cornerRadius > 0)
            {
                if( options.numSegmentsPerCorner <= 0 )
                {
                    options.numSegmentsPerCorner = options.cornerRadius * Math.PI * 2 / 4;
                }
                if( options.numSegmentsPerCorner < 2 ) options.numSegmentsPerCorner = 2;

                _numSegmentsPerCorner = options.numSegmentsPerCorner;
                _cornerRadius = options.cornerRadius;
                _cornerRadius2 = _cornerRadius*2;

                numTriangles = (_numSegmentsPerCorner+1) * 4;
                numVertices = (_numSegmentsPerCorner+1)*4+2;
            }
            else
            {
                _cornerRadius = 0;
                _cornerRadius2 = 0;

                numTriangles = 2;
                numVertices = 4;
            }

            _width = options.width;
            _height = options.height;
            _x = options.x;
            _y = options.y;

            _bgColor = options.bgColor;

            _dirty = 1 << 2;
            _dirty |= 1 << 4;
        }

        public function get color():uint { return _bgColor; }
        public function set color(value:uint):void
        {
            _dirty |= int(value != _bgColor) << 4;
            _bgColor = value;
        }

        override public function setup(gui:GPUGUI):void
        {
            this.gui = gui;
            var vertices:Vector.<Number> = gui._vertexData;
            var indices:Vector.<uint> = gui._indexData;

            vertexOffset = vertices.length;
            indexOffset = indices.length;

            // enlarge data holders
            vertices.length += numVertices * 8; // x,y, u,v, r,g,b,a
            indices.length += numTriangles * 3;

            var off_tri:int;
            var off_ver:int;
            var tx:Number;
            var ty:Number;

            if(_cornerRadius == 0)
            {
                // indices update
                off_tri = indexOffset;
                off_ver = vertexOffset / 8; // number of points
                indices[off_tri++] = off_ver + 2;
                indices[off_tri++] = off_ver + 1;
                indices[off_tri++] = off_ver + 0;
                indices[off_tri++] = off_ver + 3;
                indices[off_tri++] = off_ver + 2;
                indices[off_tri++] = off_ver + 0;

                // uv update
                tx = gui._colorTextureRect.x;
                ty = gui._colorTextureRect.y;

                off_ver = vertexOffset + 2;

                vertices[off_ver++] = tx;
                vertices[off_ver++] = ty;
                off_ver += 6;
                vertices[off_ver++] = tx;
                vertices[off_ver++] = ty;
                off_ver += 6;
                vertices[off_ver++] = tx;
                vertices[off_ver++] = ty;
                off_ver += 6;
                vertices[off_ver++] = tx;
                vertices[off_ver++] = ty;
            }
            else
            {
                off_tri = indexOffset;
                off_ver = vertexOffset / 8; // number of points
                var i:int, j:int;

                for (i = 0; i < numTriangles; ++i)
                {
                    indices[off_tri++] = off_ver+0;
                    indices[off_tri++] = off_ver+i+1;
                    indices[off_tri++] = off_ver+i+2;
                }

                // uv update
                tx = gui._colorTextureRect.x;
                ty = gui._colorTextureRect.y;

                off_ver = vertexOffset;

                _precompRadiusOffset = new Vector.<Number>((_numSegmentsPerCorner+1)*2*4, true);

                const angleDelta:Number = 1. / _numSegmentsPerCorner * Math.PI / 2.;
                const rx2:Number = _x + _width;
                const ry2:Number = _y + _height;
                const rx1:Number = _x;
                const ry1:Number = _y;
                const cornerCenterVerts:Vector.<Number> = new <Number>[
                                    rx2 - _cornerRadius, ry2 - _cornerRadius,
                                    rx1 + _cornerRadius, ry2 - _cornerRadius,
                                    rx1 + _cornerRadius, ry1 + _cornerRadius,
                                    rx2 - _cornerRadius, ry1 + _cornerRadius];

                vertices[off_ver++] = _x + _width * 0.5;
                vertices[off_ver++] = _y + _height * 0.5;
                vertices[off_ver++] = tx;
                vertices[off_ver++] = ty;
                off_ver += 4;

                var off_ind:int = 0;
                for( i = 0; i < 4; ++i )
                {
                    var angle:Number = Number(i) * Math.PI / 2.0;
                    var cx:Number = cornerCenterVerts[i*2];
                    var cy:Number = cornerCenterVerts[i*2+1];
                    for( j = 0; j <= _numSegmentsPerCorner; ++j )
                    {
                        const cos:Number = Math.cos(angle);
                        const sin:Number = Math.sin(angle);
                        vertices[off_ver++] = cx + cos * _cornerRadius;
                        vertices[off_ver++] = cy + sin * _cornerRadius;
                        vertices[off_ver++] = tx;
                        vertices[off_ver++] = ty;

                        off_ver += 4;

                        _precompRadiusOffset[off_ind++] = cos;
                        _precompRadiusOffset[off_ind++] = sin;

                        angle += angleDelta;
                    }
                }

                vertices[off_ver++] = rx2;
	            vertices[off_ver++] = ry2 - _cornerRadius;
                vertices[off_ver++] = tx;
                vertices[off_ver++] = ty;
            }
        }
        // special case to optimize width/height transform speed
        //
        override public function set width(value:int):void
        {
            // to prevent flipping we should limit size
            var tmp:Number=Number(value > _cornerRadius2);
			value = value * tmp + (1.0 - tmp) * _cornerRadius2;
            //
            _dirty |= int(value != _width) << 1;
            _width = value;
        }
        override public function set height(value:int):void
        {
            // to prevent flipping we should limit size
            var tmp:Number=Number(value > _cornerRadius2);
			value = value * tmp + (1.0 - tmp) * _cornerRadius2;
            //
            _dirty |= int(value != _height) << 3;
            _height = value;
        }
        //
        override public function updateBatch(vertices:Vector.<Number>, indices:Vector.<uint>):void
        {
            var off_ver:int;
            var i:int,  j:int;

            // verts update
            if (_dirty & 4)
            {
                // clear special cases since
                // we will handle it here
                _dirty &= ~(1 << 1);
                _dirty &= ~(1 << 2);
                _dirty &= ~(1 << 3);

                var _tlx:Number, _tly:Number, _trx:Number, _try:Number;
                var _blx:Number, _bly:Number, _brx:Number, _bry:Number;

                var offx:int = globalX,  offy:int = globalY;

                if(_cornerRadius == 0)
                {

                    _tlx = offx;
                    _tly = offy;
                    _trx = offx + _width;
                    _try = _tly;
                    _brx = _trx;
                    _bry = offy + _height;
                    _blx = _tlx;
                    _bly = _bry;

                    off_ver = vertexOffset;
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
                }
                else
                {
                    // to prevent flipping we should limit size
                    var w:Number = _width;
                    var h:Number = _height;

                    var rx2:Number = offx + w;
                    var ry2:Number = offy + h;

                    var off_ind:int = 0;
                    off_ver = vertexOffset;
                    i = _numSegmentsPerCorner + 1;

                    vertices[off_ver++] = offx + w * 0.5;
                    vertices[off_ver++] = offy + h * 0.5;
                    off_ver += 6;

                    //for( i = 0; i < 4; ++i )
                    //{
                        // BR
                        var cx:Number = rx2 - _cornerRadius;
                        var cy:Number = ry2 - _cornerRadius;
                        for( j = 0; j < i; ++j )
                        {
                            var cos:Number = _precompRadiusOffset[off_ind++];
                            var sin:Number = _precompRadiusOffset[off_ind++];
                            vertices[off_ver++] = cx + cos * _cornerRadius;
                            vertices[off_ver++] = cy + sin * _cornerRadius;

                            off_ver += 6;
                        }
                        // BL
                        cx = offx + _cornerRadius;
                        //cy = ry2 - _cornerRadius;
                        for( j = 0; j < i; ++j )
                        {
                            cos = _precompRadiusOffset[off_ind++];
                            sin = _precompRadiusOffset[off_ind++];
                            vertices[off_ver++] = cx + cos * _cornerRadius;
                            vertices[off_ver++] = cy + sin * _cornerRadius;

                            off_ver += 6;
                        }
                        // TL
                        //cx = offx + _cornerRadius;
                        cy = offy + _cornerRadius;
                        for( j = 0; j < i; ++j )
                        {
                            cos = _precompRadiusOffset[off_ind++];
                            sin = _precompRadiusOffset[off_ind++];
                            vertices[off_ver++] = cx + cos * _cornerRadius;
                            vertices[off_ver++] = cy + sin * _cornerRadius;

                            off_ver += 6;
                        }
                        // TR
                        cx = rx2 - _cornerRadius;
                        //cy = offy + _cornerRadius;
                        for( j = 0; j < i; ++j )
                        {
                            cos = _precompRadiusOffset[off_ind++];
                            sin = _precompRadiusOffset[off_ind++];
                            vertices[off_ver++] = cx + cos * _cornerRadius;
                            vertices[off_ver++] = cy + sin * _cornerRadius;

                            off_ver += 6;
                        }
                    //}
                    vertices[off_ver++] = rx2;
	                vertices[off_ver++] = ry2 - _cornerRadius;
                }

                gui._dirty |= 1 << 2;
            }

            // special case for faster width change
            // avoiding whole structure update
            if(_dirty & 2)
            {
                _dirty &= ~(1 << 1);

                offx = globalX;

                if(_cornerRadius == 0)
                {
                    _trx = offx + _width;

                    off_ver = vertexOffset + 8;
                    vertices[off_ver] = _trx;
                    off_ver += 8;
                    vertices[off_ver] = _trx;
                }
                else
                {
                    w = _width;

                    rx2 = offx + w;

                    off_ind = 0;
                    off_ver = vertexOffset;
                    i = _numSegmentsPerCorner + 1;

                    vertices[off_ver] = offx + w * 0.5;
                    off_ver += 8;

                    // BR
                    cx = rx2 - _cornerRadius;
                    for( j = 0; j < i; ++j )
                    {
                        cos = _precompRadiusOffset[off_ind++];
                        vertices[off_ver] = cx + cos * _cornerRadius;

                        off_ver += 8;
                        off_ind++;
                    }
                    off_ver += i * 2 * 8;
                    off_ind += i * 4;
                    // TR
                    cx = rx2 - _cornerRadius;
                    for( j = 0; j < i; ++j )
                    {
                        cos = _precompRadiusOffset[off_ind++];
                        vertices[off_ver] = cx + cos * _cornerRadius;

                        off_ver += 8;
                        off_ind++;
                    }
                    vertices[off_ver] = rx2;
                }
                gui._dirty |= 1 << 2;
            }
            // same for height
            if(_dirty & 3)
            {
                _dirty &= ~(1 << 3);

                offy = globalY;

                if(_cornerRadius == 0)
                {
                    _bry = offy + _height;

                    off_ver = vertexOffset + 17;

                    vertices[off_ver] = _bry;
                    off_ver += 8;
                    vertices[off_ver] = _bry;
                }
                else
                {
                    // to prevent flipping we should limit size
                    h = _height;
                    ry2 = offy + h;

                    off_ind = 0;
                    off_ver = vertexOffset + 1;
                    i = _numSegmentsPerCorner + 1;

                    vertices[off_ver] = offy + h * 0.5;
                    off_ver += 8;

                    // BR
                    cy = ry2 - _cornerRadius;
                    for( j = 0; j < i; ++j )
                    {
                        off_ind++;
                        sin = _precompRadiusOffset[off_ind++];
                        vertices[off_ver] = cy + sin * _cornerRadius;

                        off_ver += 8;
                    }
                    // BL
                    for( j = 0; j < i; ++j )
                    {
                        off_ind++;
                        sin = _precompRadiusOffset[off_ind++];
                        vertices[off_ver] = cy + sin * _cornerRadius;

                        off_ver += 8;
                    }
	                vertices[off_ver] = cy;
                }
                gui._dirty |= 1 << 2;
            }

            // rgba update
            if (_dirty & 16)
            {
                _dirty &= ~(1 << 4);

                var r:Number, g:Number, b:Number, a:Number;

                a = ((_bgColor >> 24) & 0xFF) / 255.0;
                r = ((_bgColor >> 16) & 0xFF) / 255.0;
                g = ((_bgColor >> 8) & 0xFF) / 255.0;
                b = (_bgColor & 0xFF) / 255.0;

                off_ver = vertexOffset + 4;

                if(_cornerRadius == 0)
                {

                    vertices[off_ver++] = r;
                    vertices[off_ver++] = g;
                    vertices[off_ver++] = b;
                    vertices[off_ver++] = a;
                    off_ver += 4;
                    vertices[off_ver++] = r;
                    vertices[off_ver++] = g;
                    vertices[off_ver++] = b;
                    vertices[off_ver++] = a;
                    off_ver += 4;
                    vertices[off_ver++] = r;
                    vertices[off_ver++] = g;
                    vertices[off_ver++] = b;
                    vertices[off_ver++] = a;
                    off_ver += 4;
                    vertices[off_ver++] = r;
                    vertices[off_ver++] = g;
                    vertices[off_ver++] = b;
                    vertices[off_ver++] = a;
                }
                else
                {
                    var n:int = numVertices;
                    for( i = 0; i < n; ++i )
                    {
                        vertices[off_ver++] = r;
                        vertices[off_ver++] = g;
                        vertices[off_ver++] = b;
                        vertices[off_ver++] = a;
                        off_ver += 4;
                    }
                }

                gui._dirty |= 1 << 2;
            }
        }
    }
}
