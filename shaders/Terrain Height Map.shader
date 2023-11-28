Shader "VF Shaders/Replacement/Terrain Height Map" {
    Properties {
        _Radius ("Radius", Float) = 200
    }
    SubShader {
        Tags { "RenderType" = "Opaque" "ReplaceTag" = "Terrain Planet" }
        Pass {
            Tags { "RenderType" = "Opaque" "ReplaceTag" = "Terrain Planet" }
            Cull Front
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 5.0
            
            #include "UnityCG.cginc"
            
            struct v2f
            {
                float4 pos : SV_POSITION0;
                float3 vertex : TEXCOORD0;
                float2 texcoord : TEXCOORD1;
            };
            
            struct fout
            {
                float4 sv_target : SV_Target0;
            };
            
            float _Radius;
            
            v2f vert(appdata_full v)
            {
                v2f o;

                o.pos = UnityObjectToClipPos(v.vertex.xyz);
                o.vertex.xyz = v.vertex.xyz;
                o.texcoord.x = v.texcoord.x;
                
                return o;
            }
            
            fout frag(v2f i)
            {
                fout o;
                
                if (_Radius < 1.0) {
                    o.sv_target = float4(0.0, 0.0, 0.0, 1.0);
                    return o;
                }
                
                o.sv_target.x = length(i.vertex.xyz) - _Radius;
                o.sv_target.y = i.texcoord.x;
                o.sv_target.zw = float2(0.0, 1.0);
                return o;
            }
            ENDCG
        }
    }
    SubShader {
        Tags { "RenderType" = "Opaque" "ReplaceTag" = "Gas Giant" }
        Pass {
            Tags { "RenderType" = "Opaque" "ReplaceTag" = "Gas Giant" }
            Cull Front
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 5.0
            
            #include "UnityCG.cginc"
            
            struct v2f
            {
                float4 pos : SV_POSITION0;
            };
            struct fout
            {
                float4 sv_target : SV_Target0;
            };
            
            v2f vert(appdata_full v)
            {
                v2f o;
                
                o.pos = UnityObjectToClipPos(v.vertex.xyz);
                
                return o;
            }
            
            fout frag(v2f i)
            {
                fout o;
                
                o.sv_target = float4(0.0, 0.0, 0.0, 1.0);
                
                return o;
            }
            ENDCG
        }
    }
}