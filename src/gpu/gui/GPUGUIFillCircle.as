package gpu.gui
{
    public class GPUGUIFillCircle extends GPUGUIControl
    {
        protected var _numSegments:int;
        protected var _precompRadiusOffset:Vector.<Number>;

        internal var _bgColor:uint;

        public function GPUGUIFillCircle(raduis:Number, options:Object)
        {
            options = parseOptions(options);

            if(options.numSegments <= 0)
            {
                options.numSegments = raduis * Math.PI * 2;
            }
            if( options.numSegments < 2 ) options.numSegments = 2;

            numTriangles = options.numSegments;
            numVertices = options.numSegments + 2;

            _numSegments = options.numSegments;
            _width = raduis;
            _height = raduis;
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
            var i:int;

            off_tri = indexOffset;
            off_ver = vertexOffset / 8; // number of points
            for (i = 0; i < numTriangles; ++i)
            {
                indices[off_tri++] = off_ver+0;
                indices[off_tri++] = off_ver+i+1;
                indices[off_tri++] = off_ver+i+2;
            }

            // uv update
            var tx:Number = gui._colorTextureRect.x;
            var ty:Number = gui._colorTextureRect.y;

            off_ver = vertexOffset;
            const radius:Number = _width;

            _precompRadiusOffset = new Vector.<Number>((_numSegments+1)*2, true);

            // add center point
            vertices[off_ver++] = _x + _width * 0.5;
            vertices[off_ver++] = _y + _height * 0.5;
            vertices[off_ver++] = tx;
            vertices[off_ver++] = ty;
            off_ver += 4;

            for (i = 0; i <= _numSegments; ++i)
            {
                var t:Number = Number(i) / Number(_numSegments) * 2.0 * 3.14159;
                var cos:Number = Math.cos(t);
                var sin:Number = Math.sin(t);

                vertices[off_ver++] = _x + cos * radius;
                vertices[off_ver++] = _y + sin * radius;
                vertices[off_ver++] = tx;
                vertices[off_ver++] = ty;

                _precompRadiusOffset[i<<1] = cos;
                _precompRadiusOffset[(i<<1)+1] = sin;

                off_ver += 4;
            }
        }

        override public function updateBatch(vertices:Vector.<Number>, indices:Vector.<uint>):void
        {
            var off_ver:int;
            var i:int, j:int;
            var n:int;

            // verts update
            if (_dirty & 4)
            {
                _dirty &= ~(1 << 2);

                var offx:int = globalX,  offy:int = globalY;
                n = _numSegments+1;
                off_ver = vertexOffset;

                vertices[off_ver++] = offx + _width * 0.5;
                vertices[off_ver++] = offy + _height * 0.5;
                off_ver += 6;

                for(i = 0, j = 0; i < n; ++i)
                {
                    vertices[off_ver++] = offx + _precompRadiusOffset[j++] * _width;
                    vertices[off_ver++] = offy + _precompRadiusOffset[j++] * _height;

                    off_ver += 6;
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
                n = numVertices;
                for(i = 0; i < n; ++i)
                {
                    vertices[off_ver++] = r;
                    vertices[off_ver++] = g;
                    vertices[off_ver++] = b;
                    vertices[off_ver++] = a;
                    off_ver += 4;
                }

                gui._dirty |= 1 << 2;
            }
        }
    }
}
