Shader "VF Shaders/Forward/GeoObject Instancing" {
    Properties {
        _Color ("Color 颜色", Color) = (1,1,1,1)
        _SpecularColor ("Specular Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB) 漫反射 (A) 颜色遮罩", 2D) = "white" {}
        _NormalTex ("Normal 法线", 2D) = "bump" {}
        _MS_Tex ("Metallic (R) 金属 (A) 高光", 2D) = "black" {}
        _EmissionTex ("Emission (RGB) 自发光  (A) 抖动遮罩", 2D) = "black" {}
        _AlbedoMultiplier ("漫反射倍率", Float) = 1
        _NormalMultiplier ("法线倍率", Float) = 1
        _MetallicMultiplier ("金属倍率", Float) = 1
        _SmoothMultiplier ("高光倍率", Float) = 1
        _EmissionMultiplier ("自发光倍率", Float) = 5.5
        _EmissionJitter ("自发光抖动倍率", Float) = 0
        _EmissionJitterTex ("自发光抖动色条", 2D) = "white" {}
        _Size ("尺寸", Vector) = (1,1,1,1)
        [Toggle(_ENABLE_VFINST)] _ToggleVerta ("Enable VFInst ?", Float) = 0
    }
    SubShader {
        LOD 200
        Tags { "DisableBatching" = "true" "RenderType" = "Opaque" }
        Pass {
            Name "FORWARD"
            LOD 200
            Tags { "DisableBatching" = "true" "LIGHTMODE" = "FORWARDBASE" "RenderType" = "Opaque" "SHADOWSUPPORT" = "true" }
            GpuProgramID 31749
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 5.0
            #pragma enable_d3d11_debug_symbols

            #include "UnityCG.cginc"
            #include "CGIncludes/DSPCommon.cginc"

            struct v2f
            {
                float4 pos : SV_POSITION0;
                float4 TBNW0 : TEXCOORD0;
                float4 TBNW1 : TEXCOORD1;
                float4 TBNW2 : TEXCOORD2;
                float4 uv_objId : TEXCOORD3;
                float3 upDir : TEXCOORD4;
                float3 indirectLight : TEXCOORD5;
                UNITY_SHADOW_COORDS(7)
                float4 unused_unk : TEXCOORD8;
            };

            struct fout
            {
                float4 sv_target : SV_Target0;
            };

            StructuredBuffer<GPUOBJECT> _InstBuffer;

            float4 _Size;
            float4 _LightColor0;
            float4 _Global_AmbientColor0;
            float4 _Global_AmbientColor1;
            float4 _Global_AmbientColor2;
            float4 _Global_SunsetColor0;
            float4 _Global_SunsetColor1;
            float4 _Global_SunsetColor2;
            float4 _Global_PointLightPos;
            float4 _Color;
            float _AlbedoMultiplier;
            float _NormalMultiplier;
            float _MetallicMultiplier;
            float _SmoothMultiplier;
            float4 _SpecularColor;

            sampler2D _MainTex;
            sampler2D _NormalTex;
            sampler2D _MS_Tex;
            sampler2D _EmissionTex;
            samplerCUBE _Global_PGI;

            // Keywords: DIRECTIONAL
            v2f vert(appdata_full v, uint instanceID : SV_InstanceID, uint vertexID : SV_VertexID)
            {
                v2f o;

                float3 objectPos = _Size.xyz * v.vertex.xyz; //cb0[33]

                float objId = _InstBuffer[instanceID].objId; //r1.x
                float3 pos = _InstBuffer[instanceID].pos; //r1.yzw

                objectPos = objId < 0.5 ? float3(0,0,0) : objectPos; //r0.xyz
                float3 objectNormal = objId < 0.5 ? float3(0,0,0) : v.normal.xyz; //r3.xyz
                float3 objectTangent = objId < 0.5 ? float3(0,0,0) : v.tangent.xyz; //r4.xyz

                float3 worldPos = objectPos;
                float3 worldNormal = objectNormal;
                float3 worldTangent = objectTangent;
                if (objId > 0.5) {
                    float4 rot = _InstBuffer[instanceID].rot; //r5.xyzw
                    worldPos = pos + rotate_vector_fast(objectPos, rot); //r0.xyz
                    worldNormal = rotate_vector_fast(objectNormal, rot); //r6.xyz //r3.xyz
                    worldTangent = rotate_vector_fast(objectTangent, rot); //float3(r1.x, r4.yz);
                }

                worldNormal = normalize(worldNormal); //r1.xyz

                float vertw = objId < 0.5 ? 0 : 1
                float3 worldPos = mul(unity_objectToWorld(float4(worldPos, vertw)); //r0.xyz
                float4 clipPos = mul(unity_MatrixVP, worldPos); //r3.xyzw

                worldNormal = UnityObjectToWorldNormal(worldNormal); //r1.xyz
                worldTangent = UnityObjectToWorldDir(worldTangent.xyz); //r4.xyz
                float tanw = objId < 0.5 ? 0 : v.tangent.w;
                float3 worldBinormal = calculateBinormal(float4(worldTangent, tanw), worldNormal); //r5.xyz

                o.pos.xyzw = clipPos.xyzw;

                o.TBNW0.x = worldTangent.x; //t
                o.TBNW0.y = binormal.x; //b
                o.TBNW0.z = worldNormal.x; //n
                o.TBNW0.w = worldPos.x; //w

                o.TBNW1.x = worldTangent.y;
                o.TBNW1.y = binormal.y;
                o.TBNW1.z = worldNormal.y;
                o.TBNW1.w = worldPos.y;

                o.TBNW2.x = worldTangent.z;
                o.TBNW2.y = binormal.z;
                o.TBNW2.z = worldNormal.z;
                o.TBNW2.w = worldPos.z;

                o.uv_objId.xy = v6.xy;
                o.uv_objId.zw = uint2(objId, objId); //r2.xy
                o.upDir.xyz = normalize(pos); //updir?
                o.indirectLight.xyz = ShadeSH9(float4(worldVNormal, 1.0));
                UNITY_TRANSFER_SHADOW(o, float(0,0))
                o.unused_unk.xyzw = float4(0,0,0,0);

                return o;
            }

            fout frag(v2f i)
            {
                fout o;
                
                float3 worldPos; //r0.yzw
                worldPos.x = i.TBNW0.w;
                worldPos.y = i.TBNW1.w;
                worldPos.z = i.TBNW2.w;
                
                float3 rayPosToCam = _WorldSpaceCameraPos - worldPos; //r1.xyz
                float3 viewDir = normalize(r1.xyz); //r2.xyz

                float4 albedo = tex2D(_MainTex, i.uv_objId.xy); //r3.xyzw
                albedo.xyz = _AlbedoMultiplier * albedo.xyz;
                
                float3 tangentNormal = UnpackNormal(tex2D(_NormalTex, i.uv_objId.xy)); //r5.xyz
                tangentNormal.xy = _NormalMultiplier * tangentNormal.xy; //r5.xyz
                tangentNormal = normalize(tangentNormal); //r5.xyz
                
                float2 metal_smooth = tex2D(_MS_Tex, i.uv_objId.xy).xw; //r4.zw
                metal_smooth = saturate(float2(_MetallicMultiplier, _SmoothMultiplier) * metal_smooth); //r4.xy
                
                float3 emission = tex2D(_EmissionTex, i.uv_objId.xy).xyz; //r6.xyz
                
                r7.xyz = lerp(float3(1,1,1), _Color.xyz, saturate(1.25 * (albedo.w - 0.1)));
                r8.xyz = r7.xyz * albedo.xyz;
                
                //shadow stuff
                r9.x = cb4[9].z; //unity_MatrixV
                r9.y = cb4[10].z; //unity_MatrixV
                r9.z = cb4[11].z; //unity_MatrixV
                r1.w = dot(r1.xyz, r9.xyz);
                r9.xyz = -cb3[25].xyz + worldPos; //unity_ShadowFadeCenterAndType
                r2.w = dot(r9.xyz, r9.xyz);
                r2.w = sqrt(r2.w);
                r2.w = r2.w + -r1.w;
                r1.w = cb3[25].w * r2.w + r1.w; //unity_ShadowFadeCenterAndType
                r1.w = saturate(r1.w * cb3[24].z + cb3[24].w); //_LightShadowData
                r2.w = cmp(cb5[0].x == 1.000000);
                if (r2.w != 0) {
                    r2.w = cmp(cb5[0].y == 1.000000);
                    r9.xyz = cb5[2].xyz * i.TBNW1.www;
                    r9.xyz = cb5[1].xyz * i.TBNW0.www + r9.xyz;
                    r9.xyz = cb5[3].xyz * i.TBNW2.www + r9.xyz;
                    r9.xyz = cb5[4].xyz + r9.xyz;
                    r0.yzw = r2.www ? r9.xyz : worldPos;
                    r0.yzw = -cb5[6].xyz + r0.yzw;
                    r9.yzw = cb5[5].xyz * r0.yzw;
                    r0.y = r9.y * 0.25 + 0.75;
                    r0.z = cb5[0].z * 0.5 + 0.75;
                    r9.x = max(r0.y, r0.z);
                    r9.xyzw = t6.Sample(s0_s, r9.xzw).xyzw;
                } else {
                    r9.xyzw = float4(1,1,1,1);
                }
                r0.y = saturate(dot(r9.xyzw, cb2[46].xyzw)); //unity_OcclusionMaskSelector
                r0.zw = v7.xy / v7.ww;
                r0.z = t4.Sample(s1_s, r0.zw).x;
                r0.y = r0.y + -r0.z;
                r0.y = r1.w * r0.y + r0.z;
                
                float3 worldNormal;
                worldNormal.x = dot(i.TBNW0.xyz, tangentNormal.xyz);
                worldNormal.y = dot(i.TBNW1.xyz, tangentNormal.xyz);
                worldNormal.z = dot(i.TBNW2.xyz, tangentNormal.xyz);
                worldNormal = normalize(worldNormal); //r5.xyz
                
                r0.z = metal_smooth.x * 0.85 + 0.649;
                r0.w = metal_smooth.x * 0.85 + 0.149;
                float perceptualRoughness = 1 - metal_smooth.y * 0.97; //r1.w
                
                float3 halfDir = normalize(viewDir + _WorldSpaceLightPos0.xyz); //r1.xyz
                
                float roughness = perceptualRoughness * perceptualRoughness; //r0.x
                float roughnessSqr = roughness * roughness; //r2.w
                
                float nDotL = dot(worldNormal, _WorldSpaceLightPos0.xyz); //r3.w
                float clamped_nDotL = max(0, nDotL); //r4.x
                float nDotV = dot(worldNormal, viewDir); //r4.z
                float clamped_nDotV = max(0, nDotV); //r4.z
                float nDotH = dot(worldNormal, halfDir); //r4.w
                float clamped_nDotH = max(0, nDotH); //r4.w
                float vDotH = dot(viewDir, halfDir); //r1.x
                float clamped_vDotH = max(0, vDotH); //r1.x
                
                r1.y = pow(nDotL * 0.35 + 1, 3);
                float upDotL = dot(i.upDir, _WorldSpaceLightPos0.xyz); //r1.z
                
                float nDotUp = dot(worldNormal, i.upDir); //r3.w
                
                float magSqrUpDir = dot(i.upDir, i.upDir);
                //rearranged cross()
                r9.xyz = float3(0,1,0) * i.upDir.yzx;
                r9.xyz = i.upDir.xyz * float3(1,0,0) - r9.xyz;
                
                r7.w = dot(r9.xy, r9.xy);
                r7.w = rsqrt(r7.w);
                r9.xyz = r9.xyz * r7.www;
                
                r9.xyz = magSqrUpDir > 0.01 && i.upDir.y < 0.9999 ? r9.xyz : float3(0,1,0);
                
                r6.w = dot(r9.xy, r9.xy); //magSqr
                r5.w = magSqrUpDir > 0.01 && r6.w > 0.01 : 0;
                
                //rearranged cross()
                r10.xyz = i.upDir.yzx * r9.xyz;
                r10.xyz = r9.zxy * i.upDir.zxy + -r10.xyz;
                r10.xyz = normalize(r10.xyz);
                
                r6.w = 2 * dot(-r2.xyz, worldNormal);
                r2.xyz = worldNormal * -r6.www - r2.xyz;
                
                r9.x = dot(r2.zx, -r9.xy);
                r9.y = dot(r2.xyz, i.upDir.xyz);
                
                r10.xyz = r5.www ? -r10.xyz : float3(-0,-0,-1);
                r9.z = dot(r2.xyz, r10.xyz);
                
                r5.w = 10 * pow(perceptualRoughness, 0.4);
                r9.xyz = _Global_PGI.SampleLevel(s2_s, r9.xyz, r5.w).xyz;
                r1.w = (r0.w * 0.7 + 0.3) * (1 - perceptualRoughness);
                r9.xyz = r9.xyz * r1.www;
                
                if (upDotL <= 1) {
                    r10.xyzw = float4(-0.200000003,-0.100000001,0.100000001,0.300000012) + upDotL;
                    r10.xyzw = saturate(float4(5,10,5,5) * r10.xyzw);
                    r11.xyz = float3(1,1,1) + -_Global_SunsetColor0.xyz;
                    r11.xyz = r10.xxx * r11.xyz + _Global_SunsetColor0.xyz;
                    r12.xyz = float3(1.25,1.25,1.25) * _Global_SunsetColor1.xyz;
                    r13.xyz = -_Global_SunsetColor1.xyz * float3(1.25,1.25,1.25) + _Global_SunsetColor0.xyz;
                    r12.xyz = r10.yyy * r13.xyz + r12.xyz;
                    r13.xyz = cmp(float3(0.200000003,0.100000001,-0.100000001) < upDotL);
                    r14.xyz = float3(1.5,1.5,1.5) * _Global_SunsetColor2.xyz;
                    r15.xyz = _Global_SunsetColor1.xyz * float3(1.25,1.25,1.25) + -r14.xyz;
                    r10.xyz = r10.zzz * r15.xyz + r14.xyz;
                    r14.xyz = r14.xyz * r10.www;
                    r10.xyz = r13.zzz ? r10.xyz : r14.xyz;
                    r10.xyz = r13.yyy ? r12.xyz : r10.xyz;
                    r10.xyz = r13.xxx ? r11.xyz : r10.xyz;
                } else {
                    r10.xyz = float3(1,1,1);
                }
                r10.xyz = _LightColor0.xyz * r10.xyz;
                
                r11.xy = saturate(float2(0.15, 3) * upDotL);
                
                r5.w = 1 - r0.y;
                
                r0.y = r11.x * r5.w + r0.y;
                r0.y = 0.8 * r0.y;
                r10.xyz = r0.yyy * r10.xyz;
                
                r0.y = clamped_nDotH * clamped_nDotH;
                r11.xz = roughness * roughness + float2(-1,1);
                r0.x = r0.y * r11.x + 1;
                r0.x = rcp(r0.x);
                r0.x = r0.x * r0.x;
                r0.x = r0.x * roughnessSqr;
                r0.x = 0.25 * r0.x;
                r0.y = r11.z * r11.z;
                r2.w = 0.125 * r0.y;
                r0.y = -r0.y * 0.125 + 1;
                r4.z = r4.z * r0.y + r2.w;
                r0.y = clamped_nDotL * r0.y + r2.w;
                
                r11.xz = float2(1,1) + -r0.zw;
                
                r2.w = r1.x * -5.55472994 + -6.98316002;
                r1.x = r2.w * r1.x;
                r1.x = exp2(r1.x);
                r0.z = r11.x * r1.x + r0.z;
                r0.x = r0.x * r0.z;
                r0.y = r4.z * r0.y;
                r0.y = rcp(r0.y);
                
                r0.z = upDotL > 0;
                r12.xyz = -_Global_AmbientColor1.xyz + _Global_AmbientColor0.xyz;
                r11.xyw = r11.yyy * r12.xyz + _Global_AmbientColor1.xyz;
                r1.x = saturate(upDotL * 3 + 1);
                r12.xyz = -_Global_AmbientColor2.xyz + _Global_AmbientColor1.xyz;
                r12.xyz = r1.xxx * r12.xyz + _Global_AmbientColor2.xyz;
                r11.xyw = r0.zzz ? r11.xyw : r12.xyz;
                r0.z = saturate(nDotUp * 0.300000012 + 0.699999988);
                r12.xyz = r11.xyw * r0.zzz;
                r12.xyz = r12.xyz * r1.yyy;
                
                r0.z = _Global_PointLightPos.w >= 0.5;
                r1.x = length(_Global_PointLightPos.xyz);
                r1.y = r1.x - 5;
                r2.w = saturate(r1.y);
                
                r3.w = dot(-i.upDir.xyz, _WorldSpaceLightPos0.xyz);
                r3.w = saturate(5 * r3.w);
                
                r2.w = r3.w * r2.w;
                r13.xyz = _Global_PointLightPos.xyz - i.upDir.xyz * r1.yyy;
                r1.y = dot(r13.xyz, r13.xyz);
                r1.y = sqrt(r1.y);
                r4.z = 20 - r1.y;
                r4.z = 0.05 * r4.z;
                r4.z = max(0, r4.z);
                r4.z = r4.z * r4.z;
                r4.w = r1.y < 0.001;
                r14.xyz = float3(1.3, 1.1, 0.6) * r2.www;
                r13.xyz = r13.xyz / r1.yyy;
                r1.y = saturate(dot(r13.xyz, worldNormal));
                r1.y = r1.y * r4.z;
                r1.y = r1.y * r2.w;
                r5.xyz = float3(1.3, 1.1, 0.6) * r1.yyy;
                r5.xyz = r4.www ? r14.xyz : r5.xyz;
                r5.xyz = _Global_PointLightPos.w >= 0.5 ? r5.xyz : 0;
                
                r1.y = pow(r11.z, 0.6);
                r2.w = 0.2 * r11.z * r8.x + r0.w;
                
                r13.xyz = r10.xyz * clamped_nDotL;
                
                r4.z = r1.y * 0.2 + 0.8;
                r14.xyz = r5.xyz * r4.zzz;
                
                r13.xyz = r13.xyz * r1.yyy + r14.xyz;
                
                r3.xyz = lerp(float3(1,1,1), albedo.xyz * r7.xyz, r0.w);
                r3.xyz = _SpecularColor.xyz * r3.xyz;
                r3.xyz = r3.xyz * r10.xyz;
                
                r0.x = r0.x * r0.y + 0.0318309888;
                
                r3.xyz = r3.xyz * r0.xxx;
                r4.xzw = r5.xyz + clamped_nDotL;
                r3.xyz = r4.xzw * r3.xyz;
                
                if (_Global_PointLightPos.w >= 0.5) {
                    r0.x = r1.x - 20;
                    
                    r0.y = saturate(r0.x) * r3.w;
                    
                    r4.xzw = _Global_PointLightPos.xyz - i.upDir.xyz * r0.xxx;
                    r0.x = length(r4.xzw);
                    
                    r0.z = pow(max(0, 0.025 * (40 - r0.x)), 2);
                    
                    r1.x = r0.x < 0.001;
                    
                    r7.xyz = float3(1.3, 1.1, 0.6) * r0.yyy;
                    
                    r4.xzw = r4.xzw / r0.xxx;
                    
                    r0.x = max(0, dot(r2.xyz, r4.xzw));
                    r1.y = exp2(9.965784 * metal_smooth.y);  //log(0.001) / log(0.5) ??
                    r0.x = pow(r0.x, r1.y);
                    
                    r0.x = 20 * r0.x * metal_smooth.y;
                    r0.x = r0.x * r0.z * r0.y;
                    r0.xyz = float3(1.3,1.1, 0.6) * r0.xxx;
                    
                    r0.xyz = r1.xxx ? r7.xyz : r0.xyz;
                } else {
                    r0.xyz = float3(0,0,0);
                }
                r0.xyz = r0.xyz * r2.www;
                
                r2.xyz = r8.xyz * float3(0.5, 0.5, 0.5) + float3(0.5, 0.5, 0.5);
                r0.xyz = r2.xyz * r0.xyz;
                r0.xyz = r3.xyz * r2.www + r0.xyz;
                
                r2.xyz = r12.xyz * r8.xyz;
                
                r0.w = 1 - r0.w * 0.6;
                
                r1.x = dot(r11.xyx, float3(0.3, 0.6, 0.1));
                r1.y = max(_Global_AmbientColor0.z, max(_Global_AmbientColor0.x, _Global_AmbientColor0.y));
                r1.xy = float2(0.003, 0.003) + r1.xy;
                r1.y = 1 / r1.y;
                r3.xyz = r11.xyw - r1.xxx;
                r3.xyz = r3.xyz * float3(0.4, 0.4, 0.4) + r1.xxx;
                r3.xyz = r3.xyz * r1.yyy;
                r3.xyz = float3(1.7, 1.7, 1.7) * r3.xyz;
                r3.xyz = r9.xyz * r3.xyz;
                
                r1.x = saturate(upDotL * 2 + 0.5) * 0.7 + 0.3;
                r1.xyz = r3.xyz * (r1.xxx + r5.xyz);
                r0.xyz = r13.xyz * r8.xyz + r0.xyz;
                r0.xyz = r2.xyz * r0.www + r0.xyz;
                r0.xyz = lerp(r0.xyz, r1.xyz * r8.xyz, r1.www);
                
                r0.w = dot(r0.xyz, float3(0.3, 0.6,0.1));
                r1.x = cmp(1 < r0.w);
                r1.yzw = r0.xyz / r0.www;
                r0.w = log(log(r0.w) + 1) + 1;
                r1.yzw = r1.yzw * r0.www;
                r0.xyz = r1.xxx ? r1.yzw : r0.xyz;
                
                r0.xyz = r8.xyz * i.indirectLight.xyz + r0.xyz + emission;
                
                o.sv_target.xyz = r0.xyz
                o.sv_target.w = 1;

                return o;
            }
            ENDCG
        }
        Pass {
            Name "ShadowCaster"
            LOD 200
            Tags { "DisableBatching" = "true" "LIGHTMODE" = "SHADOWCASTER" "RenderType" = "Opaque" "SHADOWSUPPORT" = "true" }
            GpuProgramID 152883
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            struct v2f
            {
                float4 position : SV_POSITION0;
                float4 texcoord1 : TEXCOORD1;
                float3 texcoord2 : TEXCOORD2;
            };
            struct fout
            {
                float4 sv_target : SV_Target0;
            };
            // $Globals ConstantBuffers for Vertex Shader
            float4 _Size;
            // $Globals ConstantBuffers for Fragment Shader
            // Custom ConstantBuffers for Vertex Shader
            // Custom ConstantBuffers for Fragment Shader
            // Texture params for Vertex Shader
            // Texture params for Fragment Shader

            // Keywords: SHADOWS_DEPTH
            v2f vert(appdata_full v)
            {
                v2f o;
                struct t0_t {
                  float val[8];
                };
                StructuredBuffer<t0_t> t0 : register(t0);

                cbuffer cb4 : register(b4)
                {
                  float4 cb4[21];
                }

                cbuffer cb3 : register(b3)
                {
                  float4 cb3[7];
                }

                cbuffer cb2 : register(b2)
                {
                  float4 cb2[6];
                }

                cbuffer cb1 : register(b1)
                {
                  float4 cb1[1];
                }

                cbuffer cb0 : register(b0)
                {
                  float4 cb0[34];
                }

                void main(
                  float4 v0 : POSITION0,
                  float3 v1 : NORMAL0,
                  float4 v2 : TANGENT0,
                  float4 v3 : COLOR0,
                  uint v4 : SV_VertexID0,
                  uint v5 : SV_InstanceID0,
                  float4 v6 : TEXCOORD0,
                  float4 v7 : TEXCOORD1,
                  float2 v8 : TEXCOORD2,
                  out float4 o0 : SV_POSITION0,
                  out float4 o1 : TEXCOORD1,
                  out float3 o2 : TEXCOORD2)
                {
                // Needs manual fix for instruction:
                // unknown dcl_: dcl_input_sgv v5.x, instance_id
                  float4 r0,r1,r2,r3,r4,r5,r6,r7,r8;
                  uint4 bitmask, uiDest;
                  float4 fDest;

                  r0.xyz = cb0[33].xyz * v0.xyz;
                  r1.x = t0[v5.x].val[0/4];
                  r1.y = t0[v5.x].val[0/4+1];
                  r1.z = t0[v5.x].val[0/4+2];
                  r1.w = t0[v5.x].val[0/4+3];
                  r2.xy = (uint2)r1.xx;
                  r0.w = cmp(r2.y < 0.5);
                  r0.xyz = r0.www ? float3(0,0,0) : r0.xyz;
                  r3.x = v0.w;
                  r3.yzw = v1.xyz;
                  r3.xyzw = r0.wwww ? float4(0,0,0,0) : r3.yzwx;
                  if (r0.w == 0) {
                    r4.x = t0[v5.x].val[16/4];
                    r4.y = t0[v5.x].val[16/4+1];
                    r4.z = t0[v5.x].val[16/4+2];
                    r4.w = t0[v5.x].val[16/4+3];
                    r5.xyzw = r4.zzxy + r4.zzxy;
                    r6.xyz = r5.zwy * r4.xyz;
                    r7.xyzw = r5.xyzw * r4.xyww;
                    r0.w = r5.y * r4.w;
                    r6.xyz = r6.yxx + r6.zzy;
                    r6.xyz = float3(1,1,1) + -r6.xyz;
                    r2.zw = r6.xy * r0.xy;
                    r1.x = r4.x * r5.w + -r0.w;
                    r2.z = r1.x * r0.y + r2.z;
                    r4.zw = r7.xy + r7.wz;
                    r5.z = r4.w * r0.y;
                    r8.x = r4.z * r0.z + r2.z;
                    r0.w = r4.x * r5.w + r0.w;
                    r2.z = r0.w * r0.x + r2.w;
                    r4.xy = r4.yx * r5.yx + -r7.zw;
                    r8.y = r4.x * r0.z + r2.z;
                    r2.z = r4.y * r0.x + r5.z;
                    r8.z = r6.z * r0.z + r2.z;
                    r0.xyz = r8.xyz + r1.yzw;
                    r2.zw = r6.xy * r3.xy;
                    r1.x = r1.x * r3.y + r2.z;
                    r2.z = r4.w * r3.y;
                    r5.x = r4.z * r3.z + r1.x;
                    r0.w = r0.w * r3.x + r2.w;
                    r5.y = r4.x * r3.z + r0.w;
                    r0.w = r4.y * r3.x + r2.z;
                    r5.z = r6.z * r3.z + r0.w;
                    r3.xyz = r5.xyz;
                    r3.w = 1;
                  }
                  r0.w = dot(r1.yzw, r1.yzw);
                  r0.w = rsqrt(r0.w);
                  o2.xyz = r1.yzw * r0.www;
                  r0.w = dot(r3.xyz, r3.xyz);
                  r0.w = rsqrt(r0.w);
                  r1.xyz = r3.xyz * r0.www;
                  r4.xyzw = cb3[1].xyzw * r0.yyyy;
                  r4.xyzw = cb3[0].xyzw * r0.xxxx + r4.xyzw;
                  r0.xyzw = cb3[2].xyzw * r0.zzzz + r4.xyzw;
                  r0.xyzw = cb3[3].xyzw * r3.wwww + r0.xyzw;
                  r1.w = cmp(cb2[5].z != 0.000000);
                  r3.x = dot(r1.xyz, cb3[4].xyz);
                  r3.y = dot(r1.xyz, cb3[5].xyz);
                  r3.z = dot(r1.xyz, cb3[6].xyz);
                  r1.x = dot(r3.xyz, r3.xyz);
                  r1.x = rsqrt(r1.x);
                  r1.xyz = r3.xyz * r1.xxx;
                  r3.xyz = -r0.xyz * cb1[0].www + cb1[0].xyz;
                  r2.z = dot(r3.xyz, r3.xyz);
                  r2.z = rsqrt(r2.z);
                  r3.xyz = r3.xyz * r2.zzz;
                  r2.z = dot(r1.xyz, r3.xyz);
                  r2.z = -r2.z * r2.z + 1;
                  r2.z = sqrt(r2.z);
                  r2.z = cb2[5].z * r2.z;
                  r1.xyz = -r1.xyz * r2.zzz + r0.xyz;
                  r0.xyz = r1.www ? r1.xyz : r0.xyz;
                  r1.xyzw = cb4[18].xyzw * r0.yyyy;
                  r1.xyzw = cb4[17].xyzw * r0.xxxx + r1.xyzw;
                  r1.xyzw = cb4[19].xyzw * r0.zzzz + r1.xyzw;
                  r0.xyzw = cb4[20].xyzw * r0.wwww + r1.xyzw;
                  r1.x = cb2[5].x / r0.w;
                  r1.x = min(0, r1.x);
                  r1.x = max(-1, r1.x);
                  r0.z = r1.x + r0.z;
                  r1.x = min(r0.z, r0.w);
                  r1.x = r1.x + -r0.z;
                  o0.z = cb2[5].y * r1.x + r0.z;
                  o0.xyw = r0.xyw;
                  o1.xy = v6.xy;
                  o1.zw = r2.xy;
                return o;
            }
            // Keywords: SHADOWS_DEPTH
            fout frag(v2f inp)
            {
                fout o;
                o.sv_target = float4(0.0, 0.0, 0.0, 0.0);
                return o;
            }
            ENDCG
        }
    }
    Fallback "Diffuse"
}