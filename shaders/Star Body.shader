Shader "VF Shaders/Star Shaders/Star Body" {
    Properties {
        _Color0 ("Sun Color 0", Color) = (1,1,1,1)
        _Color1 ("Sun Color 1", Color) = (1,1,1,1)
        _Color2 ("Sun Color 2", Color) = (1,1,1,1)
        _Color3 ("Sun Color 3", Color) = (1,1,1,1)
        _Multiplier ("Multiplier", Float) = 2.5
        _NoiseTile ("Noise Tile", Float) = 50
        _NoiseSpeed ("Noise Speed", Float) = 0.2
        _ChaosTile ("Chaos Tile", Float) = 1
        _ChaosDistort ("Chaos Distort", Float) = 0.2
        _ChaosOverlay ("Chaos Overlay", Float) = 0.4
        _SpotIntens ("Spots Intensity", Float) = 4
        _RimPower ("Rim Power", Float) = 5
        _RotSpeed ("Rotate Speed", Float) = 0.04
    }
    SubShader {
        LOD 100
        Tags { "RenderType" = "Opaque" }
        Pass {
            LOD 100
            Tags { "RenderType" = "Opaque" }
            Blend One One, One One
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 5.0
            
            #include "UnityCG.cginc"
            #include "CGIncludes/NoiseSimplex.cginc"

            float2 rotate2D(float2 pos, float angle)
            {
                float cosA = cos(angle);
                float sinA = sin(angle);
                return float2(pos.x * cosA - pos.y * sinA, pos.x * sinA + pos.y * cosA);
            }
            
            
            struct v2f
            {
                float4 pos : SV_Position0;
                float3 upDir : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float3 worldNormal : TEXCOORD2;
            };
            
            struct fout
            {
                float4 sv_target : SV_Target0;
            };
            
            float4 _Color0;
            float4 _Color1;
            float4 _Color2;
            float4 _Color3;
            float _Multiplier;
            float _NoiseTile;
            float _NoiseSpeed;
            float _ChaosTile;
            float _ChaosDistort;
            float _ChaosOverlay;
            float _SpotIntens;
            float _RimPower;
            float _RotSpeed;
            
            v2f vert(appdata_full v)
            {
                v2f o;

                o.pos.xyzw = UnityObjectToClipPos(float4(v.vertex.xyz, 1));
                o.upDir.xyz = normalize(v.vertex.xyz);
                o.worldPos.xyz = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldNormal.xyz = mul((float3x3)unity_ObjectToWorld, v.normal.xyz);
                
                return o;
            }
            
            fout frag(v2f i)
            {
                fout o;
                
                float4 v;
                v.xyz = (_NoiseTile * i.upDir) / 8.0;
                v.w = _Time.y * _NoiseSpeed;
                v.xz = rotate2D(v.xz, _RotSpeed * -v.w);
                
                float n1 = snoise(v.xyzw);

                float4 v2;
                v2.xz = rotate2D(2.0 * v.xz, 0.25 * _RotSpeed * -v.w);
                v2.x = v2.x + n1 * 0.2 - v.w;
                v2.y = 0.25 * v.y;
                v2.w = 2.0 * v.w;
                
                float n2 = snoise(v2.xyzw);

                float4 v3;
                v3.x = 2.0 * v2.x;
                v3.y = 0.5 *  v.y + (n2 * 0.2 + v.w);
                v3.z = 2.0 * v2.z;
                v3.w = 4.0 * v.w;
                
                float n3 = snoise(v3.xyzw);

                float4 v4;
                v4.x = 2.0 * v2.x;
                v4.y = 0.5 * v.y  + (n2 * 0.2  + v.w);
                v4.z = 4.0 * v2.z + (n3 * 0.25 - v.w);
                v4.w = 4.0 * v.w;
                
                float n4 = snoise(v4.xyzw);
                
                float4 chaosTiled = _ChaosTile * v.xyzw;
                
                float4 v5 = chaosTiled.xyzw / float4(4, 32, 4, 4);
                
                float n5 = snoise(v5.xyzw);
                
                chaosTiled.y  = 2.0 * abs(n5) * _ChaosDistort + (chaosTiled.y / 32.0);
                float n6 = snoise(float4(0.5, 2.0, 0.5, 0.5) * chaosTiled.xyzw);
                
                chaosTiled.xz = 2.0 * abs(n6) * _ChaosDistort + (chaosTiled.xz / 2.0);
                float n7 = snoise(float4(2.0, 4.0, 2.0, 1.0) * chaosTiled.xyzw);

                float n1234 = max(0,(n4 * 0.125 + n3 * 0.25 + n1 + 0.5 * n2) * 0.2 + 0.6);
                float n567 = min(1, 0.9 * sin(2.0 * abs(n5) + abs(n6) - 0.5 * abs(n7)) + 1.0);
                
                float n8 = snoise(float4(0.09, 0.01125, 0.09, 0.36) * v.xyzw);
                
                float animPower = n567 * _SpotIntens * saturate(-n8 - 0.55) + (1 - min(1, 0.7 * n567 * _SpotIntens * saturate(n8 - 0.7)));
                animPower = min(1, n1234 * animPower * lerp(1, n567, _ChaosOverlay));
                
                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                float3 worldNormal = normalize(i.worldNormal);
                float nDotV = dot(worldNormal.xyz, viewDir.xyz);
                
                float rimPower = pow(max(0, 1.0 - abs(nDotV)), _RimPower);
                float3 finalColor = rimPower * _Color3.xyz
                                  + _Color2.xyz
                                  + animPower * lerp(_Color1, _Color0, animPower);
                o.sv_target.xyz = _Multiplier * finalColor.xyz;
                o.sv_target.w = 1;
                return o;
            }
            ENDCG
        }
    }
}