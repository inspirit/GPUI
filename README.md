GPUI - Stage3D based UI
==
**Core ideas:**
  + make it as tiny and simple as possible
  + make it single call render

> yes the whole UI set is single batch ;) and rendered via single `drawTriangles`... that's probably not very smart but fun!
there is no dynamic text support, i mean u only have labels, and labels are rendered as textures. lame but fast and uses only one `Texture` for whole UI set! fun! ;)

**Very basic style system:**

u can define default `TextFormat` to use for labels and several color options like 
`bgColor` `darkColor` `lightColor` `textColor` 
and thats it... fun! ;)
ahh yes and u can use `roundedCorners` with specified radius :) or dont use...
```
GPUGUIStyle.setStyle(
                     darkColor:uint, lightColor:uint, bgColor:uint, // default color theme
                     textFormat:TextFormat = null, // define text font and size
                     embedFonts:Boolean = true, // if font is embedded
                     textAntiAlis:String = AntiAliasType.NORMAL, // font alias type
                     textColor:uint = 0xFFFFFFFF, // label color
                     paddX:Number = 3, paddY:Number = 3, // padding between controls
                     controlWidth:Number = 200, controlHeight:Number = 30, // default controls size
                     controlCornerRadius:Number = 0.0 // shapes corner radius
                     ):void;
```
> well i was creating it for my personal needs and wasn't thinking about sharing the result since it is too small and maybe unusable for real world problems.
but i think it is quite useful for quick tests because u can setup it on top of your own `Stage3D` stuff without including any other frameworks...

**Handle events and getting results**
```
control.setCallBack(onCallBack);
function onCallback(...args):void
{
    // u shoulc check specific component what arguments it returns
    // for example GPUGUIColor returns 5 arguments
    // color:uint, red:Number, green:Number, blue:Number, alpha:Number
}

//
// u can also assing properties directly to your objects
//
control.setTarget(target:*, property:String):void

// so when controls value changed it will set
target.property = newValue;
```

**Few Screens to get the feeling**

<img src="https://lh5.googleusercontent.com/-uUNNrSYAsNA/T6FEH4Ik8qI/AAAAAAAAAXs/rkhPsUfVISo/s594/gpui_1.jpg"/>
<img src="https://lh5.googleusercontent.com/--79WxUwDvP4/T6FEHxS8pzI/AAAAAAAAAX0/i7OnuEI7ezU/s594/gpui_0.jpg"/>

<pre>
Copyright 2012 Eugene Zatepyakin

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
</pre>