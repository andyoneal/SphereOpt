Shader "VF Shaders/Forward/PBR Standard Vein Crystal" {
    Properties {
        _Color0 ("Color 颜色 ID=0", Vector) = (1,1,1,1)
        _Color1 ("Color 颜色 ID=1", Vector) = (1,1,1,1)
        _Color2 ("Color 颜色 ID=2", Vector) = (1,1,1,1)
        _Color3 ("Color 颜色 ID=3", Vector) = (1,1,1,1)
        _Color4 ("Color 颜色 ID=4", Vector) = (1,1,1,1)
        _Color5 ("Color 颜色 ID=5", Vector) = (1,1,1,1)
        _Color6 ("Color 颜色 ID=6", Vector) = (1,1,1,1)
        _Color9 ("Color 颜色 ID=9", Vector) = (1,1,1,1)
        _Color10 ("Color 颜色 ID=10", Vector) = (1,1,1,1)
        _Color11 ("Color 颜色 ID=11", Vector) = (1,1,1,1)
        _Color12 ("Color 颜色 ID=12", Vector) = (1,1,1,1)
        _Color13 ("Color 颜色 ID=13", Vector) = (1,1,1,1)
        _Color14 ("Color 颜色 ID=14", Vector) = (1,1,1,1)
        _Crystal ("Crystal", Float) = 5
        _CrystalRefrac ("Crystal Refrac", Float) = 0.1
        _SpecularColor ("Specular Color", Vector) = (1,1,1,1)
        _EmissionMask ("自发光正片叠底色", Vector) = (1,1,1,1)
        _MainTexA ("Albedo (RGB) 漫反射 铺底", 2D) = "white" {}
        _MainTexB ("Albedo (RGB) 漫反射 颜色", 2D) = "white" {}
        _OcclusionTex ("环境光遮蔽", 2D) = "white" {}
        _NormalTex ("Normal 法线", 2D) = "bump" {}
        _MS_Tex ("Metallic (R) 透贴 (G) 金属 (A) 高光", 2D) = "black" {}
        _EmissionTex ("Emission (RGB) 自发光  (A) 抖动遮罩", 2D) = "black" {}
        _AmbientInc ("环境光提升", Float) = 0
        _AlbedoMultiplier ("漫反射倍率", Float) = 1
        _OcclusionPower ("环境光遮蔽指数", Float) = 1
        _NormalMultiplier ("法线倍率", Float) = 1
        _MetallicMultiplier ("金属倍率", Float) = 1
        _SmoothMultiplier ("高光倍率", Float) = 1
        _EmissionMultiplier ("自发光倍率", Float) = 5.5
        _EmissionJitter ("自发光抖动倍率", Float) = 0
        _EmissionSwitch ("是否使用游戏状态决定自发光", Float) = 0
        _EmissionUsePower ("是否使用供电数据决定自发光", Float) = 1
        _EmissionJitterTex ("自发光抖动色条", 2D) = "white" {}
        _AlphaClip ("透明通道剪切", Float) = 0
        _CullMode ("剔除模式", Float) = 2
        _Biomo ("Biomo 融合因子", Float) = 0.3
        _BiomoMultiplier ("Biomo 颜色乘数", Float) = 1
        _BiomoHeight ("Biomo 融合高度", Float) = 1.1
        [Toggle(_ENABLE_VFINST)] _ToggleVerta ("Enable VFInst ?", Float) = 0
    }
    SubShader {
        LOD 200
        Tags { "DisableBatching" = "true" "RenderType" = "Opaque" }
        GrabPass {
            "_ScreenTex"
        }
        Pass {
            Name "FORWARD"
            LOD 200
            Tags { "DisableBatching" = "true" "LIGHTMODE" = "FORWARDBASE" "RenderType" = "Opaque" "SHADOWSUPPORT" = "true" }
            Cull 
            GpuProgramID 63316
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 5.0
            #pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight
            #pragma enable_d3d11_debug_symbols
            
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "CGIncludes/DSPCommon.cginc"
            
            struct v2f
            {   
                float4 pos : SV_POSITION0;
                float4 TBN0 : TEXCOORD0;
                float4 TBN1 : TEXCOORD1;
                float4 TBN2 : TEXCOORD2;
                float4 uv_controlUV : TEXCOORD3;
                float4 upDir_lodDist : TEXCOORD4;
                float3 time_state_emiss : TEXCOORD5;
                float3 worldPos : TEXCOORD6;
                float4 screenPosIsh : TEXCOORD7;
                float3 indirectLight : TEXCOORD8;
                UNITY_SHADOW_COORDS(10)
                float4 unk : TEXCOORD11;
            };
            struct fout
            {
                float4 sv_target : SV_Target0;
            };
            
            float _EmissionUsePower;
            float4 _LightColor0;
            float4 _Global_AmbientColor0;
            float4 _Global_AmbientColor1;
            float4 _Global_AmbientColor2;
            float4 _Global_SunsetColor0;
            float4 _Global_SunsetColor1;
            float4 _Global_SunsetColor2;
            float4 _Global_Biomo_Color0;
            float4 _Global_Biomo_Color1;
            float4 _Global_Biomo_Color2;
            float _Global_Planet_Radius;
            float4 _Global_PointLightPos;
            float4 _Color0;
            float4 _Color1;
            float4 _Color2;
            float4 _Color3;
            float4 _Color4;
            float4 _Color5;
            float4 _Color6;
            float4 _Color9;
            float4 _Color10;
            float4 _Color11;
            float4 _Color12;
            float4 _Color13;
            float4 _Color14;
            float _AmbientInc;
            float _AlbedoMultiplier;
            float _OcclusionPower;
            float _NormalMultiplier;
            float _MetallicMultiplier;
            float _SmoothMultiplier;
            float _EmissionMultiplier;
            float4 _EmissionMask;
            float _EmissionJitter;
            float _EmissionSwitch;
            float _AlphaClip;
            float _Biomo;
            float _BiomoMultiplier;
            float _BiomoHeight;
            float4 _SpecularColor;
            float _Crystal;
            float _CrystalRefrac;
            float4 _ScreenTex_TexelSize;
            
            sampler2D _MainTexA;
            sampler2D _MainTexB;
            sampler2D _OcclusionTex;
            sampler2D _MS_Tex;
            sampler2D _NormalTex;
            sampler2D _EmissionTex;
            sampler2D _EmissionJitterTex;
            samplerCUBE _Global_LocalPlanetHeightmap;
            sampler2D _ScreenTex;
            samplerCUBE _Global_PGI;
            
            // Keywords: DIRECTIONAL
            v2f vert(appdata_full v)
            {
                v2f o
                
                float objIndex = _IdBuffer[instanceID]; //r0.x
                
                float objId = _InstBuffer[objIndex].objId; //r1.x
                float3 pos = _InstBuffer[objIndex].pos; //r1.yzw
                float4 rot = _InstBuffer[objIndex].rot; //r2.xyzw
                
                float time = _AnimBuffer[objId].time; //r3.x
                float prepare_length = _AnimBuffer[objId].prepare_length; //r3.y
                float working_length = _AnimBuffer[objId].working_length; //r3.z
                uint state = _AnimBuffer[objId].state; //r3.w
                float power = _AnimBuffer[objId].power; //r0.y
                
                float3 scale = _ScaleBuffer[objIndex]; //r4.xyz
                bool useScale = _UseScale > 0.5;
                float3 scaledVPos = useScale ? v.vertex.xyz * scale.xyz : v.vertex.xyz; //r5.xyz
                float3 scaledVNormal = useScale ? v.normal.xyz * scale.xyz : v.normal.xyz; //r4.xyz
                float3 scaledVTan = v.tangent.xyz; //r6.xyz
                
                animateWithVerta(vertexID, time, prepare_length, working_length, /*inout*/ scaledVPos, /*inout*/ scaledVNormal, /*inout*/ scaledVTan);
                
                float3 worldVPos = rotate_vector_fast(scaledVPos, rot) + pos; //r5.xyz
                float3 worldVNormal = rotate_vector_fast(scaledVNormal, rot); //r7.xyz
                float3 worldTangent = rotate_vector_fast(scaledVTan, rot); //r4.yzx
                
                float posHeight = length(pos); //r0.x
                float3 upDir = float3(0,1,0); //r2.xyz
                float lodDist = 0; //r2.w
                if (posHeight > 0) {
                    upDir = pos / posHeight;
                    float g_heightMap = UNITY_SAMPLE_TEXCUBE_LOD(_Global_LocalPlanetHeightmap, normalize(worldVPos), 0).x; //r0.z
                    float g_adjustHeight = (_Global_Planet_Radius + g_heightMap) - posHeight; //r0.x
                    worldVPos = g_adjustHeight * upDir + worldVPos.xyz;
                    lodDist = saturate(0.01 * (distance(pos, _WorldSpaceCameraPos) - 180)); //r2.w
                }
                
                //float3 worldVPos = mul(unity_ObjectToWorld, float4(worldVPos,1)).xyz; //r0.xzw
                //float4 clipPos = UnityObjectToClipPos(worldVPos); //r6.xyzw
                
                worldVNormal = lerp(normalize(worldVNormal), upDir, 0.2 * lodDist); //r1.xyz
                
                float4 clipPos = mul(UNITY_MATRIX_VP, float4(worldVPos,1)); //r6.xyzw
                
                float viewDir = normalize(_WorldSpaceCameraPos.xyz - worldVPos.xyz); //r3.yzw
                float controlU = dot(worldTangent, viewDir);
                // r5.xyz = r4.xyz * r1.yzx;
                // r5.xyz = r4.zxy * r1.zxy - r5.xyz;
                // r1.w = dot(r5.xyz, r5.xyz);
                // r1.w = rsqrt(r1.w);
                // r5.xyz = r5.xyz * r1.www;
                float3 worldBitangent = normalize(cross(worldVNormal, worldTangent)); //r5.xyz
                float controlV = dot(worldBitangent, viewDir);
                
                //worldVNormal = UnityObjectToWorldNormal(worldVNormal);
                worldVNormal = normalize(worldVNormal); //r1.xyz
                worldTangent = float4(UnityObjectToWorldDir(worldTangent.xyz), v.tangent.w); //r3.yzw
                float3 worldBinormal = calculateBinormal(float4(worldTangent.xyz, v.tangent.w), worldVNormal); //r4.xyz
                
                // o8.x = clipPos.x * 0.5 + (clipPos.w * 0.5);
                // o8.y = clipPos.y * -0.5 + (clipPos.w * 0.5);
                // o8.zw = clipPos.zw;
                
                // o10.xy = float2(clipPos.x * 0.5, clipPos.y * 0.5 * _ProjectionParams.x) + (clipPos.w * 0.5);
                // o10.zw = clipPos.zw;
                
                o.pos.xyzw = clipPos.xyzw;
                
                o.TBN0.x = worldTangent.x;
                o.TBN0.y = worldBinormal.x;
                o.TBN0.z = worldVNormal.x;
                o.TBN0.w = worldVPos.x;
                o.TBN1.x = worldTangent.y;
                o.TBN1.y = worldBinormal.y;
                o.TBN1.z = worldVNormal.y;
                o.TBN1.w = worldVPos.y;
                o.TBN2.x = worldTangent.z;
                o.TBN2.y = worldBinormal.z;
                o.TBN2.z = worldVNormal.z;
                o.TBN2.w = worldVPos.z; //tex2
                
                o.uv_controlUV.xy = v.texcoord.xy;
                o.uv_controlUV.z = controlU;
                o.uv_controlUV.w = controlV;
                
                o.upDir_lodDist.xyz = upDir.xyz; //o5 //tex4
                o.upDir_lodDist.w = lodDist; //o5
                
                o.time_state_emiss.x = time; //o6.x //tex5
                o.time_state_emiss.y = state; //o6.y
                o.time_state_emiss.z = lerp(1, power, _EmissionUsePower); //o6.z
                o.worldPos1.xyz = worldVPos; //o7 //tex6
                o.screenPosIsh.x = clipPos.x * 0.5 + clipPos.w * 0.5; // ??
                o.screenPosIsh.y = clipPos.y * -0.5 + clipPos.w * 0.5; // ??
                o.screenPosIsh.zw = clipPos.zw; //tex7
                o.indirectLight.xyz = ShadeSH9(float4(worldVNormal, 1.0));
                UNITY_TRANSFER_SHADOW(o, float(0,0));
                //o10.xyzw = ComputeScreenPos(o.pos);
                o11.xyzw = float4(0,0,0,0);
                
                return o;
            }
            // Keywords: DIRECTIONAL
            fout frag(v2f inp)
            {
                fout o;
                  
                  float2 uv = inp.uv_viewAngle.xy;
                  float2 controlUV = inp.uv_controlUV.zw;
                  float3 upDir = inp.upDir_lodDist.xyz;
                  float lodDist = inp.upDir_lodDist.w;
                  float time = inp.time_state_emiss.x;
                  float veinType = inp.time_state_emiss.y;
                  float emissionPower = inp.time_state_emiss.z;
                  float3 worldPos1 = inp.worldPos.xyz;
                  float3 worldPos1 = inp.screenPosIsh.xyz;
                  float3 indirectLight = inp.indirectLight.xyz;
                  
                  
                  float3 veinColor = float3(0,0,0); //r0.xyz
                  if (veinType < 1.05 && 0.95 < veinType) { //iron
                    veinColor = _Color1.xyz;
                  } else {
                    if (veinType < 2.05 && 1.95 < veinType) { //copper
                      veinColor = _Color2.xyz;
                    } else {
                      if (veinType < 3.05 && 2.95 < veinType) { //Silicon
                        veinColor = _Color3.xyz;
                      } else {
                        if (veinType < 4.05 && 3.95 < veinType) { //titanium
                          veinColor = _Color4.xyz;
                        } else {
                          if (veinType < 5.05 && 4.95 < veinType) { //stone
                            veinColor = _Color5.xyz;
                          } else {
                            if (veinType < 6.05 && 5.95 < veinType) { //coal
                              veinColor = _Color6.xyz;
                            } else {
                              if (veinType < 9.05 && 8.95 < veinType) { //diamond
                                veinColor = _Color9.xyz;
                              } else {
                                veinColor = veinType < 14.05 && 13.95 < veinType ? _Color14.xyz : _Color0.xyz; //mag, then none
                                veinColor = veinType < 13.05 && 12.95 < veinType ? _Color13.xyz : veinColor; //bamboo
                                veinColor = veinType < 12.05 && 11.95 < veinType ? _Color12.xyz : veinColor; //grat
                                veinColor = veinType < 11.05 && 10.95 < veinType ? _Color11.xyz : veinColor; //crysrub
                                veinColor = veinType < 10.05 && 9.95 < veinType ? _Color10.xyz : veinColor; //frac
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                  
                  // r0.x = cmp(0.949999988 < v6.y);
                  // r0.y = cmp(v6.y < 1.04999995);
                  // r0.x = r0.y ? r0.x : 0;
                  // if (r0.x != 0) {
                  //   r0.xyz = cb0[31].xyz;
                  // } else {
                  //   r0.w = cmp(1.95000005 < v6.y);
                  //   r1.x = cmp(v6.y < 2.04999995);
                  //   r0.w = r0.w ? r1.x : 0;
                  //   if (r0.w != 0) {
                  //     r0.xyz = cb0[32].xyz;
                  //   } else {
                  //     r0.w = cmp(2.95000005 < v6.y);
                  //     r1.x = cmp(v6.y < 3.04999995);
                  //     r0.w = r0.w ? r1.x : 0;
                  //     if (r0.w != 0) {
                  //       r0.xyz = cb0[33].xyz;
                  //     } else {
                  //       r0.w = cmp(3.95000005 < v6.y);
                  //       r1.x = cmp(v6.y < 4.05000019);
                  //       r0.w = r0.w ? r1.x : 0;
                  //       if (r0.w != 0) {
                  //         r0.xyz = cb0[34].xyz;
                  //       } else {
                  //         r0.w = cmp(4.94999981 < v6.y);
                  //         r1.x = cmp(v6.y < 5.05000019);
                  //         r0.w = r0.w ? r1.x : 0;
                  //         if (r0.w != 0) {
                  //           r0.xyz = cb0[35].xyz;
                  //         } else {
                  //           r0.w = cmp(5.94999981 < v6.y);
                  //           r1.x = cmp(v6.y < 6.05000019);
                  //           r0.w = r0.w ? r1.x : 0;
                  //           if (r0.w != 0) {
                  //             r0.xyz = cb0[36].xyz;
                  //           } else {
                  //             r0.w = cmp(8.94999981 < v6.y);
                  //             r1.x = cmp(v6.y < 9.05000019);
                  //             r0.w = r0.w ? r1.x : 0;
                  //             if (r0.w != 0) {
                  //               r0.xyz = cb0[37].xyz;
                  //             } else {
                  //               r1.xyzw = cmp(float4(9.94999981,10.9499998,11.9499998,12.9499998) < v6.yyyy);
                  //               r2.xyzw = cmp(v6.yyyy < float4(10.0500002,11.0500002,12.0500002,13.0500002));
                  //               r1.xyzw = r1.xyzw ? r2.xyzw : 0;
                  //               r0.w = cmp(13.9499998 < v6.y);
                  //               r2.x = cmp(v6.y < 14.0500002);
                  //               r0.w = r0.w ? r2.x : 0;
                  //               r2.xyz = r0.www ? cb0[42].xyz : cb0[30].xyz;
                  //               r2.xyz = r1.www ? cb0[41].xyz : r2.xyz;
                  //               r2.xyz = r1.zzz ? cb0[40].xyz : r2.xyz;
                  //               r1.yzw = r1.yyy ? cb0[39].xyz : r2.xyz;
                  //               r0.xyz = r1.xxx ? cb0[38].xyz : r1.yzw;
                  //             }
                  //           }
                  //         }
                  //       }
                  //     }
                  //   }
                  // }
                  
                  float3 mstex = UNITY_SAMPLE_TEX2D(_MS_Tex, uv).xyw; //r1.xyz
                  
                  if (mstex.y < _AlphaClip - 0.001) discard;
                  
                  float3 colorA = tex2D(_MainTexA, uv).xyz * veinColor; //r2.xyz
                  float4 colorB = tex2D(_MainTexB, uv); //r3.xyzw
                  float2 occTex = tex2D(_OcclusionTex, uv).xw; //r1.yw
                  float3 albedo = lerp(colorA.xyz * float3(6.0, 6.0, 6.0), colorB.xyz * float3(1.7, 1.7, 1.7), (1.0 - lodDist) * colorB.w); //r2.xyz
                  
                  albedo = albedo * pow(lerp(1.0, occTex.x, occTex.y), _OcclusionPower); //r2.xyz
                  
                  float3 unpackedNormal = UnpackNormal(tex2Dbias(_NormalTex, float4(uv, 0, -1))); //r3.xyz
                  float3 normal = float3(_NormalMultiplier * unpackedNormal.xy, unpackedNormal.z); //r3.xyz
                  
                  float4 emmTex = tex2Dbias(_EmissionTex, float4(uv,0,-1)); //r4.xyzw
                  
                  float emmJitTex = UNITY_SAMPLE_TEX2D(_EmissionJitterTex, float2(time, 0)).x; //r0.w
                  
                  float canEmit = (int)(emissionPower > 0.1) | (int)(_EmissionSwitch < 0.5) ? 1.0 : 0.0; //r3.w
                  
                  float2 g_heightMap = UNITY_SAMPLE_TEXCUBE(_Global_LocalPlanetHeightmap, normalize(worldPos1)).xy; //r5.xy
                  float frac_heightMap = frac(g_heightMap.y);
                  float int_heightMap = g_heightMap.y - frac_heightMap;
                  float biomoThreshold = (frac_heightMap * frac_heightMap) * (frac_heightMap * -2.0 + 3.0) + int_heightMap;
                  float biomoThreshold0 = saturate(1.0 - biomoThreshold);
                  float biomoThreshold1 = min(saturate(2.0 - biomoThreshold), saturate(biomoThreshold));
                  float biomoThreshold2 = saturate(biomoThreshold - 1);
                  float4 biomoColor = biomoThreshold1 * _Global_Biomo_Color1; //r6.xyzw
                  biomoColor = _Global_Biomo_Color0 * biomoThreshold0 + biomoColor;
                  biomoColor = _Global_Biomo_Color2 * biomoThreshold2 + biomoColor;
                  biomoColor.xyz = biomoColor.xyz * _BiomoMultiplier; //r5.yzw
                  
                  float heightOffset = saturate((_BiomoHeight - length(worldPos1) - g_heightMap.x + _Global_Planet_Radius) / _BiomoHeight); //r1.y
                  heightOffset = biomoColor.w * pow(heightOffset, 2); //r1.w
                  
                  multiAlbedo = _AlbedoMultiplier * albedo; //r6.xyz
                  
                  biomoColor.xyz = lerp(biomoColor.xyz, biomoColor.xyz * albedo, _Biomo); //r5.xyz //r6.w
                  
                  float screenAspect = _ScreenTex_TexelSize.z / _ScreenTex_TexelSize.w; //r5.w
                  float2 controlRefraction = _CrystalRefrac * float2(controlUV.x, controlUV.y * screenAspect); //r7.yz
                  float2 uvRefraction = (screenPosIsh.xy - controlRefraction.xy) / screenPosIsh.ww;
                  float3 screenTex = tex2D(_ScreenTex, uvRefraction).xyz; //r7.xyz
                  
                  albedo = lerp(multiAlbedo, biomoColor.xyz, heightOffset); //r2.xyz
                  
                  screenTex = _Crystal * screenTex; //r5.xyz
                  
                  r6.xy = float2(4,4) * saturate(controlUV.xy - float2(0.3, 0.3));
                  r1.w = saturate(3.0 - length(r6.xy));
                  screenTex.xyz = screenTex.xyz * r1.www; //r5.xyz
                  albedo = albedo + screenTex.xyz * (1 - heightOffset * biomoColor.w);
                  
                  normal = normalize(normal); //r3.xyz
                  
                  r1.xy = saturate(cb0[44].xy * r1.xz);
                  
                  // r4.xyz = cb0[44].zzz * r4.xyz;
                  // r1.zw = cb0[46].yx * r4.ww;
                  // r2.w = -1 + r2.w;
                  // r1.z = r1.z * r2.w + 1;
                  // r4.xyz = r4.xyz * r1.zzz;
                  // r1.z = cb0[46].y * r1.w;
                  // r0.w = -1 + r0.w;
                  // r0.w = r1.z * r0.w + 1;
                  // r4.xyz = r4.xyz * r0.www;
                  // r4.xyz = r4.xyz * r3.www;
                  
                  /* calculate emission/glow from the textures and the various properties that control emission. */
                  float3 emissionColor = _EmissionMultiplier * emmTex.xyz;
                  float emissionSwitch = _EmissionSwitch * emmTex.w;
                  float emissionJitter = _EmissionJitter * emmTex.w;
                  float emmIsOn = lerp(1, saturate(veinType), emissionSwitch);
                  emissionColor = emissionColor * emmIsOn;
                  float jitterRatio = _EmissionSwitch * emissionJitter;
                  float jitter = lerp(1.0, emmJitTex, jitterRatio);
                  emissionColor = emissionColor * jitter;
                  emissionColor = emissionColor * canEmit; // r4.xyz
                  
                  float3 worldPos = float3(inp.TBN0.w, inp.TBN1.w, inp.TBN2.w); //r5.yzw
                  
                  // r6.xyz = cb1[4].xyz + -r5.yzw;
                  // r0.w = dot(r6.xyz, r6.xyz);
                  // r0.w = rsqrt(r0.w);
                  // r7.xyz = r6.xyz * r0.www;
                  // r8.x = cb4[9].z;
                  // r8.y = cb4[10].z;
                  // r8.z = cb4[11].z;
                  // r1.z = dot(r6.xyz, r8.xyz);
                  // r8.xyz = -cb3[25].xyz + r5.yzw;
                  // r1.w = dot(r8.xyz, r8.xyz);
                  // r1.w = sqrt(r1.w);
                  // r1.w = r1.w + -r1.z;
                  // r1.z = cb3[25].w * r1.w + r1.z;
                  // r1.z = saturate(r1.z * cb3[24].z + cb3[24].w);
                  // r1.w = cmp(cb5[0].x == 1.000000);
                  // if (r1.w != 0) {
                  //   r1.w = cmp(cb5[0].y == 1.000000);
                  //   r8.xyz = cb5[2].xyz * v2.www;
                  //   r8.xyz = cb5[1].xyz * v1.www + r8.xyz;
                  //   r8.xyz = cb5[3].xyz * v3.www + r8.xyz;
                  //   r8.xyz = cb5[4].xyz + r8.xyz;
                  //   r5.xyz = r1.www ? r8.xyz : r5.yzw;
                  //   r5.xyz = -cb5[6].xyz + r5.xyz;
                  //   r5.yzw = cb5[5].xyz * r5.xyz;
                  //   r1.w = r5.y * 0.25 + 0.75;
                  //   r2.w = cb5[0].z * 0.5 + 0.75;
                  //   r5.x = max(r2.w, r1.w);
                  //   r5.xyzw = t11.Sample(s1_s, r5.xzw).xyzw;
                  // } else {
                  //   r5.xyzw = float4(1,1,1,1);
                  // }
                  // r1.w = saturate(dot(r5.xyzw, cb2[46].xyzw));
                  // r5.xy = v10.xy / v10.ww;
                  // r2.w = t9.Sample(s2_s, r5.xy).x;
                  // r1.w = -r2.w + r1.w;
                  // r1.z = r1.z * r1.w + r2.w;
                  UNITY_LIGHT_ATTENUATION(atten, inp, worldPos); //r1.z
                  
                  float3 viewDir = normalize(_WorldSpaceCameraPos - worldPos); //r7.xyz or (r6.xyz * r0.www)
                  
                  float3 worldNormal;
                  worldNormal.x = dot(inp.TBN0.xyz, normal.xyz);
                  worldNormal.y = dot(inp.TBN1.xyz, normal.xyz);
                  worldNormal.z = dot(inp.TBN2.xyz, normal.xyz);
                  worldNormal = normalize(worldNormal); //r3.xyz
                  
                  float metallicLow = metallic * 0.85 + 0.149; //r1.w
                  float metallicHigh = metallic * 0.85 + 0.649; //r1.x
                  
                  float perceptualRoughness = 1 - smoothness * 0.97; //r1.y
                  
                  float3 lightDir = _WorldSpaceLightPos0;
                  
                  float3 halfDir = normalize(viewDir + lightDir); //r5.xyz
                  
                  float roughness = perceptualRoughness * perceptualRoughness; //r0.w
                  //r2.w = r0.w * r0.w;
                  
                  float unclamped_nDotL = dot(worldNormal, lightDir); //r3.w
                  float nDotL = max(0, unclamped_nDotL); //r4.w
                  float unclamped_nDotV = dot(worldNormal, viewDir); //r5.w
                  float nDotV = max(0, unclamped_nDotV); //r5.w
                  float unclamped_nDotH = dot(worldNormal, halfDir); //r6.x
                  float nDotH = max(0, unclamped_nDotH); //r6.x
                  float unclamped_vDotH = dot(viewDir, halfDir); //r5.x
                  float vDotH = max(0, unclamped_vDotH); //r5.x
                  
                  //cubed_ndotl
                  r3.w = r3.w * 0.349999994 + 1;
                  r5.y = r3.w * r3.w;
                  r3.w = r5.y * r3.w;
                  
                  float upDotL = dot(upDir, lightDir); //r5.y
                  float nDotUp = dot(worldNormal, upDir); //r5.z
                  
                  //float upDotUp = dot(upDir, upDir); //r6.y
                  // r6.z = cmp(v5.y < 0.999899983);
                  // r6.y = cmp(0.00999999978 < r6.y);
                  // r6.z = r6.y ? r6.z : 0;
                  // r8.xyz = float3(0,1,0) * v5.yzx;
                  // r8.xyz = v5.xyz * float3(1,0,0) + -r8.xyz;
                  // r6.w = dot(r8.xy, r8.xy);
                  // r6.w = rsqrt(r6.w);
                  // r8.xyz = r8.xyz * r6.www;
                  // r8.xyz = r6.zzz ? r8.xyz : float3(0,1,0);
                  // r6.z = dot(r8.xy, r8.xy);
                  // r6.z = cmp(0.00999999978 < r6.z);
                  // r6.y = r6.z ? r6.y : 0;
                  // r9.xyz = v5.yzx * r8.xyz;
                  // r9.xyz = r8.zxy * v5.zxy + -r9.xyz;
                  // r6.z = dot(r9.xyz, r9.xyz);
                  // r6.z = rsqrt(r6.z);
                  // r9.xyz = r9.xyz * r6.zzz;
                  // r6.z = dot(-viewDir, r3.xyz);
                  // r6.z = r6.z + r6.z;
                  // r7.xyz = r3.xyz * -r6.zzz + -viewDir;
                  // r8.x = dot(r7.zx, -r8.xy);
                  // r8.y = dot(r7.xyz, v5.xyz);
                  // r6.yzw = r6.yyy ? -r9.xyz : float3(-0,-0,-1);
                  // r8.z = dot(r7.xyz, r6.yzw);
                  // r6.y = log2(r1.y);
                  // r6.y = 0.400000006 * r6.y;
                  // r6.y = exp2(r6.y);
                  // r6.y = 10 * r6.y;
                  // r6.yzw = t10.SampleLevel(s3_s, r8.xyz, r6.y).xyz;
                  // r7.x = r1.w * 0.699999988 + 0.300000012;
                  // r1.y = 1 + -r1.y;
                  // r1.y = r7.x * r1.y;
                  // r6.yzw = r6.yzw * r1.yyy;
                  
                  float reflectivity; //r1.y
                  float3 reflectColor = reflection(perceptualRoughness, metallicLow, upDir, viewDir, worldNormal, /*out*/ reflectivity); //r6.yzw
                  
                  // r7.x = cmp(1 >= r5.y);
                  // if (r7.x != 0) {
                  //   r7.xyzw = float4(-0.200000003,-0.100000001,0.100000001,0.300000012) + r5.yyyy;
                  //   r7.xyzw = saturate(float4(5,10,5,5) * r7.xyzw);
                  //   r8.xyz = float3(1,1,1) + -cb0[12].xyz;
                  //   r8.xyz = r7.xxx * r8.xyz + cb0[12].xyz;
                  //   r9.xyz = float3(1.25,1.25,1.25) * cb0[13].xyz;
                  //   r10.xyz = -cb0[13].xyz * float3(1.25,1.25,1.25) + cb0[12].xyz;
                  //   r9.xyz = r7.yyy * r10.xyz + r9.xyz;
                  //   r10.xyz = cmp(float3(0.200000003,0.100000001,-0.100000001) < r5.yyy);
                  //   r11.xyz = float3(1.5,1.5,1.5) * cb0[14].xyz;
                  //   r12.xyz = cb0[13].xyz * float3(1.25,1.25,1.25) + -r11.xyz;
                  //   r7.xyz = r7.zzz * r12.xyz + r11.xyz;
                  //   r11.xyz = r11.xyz * r7.www;
                  //   r7.xyz = r10.zzz ? r7.xyz : r11.xyz;
                  //   r7.xyz = r10.yyy ? r9.xyz : r7.xyz;
                  //   r7.xyz = r10.xxx ? r8.xyz : r7.xyz;
                  // } else {
                  //   r7.xyz = float3(1,1,1);
                  // }
                  float3 sunsetColor = float3(1, 1, 1); //r7.xyz
                  if (upDotL <= 1) {
                      float3 sunsetColor0 = _Global_SunsetColor0.xyz;
                      float3 sunsetColor1 = _Global_SunsetColor1.xyz * float3(1.25, 1.25, 1.25);
                      float3 sunsetColor2 = _Global_SunsetColor2.xyz * float3(1.5, 1.5, 1.5);
                      
                      float3 sunsetBlendDawn    = lerp(float3(0,0,0), sunsetColor2,  saturate(5  * (upDotL + 0.3))); // -30% to -10%
                      float3 sunsetBlendSunrise = lerp(sunsetColor2,  sunsetColor1,  saturate(5  * (upDotL + 0.1))); // -10% to  10%
                      float3 sunsetBlendMorning = lerp(sunsetColor1,  sunsetColor0,  saturate(10 * (upDotL - 0.1))); //  10% to  20%
                      float3 sunsetBlendDay     = lerp(sunsetColor0,  float3(1,1,1), saturate(5  * (upDotL - 0.2))); //  20% to  40%
                      
                      sunsetColor = upDotL > -0.1 ? sunsetBlendSunrise : sunsetBlendDawn;
                      sunsetColor = upDotL >  0.1 ? sunsetBlendMorning : sunsetColor;
                      sunsetColor = upDotL >  0.2 ? sunsetBlendDay     : sunsetColor; //r7.xyz
                  }
                  sunsetColor = _LightColor0.xyz * sunsetColor;
                  
                  r8.xy = float2(0.150000006,3) * r5.yy;
                  r8.xy = saturate(r8.xy);
                  
                  atten = 0.8 * lerp(atten, 1, saturate(0.15 * upDotL)); //r1.z
                  lightColor = atten * lightColor; //r7.xyz
                  
                  // r1.z = r6.x * r6.x;
                  // r8.xz = r0.ww * r0.ww + float2(-1,1);
                  // r0.w = r1.z * r8.x + 1;
                  // r0.w = rcp(r0.w);
                  // r0.w = r0.w * r0.w;
                  // r0.w = r0.w * r2.w;
                  // r0.w = 0.25 * r0.w;
                  // r1.z = r8.z * r8.z;
                  // r2.w = 0.125 * r1.z;
                  // r1.z = -r1.z * 0.125 + 1;
                  // r5.w = r5.w * r1.z + r2.w;
                  // r1.z = r4.w * r1.z + r2.w;
                  // r8.xz = float2(1,1) + -r1.xw;
                  // r2.w = r5.x * -5.55472994 + -6.98316002;
                  // r2.w = r2.w * r5.x;
                  // r2.w = exp2(r2.w);
                  // r1.x = r8.x * r2.w + r1.x;
                  // r0.w = r1.x * r0.w;
                  // r1.x = r5.w * r1.z;
                  // r1.x = rcp(r1.x);
                  
                  float specularTerm = GGX(roughness, metallicHigh, nDotH, nDotV, nDotL, vDotH);
                  
                  // r1.z = cmp(0 < r5.y);
                  // r9.xyz = -cb0[7].xyz + cb0[6].xyz;
                  // r8.xyw = r8.yyy * r9.xyz + cb0[7].xyz;
                  // r2.w = saturate(r5.y * 3 + 1);
                  // r9.xyz = -cb0[8].xyz + cb0[7].xyz;
                  // r9.xyz = r2.www * r9.xyz + cb0[8].xyz;
                  // r8.xyw = r1.zzz ? r8.xyw : r9.xyz;
                  
                  float3 ambientTwilight = lerp(_Global_AmbientColor2.xyz, _Global_AmbientColor1.xyz, saturate(upDotL * 3.0 + 1)); //-33% to 0%
                  float3 ambientLowSun = lerp(_Global_AmbientColor1.xyz, _Global_AmbientColor0.xyz, saturate(upDotL * 3.0)); // 0% - 33%
                  float3 ambientColor = upDotL > 0 ? ambientLowSun : ambientTwilight; //r8.xyw
                  
                  // r1.z = saturate(r5.z * 0.300000012 + 0.699999988);
                  // r5.xzw = r8.xyw * r1.zzz;
                  // r5.xzw = r5.xzw * r3.www;
                  // r1.z = 1 + cb0[43].x;
                  // r5.xzw = r5.xzw * r1.zzz;
                  float3 ambientLightColor = ambientColor * saturate(nDotUp * 0.3 + 0.7);
                  ambientLightColor = ambientLightColor * pow(unclamped_nDotL * 0.35 + 1, 3);
                  ambientLightColor = ambientLightColor * (_AmbientInc + 1); //r5.xzw
                  
                  // r1.z = cmp(cb0[29].w >= 0.5);
                  // r2.w = dot(cb0[29].xyz, cb0[29].xyz);
                  // r2.w = sqrt(r2.w);
                  // r2.w = -5 + r2.w;
                  // r3.w = saturate(r2.w);
                  // r6.x = dot(-v5.xyz, lightDir);
                  // r6.x = saturate(5 * r6.x);
                  // r3.w = r6.x * r3.w;
                  // r9.xyz = -v5.xyz * r2.www + cb0[29].xyz;
                  // r2.w = dot(r9.xyz, r9.xyz);
                  // r2.w = sqrt(r2.w);
                  // r6.x = 20 + -r2.w;
                  // r6.x = 0.0500000007 * r6.x;
                  // r6.x = max(0, r6.x);
                  // r6.x = r6.x * r6.x;
                  // r7.w = cmp(r2.w < 0.00100000005);
                  // r10.xyz = float3(1.29999995,1.10000002,0.600000024) * r3.www;
                  // r9.xyz = r9.xyz / r2.www;
                  // r2.w = saturate(dot(r9.xyz, r3.xyz));
                  // r2.w = r2.w * r6.x;
                  // r2.w = r2.w * r3.w;
                  // r3.xyz = float3(1.29999995,1.10000002,0.600000024) * r2.www;
                  // r3.xyz = r7.www ? r10.xyz : r3.xyz;
                  // r3.xyz = r1.zzz ? r3.xyz : 0;
                  float3 headlampLight = calculateLightFromHeadlamp(_Global_PointLightPos, upDir, lightDir, worldNormal); //r3.xyz
                  
                  // r3.xyz = r4.www * r7.xyz + r3.xyz;
                  // r3.xyz = r3.xyz * r2.xyz;
                  float3 headlampLightColor = nDotL * lightColor + headlampLight;
                  headlampLightColor = albedo * headlampLightColor; //r3.xyz
                  
                  // r1.z = log2(r8.z);
                  // r1.z = 0.600000024 * r1.z;
                  // r1.z = exp2(r1.z);
                  
                  // r9.xyz = float3(-1,-1,-1) + r2.xyz;
                  // r9.xyz = r1.www * r9.xyz + float3(1,1,1);
                  // r9.xyz = cb0[48].xyz * r9.xyz;
                  // r7.xyz = r9.xyz * r7.xyz;
                  // r0.w = specularTerm + 0.0318309888;
                  // r7.xyz = r7.xyz * r0.www;
                  // r7.xyz = r7.xyz * r4.www;
                  float3 specularColor = _SpecularColor.xyz * lerp(float3(1.0, 1.0, 1.0), albedo, metallicLow);
                  specularColor = specularColor * lightColor;
                  float INV_TEN_PI = 0.0318309888;
                  specularColor = specularColor * nDotL * (specularTerm + INV_TEN_PI); //r7.xyz
                  
                  // r0.w = 0.200000003 * r8.z;
                  // r9.xyz = r0.www * r2.xyz + r1.www;
                  // r7.xyz = r9.xyz * r7.xyz;
                  float3 specColorMod = (1.0 - metallicLow) * 0.2 * albedo + metallicLow;
                  specularColor = specularColor * specColorMod; //r7.xyz
                  
                  //r5.xzw = r5.xzw * r2.xyz; //r5.xzw
                  ambientLightColor = albedo * ambientLightColor; //r5.xzw
                  
                  float3 ambientSpecularLight = ambientLightColor * (1.0 - metallicLow * 0.6); //r9.xyz
                  float ambientSpecularLuminance = dot(ambientSpecularLight, float3(0.3, 0.6, 0.1)); //r1.x
                  r5.xzw = lerp(ambientSpecularLight, ambientSpecularLuminance, float3(0.5, 0.5, 0.5)); //r5.xzw
                  
                  // r0.w = dot(ambientColor.xyx, float3(0.3, 0.6, 0.1));
                  // r0.w = 0.00300000003 + r0.w;
                  // r1.x = max(cb0[6].x, cb0[6].y);
                  // r1.x = max(cb0[6].z, r1.x);
                  // r1.x = 0.00300000003 + r1.x;
                  float ambientLuminance = 0.003 + dot(ambientColor.xyx, float3(0.3, 0.6, 0.1)); //r0.w
                  float maxAmbient = 0.003 + max(_Global_AmbientColor0.z, max(_Global_AmbientColor0.x, _Global_AmbientColor0.y)); //r1.x
                  
                  // r1.x = 1 / r1.x;
                  // r8.xyz = r8.xyw + -r0.www;
                  // r8.xyz = r8.xyz * float3(0.400000006,0.400000006,0.400000006) + r0.www;
                  // r8.xyz = r8.xyz * r1.xxx;
                  float3 greyedAmbient = lerp(ambientLuminance, ambientColor, float3(0.4, 0.4, 0.4)) / maxAmbient; //r8.xyz
                  // r8.xyz = float3(1.70000005,1.70000005,1.70000005) * r8.xyz;
                  // r6.xyz = r8.xyz * r6.yzw;
                  reflectColor = reflectColor * float3(1.7, 1.7, 1.7) * greyedAmbient; //r6.xyz
                  
                  //r0.w = saturate(r5.y * 2 + 0.5);
                  //r0.w = r0.w * 0.699999988 + 0.300000012;
                  float reflectStrength = saturate(upDotL * 2.0 + 0.5) * 0.7 + 0.3; //r0.w
                  //r8.xyz = r6.xyz * r0.www;
                  float reflectLuminance = dot(reflectColor * reflectStrength, float3(0.3, 0.6, 0.1)); //r1.x
                  reflectColor = lerp(reflectColor * reflectStrength, reflectLuminance, float3(0.8, 0.8, 0.8); //r6.xyz
                  reflectColor = reflectColor * lerp(float3(1,1,1), veinColor, float3(0.8, 0.8, 0.8)); //r0.xyz
                  
                  float3 finalColor = headlampLightColor * pow(1.0 - metallicLow, 0.6) + specularColor + r5.xzw; //r1.xzw
                  finalColor = lerp(finalColor, reflectColor * albedo, reflectivity);
                  
                  //r0.w = dot(r0.xyz, float3(0.3, 0.6, 0.1));
                  float colorIntensity = dot(finalColor, float3(0.3, 0.6, 0.1)); //r0.w
                  // r1.x = r0.w > 1.0;
                  // r1.yzw = r0.xyz / r0.www;
                  // r0.w = log2(r0.w);
                  // r0.w = r0.w * 0.693147182 + 1;
                  // r0.w = log2(r0.w);
                  // r0.w = r0.w * 0.693147182 + 1;
                  // r1.yzw = r1.yzw * r0.www;
                  // r0.xyz = r1.xxx ? r1.yzw : r0.xyz;
                  finalColor = colorIntensity > 1.0 ? (finalColor / colorIntensity) * (log(log(colorIntensity) + 1) + 1) : finalColor; //r0.xyz
                  
                  o.sv_target.xyz = emissionColor * _EmissionMask.xyz
                    + albedo * indirectLight
                    + finalColor;
                  o.sv_target.w = 1;
                  
                  return o;
            }
            ENDCG
        }
        Pass {
            Name "FORWARD"
            LOD 200
            Tags { "DisableBatching" = "true" "LIGHTMODE" = "FORWARDADD" "RenderType" = "Opaque" }
            Blend One One, One One
            ZWrite Off
            Cull Off
            GpuProgramID 107329
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "UnityCG.cginc"
            struct v2f
            {
                float4 position : SV_POSITION0;
                float3 texcoord : TEXCOORD0;
                float3 texcoord1 : TEXCOORD1;
                float3 texcoord2 : TEXCOORD2;
                float3 texcoord3 : TEXCOORD3;
                float4 texcoord4 : TEXCOORD4;
                float4 texcoord5 : TEXCOORD5;
                float3 texcoord6 : TEXCOORD6;
                float3 texcoord7 : TEXCOORD7;
                float4 texcoord8 : TEXCOORD8;
                float3 texcoord9 : TEXCOORD9;
                float4 texcoord10 : TEXCOORD10;
            };
            struct fout
            {
                float4 sv_target : SV_Target0;
            };
            // $Globals ConstantBuffers for Vertex Shader
            float4x4 unity_WorldToLight;
            float _EmissionUsePower;
            // $Globals ConstantBuffers for Fragment Shader
            float4 _LightColor0;
            float4 _Global_AmbientColor0;
            float4 _Global_AmbientColor1;
            float4 _Global_AmbientColor2;
            float4 _Global_SunsetColor0;
            float4 _Global_SunsetColor1;
            float4 _Global_SunsetColor2;
            float4 _Global_Biomo_Color0;
            float4 _Global_Biomo_Color1;
            float4 _Global_Biomo_Color2;
            float _Global_Planet_Radius;
            float4 _Global_PointLightPos;
            float4 _Color0;
            float4 _Color1;
            float4 _Color2;
            float4 _Color3;
            float4 _Color4;
            float4 _Color5;
            float4 _Color6;
            float4 _Color9;
            float4 _Color10;
            float4 _Color11;
            float4 _Color12;
            float4 _Color13;
            float4 _Color14;
            float _AmbientInc;
            float _AlbedoMultiplier;
            float _OcclusionPower;
            float _NormalMultiplier;
            float _MetallicMultiplier;
            float _SmoothMultiplier;
            float _AlphaClip;
            float _Biomo;
            float _BiomoMultiplier;
            float _BiomoHeight;
            float4 _SpecularColor;
            float _Crystal;
            float _CrystalRefrac;
            float4 _ScreenTex_TexelSize;
            // Custom ConstantBuffers for Vertex Shader
            // Custom ConstantBuffers for Fragment Shader
            // Texture params for Vertex Shader
            // Texture params for Fragment Shader
            sampler2D _MainTexA;
            sampler2D _MainTexB;
            sampler2D _OcclusionTex;
            sampler2D _MS_Tex;
            sampler2D _NormalTex;
            samplerCUBE _Global_LocalPlanetHeightmap;
            sampler2D _ScreenTex;
            sampler2D _LightTexture0;
            samplerCUBE _Global_PGI;
            
            // Keywords: POINT
            v2f vert(appdata_full v)
            {
                v2f o;
                float4 tmp0;
                float4 tmp1;
                float4 tmp2;
                float4 tmp3;
                float4 tmp4;
                float4 tmp5;
                tmp0 = v.vertex.yyyy * unity_ObjectToWorld._m01_m11_m21_m31;
                tmp0 = unity_ObjectToWorld._m00_m10_m20_m30 * v.vertex.xxxx + tmp0;
                tmp0 = unity_ObjectToWorld._m02_m12_m22_m32 * v.vertex.zzzz + tmp0;
                tmp1 = tmp0 + unity_ObjectToWorld._m03_m13_m23_m33;
                tmp0 = unity_ObjectToWorld._m03_m13_m23_m33 * v.vertex.wwww + tmp0;
                tmp2 = tmp1.yyyy * unity_MatrixVP._m01_m11_m21_m31;
                tmp2 = unity_MatrixVP._m00_m10_m20_m30 * tmp1.xxxx + tmp2;
                tmp2 = unity_MatrixVP._m02_m12_m22_m32 * tmp1.zzzz + tmp2;
                tmp1 = unity_MatrixVP._m03_m13_m23_m33 * tmp1.wwww + tmp2;
                o.position = tmp1;
                tmp2.x = v.tangent.w * unity_WorldTransformParams.w;
                tmp2.y = dot(v.normal.xyz, v.normal.xyz);
                tmp2.y = rsqrt(tmp2.y);
                tmp2.yzw = tmp2.yyy * v.normal.xyz;
                tmp3.y = dot(tmp2.xyz, unity_WorldToObject._m00_m10_m20);
                tmp3.z = dot(tmp2.xyz, unity_WorldToObject._m01_m11_m21);
                tmp3.x = dot(tmp2.xyz, unity_WorldToObject._m02_m12_m22);
                tmp3.w = dot(tmp3.xyz, tmp3.xyz);
                tmp3.w = rsqrt(tmp3.w);
                tmp3.xyz = tmp3.www * tmp3.xyz;
                tmp4.xyz = v.tangent.yyy * unity_ObjectToWorld._m11_m21_m01;
                tmp4.xyz = unity_ObjectToWorld._m10_m20_m00 * v.tangent.xxx + tmp4.xyz;
                tmp4.xyz = unity_ObjectToWorld._m12_m22_m02 * v.tangent.zzz + tmp4.xyz;
                tmp3.w = dot(tmp4.xyz, tmp4.xyz);
                tmp3.w = rsqrt(tmp3.w);
                tmp4.xyz = tmp3.www * tmp4.xyz;
                tmp5.xyz = tmp3.xyz * tmp4.xyz;
                tmp5.xyz = tmp3.zxy * tmp4.yzx + -tmp5.xyz;
                tmp5.xyz = tmp2.xxx * tmp5.xyz;
                o.texcoord.y = tmp5.x;
                o.texcoord.x = tmp4.z;
                o.texcoord.z = tmp3.y;
                o.texcoord1.x = tmp4.x;
                o.texcoord2.x = tmp4.y;
                o.texcoord1.z = tmp3.z;
                o.texcoord2.z = tmp3.x;
                o.texcoord1.y = tmp5.y;
                o.texcoord2.y = tmp5.z;
                tmp3.xyz = v.vertex.yyy * unity_ObjectToWorld._m01_m11_m21;
                tmp3.xyz = unity_ObjectToWorld._m00_m10_m20 * v.vertex.xxx + tmp3.xyz;
                tmp3.xyz = unity_ObjectToWorld._m02_m12_m22 * v.vertex.zzz + tmp3.xyz;
                tmp3.xyz = unity_ObjectToWorld._m03_m13_m23 * v.vertex.www + tmp3.xyz;
                o.texcoord3.xyz = tmp3.xyz;
                o.texcoord7.xyz = tmp3.xyz;
                tmp3.xyz = tmp2.zwy * v.tangent.zxy;
                tmp2.xyz = v.tangent.yzx * tmp2.wyz + -tmp3.xyz;
                tmp2.w = dot(tmp2.xyz, tmp2.xyz);
                tmp2.w = rsqrt(tmp2.w);
                tmp2.xyz = tmp2.www * tmp2.xyz;
                tmp3.xyz = _WorldSpaceCameraPos - v.vertex.xyz;
                tmp2.w = dot(tmp3.xyz, tmp3.xyz);
                tmp2.w = rsqrt(tmp2.w);
                tmp3.xyz = tmp2.www * tmp3.xyz;
                o.texcoord4.w = dot(tmp2.xyz, tmp3.xyz);
                o.texcoord4.z = dot(v.tangent.xyz, tmp3.xyz);
                o.texcoord4.xy = v.texcoord.xy;
                o.texcoord5 = float4(0.0, 1.0, 0.0, 0.0);
                o.texcoord6.xy = float2(0.0, 0.0);
                o.texcoord6.z = 1.0 - _EmissionUsePower;
                tmp2.xyz = tmp1.xwy * float3(0.5, 0.5, -0.5);
                o.texcoord8.zw = tmp1.zw;
                o.texcoord8.xy = tmp2.yy + tmp2.xz;
                tmp1.xyz = tmp0.yyy * unity_WorldToLight._m01_m11_m21;
                tmp1.xyz = unity_WorldToLight._m00_m10_m20 * tmp0.xxx + tmp1.xyz;
                tmp0.xyz = unity_WorldToLight._m02_m12_m22 * tmp0.zzz + tmp1.xyz;
                o.texcoord9.xyz = unity_WorldToLight._m03_m13_m23 * tmp0.www + tmp0.xyz;
                o.texcoord10 = float4(0.0, 0.0, 0.0, 0.0);
                return o;
            }
            // Keywords: POINT
            fout frag(v2f inp)
            {
                fout o;
                float4 tmp0;
                float4 tmp1;
                float4 tmp2;
                float4 tmp3;
                float4 tmp4;
                float4 tmp5;
                float4 tmp6;
                float4 tmp7;
                float4 tmp8;
                float4 tmp9;
                float4 tmp10;
                float4 tmp11;
                float4 tmp12;
                float4 tmp13;
                tmp0.x = inp.texcoord6.y > 0.95;
                tmp0.y = inp.texcoord6.y < 1.05;
                tmp0.x = tmp0.y ? tmp0.x : 0.0;
                if (tmp0.x) {
                    tmp0.xyz = _Color1.xyz;
                } else {
                    tmp0.w = inp.texcoord6.y > 1.95;
                    tmp1.x = inp.texcoord6.y < 2.05;
                    tmp0.w = tmp0.w ? tmp1.x : 0.0;
                    if (tmp0.w) {
                        tmp0.xyz = _Color2.xyz;
                    } else {
                        tmp0.w = inp.texcoord6.y > 2.95;
                        tmp1.x = inp.texcoord6.y < 3.05;
                        tmp0.w = tmp0.w ? tmp1.x : 0.0;
                        if (tmp0.w) {
                            tmp0.xyz = _Color3.xyz;
                        } else {
                            tmp0.w = inp.texcoord6.y > 3.95;
                            tmp1.x = inp.texcoord6.y < 4.05;
                            tmp0.w = tmp0.w ? tmp1.x : 0.0;
                            if (tmp0.w) {
                                tmp0.xyz = _Color4.xyz;
                            } else {
                                tmp0.w = inp.texcoord6.y > 4.95;
                                tmp1.x = inp.texcoord6.y < 5.05;
                                tmp0.w = tmp0.w ? tmp1.x : 0.0;
                                if (tmp0.w) {
                                    tmp0.xyz = _Color5.xyz;
                                } else {
                                    tmp0.w = inp.texcoord6.y > 5.95;
                                    tmp1.x = inp.texcoord6.y < 6.05;
                                    tmp0.w = tmp0.w ? tmp1.x : 0.0;
                                    if (tmp0.w) {
                                        tmp0.xyz = _Color6.xyz;
                                    } else {
                                        tmp0.w = inp.texcoord6.y > 8.95;
                                        tmp1.x = inp.texcoord6.y < 9.05;
                                        tmp0.w = tmp0.w ? tmp1.x : 0.0;
                                        if (tmp0.w) {
                                            tmp0.xyz = _Color9.xyz;
                                        } else {
                                            tmp1 = inp.texcoord6.yyyy > float4(9.95, 10.95, 11.95, 12.95);
                                            tmp2 = inp.texcoord6.yyyy < float4(10.05, 11.05, 12.05, 13.05);
                                            tmp1 = tmp1 ? tmp2 : 0.0;
                                            tmp0.w = inp.texcoord6.y > 13.95;
                                            tmp2.x = inp.texcoord6.y < 14.05;
                                            tmp0.w = tmp0.w ? tmp2.x : 0.0;
                                            tmp2.xyz = tmp0.www ? _Color14.xyz : _Color0.xyz;
                                            tmp2.xyz = tmp1.www ? _Color13.xyz : tmp2.xyz;
                                            tmp2.xyz = tmp1.zzz ? _Color12.xyz : tmp2.xyz;
                                            tmp1.yzw = tmp1.yyy ? _Color11.xyz : tmp2.xyz;
                                            tmp0.xyz = tmp1.xxx ? _Color10.xyz : tmp1.yzw;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                tmp1.xyz = tex2D(_MS_Tex, inp.texcoord4.xy);
                tmp0.w = _AlphaClip - 0.001;
                tmp0.w = tmp1.y < tmp0.w;
                if (tmp0.w) {
                    discard;
                }
                tmp2.xyz = tex2D(_MainTexA, inp.texcoord4.xy);
                tmp2.xyz = tmp0.xyz * tmp2.xyz;
                tmp3 = tex2D(_MainTexB, inp.texcoord4.xy);
                tmp1.yw = tex2D(_OcclusionTex, inp.texcoord4.xy);
                tmp2.xyz = tmp2.xyz * float3(6.0, 6.0, 6.0);
                tmp0.w = 1.0 - inp.texcoord5.w;
                tmp0.w = tmp0.w * tmp3.w;
                tmp3.xyz = tmp3.xyz * float3(1.7, 1.7, 1.7) + -tmp2.xyz;
                tmp2.xyz = tmp0.www * tmp3.xyz + tmp2.xyz;
                tmp0.w = tmp1.y - 1.0;
                tmp0.w = tmp1.w * tmp0.w + 1.0;
                tmp0.w = log(tmp0.w);
                tmp0.w = tmp0.w * _OcclusionPower;
                tmp0.w = exp(tmp0.w);
                tmp2.xyz = tmp0.www * tmp2.xyz;
                tmp3.x = tmp3.z * tmp3.x;
                tmp1.yw = tmp3.xy * float2(2.0, 2.0) + float2(-1.0, -1.0);
                tmp0.w = dot(tmp1.xy, tmp1.xy);
                tmp0.w = min(tmp0.w, 1.0);
                tmp0.w = 1.0 - tmp0.w;
                tmp3.z = sqrt(tmp0.w);
                tmp3.xy = tmp1.yw * _NormalMultiplier.xx;
                tmp0.w = dot(inp.texcoord7.xyz, inp.texcoord7.xyz);
                tmp1.y = rsqrt(tmp0.w);
                tmp4.xyz = tmp1.yyy * inp.texcoord7.xyz;
                tmp1.yw = texCUBE(_Global_LocalPlanetHeightmap, tmp4.xyz);
                tmp2.w = frac(tmp1.w);
                tmp1.w = tmp1.w - tmp2.w;
                tmp3.w = 3.0 - tmp2.w;
                tmp3.w = tmp3.w - tmp2.w;
                tmp2.w = tmp2.w * tmp2.w;
                tmp1.w = tmp2.w * tmp3.w + tmp1.w;
                tmp4.xy = saturate(float2(1.0, 2.0) - tmp1.ww);
                tmp2.w = saturate(tmp1.w);
                tmp2.w = min(tmp2.w, tmp4.y);
                tmp1.w = saturate(tmp1.w - 1.0);
                tmp5 = tmp2.wwww * _Global_Biomo_Color1;
                tmp4 = _Global_Biomo_Color0 * tmp4.xxxx + tmp5;
                tmp4 = _Global_Biomo_Color2 * tmp1.wwww + tmp4;
                tmp4.xyz = tmp4.xyz * _BiomoMultiplier.xxx;
                tmp1.y = tmp1.y + _Global_Planet_Radius;
                tmp0.w = sqrt(tmp0.w);
                tmp0.w = tmp0.w - tmp1.y;
                tmp0.w = _BiomoHeight - tmp0.w;
                tmp0.w = saturate(tmp0.w / _BiomoHeight);
                tmp0.w = tmp0.w * tmp0.w;
                tmp1.y = tmp4.w * tmp0.w;
                tmp5.xyz = tmp2.xyz * _AlbedoMultiplier.xxx;
                tmp6.xyz = tmp4.xyz * tmp5.xyz + -tmp4.xyz;
                tmp4.xyz = _Biomo.xxx * tmp6.xyz + tmp4.xyz;
                tmp1.w = _ScreenTex_TexelSize.z / _ScreenTex_TexelSize.w;
                tmp6.xy = -inp.texcoord4.wz;
                tmp6.z = tmp1.w * tmp6.x;
                tmp6.xw = inp.texcoord8.xy / inp.texcoord8.ww;
                tmp6.yz = tmp6.yz * _CrystalRefrac.xx;
                tmp6.yz = tmp6.yz / inp.texcoord8.ww;
                tmp6.xy = tmp6.yz + tmp6.xw;
                tmp6.xy = tmp6.xy * inp.texcoord8.ww;
                tmp6.xy = tmp6.xy / inp.texcoord8.ww;
                tmp6.xyz = tex2D(_ScreenTex, tmp6.xy);
                tmp2.xyz = -tmp2.xyz * _AlbedoMultiplier.xxx + tmp4.xyz;
                tmp2.xyz = tmp1.yyy * tmp2.xyz + tmp5.xyz;
                tmp4.xyz = tmp6.xyz * _Crystal.xxx;
                tmp1.yw = saturate(inp.texcoord4.zw - float2(0.3, 0.3));
                tmp1.yw = tmp1.yw * float2(4.0, 4.0);
                tmp1.y = dot(tmp1.xy, tmp1.xy);
                tmp1.y = sqrt(tmp1.y);
                tmp1.y = saturate(3.0 - tmp1.y);
                tmp4.xyz = tmp1.yyy * tmp4.xyz;
                tmp0.w = -tmp0.w * tmp4.w + 1.0;
                tmp2.xyz = tmp4.xyz * tmp0.www + tmp2.xyz;
                tmp0.w = dot(tmp3.xyz, tmp3.xyz);
                tmp0.w = rsqrt(tmp0.w);
                tmp3.xyz = tmp0.www * tmp3.xyz;
                tmp1.xy = saturate(tmp1.xz * float2(_MetallicMultiplier.x, _SmoothMultiplier.x));
                tmp4.xyz = _WorldSpaceLightPos0.xyz - inp.texcoord3.xyz;
                tmp0.w = dot(tmp4.xyz, tmp4.xyz);
                tmp0.w = rsqrt(tmp0.w);
                tmp5.xyz = tmp0.www * tmp4.xyz;
                tmp6.xyz = _WorldSpaceCameraPos - inp.texcoord3.xyz;
                tmp1.z = dot(tmp6.xyz, tmp6.xyz);
                tmp1.z = rsqrt(tmp1.z);
                tmp6.xyz = tmp1.zzz * tmp6.xyz;
                tmp7.xyz = inp.texcoord3.yyy * unity_WorldToLight._m01_m11_m21;
                tmp7.xyz = unity_WorldToLight._m00_m10_m20 * inp.texcoord3.xxx + tmp7.xyz;
                tmp7.xyz = unity_WorldToLight._m02_m12_m22 * inp.texcoord3.zzz + tmp7.xyz;
                tmp7.xyz = tmp7.xyz + unity_WorldToLight._m03_m13_m23;
                tmp1.z = unity_ProbeVolumeParams.x == 1.0;
                if (tmp1.z) {
                    tmp1.z = unity_ProbeVolumeParams.y == 1.0;
                    tmp8.xyz = inp.texcoord3.yyy * unity_ProbeVolumeWorldToObject._m01_m11_m21;
                    tmp8.xyz = unity_ProbeVolumeWorldToObject._m00_m10_m20 * inp.texcoord3.xxx + tmp8.xyz;
                    tmp8.xyz = unity_ProbeVolumeWorldToObject._m02_m12_m22 * inp.texcoord3.zzz + tmp8.xyz;
                    tmp8.xyz = tmp8.xyz + unity_ProbeVolumeWorldToObject._m03_m13_m23;
                    tmp8.xyz = tmp1.zzz ? tmp8.xyz : inp.texcoord3.xyz;
                    tmp8.xyz = tmp8.xyz - unity_ProbeVolumeMin;
                    tmp8.yzw = tmp8.xyz * unity_ProbeVolumeSizeInv;
                    tmp1.z = tmp8.y * 0.25 + 0.75;
                    tmp1.w = unity_ProbeVolumeParams.z * 0.5 + 0.75;
                    tmp8.x = max(tmp1.w, tmp1.z);
                    tmp8 = UNITY_SAMPLE_TEX3D_SAMPLER(unity_ProbeVolumeSH, unity_ProbeVolumeSH, tmp8.xzw);
                } else {
                    tmp8 = float4(1.0, 1.0, 1.0, 1.0);
                }
                tmp1.z = saturate(dot(tmp8, unity_OcclusionMaskSelector));
                tmp1.w = dot(tmp7.xyz, tmp7.xyz);
                tmp1.w = tex2D(_LightTexture0, tmp1.ww);
                tmp2.w = tmp1.z * tmp1.w;
                tmp7.x = dot(inp.texcoord.xyz, tmp3.xyz);
                tmp7.y = dot(inp.texcoord1.xyz, tmp3.xyz);
                tmp7.z = dot(inp.texcoord2.xyz, tmp3.xyz);
                tmp3.x = dot(tmp7.xyz, tmp7.xyz);
                tmp3.x = rsqrt(tmp3.x);
                tmp3.xyz = tmp3.xxx * tmp7.xyz;
                tmp7.xy = tmp1.xx * float2(0.85, 0.85) + float2(0.649, 0.149);
                tmp1.x = -tmp1.y * 0.97 + 1.0;
                tmp4.xyz = tmp4.xyz * tmp0.www + tmp6.xyz;
                tmp0.w = dot(tmp4.xyz, tmp4.xyz);
                tmp0.w = rsqrt(tmp0.w);
                tmp4.xyz = tmp0.www * tmp4.xyz;
                tmp0.w = tmp1.x * tmp1.x;
                tmp1.y = tmp0.w * tmp0.w;
                tmp3.w = dot(tmp3.xyz, tmp5.xyz);
                tmp4.w = max(tmp3.w, 0.0);
                tmp5.w = dot(tmp3.xyz, tmp6.xyz);
                tmp5.w = max(tmp5.w, 0.0);
                tmp6.w = dot(tmp3.xyz, tmp4.xyz);
                tmp6.w = max(tmp6.w, 0.0);
                tmp4.x = dot(tmp6.xyz, tmp4.xyz);
                tmp4.x = max(tmp4.x, 0.0);
                tmp3.w = tmp3.w * 0.35 + 1.0;
                tmp4.y = tmp3.w * tmp3.w;
                tmp3.w = tmp3.w * tmp4.y;
                tmp4.y = dot(inp.texcoord5.xyz, tmp5.xyz);
                tmp4.z = dot(tmp3.xyz, inp.texcoord5.xyz);
                tmp7.z = dot(inp.texcoord5.xyz, inp.texcoord5.xyz);
                tmp7.w = inp.texcoord5.y < 0.9999;
                tmp7.z = tmp7.z > 0.01;
                tmp7.w = tmp7.z ? tmp7.w : 0.0;
                tmp8.xyz = inp.texcoord5.yzx * float3(0.0, 1.0, 0.0);
                tmp8.xyz = inp.texcoord5.xyz * float3(1.0, 0.0, 0.0) + -tmp8.xyz;
                tmp8.w = dot(tmp8.xy, tmp8.xy);
                tmp8.w = rsqrt(tmp8.w);
                tmp8.xyz = tmp8.www * tmp8.xyz;
                tmp8.xyz = tmp7.www ? tmp8.xyz : float3(0.0, 1.0, 0.0);
                tmp7.w = dot(tmp8.xy, tmp8.xy);
                tmp7.w = tmp7.w > 0.01;
                tmp7.z = tmp7.w ? tmp7.z : 0.0;
                tmp9.xyz = tmp8.xyz * inp.texcoord5.yzx;
                tmp9.xyz = tmp8.zxy * inp.texcoord5.zxy + -tmp9.xyz;
                tmp7.w = dot(tmp9.xyz, tmp9.xyz);
                tmp7.w = rsqrt(tmp7.w);
                tmp9.xyz = tmp7.www * tmp9.xyz;
                tmp7.w = dot(-tmp6.xyz, tmp3.xyz);
                tmp7.w = tmp7.w + tmp7.w;
                tmp6.xyz = tmp3.xyz * -tmp7.www + -tmp6.xyz;
                tmp8.x = dot(tmp6.xy, -tmp8.xy);
                tmp8.y = dot(tmp6.xyz, inp.texcoord5.xyz);
                tmp9.xyz = tmp7.zzz ? -tmp9.xyz : float3(-0.0, -0.0, -1.0);
                tmp8.z = dot(tmp6.xyz, tmp9.xyz);
                tmp6.x = log(tmp1.x);
                tmp6.x = tmp6.x * 0.4;
                tmp6.x = exp(tmp6.x);
                tmp6.x = tmp6.x * 10.0;
                tmp6.xyz = texCUBElod(_Global_PGI, float4(tmp8.xyz, tmp6.x));
                tmp7.z = tmp7.y * 0.7 + 0.3;
                tmp1.x = 1.0 - tmp1.x;
                tmp1.x = tmp1.x * tmp7.z;
                tmp6.xyz = tmp1.xxx * tmp6.xyz;
                tmp7.z = tmp4.y <= 1.0;
                if (tmp7.z) {
                    tmp8 = tmp4.yyyy + float4(-0.2, -0.1, 0.1, 0.3);
                    tmp8 = saturate(tmp8 * float4(5.0, 10.0, 5.0, 5.0));
                    tmp9.xyz = float3(1.0, 1.0, 1.0) - _Global_SunsetColor0.xyz;
                    tmp9.xyz = tmp8.xxx * tmp9.xyz + _Global_SunsetColor0.xyz;
                    tmp10.xyz = _Global_SunsetColor1.xyz * float3(1.25, 1.25, 1.25);
                    tmp11.xyz = -_Global_SunsetColor1.xyz * float3(1.25, 1.25, 1.25) + _Global_SunsetColor0.xyz;
                    tmp10.xyz = tmp8.yyy * tmp11.xyz + tmp10.xyz;
                    tmp11.xyz = tmp4.yyy > float3(0.2, 0.1, -0.1);
                    tmp12.xyz = _Global_SunsetColor2.xyz * float3(1.5, 1.5, 1.5);
                    tmp13.xyz = _Global_SunsetColor1.xyz * float3(1.25, 1.25, 1.25) + -tmp12.xyz;
                    tmp8.xyz = tmp8.zzz * tmp13.xyz + tmp12.xyz;
                    tmp12.xyz = tmp8.www * tmp12.xyz;
                    tmp8.xyz = tmp11.zzz ? tmp8.xyz : tmp12.xyz;
                    tmp8.xyz = tmp11.yyy ? tmp10.xyz : tmp8.xyz;
                    tmp8.xyz = tmp11.xxx ? tmp9.xyz : tmp8.xyz;
                } else {
                    tmp8.xyz = float3(1.0, 1.0, 1.0);
                }
                tmp8.xyz = tmp8.xyz * _LightColor0.xyz;
                tmp7.zw = tmp4.yy * float2(0.15, 3.0);
                tmp7.zw = saturate(tmp7.zw);
                tmp1.z = -tmp1.w * tmp1.z + 1.0;
                tmp1.z = tmp7.z * tmp1.z + tmp2.w;
                tmp1.z = tmp1.z * 0.8;
                tmp8.xyz = tmp8.xyz * tmp1.zzz;
                tmp1.z = tmp6.w * tmp6.w;
                tmp9.xy = tmp0.ww * tmp0.ww + float2(-1.0, 1.0);
                tmp0.w = tmp1.z * tmp9.x + 1.0;
                tmp0.w = rcp(tmp0.w);
                tmp0.w = tmp0.w * tmp0.w;
                tmp0.w = tmp1.y * tmp0.w;
                tmp0.w = tmp0.w * 0.25;
                tmp1.y = tmp9.y * tmp9.y;
                tmp1.z = tmp1.y * 0.125;
                tmp1.y = -tmp1.y * 0.125 + 1.0;
                tmp1.w = tmp5.w * tmp1.y + tmp1.z;
                tmp1.y = tmp4.w * tmp1.y + tmp1.z;
                tmp9.xy = float2(1.0, 1.0) - tmp7.xy;
                tmp1.z = tmp4.x * -5.55473 + -6.98316;
                tmp1.z = tmp4.x * tmp1.z;
                tmp1.z = exp(tmp1.z);
                tmp1.z = tmp9.x * tmp1.z + tmp7.x;
                tmp0.w = tmp0.w * tmp1.z;
                tmp1.y = tmp1.y * tmp1.w;
                tmp1.y = rcp(tmp1.y);
                tmp1.z = tmp4.y > 0.0;
                tmp9.xzw = _Global_AmbientColor0.xyz - _Global_AmbientColor1.xyz;
                tmp7.xzw = tmp7.www * tmp9.xzw + _Global_AmbientColor1.xyz;
                tmp1.w = saturate(tmp4.y * 3.0 + 1.0);
                tmp9.xzw = _Global_AmbientColor1.xyz - _Global_AmbientColor2.xyz;
                tmp9.xzw = tmp1.www * tmp9.xzw + _Global_AmbientColor2.xyz;
                tmp7.xzw = tmp1.zzz ? tmp7.xzw : tmp9.xzw;
                tmp1.z = saturate(tmp4.z * 0.3 + 0.7);
                tmp9.xzw = tmp1.zzz * tmp7.xzw;
                tmp9.xzw = tmp3.www * tmp9.xzw;
                tmp1.z = _AmbientInc + 1.0;
                tmp9.xzw = tmp1.zzz * tmp9.xzw;
                tmp1.z = _Global_PointLightPos.w >= 0.5;
                tmp1.w = dot(_Global_PointLightPos.xyz, _Global_PointLightPos.xyz);
                tmp1.w = sqrt(tmp1.w);
                tmp1.w = tmp1.w - 5.0;
                tmp2.w = saturate(tmp1.w);
                tmp3.w = dot(-inp.texcoord5.xyz, tmp5.xyz);
                tmp3.w = saturate(tmp3.w * 5.0);
                tmp2.w = tmp2.w * tmp3.w;
                tmp5.xyz = -inp.texcoord5.xyz * tmp1.www + _Global_PointLightPos.xyz;
                tmp1.w = dot(tmp5.xyz, tmp5.xyz);
                tmp1.w = sqrt(tmp1.w);
                tmp3.w = 20.0 - tmp1.w;
                tmp3.w = tmp3.w * 0.05;
                tmp3.w = max(tmp3.w, 0.0);
                tmp3.w = tmp3.w * tmp3.w;
                tmp4.x = tmp1.w < 0.001;
                tmp10.xyz = tmp2.www * float3(1.3, 1.1, 0.6);
                tmp5.xyz = tmp5.xyz / tmp1.www;
                tmp1.w = saturate(dot(tmp5.xyz, tmp3.xyz));
                tmp1.w = tmp3.w * tmp1.w;
                tmp1.w = tmp2.w * tmp1.w;
                tmp3.xyz = tmp1.www * float3(1.3, 1.1, 0.6);
                tmp3.xyz = tmp4.xxx ? tmp10.xyz : tmp3.xyz;
                tmp3.xyz = tmp1.zzz ? tmp3.xyz : 0.0;
                tmp3.xyz = tmp4.www * tmp8.xyz + tmp3.xyz;
                tmp3.xyz = tmp2.xyz * tmp3.xyz;
                tmp1.z = log(tmp9.y);
                tmp1.z = tmp1.z * 0.6;
                tmp1.z = exp(tmp1.z);
                tmp5.xyz = tmp2.xyz - float3(1.0, 1.0, 1.0);
                tmp5.xyz = tmp7.yyy * tmp5.xyz + float3(1.0, 1.0, 1.0);
                tmp5.xyz = tmp5.xyz * _SpecularColor.xyz;
                tmp5.xyz = tmp8.xyz * tmp5.xyz;
                tmp0.w = tmp0.w * tmp1.y + 0.031831;
                tmp5.xyz = tmp0.www * tmp5.xyz;
                tmp4.xzw = tmp4.www * tmp5.xyz;
                tmp0.w = tmp9.y * 0.2;
                tmp5.xyz = tmp0.www * tmp2.xyz + tmp7.yyy;
                tmp4.xzw = tmp4.xzw * tmp5.xyz;
                tmp5.xyz = tmp2.xyz * tmp9.xzw;
                tmp0.w = -tmp7.y * 0.6 + 1.0;
                tmp8.xyz = tmp0.www * tmp5.xyz;
                tmp1.y = dot(tmp8.xyz, float3(0.3, 0.6, 0.1));
                tmp5.xyz = -tmp5.xyz * tmp0.www + tmp1.yyy;
                tmp5.xyz = tmp5.xyz * float3(0.5, 0.5, 0.5) + tmp8.xyz;
                tmp0.w = dot(tmp7.xyz, float3(0.3, 0.6, 0.1));
                tmp0.w = tmp0.w + 0.003;
                tmp1.y = max(_Global_AmbientColor0.y, _Global_AmbientColor0.x);
                tmp1.y = max(tmp1.y, _Global_AmbientColor0.z);
                tmp1.y = tmp1.y + 0.003;
                tmp1.y = 1.0 / tmp1.y;
                tmp7.xyz = tmp7.xzw - tmp0.www;
                tmp7.xyz = tmp7.xyz * float3(0.4, 0.4, 0.4) + tmp0.www;
                tmp7.xyz = tmp1.yyy * tmp7.xyz;
                tmp7.xyz = tmp7.xyz * float3(1.7, 1.7, 1.7);
                tmp6.xyz = tmp6.xyz * tmp7.xyz;
                tmp0.w = saturate(tmp4.y * 2.0 + 0.5);
                tmp0.w = tmp0.w * 0.7 + 0.3;
                tmp7.xyz = tmp0.www * tmp6.xyz;
                tmp1.y = dot(tmp7.xyz, float3(0.3, 0.6, 0.1));
                tmp6.xyz = -tmp6.xyz * tmp0.www + tmp1.yyy;
                tmp6.xyz = tmp6.xyz * float3(0.8, 0.8, 0.8) + tmp7.xyz;
                tmp0.xyz = tmp0.xyz - float3(1.0, 1.0, 1.0);
                tmp0.xyz = tmp0.xyz * float3(0.8, 0.8, 0.8) + float3(1.0, 1.0, 1.0);
                tmp0.xyz = tmp0.xyz * tmp6.xyz;
                tmp1.yzw = tmp3.xyz * tmp1.zzz + tmp4.xzw;
                tmp1.yzw = tmp5.xyz + tmp1.yzw;
                tmp0.xyz = tmp0.xyz * tmp2.xyz + -tmp1.yzw;
                tmp0.xyz = tmp1.xxx * tmp0.xyz + tmp1.yzw;
                tmp0.w = dot(tmp0.xyz, float3(0.3, 0.6, 0.1));
                tmp1.x = tmp0.w > 1.0;
                tmp1.yzw = tmp0.xyz / tmp0.www;
                tmp0.w = log(tmp0.w);
                tmp0.w = tmp0.w * 0.6931472 + 1.0;
                tmp0.w = log(tmp0.w);
                tmp0.w = tmp0.w * 0.6931472 + 1.0;
                tmp1.yzw = tmp0.www * tmp1.yzw;
                o.sv_target.xyz = tmp1.xxx ? tmp1.yzw : tmp0.xyz;
                o.sv_target.w = 1.0;
                return o;
            }
            ENDCG
        }
        Pass {
            Name "ShadowCaster"
            LOD 200
            Tags { "DisableBatching" = "true" "LIGHTMODE" = "SHADOWCASTER" "RenderType" = "Opaque" "SHADOWSUPPORT" = "true" }
            Cull Off
            GpuProgramID 135263
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "UnityCG.cginc"
            struct v2f
            {
                float4 position : SV_POSITION0;
                float4 texcoord1 : TEXCOORD1;
                float4 texcoord2 : TEXCOORD2;
                float3 texcoord3 : TEXCOORD3;
                float3 texcoord4 : TEXCOORD4;
                float4 texcoord5 : TEXCOORD5;
            };
            struct fout
            {
                float4 sv_target : SV_Target0;
            };
            // $Globals ConstantBuffers for Vertex Shader
            float _EmissionUsePower;
            // $Globals ConstantBuffers for Fragment Shader
            float _AlphaClip;
            // Custom ConstantBuffers for Vertex Shader
            // Custom ConstantBuffers for Fragment Shader
            // Texture params for Vertex Shader
            // Texture params for Fragment Shader
            sampler2D _MS_Tex;
            
            // Keywords: SHADOWS_DEPTH
            v2f vert(appdata_full v)
            {
                v2f o;
                float4 tmp0;
                float4 tmp1;
                float4 tmp2;
                float4 tmp3;
                float4 tmp4;
                tmp0.x = dot(v.normal.xyz, v.normal.xyz);
                tmp0.x = rsqrt(tmp0.x);
                tmp0.xyz = tmp0.xxx * v.normal.xyz;
                tmp1.x = dot(tmp0.xyz, unity_WorldToObject._m00_m10_m20);
                tmp1.y = dot(tmp0.xyz, unity_WorldToObject._m01_m11_m21);
                tmp1.z = dot(tmp0.xyz, unity_WorldToObject._m02_m12_m22);
                tmp0.w = dot(tmp1.xyz, tmp1.xyz);
                tmp0.w = rsqrt(tmp0.w);
                tmp1.xyz = tmp0.www * tmp1.xyz;
                tmp2 = v.vertex.yyyy * unity_ObjectToWorld._m01_m11_m21_m31;
                tmp2 = unity_ObjectToWorld._m00_m10_m20_m30 * v.vertex.xxxx + tmp2;
                tmp2 = unity_ObjectToWorld._m02_m12_m22_m32 * v.vertex.zzzz + tmp2;
                tmp3 = unity_ObjectToWorld._m03_m13_m23_m33 * v.vertex.wwww + tmp2;
                tmp2 = tmp2 + unity_ObjectToWorld._m03_m13_m23_m33;
                tmp4.xyz = -tmp3.xyz * _WorldSpaceLightPos0.www + _WorldSpaceLightPos0.xyz;
                tmp0.w = dot(tmp4.xyz, tmp4.xyz);
                tmp0.w = rsqrt(tmp0.w);
                tmp4.xyz = tmp0.www * tmp4.xyz;
                tmp0.w = dot(tmp1.xyz, tmp4.xyz);
                tmp0.w = -tmp0.w * tmp0.w + 1.0;
                tmp0.w = sqrt(tmp0.w);
                tmp0.w = tmp0.w * unity_LightShadowBias.z;
                tmp1.xyz = -tmp1.xyz * tmp0.www + tmp3.xyz;
                tmp0.w = unity_LightShadowBias.z != 0.0;
                tmp1.xyz = tmp0.www ? tmp1.xyz : tmp3.xyz;
                tmp4 = tmp1.yyyy * unity_MatrixVP._m01_m11_m21_m31;
                tmp4 = unity_MatrixVP._m00_m10_m20_m30 * tmp1.xxxx + tmp4;
                tmp1 = unity_MatrixVP._m02_m12_m22_m32 * tmp1.zzzz + tmp4;
                tmp1 = unity_MatrixVP._m03_m13_m23_m33 * tmp3.wwww + tmp1;
                tmp0.w = unity_LightShadowBias.x / tmp1.w;
                tmp0.w = min(tmp0.w, 0.0);
                tmp0.w = max(tmp0.w, -1.0);
                tmp0.w = tmp0.w + tmp1.z;
                tmp1.z = min(tmp1.w, tmp0.w);
                o.position.xyw = tmp1.xyw;
                tmp1.x = tmp1.z - tmp0.w;
                o.position.z = unity_LightShadowBias.y * tmp1.x + tmp0.w;
                tmp1.xyz = tmp0.yzx * v.tangent.zxy;
                tmp0.xyz = v.tangent.yzx * tmp0.zxy + -tmp1.xyz;
                tmp0.w = dot(tmp0.xyz, tmp0.xyz);
                tmp0.w = rsqrt(tmp0.w);
                tmp0.xyz = tmp0.www * tmp0.xyz;
                tmp1.xyz = _WorldSpaceCameraPos - v.vertex.xyz;
                tmp0.w = dot(tmp1.xyz, tmp1.xyz);
                tmp0.w = rsqrt(tmp0.w);
                tmp1.xyz = tmp0.www * tmp1.xyz;
                o.texcoord1.w = dot(tmp0.xyz, tmp1.xyz);
                o.texcoord1.z = dot(v.tangent.xyz, tmp1.xyz);
                o.texcoord1.xy = v.texcoord.xy;
                o.texcoord2 = float4(0.0, 1.0, 0.0, 0.0);
                o.texcoord3.xy = float2(0.0, 0.0);
                o.texcoord3.z = 1.0 - _EmissionUsePower;
                tmp0.xyz = v.vertex.yyy * unity_ObjectToWorld._m01_m11_m21;
                tmp0.xyz = unity_ObjectToWorld._m00_m10_m20 * v.vertex.xxx + tmp0.xyz;
                tmp0.xyz = unity_ObjectToWorld._m02_m12_m22 * v.vertex.zzz + tmp0.xyz;
                o.texcoord4.xyz = unity_ObjectToWorld._m03_m13_m23 * v.vertex.www + tmp0.xyz;
                tmp0 = tmp2.yyyy * unity_MatrixVP._m01_m11_m21_m31;
                tmp0 = unity_MatrixVP._m00_m10_m20_m30 * tmp2.xxxx + tmp0;
                tmp0 = unity_MatrixVP._m02_m12_m22_m32 * tmp2.zzzz + tmp0;
                tmp0 = unity_MatrixVP._m03_m13_m23_m33 * tmp2.wwww + tmp0;
                o.texcoord5.zw = tmp0.zw;
                tmp0.xyz = tmp0.xwy * float3(0.5, 0.5, -0.5);
                o.texcoord5.xy = tmp0.yy + tmp0.xz;
                return o;
            }
            // Keywords: SHADOWS_DEPTH
            fout frag(v2f inp)
            {
                fout o;
                float4 tmp0;
                tmp0.x = tex2D(_MS_Tex, inp.texcoord1.xy);
                tmp0.y = _AlphaClip - 0.001;
                tmp0.x = tmp0.x < tmp0.y;
                if (tmp0.x) {
                    discard;
                }
                o.sv_target = float4(0.0, 0.0, 0.0, 0.0);
                return o;
            }
            ENDCG
        }
    }
    Fallback "Diffuse"
}