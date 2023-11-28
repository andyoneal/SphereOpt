Shader "Universe/Sun" {
    Properties {
        _Multiplier ("Multiplier", Float) = 1
        _SunGlowColor ("Sun Glow Color", Color) = (1,1,1,1)
        _SunGlowPower ("Sun Glow Power", Float) = 4
        _SunCenterColor ("Sun Center Color", Color) = (1,1,1,1)
        _SunCenterMultiplier ("Sun Center Multiplier", Float) = 3
        _SunCenterSize ("Sun Center Size", Range(0.01, 0.9)) = 0.3
        _SunCenterBlur ("Sun Center Blur", Range(0.01, 0.9)) = 0.05
        _SunCenterBlurPower ("Sun Center Blur Power", Float) = 4
    }
    SubShader {
        Tags { "QUEUE" = "Transparent" "RenderType" = "Transparent" }
        Pass {
            Tags { "QUEUE" = "Transparent" "RenderType" = "Transparent" }
            Blend One One, One One
            ZWrite Off
            Cull Off
//			Fog {
//				Mode 0
//			}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 5.0
            
            #include "UnityCG.cginc"
            
            struct v2f
            {
                float4 pos : SV_Position0;
                float2 quadCoords : TEXCOORD0;
            };
            
            struct fout
            {
                float4 sv_target : SV_Target0;
            };
            
            float _Multiplier;
            float4 _SunGlowColor;
            float _SunGlowPower;
            float4 _SunCenterColor;
            float _SunCenterMultiplier;
            float _SunCenterSize;
            float _SunCenterBlur;
            float _SunCenterBlurPower;
            
            v2f vert(appdata_full v)
            {
                v2f o;

                o.pos = UnityObjectToClipPos(v.vertex.xyz);
                o.quadCoords.xy = v.texcoord.xy;
                
                return o;
            }
             
            fout frag(v2f i)
            {
                fout o;
                
                float distfromCenter = length(i.quadCoords.xy - float2(0.5, 0.5));
                float falloff = 1.0 - distfromCenter * 2.0;
                
                float sunCenterFactor = _SunCenterSize - distfromCenter * 2.0;
                sunCenterFactor = saturate(sunCenterFactor / _SunCenterBlur);
                sunCenterFactor = pow(sunCenterFactor, _SunCenterBlurPower);
                
                if (falloff < 0.0)
                    discard;

                float3 sunColor = lerp(_SunGlowColor.xyz, _SunCenterColor.xyz * _SunCenterMultiplier, sunCenterFactor);
                
                float sunGlowSize = 1.0 - _SunCenterSize + _SunCenterBlur;
                float sunGlowFactor = saturate(falloff / sunGlowSize);
                sunGlowFactor = pow(sunGlowFactor, _SunGlowPower);
                
                o.sv_target.xyz = sunGlowFactor * sunColor * _Multiplier;
                o.sv_target.w = 1.0;
                return o;
            }
            ENDCG
        }
    }
}