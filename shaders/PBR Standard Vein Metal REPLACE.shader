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
            #include "CGIncludes/DSPCommon.cginc"
            
            /* v2f: struct of data that is output from the vertex shader (runs once per vertex) to the
                input of the fragment/pixel shader (runs once per pixel on screen).  */
            struct v2f
            {   
                    /* pos: clip space position. essentially, the position on the screen. */
                float4 pos : SV_POSITION0;
                    /* TBN[0,1,2]: Tangent, Binormal, Normal. Packed into 3 variables, which will act as
                        a transformation matrix on the normal texture. I don't fully understand this.
                        Also packs World Position into the last float since there is space left */
                float4 TBN0 : TEXCOORD0; // (Tan.x, Bin.x, Norm.x, wPos.x)
                float4 TBN1 : TEXCOORD1; // (Tan.y, Bin.y, Norm.y, wPos.y)
                float4 TBN2 : TEXCOORD2; // (Tan.z, Bin.z, Norm.z, wPos.z)
                    /* uv_lodDist:  UV coords (basically x,y coordinates for a pixel in a texture) and
                        camera distance from the object */
                float3 uv_lodDist : TEXCOORD3; // (u, v, lodDist)
                    /* upDir: literally the upward direction relative to the object. "Up" depends
                        where on the planet the object is located.*/
                float3 upDir : TEXCOORD4;
                    /* time_state_emiss: time and state passed directly from the _AnimBuffer and a
                        toggle for if the object "emission" (aka glow) should be active. (Not relevant
                        for metal veins)*/
                float3 time_state_emiss : TEXCOORD5;
                    /* worldPos: for some reason, a second copy of World Position. */
                float3 worldPos : TEXCOORD6;
                    /* indirectLight: Unity's built in indirect lighting. Don't mess with this. */
                float3 indirectLight : TEXCOORD7;
                    /* macro for adding needed shadow data. Don't mess with this */
                UNITY_SHADOW_COORDS(9)
                    /* unk: unknown and not actually used, as far as I can tell. */
                float4 unk : TEXCOORD10;
            };
            
            /* fout: the output of the fragment/pixel shader. Basically, the color of the pixel in RGBA */
            struct fout
            {
                float4 sv_target : SV_Target0;
            };
            
            StructuredBuffer<uint> _IdBuffer;
            StructuredBuffer<GPUOBJECT> _InstBuffer;
            StructuredBuffer<AnimData> _AnimBuffer;
            StructuredBuffer<float3> _ScaleBuffer;
            
            /* All of the properties and globals that will be used in the shader */
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
            
            /* Textures used in the shader */
            sampler2D _MainTexA;
            sampler2D _MainTexB;
            sampler2D _OcclusionTex;
            UNITY_DECLARE_TEX2D(_MS_Tex);
            sampler2D _NormalTex;
            sampler2D _EmissionTex;
            UNITY_DECLARE_TEX2D(_EmissionJitterTex);
            UNITY_DECLARE_TEXCUBE(_Global_LocalPlanetHeightmap);
            UNITY_DECLARE_TEXCUBE(_Global_PGI);
            
            /* What image is reflected in metallic surfaces and how reflective is it? */
            inline float3 reflection(float perceptualRoughness, float3 metallicLow, float3 upDir, float3 viewDir, float3 worldNormal, out float reflectivity) {
                float upDirMagSqr = dot(upDir, upDir);
                bool validUpDirY = upDirMagSqr > 0.01 && upDir.y < 0.9999;
                float3 xaxis = validUpDirY ? normalize(cross(upDir.zxy, float3(0, 0, 1))) : float3(0, 1, 0);
                bool validUpDirXY = dot(xaxis, xaxis) > 0.01 && upDirMagSqr > 0.01;
                float3 zaxis = validUpDirXY ? normalize(cross(xaxis.yzx, upDir)) : float3(0, 0, 1);
                
                float3 worldReflect = reflect(-viewDir, worldNormal);
                float3 reflectDir;
                reflectDir.x = dot(worldReflect.zxy, -xaxis);
                reflectDir.y = dot(worldReflect, upDir);
                reflectDir.z = dot(worldReflect, -zaxis);
                
                float reflectLOD = 10.0 * pow(perceptualRoughness, 0.4);
                float3 g_PGI = UNITY_SAMPLE_TEXCUBE_LOD(_Global_PGI, reflectDir, reflectLOD);
                
                float scaled_metallicLow = metallicLow * 0.7 + 0.3;
                reflectivity = scaled_metallicLow * (1.0 - perceptualRoughness);
                
                return g_PGI * reflectivity;
            }
            
            v2f vert(appdata_full v, uint instanceID : SV_InstanceID, uint vertexID : SV_VertexID)
            {
                v2f o;
                
                /* _IdBuffer: an array of Ids (uints) populated by the LOD compute shader, which determines
                    which instances of the object need to be rendered. The compute shader runs each frame, adds
                    Ids for use as indices on _InstBufffer, and provides a final count 'n'. The model will be
                    rendered 'n' times, with the built in 'System Value' SV_InstanceID iterating from 0 to n-1.
                    
                    objId: an Id for this instance, used to lookup the right data on the _AnimBuffer below.
                    pos: xyz position of this instance in the world
                    rot: quaternion rotation */
                float objIndex = _IdBuffer[instanceID];
                  
                /* _InstBuffer: an array of GPUOBJECTs, which is a struct defined in the game code.
                    This buffer stores all of the position and rotation info for every copy of the object,
                    even if it will not be rendered this frame. _InstBuffer provides the Ids of the instances
                    that need to be rendered. That way the game can make one draw call for each object
                    and the GPU can do the rest of the work.
                    
                    objId: an Id for this instance, used to lookup the right data on the _AnimBuffer below.
                    pos: xyz position of this instance in the world
                    rot: quaternion rotation */
                float objId = _InstBuffer[objIndex].objId;
                float3 pos = _InstBuffer[objIndex].pos;
                float4 rot = _InstBuffer[objIndex].rot;
                
                /* _AnimBuffer: an array of AnimData, which is a struct defined in the game code.
                    Typically used for animation data, but frequently used as a place to put extra data.
                    For example, in metal veins, state is used to store VeinType, which is used to select
                    the right color. Nothing to do with animation.
                    
                    time: 
                    prepare_length:
                    working_length:
                    state:
                    power: */
                float time = _AnimBuffer[objId].time;
                float prepare_length = _AnimBuffer[objId].prepare_length;
                float working_length = _AnimBuffer[objId].working_length;
                uint state = _AnimBuffer[objId].state;
                float power = _AnimBuffer[objId].power;
                
                /* Resize/Scale: mostly used for randomizing size of vegetation
                    If _UseScale is on, grab the scaling factor from _ScaleBuffer and use to scale
                    both the vertices and the normals. For some reason, tangent isn't scaled.*/
                float3 scale = _ScaleBuffer[objIndex];
                bool useScale = _UseScale > 0.5;
                float3 scaledVPos = useScale ? v.vertex.xyz * scale.xyz : v.vertex.xyz;
                float3 scaledVNormal = useScale ? v.normal.xyz * scale.xyz : v.normal.xyz;
                float3 scaledVTan = v.tangent.xyz;
                
                /* DSP stores some animation data in separate Verta files, which contain vertex positions(optionally, also
                    normals and tangents) for each frame of an animation. This will replace the current values for each, if
                    there is a verta file for this model and this instance is currently animating. Otherwise does nothing. */
                animateWithVerta(vertexID, time, prepare_length, working_length, /*inout*/ scaledVPos, /*inout*/ scaledVNormal, /*inout*/ scaledVTan);
                
                /* Use the position and rotation data for this instance to put it in the right position in the world.
                    Each vertex, normal, and tangent needs to be rotated, but only the positions of the vertex need to be
                    moved. This is because normal and tangents are directions, not points. */
                float3 worldVPos = rotate_vector_fast(scaledVPos, rot) + pos.xyz;
                float3 worldVNormal = rotate_vector_fast(scaledVNormal, rot);
                float3 worldTangent = rotate_vector_fast(scaledVTan, rot);
                
                /* posHeight: Since the position of the instance in the world is likely the surface of the planet, (0,0,0) in
                    world space is the center of the planet, and all rocky planets are have a radius of 200, length(pos) is
                    going to be (roughly) 200 almost every time. */
                float posHeight = length(pos);
                
                /* upDir: literally the upwards direction relative to the object. Default to (0,1,0) then calculate based
                    on the actual position of the object below. */
                float3 upDir = float3(0,1,0);
                
                /* lodDist: a distance factor (object to camera) used to control level of detail*/
                float lodDist = 0;
                
                // Just checking to see if the value of pos is nonsense.
                if (posHeight > 0.1) {
                    
                    /* Since (0,0,0) in world space is the center of the planet, the pos vector points upward!
                        Normalize pos to make it a "direction" rather than a point in 3D space */
                    upDir.xyz = normalize(pos);
                    
                    /* g_heightMap: a texture containing the height map of the land on the planet, relative to sea level. */
                    float g_heightMap = UNITY_SAMPLE_TEXCUBE_LOD(_Global_LocalPlanetHeightmap, normalize(worldVPos.xyz), 0).x;
                    
                    /* If pos is slightly below ground or floating, bring it to surface level. Adjust along our upDir axis. */
                    float adjustHeight = (_Global_Planet_Radius + g_heightMap) - posHeight;
                    worldVPos.xyz = adjustHeight * upDir.xyz + worldVPos.xyz;
                    
                    /* calculate lodDist. Essentially 0 = close, 1 = far */
                    lodDist = saturate(0.01 * (distance(pos.xyz, _WorldSpaceCameraPos) - 180));
                }
                
                /* Usually converts vertex position to world space, but we already have it world space thanks to
                    _InstBuffer.pos and .rot. Does nothing. */
                worldVPos.xyz = mul(unity_ObjectToWorld, float4(worldVPos,1)).xyz;
                
                /* Slightly adjusts our normals towards the upward direction if the camera is far. Not clear to me why
                    you would want this. Maybe it looks better in the planet map view? */
                worldVNormal.xyz = lerp(normalize(worldVNormal), upDir.xyz, 0.2 * lodDist);
                
                // Unity can convert our World Position to ClipPos for us. 
                float4 clipPos = UnityObjectToClipPos(worldVPos);
                
                /* Again, usually would convert normals and tangents to world space, but we already have them there.
                    Does nothing. */
                worldVNormal = UnityObjectToWorldNormal(worldVNormal.xyz);
                worldTangent = float4(UnityObjectToWorldDir(worldTangent.xyz), v.tangent.w);
                
                /* Use math to calulate binormals using normals and tangents. Basically, the binormal is the cross product
                    of the normal and tangent. */
                float3 worldBinormal = calculateBinormal(float4(worldTangent.xyz, v.tangent.w), worldVNormal);
                
                /* Unity's built-in indirect lighting calculation */
                o.indirectLight.xyz = ShadeSH9(float4(worldVNormal, 1.0));
                
                /* pass all of our values to the fragment/pixel shader */
                UNITY_TRANSFER_SHADOW(o, float(0,0))
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
                o.TBN2.w = worldVPos.z;
                o.uv_lodDist.xy = v.texcoord.xy;
                o.uv_lodDist.z = lodDist;
                o.upDir.xyz = upDir.xyz;
                o.time_state_emiss.x = time;
                o.time_state_emiss.y = state;
                o.time_state_emiss.z = lerp(1, power, _EmissionUsePower);
                o.worldPos.xyz = worldVPos.xyz;
                o.unk.xyzw = float4(0,0,0,0);
                return o;
            }
            
            fout frag(v2f inp)
            {
                fout o;
                
                /* load inputs into variables. Not necessary, but makes things easier. */
                float2 uv = inp.uv_lodDist.xy;
                float lodDist = inp.uv_lodDist.z;
                float3 upDir = inp.upDir.xyz;
                float time = inp.time_state_emiss.x;
                float veinType = inp.time_state_emiss.y;
                float emissionPower = inp.time_state_emiss.z;
                float3 worldPos1 = inp.worldPos.xyz;
                float3 indirectLight = inp.indirectLight.xyz;
              
                /* Choose color based on the veinType */
                /* Why not just veinType == 1? The general rule is to assume imprecision. Everything in a shader
                    is a float, and floats can be imprecise, so assume nothing is exact. The reason in this case
                    is interpolation. When values are passed from vertex to fragment shader, the values on each
                    vertex that make up a triangle are interpolated across the triangle. *shouldn't* be a problem
                    since each vertex should have the same VeinType, but this is safer. Interpolation is a black
                    box that can differ for each GPU brand/generation. */
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
                 
                /* _MS_Tex: Metallic+Smoothness/Glossy texture. Instead of RGB colors, the values are how metallic (in the
                    red/x channel) or how smooth/glossy (in the alpha/w channel) this part of the object is. Used later for
                    reflections and lighting.
                    Since there's room and to avoid having another texture, the "clip" value (in the blue/y channel) is also
                    included. Anything with 0 for a clip value is not rendered.
                    */
                float3 mstex = UNITY_SAMPLE_TEX2D(_MS_Tex, uv).xyw;
                
                /* As mentioned above, if the value in _MS_Tex.y is less than the _AlphaClip threshold, stop rendering. */
                if (mstex.y < _AlphaClip - 0.001) discard;
                
                /* _MainTexA, MainTexB: the typical sort of textures that provide the color. In this case, _MainTexA is the
                    crystal and _MainTexB is the dirt/rock texture near the bottom. Split so that amount of dirt shown can be
                    altered. */
                float3 colorA = veinColor.xyz * tex2D(_MainTexA, uv).xyz;
                float4 colorB = tex2D(_MainTexB, uv);
                
                /* _OcclusionTex: Ambient Occlusion texture. I don't understand this well enough to describe it. */
                float2 occTex = tex2D(_OcclusionTex, uv).xw;
                
                /* get the combined color (albedo) from the textures */
                float3 albedo = lerp(colorA.xyz * float3(6.0, 6.0, 6.0), colorB.xyz * float3(1.7, 1.7, 1.7), (1.0 - lodDist) * colorB.w);
                
                /* applying ambient occlusion to the combined color (albedo). Again, I don't understand how this works. */
                albedo = albedo * pow(lerp(1.0, occTex.x, occTex.y), _OcclusionPower);
                
                /* Multiply/exaggerate/boost the albedo with the _AlbedoMultiplier property */
                albedo = albedo.xyz * _AlbedoMultiplier;
                
                /* _NormalTex: basically a "bump map". Uses lighting tricks to make an object seem more 3D by affecting lighting.
                    UnpackNormal() is a built-in function provided by Unity. _NormalMultiplier exaggerates the bump map. */
                float3 unpackedNormal = UnpackNormal(tex2Dbias(_NormalTex, float4(uv, 0, -1)));
                float3 normal = float3(_NormalMultiplier * unpackedNormal.xy, unpackedNormal.z);
                normal.xyz = normalize(normal.xyz);
                
                /* _EmissionTex: defines which part of the object should glow or emit "light". */
                float4 emmTex = tex2Dbias(_EmissionTex, float4(uv,0,-1));
                
                /* _EmissionJitterTex: amount of emission/glow as a function of time. */
                float emmJitTex = UNITY_SAMPLE_TEX2D(_EmissionJitterTex, float2(time, 0)).x;
                
                //Can this object emit/glow, based on if the object is powered and an on/off toggle?
                float canEmit = (int)(emissionPower > 0.1) | (int)(_EmissionSwitch < 0.5) ? 1.0 : 0.0;
                
                /* Calculate how much of the planet's theme/biomo colors should be included, based on how near to the
                    ground the object is.
                    ...I think. I don't understand this part very well, but it's definitely used to add to color/albedo.*/
                float2 g_heightMap = UNITY_SAMPLE_TEXCUBE(_Global_LocalPlanetHeightmap, normalize(worldPos1.xyz)).xy;
                float frac_heightMap = frac(g_heightMap.y);
                float int_heightMap = g_heightMap.y - frac_heightMap;
                float biomoThreshold = (frac_heightMap * frac_heightMap) * (frac_heightMap * -2.0 + 3.0) + int_heightMap;
                float biomoThreshold0 = saturate(1.0 - biomoThreshold);
                float biomoThreshold1 = min(saturate(2.0 - biomoThreshold), saturate(biomoThreshold));
                float biomoThreshold2 = saturate(biomoThreshold - 1);
                float4 biomoColor = biomoThreshold1 * _Global_Biomo_Color1;
                biomoColor = _Global_Biomo_Color0 * biomoThreshold0 + biomoColor;
                biomoColor = _Global_Biomo_Color2 * biomoThreshold2 + biomoColor;
                biomoColor.xyz = biomoColor.xyz * _BiomoMultiplier;
                
                float heightOffset = saturate((_BiomoHeight - (length(worldPos1.xyz) - (g_heightMap.x + _Global_Planet_Radius))) / _BiomoHeight);
                heightOffset = biomoColor.w * pow(heightOffset, 2);
                
                biomoColor.xyz = lerp(biomoColor.xyz, biomoColor.xyz * albedo, _Biomo);
                albedo.xyz = lerp(albedo, biomoColor.xyz, heightOffset);
                
                /* Multiply/exaggerate/boost the metallic and smoothness values from _MS_Tex with the _MetallicMultiplier
                    _MetallicMultiplier and _SmoothMultiplier properties. */
                float metallic = saturate(_MetallicMultiplier * mstex.x);
                float smoothness = saturate(_SmoothMultiplier * mstex.z);
                
                /* calculate emission/glow from the textures and the various properties that control emission. */
                float3 emissionColor = _EmissionMultiplier * emmTex.xyz;
                float2 emmSwitchJitter = float2(_EmissionSwitch, _EmissionJitter) * emmTex.ww;
                float emmIsOn = lerp(1, saturate(veinType), emmSwitchJitter.x);
                emissionColor.xyz = emissionColor.xyz * emmIsOn;
                float jitterRatio = _EmissionSwitch * emmSwitchJitter.y;
                float jitter = lerp(1.0, emmJitTex, jitterRatio);
                emissionColor.xyz = emissionColor.xyz * jitter;
                emissionColor.xyz = emissionColor.xyz * canEmit;
                
                /* reconstruct worldPos from where they were packed into the TBN vectors sent by the vertex shader. */
                float3 worldPos = float3(inp.TBN0.w, inp.TBN1.w, inp.TBN2.w);
                
                /* built-in unity function for applying shadows. "atten" is set to a value between 0 and 1, with 0 being
                    completely in shadow and 1 being no shadows at all.  */
                UNITY_LIGHT_ATTENUATION(atten, inp, worldPos);
                
                /* viewDir: the direction from the object to the camera. Used to calculate things like reflected light */
                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - worldPos.xyz);
                
                /* Using Tangent, Binormal, and Normal from the shader, transform the values from the "bump map" _NormalTex
                    to where the normals are in the world.  */
                float3 worldNormal;
                worldNormal.x = dot(inp.TBN0.xyz, normal.xyz);
                worldNormal.y = dot(inp.TBN1.xyz, normal.xyz);
                worldNormal.z = dot(inp.TBN2.xyz, normal.xyz);
                worldNormal = normalize(worldNormal.xyz);
                
                /* for reasons I don't understand, scale the metallic values to two different scales */
                float metallicLow = metallic * 0.85 + 0.149; //scale metallic from 0.15 to 1.0
                float metallicHigh = metallic * 0.85 + 0.649; //scale metallic from 0.65 to 1.5
                
                /* the opposite of smoothness is roughness, but make it 3% rougher for some reason. */
                float perceptualRoughness = 1 - smoothness * 0.97;
                
                /* lightDir: _WorldSpaceLightPos0 is the direction from the center of the planet (0,0,0) to the star. */
                float3 lightDir = _WorldSpaceLightPos0;
                
                /* halfDir: smart math people have decided that adding the direction of light and view together and using
                    that as the "half" direction is useful for calculating light. */
                float3 halfDir = normalize(viewDir + lightDir);
                
                /* roughness and roughnessSqr: smart math people have decided that roughness^2 and roughness^4 are useful
                    for calculating light. */
                float roughness = perceptualRoughness * perceptualRoughness;
                float roughnessSqr = roughness * roughness;
                
                /* the dot product of a normalized vector and another normalized vector (aka directions) gives us the
                    cosine of the angle between them. That's easy to work with since that means if the two directions
                    point the same way, the value is 1. If the two directions are perpendicular, the value is 0. If they're
                    pointing in opposite directions, -1.
                    All of the xDotX values below are used in calculating lighting.
                    Taking the max(0, value) of this just limits the range between pointing the same direction and
                    perpendicular. */
                /* nDotL: Normal dot LightDir. The angle between the normal (the direction the surface of the triangle
                    is facing) and the direction to the source of light (the star) */
                float unclamped_nDotL = dot(worldNormal, lightDir);
                float nDotL = max(0, unclamped_nDotL);
                
                /* nDotV: Normal dot ViewDir. The angle between the normal and the direction towards the camera */
                float unclamped_nDotV = dot(worldNormal, viewDir);
                float nDotV = max(0, unclamped_nDotV);
                
                /* nDotH: Normal dot HalfDir. The angle between the normal and the direction towards the mysterious "half"
                    direction. */
                float unclamped_nDotH = dot(worldNormal.xyz, halfDir);
                float nDotH = max(0, unclamped_nDotH);
                
                /* vDotH: ViewDir dot HalfDir. The angle between the direction towards the camera and the direction
                    towards the mysterious "half" direction */
                float unclamped_vDotH = dot(viewDir.xyz, halfDir);
                float vDotH = max(0, unclamped_vDotH);
                
                /* upDotL: angle from the object to source of light (the star).
                    1 = star is directly above
                    0 = star is directly perpendicular.
                   -1 = star is on opposite side of the planet */
                float upDotL = dot(upDir.xyz, lightDir.xyz);
                
                /* nDotL: angle from the normal to the upward direction from the object.
                    1 = surface faces directly up
                    0 = surface faces the side
                   -1 = surface faces down*/
                float nDotUp = dot(worldNormal.xyz, upDir.xyz);
                
                /* reflectivity: how reflective is the surface, based on how rough and metallic it is?
                   reflectColor: what should be shown in the reflection? Raytracing is expensive, so fake it with an image
                        of a landscape */
                float reflectivity;
                float3 reflectColor = reflection(perceptualRoughness, metallicLow, upDir, viewDir, worldNormal, /*out*/ reflectivity);
                
                /* sunsetColor: how should the color of light be changed for the oranges and reds produced during a sunset?
                    Based on the position of the sun in the sky, relative to the object.*/
                float3 sunsetColor = float3(1, 1, 1);
                UNITY_BRANCH
                if (upDotL <= 1) {
                  float4 sunAngleThreshold = saturate(float4(5, 10, 5, 5) * (float4(-0.2, -0.1, 0.1, 0.3) + upDotL));
                  float3 sunsetColor1 = _Global_SunsetColor1 * float3(1.25, 1.25, 1.25);
                  float3 sunsetColor2 =_Global_SunsetColor2 * float3(1.5, 1.5, 1.5);
                  sunsetColor = upDotL > -0.1 ? lerp(sunsetColor2, sunsetColor1, sunAngleThreshold.z) : sunsetColor2 * sunAngleThreshold.w;
                  sunsetColor = upDotL > 0.1 ? lerp(sunsetColor1, _Global_SunsetColor0, sunAngleThreshold.y) : sunsetColor;
                  sunsetColor = upDotL > 0.2 ? lerp(_Global_SunsetColor0, float3(1, 1, 1), sunAngleThreshold.x) : sunsetColor;
                }
                /* _LightColor0: a property set by the game code for the color of the light coming from the star. Apply the
                    sunset colors calculated above to the star light to get a light color. */
                float3 lightColor = sunsetColor.xyz * _LightColor0.xyz;
                
                /* decrease shadows a bit, depending on where the sun is in the sky. Directly overhead means a weaker shadow,
                    sunrise/sunset means full strength shadows.
                    After that, use 80% of the shadow remaining so nothing is pure black. */
                atten = 0.8 * lerp(atten, 1.0, saturate(upDotL * 0.15));
                lightColor = atten * lightColor.xyz;
                
                /* specularTerm: Getting into complicated lighting calculations. This calculates strength of "specular" light
                    (aka shine/highlights). */
                float specularTerm = GGX(roughness, metallicHigh, nDotH, nDotV, nDotL, vDotH);
                
                /* ambientColor: the color of the ambient light on the planet, based on the position of the star.
                    Star is directly overhead to 33% above perpendicular (aka day) -> _Global_AmbientColor0
                    Star is 33% above perpendicular to perpendicular -> blend from _Global_AmbientColor0 to _Global_AmbientColor1
                    Star is perpendicular to 33% below perpendicular -> blend from _Global_AmbientColor1 to _Global_AmbientColor2
                    Star is below 33% perpendicular (aka night) -> _Global_AmbientColor2
                    */
                float3 ambientColor = lerp(_Global_AmbientColor1, _Global_AmbientColor0, saturate(upDotL * 3.0));
                float3 ambientColor2 = lerp(_Global_AmbientColor2, _Global_AmbientColor1, saturate(upDotL * 3.0 + 1.0));
                ambientColor = upDotL > 0 ? ambientColor : ambientColor2;
                
                /* scale the ambientColor based on the direction of the surface of the object. Unchanged for surfaces facing up
                    and hit by light from the side, stronger when hit by light directly, and weaker for surfaces facing down or
                    for light coming from behind.
                    Further increase the ambientColor with the _AmbientInc property.
                */
                float scaled_nDotUp = saturate(nDotUp * 0.3 + 0.7); //surface facing up = 1.0, side = 0.7, bottom = 0.4
                float cubed_nDotL = pow(unclamped_nDotL * 0.35 + 1, 3); //light pointing directly at surface = 2.46, side = 1, directly behind surface = 0.275
                float3 scaled_ambientColor = cubed_nDotL * (scaled_nDotUp * ambientColor);
                scaled_ambientColor = (_AmbientInc + 1.0) * scaled_ambientColor;
                
                // Calculate mecha headlamp light. Only active during night.
                float3 headlampLight = calculateLightFromHeadlamp(_Global_PointLightPos, upDir, lightDir, worldNormal);
                
                // Add the headlamp light color to the star and shadow light. 
                float3 headlampLightColor = nDotL * lightColor + headlampLight;
                headlampLightColor = albedo * headlampLightColor;
                
                /* specularColor: color of the shine/highlights, depending on how metallic the material is and the color of the
                    light. Then, apply the calculated specular strength. */
                float3 specularColor = _SpecularColor.xyz * lerp(float3(1.0, 1.0, 1.0), albedo.xyz, metallicLow);
                specularColor = specularColor.xyz * lightColor.xyz;
                specularColor = nDotL * (specularTerm + 0.0318) * specularColor.xyz;
                
                /* Not sure what this is doing */
                float3 specColorMod = (1.0 - metallicLow) * 0.2 * albedo.xyz + metallicLow;
                specularColor = specularColor * specColorMod;
                
                /* tint color to the ambient color */
                scaled_ambientColor = albedo.xyz * scaled_ambientColor;
                
                /* tint the reflection to be the ambient color */
                float ambientLuminance = 0.003 + dot(ambientColor.xyx, float3(0.3, 0.6, 0.1));
                float maxAmbient = 0.003 + max(_Global_AmbientColor0.z, max(_Global_AmbientColor0.x, _Global_AmbientColor0.y));
                reflectColor = reflectColor * float3(1.7, 1.7, 1.7) * lerp(ambientLuminance, ambientColor, float3(0.4, 0.4, 0.4)) / maxAmbient;
                float reflectStrength = saturate(upDotL * 2.0 + 0.5) * 0.7 + 0.3;
                reflectColor = reflectColor.xyz * reflectStrength;
                
                /* collect all the calculated color values into our final color for output. */
                float3 finalColor = scaled_ambientColor * (1.0 - metallicLow * 0.6)
                    + headlampLightColor * pow(1.0 - metallicLow, 0.6)
                    + specularColor;
                    
                // add in the reflection based on reflectivity
                finalColor = lerp(finalColor, reflectColor * albedo, reflectivity);
                
                // if the color value is too high (in the HDR range), normalize it.
                float colorIntensity = dot(finalColor.xyz, float3(0.3, 0.6, 0.1));
                finalColor = colorIntensity > 1.0 ? finalColor / colorIntensity * (log(log(colorIntensity) + 1) + 1) : finalColor;
                
                // add in any emission/glow and indirect lighting
                finalColor = emissionColor * _EmissionMask
                    + albedo.xyz * indirectLight
                    + finalColor;
                    
                // output to the screen     
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
            
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "CGIncludes/DSPCommon.cginc"
            
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
                
                float3 tan = float3(0,0,0);
                animateWithVerta(vertexID, time, prepare_length, working_length, /*inout*/ scaledVPos, /*inout*/ scaledVNormal, /*inout*/ tan);
                
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