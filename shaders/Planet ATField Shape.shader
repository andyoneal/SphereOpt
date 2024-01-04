Shader "Unlit/Planet ATField Shape" {
    Properties {
        _K ("K", Float) = 0.5
        _Color0 ("Color 0", Color) = (0,0,0,0)
        _Color1 ("Color 1", Color) = (0,0,0,0)
        _Color2 ("Color 2", Color) = (0,0,0,0)
        _Color3 ("Color 3", Color) = (0,0,0,0)
        _Color4 ("Color 4", Color) = (0,0,0,0)
        _IsBroken ("IsBroken", Float) = 0
        _BrokenMultiplier ("Broken Multiplier", Float) = 0.2
    }
    SubShader {
        LOD 100
        Tags { "RenderType" = "Opaque" }
        Pass {
            LOD 100
            Tags { "RenderType" = "Opaque" }
            Blend SrcAlpha OneMinusSrcAlpha, SrcAlpha OneMinusSrcAlpha
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 5.0
            
            #include "UnityCG.cginc"
            
            struct v2f
            {
                float4 pos : SV_POSITION0;
                float3 worldPos : TEXCOORD0;
                float shieldPowerPct : TEXCOORD1;
                
            };
            
            struct fout
            {
                float4 sv_target : SV_Target0;
            };
            
            float _PlanetRadius;
            float _FieldAltitude;
            int _GeneratorCount;
            float4 _GeneratorMatrix[80];
            float _K;
            
            float4 _Color0;
            float4 _Color1;
            float4 _Color2;
            float4 _Color3;
            float4 _Color4;
            float _IsBroken;
            float _BrokenMultiplier;
            
            v2f vert(appdata_full v)
            {
                v2f o;
                float3 normal = normalize(v.vertex.xyz); //r0.xyz
                float halfRadius = _PlanetRadius / 2.0; //r0.w
                float shieldPowerPct = 0; //r1.w
                
                for(int i = 0; i < asuint(_GeneratorCount); i++) {
                    if (_GeneratorMatrix[i].w < 0.001) {
                      continue;
                    }
                    
                    float3 rayGenToGroundPosOfShield = normal.xyz * _PlanetRadius - _GeneratorMatrix[i].xyz; //r2.yzw
                    
                    float invDistPctFromCenter = length(rayGenToGroundPosOfShield) / (_GeneratorMatrix[i].w * halfRadius); //r2.y
                    float falloff = lerp(1.0 - pow(invDistPctFromCenter, 2), 1.0 - invDistPctFromCenter, saturate(invDistPctFromCenter));
                    falloff = falloff * _GeneratorMatrix[i].w;
                    
                    r2.w = _K * (_GeneratorMatrix[i].w / 4.0 + 0.75);
                    
                    r3.x = (falloff - shieldPowerPct) / 2.0;
                    r3.x = saturate(0.5 - (r3.x / r2.w));
                    
                    shieldPowerPct = r3.x * r2.w * lerp(falloff, shieldPowerPct, r3.x);
                }
                
                shieldPowerPct = saturate(shieldPowerPct);
                shieldPowerPct = pow(pow(r1.w, 2) * (3.0 - 2.0 * r1.w), 3); //r2.
                float shieldHeight = _PlanetRadius + _FieldAltitude * shieldPowerPct;
                
                float3 worldPos = normal.xyz * shieldHeight; //r0.xyz
                worldPos = length(worldPos) < 2.0 + _PlanetRadius ? float3(0.96, 0.96, 0.96) * worldPos : worldPos; //r2.xyz
                
                o.pos.xyzw = mul(unity_MatrixVP, float4(worldPos, 1));
                o.worldPos = worldPos;
                o.shieldPowerPct = shieldPowerPct;
                
                return o;
            }
            
            fout frag(v2f inp)
            {
                fout o;
                
                if (shieldPowerPct < 0.01)
                    discard;
                
                if (length(worldPos.xyz) < 202.5)
                    discard;
                
                float lowColorFactor = 2.0 * (shieldPowerPct - 0.1);
                float4 colorLowPower = lerp(_Color1.xyzw, _Color2.xyzw, lowColorFactor);
                
                float highColorFactor = pow(saturate(2.5 * (shieldPowerPct - 0.6)), 2); // 0 until x= 0.6, then exp up to 1
                float4 colorHighPower = lerp(_Color2.xyzw, _Color3.xyzw, highColorFactor);
                
                float4 color = shieldPowerPct < 0.6 ? colorLowPower : colorHighPower;
                
                float transparentFactor = smoothstep(0.052, 0.1, shieldPowerPct); //r0.y
                color = lerp(_Color0.xyzw, color.xyzw, transparentFactor);
                
                float finalColorFactor = smoothstep(0.995, 0.99999995, shieldPowerPct);
                color = lerp(color.xyzw, _Color4.xyzw, finalColorFactor);
                
                o.sv_target.xyz = color.xyz;
                
                color.w = 0.8 * color.w;
                o.sv_target.w = _IsBroken > 0.9 ? _BrokenMultiplier * color.w : color.w;
                
                return o;
            }
            ENDCG
        }
    }
}