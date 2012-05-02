package gpu.gui
{
    import flash.text.AntiAliasType;
    import flash.text.TextFormat;

    public class GPUGUIStyle
    {
        [Embed(source = "../../../assets/tempesta-seven-fonts-1.2/pf_tempesta_seven.ttf", embedAsCFF = "false", fontName = "PF Tempesta Seven", mimeType = "application/x-font")]
        protected static const TempestaSeven:Class;

        internal static const DEFAULT_TEXT_FORMAT:TextFormat = new TextFormat('PF Tempesta Seven', 8);

        // STYLE OPTIONS
        internal static var _darkColor:uint = 0xFF4D4D4D;
        internal static var _lightColor:uint = 0xFFFFFFFF;
        internal static var _bgColor:uint = 0x7F000000; // 50% black
        internal static var _textColor:uint = 0xFFFFFFFF;
        internal static var _paddX:Number = 3;
        internal static var _paddY:Number = 3;
        internal static var _controlWidth:Number = 200;
        internal static var _controlHeight:Number = 30;
        internal static var _cornerRadius:Number = 0.;

        public function GPUGUIStyle()
        {
            throw new Error('STATIC CLASS');
        }

        public static function setStyle(darkColor:uint, lightColor:uint, bgColor:uint,
                                textFormat:TextFormat = null,
                                embedFonts:Boolean = true,
                                textAntiAlis:String = AntiAliasType.NORMAL,
                                textColor:uint = 0xFFFFFFFF,
                                paddX:Number = 3, paddY:Number = 3,
                                controlWidth:Number = 200, controlHeight:Number = 30,
                                controlCornerRadius:Number = 0.0):void
        {
            _darkColor = darkColor;
            _lightColor = lightColor;
            _bgColor = bgColor;
            _textColor = textColor;
            _paddX = paddX;
            _paddY = paddY;
            _controlWidth = controlWidth;
            _controlHeight = controlHeight;
            _cornerRadius = controlCornerRadius;

            GPUGUILabel.updateTextFormat(textFormat || GPUGUIStyle.DEFAULT_TEXT_FORMAT, embedFonts, textAntiAlis);
        }
    }
}
