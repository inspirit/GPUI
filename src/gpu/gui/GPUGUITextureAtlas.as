package gpu.gui
{
    import flash.display.BitmapData;
    import flash.display3D.Context3D;
    import flash.display3D.Context3DTextureFormat;
    import flash.display3D.textures.Texture;
    import flash.geom.Rectangle;
    
    // gently grabbed from Minko 3D engine ;-)

    internal final class GPUGUITextureAtlas
    {
        internal var _bitmapData:BitmapData = null;
        internal var _size:int = 0;
        internal var _step:Number = 0;
        internal var _texture:Texture = null;

		protected var _nodes:Array = new Array();
		protected var _empty:Array = new Array();

        public function GPUGUITextureAtlas(size:int, transparent:Boolean = true, color:uint = 0x0)
        {
            _size = size;
            _step = 1.0 / Number(size);
			_nodes[0] = new Rectangle(0, 0, _size, _size);
			_bitmapData = new BitmapData(_size, _size, transparent, color);
        }

        public function addBitmapData(bitmapData:BitmapData):Rectangle
		{
			var rectangle:Rectangle	= getRectangle(bitmapData.width, bitmapData.height);

			_bitmapData.copyPixels(bitmapData, bitmapData.rect, rectangle.topLeft, null,null,bitmapData.transparent);

			return rectangle.clone();
		}

        public function uploadTexture(context:Context3D, forceRebuild:Boolean = false):void
        {
            if(!_texture || forceRebuild)
            {
                if(_texture)_texture.dispose();
                _texture = context.createTexture(_size, _size, Context3DTextureFormat.BGRA, false);
            }
            _texture.uploadFromBitmapData(_bitmapData, 0);
        }

        protected function getRectangle(width : uint, height : uint, rootId : int = 0) : Rectangle
		{
			var node:Rectangle = _nodes[rootId];
			var first:Rectangle	= _nodes[int(rootId * 2 + 1)];
			var second:Rectangle = _nodes[int(rootId * 2 + 2)];
			if (!first && !second)
			{
				if (_empty[rootId] === false || width > node.width || height > node.height)
					return null;

				if (width == node.width && height == node.height)
				{
					_empty[rootId] = false;

					return node;
				}
				else
				{
					var dw : uint = node.width - width;
					var dh : uint = node.height - height;

					if (dw > dh)
					{
						first = new Rectangle(node.left, node.top,
											  width, node.height);
						second = new Rectangle(node.left + width, node.top,
											   node.width - width, node.height);
					}
					else
					{
						first = new Rectangle(node.left, node.top,
											  node.width, height);
						second = new Rectangle(node.left, node.top + height,
											   node.width, node.height - height);
					}

					_nodes[int(rootId * 2 + 1)] = first;
					_nodes[int(rootId * 2 + 2)] = second;

					return getRectangle(width, height, rootId * 2 + 1);
				}
			}

			if ((node = getRectangle(width, height, rootId * 2 + 1)))
				return node;

			return getRectangle(width, height, rootId * 2 + 2);
		}
        
        public function dispose():void
        {
            if (_texture)
            {
                _nodes = new Array();
                _empty = new Array();
                
                _bitmapData.dispose();
                _texture.dispose();
                
                _bitmapData = null;
                _texture = null;
            }
        }
    }
}
