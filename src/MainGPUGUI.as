package  
{
	import flash.display.Sprite;
    import flash.display.Stage3D;
    import flash.display3D.Context3D;
    import flash.display3D.Context3DRenderMode;
    import flash.events.Event;
    import flash.geom.Rectangle;
import flash.text.AntiAliasType;
import flash.text.TextFormat;

import gpu.gui.GPUGUIButton;
import gpu.gui.GPUGUICheckBox;
import gpu.gui.GPUGUIFillCircle;

import gpu.gui.GPUGUIFillRect;
import gpu.gui.GPUGUIColor;
import gpu.gui.GPUGUIControlGroup;
import gpu.gui.GPUGUILabel;
import gpu.gui.GPUGUIStyle;
import gpu.gui.GPUGUIVSlider;
import gpu.gui.GPUGUI;
import gpu.gui.GPUGUIHSlider;

/**
     * ...
     * @author Eugene Zatepyakin
     */
    [SWF(frameRate='40', width='640', height='480', backgroundColor='0xFFFFFF')]
    public final class MainGPUGUI extends Sprite 
    {
        [Embed(source = "../assets/NewMedia_Fett.ttf", embedAsCFF = "false", fontName = "NewMedia Fett", mimeType = "application/x-font")]
        protected var NewMediaFett:Class;

        public var stageW:int = 640;
        public var stageH:int = 480;
        public var invStageW:Number = 1. / stageW;
        
        private var context3D:Context3D;
        public var gui:GPUGUI;
        
        public function MainGPUGUI() 
        {
            getContext(Context3DRenderMode.AUTO);
        }
        
        private function getContext(mode:String): void
        {
            context3D = null;
            var stage3D:Stage3D = stage.stage3Ds[0];
            stage3D.addEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
            stage3D.requestContext3D(mode);
        }
 
        private function onContextCreated(ev:Event): void
        {
            stageW = stage.stageWidth;
            stageH = stage.stageHeight;
            invStageW = 1. / stageW;
            
            // Setup context
            var stage3D:Stage3D = stage.stage3Ds[0];
            stage3D.removeEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
            context3D = stage3D.context3D;
            context3D.configureBackBuffer(
                stageW,
                stageH,
                2,
                false
            );
            
            // Enable error checking in the debug player
            /*var debug:Boolean = Capabilities.isDebugger;
            if (debug)
            {
                context3D.enableErrorChecking = true;
            }*/

            var tf:TextFormat = new TextFormat('NewMedia Fett', 22);
            /*GPUGUIStyle.setStyle(0xFF4D4D4D, 0xFFFFFFFF, 0x7F000000, 
                                tf, true, AntiAliasType.ADVANCED, 0xFF00FFFF,
                                3, 3, 200, 30, 2);*/
            /*
            GPUGUIStyle.setStyle(0xFF4D4D4D, 0xFFFFFFFF, 0x7F000000,
                                null, true, AntiAliasType.NORMAL, 0xFF00FFFF,
                                3, 3, 200, 30, 2);
            */
            
            gui = new GPUGUI(stage, context3D, new Rectangle(0, 0, stageW, stageH));

            var grp:GPUGUIControlGroup = new GPUGUIControlGroup(10, 240, 'gpu_slider');
            var lab:GPUGUILabel = new GPUGUILabel('My Super label 123', {x:0, y:-40});
            var sl:GPUGUIHSlider = new GPUGUIHSlider(0, 1, 0.5,
                    {width:200, height:30, label:'GPU HSLIDER', drawBackground:true});
            var clr:GPUGUIColor = new GPUGUIColor(0x7F7F7F, GPUGUIColor.COLOR_TYPE_RGB,
                    {x:10, y:20, sliderHeight:15, label:'GPU COLOR', drawBackground:true});
            var btn:GPUGUIButton = new GPUGUIButton( { x:240, y:20, width:40, height:20, 
                    label:'GPU BUTTON', drawBackground:true});

            var chk_grp:GPUGUIControlGroup = new GPUGUIControlGroup(380, 140, 'checkbox');
            var chk0:GPUGUICheckBox = new GPUGUICheckBox({y:0, boxSize:20, label:'GPU CHECK 0', drawBackground:true});
            var chk1:GPUGUICheckBox = new GPUGUICheckBox({y:27, boxSize:20, label:'GPU CHECK 1', drawBackground:true});
            var chk2:GPUGUICheckBox = new GPUGUICheckBox({y:54, boxSize:20, label:'GPU CHECK 2', drawBackground:true});
            chk0.groupID = 0; chk1.groupID = 0; chk2.groupID = 0;
            chk1.checked = true;

            chk_grp.addControl(chk0); chk_grp.addControl(chk1); chk_grp.addControl(chk2);

            var chk:GPUGUICheckBox = new GPUGUICheckBox({x:10, y:140, boxSize:20, width:20, label:'GPU CHECKBOX', drawBackground:true});
            var circ:GPUGUIFillCircle = new GPUGUIFillCircle(20, {x:260, y:140});
            var fillR:GPUGUIFillRect = new GPUGUIFillRect({x:240, y:60, width:80, height:30, cornerRadius:2});
            var slV:GPUGUIVSlider = new GPUGUIVSlider(0, 1, 0.5,
                    {x:250, y:350, width:150, height:20, label:'GPU VSLIDER', drawBackground:true});

            //lab.align = GPUGUILabel.TEXT_ALIGN_VERTICAL;

            //grp.addControl(bg);
            grp.addControl(sl);
            grp.addControl(lab);

            gui.addControl(grp);
            gui.addControl(clr);
            gui.addControl(btn);
            gui.addControl(chk);
            gui.addControl(chk_grp);
            gui.addControl(circ);
            gui.addControl(fillR);
            gui.addControl(slV);

            clr.setCallBack(onColorChange);

            addEventListener(Event.ENTER_FRAME, updateFrame);
        }

        private function onColorChange(color:uint, red:Number, green:Number, blue:Number, alpha:Number):void
        {
            _bgR = red;
            _bgG = green;
            _bgB = blue;
            _bgA = alpha;
        }

        protected var _bgR:Number = 0.5;
        protected var _bgG:Number = 0.5;
        protected var _bgB:Number = 0.5;
        protected var _bgA:Number = 1.0;
        private function updateFrame(e:Event):void 
        {
            context3D.clear(_bgR, _bgG, _bgB, _bgA);
            
            gui.draw();
            
            context3D.present();
        }
        
    }

}