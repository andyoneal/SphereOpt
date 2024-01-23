Shader "VF Shaders/Batching/Belt Instancing" {
    Properties {
        _Color ("Color", Vector) = (1,1,1,1)
        _EmissionColor ("Emission Color", Vector) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _NormalTex ("Normal Map", 2D) = "bump" {}
        _MSTex ("Metallic Smoothness (RA)", 2D) = "white" {}
        _EmissionTex ("Emission (RGB)", 2D) = "white" {}
        _ClipTex ("Clip (RG)", 2D) = "white" {}
        _InstOfs ("Instance Offset", Float) = 0
        _NodeWidth ("Node Width", Float) = 2
        _UVSpeed ("UV Speed", Float) = 1
    }
    SubShader {
        LOD 200
        Tags { "RenderType" = "Opaque" }
        Pass {
            Name "FORWARD"
            LOD 200
            Tags { "LIGHTMODE" = "FORWARDBASE" "RenderType" = "Opaque" "SHADOWSUPPORT" = "true" }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 5.0
            #pragma enable_d3d11_debug_symbols
            
            #include "UnityCG.cginc"
            #include "CGIncludes/DSPCommon.cginc"
            
            struct BeltAnchor
            {
                float t;
                float3 pos;
                float4 rot;
            };
            
            struct v2f
            {
                float4 pos : SV_POSITION,
                float4 TBNW0 : TEXCOORD0; //o1
                float4 TBNW1 : TEXCOORD1; //o2
                float4 TBNW2 : TEXCOORD2; //o3
                float4 animFrame_V_t_state : TEXCOORD3; //o4
                float4 worldPos : TEXCOORD4;
                float2 uv : TEXCOORD5;
                float4 indirectLight : TEXCOORD6;
                float4 screenPos : TEXCOORD8;
                float4 unk : TEXCOORD9;
            };
            
            struct fout
            {
                float4 sv_target : SV_Target;
            };
            
            StructuredBuffer<BeltAnchor> _Buffer;
            StructuredBuffer<float> _BeltStateBuffer;
            
            float _NodeWidth;
            float4 _LightColor0;
            float4 _Global_AmbientColor0;
            float4 _Global_AmbientColor1;
            float4 _Global_AmbientColor2;
            float4 _Global_SunsetColor0;
            float4 _Global_SunsetColor1;
            float4 _Global_SunsetColor2;
            float _PGI_Gray;
            float4 _Global_PointLightPos;
            float4 _Color;
            float4 _EmissionColor;
            float _UVSpeed;
            float4 _Global_SunDir;
            
            sampler2D _ClipTex;
            sampler2D _MainTex;
            sampler2D _NormalTex;
            sampler2D _MSTex;
            sampler2D _EmissionTex;
            samplerCUBE _Global_PGI;
            
            
            v2f vert(appdata_full v, uint instanceID : SV_InstanceID)
            {
                v2f o;
                uint offset = v.vertex.z * (_NodeWidth - 1.0) + 0.4; // (2,3,5,9) = (1.4*z, 2.4+z, 4.4*z, 8.4+z) z=[0,1] where 0 is beginning of belt, 1 is end
                uint nodeIndex = instanceID * _NodeWidth + offset; //r0.x
                
                float t = _Buffer[nodeIndex].t; //r1.x
                float3 pos = _Buffer[nodeIndex].pos; //r1.yzw
                
                o.animFrame_V_t_state.w = _BeltStateBuffer[nodeIndex];
                
                float3 worldPos;
                float3 worldNormal;
                if (t > 0.5) {
                    float4 rot = _Buffer[nodeIndex].rot; //r0.xyzw
                    r2.xyzw = r0.zzxy + r0.zzxy;
                    r3.xyz = r2.zwy * r0.xyz;
                    r4.xyzw = r2.xyzw * r0.xyww;
                    r0.z = r2.y * r0.w;
                    r3.xyz = r3.yxx + r3.zzy;
                    
                    r3.xyz = float3(1,1,1) - r3.zxy; //r3.x
                    
                    r5.xy = v.vertex.xy * r3.yz;
                    r0.w = r0.x * r2.w - r0.z;
                    r6.x = r0.w * v.vertex.y + r5.x;
                    r0.z = r0.x * r2.w + r0.z;
                    r6.y = r0.z * v.vertex.x + r5.y;
                    
                    r0.xy = r0.yx * r2.yx - r4.zw; //r0.x
                    
                    r2.xy = r4.xy + r4.wz; //r2.x
                    
                    r2.z = v.vertex.y * r2.y;
                    r6.z = r0.y * v.vertex.x + r2.z;
                    worldPos.yzw = r6.xyz + pos; //r1.yzw
                    
                    r2.zw = v.normal.xy * r3.yz;
                    r0.w = r0.w * v.normal.y + r2.z;
                    r2.y = v.normal.y * r2.y;
                    r4.x = r2.x * v.normal.z + r0.w;
                    r0.z = r0.z * v.normal.x + r2.w;
                    r4.y = r0.x * v.normal.z + r0.z;
                    r0.y = r0.y * v.normal.x + r2.y;
                    r4.z = r3.x * v.normal.z + r0.y;
                    worldNormal = r4.xyz;
                } else {
                    worldNormal.xyz = float3(0,0,0); //r4.xyz
                    worldPos.yzw = float3(0,0,0); //r1.yzw
                    r2.x = 0; //tan x?
                    r0.x = 0; //tan y?
                    r3.x = 1; //tan z?
                }
                
                float sign = sign(0.1 + v.normal.x); //r0.y
                
                //r0.z = 1.0 - ((0.5 + v.vertex.x) - (v.normal.x * v.vertex.y) / 1.5);
                float texV = 0.5 - v.vertex.x + (v.vertex.y * v.normal.x) / 1.5; //r0.z
                //v.normal.x for up/down/forward/back will be 0, so this is just a side thing? on sides, either -1 or 1 (left/right)
                //on sides, v.vertex.y will be -0.15 on bottom and ~0 on top
                //so vert.y * normal.x = 0.15 to 0 bottom to top on left, -0.15 to 0 from bottom to top on right. div 1.5, so ±0.1 to 0
                //0.5 - vert.x = 0.5 - [-0.4, 0.4] = [0.9, 0.1], left to right
                //on up/down/forward/back, it's +0, so just [0.9, 0.1] left to right all the way from back to front
                //on left side, it'll be 0.9 + [0.1, 0] = [1.0, 0.9] from bottom to top.
                //on right side, itll be 0.1 + [-0.1, 0] = [0.0, 0.1] from bottom to top.
                
                float4 worldPos2 = mul(unity_ObjectToWorld, float4(worldPos, 1.0); //r5
                float4 clipPos = mul(UNITY_MATRIX_VP, worldPos2); //r6
                
                worldNormal = UnityObjectToWorldNormal(worldNormal);
                float3 worldTangent = UnityObjectToWorldDir(float3(r2.x, r0.x, r3.x));; //r2.xyz
                float sign = sign(0.1 + v.normal.x); //r0.y
                float3 worldBinormal(calculateBinormal(float4(worldTangent, sign), worldNormal);
                
                o.indirectLight.xyz shadeSH9(float4(worldNormal.xyz, 1));
                
                o.screenPos.xyzw = ComputeScreenPos(clipPos); //shadowcoords?
                
                o.pos.xyzw = clipPos.xyzw;
                
                TBNW0.x = worldTangent.x;
                TBNW0.y = worldBinormal.x;
                TBNW0.z = worldNormal.x;
                TBNW0.w = worldPos2.x;
                
                TBNW1.x = worldTangent.y;
                TBNW1.y = worldBinormal.y;
                TBNW1.z = worldNormal.y;
                TBNW1.w = worldPos2.y;
                
                TBNW2.x = worldTangent.z;
                TBNW2.y = worldBinormal.z;
                TBNW2.z = worldNormal.z;
                TBNW2.w = worldPos2.z;
                
                o.animFrame_V_t_state.x = t / 17.0;
                o.animFrame_V_t_state.y = texV;
                o.animFrame_V_t_state.z = t;
                
                o.unk.xyzw = float4(0,0,0,0);
                
                o.worldPos.xyz = worldPos.yzw;
                
                o.uv.x = v.vertex.z; //z = 0 to 1 in the direction of travel
                o.uv.y = texV;
                return;

            }

            fout frag(v2f inp)
            {
                fout o;
                
                float t = animFrame_V_t_state.z;
                if (t < 0.5)
                    discard;
                
                float animFrame = animFrame_V_t_state.x;
                float texV = animFrame_V_t_state.y;
                float2 clip = tex2Dlod(_ClipTex, float4(animFrame, texV, 0, 0)).xz; //r0.xy
                if (clip.x < 0.5)
                    discard;
                    
                float state = animFrame_V_t_state.w;
                r0.x = (60.0 / 17.0) * _UVSpeed;
                distCamToPos = distance(i.worldPos, _WorldSpaceCameraPos); //r0.z
                
                float2 deriv;
                deriv.x = ddx_coarse(texV);
                deriv.y = ddy_coarse(texV);
                float mip = log2(length(deriv.xy)) * 1.0 + 8.0; //r0.w
                
                float2 uv; //r1.xy
                uv.x = abs(texV - 0.5) < 0.34 ? animFrame - frac(_Time.y * (60.0 / 17.0) * _UVSpeed) : animFrame;
                uv.y = texV;
                
                float albedo = tex2Dlod(_MainTex, float4(uv.xy, 0, mip).xyz); //r2.xyz
                albedo.xyz = albedo.xyz * lerp(float3(1, 1, 1), _Color.xyz, clip.y); //r2.xyz
                
                float3 unpackedNormal = UnpackNormal(tex2Dlod(_NormalTex, float4(uv.xy, 0, mip)));
                unpackedNormal = normalize(unpackedNormal); //r3.xyz
                
                float2 metalSmooth = tex2Dlod(_MSTex, float4(uv.xy, 0, mip)).xw; //r0.xy
                float3 emiss = tex2D(_EmissionTex, uv.xy); //r1.xyz
                
                float3 upDir = normalize(i.worldPos.xyz); //r4.xyz
                
                emiss.xyz = emiss.xyz * min(10, max(1, 1000 / distCamToPos)); //r1.xyz
                
                float sunAngle = dot(upDir.xyz, _Global_SunDir.xyz); //noon = 1, perpendicular = 0, midnight = -1 (sundir is planet to star, right?)
                float3 nightLightColor = _EmissionColor.xyz * saturate(-500 * sunAngle); //r5.xyz
                nightLightColor = nightLightColor.xyz * emiss.xyz; //r6.xyz
                
                  if (state > 0.5 && state < 1.5) {
                    r7.xyz = nightLightColor + float3(1.1, 0.4, 0);
                  } else {
                    if (state > 1.5 && state < 2.5) {
                      r7.xyz = nightLightColor + float3(0, 1.1, 0.3);
                    } else {
                      r8.xyzw = state > float4(4.5, 99.5, 9.5, 19.5));
                      r9.xyzw = state < float4(5.5, 100.5, 10.5, 20.5);
                      r10.xyz = nightLightColor + float3(0, 0.4 ,1.1);
                      r11.xyz = emiss.xyz * nightLightColor.xyz + float3(0.5, 0.5, 0.5);
                      r1.xyz = emiss.xyz * nightLightColor.xyz + float3(0, 0.45, 4.95);
                      r5.xyzw = r8.xyzw ? r9.xyzw : 0;
                      r0.z = state > 49.5 && state < 50.5;
                      
                      r8.xyz = state > 999.5 ? float3(0.15, 0.15, 0.15) : albedo.xyz;
                      r6.xyz = state > 999.5 ? float3(0.15, 0.15, 0.15) : r6.xyz;
                      
                      r1.xyz = r5.z || r5.w || r0.z ? r1.xyz : r6.xyz;
                      r1.xyz = r5.yyy ? r11.xyz : r1.xyz;
                      
                      albedo.xyz = r5.x || r5.y || r5.z || r5.w || r0.z ? albedo.xyz : r8.xyz;
                      r7.xyz = r5.xxx ? r10.xyz : r1.xyz;
                    }
                  }
                  
                  //-- usual DSP Shader stuff --//
                  
                  //atten = shadows
                  r1.y = v1.w;
                  r1.z = v2.w;
                  r1.w = v3.w;
                  r5.xyz = _WorldSpaceCameraPos.xyz - r1.yzw;
                  r6.xyz = normalize(r5.xyz);
                  r8.x = cb4[9].z;
                  r8.y = cb4[10].z;
                  r8.z = cb4[11].z;
                  r0.w = dot(r5.xyz, r8.xyz);
                  r1.x = length(r1.yzw - cb3[25].xyz);
                  r1.x = r1.x - r0.w;
                  r0.w = cb3[25].w * r1.x + r0.w;
                  r0.w = saturate(r0.w * cb3[24].z + cb3[24].w);
                  r1.x = cmp(cb5[0].x == 1.0);
                  if (r1.x != 0) {
                    r1.x = cmp(cb5[0].y == 1.0);
                    r8.xyz = cb5[2].xyz * v2.www;
                    r8.xyz = cb5[1].xyz * v1.www + r8.xyz;
                    r8.xyz = cb5[3].xyz * v3.www + r8.xyz;
                    r8.xyz = cb5[4].xyz + r8.xyz;
                    r1.xyz = r1.xxx ? r8.xyz : r1.yzw;
                    r1.xyz = r1.xyz - cb5[6].xyz;
                    r1.yzw = cb5[5].xyz * r1.xyz;
                    r1.y = r1.y * 0.25 + 0.75;
                    r2.w = cb5[0].z * 0.5 + 0.75;
                    r1.x = max(r2.w, r1.y);
                    r1.xyzw = t7.Sample(s0_s, r1.xzw).xyzw; //grey thing
                  } else {
                    r1.xyzw = float4(1,1,1,1);
                  }
                  r1.x = saturate(dot(r1.xyzw, unity_OcclusionMaskSelector.xyzw));
                  r1.yz = v8.xy / v8.ww;
                  r1.y = t5.Sample(s1_s, r1.yz).x; //shadowmap
                  r1.x = r1.x - r1.y;
                  r0.w = r0.w * r1.x + r1.y;
                  
                  //tranform normal from tangent to world space
                  float3 worldNormal;
                  worldNormal.x = dot(TBNW0.xyz, unpackedNormal.xyz);
                  worldNormal.y = dot(TBNW1.xyz, unpackedNormal.xyz);
                  worldNormal.z = dot(TBNW2.xyz, unpackedNormal.xyz);
                  worldNormal.xyz = normalize(worldNormal.xyz);
                  
                  //light vars
                  r0.x = saturate(metalSmooth.x * 0.85 + 0.149);
                  r1.w = saturate(1 - metalSmooth.y * 0.97);
                  r3.xyz = nomalize(r6.xyz + _WorldSpaceLightPos0.xyz);
                  r0.z = r1.w * r1.w;
                  r2.w = r0.z * r0.z;
                  r3.w = dot(r1.xyz, _WorldSpaceLightPos0.xyz);
                  r4.w = max(0, r3.w);
                  r5.x = dot(r1.xyz, r6.xyz);
                  r5.y = dot(r1.xyz, r3.xyz);
                  r5.xy = max(float2(0,0), r5.xy);
                  r3.x = dot(r6.xyz, r3.xyz);
                  r3.x = max(0, r3.x);
                  r3.y = r3.w * 0.349999994 + 1;
                  r3.z = r3.y * r3.y;
                  r3.y = r3.z * r3.y;
                  r3.z = dot(upDir.xyz, _WorldSpaceLightPos0.xyz);
                  r3.w = dot(r1.xyz, upDir.xyz);
                  r5.z = dot(upDir.xyz, upDir.xyz);
                  
                  //global illum
                  r5.w = cmp(upDir.y < 0.999899983);
                  r5.z = cmp(0.00999999978 < r5.z);
                  r5.w = r5.z ? r5.w : 0;
                  r8.xyz = float3(0,1,0) * upDir.yzx;
                  r8.xyz = upDir.xyz * float3(1,0,0) + -r8.xyz;
                  r6.w = dot(r8.xy, r8.xy);
                  r6.w = rsqrt(r6.w);
                  r8.xyz = r8.xyz * r6.www;
                  r8.xyz = r5.www ? r8.xyz : float3(0,1,0);
                  r5.w = dot(r8.xy, r8.xy);
                  r5.w = cmp(0.00999999978 < r5.w);
                  r5.z = r5.w ? r5.z : 0;
                  r9.xyz = r8.xyz * upDir.yzx;
                  r9.xyz = r8.zxy * upDir.zxy + -r9.xyz;
                  r5.w = dot(r9.xyz, r9.xyz);
                  r5.w = rsqrt(r5.w);
                  r9.xyz = r9.xyz * r5.www;
                  r5.w = dot(-r6.xyz, r1.xyz);
                  r5.w = r5.w + r5.w;
                  r6.xyz = r1.xyz * -r5.www + -r6.xyz;
                  r8.x = dot(r6.zx, -r8.xy);
                  r8.y = dot(r6.xyz, upDir.xyz);
                  r9.xyz = r5.zzz ? -r9.xyz : float3(-0,-0,-1);
                  r8.z = dot(r6.xyz, r9.xyz);
                  r5.z = log2(r1.w);
                  r5.z = 0.400000006 * r5.z;
                  r5.z = exp2(r5.z);
                  r5.z = 10 * r5.z;
                  r8.xyz = texCUBElod(_Global_PGI, float4(r8.xyz, r5.z)).xyz;
                  r5.z = dot(r8.xyz, float3(0.289999992,0.579999983,0.129999995));
                  r9.xyz = r5.zzz + -r8.xyz;
                  r8.xyz = _PGI_Gray.xxx * r9.xyz + r8.xyz;
                  r5.z = r0.x * 0.699999988 + 0.300000012;
                  r1.w = 1 + -r1.w;
                  r1.w = r5.z * r1.w;
                  r8.xyz = r8.xyz * r1.www;
                  
                  //sunset
                  r5.z = cmp(1 >= r3.z);
                  if (r5.z != 0) {
                    r9.xyzw = float4(-0.200000003,-0.100000001,0.100000001,0.300000012) + r3.zzzz;
                    r9.xyzw = saturate(float4(5,10,5,5) * r9.xyzw);
                    r10.xyz = float3(1,1,1) + -cb0[10].xyz;
                    r10.xyz = r9.xxx * r10.xyz + cb0[10].xyz;
                    r11.xyz = float3(1.25,1.25,1.25) * cb0[11].xyz;
                    r12.xyz = -cb0[11].xyz * float3(1.25,1.25,1.25) + cb0[10].xyz;
                    r11.xyz = r9.yyy * r12.xyz + r11.xyz;
                    r12.xyz = cmp(float3(0.200000003,0.100000001,-0.100000001) < r3.zzz);
                    r13.xyz = float3(1.5,1.5,1.5) * cb0[12].xyz;
                    r14.xyz = cb0[11].xyz * float3(1.25,1.25,1.25) + -r13.xyz;
                    r9.xyz = r9.zzz * r14.xyz + r13.xyz;
                    r13.xyz = r13.xyz * r9.www;
                    r9.xyz = r12.zzz ? r9.xyz : r13.xyz;
                    r9.xyz = r12.yyy ? r11.xyz : r9.xyz;
                    r9.xyz = r12.xxx ? r10.xyz : r9.xyz;
                  } else {
                    r9.xyz = float3(1,1,1);
                  }
                  r9.xyz = _LightColor0.xyz * r9.xyz;
                  r5.zw = float2(0.150000006,3) * r3.zz;
                  r5.zw = saturate(r5.zw);
                  
                  r6.w = 1 + -r0.w;
                  r0.w = r5.z * r6.w + r0.w;
                  r0.w = 0.800000012 * r0.w;
                  r5.z = 0.5 + r0.x;
                  r9.xyz = r0.www * r9.xyz;
                  
                  //PBR 
                  r0.w = r5.y * r5.y;
                  r10.xy = r0.zz * r0.zz + float2(-1,1);
                  r0.z = r0.w * r10.x + 1;
                  r0.z = rcp(r0.z);
                  r0.z = r0.z * r0.z;
                  r0.z = r0.z * r2.w;
                  r0.z = 0.25 * r0.z;
                  r0.w = r10.y * r10.y;
                  r2.w = 0.125 * r0.w;
                  r0.w = -r0.w * 0.125 + 1;
                  r5.x = r5.x * r0.w + r2.w;
                  r0.w = r4.w * r0.w + r2.w;
                  r2.w = 1 + -r5.z;
                  r5.y = r3.x * -5.55472994 + -6.98316002;
                  r3.x = r5.y * r3.x;
                  r3.x = exp2(r3.x);
                  r2.w = r2.w * r3.x + r5.z;
                  r0.z = r2.w * r0.z;
                  r0.w = r5.x * r0.w;
                  r0.w = rcp(r0.w);
                  
                  //ambient light
                  r2.w = cmp(0 < r3.z);
                  r5.xyz = -cb0[5].xyz + cb0[4].xyz;
                  r5.xyz = r5.www * r5.xyz + cb0[5].xyz;
                  r3.x = saturate(r3.z * 3 + 1);
                  r10.xyz = -cb0[6].xyz + cb0[5].xyz;
                  r10.xyz = r3.xxx * r10.xyz + cb0[6].xyz;
                  r5.xyz = r2.www ? r5.xyz : r10.xyz;
                  r2.w = saturate(r3.w * 0.300000012 + 0.699999988);
                  r10.xyz = r5.xyz * r2.www;
                  r3.xyw = r10.xyz * r3.yyy;
                  
                  //headlamp
                  r2.w = cmp(_Global_PointLightPos.w >= 0.5);
                  r5.w = dot(_Global_PointLightPos.xyz, _Global_PointLightPos.xyz);
                  r5.w = sqrt(r5.w);
                  r6.w = -5 + r5.w;
                  r7.w = saturate(r6.w);
                  r8.w = dot(-upDir.xyz, _WorldSpaceLightPos0.xyz);
                  r8.w = saturate(5 * r8.w);
                  r7.w = r8.w * r7.w;
                  r10.xyz = -upDir.xyz * r6.www + _Global_PointLightPos.xyz;
                  r6.w = dot(r10.xyz, r10.xyz);
                  r6.w = sqrt(r6.w);
                  r9.w = 20 + -r6.w;
                  r9.w = 0.05 * r9.w;
                  r9.w = max(0, r9.w);
                  r9.w = r9.w * r9.w;
                  r10.w = cmp(r6.w < 0.00100000005);
                  r11.xyz = float3(1.3,1.1,0.6]) * r7.www;
                  r10.xyz = r10.xyz / r6.www;
                  r1.x = saturate(dot(r10.xyz, r1.xyz));
                  r1.x = r1.x * r9.w;
                  r1.x = r1.x * r7.w;
                  r1.xyz = float3(1.29999995,1.10000002,0.600000024) * r1.xxx;
                  r1.xyz = r10.www ? r11.xyz : r1.xyz;
                  r1.xyz = r2.www ? r1.xyz : 0;
                  r6.w = 1 + -r0.x;
                  r7.w = log2(r6.w);
                  r7.w = 0.600000024 * r7.w;
                  r7.w = exp2(r7.w);
                  
                  //mix lighting
                  r6.w = r6.w * albedo.x;
                  r6.w = r6.w * 0.200000003 + r0.x;
                  r10.xyz = r9.xyz * r4.www;
                  r9.w = r7.w * 0.200000003 + 0.800000012;
                  r11.xyz = r9.www * r1.xyz;
                  r10.xyz = r10.xyz * r7.www + r11.xyz;
                  r11.xyz = float3(-1,-1,-1) + albedo.xyz;
                  r11.xyz = r0.xxx * r11.xyz + float3(1,1,1);
                  r9.xyz = r11.xyz * r9.xyz;
                  r0.z = r0.z * r0.w + 0.0318309888;
                  r9.xyz = r9.xyz * r0.zzz;
                  r11.xyz = r4.www + r1.xyz;
                  r9.xyz = r11.xyz * r9.xyz;
                  
                  //extra headlamp
                  if (r2.w != 0) {
                    r0.z = -20 + r5.w;
                    r0.w = saturate(r0.z);
                    r0.w = r0.w * r8.w;
                    r4.xyz = -upDir.xyz * r0.zzz + _Global_PointLightPos.xyz;
                    r0.z = dot(r4.xyz, r4.xyz);
                    r0.z = sqrt(r0.z);
                    r2.w = 40 + -r0.z;
                    r2.w = 0.0250000004 * r2.w;
                    r2.w = max(0, r2.w);
                    r2.w = r2.w * r2.w;
                    r4.w = cmp(r0.z < 0.00100000005);
                    r11.xyz = float3(1.29999995,1.10000002,0.600000024) * r0.www;
                    r4.xyz = r4.xyz / r0.zzz;
                    r0.z = dot(r6.xyz, r4.xyz);
                    r0.z = max(0, r0.z);
                    r4.x = 9.96578407 * metalSmooth.y;
                    r4.x = exp2(r4.x);
                    r0.z = log2(r0.z);
                    r0.z = r4.x * r0.z;
                    r0.z = exp2(r0.z);
                    r0.z = 20 * r0.z;
                    r0.y = r0.z * metalSmooth.y;
                    r0.y = r0.y * r2.w;
                    r0.y = r0.y * r0.w;
                    r0.yzw = float3(1.29999995,1.10000002,0.600000024) * r0.yyy;
                    r0.yzw = r4.www ? r11.xyz : r0.yzw;
                  } else {
                    r0.yzw = float3(0,0,0);
                  }
                  r0.yzw = r0.yzw * r6.www;
                  
                  //mix lighting
                  r4.xyz = albedo.xyz * float3(0.5,0.5,0.5) + float3(0.5,0.5,0.5);
                  r0.yzw = r4.xyz * r0.yzw;
                  r0.yzw = r9.xyz * r6.www + r0.yzw;
                  r3.xyw = r3.xyw * albedo.xyz;
                  r0.x = -r0.x * 0.600000024 + 1;
                  r2.w = dot(r5.xyx, float3(0.300000012,0.600000024,0.100000001));
                  r2.w = 0.00300000003 + r2.w;
                  r4.x = max(_Global_AmbientColor0.x, _Global_AmbientColor0.y);
                  r4.x = max(_Global_AmbientColor0.z, r4.x);
                  r4.x = 0.00300000003 + r4.x;
                  r4.x = 1 / r4.x;
                  r4.yzw = r5.xyz + -r2.www;
                  r4.yzw = r4.yzw * float3(0.400000006,0.400000006,0.400000006) + r2.www;
                  r4.xyz = r4.yzw * r4.xxx;
                  r4.xyz = float3(1.70000005,1.70000005,1.70000005) * r4.xyz;
                  r4.xyz = r8.xyz * r4.xyz;
                  r2.w = saturate(r3.z * 2 + 0.5);
                  r2.w = r2.w * 0.699999988 + 0.300000012;
                  r1.xyz = r2.www + r1.xyz;
                  r1.xyz = r4.xyz * r1.xyz;
                  r0.yzw = r10.xyz * albedo.xyz + r0.yzw;
                  r0.xyz = r3.xyw * r0.xxx + r0.yzw;
                  r1.xyz = r1.xyz * albedo.xyz + -r0.xyz;
                  r0.xyz = r1.www * r1.xyz + r0.xyz;
                  
                  //finalize
                  r0.w = dot(r0.xyz, float3(0.300000012,0.600000024,0.100000001));
                  r1.x = cmp(1 < r0.w);
                  r1.yzw = r0.xyz / r0.www;
                  r0.w = log2(r0.w);
                  r0.w = r0.w * 0.693147182 + 1;
                  r0.w = log2(r0.w);
                  r0.w = r0.w * 0.693147182 + 1;
                  r1.yzw = r1.yzw * r0.www;
                  r0.xyz = r1.xxx ? r1.yzw : r0.xyz;
                  r0.xyz = albedo.xyz * v7.xyz + r0.xyz;
                  o0.xyz = r0.xyz + r7.xyz;
                  o0.w = 1;
                  return;
                return o;
            }
            ENDCG
        }
        
        Pass {
            Name "ShadowCaster"
            LOD 200
            Tags { "LIGHTMODE" = "SHADOWCASTER" "RenderType" = "Opaque" "SHADOWSUPPORT" = "true" }
            GpuProgramID 190269
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 5.0
            
            #include "UnityCG.cginc"
            
            struct v2f
            {
                float4 position : SV_POSITION0;
                float4 texcoord1 : TEXCOORD1;
                float3 texcoord2 : TEXCOORD2;
                float2 texcoord3 : TEXCOORD3;
            };
            
            struct fout
            {
                float4 sv_target : SV_Target0;
            };

            float _NodeWidth;
            sampler2D _ClipTex;
            
            v2f vert(appdata_full v)
            {
                v2f o;
                float4 r0;
                float4 r1;
                float4 r2;
                float4 r3;
                float4 r4;
                float4 r5;
                float4 r6;
                r0.x = _NodeWidth - 1.0;
                r0.x = v.vertex.z * r0.x + 0.4;
                r0.x = r0.y * _NodeWidth + r0.x;
                r1 = ((float4[1])rsc0.Load(r0.x))[0];
                o.texcoord1.w = ((float4[1])rsc1.xxxx.Load(r0.x))[0];
                r0.y = r1.x > 0.5;
                if (r0.y) {
                    r0 = ((float4[1])rsc0.Load(r0.x))[1];
                    r2 = r0.zzxy + r0.zzxy;
                    r3.xyz = r0.xyz * r2.zwy;
                    r4 = r0.xyww * r2;
                    r0.z = r0.w * r2.y;
                    r3.xyz = r3.zzy + r3.yxx;
                    r3.xyz = float3(1.0, 1.0, 1.0) - r3.xyz;
                    r5.xy = r3.xy * v.vertex.xy;
                    r0.w = r0.x * r2.w + -r0.z;
                    r6.x = r0.w * v.vertex.y + r5.x;
                    r0.z = r0.x * r2.w + r0.z;
                    r6.y = r0.z * v.vertex.x + r5.y;
                    r0.xy = r0.yx * r2.yx + -r4.zw;
                    r2.xy = r4.wz + r4.xy;
                    r2.z = r2.y * v.vertex.y;
                    r6.z = r0.y * v.vertex.x + r2.z;
                    r1.yzw = r1.yzw + r6.xyz;
                    r2.zw = r3.xy * v.normal.xy;
                    r0.w = r0.w * v.normal.y + r2.z;
                    r2.y = r2.y * v.normal.y;
                    r4.x = r2.x * v.normal.z + r0.w;
                    r0.z = r0.z * v.normal.x + r2.w;
                    r4.y = r0.x * v.normal.z + r0.z;
                    r0.x = r0.y * v.normal.x + r2.y;
                    r4.z = r3.z * v.normal.z + r0.x;
                } else {
                    r4.xyz = float3(0.0, 0.0, 0.0);
                    r1.yzw = float3(0.0, 0.0, 0.0);
                }
                r0.x = v.vertex.x + 0.5;
                r0.y = v.vertex.y * v.normal.x;
                r0.x = -r0.y * 0.666666 + r0.x;
                r0.x = 1.0 - r0.x;
                r2 = r1.zzzz * unity_ObjectToWorld._m01_m11_m21_m31;
                r2 = unity_ObjectToWorld._m00_m10_m20_m30 * r1.yyyy + r2;
                r2 = unity_ObjectToWorld._m02_m12_m22_m32 * r1.wwww + r2;
                r2 = r2 + unity_ObjectToWorld._m03_m13_m23_m33;
                r0.y = unity_LightShadowBias.z != 0.0;
                r3.x = dot(r4.xyz, unity_WorldToObject._m00_m10_m20);
                r3.y = dot(r4.xyz, unity_WorldToObject._m01_m11_m21);
                r3.z = dot(r4.xyz, unity_WorldToObject._m02_m12_m22);
                r0.z = dot(r3.xyz, r3.xyz);
                r0.z = rsqrt(r0.z);
                r3.xyz = r0.zzz * r3.xyz;
                r4.xyz = -r2.xyz * _WorldSpaceLightPos0.www + _WorldSpaceLightPos0.xyz;
                r0.z = dot(r4.xyz, r4.xyz);
                r0.z = rsqrt(r0.z);
                r4.xyz = r0.zzz * r4.xyz;
                r0.z = dot(r3.xyz, r4.xyz);
                r0.z = -r0.z * r0.z + 1.0;
                r0.z = sqrt(r0.z);
                r0.z = r0.z * unity_LightShadowBias.z;
                r3.xyz = -r3.xyz * r0.zzz + r2.xyz;
                r0.yzw = r0.yyy ? r3.xyz : r2.xyz;
                r3 = r0.zzzz * unity_MatrixVP._m01_m11_m21_m31;
                r3 = unity_MatrixVP._m00_m10_m20_m30 * r0.yyyy + r3;
                r3 = unity_MatrixVP._m02_m12_m22_m32 * r0.wwww + r3;
                r2 = unity_MatrixVP._m03_m13_m23_m33 * r2.wwww + r3;
                r0.y = unity_LightShadowBias.x / r2.w;
                r0.y = min(r0.y, 0.0);
                r0.y = max(r0.y, -1.0);
                r0.y = r0.y + r2.z;
                r0.z = min(r2.w, r0.y);
                r0.z = r0.z - r0.y;
                o.position.z = unity_LightShadowBias.y * r0.z + r0.y;
                o.position.xyw = r2.xyw;
                o.texcoord1.xz = r1.xx * float2(0.0588235, 1.0);
                o.texcoord1.y = r0.x;
                o.texcoord2.xyz = r1.yzw;
                o.texcoord3.x = v.vertex.z;
                o.texcoord3.y = r0.x;
                return o;
            }
            
            fout frag(v2f i)
            {
                fout o;
                
                if (i.texcoord1.z < 0.5)
                    discard;

                float clip = tex2Dlod(_ClipTex, float4(i.texcoord1.xy, 0, 0)).x;
                if (clip < 0.5)
                    discard;
                    
                o.sv_target = float4(0.0, 0.0, 0.0, 0.0);
                
                return o;
            }
            ENDCG
        }
    }
    Fallback "Diffuse"
}