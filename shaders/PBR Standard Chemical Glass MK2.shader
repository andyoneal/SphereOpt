Shader "VF Shaders/Forward/PBR Standard Chemical Glass MK2" {
    Properties {
        _Color ("Color 颜色", Vector) = (1,1,1,1)
        _RimColor ("Rim Color 颜色", Vector) = (1,1,1,1)
        _RimThickness ("Rim Thickness", Float) = 0.3
        _RimSoftness ("Rim Softness", Float) = 1
        _SpecularColor ("Specular Color", Vector) = (1,1,1,1)
        _FluidTex ("Fluid 贴图", 2D) = "white" {}
        _NormalTex ("Normal 法线", 2D) = "bump" {}
        _DropsTex ("水滴法线", 2D) = "bump" {}
        _Metallic ("金属倍率", Float) = 0.8
        _Smoothness ("高光倍率", Float) = 0.8
        _SpherePos ("球状玻璃位置", Vector) = (-2.55,4.72,0,2.9)
        _SphereThickness ("Sphere Thickness", Float) = 0.07
        [Toggle(_ENABLE_VFINST)] _ToggleVerta ("Enable VFInst ?", Float) = 0
    }
    SubShader {
        LOD 200
        Tags {
            "DisableBatching" = "true" "QUEUE" = "Transparent" "RenderType" = "Transparent"
        }
        GrabPass {
            "_ScreenTexLate"
        }
        Pass {
            Name "FORWARD"
            LOD 200
            Tags {
                "DisableBatching" = "true" "LIGHTMODE" = "FORWARDBASE" "QUEUE" = "Transparent" "RenderType" = "Transparent"
            }
            Blend SrcAlpha OneMinusSrcAlpha, SrcAlpha OneMinusSrcAlpha // Op is Add on both. does it need to say that?
            ColorMask RGB -1 // -1? renderdoc says RGB_
            ZWrite Off
            Stencil {
                Ref 2
                Comp Always
                Pass Replace // back should be keep. does it matter?
                Fail Keep
                ZFail Keep // Zfail?
            }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 5.0
            #pragma enable_d3d11_debug_symbols

            #define _ENABLE_VFINST

            #include "../../../Downloads/builtin_shaders-2018/CGIncludes/UnityCG.cginc"
            #include "../../../Downloads/builtin_shaders-2018/CGIncludes/AutoLight.cginc"
            #include "CGIncludes/DSPCommon.cginc"

            StructuredBuffer<float3> _ScaleBuffer; //t4
            StructuredBuffer<AnimData> _AnimBuffer; //t3
            StructuredBuffer<float> _IdBuffer; // t1
            StructuredBuffer<GPUOBJECT> _InstBuffer; //t0

            float4 _LightColor0;
            float _UseScale;
            int _Mono_Inst;
            float3 _Mono_Pos;
            float4 _Mono_Rot;
            float3 _Mono_Scl;
            float _Mono_Anim_Time;
            float _Mono_Anim_LP;
            float _Mono_Anim_LW;
            int _Mono_Anim_State;
            float _Mono_Anim_Power;
            float4 _Global_AmbientColor0;
            float4 _Global_AmbientColor1;
            float4 _Global_AmbientColor2;
            float4 _Global_SunsetColor0;
            float4 _Global_SunsetColor1;
            float4 _Global_SunsetColor2;
            float4 _RimColor;
            float _RimThickness;
            float _RimSoftness;
            float4 _SpecularColor;
            float _Metallic;
            float _Smoothness;
            float4 _SpherePos;
            float _SphereThickness;
            float4 _ScreenTexLate_TexelSize;
            float3 _Global_SunDir;

            sampler2D _FluidTex;
            sampler2D _NormalTex;
            sampler2D _DropsTex;
            sampler2D _ScreenTexLate;

            float2 SampleNormalTex2D(float2 uv) {
                float3 tex = tex2D(_NormalTex, uv.xy).xyw;
                tex.x = tex.x * tex.z;
                tex.xy = tex.xy * float2(2.0, 2.0) - float2(1.0, 1.0);
                return tex;
            }

            float2 SampleNormalTex2DLOD(float2 uv) {
                float3 tex = tex2Dlod(_NormalTex, float4(uv.xy,0,0)).xyw;
                tex.x = tex.x * tex.z;
                tex.xy = tex.xy * float2(2.0, 2.0) - float2(1.0, 1.0);
                return tex;
            }

            float2 SampleDropsTex2DLOD(float2 uv) {
                float3 tex = tex2Dlod(_DropsTex, float4(uv.xy,0,0)).xyw;
                tex.x = tex.x * tex.z;
                tex.xy = tex.xy * float2(2.0, 2.0) - float2(1.0, 1.0);
                return tex;
            }

            float CalculateProjectedU(float2 rayToRim)
            {
                float minSize = min(abs(rayToRim.y), abs(rayToRim.x)); //r3.w
                float maxSize = max(abs(rayToRim.y), abs(rayToRim.x)); //r4.w
                float ratio = minSize / maxSize; //r3.w
                float ratioSqr = pow(ratio, 2.0); //r4.w
                float fallOff = ratioSqr * (ratioSqr * (ratioSqr * (ratioSqr * 0.0208351 - 0.085133) + 0.180141)
                    - 0.3302995) + 0.999866; //r4.w

                float sizeOne = abs(rayToRim.x) < abs(rayToRim.y) ? UNITY_HALF_PI - 2.0 * fallOff * ratio : 0; //r5.z
                float sizeTwo = rayToRim.x < -rayToRim.x ? UNITY_PI : 0; //r4.w
                float size = ratio * fallOff + sizeOne - sizeTwo; //r3.w

                float minRadius2 = min(rayToRim.y, rayToRim.x); //r4.w
                float maxRadius2 = max(rayToRim.y, rayToRim.x); //r5.x
                size = minRadius2 < -minRadius2 && maxRadius2 >= -maxRadius2 ? -size : size; //r3.w

                return size * UNITY_INV_TWO_PI;
            }
            
            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 TBNW0 : TEXCOORD0; //o1
                float4 TBNW1 : TEXCOORD1; //o2
                float4 TBNW2 : TEXCOORD2; //o3
                float4 worldSpherePos_WL : TEXCOORD3; //o4
                float3 time_state_unk : TEXCOORD4; //o5 // x, z, w not used
                float3 vertPos : TEXCOORD5; //o6
                float4 worldPos_anim : TEXCOORD6; //o7
                float3 worldNormal : TEXCOORD7; //o8
                float4 clipPos : TEXCOORD8; // o9
                float3 o10 : TEXCOORD9; //o10 //z is not used
                float4 indirectLight : TEXCOORD10; //o11
                //UNITY_SHADOW_COORDS(10)
                float4 unused : TEXCOORD13; //o12
            };

            struct fout
            {
                float4 sv_target : SV_Target0;
            };

            v2f vert(appdata_full v, uint vertexID : SV_VertexID, uint instanceID : SV_InstanceID) {
                float4 r0, r1, r4, r6, r7;

                v2f o;

                float objIndex = _Mono_Inst > 0 ? 0 : _IdBuffer[instanceID]; //r0.y

                float objId = _Mono_Inst > 0 ? 0 : _InstBuffer[objIndex].objId; //r0.z
                float3 pos = _Mono_Inst > 0 ? _Mono_Pos : _InstBuffer[objIndex].pos; //r1.xyz
                float4 rot = _Mono_Inst > 0 ? _Mono_Rot : _InstBuffer[objIndex].rot; //r2.xyzw
                
                float time = _Mono_Inst > 0 ? _Mono_Anim_Time : _AnimBuffer[objId].time; //r0.w
                o.worldSpherePos_WL.w = _Mono_Inst > 0 ? _Mono_Anim_LW : _AnimBuffer[objId].working_length;
                uint state = _Mono_Inst > 0 ? _Mono_Anim_State : _AnimBuffer[objId].state; //r0.z

                float3 scale = _Mono_Inst > 0 ? _Mono_Scl : _ScaleBuffer[objIndex]; // r4.xyz
                bool useScale = _UseScale > 0.5; //r3.y

                float3 scaledVertex = useScale ? v.vertex.xyz * scale.xyz : v.vertex.xyz; //r5.xyz
                float3 scaledNormal = useScale ? v.normal.xyz * scale.xyz : v.normal.xyz; //r3.yzw
                float3 scaledTangent = v.tangent.xyz; //r4.yzw

                animateWithVerta(vertexID, time, 1, 2, /*inout*/ scaledVertex, /*inout*/
                                           scaledNormal, /*inout*/ scaledTangent);

                float3 worldPos = rotate_vector_fast(scaledVertex, rot) + pos; //r5.xyz

                o.worldSpherePos_WL.xyz = rotate_vector_fast(_SpherePos, rot) + pos;

                float3 worldNormal = rotate_vector_fast(scaledNormal, rot); //r6.xyz
                float3 worldTangent = rotate_vector_fast(scaledTangent, rot); //r0.yx + r1.x

                float animTime = pow(min(1.0, sin(1.796 * _Time.y) * 0.5 + 0.501), 0.4); // repeat every ~3.5 sec //r1.y
                animTime = pow(animTime, 2.0) * (3.0 - 2.0 * animTime);
                animTime = pow(animTime, 2.0) * (3.0 - 2.0 * animTime);
                animTime = state ? animTime : 0; //r1.y
                animTime = animTime <= 0.0000001 ? 0.8000002 * animTime + 0.599999 : 0.8000002 * animTime + 4.6; //r1.y
                o.worldPos_anim.w = animTime - _SpherePos.y;

                worldNormal = normalize(worldNormal.xyz); //r1.yzw

                o.time_state_unk.y = (uint)state;

                float4 worldPos2 = mul(unity_ObjectToWorld, float4(worldPos, 1)); //r2.xyzw

                float4 clipPos = mul(unity_MatrixVP, worldPos2); //r3.xyzw

                r4.x = -unity_MatrixV[0].x;
                r4.y = -unity_MatrixV[1].x;
                r4.z = -unity_MatrixV[2].x;
                r4.xyz = normalize(r4.xyz);
                
                r6.x = -unity_MatrixV[0].y;
                r6.y = -unity_MatrixV[1].y;
                r6.z = -unity_MatrixV[2].y;
                r6.xyz = normalize(r6.xyz);

                o.o10.x = dot(r4.xyz, worldNormal);
                o.o10.y = dot(r6.xyz, worldNormal);
                
                r7.x = -unity_MatrixV[0].z;
                r7.y = -unity_MatrixV[1].z;
                r7.z = -unity_MatrixV[2].z;
                r7.xyz = normalize(r7.xyz);
                
                float3 camToPos = normalize(worldPos.xyz - _WorldSpaceCameraPos.xyz); //r4.xyz
                o.o10.z = dot(r7.xyz, camToPos.xyz);

                float3 worldNormal2 = UnityObjectToWorldNormal(worldNormal); //r4.xyz

                r6.xyz = unity_ObjectToWorld[1].yzx * r0.xxx;
                r0.xyz = unity_ObjectToWorld[0].yzx * r0.yyy + r6.xyz;
                r0.xyz = unity_ObjectToWorld[2].yzx * r1.xxx + r0.xyz;
                worldTangent = normalize(r0.xyz); //r0.xyz

                r6.xyz = worldNormal2.yzx * worldTangent.yzx - worldNormal2.zxy * worldTangent.xyz;
                float3 worldBinormal = r6.xyz * unity_WorldTransformParams[9].w * v.tangent.w; //r6.xyz

                o.indirectLight.xyz = ShadeSH9(float4(worldNormal2, 1.0));


                o.pos.xyzw = clipPos.xyzw;
                o.TBNW0.x = worldTangent.z;
                o.TBNW0.y = worldBinormal.x;
                o.TBNW0.z = worldNormal2.x;
                o.TBNW0.w = worldPos2.x;
                o.TBNW1.x = worldTangent.x;
                o.TBNW1.y = worldBinormal.y;
                o.TBNW1.z = worldNormal2.y;
                o.TBNW1.w = worldPos2.y;
                o.TBNW2.x = worldTangent.y;
                o.TBNW2.y = worldBinormal.z;
                o.TBNW2.z = worldNormal2.z;
                o.TBNW2.w = worldPos2.z;
                o.worldPos_anim.xyz = worldPos.xyz;
                o.clipPos.xyzw = clipPos.xyzw;
                o.unused.xyzw = float4(0, 0, 0, 0);
                o.time_state_unk.x = time;
                o.time_state_unk.z = 1116;
                o.vertPos.xyz = v.vertex.xyz;
                o.worldNormal.xyz = worldNormal.xyz;
                return o;
            }
            
            fout frag(v2f i) {
                fout o;

                float3 worldSpherePos = i.worldSpherePos_WL.xyz;
                float3 worldPos = i.worldPos_anim.xyz;
                float animTime = i.worldPos_anim.w;
                float working_length = i.worldSpherePos_WL.w;
                float state = i.time_state_unk.y; // 0 or 1

                bool isGlassDome = i.vertPos.y > 4.0; //r0.x

                float glassPart = isGlassDome ? 0.0 : (i.vertPos.x > 2.0 ? 5.0 : (i.vertPos.z > 1.5 ? 2.0 : 3.0)); //r0.y
                //isGlassDome == 0
                //isCurvedGlass == 5
                //isFlatSidePanel == 2
                //else?? == 3
                float glassPartUInt = (uint)glassPart; //r0.z

                float2 fluidTexUV;
                fluidTexUV.x = (working_length / 512.0) + (1.0 / 1024);
                fluidTexUV.y = (0.5 + glassPartUInt) / 16.0; //r1.y
                float3 recipeColor = tex2Dlod(_FluidTex, float4(fluidTexUV.xy, 0, 0)).xyz; //r1.xyz

                float3 upDir = normalize(worldSpherePos); //r2.xyz //8.10814, 16.81796, 3.36858
                float distCamToPos = distance(_WorldSpaceCameraPos.xyz, worldPos); // r0.w // //27.68412
                float3 dirCamToPos = normalize(worldPos - _WorldSpaceCameraPos.xyz); //r4.xyz //(-0.73602, 0.24321, 0.63177)
                float scaleByDistFromCam = min(1.6, pow(max(1, distCamToPos / 20.0), 0.2)); // 1.06719
                // 0 to 20 = 1.0
                // 20 to about 210 = log up from 1.0 to 1.6
                // 210 and later = 1.6

                float3 waterColor = float3(1,1,1);
                float rimVisibility = 1.0;
                float3 sphereNormal = upDir.xyz;
                float2 drops = float2(0, 0); //r10.yz
                float animWaterHeight = animTime;
                float scaleDiamOffset = 1.0;
                float alpha = 1.0;
                float rimAngle = 1.0;
                float2 rayCentToRim = float2(0, 0);
                float sphereHasThickAndAboveCenter = state;

                if (isGlassDome)
                {
                    float outerSphereRadius = 0.5 * _SpherePos.w; // r2.w // 1.335
                    float innerSphereRadius = 0.5 * (_SpherePos.w - _SphereThickness); //r3.z // 1.3

                    float3 camToSpherePos = worldSpherePos - _WorldSpaceCameraPos.xyz; //r5.xyz // -21.3801, 7.58517, 17.90562
                    float projSpherePosOnPos = dirCamToPos * dot(dirCamToPos, camToSpherePos); // dirCamToPos * 28.89306
                    float viewedDistFromCenter = distance(camToSpherePos, projSpherePosOnPos); //r5.xyz // sqrt(dot(0.1143, -0.55816, 0.34805)) = 0.66765
                    
                    viewedDistFromCenter = outerSphereRadius < viewedDistFromCenter ? outerSphereRadius : viewedDistFromCenter; //r4.w
                    float outerSphereRadiusOffset = sqrt(0.0001 + pow(outerSphereRadius, 2.0) - pow(viewedDistFromCenter, 2.0)); //r2.w //1.1561 = sqrt(outerSphereRadius^2 - 0.44575^2)
                    
                    viewedDistFromCenter = innerSphereRadius < viewedDistFromCenter ? innerSphereRadius : viewedDistFromCenter;
                    float innerSphereRadiusOffset = sqrt(0.0001 + pow(innerSphereRadius, 2.0) - pow(viewedDistFromCenter, 2.0)); //r4.w // // 1.1155

                    float3 rayCamtoOuterPos = projSpherePosOnPos - dirCamToPos * outerSphereRadiusOffset; //-20.41488, 6.74583, 17.52328 ??
                    float3 rayCamToInnterPos = projSpherePosOnPos - dirCamToPos * innerSphereRadiusOffset;
                    float3 camToPosDir = normalize(rayCamtoOuterPos); //r5.xyz // -0.73602, 0.24321, 0.63177
                    sphereNormal = normalize(rayCamtoOuterPos - camToSpherePos); //r6.xyz //106.06351, 62.38314, -164.54601 -> 0.96522, -0.83934, -0.38234
                    float3 rayFromCenterToRim = rayCamToInnterPos - camToSpherePos; //r7.xyz //106.03362, 62.39302, -164.52036 -> 0.93533, -0.82946, -0.35669??

                    float3 up = float3(0, 1, 0);
                    float3 yAxisTransform = upDir.xyz;
                    float3 xAxisTransform = normalize(cross(upDir, up));
                    float3 zAxisTransform = cross(xAxisTransform, yAxisTransform);

                    float3 tmp;
                    tmp.x = dot(rayFromCenterToRim.xyz, xAxisTransform.xyz);
                    tmp.y = dot(rayFromCenterToRim.xyz, yAxisTransform.xyz);
                    tmp.z = dot(rayFromCenterToRim.xyz, zAxisTransform.xyz);
                    rayFromCenterToRim = tmp; //r8.xyz

                    float sphereHeightOffsetFromCenter = rayFromCenterToRim.y; 

                    float3 rotatedCamToPosDir; //r7.xyz
                    rotatedCamToPosDir.x = dot(camToPosDir.xyz, xAxisTransform.xyz);
                    rotatedCamToPosDir.y = dot(camToPosDir.xyz, yAxisTransform.xyz);
                    rotatedCamToPosDir.z = dot(camToPosDir.xyz, zAxisTransform.xyz);

                    float animHeight = sphereHeightOffsetFromCenter - animTime; //r3.w

                    alpha = saturate((outerSphereRadius - viewedDistFromCenter) * (800.0 / distCamToPos)); //r0.w
                    alpha = sphereHeightOffsetFromCenter < -innerSphereRadius ? 0 : alpha; //alpha?

                    float projU = CalculateProjectedU(rayFromCenterToRim.xy); //r0.w
                    float sphereRadiusAtHeight = saturate(length(rayFromCenterToRim.xz) - 0.2); //r3.z

                    float3 waterTexUV; //r11.xyz
                    waterTexUV.x = projU - (_Time.y / 2.0);
                    waterTexUV.y = sphereHeightOffsetFromCenter / 5.0;
                    float normalTexOne = SampleNormalTex2DLOD(waterTexUV.xy).y;
                    waterTexUV.x = projU + (_Time.y / 4.0);
                    //waterTexUV.y = sphereHeight / 5.0;
                    float normalTexTwo = SampleNormalTex2DLOD(waterTexUV.xy).y;
                    float normalTex = normalTexOne + normalTexTwo; //r5.w
                    
                    animWaterHeight = normalTex * sphereRadiusAtHeight * 0.13 + animHeight;
                    
                    if (animHeight > 0)
                    {
                        float2 adjustedRayFromCenterToRim = rotatedCamToPosDir.xz * 2.0 * innerSphereRadiusOffset + rayFromCenterToRim.xz; //r10.yz
                        float projUDrops = CalculateProjectedU(adjustedRayFromCenterToRim.xy); //r7.w
                        float adjustedDistFromCenterXZ = saturate(length(adjustedRayFromCenterToRim.xy) - 0.2); //r10.y

                        float2 dropsUV; //r11.xy
                        dropsUV.x = projU * 5.0;
                        dropsUV.y = (animHeight + _Time.y) / 10.0;
                        float2 dropsOne = SampleDropsTex2DLOD(dropsUV.xy); //r10.zw
                        dropsOne.xy = dropsOne.xy * sphereRadiusAtHeight * saturate(2.0 - sphereHeightOffsetFromCenter);

                        dropsUV.x = projUDrops * 5.0;
                        //dropsUV.y = (animHeight + _Time.y) / 10.0;
                        float2 dropsTwo = SampleDropsTex2DLOD(dropsUV.xz); //r11.xy
                        dropsTwo.xy = dropsTwo.xy * adjustedDistFromCenterXZ;
                        drops = dropsOne.xy + dropsTwo.xy;

                        float dropsAnimTime = max(0, cos(_Time.y * 0.898 + 1.7));
                        drops = drops * dropsAnimTime * saturate(1.0 - animHeight);
                    }
                    
                    float3 viewDir = -camToPosDir;
                    float viewAngle = dot(viewDir, upDir.xyz); //r5.x
                    bool viewFromAbove = viewAngle > 0.00001; //r5.y
                    float3 adjustedRayFromCenterToRim;
                    float innerSphereDiamOffset = innerSphereRadiusOffset * 2.0;
                    float outerSphereDiamOffset = outerSphereRadiusOffset * 2.0;
                    if (viewFromAbove)
                    {
                        float adjustedOffset = (innerSphereDiamOffset - (animWaterHeight / viewAngle)) * 0.3 + (animWaterHeight / viewAngle); //r11.w
                        adjustedRayFromCenterToRim = rotatedCamToPosDir.xyz * adjustedOffset + rayFromCenterToRim.xyz; //r5.xyz
                        
                        rayCentToRim.xy = adjustedRayFromCenterToRim.xy;
                        
                        sphereHasThickAndAboveCenter = innerSphereDiamOffset < adjustedOffset ? 0 : 1.0; //r7.x
                        sphereHasThickAndAboveCenter = animWaterHeight > 0 ? sphereHasThickAndAboveCenter : 1.0;
                    
                        scaleDiamOffset = innerSphereDiamOffset < adjustedOffset ? 0 : 0.05 + saturate(2.0 * (innerSphereDiamOffset - adjustedOffset)); //r7.y
                        scaleDiamOffset = animWaterHeight > 0 ? scaleDiamOffset : 1.0;
                    }
                    else
                    {
                        adjustedRayFromCenterToRim = rayFromCenterToRim.xyz; //r5.xyz
                        
                        rayCentToRim.xy = rayFromCenterToRim.xy;
                        sphereHasThickAndAboveCenter = innerSphereDiamOffset < outerSphereDiamOffset ? 0 : 1.0; //r7.x
                        sphereHasThickAndAboveCenter = animWaterHeight > 0 ? sphereHasThickAndAboveCenter : 1.0;
                    
                        scaleDiamOffset = innerSphereDiamOffset < outerSphereDiamOffset ? 0 : 0.05 + saturate(2.0 * (innerSphereDiamOffset - outerSphereDiamOffset)); //r7.y
                        scaleDiamOffset = animWaterHeight > 0 ? scaleDiamOffset : 1.0;
                    }
                    
                    if (sphereHasThickAndAboveCenter != 0)
                    {
                        
                        float2 adjustedRayFromCenterToRim2 = animWaterHeight > 0 ? adjustedRayFromCenterToRim.xz : rayFromCenterToRim.xz; //r5.xy
                        float adjustedRadiusAtHeight = length(adjustedRayFromCenterToRim2.xy); //r2.w
                        float projU2 = CalculateProjectedU(adjustedRayFromCenterToRim2);
                        float heightOffsetFromCenter = animWaterHeight > 0 ? rayCentToRim.y : sphereHeightOffsetFromCenter; //r7.z

                        float2 waterUVOne;
                        waterUVOne.x = projU2 - 0.5 * _Time.y; //r8.x
                        waterUVOne.y = 0.7 * heightOffsetFromCenter - projU2; //r8.y

                        float2 waterUVTwo;
                        waterUVTwo.x = projU2 + 0.49 * adjustedRadiusAtHeight - 0.3 * _Time.y; //r11.x
                        waterUVTwo.y = 0.21 * adjustedRadiusAtHeight + 0.3 * _Time.y; //r11.y
                        
                        float2 waterUV = animWaterHeight < 0 ? waterUVOne.xy : waterUVTwo.xy; //r5.xy
                        float2 waterTex = SampleNormalTex2DLOD(waterUV.xy);
                        rayCentToRim.xy = waterTex.xy * min(1.0, 2.0 * adjustedRadiusAtHeight);
                    }

                    rimAngle = pow(outerSphereRadiusOffset, 2.0) / scaleByDistFromCam;
                    rimVisibility = saturate(_RimSoftness * (rimAngle - _RimThickness)); //r3.w
                    waterColor.xyz = recipeColor;
                }
                else
                {
                    float3 worldNormal = normalize(i.worldNormal.xyz); //r11.xyz
                    float nDotV = dot(-dirCamToPos, worldNormal.xyz); //r4.x

                    if ((int)glassPart == 1)
                    {
                        float2 waterUV; //r11.xy
                        waterUV.x = 0.5 * i.vertPos.z - 0.5 * i.vertPos.x;
                        waterUV.y = 0.5 * i.vertPos.y - _Time.y;
                        float waterY = SampleNormalTex2D(waterUV.xy).y; //r4.w

                        waterUV.x = 0.5 * i.vertPos.x + 0.2 * i.vertPos.z + 0.1 * _Time.y;
                        waterUV.y = 0.2 * i.vertPos.z - 0.2 * i.vertPos.y - 0.3 * _Time.y;
                        float2 waterTex = SampleNormalTex2D(waterUV); //r11.xy
                        rayCentToRim.xy = waterTex.xy * (0.2 * scaleByDistFromCam) - float2(0.3, 0.3) * i.o10.xy;
                        
                        waterY = saturate(waterY * saturate(5.0 * (3.65 - i.vertPos.y)) + 1.15); //r4.y
                        waterColor.xyz = lerp(recipeColor * float3(3, 3, 3) + float3(4, 4, 4), recipeColor, waterY);
                        
                        rimAngle = saturate(1.2 * nDotV);
                        rimVisibility = saturate(2.0 * _RimSoftness * (rimAngle - 0.6 * _RimThickness)); //r3.w
                    }
                    else
                    {
                        if ((int)glassPart == 2)
                        {
                            recipeColor.xyz = float3(1, 1, 1); //fluidTex?
                            sphereHasThickAndAboveCenter = 0;
                        }
                        else
                        {
                            if ((int)glassPart == 5) //curved glass
                            {

                                float2 fluidCurvedUV; //r11.xy
                                fluidCurvedUV.x = (working_length / 512.0) + (1.0 / 1024.0);
                                fluidCurvedUV.y = (7.0 / 32.0);
                                float3 curvedWaterColor = tex2Dlod(_FluidTex, float4(fluidCurvedUV.xy, 0, 0)).xyz; //r4.yzw

                                float2 waterCurvedUV; //r12.xy
                                waterCurvedUV.x = i.vertPos.x * 0.13 + _Time.y * 0.6;
                                waterCurvedUV.y = i.vertPos.z * 0.2 + i.vertPos.y * 1.2;
                                float2 waterTex = SampleNormalTex2DLOD(waterCurvedUV.xy);
                                
                                curvedWaterColor = lerp(recipeColor, curvedWaterColor, saturate(waterTex.y * 0.8 + 0.3));
                                curvedWaterColor = curvedWaterColor * (float3(10, 10, 10) - float3(9, 9, 9) * saturate(waterTex.y + 1.3));

                                float2 waterCurvedUV2;
                                waterCurvedUV2.x = i.vertPos.y * 0.8 - i.vertPos.z * 0.3;
                                waterCurvedUV2.y = i.vertPos.x * 0.3 - _Time.y * 0.7;
                                float waterY = SampleNormalTex2D(waterCurvedUV2.xy).y;
                                
                                float3 adjustedCurvedWaterColor = curvedWaterColor * float3(4, 4, 4) + float3(3, 3, 3); //r11.xyz
                                float waterHorzOffset = saturate((i.vertPos.y * 0.5 + 1.5) - i.vertPos.x); //r5.w
                                curvedWaterColor = lerp(adjustedCurvedWaterColor, curvedWaterColor, saturate(waterY * waterHorzOffset + 1.2));
                                curvedWaterColor = saturate(waterTex.y * waterTex.x - 0.1) * float3(210, 120, 300) + curvedWaterColor;
                                waterColor.xyz = curvedWaterColor * waterHorzOffset + curvedWaterColor;

                                float2 waterCurvedUV3; //r11.xy
                                waterCurvedUV3.x = i.vertPos.x * 0.2 + _Time.y * 0.8;
                                waterCurvedUV3.y = i.vertPos.z * 0.3 + i.vertPos.y;
                                float2 waterTexCurved = SampleNormalTex2D(waterCurvedUV3.xy);
                                rayCentToRim.xy = waterTexCurved.xy * 0.5 * scaleByDistFromCam + float2(0.1, 0.1) * i.o10.xy;
                                
                                rimAngle = saturate(1.2 * nDotV);
                                rimVisibility = saturate(2.0 * _RimSoftness * (rimAngle - _RimThickness * 0.6));
                            }
                            else
                            {
                                waterColor.xyz = recipeColor.xyz; // fluidTex?
                            }
                        }
                    }
                }

                float2 animScaleFactor;
                if (isGlassDome)
                {
                    animScaleFactor = pow(scaleDiamOffset, 2.0) * float2(0.16, 0.16) * rayCentToRim.xy + (1.0 - scaleDiamOffset) * (drops.xy / 5.0);
                    animScaleFactor = animWaterHeight < 0
                        ? animScaleFactor + pow(scaleDiamOffset, 2.0) * float2(0.7, 0.7) * i.o10.xy
                        : animScaleFactor + pow(scaleDiamOffset, 2.0) * float2(0, -0.1);
                }
                else
                {
                    animScaleFactor = float2(0.5, 0.5) * rayCentToRim.xy;
                }
                
                float screenAspectRatio = _ScreenTexLate_TexelSize.z / _ScreenTexLate_TexelSize.w;
                animScaleFactor.y = animScaleFactor.y * screenAspectRatio;
                
                float2 screenTexCoordsUV;
                float4 clipPos = i.clipPos;
                screenTexCoordsUV.x = 0.5 * clipPos.x + 0.5 * clipPos.w;
                screenTexCoordsUV.y = 0.5 * clipPos.w - 0.5 * clipPos.y;
                screenTexCoordsUV.xy = (state * animScaleFactor + screenTexCoordsUV.xy) / clipPos.ww;
                screenTexCoordsUV.xy = (clipPos.ww * screenTexCoordsUV.xy) / clipPos.ww;
                float3 screenTex = tex2D(_ScreenTexLate, screenTexCoordsUV.xy).xyz; //r4.xyz
                
                float smoothness = 0.01; //r8.y
                float metallic = 0.01; // r8.x
                float3 albedo = screenTex.xyz; // r7.yzw
                float3 specularColor = float3(0, 0, 0); //r3.xyw
                float rimColor = float3(0,0,0);
                float rimAlpha = 0;
                
                if (alpha > 0.001)
                {
                    bool isProducing = state > 0.5;
                    if (isProducing)
                    {
                        float fluidTex2UV;
                        fluidTex2UV.x = (working_length / 512.0) + (1.0 / 1024.0);
                        fluidTex2UV.y = (19.0 / 32.0);
                        float3 fluidTex2 = tex2Dlod(_FluidTex, float4(fluidTex2UV.xy, 0, 0)).xyz; //r5.xzw

                        float glassFactor = 0.03;

                        if(isGlassDome)
                        {
                            fluidTex2 = lerp(waterColor, fluidTex2, saturate(rayCentToRim.y));
                            
                            albedo = lerp(_RimColor.xxx, float3(1.2, 1.2, 1.2) - saturate(1.0 - animWaterHeight) * (float3(1.2, 1.2, 1.2) + fluidTex2), rimVisibility);
                            smoothness = _Smoothness;
                            
                            float colorFactor = 4.0 * saturate(1.0 - (50.0 * abs(animWaterHeight) / scaleByDistFromCam)); //r10.x
                            colorFactor = colorFactor + saturate(1.0 - animWaterHeight); //r3.y
                            rimColor = float3(0.2, 0.2, 0.2) * fluidTex2 * colorFactor * min(1, 10 * rimVisibility);
                            glassFactor = saturate((rayCentToRim.y * 0.5 + 0.5) * (animWaterHeight - 50.0)) * 0.14 + 0.08; //r0.x
                        }
                        else
                        {
                            fluidTex2 = waterColor.xyz;
                            
                            albedo = lerp(waterColor.xxx, float3(1.2, 1.2, 1.2) - state * (float3(1.2, 1.2, 1.2) + waterColor), rimVisibility);
                            smoothness = (int)glassPart == 2 ? 0.5 : _Smoothness;
                            
                            float sunAngle = min(1.0, 0.1 + saturate(0.3 + dot(upDir.xyz, _Global_SunDir.xyz))); //r4.w
                            rimColor = float3(0.2, 0.2, 0.2) * waterColor * state * sunAngle * min(1, 10 * rimVisibility);
                        }
                        
                        float3 glassAndFluid = fluidTex2 * (screenTex * float3(2.5, 2.5, 2.5) + glassFactor); //r5.xyz
                        screenTex.xyz = lerp(screenTex, glassAndFluid, sphereHasThickAndAboveCenter * albedo.y);
                        specularColor = _SpecularColor;

                        if ((int)glassPart == 2)
                        {
                            rimAlpha = sphereHasThickAndAboveCenter < 0.5 ? 0.1 : 1.0;
                        }
                        else
                        {
                            rimAlpha = 1.0 - (1.0 - (1.0 - rimVisibility)) * saturate(1.0 - _RimColor.w);
                        }
                    }
                    else
                    {
                        smoothness = 0.7 * _Smoothness;
                        specularColor = float3(0.4, 0.4, 0.4) * _SpecularColor.xyz;
                        screenTex = float3(0.5, 0.5, 0.5) * screenTex;
                        albedo = float3(0.3, 0.3, 0.3);
                        
                        if ((int)glassPart == 2)
                        {
                            rimAlpha = sphereHasThickAndAboveCenter < 0.5 ? 0.1 : 1.0;
                        }
                        else
                        {
                            rimAlpha = 1.0 - (1.0 - (1.0 - rimVisibility)) * saturate(1.0 - _RimColor.w) * 0.2; //r0.w
                        }
                    }
                    
                    metallic = _Metallic;
                }
                
                UNITY_LIGHT_ATTENUATION(atten, inp, worldPos); //r1.w = atten

                float upDotL = dot(upDir.xyz, _WorldSpaceLightPos0.xyz); //r0.y
                float3 sunsetColor = calculateSunlightColor(_LightColor0.xyz, upDotL, _Global_SunsetColor0.xyz, _Global_SunsetColor1.xyz, _Global_SunsetColor2);

                if (alpha < 0.05) discard;

                float3 worldPos_2; //r12.xyz
                worldPos_2.x = i.TBNW0.w;
                worldPos_2.y = i.TBNW1.w;
                worldPos_2.z = i.TBNW2.w;
                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - worldPos_2.xyz); //r13.xyz

                float3 worldNormal; //r5.xyz
                worldNormal.x = i.TBNW0.z;
                worldNormal.y = i.TBNW1.z;
                worldNormal.z = i.TBNW2.z;
                worldNormal.xyz = normalize(worldNormal.xyz); //r5.xyz

                float metallicLow = saturate(metallic * 0.85 + 0.149); //r4.w
                float perceptualRoughness = saturate(1.0 - smoothness * 0.97); //r5.w

                float3 halfDir = normalize(viewDir.xyz + _WorldSpaceLightPos0.xyz); //r8.xyz

                float roughness = pow(perceptualRoughness, 2.0); //r0.w

                worldNormal.xyz = glassPartUInt < 0.5 ? sphereNormal.xyz : worldNormal.xyz;
                float unclamped_nDotL = dot(worldNormal.xyz, _WorldSpaceLightPos0.xyz); //r6.x
                float nDotV = max(0, dot(worldNormal.xyz, viewDir.xyz)); //r6.z
                float nDotL = max(0, unclamped_nDotL); //r6.y
                float nDotH = max(0, dot(worldNormal.xyz, halfDir.xyz)); //r8.w
                float vDotH = max(0, dot(viewDir.xyz, halfDir.xyz)); //r8.x
                float nDotUp = dot(worldNormal.xyz, upDir.xyz); // r8.y

                float reflectivity; //r5.x
                float3 reflectColor = reflection(perceptualRoughness, metallicLow, upDir, viewDir, worldNormal, /*out*/ reflectivity); //r5.yzw

                float reflectLum = dot(reflectColor, float3(0.3, 0.6, 0.1)); //r8.z
                reflectColor = (reflectLum - upDir * reflectivity) * float3(0.5, 0.5, 0.5) + reflectColor;
                reflectColor = sphereHasThickAndAboveCenter ? sqrt(reflectColor) : reflectColor;
                reflectColor = float3(0.5,0.5,0.5) * reflectColor * (1.0 + recipeColor);
                
                atten = lerp(atten, 1.0, saturate(0.15 * upDotL));
                float3 lightColor = (0.8 * atten) * sunsetColor.xyz; //r5.yzw

                float metallicHigh = 0.5 + metallicLow; //r7.x
                float specularTerm = GGX(roughness, metallicHigh, nDotH, nDotV, nDotL, vDotH); //r0.w * r1.w
                
                float3 ambientLowSun = lerp(_Global_AmbientColor1.xyz, _Global_AmbientColor0.xyz, saturate(upDotL * 3.0)); //r12.xyz
                float3 ambientTwilight = lerp(_Global_AmbientColor2.xyz, _Global_AmbientColor1.xyz, saturate(upDotL * 3.0 + 1.0)); //r13.xyz
                float3 ambientColor = upDotL > 0 ? ambientLowSun : ambientTwilight; //r12.xyz
                
                float3 ambientLightColor = ambientColor.xyz * saturate(nDotUp * 0.3 + 0.7); //r8.xyz
                ambientLightColor = ambientLightColor * pow(unclamped_nDotL * 0.35 + 1.0, 3.0); //r6.xzw
                
                specularColor = specularColor * lightColor * lerp(float3(1, 1, 1), albedo, metallicLow) * float3(0.5, 0.5, 0.5); //r3.xyw
                specularColor = specularColor * nDotL * (specularTerm + INV_TEN_PI);
                
                float3 specColorMod = 0.2 * (1.0 - metallicLow) * albedo + metallicLow; //r5.yzw
                specularColor = specularColor * specColorMod; //r3.xyw
                
                ambientLightColor = ambientLightColor * albedo * (1.0 - metallicLow * 0.6); // r5.yzw
                
                float3 recipeLightColor;
                if(isGlassDome)
                {
                    float somethingStateRelated = alpha > 0.0001 ? (isGlassDome ? saturate(1.0 - animWaterHeight) : state) : 0.0;
                    float lightAngle = pow(somethingStateRelated, 8.0) * saturate(1.0 - (0.4 + upDotL) * 3.0); //r0.w // somethingStateRelated altered in last if statement
                    float rimLightFactor = min(1.0, (1.0 - abs(saturate(_RimSoftness * rimAngle) - 0.5)) * nDotH); //r0.w
                    float3 rimLight = _RimColor.xyz * (pow(rimLightFactor, 10) * 8.0 + 1.2); //r13.xyz
                    recipeLightColor = lerp(rimLight, 25.0 * recipeColor, lightAngle); //r1.xyz    
                }
                else
                {
                    recipeLightColor = float3(0.15, 0.15, 0.15) * recipeColor; //r1.xyz
                }

                rimVisibility = saturate(_RimSoftness * (rimAngle - _RimThickness)); //r1.w
                float ambientColorLum = 0.003 + dot(ambientColor.xyx, float3(0.3, 0.6, 0.1)); // r0.w
                float maxAmbient = 0.003 + max(_Global_AmbientColor0.z, max(_Global_AmbientColor0.x, _Global_AmbientColor0.y)); //r3.z
                reflectColor = reflectColor * float3(1.7, 1.7, 1.7) * lerp(ambientColorLum, ambientColor, 0.4) / maxAmbient;
                float reflectStrength = saturate(upDotL * 2.0 + 0.5) * 0.7 + 0.3; //r0.y
                reflectColor = reflectColor * reflectStrength * lerp(albedo, float3(1, 1, 1), rimVisibility);

                float ambientLightLum = dot(ambientLightColor, float3(0.3, 0.6, 0.1)); //r0.z
                float3 finalColor = nDotL * lightColor * albedo * pow(1.0 - metallicLow, 0.6) + specularColor + ambientLightLum; //r0.yzw
                finalColor = lerp(finalColor, reflectColor, reflectivity); //r0.yzw

                sunsetColor = saturate(sunsetColor + float3(0.5, 0.5, 0.5)); //r2.xyz
                specularColor = saturate(specularColor * float3(0.2, 0.2, 0.2) - float3(0.05, 0.05, 0.05)); //r3.xyz
                finalColor = lerp(recipeLightColor * sunsetColor + specularColor, finalColor, min(1.0, 0.9 + rimVisibility));
                finalColor = lerp(screenTex, finalColor, rimAlpha);

                float luminance = dot(finalColor, float3(0.3, 0.6, 0.1)); //r0.w
                float3 normalizedColor = finalColor / luminance;
                float logLum = log(log(luminance) + 1.0) + 1.0;
                finalColor = luminance > 1.0 ? normalizedColor * logLum : finalColor;
                finalColor = i.indirectLight.xyz * albedo + finalColor;

                o.sv_target.xyz = finalColor + rimColor;
                o.sv_target.w = alpha;

                return o;
            }
            ENDCG
        }
    }
    Fallback "Diffuse"
}