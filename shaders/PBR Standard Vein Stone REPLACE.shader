Shader "VF Shaders/Forward/PBR Standard Vein Stone REPLACE" {
    Properties {
        _Color0 ("Color 颜色 ID=0", Color) = (1,1,1,1)
        _Color5 ("Color 颜色 ID=5", Color) = (1,1,1,1)
        _Color6 ("Color 颜色 ID=6", Color) = (1,1,1,1)
        _Color8 ("Color 颜色 ID=8", Color) = (1,1,1,1)
        _SpecularColor ("Specular Color", Color) = (1,1,1,1)
        _EmissionMask ("自发光正片叠底色 Emmission Background Color", Color) = (1,1,1,1)
        _MainTexA ("Albedo (RGB) 漫反射 铺底 Diffuse Reflection", 2D) = "white" {}
        _MainTexB ("Albedo (RGB) 漫反射 颜色 Diffuse Color", 2D) = "white" {}
        _OcclusionTex ("环境光遮蔽 Ambient Occlusion", 2D) = "white" {}
        _NormalTex ("Normal 法线", 2D) = "bump" {}
        _MS_Tex ("Metallic (R) 透贴 Transparent (G) 金属 Metal (A) 高光 Highlight", 2D) = "black" {}
        _EmissionTex ("Emission (RGB) 自发光  (A) 抖动遮罩 (Dither Mask)", 2D) = "black" {}
        _AmbientInc ("环境光提升  Ambient Light Boost", Float) = 0
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
            GpuProgramID 34573
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
                float2 uv : TEXCOORD3;
                float3 upDir : TEXCOORD4;
                float3 time_state_emiss : TEXCOORD5;
                float3 worldPos : TEXCOORD6;
                float3 indirectLight : TEXCOORD7;
                UNITY_SHADOW_COORDS(9)
                float4 unk : TEXCOORD10;
            };
            
            struct fout
            {
                float4 sv_target : SV_Target0;
            };
            
            StructuredBuffer<uint> _IdBuffer;
            StructuredBuffer<GPUOBJECT> _InstBuffer;
            StructuredBuffer<AnimData> _AnimBuffer;
            StructuredBuffer<float3> _ScaleBuffer;
            
            float4 _LightColor0;
            float _UseScale;
            float4 _Global_AmbientColor0;
            float4 _Global_AmbientColor1;
            float4 _Global_AmbientColor2;
            float3 _Global_SunsetColor0;
            float3 _Global_SunsetColor1;
            float3 _Global_SunsetColor2;
            float4 _Global_Biomo_Color0;
            float4 _Global_Biomo_Color1;
            float4 _Global_Biomo_Color2;
            float _Global_Planet_Radius;
            float4 _Global_PointLightPos;
            float4 _Color0;
            float4 _Color5;
            float4 _Color6;
            float4 _Color8;
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
            
            /* Textures used in the shader */
            sampler2D _MainTexA;
            sampler2D _MainTexB;
            sampler2D _OcclusionTex;
            UNITY_DECLARE_TEX2D(_MS_Tex);
            sampler2D _NormalTex;
            sampler2D _EmissionTex;
            UNITY_DECLARE_TEX2D(_EmissionJitterTex);
            UNITY_DECLARE_TEXCUBE(_Global_LocalPlanetHeightmap);
            
            v2f vert(appdata_full v, uint instanceID : SV_InstanceID, uint vertexID : SV_VertexID)
            {
                v2f o;
                
                float objIndex = _IdBuffer[instanceID];
                
                float objId = _InstBuffer[objIndex].objId;
                float3 pos = _InstBuffer[objIndex].pos;
                float4 rot = _InstBuffer[objIndex].rot;
                
                float time = _AnimBuffer[objId].time;
                float prepare_length = _AnimBuffer[objId].prepare_length;
                float working_length = _AnimBuffer[objId].working_length;
                uint state = _AnimBuffer[objId].state;
                float power = _AnimBuffer[objId].power;
                
                float3 scale = _ScaleBuffer[objIndex];
                bool useScale = _UseScale > 0.5;
                float3 scaledVPos = useScale ? v.vertex.xyz * scale.xyz : v.vertex.xyz;
                float3 scaledVNormal = useScale ? v.normal.xyz * scale.xyz : v.normal.xyz;
                float3 scaledVTan = v.tangent.xyz;
                
                animateWithVerta(vertexID, time, prepare_length, working_length, /*inout*/ scaledVPos, /*inout*/ scaledVNormal, /*inout*/ scaledVTan);
                
                float3 worldVPos = rotate_vector_fast(scaledVPos, rot) + pos;
                float3 worldVNormal = rotate_vector_fast(scaledVNormal, rot);
                float3 worldTangent = rotate_vector_fast(scaledVTan, rot);
                
                float posHeight = length(pos);
                float3 upDir = float3(0,1,0);
                if (posHeight > 0.1) {
                    upDir = pos / posHeight;
                    float g_heightMap = UNITY_SAMPLE_TEXCUBE_LOD(_Global_LocalPlanetHeightmap, normalize(worldVPos), 0).x;
                    float adjustHeight = (_Global_Planet_Radius + g_heightMap) - posHeight;
                    worldVPos = adjustHeight * upDir + worldVPos;
                    upDir = normalize(pos);
                }
                
                worldVPos = mul(unity_ObjectToWorld, float4(worldVPos,1)).xyz;
                worldVNormal = normalize(worldVNormal);
                
                float4 clipPos = UnityObjectToClipPos(worldVPos);
                
                worldVNormal = UnityObjectToWorldNormal(worldVNormal);
                worldTangent = float4(UnityObjectToWorldDir(worldTangent), v.tangent.w);
                float3 worldBinormal = calculateBinormal(float4(worldTangent, v.tangent.w), worldVNormal);
                
                o.indirectLight = ShadeSH9(float4(worldVNormal, 1.0));
                
                o.pos.xyzw = clipPos.xyzw;
                UNITY_TRANSFER_SHADOW(o, float(0,0))
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
                o.TBN2.w = worldVPos.z;
                o.upDir.xyz = upDir;
                o.unk.xyzw = float4(0,0,0,0);
                o.uv.xy = v.texcoord.xy;
                o.time_state_emiss.x = time;
                o.time_state_emiss.y = state;
                o.time_state_emiss.z = lerp(1, power, _EmissionUsePower);
                o.worldPos.xyz = worldVPos.xyz;
                
                return o;
            }
            
            fout frag(v2f inp)
            {
                fout o;
                
                float2 uv = inp.uv.xy;
                float3 upDir = inp.upDir.xyz;
                float time = inp.time_state_emiss.x;
                float veinType = inp.time_state_emiss.y;
                float emissionPower = inp.time_state_emiss.z;
                float3 worldPos1 = inp.worldPos.xyz;
                float3 indirectLight = inp.indirectLight.xyz;
                
                float3 mstex = UNITY_SAMPLE_TEX2D(_MS_Tex, uv).xyw; //r0.xyz
                
                if (mstex.y < _AlphaClip - 0.001) discard;
                
                float4 veinColor = veinType > 7.95 && veinType < 8.05 ? _Color8.xyzw : _Color0.xyzw;
                veinColor = veinType > 5.95 && veinType < 6.05 ? _Color6.xyzw : veinColor;
                veinColor = veinType > 4.95 && veinType < 5.05 ? _Color5.xyzw : veinColor; //r2.xyzw
                
                float3 colorA = tex2D(_MainTexA, uv).xyz * veinColor.xyz; //r1.xyz
                float4 colorB = tex2D(_MainTexB, uv); //r3.xyzw
                float4 muted_veinColor = lerp(float4(1,1,1,1), veinColor.xyzw, float4(0.5, 0.5, 0.5, 0.5)); //r2.xyzw
                colorB = colorB * muted_veinColor; //r2.xyzw
                
                float2 occTex = tex2D(_OcclusionTex, uv).xw; //r0.yw
                float3 albedo = lerp(colorA.xyz * float3(5.0, 5.0, 5.0), colorB.xyz * float3(2.0, 2.0, 2.0), colorB.www); //r1.xyz
                albedo = albedo * pow(lerp(1.0, occTex.x, occTex.y), _OcclusionPower);
                albedo = _AlbedoMultiplier * albedo.xyz;
                
                float3 unpackedNormal = UnpackNormal(tex2Dbias(_NormalTex, float4(uv, 0, -1)));
                float3 normal = float3(_NormalMultiplier * unpackedNormal.xy, unpackedNormal.z);
                normal = normalize(normal);
                
                float4 emmTex = tex2Dbias(_EmissionTex, float4(uv,0,-1)); //r3.xyzw
                float emmJitTex = UNITY_SAMPLE_TEX2D(_EmissionJitterTex, float2(time, 0)).x; //r2.w
                
                float canEmit = (int)(emissionPower > 0.1) | (int)(_EmissionSwitch < 0.5) ? 1.0 : 0.0; //r1.w
                
                float2 g_heightMap = UNITY_SAMPLE_TEXCUBE(_Global_LocalPlanetHeightmap, normalize(worldPos1.xyz)).xy; //r4.yz
                float frac_heightMap = frac(g_heightMap.y); //r0.w
                float int_heightMap = g_heightMap.y - frac_heightMap; //r4.z
                float biomoThreshold = (frac_heightMap * frac_heightMap) * (frac_heightMap * -2.0 + 3.0) + int_heightMap; //r0.w
                float biomoThreshold0 = saturate(1.0 - biomoThreshold);
                float biomoThreshold1 = min(saturate(2.0 - biomoThreshold), saturate(biomoThreshold));
                float biomoThreshold2 = saturate(biomoThreshold - 1);
                float4 biomoColor = biomoThreshold1 * _Global_Biomo_Color1; //r5.xyzw
                biomoColor = _Global_Biomo_Color0 * biomoThreshold0 + biomoColor;
                biomoColor = _Global_Biomo_Color2 * biomoThreshold2 + biomoColor;
                biomoColor.xyz = biomoColor.xyz * _BiomoMultiplier; //r5.xyz
                
                float heightOffset = saturate((_BiomoHeight - length(worldPos1) - g_heightMap.x + _Global_Planet_Radius) / _BiomoHeight); //r0.y
                heightOffset = biomoColor.w * pow(heightOffset, 2);
                
                biomoColor.xyz = lerp(biomoColor, biomoColor * albedo, _Biomo); //r5.xyz
                albedo = lerp(albedo, biomoColor, heightOffset); //r1.xyz
                
                float metallic = saturate(_MetallicMultiplier * mstex.x);
                float smoothness = saturate(_SmoothMultiplier * mstex.z);
                
                float3 emissionColor = _EmissionMultiplier * emmTex.xyz; //r3.xyz
                float emissionSwitch = _EmissionSwitch * emmTex.w; //r0.z
                float emissionJitter = _EmissionJitter * emmTex.w; //r0.w
                float emmIsOn = lerp(1.0, saturate(veinType), emissionSwitch); //r0.z
                emissionColor = emissionColor * emmIsOn; //r3.xyz
                float jitterRatio = _EmissionSwitch * emissionJitter; //r0.z
                float jitter = lerp(1, emmJitTex, jitterRatio); //r0.z
                emissionColor = emissionColor * jitter;
                emissionColor = emissionColor * canEmit; //r3.xyz
                
                float3 worldPos = float3(inp.TBN0.w, inp.TBN1.w, inp.TBN2.w); //r4.yzw
                
                UNITY_LIGHT_ATTENUATION(atten, inp, worldPos); //r0.w
                
                float3 viewDir = normalize(_WorldSpaceCameraPos - worldPos); //r6.xyz
                
                float3 worldNormal;
                worldNormal.x = dot(inp.TBN0.xyz, normal.xyz);
                worldNormal.y = dot(inp.TBN1.xyz, normal.xyz);
                worldNormal.z = dot(inp.TBN2.xyz, normal.xyz);
                worldNormal = normalize(worldNormal.xyz); //r2.xyz
                
                float metallicLow = metallic * 0.85 + 0.149; //r4.y
                float metallicHigh = metallic * 0.85 + 0.649; //r4.x
                
                float perceptualRoughness = 1 - smoothness * 0.97; //r0.x
                
                float3 lightDir = _WorldSpaceLightPos0;
                
                float3 halfDir = normalize(viewDir + lightDir); //r5.xyz
                
                float roughness = perceptualRoughness * perceptualRoughness; //r0.y
                
                float unclamped_nDotL = dot(worldNormal, lightDir); //r1.w
                float nDotL = max(0, unclamped_nDotL); //r2.w
                float unclamped_nDotV = dot(worldNormal, viewDir); //r3.w
                float nDotV = max(0, unclamped_nDotV); //r3.w
                float unclamped_nDotH = dot(worldNormal, halfDir); //r4.z
                float nDotH = max(0, unclamped_nDotH); //r4.z
                float unclamped_vDotH = dot(viewDir, halfDir); //r4.w
                float vDotH = max(0, unclamped_vDotH); //r4.w
                
                float upDotL = dot(upDir, lightDir); //r5.x
                float nDotUp = dot(worldNormal, upDir); //r5.y
                
                float reflectivity; //r0.x
                float3 reflectColor = reflection(perceptualRoughness, metallicLow, upDir, viewDir, worldNormal, /*out*/ reflectivity); //r6.xyz

                float3 sunsetColor = float3(1, 1, 1);
                // an odd sanity check to make sure upDotL is 1 or less, but it should always be?
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
                    sunsetColor = upDotL >  0.2 ? sunsetBlendDay     : sunsetColor;
                }
                
                float3 lightColor = sunsetColor * _LightColor0.xyz; //r7.xyz
                
                atten = 0.8 * lerp(atten, 1, saturate(0.15 * upDotL)); //r0.w
                lightColor = atten * lightColor; //r7.xyz
                
                float specularTerm = GGX(roughness, metallicHigh, nDotH, nDotV, nDotL, vDotH);
                
                float3 ambientTwilight = lerp(_Global_AmbientColor2.xyz, _Global_AmbientColor1.xyz, saturate(upDotL * 3.0 + 1)); //-33% to 0%
                float3 ambientLowSun = lerp(_Global_AmbientColor1.xyz, _Global_AmbientColor0.xyz, saturate(upDotL * 3.0)); // 0% - 33%
                float3 ambientColor = upDotL > 0 ? ambientLowSun : ambientTwilight; //r4.xzw
                
                float3 ambientLightColor = ambientColor * saturate(nDotUp * 0.3 + 0.7); //r5.yzw
                ambientLightColor = ambientLightColor * pow(unclamped_nDotL * 0.35 + 1, 3); //r5.yzw
                ambientLightColor = ambientLightColor * (_AmbientInc + 1);
                
                float3 headlampLight = calculateLightFromHeadlamp(_Global_PointLightPos, upDir, lightDir, worldNormal); //r2.xyz
                
                float3 headlampLightColor = nDotL * lightColor + headlampLight;
                headlampLightColor = albedo * headlampLightColor; //r2.xyz
                
                float3 specularColor = _SpecularColor.xyz * lerp(float3(1.0, 1.0, 1.0), albedo, metallicLow); //r8.xzw
                specularColor = specularColor * lightColor;
                float INV_TEN_PI = 0.0318309888;
                specularColor = specularColor * nDotL * (specularTerm + INV_TEN_PI);
                
                float3 specColorMod = (1.0 - metallicLow) * 0.2 * albedo + metallicLow; //r8.xyz
                specularColor = specularColor * specColorMod; //r7.xyz
                
                ambientLightColor = ambientLightColor * albedo.xyz; //r5.yzw
                
                float ambientLuminance = 0.003 + dot(ambientColor.xyx, float3(0.3, 0.6, 0.1)); //r0.z
                float maxAmbient = 0.003 + max(_Global_AmbientColor0.z, max(_Global_AmbientColor0.x, _Global_AmbientColor0.y)); //r1.w
                float3 greyedAmbient = lerp(ambientLuminance, ambientColor, float3(0.4, 0.4, 0.4)) / maxAmbient; //r4.xyz
                reflectColor = reflectColor * float3(1.7, 1.7, 1.7) * greyedAmbient; //r4.xyz
                
                float reflectStrength = saturate(upDotL * 2.0 + 0.5) * 0.7 + 0.3; //r0.z
                reflectColor = reflectColor * reflectStrength; //r4.xyz
                
                float3 finalColor = ambientLightColor * (1.0 - metallicLow * 0.6)
                    + headlampLightColor * pow(1 - metallicLow, 0.6)
                    + specularColor.xyz; //r0.yzw
                finalColor = lerp(finalColor, reflectColor * albedo, reflectivity);
                
                float colorIntensity = dot(finalColor, float3(0.3, 0.6, 0.1)); //r0.w
                finalColor = colorIntensity > 1.0 ? (finalColor / colorIntensity) * (log(log(colorIntensity) + 1) + 1) : finalColor;
                finalColor = emissionColor * _EmissionMask
                    + albedo.xyz * indirectLight
                    + finalColor;
                    
                o.sv_target.xyz = finalColor;
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
            #pragma enable_d3d11_debug_symbols
            
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "CGIncludes/DSPCommon.cginc"
            
            struct v2f
            {
                float4 pos : SV_POSITION0;
                float2 uv : TEXCOORD1;
                float3 upDir : TEXCOORD2;
                float3 time_state_emiss : TEXCOORD3;
            };
            struct fout
            {
                float4 sv_target : SV_Target0;
            };
            
            StructuredBuffer<uint> _IdBuffer;
            StructuredBuffer<GPUOBJECT> _InstBuffer;
            StructuredBuffer<AnimData> _AnimBuffer;
            StructuredBuffer<float3> _ScaleBuffer;
            
            float _UseScale;
            float _Global_Planet_Radius;
            float _EmissionUsePower;
            float _AlphaClip;
            
            UNITY_DECLARE_TEX2D(_MS_Tex);
            UNITY_DECLARE_TEXCUBE(_Global_LocalPlanetHeightmap);
            
            v2f vert(appdata_full v, uint instanceID : SV_InstanceID, uint vertexID : SV_VertexID)
            {
                v2f o;
                
                float objIndex = _IdBuffer[instanceID];
                  
                float objId = _InstBuffer[objIndex].objId;
                float3 pos = _InstBuffer[objIndex].pos;
                float4 rot = _InstBuffer[objIndex].rot;
                
                float time = _AnimBuffer[objId].time;
                float prepare_length = _AnimBuffer[objId].prepare_length;
                float working_length = _AnimBuffer[objId].working_length;
                uint state = _AnimBuffer[objId].state;
                float power = _AnimBuffer[objId].power;
                
                float prepareFrameCount = prepare_length > 0 ? _FrameCount - 1 : _FrameCount;
                
                bool useScale = _UseScale > 0.5;
                
                float3 scale = _ScaleBuffer[objIndex];
                
                float3 scaledVPos = useScale ? v.vertex.xyz * scale.xyz : v.vertex.xyz;
                float3 scaledVNormal = useScale ? v.normal.xyz * scale.xyz : v.normal.xyz;
                
                float3 tan = float3(0,0,0);
                animateWithVerta(vertexID, time, prepare_length, working_length, /*inout*/ scaledVPos, /*inout*/ scaledVNormal, /*inout*/ tan);
                
                float3 worldVPos = rotate_vector_fast(scaledVPos, rot) + pos;
                float3 worldVNormal = rotate_vector_fast(scaledVNormal, rot);
                
                float posHeight = length(pos);
                float3 upDir = float3(0,1,0);
                if (posHeight > 0.1) {
                    upDir = pos / posHeight;
                    float g_heightMap = UNITY_SAMPLE_TEXCUBE_LOD(_Global_LocalPlanetHeightmap, normalize(worldVPos), 0).x;
                    float adjustHeight = (_Global_Planet_Radius + g_heightMap) - posHeight;
                    worldVPos = adjustHeight * upDir + worldVPos;
                    upDir = normalize(pos);
                }
                
                worldVPos = mul(unity_ObjectToWorld, float4(worldVPos,1)).xyz;
                worldVNormal = normalize(worldVNormal);
                
                o.time_state_emiss.y = state;
                o.time_state_emiss.z = lerp(1, power, _EmissionUsePower);
                
                float4 clipPos = UnityClipSpaceShadowCasterPos(float4(worldVPos.xyz, 1.0), worldVNormal);
                o.pos.xyzw = UnityApplyLinearShadowBias(clipPos);
                
                o.uv.xy = v.texcoord.xy;
                
                o.upDir = upDir;
                o.time_state_emiss.x = time;
                return o;
            }
            
            fout frag(v2f inp)
            {
                fout o;
                float2 uv = inp.uv.xy;
                float3 mstex = UNITY_SAMPLE_TEX2D(_MS_Tex, uv).xyw;
                if (mstex.y < _AlphaClip - 0.001) discard;
                o.sv_target.xyzw = float4(0,0,0,0);
                return o;
            }
            ENDCG
        }
    }
    Fallback "Diffuse"
}