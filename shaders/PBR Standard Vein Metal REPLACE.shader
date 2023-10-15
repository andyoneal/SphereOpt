Shader "VF Shaders/Forward/PBR Standard Vein Metal REPLACE" {
    Properties {
        _Color0 ("Color 颜色 ID=0", Color) = (1,1,1,1)
        _Color1 ("Color 颜色 ID=1", Color) = (1,1,1,1)
        _Color2 ("Color 颜色 ID=2", Color) = (1,1,1,1)
        _Color3 ("Color 颜色 ID=3", Color) = (1,1,1,1)
        _Color4 ("Color 颜色 ID=4", Color) = (1,1,1,1)
        _Color5 ("Color 颜色 ID=5", Color) = (1,1,1,1)
        _Color6 ("Color 颜色 ID=6", Color) = (1,1,1,1)
        _Color9 ("Color 颜色 ID=9", Color) = (1,1,1,1)
        _Color10 ("Color 颜色 ID=10", Color) = (1,1,1,1)
        _Color11 ("Color 颜色 ID=11", Color) = (1,1,1,1)
        _Color12 ("Color 颜色 ID=12", Color) = (1,1,1,1)
        _Color13 ("Color 颜色 ID=13", Color) = (1,1,1,1)
        _Color14 ("Color 颜色 ID=14", Color) = (1,1,1,1)
        _SpecularColor ("Specular Color", Color) = (1,1,1,1)
        _EmissionMask ("自发光正片叠底色 Emmission Background Color", Color) = (1,1,1,1)
        _MainTexA ("Albedo (RGB) 漫反射 铺底 Diffuse Reflection", 2D) = "white" {}
        _MainTexB ("Albedo (RGB) 漫反射 颜色 Diffuse Color", 2D) = "white" {}
        _OcclusionTex ("环境光遮蔽 Ambient Occlusion", 2D) = "white" {}
        _NormalTex ("Normal 法线", 2D) = "bump" {}
        _MS_Tex ("Metallic (R) 透贴 Transparent (G) 金属 Metal (A) 高光 Highlight", 2D) = "black" {}
        _EmissionTex ("Emission (RGB) 自发光  (A) 抖动遮罩 (Dither Mask)", 2D) = "black" {}
        _AmbientInc ("环境光提升 Ambient Light Boost", Float) = 0
        _AlbedoMultiplier ("漫反射倍率 Diffuse Reflection Mult", Float) = 1
        _OcclusionPower ("环境光遮蔽指数 Ambient Light Occlusion Index", Float) = 1
        _NormalMultiplier ("法线倍率 Normal Multiplier", Float) = 1
        _MetallicMultiplier ("金属倍率 Metallic Multiplier", Float) = 1
        _SmoothMultiplier ("高光倍率 Highlight Multiplier", Float) = 1
        _EmissionMultiplier ("自发光倍率 Emission Multiplier", Float) = 5.5
        _EmissionJitter ("自发光抖动倍率 Emission Jitter Ratio", Float) = 0
        _EmissionSwitch ("是否使用游戏状态决定自发光 Emission based on Switch", Float) = 0
        _EmissionUsePower ("是否使用供电数据决定自发光 Emission based on Power", Float) = 1
        _EmissionJitterTex ("自发光抖动色条 Emission Dither Color Bar", 2D) = "white" {}
        _AlphaClip ("透明通道剪切 Transparent Channel Clipping", Float) = 0
        _CullMode ("剔除模式 Cull Mode", Float) = 2
        _Biomo ("Biomo 融合因子 Blend Factor", Float) = 0.3
        _BiomoMultiplier ("Biomo 颜色乘数 Color Multiplier", Float) = 1
        _BiomoHeight ("Biomo 融合高度 Blend Height", Float) = 1.1
        [Toggle(_ENABLE_VFINST)] _ToggleVerta ("Enable VFInst ? (Always On)", Float) = 0
    }
    SubShader {
        LOD 200
        Tags { "DisableBatching" = "true" "RenderType" = "Opaque" }
        Pass {
            Name "FORWARD"
            LOD 200
            Tags { "DisableBatching" = "true" "LIGHTMODE" = "FORWARDBASE" "RenderType" = "Opaque" "SHADOWSUPPORT" = "true" }
            Cull [_CullMode]
            GpuProgramID 48911
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 5.0
            #pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight
            #pragma enable_d3d11_debug_symbols
            
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            
            struct v2f
            {
                float4 pos : SV_POSITION0;
                float4 TBN0 : TEXCOORD0;
                float4 TBN1 : TEXCOORD1;
                float4 TBN2 : TEXCOORD2;
                float3 uv_lodDist : TEXCOORD3;
                float3 upDir : TEXCOORD4;
                float3 time_state_emiss : TEXCOORD5;
                float3 worldPos : TEXCOORD6;
                float3 shadows : TEXCOORD7;
                UNITY_SHADOW_COORDS(9)
                float4 unk : TEXCOORD10;
            };
            struct fout
            {
                float4 sv_target : SV_Target0;
            };
            struct GPUOBJECT
            {
              uint objId;
              float3 pos;
              float4 rot;
            };
            
            struct AnimData
            {
              float time;
              float prepare_length;
              float working_length;
              uint state;
              float power;
            };
            
            StructuredBuffer<uint> _IdBuffer;
            StructuredBuffer<GPUOBJECT> _InstBuffer;
            StructuredBuffer<float> _VertaBuffer;
            StructuredBuffer<AnimData> _AnimBuffer;
            StructuredBuffer<float3> _ScaleBuffer;
            
            float4 _LightColor0;
            float4 unused0;
            int _VertexSize;
            uint _VertexCount;
            uint _FrameCount;
            float _UseScale;
            float4 unused1;
            float4 _Global_AmbientColor0;
            float4 _Global_AmbientColor1;
            float4 _Global_AmbientColor2;
            float4 unused2;
            float4 unused3;
            float4 unused4;
            float3 _Global_SunsetColor0;
            float3 _Global_SunsetColor1;
            float3 _Global_SunsetColor2;
            float4 unused5;
            float4 unused6;
            float4 unused7;
            float4 unused8;
            float4 unused9;
            float4 unused10;
            float4 _Global_Biomo_Color0;
            float4 _Global_Biomo_Color1;
            float4 _Global_Biomo_Color2;
            float _Global_Planet_Radius;
            float4 unused11;
            float4 unused12;
            float4 unused13;
            float unused14;
            float unused15;
            float unused16;
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
            float _EmissionUsePower;
            float _AlphaClip;
            float _Biomo;
            float _BiomoMultiplier;
            float _BiomoHeight;
            float4 _SpecularColor;
            
            sampler2D _MainTexA;
            sampler2D _MainTexB;
            sampler2D _OcclusionTex;
            UNITY_DECLARE_TEX2D(_MS_Tex);
            sampler2D _NormalTex;
            sampler2D _EmissionTex;
            UNITY_DECLARE_TEX2D(_EmissionJitterTex);
            UNITY_DECLARE_TEXCUBE(_Global_LocalPlanetHeightmap);
            UNITY_DECLARE_TEXCUBE(_Global_PGI);

            float3 rotate_vector_fast(float3 v, float4 r){ 
                return v + cross(2.0 * r.xyz, cross(r.xyz, v) + r.w * v);
            }
            
            v2f vert(appdata_full v, uint instanceID : SV_InstanceID, uint vertexID : SV_VertexID)
            {
                v2f o;
                float objIndex = _IdBuffer[instanceID]; //r0.x
                  
                //GPUOBJECT
                float objId = _InstBuffer[objIndex].objId; //r1.x
                float3 pos = _InstBuffer[objIndex].pos; //r1.yzw
                float4 rot = _InstBuffer[objIndex].rot; //r2.xyzw
                
                //animData
                float time = _AnimBuffer[objId].time; //r3.x
                float prepare_length = _AnimBuffer[objId].prepare_length; //r3.y
                float working_length = _AnimBuffer[objId].working_length; //r3.z
                uint state = _AnimBuffer[objId].state; //r3.w
                float power = _AnimBuffer[objId].power; //r0.y
                
                float prepareFrameCount = prepare_length > 0 ? _FrameCount - 1 : _FrameCount; //r0.w
                
                bool useScale = _UseScale > 0.5;
                
                float3 scale = _ScaleBuffer[objIndex]; //r4.xyz;
                
                float3 scaledVPos = useScale ? v.vertex.xyz * scale.xyz : v.vertex.xyz; //r5.xyz
                float3 scaledVNormal = useScale ? v.normal.xyz * scale.xyz : v.normal.xyz; //r4.xyz
                float3 scaledVTan = v.tangent.xyz; //r6
                  
                bool skipVerta = prepareFrameCount <= 0 || (_VertexSize != 9 && _VertexSize != 6 && _VertexSize != 3) || _VertexCount <= 0 || working_length <= 0; //r0.x
                if (!skipVerta) {
                  float prepareTime = time >= prepare_length && prepare_length > 0 ? 1.0 : 0; //r0.x
                  prepareTime = frac(time / (prepare_length + working_length)) * (prepareFrameCount - 1) + prepareTime;
                  prepareTime = prepareFrameCount - 1 <= 0 ? 0 : prepareTime; //r0.x
                  uint prepareTimeSec = (uint)prepareTime; //r0.z
                  float prepareTimeFrac = frac(prepareTime); //r0.x
                  int frameStride = _VertexSize * _VertexCount; //r0.w
                  int offset = vertexID * _VertexSize; //r1.x
                  uint frameIdx = mad(frameStride, prepareTimeSec, offset); //r3.y
                  uint nextFrameIdx = mad(frameStride, prepareTimeSec + 1, offset); //r0.z
                  
                  if (_VertexSize == 3) {
                    scaledVPos.x = lerp(_VertaBuffer[frameIdx], _VertaBuffer[nextFrameIdx], prepareTimeFrac);
                    scaledVPos.y = lerp(_VertaBuffer[frameIdx + 1], _VertaBuffer[nextFrameIdx + 1], prepareTimeFrac);
                    scaledVPos.z = lerp(_VertaBuffer[frameIdx + 2], _VertaBuffer[nextFrameIdx + 2], prepareTimeFrac);
                  } else {
                    if (_VertexSize == 6) {
                      scaledVPos.x = lerp(_VertaBuffer[frameIdx], _VertaBuffer[nextFrameIdx], prepareTimeFrac);
                      scaledVPos.y = lerp(_VertaBuffer[frameIdx + 1], _VertaBuffer[nextFrameIdx + 1], prepareTimeFrac);
                      scaledVPos.z = lerp(_VertaBuffer[frameIdx + 2], _VertaBuffer[nextFrameIdx + 2], prepareTimeFrac);
                      scaledVNormal.x = lerp(_VertaBuffer[frameIdx + 3], _VertaBuffer[nextFrameIdx + 3], prepareTimeFrac);
                      scaledVNormal.y = lerp(_VertaBuffer[frameIdx + 4], _VertaBuffer[nextFrameIdx + 4], prepareTimeFrac);
                      scaledVNormal.z = lerp(_VertaBuffer[frameIdx + 5], _VertaBuffer[nextFrameIdx + 5], prepareTimeFrac);
                    } else {
                      if (_VertexSize == 9) {
                        scaledVPos.x = lerp(_VertaBuffer[frameIdx], _VertaBuffer[nextFrameIdx], prepareTimeFrac);
                        scaledVPos.y = lerp(_VertaBuffer[frameIdx + 1], _VertaBuffer[nextFrameIdx + 1], prepareTimeFrac);
                        scaledVPos.z = lerp(_VertaBuffer[frameIdx + 2], _VertaBuffer[nextFrameIdx + 2], prepareTimeFrac);
                        scaledVNormal.x = lerp(_VertaBuffer[frameIdx + 3], _VertaBuffer[nextFrameIdx + 3], prepareTimeFrac);
                        scaledVNormal.y = lerp(_VertaBuffer[frameIdx + 4], _VertaBuffer[nextFrameIdx + 4], prepareTimeFrac);
                        scaledVNormal.z = lerp(_VertaBuffer[frameIdx + 5], _VertaBuffer[nextFrameIdx + 5], prepareTimeFrac);
                        scaledVTan.x = lerp(_VertaBuffer[frameIdx + 6], _VertaBuffer[nextFrameIdx + 6], prepareTimeFrac);
                        scaledVTan.y = lerp(_VertaBuffer[frameIdx + 7], _VertaBuffer[nextFrameIdx + 7], prepareTimeFrac);
                        scaledVTan.z = lerp(_VertaBuffer[frameIdx + 8], _VertaBuffer[nextFrameIdx + 8], prepareTimeFrac);
                      }
                    }
                  }
                }
                  
                float3 worldVPos = rotate_vector_fast(scaledVPos, rot) + pos.xyz; //r5.xyz
                float3 worldVNormal = rotate_vector_fast(scaledVNormal, rot); //r7.xyz
                float3 worldTangent = rotate_vector_fast(scaledVTan, rot); //r0.xyz
                
                float posHeight = length(pos); //r1.x
                float3 upDir = float3(0,1,0); //r2.xyz
                float lodDist = 0; //r1.x
                
                if (posHeight > 0.1) {
                  upDir.xyz = pos / posHeight; //r2.xyz
                  float g_heightMap = UNITY_SAMPLE_TEXCUBE_LOD(_Global_LocalPlanetHeightmap, normalize(worldVPos.xyz), 0).x;
                  float adjustHeight = (_Global_Planet_Radius + g_heightMap) - posHeight; //r1.x
                  worldVPos.xyz = adjustHeight * upDir.xyz + worldVPos.xyz; //r5
                  lodDist = saturate(0.01 * (distance(pos.xyz, _WorldSpaceCameraPos) - 180)); //r1.x
                }
                
                worldVPos.xyz = mul(unity_ObjectToWorld, float4(worldVPos,1)).xyz; //r4.xyz
                worldVNormal.xyz = lerp(normalize(worldVNormal), upDir.xyz, 0.2 * lodDist); //r6.xyz
                
                o.time_state_emiss.y = state;
                o.time_state_emiss.z = lerp(1, power, _EmissionUsePower);
                
                float4 clipPos = UnityObjectToClipPos(worldVPos);
                worldVNormal = UnityObjectToWorldNormal(worldVNormal.xyz); //r6.xyz
                worldTangent = float4(UnityObjectToWorldDir(worldTangent.xyz), v.tangent.w); //r0.xyz as yzx
                
                float sign = v.tangent.w * unity_WorldTransformParams.w; //r0.w
                float3 binormal = cross(worldVNormal.xyz, worldTangent.xyz) * sign; //r3.yzw
                
                o.shadows.xyz = ShadeSH9(float4(worldVNormal, 1.0));
                
                o.pos.xyzw = clipPos.xyzw;
                UNITY_TRANSFER_SHADOW(o, float(0,0))
                
                o.TBN0.x = worldTangent.x; //t.x
                o.TBN0.y = binormal.x; //b.x
                o.TBN0.z = worldVNormal.x; //n.x
                o.TBN0.w = worldVPos.x; //p.x
                o.TBN1.x = worldTangent.y; //t.y
                o.TBN1.y = binormal.y; //b.y
                o.TBN1.z = worldVNormal.y; //n.y
                o.TBN1.w = worldVPos.y; //p.y
                o.TBN2.x = worldTangent.z; //t.z
                o.TBN2.y = binormal.z; //b.z
                o.TBN2.z = worldVNormal.z; //n.z
                o.TBN2.w = worldVPos.z; //p.z
                o.unk.xyzw = float4(0,0,0,0);
                o.uv_lodDist.xy = v.texcoord.xy; //uv
                o.uv_lodDist.z = lodDist;
                o.upDir.xyz = upDir.xyz; //r2.xyz
                o.time_state_emiss.x = time;
                o.worldPos.xyz = worldVPos.xyz;
                return o;
            }
            // Keywords: DIRECTIONAL
            fout frag(v2f inp)
            {
                fout o;
                float2 uv = inp.uv_lodDist.xy;
                float lodDist = inp.uv_lodDist.z;
                float3 upDir = inp.upDir.xyz;
                float time = inp.time_state_emiss.x;
                float veinType = inp.time_state_emiss.y;
                float emissionPower = inp.time_state_emiss.z;
                float3 worldPos1 = inp.worldPos.xyz;
                float3 shadows = inp.shadows.xyz;
              
                // Choose color based on the veinType
                float3 veinColor = float3(0,0,0);
                if (veinType < 1.05 && 0.95 < veinType) { //iron
                  veinColor.xyz = _Color1.xyz;
                } else {
                  if (veinType < 2.05 && 1.95 < veinType) { //copper
                    veinColor.xyz = _Color2.xyz;
                  } else {
                    if (veinType < 3.05 && 2.95 < veinType) { //Silicon
                      veinColor.xyz = _Color3.xyz;
                    } else {
                      if (veinType < 4.05 && 3.95 < veinType) { //titanium
                        veinColor.xyz = _Color4.xyz;
                      } else {
                        if (veinType < 5.05 && 4.95 < veinType) { //stone
                          veinColor.xyz = _Color5.xyz;
                        } else {
                          if (veinType < 6.05 && 5.95 < veinType) { //coal
                            veinColor.xyz = _Color6.xyz;
                          } else {
                            if (veinType < 9.05 && 8.95 < veinType) { //diamond
                              veinColor.xyz = _Color9.xyz;
                            } else {
                              veinColor.xyz = veinType < 14.05 && 13.95 < veinType ? _Color14.xyz : _Color0.xyz; //mag, then none
                              veinColor.xyz = veinType < 13.05 && 12.95 < veinType ? _Color13.xyz : veinColor.xyz; //bamboo
                              veinColor.xyz = veinType < 12.05 && 11.95 < veinType ? _Color12.xyz : veinColor.xyz; //grat
                              veinColor.xyz = veinType < 11.05 && 10.95 < veinType ? _Color11.xyz : veinColor.xyz; //crysrub
                              veinColor.xyz = veinType < 10.05 && 9.95 < veinType ? _Color10.xyz : veinColor.xyz; //frac
                            }
                          }
                        }
                      }
                    }
                  }
                }
                  
                float3 mstex = UNITY_SAMPLE_TEX2D(_MS_Tex, uv).xyw; //r1.xyz
                
                if (mstex.y < _AlphaClip - 0.001) discard; //r1.y
                
                float3 colorA = veinColor.xyz * tex2D(_MainTexA, uv).xyz; //r0.xyz
                float4 mainTexB = tex2D(_MainTexB, uv); //r2.xyzw
                float2 occTex = tex2D(_OcclusionTex, uv).xw; //r1.yw
                float3 colorB = lerp(colorA.xyz * float3(6.0, 6.0, 6.0), mainTexB.xyz * float3(1.7, 1.7, 1.7), (1.0 - lodDist) * mainTexB.w); //r0.xyz
                float3 albedo = colorB * pow(lerp(1.0, occTex.x, occTex.y), _OcclusionPower); //r0.xyz
                
                float3 unpackedNormal = UnpackNormal(tex2Dbias(_NormalTex, float4(uv, 0, -1)));
                float3 normal;
                normal.xy = unpackedNormal.xy;
                normal.z = unpackedNormal.z;
                
                float4 emmTex = tex2Dbias(_EmissionTex, float4(uv,0,-1)); //r3.xyzw
                float emmJitTex = UNITY_SAMPLE_TEX2D(_EmissionJitterTex, float2(time, 0)).x; //r0.w
                
                float sat_Type = saturate(veinType); //r2.w
                
                float canEmit = (int)(emissionPower > 0.1) | (int)(_EmissionSwitch < 0.5) ? 1.0 : 0.0; //r4.x
                
                normal.xy = _NormalMultiplier * normal.xy;
                
                //Calculate how much of the planet's theme/biomo should be included
                float2 g_heightMap = UNITY_SAMPLE_TEXCUBE(_Global_LocalPlanetHeightmap, normalize(worldPos1.xyz)).xy; //r4.yz
                float frac_heightMap = frac(g_heightMap.y); //r1.w
                float int_heightMap = g_heightMap.y - frac_heightMap; //r4.z
                float biomoThreshold = (frac_heightMap * frac_heightMap) * (frac_heightMap * -2.0 + 3.0) + int_heightMap; //r1.w
                float biomoThreshold0 = saturate(1.0 - biomoThreshold);  //r4.z
                float biomoThreshold1 = min(saturate(2.0 - biomoThreshold), saturate(biomoThreshold)); //r4.w
                float biomoThreshold2 = saturate(biomoThreshold - 1); //r1.w
                float4 biomoColor = biomoThreshold1 * _Global_Biomo_Color1; //r5.xyzw
                biomoColor = _Global_Biomo_Color0 * biomoThreshold0 + biomoColor;
                biomoColor = _Global_Biomo_Color2 * biomoThreshold2 + biomoColor;
                biomoColor.xyz = biomoColor.xyz * _BiomoMultiplier;
                float heightOffset = saturate((_BiomoHeight - (length(worldPos1.xyz) - (g_heightMap.x + _Global_Planet_Radius))) / _BiomoHeight); //r1.y
                heightOffset = biomoColor.w * pow(heightOffset, 2);
                float3 multipliedAlbedo = albedo.xyz * _AlbedoMultiplier; //r4.yzw
                biomoColor = lerp(biomoColor.xyz, biomoColor.xyz * multipliedAlbedo, _Biomo);
                albedo.xyz = lerp(multipliedAlbedo, biomoColor, heightOffset);
                
                normal.xyz = normalize(normal.xyz);
                
                float metallic = saturate(_MetallicMultiplier * mstex.x); //r1.x
                float smoothness = saturate(_SmoothMultiplier * mstex.z); //r1.y =  //r1.z
                
                float3 emissionColor = _EmissionMultiplier * emmTex.xyz; //r3.xyz
                float2 emmSwitchJitter = float2(_EmissionSwitch, _EmissionJitter) * emmTex.ww; //r1.zw
                float emmIsOn = lerp(1, sat_Type, emmSwitchJitter.x); //r1.z
                emissionColor.xyz = emissionColor.xyz * emmIsOn; //r3.xyz
                float jitterRatio = _EmissionSwitch * emmSwitchJitter.y; //r1.z
                float jitter = lerp(1.0, emmJitTex, jitterRatio); //r0.w
                emissionColor.xyz = emissionColor.xyz * jitter; //r3.xyz
                emissionColor.xyz = emissionColor.xyz * canEmit; //r3.xyz
                
                float3 worldPos = float3(inp.TBN0.w, inp.TBN1.w, inp.TBN2.w); //r4.yzw
                UNITY_LIGHT_ATTENUATION(atten, inp, worldPos); //r1.z
                
                float3 posToCam = _WorldSpaceCameraPos.xyz - worldPos.xyz; //r5.xyz
                
                float3 viewDir = normalize(posToCam);//r6.xyz
                
                float3 worldNormal;
                worldNormal.x = dot(inp.TBN0.xyz, normal.xyz);
                worldNormal.y = dot(inp.TBN1.xyz, normal.xyz); //r4.xyz
                worldNormal.z = dot(inp.TBN2.xyz, normal.xyz);
                worldNormal = normalize(worldNormal.xyz); //r2.xyz
                
                float metallicLow = metallic * 0.85 + 0.149; //r1.w //scale metallic from 0.15 to 1.0
                float metallicHigh = metallic * 0.85 + 0.649; //r1.x //scale metallic from 0.65 to 1.5
                
                float perceptualRoughness = 1 - smoothness * 0.97; //r1.y
                
                float3 lightDir = _WorldSpaceLightPos0;
                float3 halfDir = normalize(viewDir + lightDir); //r4.xyz
                
                float roughness = perceptualRoughness * perceptualRoughness; //r0.w
                float roughnessSqr = roughness * roughness; //r2.w == "a2"
                
                float unclamped_nDotL = dot(worldNormal, lightDir); //r3.w
                float nDotL = max(0, unclamped_nDotL); //r4.w
                float unclamped_nDotV = dot(worldNormal, viewDir);
                float unclamped_nDotH = dot(worldNormal.xyz, halfDir);
                float nDotV = max(0, unclamped_nDotV); //r5.x
                float nDotH = max(0, unclamped_nDotH); //r5.y
                float unclamped_vDotH = dot(viewDir.xyz, halfDir);
                float vDotH = max(0, unclamped_vDotH); //r4.x
                float cubed_nDotL = pow(unclamped_nDotL * 0.35 + 1, 3); //r3.w
                
                /* upDotL: angle from the object to the sun.
                    1 = sun is directly above
                    0 = sun is directly perpendicular.
                   -1 = sun is on opposite side of the planet */
                float upDotL = dot(upDir.xyz, lightDir.xyz); //r4.y
                
                /* nDotL: angle from the normal to the upward direction from the object.
                    1 = surface faces directly up
                    0 = surface faces the side
                   -1 = surface faces down*/
                float nDotUp = dot(worldNormal.xyz, upDir.xyz); //r4.z
                
                float upDirMagSqr = dot(upDir.xyz, upDir.xyz); //r5.z
                float yNotOnYAxis = upDir.y < 0.9999; //r5.w
                float ylengthNotZero = upDirMagSqr > 0.01; //r5.z
                bool validUpDirY = ylengthNotZero && yNotOnYAxis; //r5.w
                
                float3 xaxis = cross(upDir.zxy, float3(0,0,1)); //r7.xyz
                xaxis = normalize(xaxis); //r7.xyz
                xaxis = validUpDirY ? xaxis : float3(0,1,0); //r7.xyz
                float xlengthNotZero = dot(xaxis, xaxis) > 0.01; //r5.w
                bool validUpDirXY = xlengthNotZero && ylengthNotZero; //r5.z
                
                float3 zaxis = cross(xaxis.yzx, upDir); //r8.xyz
                zaxis = normalize(zaxis); //r8.xyz
                
                float3 worldReflect = reflect(-viewDir, worldNormal); //r6.xyz
                
                float3 reflectDir; //r7.xyz
                reflectDir.x = dot(worldReflect.zxy, -xaxis.xyz);
                reflectDir.y = dot(worldReflect.xyz, upDir.xyz);
                zaxis.xyz = validUpDirXY ? zaxis.xyz : float3(0,0,1);
                reflectDir.z = dot(worldReflect.xyz, -zaxis.xyz);
                
                float reflectLOD = 10.0 * pow(perceptualRoughness, 0.4); //r5.z
                float3 g_PGI = UNITY_SAMPLE_TEXCUBE_LOD(_Global_PGI, reflectDir.xyz, reflectLOD).xyz; //r6.xyz
                float scaled_metallicLow = metallicLow * 0.7 + 0.3; //r5.z
                float gloss = 1.0 - perceptualRoughness; //r1.y
                float reflectivity = scaled_metallicLow * gloss; //r1.y
                float3 reflectColor = g_PGI * reflectivity; //r6.xyz
                
                float3 sunsetColor = float3(1, 1, 1); //r7.xyz
                UNITY_BRANCH
                if (upDotL <= 1) {
                  float4 sunAngleThreshold = saturate(float4(5, 10, 5, 5) * (float4(-0.2, -0.1, 0.1, 0.3) + upDotL)); //r7.xyzw
                  float3 sunsetColor1 = _Global_SunsetColor1 * float3(1.25, 1.25, 1.25);
                  float3 sunsetColor2 =_Global_SunsetColor2 * float3(1.5, 1.5, 1.5);
                  sunsetColor = upDotL > -0.1 ? lerp(sunsetColor2, sunsetColor1, sunAngleThreshold.z) : sunsetColor2 * sunAngleThreshold.w;
                  sunsetColor = upDotL > 0.1 ? lerp(sunsetColor1, _Global_SunsetColor0, sunAngleThreshold.y) : sunsetColor;
                  sunsetColor = upDotL > 0.2 ? lerp(_Global_SunsetColor0, float3(1, 1, 1), sunAngleThreshold.x) : sunsetColor;
                }
                
                float3 lightColor = sunsetColor.xyz * _LightColor0.xyz; //r7.xyz
                float2 scaled_upDotL = saturate(upDotL * float2(0.15, 3.0)); //r5.zw
                atten = 0.8 * lerp(atten, 1.0, scaled_upDotL.x); //r1.z
                lightColor = atten * lightColor.xyz; //r7.xyz
                
                //distributionGGX
                float sqr_nDotH = nDotH * nDotH; //r1.z
                float2 offset_roughnessSqr = roughness * roughness + float2(-1.0, 1.0); //r5.yz
                float pbr_step1 = rcp(sqr_nDotH * offset_roughnessSqr.x + 1.0); //r0.w
                float D = roughnessSqr * pbr_step1 * pbr_step1 * 0.25; //r0.w;
                //missing (1/PI) *
                
                //geometrySchlickGGX
                float k_1 = offset_roughnessSqr.y * offset_roughnessSqr.y; //r1.z
                float k = k_1 * 0.125; //r2.w
                float lerp_bma = 1.0 - k; //r1.z
                float ggxNV = nDotV * lerp_bma + k; //r5.x
                float ggxNL = nDotL * lerp_bma + k; //r1.z
                
                //fresnelSchlick
                float2 metallicHighLowM1 = 1.0 - float2(metallicHigh, metallicLow); //r5.yz
                float factor = exp2(vDotH * (vDotH * -5.5547 - 6.9832)); //r2.w 
                float F = (metallicHighLowM1.x * factor + metallicHigh); //r1.x
                float DF = D * F;//r0.w
                
                //geometrySmith
                float G = rcp(ggxNL * ggxNV); //r1.x
                //missing (NdotL * NdotV) / r1.x
                
                float3 ambientColor = lerp(_Global_AmbientColor1.xyz, _Global_AmbientColor0.xyz, scaled_upDotL.y); //r5.xyw
                float3 ambientColor2 = lerp(_Global_AmbientColor2.xyz, _Global_AmbientColor1.xyz, saturate(upDotL * 3.0 + 1.0)); //r8.xyz
                ambientColor = 0 < upDotL ? ambientColor : ambientColor2; //r5.xyw
                float scaled_nDotUp = saturate(nDotUp * 0.3 + 0.7); //r1.z
                float3 scaled_ambientColor = cubed_nDotL * (scaled_nDotUp * ambientColor); //r8.xyz
                scaled_ambientColor = (_AmbientInc + 1.0) * scaled_ambientColor;
                
                // Add mecha headlamp light. Only active during night.
                float headlampIsOn = _Global_PointLightPos.w >= 0.5; //r1.z
                float length_headlamp = length(_Global_PointLightPos.xyz) - 5.0; //r2.w
                float headlampVisible = saturate(length_headlamp); //r3.w
                float headlampDimInDaylight = saturate(dot(-upDir.xyz, _WorldSpaceLightPos0.xyz) * 5.0); //r4.x
                float headlampLightIntensity = headlampVisible * headlampDimInDaylight; //r3.w
                float3 rayObjToPlayer = _Global_PointLightPos.xyz - upDir.xyz * length_headlamp; //r9.xyz
                float distObjToPlayer = length(rayObjToPlayer.xyz); //r2.w
                float falloffHeadlampLight = pow(max((20.0 - distObjToPlayer) * 0.05, 0),2); //r4.x //inverse log falloff of headlamp light from player. max distance is 20.
                float playerIsDirectlyOnObj = distObjToPlayer < 0.001; //r4.z
                float3 fallbackHeadlampLight = headlampLightIntensity * float3(1.3, 1.1, 0.6); //r10.xyz
                float3 dirObjToPlayer = rayObjToPlayer.xyz / distObjToPlayer; //r9.xyz
                float plDotN = saturate(dot(dirObjToPlayer.xyz, worldNormal.xyz)); //angle between player and Normal
                headlampLightIntensity = headlampLightIntensity * (falloffHeadlampLight * plDotN); //r2.x
                float3 headlampLight = playerIsDirectlyOnObj ? fallbackHeadlampLight : headlampLightIntensity * float3(1.3, 1.1, 0.6); //r2.xyz
                headlampLight = headlampIsOn ? headlampLight.xyz : float3(0,0,0); AND r2.xyz;
                float3 headlampLightColor = nDotL * lightColor.xyz + headlampLight.xyz; //r2.xyz
                headlampLightColor = albedo.xyz * headlampLightColor.xyz; //r2.xyz //albedoLight
                
                
                float metalReverseFalloff = pow(metallicHighLowM1.y, 0.6); //r1.z //[.9071 - 0] log falloff but reversed?
                float3 specularColor = _SpecularColor.xyz * lerp(float3(1.0, 1.0, 1.0), albedo.xyz, metallicLow); //r9.xyz
                specularColor.xyz = specularColor.xyz * lightColor.xyz; //r7.xyz
                specularColor = (DF * G + 0.0318) * specularColor.xyz;
                float3 specColorFactor = nDotL * specularColor.xyz; //r4.xzw
                float3 specColorMod = (metallicHighLowM1.y * 0.2) * albedo.xyz + metallicLow; //r7.xyz //[0.17, 0] * albedo * [0, 1] = [0.32, 1] * albedo
                specularColor = specColorFactor * specColorMod; //r4.xzw //used below
                
                float3 finalColor = albedo.xyz * scaled_ambientColor.xyz; //r7.xyz
                
                float metallicInvFalloff = 1.0 - metallicLow * 0.6; //r0.w // [0.91, 0.4]
                
                float ambientLuminance = dot(ambientColor.xyx, float3(0.3, 0.6, 0.1)); //r1.x //.xyx is correct. why?
                float maxAmbient = max(_Global_AmbientColor0.z, max(_Global_AmbientColor0.x, _Global_AmbientColor0.y)); //r1.w
                float2 ambLumMax = float2(0.003,0.003) + float2(ambientLuminance, maxAmbient); //r1.xw 
                float ambMaxInv = 1.0 / ambLumMax.y; //r1.w
                reflectColor.xyz = reflectColor.xyz * float3(1.7, 1.7, 1.7) * lerp(ambLumMax.xxx, ambientColor, float3(0.4, 0.4, 0.4)) * ambMaxInv;
                float reflectStrength = saturate(upDotL * 2.0 + 0.5) * 0.7 + 0.3; //r1.x
                reflectColor.xyz = reflectColor.xyz * reflectStrength;
                
                finalColor = finalColor.xyz * metallicInvFalloff + (headlampLightColor.xyz * metalReverseFalloff + specularColor);
                finalColor = lerp(finalColor, reflectColor.xyz * albedo.xyz, reflectivity);
                
                float colorIntensity = dot(finalColor.xyz, float3(0.3, 0.6, 0.1)); //r0.w
                finalColor = colorIntensity > 1.0 ? finalColor / colorIntensity * (log(log(colorIntensity) + 1) + 1) : finalColor;
                o.sv_target.xyz = emissionColor * _EmissionMask.xyz + (albedo.xyz * shadows.xyz + finalColor);
                o.sv_target.w = 1;
                return o;
            }
            ENDCG
        }
        Pass {
            Name "ShadowCaster"
            LOD 200
            Tags { "DisableBatching" = "true" "LIGHTMODE" = "SHADOWCASTER" "RenderType" = "Opaque" "SHADOWSUPPORT" = "true" }
            Cull [_CullMode]
            GpuProgramID 175714
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 5.0
            #pragma multi_compile_shadowcaster
            
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            
            struct v2f
            {
                float4 pos : SV_POSITION0;
                float3 uv_lodDist : TEXCOORD1;
                float3 upDir : TEXCOORD2;
                float3 time_state_emiss : TEXCOORD3;
            };
            struct fout
            {
                float4 sv_target : SV_Target0;
            };
            struct GPUOBJECT
            {
              uint objId;
              float3 pos;
              float4 rot;
            };
            
            struct AnimData
            {
              float time;
              float prepare_length;
              float working_length;
              uint state;
              float power;
            };
            
            StructuredBuffer<uint> _IdBuffer;
            StructuredBuffer<GPUOBJECT> _InstBuffer;
            StructuredBuffer<float> _VertaBuffer;
            StructuredBuffer<AnimData> _AnimBuffer;
            StructuredBuffer<float3> _ScaleBuffer;
            
            int _VertexSize;
            uint _VertexCount;
            uint _FrameCount;
            float _UseScale;
            float _Global_Planet_Radius;
            float _EmissionUsePower;
            float _AlphaClip;
            
            UNITY_DECLARE_TEX2D(_MS_Tex);
            UNITY_DECLARE_TEXCUBE(_Global_LocalPlanetHeightmap);
            
            float3 rotate_vector_fast(float3 v, float4 r){ 
                return v + cross(2.0 * r.xyz, cross(r.xyz, v) + r.w * v);
            }
            
            // Keywords: SHADOWS_DEPTH
            v2f vert(appdata_full v, uint instanceID : SV_InstanceID, uint vertexID : SV_VertexID)
            {
                v2f o;
                
                float objIndex = _IdBuffer[instanceID]; //r0.x
                  
                //GPUOBJECT
                float objId = _InstBuffer[objIndex].objId; //r1.x
                float3 pos = _InstBuffer[objIndex].pos; //r1.yzw
                float4 rot = _InstBuffer[objIndex].rot; //r2.xyzw
                
                //animData
                float time = _AnimBuffer[objId].time; //r3.x
                float prepare_length = _AnimBuffer[objId].prepare_length; //r3.y
                float working_length = _AnimBuffer[objId].working_length; //r3.z
                uint state = _AnimBuffer[objId].state; //r3.w
                float power = _AnimBuffer[objId].power; //r0.y
                
                float prepareFrameCount = prepare_length > 0 ? _FrameCount - 1 : _FrameCount; //r0.w
                
                bool useScale = _UseScale > 0.5;
                
                float3 scale = _ScaleBuffer[objIndex]; //r4.xyz;
                
                float3 scaledVPos = useScale ? v.vertex.xyz * scale.xyz : v.vertex.xyz; //r5.xyz
                float3 scaledVNormal = useScale ? v.normal.xyz * scale.xyz : v.normal.xyz; //r4.xyz
                
                bool skipVerta = prepareFrameCount <= 0 || (_VertexSize != 9 && _VertexSize != 6 && _VertexSize != 3) || _VertexCount <= 0 || working_length <= 0; //r0.x
                if (!skipVerta) {
                  float prepareTime = time >= prepare_length && prepare_length > 0 ? 1.0 : 0; //r0.x
                  prepareTime = frac(time / (prepare_length + working_length)) * (prepareFrameCount - 1) + prepareTime;
                  prepareTime = prepareFrameCount - 1 <= 0 ? 0 : prepareTime; //r0.x
                  uint prepareTimeSec = (uint)prepareTime; //r0.z
                  float prepareTimeFrac = frac(prepareTime); //r0.x
                  int frameStride = _VertexSize * _VertexCount; //r0.w
                  int offset = vertexID * _VertexSize; //r1.x
                  uint frameIdx = mad(frameStride, prepareTimeSec, offset); //r3.y
                  uint nextFrameIdx = mad(frameStride, prepareTimeSec + 1, offset); //r0.z
                  
                  if (_VertexSize == 3) {
                    scaledVPos.x = lerp(_VertaBuffer[frameIdx], _VertaBuffer[nextFrameIdx], prepareTimeFrac);
                    scaledVPos.y = lerp(_VertaBuffer[frameIdx + 1], _VertaBuffer[nextFrameIdx + 1], prepareTimeFrac);
                    scaledVPos.z = lerp(_VertaBuffer[frameIdx + 2], _VertaBuffer[nextFrameIdx + 2], prepareTimeFrac);
                  } else {
                    if (_VertexSize == 6) {
                      scaledVPos.x = lerp(_VertaBuffer[frameIdx], _VertaBuffer[nextFrameIdx], prepareTimeFrac);
                      scaledVPos.y = lerp(_VertaBuffer[frameIdx + 1], _VertaBuffer[nextFrameIdx + 1], prepareTimeFrac);
                      scaledVPos.z = lerp(_VertaBuffer[frameIdx + 2], _VertaBuffer[nextFrameIdx + 2], prepareTimeFrac);
                      scaledVNormal.x = lerp(_VertaBuffer[frameIdx + 3], _VertaBuffer[nextFrameIdx + 3], prepareTimeFrac);
                      scaledVNormal.y = lerp(_VertaBuffer[frameIdx + 4], _VertaBuffer[nextFrameIdx + 4], prepareTimeFrac);
                      scaledVNormal.z = lerp(_VertaBuffer[frameIdx + 5], _VertaBuffer[nextFrameIdx + 5], prepareTimeFrac);
                    } else {
                      if (_VertexSize == 9) {
                        scaledVPos.x = lerp(_VertaBuffer[frameIdx], _VertaBuffer[nextFrameIdx], prepareTimeFrac);
                        scaledVPos.y = lerp(_VertaBuffer[frameIdx + 1], _VertaBuffer[nextFrameIdx + 1], prepareTimeFrac);
                        scaledVPos.z = lerp(_VertaBuffer[frameIdx + 2], _VertaBuffer[nextFrameIdx + 2], prepareTimeFrac);
                        scaledVNormal.x = lerp(_VertaBuffer[frameIdx + 3], _VertaBuffer[nextFrameIdx + 3], prepareTimeFrac);
                        scaledVNormal.y = lerp(_VertaBuffer[frameIdx + 4], _VertaBuffer[nextFrameIdx + 4], prepareTimeFrac);
                        scaledVNormal.z = lerp(_VertaBuffer[frameIdx + 5], _VertaBuffer[nextFrameIdx + 5], prepareTimeFrac);
                      }
                    }
                  }
                }
                
                float3 worldVPos = rotate_vector_fast(scaledVPos, rot) + pos.xyz; //r5.xyz
                float3 worldVNormal = rotate_vector_fast(scaledVNormal, rot); //r7.xyz //moved to r6
                
                float posHeight = length(pos); //r1.x
                float3 upDir = float3(0,1,0); //r2.xyz
                float lodDist = 0; //r1.x
                if (posHeight > 0.1) {
                  upDir.xyz = pos / posHeight; //r2.xyz
                  float g_heightMap = UNITY_SAMPLE_TEXCUBE_LOD(_Global_LocalPlanetHeightmap, normalize(worldVPos.xyz), 0).x;
                  float adjustHeight = (_Global_Planet_Radius + g_heightMap) - posHeight; //r1.x
                  worldVPos.xyz = adjustHeight * upDir.xyz + worldVPos.xyz; //r5
                  lodDist = saturate(0.01 * (distance(pos.xyz, _WorldSpaceCameraPos) - 180)); //r1.x
                }
                
                worldVPos.xyz = mul(unity_ObjectToWorld, float4(worldVPos,1)).xyz; //r4.xyz
                worldVNormal.xyz = lerp(normalize(worldVNormal), upDir.xyz, 0.2 * lodDist); //r6.xyz //moved to r0.xzw
                
                o.time_state_emiss.y = state;
                o.time_state_emiss.z = lerp(1, power, _EmissionUsePower);
                
                float4 clipPos = UnityClipSpaceShadowCasterPos(float4(worldVPos.xyz, 1.0), worldVNormal.xyz);
                o.pos = UnityApplyLinearShadowBias(clipPos);
                
                o.uv_lodDist.xy = v.texcoord.xy; //uv
                o.uv_lodDist.z = lodDist;
                
                o.upDir.xyz = upDir.xyz;
                o.time_state_emiss.x = time;
                return o;
            }
            // Keywords: SHADOWS_DEPTH
            fout frag(v2f inp)
            {
                fout o;
                float2 uv = inp.uv_lodDist.xy;
                float3 mstex = UNITY_SAMPLE_TEX2D(_MS_Tex, uv).xyw; //r1.xyz
                if (mstex.y < _AlphaClip - 0.001) discard; //r1.y
                o.sv_target.xyzw = float4(0,0,0,0);
                return o;
            }
            ENDCG
        }
    }
    Fallback "Diffuse"
}