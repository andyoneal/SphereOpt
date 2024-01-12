Shader "Unlit/Planet ATField Shape REPLACE" {
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
        Tags { "DisableBatching" = "true" "IGNOREPROJECTOR" = "true" "QUEUE" = "Transparent+100" "RenderType" = "Transparent" }
        Pass {
            LOD 100
            Tags { "DisableBatching" = "true" "IGNOREPROJECTOR" = "true" "QUEUE" = "Transparent+100" "RenderType" = "Transparent" }
            Blend SrcAlpha OneMinusSrcAlpha, SrcAlpha OneMinusSrcAlpha
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 5.0
            #pragma enable_d3d11_debug_symbols
            
            #include "UnityCG.cginc"
            
            struct v2f
            {
                float4 pos : SV_POSITION0;
                float3 worldPos : TEXCOORD0;
                float shieldHeightPct : TEXCOORD1;
                
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
            
            float sdf(float3 centerPos, float3 pointPos, float radius, float scale)
            {
                radius = radius * scale;
                
                float distfromCenter = distance(centerPos, pointPos); //r2.yzw
                
                //center = 0, edge = 1, outside edge > 1
                float pctDistShieldRadius = distfromCenter / radius; //r2.y
                //center = 1, edge = 0, outside edge < 0
                float distFromEdge = lerp(1.0 - pow(pctDistShieldRadius, 2), 1.0 - pctDistShieldRadius, saturate(pctDistShieldRadius));
                return distFromEdge * scale;
            }
            
            v2f vert(appdata_full v)
            {
                v2f o;
                float3 normal = normalize(v.vertex.xyz); //r0.xyz
                float halfRadius = _PlanetRadius / 2.0; //r0.w
                float3 surfaceLevelPos = _PlanetRadius * normal.xyz;
                
                float shieldHeightPct = 0; //r1.w
                
                for(uint i = 0; i < asuint(_GeneratorCount); i++) {
                    float shieldGeneratorPower = _GeneratorMatrix[i].w;
                    
                    if (shieldGeneratorPower < 0.001) {
                      continue;
                    }
                    
                    float3 shieldGeneratorPos = _GeneratorMatrix[i].xyz;
                    
                    //center = 1, edge = 0, outside edge < 0
                    float dist = sdf(shieldGeneratorPos, surfaceLevelPos, halfRadius, shieldGeneratorPower);
                    
                    float kPower = _K * (shieldGeneratorPower / 4.0 + 0.75); //r2.w // 2.1 * [.75, 1.0]
                    float powerFactor = saturate(0.5 - ((0.5 * (dist - shieldHeightPct)) / kPower));
                    
                    shieldHeightPct = powerFactor * kPower * (1.0 - powerFactor) + lerp(dist, shieldHeightPct, powerFactor);
                }
                
                shieldHeightPct = saturate(shieldHeightPct);
                shieldHeightPct = pow(pow(shieldHeightPct, 2) * (3.0 - 2.0 * shieldHeightPct), 3); //r2.
                float shieldHeight = _PlanetRadius + _FieldAltitude * shieldHeightPct;
                
                float3 worldPos = normal.xyz * shieldHeight; //r0.xyz
                worldPos = length(worldPos) < 2.0 + _PlanetRadius ? float3(0.96, 0.96, 0.96) * worldPos : worldPos; //r2.xyz
                
                o.pos.xyzw = mul(unity_MatrixVP, float4(worldPos, 1));
                o.worldPos = worldPos;
                o.shieldHeightPct = shieldHeightPct;
                
                return o;
            }
            
            fout frag(v2f i)
            {
                fout o;
                
                if (i.shieldHeightPct < 0.01)
                    discard;
                
                if (length(i.worldPos.xyz) < _PlanetRadius + 2.5)
                    discard;
                
                float lowColorFactor = 2.0 * (i.shieldHeightPct - 0.1);
                float4 colorLowPower = lerp(_Color1.xyzw, _Color2.xyzw, lowColorFactor);
                
                float highColorFactor = pow(saturate(2.5 * (i.shieldHeightPct - 0.6)), 2); // 0 until x= 0.6, then exp up to 1
                float4 colorHighPower = lerp(_Color2.xyzw, _Color3.xyzw, highColorFactor);
                
                float4 color = i.shieldHeightPct < 0.6 ? colorLowPower : colorHighPower;
                
                float transparentFactor = smoothstep(0.052, 0.1, i.shieldHeightPct); //r0.y
                color = lerp(_Color0.xyzw, color.xyzw, transparentFactor);
                
                float finalColorFactor = smoothstep(0.995, 0.99999995, i.shieldHeightPct);
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