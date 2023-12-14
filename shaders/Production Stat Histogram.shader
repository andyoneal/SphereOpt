Shader "UI Ex/Production Stat Histogram REPLACE" {
Properties {
    _Multiplier ("Multiplier", Float) = 1.55
    [PerRendererData] _MainTex ("Main Texture", 2D) = "white" {}
    _ProductColor1 ("Product Color 1", Vector) = (1,1,1,1)
    _ConsumeColor1 ("Consume Color 1", Vector) = (1,1,1,1)
    _ZeroColor ("ZeroColor", Vector) = (1,1,1,1)
    _BigImage ("Is Big Image", Float) = 0
    _MaxCount1 ("Max Count 1", Float) = 0
    _StencilComp ("Stencil Comparison", Float) = 8
    _Stencil ("Stencil ID", Float) = 0
    _StencilOp ("Stencil Operation", Float) = 0
    _StencilWriteMask ("Stencil Write Mask", Float) = 255
    _StencilReadMask ("Stencil Read Mask", Float) = 255
    _ColorMask ("Color Mask", Float) = 15
}
SubShader {
    Tags { "CanUseSpriteAtlas" = "true" "IGNOREPROJECTOR" = "true" "PreviewType" = "Plane" "QUEUE" = "Transparent" "RenderType" = "Transparent" }
    Pass {
        Tags { "CanUseSpriteAtlas" = "true" "IGNOREPROJECTOR" = "true" "PreviewType" = "Plane" "QUEUE" = "Transparent" "RenderType" = "Transparent" }
        Blend SrcAlpha One, SrcAlpha One
        //ColorMask 0 -1 //?
        ZWrite Off
        Cull Off
        Stencil {
            Ref 1
            ReadMask 1
            WriteMask 0
            Comp equal
            Pass Keep
            Fail Keep
            ZFail Keep
        }
        
        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag
        #pragma target 5.0
        
        #include "UnityCG.cginc"
        
        struct v2f
        {
            float4 pos : SV_Position0;
            float2 graphCoords : TEXCOORD0;
        };
        
        struct fout
        {
            float4 sv_target : SV_Target0;
        };
        
        float _Multiplier;
        float4 _ProductColor1;
        float4 _ConsumeColor1;
        float4 _ZeroColor;
        float _BigImage;
        float _MaxCount1;
        
        StructuredBuffer<float> _Buffer1;


        v2f vert(appdata_full v)
        {
            v2f o;
            
            o.pos.xyzw = UnityObjectToClipPos(v.vertex);
            
            o.graphCoords.xy = v.texcoord.xy;
            // (0,0) is bottom left, (1,1) is top right
            // will be interpolated when passed to the fragment shader, so the pixel in the bottom left will still
            // be (very close to) (0,0) and, assuming the graph is 400 pixels wide, the pixel one to the right will
            // be (0, 0.0025) and the next to the right will be (0, 0.005) and so on.
            
            return o;
        }
        
        fout frag(v2f i)
        {
            fout o;
            
            /* Y axis */
            
            // I don't think this is ever true. _BigImage is always 0.
            bool bigImageEnabled = _BigImage > 0.5;
            
            // you'd think the middle of the graph (since it goes from 0 to 1) would be 0.5
            float offsetFromTopToXAxis = bigImageEnabled ? 0.4975 : 0.495; //r0.y
            
            // distance from this pixel to the middle of the graph
            float distFromYPosToXAxis = i.graphCoords.y - offsetFromTopToXAxis; //r0.y
            
            float xAxisLineThickness = bigImageEnabled ? 0.00125 : 0.0025; //r0.z
            
            // if this pixel is inside the x-axis line in the middle of the graph, draw the x-axis line color and return early
            bool yPosIsInsideXAxisLine = abs(distFromYPosToXAxis) < xAxisLineThickness;
            if (yPosIsInsideXAxisLine) {
                o.sv_target.xyzw = _ZeroColor.xyzw;
                return o;
            }
            
            // "off the charts" limit.
            float yLimit = bigImageEnabled ? 0.495 : 0.49; //r0.z
            float pctOfYLimit = (abs(distFromYPosToXAxis) - xAxisLineThickness) / yLimit; //r0.y
            // if this pixel is outside the bounds of the graph, draw nothing
            if (pctOfYLimit > 1.0) discard;
            
            /* X axis */
            
            // this pixel along the x axis (0 to 1) * 600. -0.5 ensures it rounds down every time.
            // production/consumption data includes 1200 data points, so this must be half of that
            float HalfxPos = round(i.graphCoords.x * 600 - 0.5); //r0.z //round to even or normal rounding?
            
            // behind the actual data, there are dim bars about every other two pixels
            // note: both this and the next group does a really strange (and seemingly useless) operation:
            //    (2*x) >= -(2*x) which is the same as x >= 0 and multiplying by 2 doesn't make a difference
            float xPos = 2.0 * HalfxPos; //r0.w
            float point5 = xPos >= -xPos ? 0.5 : -0.5; //r1.y
            float bgBars = frac(point5 * HalfxPos); //r0.w
            
            // if you split the graph up into 10 groups, every other group dims or brightens the background bars
            float TenGroupsOfX = floor(HalfxPos / 60.0); //r1.y
            float x2TenGroupsOfX = 2.0 * TenGroupsOfX; //r1.z
            point5 = x2TenGroupsOfX >= -x2TenGroupsOfX ? 0.5 : -0.5;
            float alternatingBarBrightness = frac(point5 * TenGroupsOfX); //r1.y
            
            // combining the two effects gives us bgBars, which controls how strong the bar color is
            // for this pixel, ranging from:
            // 0.0: blank space between bars
            // 0.8: dimmed background bars
            // 1.0: full strength background bars
            // it's later multiplied by 0.15 to give it the dimmed appearance in game
            float two = xPos >= -xPos ? 2.0 : -2.0; //r1.x
            float anotherTwo = x2TenGroupsOfX >= -x2TenGroupsOfX ? 2.0 : -2.0; //r1.z
            bgBars = saturate(two * bgBars + 0.1);
            alternatingBarBrightness = saturate(anotherTwo * alternatingBarBrightness + 0.8);
            bgBars = alternatingBarBrightness * bgBars; //r0.w
            
            /* Colors */
            
            // midpoint of the graph on the Y axis. again, you'd think it'd be 0.5
            float yMidPt = bigImageEnabled ? 0.4975 : 0.495; //r0.x
            // if this pixel is above the midpoint, it's product, if it's below, it's consume.
            float4 color = i.graphCoords.y > yMidPt ? _ProductColor1.xyzw : _ConsumeColor1.xyzw;
            
            /* Fetch Data */
            
            // data is stored in the buffer with product data in the first 1200 elements and consumption in
            // in the last 1200 elements, so if this pixel is above the midpoint, start at the beginning,
            // if it's below, start at the middle.
            float indexOffset = i.graphCoords.y > yMidPt ? 0 : 1200; //r0.w
            
            // add the offset to the pixel's location on the xaxis ([0 to 1] * 600 * 2 == 0 to 1200)
            // to get the index
            float bufferIndex = HalfxPos * 2.0 + indexOffset; //r0.x
            uint idx = bufferIndex = 0.5 + bufferIndex;
            
            uint count = _Buffer1[idx]; //r0.x
            
            /* Output */
            
            // _MaxCount1 is the upper/lower bound of the graph on the y axis. The most we've produced/consumed
            // within the time period. make sure _MaxCount1 has a usable value, especially because we're about
            // to divide with it
            float maxCount = _MaxCount1 > 0.001 ? _MaxCount1 : 1; //r0.z
            
            // what percent of the max are we producing/consuming?
            float pctOfMaxCount = count / maxCount; //r0.x
            
            // if this pixel is higher on the graph than the count reaches, draw the background bars (here's where they
            // actually get dimmed by 0.15), otherwise draw the bar (1.0)
            float colorStrength = pctOfMaxCount < pctOfYLimit ? 0.15 * bgBars : 1.0; //r0.x
            
            // multiply the color (product or consume) by the strength (data bars or background bar)
            color = colorStrength * color;
            o.sv_target.xyzw = _Multiplier * color;
            
            return o;
        }
        
        ENDCG
        }
    }
}