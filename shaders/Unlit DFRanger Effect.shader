Shader "VF Shaders/Forward/Unlit DFRanger Effect" {
    Properties {
        _LocalScale ("整体缩放", Float) = 1
        _TintColor ("Tint Color", Vector) = (1,1,1,1)
        _TintColor2 ("Tint Color 2", Vector) = (1,1,1,1)
        _Multiplier ("Multiplier", Float) = 1
        _AlphaMultiplier ("Alpha Multiplier", Float) = 1
        _MainTex ("Main Tex", 2D) = "black" {}
        _Tex101 ("Tex 101", 2D) = "black" {}
        _Tex102 ("Tex 102", 2D) = "black" {}
        _Tex103 ("Tex 103", 2D) = "black" {}
        _Tex104 ("Tex 104", 2D) = "black" {}
        _Tex200 ("Tex 200", 2D) = "black" {}
        _Mask200 ("Mask 200", 2D) = "white" {}
        _Position101 ("Position 101", Vector) = (0,0.125,-1.6,0)
        _UVSpeed ("UV Speed", Vector) = (0,0,0,0)
        _ZMin ("Z Min", Float) = -2
        _ZMax ("Z Max", Float) = 2
        _SideFade ("侧面消隐", Range(0, 2)) = 0
        _SizeSettings ("Size(Flare, Burn, Flame0, FlameL)", Vector) = (2.7,0.52,1.3,0.12)
        _IntensSettings ("Intens(Flare, Burn, Flame, Fire)", Vector) = (0.5,0.8,1,2)
        [Toggle(_ENABLE_VFINST)] _ToggleVerta ("Enable VFInst ?", Float) = 0
    }
    SubShader {
        Tags { "DisableBatching" = "true" "IGNOREPROJECTOR" = "true" "QUEUE" = "Transparent" "RenderType" = "Transparent" }
        Pass {
            Tags { "DisableBatching" = "true" "IGNOREPROJECTOR" = "true" "QUEUE" = "Transparent" "RenderType" = "Transparent" }
            Blend SrcAlpha One, SrcAlpha One
            ColorMask RGB -1
            ZWrite Off
            Cull Off
            GpuProgramID 48791
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 5.0
            
            #include "UnityCG.cginc"
            struct v2f
            {
                float4 pos : SV_POSITION0;
                float2 uv : TEXCOORD0;
                float unk1 : TEXCOORD1;
                float unk3 : TEXCOORD3;
                float4 clipPos : TEXCOORD2;
                float3 worldPos : TEXCOORD4;
                float colorX : TEXCOORD6;
                float3 worldNormal : TEXCOORD5;
                float4 unk7 : TEXCOORD7;
            };
            
            struct fout
            {
                float4 sv_target : SV_Target0;
            };
            
            // $Globals ConstantBuffers for Vertex Shader
            float _LocalScale;
            float4 _Position101;
            float4 _SizeSettings;
            float4 _MainTex_ST;
            // $Globals ConstantBuffers for Fragment Shader
            float4 _TintColor;
            float4 _TintColor2;
            float _Multiplier;
            float _AlphaMultiplier;
            float4 _UVSpeed;
            float _ZMin;
            float _ZMax;
            float _SideFade;
            float4 _IntensSettings;
            // Custom ConstantBuffers for Vertex Shader
            // Custom ConstantBuffers for Fragment Shader
            // Texture params for Vertex Shader
            // Texture params for Fragment Shader
            sampler2D _CameraDepthTexture;
            sampler2D _Tex101;
            sampler2D _Tex102;
            sampler2D _Tex103;
            sampler2D _Tex104;
            sampler2D _Tex200;
            sampler2D _Mask200;
            
            // Keywords: 
            v2f vert(appdata_full v)
            {
                v2f o;
                
                float3x3 unityV = float3x3(
                    normalize(unity_MatrixV._m00_m01_m02),
                    normalize(unity_MatrixV._m10_m11_m12),
                    normalize(unity_MatrixV._m20_m21_m22)
                );
                
                float3 vertPos = v.vertex.xyz - _Position101.xyz - float3(0.0, 0.0, 0.3);
                float timeinSec = _Time.y;
                float2 animFrame = sin(timeinSec * float2(417.0, 771.0)) * float2(0.06, 0.06) + float2(1.0, 1.0);
                
                int colorX = (int)(v.color.x * 255.0 + 0.5);
                //101: "Flare"
                //102: "Burn"
                //103: "Flame0"
                //104: "FlameL"
                //>104: more flame
                
                float finalVertZ = v.vertex.z - 0.3;
                float3 offset = float3(0.0, 0.0, 0.0);
                
                if (colorX == 101) {
                    finalVertZ = _Position101.z * 0.95;
                    offset = vertPos.xyz * _SizeSettings.xxx * animFrame.xxx;
                } else if (colorX == 102) {
                    finalVertZ = vertPos.z * _SizeSettings.y * animFrame.y + _Position101.z * 0.95;
                    offset = float3(1.0, 0.5, 0.0);
                } else if (colorX == 103) {
                    finalVertZ = 0.0;
                    offset = float3(0.0, 0.0, 0.0);
                } else if (colorX == 104) {
                    finalVertZ = 0.0;
                    offset = v.vertex.xyz * float3(260.0, 96.2, 260.0) - float3(0.0, 0.0, 78.0);
                }
                
                float3 offsetView = float3(0.0, 0.0, 0.0);
                if (colorX == 102 || colorX == 104) {
                    offsetView = mul(unityV, offset);
                }
                
                float3 finalVertPos = float3(v.vertex.xy, finalVertZ + 0.3);
                
                if (colorX == 101) {
                    finalVertPos.xy = _Position101.xy * float2(0.95, 0.95) + float2(0.0, 0.05);
                } else if (colorX == 102) {
                    finalVertPos.xy = vertPos.xy * _SizeSettings.yy * animFrame.yy + _Position101.xy * float2(0.95, 0.95) + float2(0.0, 0.05);
                } else if (colorX == 103 || colorX == 104) {
                    finalVertPos.xy = float2(0.0, 0.0);
                }
                
                finalVertPos = finalVertPos * _LocalScale.x + offsetView;
                
                float4 clipPos = UnityObjectToClipPos(finalVertPos);
                float3 worldPos = mul(unity_ObjectToWorld, float4(finalVertPos, v.vertex.w));
                
                
                o.pos.xyzw = clipPos;
                o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.unk1.x = 0.0;
                o.clipPos.xyzw = clipPos;
                o.unk3.x = 0.0;
                o.worldPos.xyz = worldPos;
                o.worldNormal.xyz = mul((float3x3)unity_ObjectToWorld, v.normal.xyz);
                o.colorX.x = colorX - 0.5;
                o.unk7.xyzw = float4(0.0, 0.0, 0.0, 0.0);
                
                return o;
            }
            // Keywords: 
            fout frag(v2f inp)
            {
                fout o;
                
                float4 color;
                if (inp.colorX.x > 100.0 && inp.colorX.x < 104.0) {
                    if (inp.colorX.x < 101.0) {
                        float4 tex = tex2D(_Tex101, inp.uv.xy);
                        color = tex * _IntensSettings * _TintColor;
                    } else if (inp.colorX.x < 102.0) {
                        float4 tex = tex2D(_Tex102, inp.uv.xy);
                        color = tex * _IntensSettings * _TintColor;
                    } else {
                        float signUnk7 = sign(inp.unk7.x);
                        if (inp.colorX.x < 103.0) {
                            if (signUnk7 < 0.001) {
                                discard;
                            }
                            float4 tex = tex2D(_Tex103, inp.uv.xy);
                            tex = 2.0 * (signUnk7 * tex * _IntensSettings);
                            color = pow(saturate(1.0 - unk1), 3.0) * saturate(unk3 * 10.0) * tex * _TintColor2;
                        } else {
                            if (signUnk7 < 0.001) {
                                discard;
                            }
                            float4 tex = tex2D(_Tex104, inp.uv.xy);
                            color = signUnk7 * tex * _TintColor2 * _IntensSettings * float4(0.55, 0.55, 0.55, 0.55);
                        }
                    }
                } else {
                    float2 animUV = _Time.yy * _UVSpeed.xy + inp.uv.xy;
                    float4 tex = tex2D(_Tex200, animUV);
                    float2 mask = tex2D(_Mask200, inp.uv.xy).xw;
                    mask.x = mask.y * mask.x;
                    color = tex * _IntensSettings * mask.xxxx * _TintColor;
                }
                
                float4 screenPos = ComputeScreenPos(inp.clipPos.xyzw); //r1.xy
                float sceneDepth = LinearEyeDepth(tex2D(_CameraDepthTexture, screenPos.xy).x);
                
                float unkX = saturate((inp.clipPos.w - screenPos.x + _ZMin) / (_ZMax - _ZMin));
                float unkY = saturate(inp.clipPos.w / (_ZMax - _ZMin));
                float unkFactor = sceneDepth > _ZMax ? 1.0 : 0.0;
                float depthFade = screenPos.y == 0.0 ? unkFactor : unkX * unkY;
                
                float colorAlpha = saturate(color.w * _TintColor.w * _AlphaMultiplier);
                
                float3 worldNormal = normalize(inp.worldNormal.xyz);
                float3 eyeVec = normalize(inp.worldPos.xyz - _WorldSpaceCameraPos);
                float fade = pow(abs(dot(worldNormal, eyeVec)), _SideFade);
                
                o.sv_target.xyz = color.xyz * _Multiplier.xxx;
                float alpha = depthFade * fade * colorAlpha;
                o.sv_target.w = min(alpha, 1.0);
                
                return o;
            }
            ENDCG
        }
    }
}