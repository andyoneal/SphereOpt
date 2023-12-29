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
            //StructuredBuffer<VertaData> _VertaBuffer; //t2 //floats in the code
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

            

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 TBNW0 : TEXCOORD0; //o1
                float4 TBNW1 : TEXCOORD1; //o2
                float4 TBNW2 : TEXCOORD2; //o3
                float4 worldSpherePos_power : TEXCOORD3; //o4
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

            v2f vert(appdata_full v, uint vertexID : SV_VertexID, uint instanceID : SV_InstanceID)
            {
                float4 r0, r1, r4, r6, r7;

                v2f o;

                float objIndex = _Mono_Inst > 0 ? 0 : _IdBuffer[instanceID]; //r0.y

                float objId = _Mono_Inst > 0 ? 0 : _InstBuffer[objIndex].objId; //r0.z
                float3 pos = _Mono_Inst > 0 ? _Mono_Pos : _InstBuffer[objIndex].pos; //r1.xyz
                float4 rot = _Mono_Inst > 0 ? _Mono_Rot : _InstBuffer[objIndex].rot; //r2.xyzw

                float time = _Mono_Inst > 0 ? _Mono_Anim_Time : _AnimBuffer[objId].time; //r0.w
                float prepare_length = _Mono_Inst > 0 ? _Mono_Anim_LP : _AnimBuffer[objId].prepare_length; //r3.y
                float working_length = _Mono_Inst > 0 ? _Mono_Anim_LW : _AnimBuffer[objId].working_length; //r3.x
                uint state = _Mono_Inst > 0 ? _Mono_Anim_State : _AnimBuffer[objId].state; //r0.z
                o.worldSpherePos_power.w = _Mono_Inst > 0 ? _Mono_Anim_Power : _AnimBuffer[objId].power;

                float3 scale = _Mono_Inst > 0 ? _Mono_Scl : _ScaleBuffer[objIndex]; // r4.xyz
                bool useScale = _UseScale > 0.5; //r3.y

                float3 scaledVertex = useScale ? v.vertex.xyz * scale.xyz : v.vertex.xyz; //r5.xyz
                float3 scaledNormal = useScale ? v.normal.xyz * scale.xyz : v.normal.xyz; //r3.yzw
                float3 scaledTangent = v.tangent.xyz; //r4.yzw

                animateWithVerta(vertexID, time, prepare_length, working_length, /*inout*/ scaledVertex, /*inout*/
                                           scaledNormal, /*inout*/ scaledTangent);

                float3 worldPos = rotate_vector_fast(scaledVertex, rot) + pos; //r5.xyz

                o.worldSpherePos_power.xyz = rotate_vector_fast(_SpherePos, rot) + pos;

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


                r7.x = -unity_MatrixV[0].z;
                r7.y = -unity_MatrixV[1].z;
                r7.z = -unity_MatrixV[2].z;
                r7.xyz = normalize(r7.xyz);

                o.o10.x = dot(r4.xyz, worldNormal);
                o.o10.y = dot(r6.xyz, worldNormal);

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
            
            fout frag(v2f i)
            {
                float4 r0, r1, r2, r3, r4, r5, r7, r8, r9, r10, r11, r12, r13;

                fout o;

                float3 worldSpherePos = i.worldSpherePos_power.xyz;
                float3 worldPos = i.worldPos_anim.xyz;
                float animTime = i.worldPos_anim.w;
                float power = i.worldSpherePos_power.w;

                bool isGlassDome = i.vertPos.y > 4.0; //r0.x

                float glassPart = i.vertPos.y > 4.0 ? 0 : i.vertPos.x > 2.0 ? 5.0 : i.vertPos.z > 1.5 ? 2.0 : 3.0; //r0.y
                //isGlassDome == 0
                //isCurvedGlass == 5
                //isFlatSidePanel == 2
                //else?? == 3
                float glassPartUInt = (uint)glassPart; //r0.z

                float2 fluidTexUV;
                fluidTexUV.x = power / 512.0 + (1.0 / 1024); // (2.0 * i.worldSpherePos_power.w + 1.0) / 1024.0 //r1.x
                fluidTexUV.y = (0.5 + glassPartUInt) / 16.0; //r1.y
                float3 fluidTex = tex2Dlod(_FluidTex, float4(fluidTexUV.xy, 0, 0)).xyz; //r1.xyz

                float3 upDir = normalize(worldSpherePos); //r2.xyz

                float3 camToPos = worldPos - _WorldSpaceCameraPos.xyz; //r4.xyz
                float distCamToPos = length(camToPos); // r0.w
                float3 dirCamToPos = camToPos / distCamToPos; //r4.xyz

                float lodScaleFactor = min(1.6, pow(max(1, distCamToPos / 20.0), 0.2)); // 5th sqrt //r1.w

                float3 waterColor = float3(1,1,1);

                float somethingRimRelated = 1.0;

                if (isGlassDome)
                {
                    float outerSphereRadius = 0.5 * _SpherePos.w; // r2.w
                    float innerSphereRadius = 0.5 * (_SpherePos.w - _SphereThickness); //r3.z

                    float3 camToSpherePos = worldSpherePos - _WorldSpaceCameraPos.xyz; //r5.xyz
                    float viewedDistFromCenter = distance(camToSpherePos, dirCamToPos * dot(dirCamToPos, camToSpherePos)); //r5.xyz
                    
                    viewedDistFromCenter = outerSphereRadius < viewedDistFromCenter.xyz ? outerSphereRadius : viewedDistFromCenter.xyz; //r4.w
                    float outerSphereRadiusOffset = sqrt(0.0001 + pow(outerSphereRadius, 2.0) - pow(viewedDistFromCenter, 2.0)); //r2.w
                    float rimStrengthUNK = saturate((outerSphereRadius - viewedDistFromCenter) * (800.0 / distCamToPos)); //r0.w
                    
                    viewedDistFromCenter = innerSphereRadius < viewedDistFromCenter ? innerSphereRadius : viewedDistFromCenter;
                    float innerSphereRadiusOffset = sqrt(0.0001 + pow(innerSphereRadius, 2.0) - pow(viewedDistFromCenter, 2.0)); //r4.w
                    
                    float3 camToPosDir = normalize(dirCamToPos * dot(dirCamToPos, camToSpherePos) - dirCamToPos * outerSphereRadiusOffset); //r5.xyz
                    float fromCenterDir = normalize((dirCamToPos * dot(dirCamToPos, camToSpherePos) - dirCamToPos * outerSphereRadiusOffset) - camToSpherePos); //r6.xyz
                    float3 rayFromCenterToRim = dirCamToPos * dot(dirCamToPos, camToSpherePos) - dirCamToPos * innerSphereRadiusOffset - camToSpherePos; //r7.xyz

                    float3 up = float3(0, 1, 0);
                    float3 yAxisTransform = upDir.xyz;
                    float3 xAxisTransform = normalize(cross(yAxisTransform, up));
                    float3 zAxisTransform = cross(xAxisTransform, yAxisTransform);

                    float3 tmp;
                    tmp.x = dot(rayFromCenterToRim.xyz, xAxisTransform.xyz);
                    tmp.y = dot(rayFromCenterToRim.xyz, yAxisTransform.xyz);
                    tmp.z = dot(rayFromCenterToRim.xyz, zAxisTransform.xyz);
                    rayFromCenterToRim = tmp; //r8.xyz

                    float3 rotatedCamToPosDir; //r7.xyz
                    rotatedCamToPosDir.x = dot(camToPosDir.xyz, xAxisTransform.xyz);
                    rotatedCamToPosDir.y = dot(camToPosDir.xyz, yAxisTransform.xyz);
                    rotatedCamToPosDir.z = dot(camToPosDir.xyz, zAxisTransform.xyz);

                    float waterHeight = rayFromCenterToRim.y - animTime; //r3.w
                    
                    r9.w = rayFromCenterToRim.y < -innerSphereRadius ? 0 : rimStrengthUNK; //alpha?

                    float minSizeSphere = min(abs(rayFromCenterToRim.z), abs(rayFromCenterToRim.x)); //r0.w
                    float maxSizeSphere = max(abs(rayFromCenterToRim.z), abs(rayFromCenterToRim.x)); //r3.z
                    float sphereRatio = minSizeSphere / maxSizeSphere; //r0.w

                    float sphereRatioSqr = pow(sphereRatio, 2.0); //r3.z
                    float sphereFallOff = sphereRatioSqr * (sphereRatioSqr * (sphereRatioSqr * (sphereRatioSqr * 0.0208351 - 0.085133) + 0.180141) -
                        0.3302995) + 0.999866; // from 1 to 0.7854096 //r3.z

                    r5.w = abs(rayFromCenterToRim.x) < abs(rayFromCenterToRim.z) ? UNITY_HALF_PI - 2.0 * sphereFallOff * sphereRatio : 0;
                    r3.z = rayFromCenterToRim.x < -rayFromCenterToRim.x ? UNITY_PI : 0;
                    r0.w = sphereRatio * sphereFallOff + r5.w - r3.z;
                    r3.z = min(rayFromCenterToRim.z, rayFromCenterToRim.x);
                    r5.w = max(rayFromCenterToRim.z, rayFromCenterToRim.x);
                    r0.w = r3.z < -r3.z && r5.w >= -r5.w ? -r0.w : r0.w;

                    r3.z = saturate(length(rayFromCenterToRim.xz) - 0.2);

                    r11.x = r0.w * UNITY_INV_TWO_PI + 0.25 * _Time.y;
                    r11.y = r0.w * UNITY_INV_TWO_PI - 0.5 * _Time.y;
                    r11.z = 0.2 * rayFromCenterToRim.y;
                    float normalTexOne = tex2Dlod(_NormalTex, float4(r11.yz, 0, 0)).y; //r5.w
                    float normalTexTwo = tex2Dlod(_NormalTex, float4(r11.xz, 0, 0)).y; //r6.w
                    float normalTex = normalTexTwo * 2.0 + normalTexOne * 2.0 - 1.0; //r5.w

                    float2 drops = float2(0, 0);
                    if (waterHeight > 0)
                    {
                        float invWaterHeight = saturate(1.0 - waterHeight); //r6.w

                        r10.yz = rotatedCamToPosDir.xz * 2.0 * innerSphereRadiusOffset + rayFromCenterToRim.xz;
                        
                        float minSize = min(abs(r10.z), abs(r10.y)); //r7.w
                        float maxSize = max(abs(r10.z), abs(r10.y)); // 1/r10.w
                        float ratio = minSize / maxSize; // r7.w
                        float ratioSqr = pow(ratio, 2.0); //r10.w
                        float fallOff = ratioSqr * (ratioSqr * (ratioSqr * (ratioSqr * 0.0208351 - 0.085133) + 0.180141)
                            - 0.3302995) + 0.999866; //r10.w

                        r11.x = abs(r10.y) < abs(r10.z) ? UNITY_HALF_PI - 2.0 * fallOff * ratio : 0;
                        r10.w = r10.y < -r10.y ? UNITY_PI : 0;
                        r7.w = ratio * fallOff + r11.x - r10.w;

                        r10.w = min(r10.z, r10.y);
                        r11.x = max(r10.z, r10.y);
                        r7.w = r10.w < -r10.w && r11.x >= -r11.x ? -r7.w : r7.w;

                        r10.y = saturate(length(r10.yz) - 0.2);

                        r11.x = r7.w * 5.0 * UNITY_INV_TWO_PI;
                        r11.y = r0.w * 5.0 * UNITY_INV_TWO_PI;
                        r11.z = 0.1 * waterHeight + 0.1 * _Time.y;
                        float3 dropsOne = tex2Dlod(_DropsTex, float4(r11.yz, 0, 0)).xyw; //r12.xyz
                        dropsOne.x = dropsOne.x * dropsOne.z;
                        dropsOne.xy = dropsOne.xy * float2(2, 2) - float2(1, 1); //r10.zw
                        dropsOne.xy = dropsOne.xy * r3.zz * invWaterHeight * saturate(2.0 - rayFromCenterToRim.y);

                        float3 dropsTwo = tex2Dlod(_DropsTex, float4(r11.xz, 0, 0)).xyw; //r11.xyz
                        dropsTwo.x = dropsTwo.x * dropsTwo.z;
                        dropsTwo.xy = dropsTwo.xy * float2(2, 2) - float2(1, 1);
                        dropsTwo.xy = dropsTwo.xy * r10.yy * invWaterHeight;

                        float dropsAnimTime = max(0, cos(_Time.y * 0.898 + 1.7)); // repeats every 7 seconds //r0.w
                        drops = dropsAnimTime * (drops.xy + dropsTwo.xy);
                    }

                    r0.w = (normalTex - 1.0) * r3.z * 0.13 + waterHeight;
                    r3.z = saturate(1.0 - r0.w);
                    
                    float viewAngle = dot(-camToPosDir.xyz, upDir.xyz); //r5.x
                    bool viewFromAbove = viewAngle > 0.00001; //r5.y
                    
                    r11.w = (innerSphereRadiusOffset * 2.0 - (r0.w / viewAngle)) * 0.3 + (r0.w / viewAngle);
                    r5.xyz = viewFromAbove ? rotatedCamToPosDir.xyz * r11.www + rayFromCenterToRim.xyz : rayFromCenterToRim.xyz;
                    r5.w = viewFromAbove ? r11.w : outerSphereRadiusOffset * 2.0;
                    
                    r7.x = innerSphereRadiusOffset * 2.0 < r5.w ? 0 : 1.0;
                    r7.y = innerSphereRadiusOffset * 2.0 < r5.w ? 0 : 0.05 + saturate(2.0 * (innerSphereRadiusOffset * 2.0 - r5.w));
                    r7.z = r5.y;
                    r7.xyz = r0.w > 0 ? r7.xyz : float3(1, 1, rayFromCenterToRim.y);

                    //r6.xyz = normalize(r6.xyz);

                    float2 normal = float2(0, 0);
                    if (r7.x != 0)
                    {
                        r5.xy = r0.w > 0 ? r5.zx : rayFromCenterToRim.zx;

                        r2.w = length(r5.xy);

                        float minSize = min(abs(r5.x), abs(r5.y)); //r3.w
                        float maxSize = max(abs(r5.x), abs(r5.y)); //r4.w
                        float ratio = minSize / maxSize; //r3.w
                        float ratioSqr = pow(ratio, 2.0); //r4.w
                        float fallOff = ratioSqr * (ratioSqr * (ratioSqr * (ratioSqr * 0.0208351 - 0.085133) + 0.180141)
                            - 0.3302995) + 0.999866; //r4.w

                        r5.z = abs(r5.y) < abs(r5.x) ? UNITY_HALF_PI - 2.0 * fallOff * ratio : 0;
                        r4.w = r5.y < -r5.y ? UNITY_PI : 0;
                        r3.w = ratio * fallOff + r5.z - r4.w;

                        r4.w = min(r5.x, r5.y);
                        r5.x = max(r5.x, r5.y);
                        r3.w = r4.w < -r4.w && r5.x >= -r5.x ? -r3.w : r3.w;

                        r8.x = r3.w * UNITY_INV_TWO_PI - 0.5 * _Time.y;
                        r8.y = r7.z * 0.7 - UNITY_INV_TWO_PI * r3.w;
                        r11.x = r3.w * UNITY_INV_TWO_PI + 0.49 * r2.w - _Time.y * 0.3;
                        r11.y = 0.21 * r2.w + _Time.y * 0.3;
                        r5.xy = r0.w < 0 ? r8.xy : r11.xy;
                        
                        float3 normalTex2 = tex2Dlod(_NormalTex, float4(r5.xy, 0, 0)).xyw;  //r5.xyz
                        normal.x = normalTex2.x * normalTex2.z;
                        normal.xy = normal.xy * float2(2, 2) - float2(1, 1);
                        normal.xy = normal.xy * min(1, 2.0 * r2.w);
                    }

                    r2.w = pow(outerSphereRadiusOffset, 2.0) / lodScaleFactor;
                    somethingRimRelated = saturate(_RimSoftness * (r2.w - _RimThickness)); //r3.w
                    waterColor.xyz = fluidTex;
                }
                else
                {
                    float3 worldNormal = normalize(i.worldNormal.xyz); //r11.xyz

                    float nDotV = dot(-dirCamToPos, worldNormal.xyz); //r4.x

                    if ((int)glassPart == 1)
                    {
                        r11.x = i.vertPos.z * 0.5 - 0.5 * i.vertPos.x;
                        r11.y = i.vertPos.y * 0.5 - _Time.y;
                        r4.w = tex2D(_NormalTex, r11.xy).y;
                        r4.w = r4.w * 2.0 - 1.0;

                        r11.x = _Time.y * 0.1 + 0.5 * i.vertPos.x + 0.2 * i.vertPos.z;
                        r11.y = (i.vertPos.z * 0.2 - 0.3 * _Time.y) - i.vertPos.y * 0.2;
                        r11.xyz = tex2D(_NormalTex, r11.xy).xyw;
                        r11.x = r11.x * r11.z;
                        r4.yz = r11.xy * float2(2, 2) - float2(1, 1);
                        
                        r5.xy = r4.yz * (0.2 * lodScaleFactor) - float2(0.3, 0.3) * i.o10.xy;
                        
                        r4.y = saturate(r4.w * saturate(5 * (3.65 - i.vertPos.y)) + 1.15);
                        waterColor.xyz = lerp(fluidTex * float3(3, 3, 3) + float3(4, 4, 4), fluidTex, r4.y);
                        
                        r2.w = saturate(1.2 * nDotV);
                        
                        somethingRimRelated = saturate(2.0 * (r2.w - _RimThickness * 0.6) * _RimSoftness); //r3.w
                        
                        r7.x = i.time_state_unk.y;
                    }
                    else
                    {
                        if ((int)glassPart == 2)
                        {
                            r1.xyz = float3(1, 1, 1); //fluidTex?
                            waterColor.xyz = float3(1, 1, 1);
                            r7.x = 0;
                            r5.xy = float2(0, 0);
                            r2.w = 1;
                            somethingRimRelated = 1;
                        }
                        else
                        {
                            if ((int)glassPart == 5)
                            {
                                r11.x = (power / 512.0) + (1.0 / 1024.0);
                                r11.y = (7.0 / 32.0);
                                r4.yzw = tex2Dlod(_FluidTex, float4(r11.xy, 0, 0)).xyz;

                                r12.x = i.vertPos.x * 0.13 + 0.6 * _Time.y;
                                r12.y = dot(i.vertPos.zy, float2(0.2, 1.2));
                                float3 normalTex = tex2Dlod(_NormalTex, float4(r12.xy, 0, 0)).xyz; //r12.xyz
                                normalTex.x = normalTex.x * normalTex.z;
                                r12.x = normalTex.y * 2.0 + 0.3;
                                r12.y = normalTex.x * 2.0 - 1.0;
                                r12.z = normalTex.y * 2.0 - 1.0;

                                r5.w = saturate((i.vertPos.y * 0.5 + 1.5) - i.vertPos.x);

                                r13.x = i.vertPos.y * 0.8 - 0.3 * i.vertPos.z;
                                r13.y = i.vertPos.x * 0.3 - 0.7 * _Time.y;
                                r5.z = tex2D(_NormalTex, r13.xy).y;
                                r5.z = r5.z * 2.0 - 1.0;

                                r4.yzw = lerp(r1.xyz, r4.yzw, saturate(r12.z * 0.8 + 0.3));

                                r11.x = i.vertPos.x * 0.2 + 0.8 * _Time.y;
                                r11.y = i.vertPos.z * 0.3 + i.vertPos.y;
                                r11.xyz = tex2D(_NormalTex, r11.xy).xyw;
                                r11.x = r11.x * r11.z;
                                r7.zw = r11.xy * float2(2, 2) - float2(1, 1);

                                r4.yzw = r4.yzw * float3(10, 10, 10) - r4.yzw * float3(9, 9, 9) * saturate(r12.x);
                                r11.xyz = r4.yzw * float3(4, 4, 4) + float3(3, 3, 3);
                                r4.yzw = lerp(r11.xyz, r4.yzw, saturate(r5.z * r5.w + 1.2));
                                r4.yzw = saturate(r12.z * r12.y - 0.1) * float3(210, 120, 300) + r4.yzw;

                                waterColor.xyz = (1.0 + r5.w) * r4.yzw;
                                r5.xy = r7.zw * 0.5 * lodScaleFactor + float2(0.1, 0.1) * i.o10.xy;
                                r2.w = saturate(1.2 * nDotV);
                                somethingRimRelated = saturate(dot(r2.w - _RimThickness * 0.6, _RimSoftness));
                            }
                            else
                            {
                                waterColor.xyz = r1.xyz; // fluidTex?
                                r5.xy = float2(0, 0);
                                r2.w = 1;
                                somethingRimRelated = 1;
                            }
                            r7.x = i.time_state_unk.y;
                        }
                    }
                    
                    fromCenterDir.xyz = upDir.xyz;
                    r10.yz = float2(0, 0);
                    r0.w = animTime;
                    r7.y = 1;
                    r3.z = i.time_state_unk.y;
                    r9.w = 1;
                }

                r4.yz = r0.w < 0 ? float2(0.7, 0.7) * i.o10.xy : float2(0, -0.1);
                r4.yz = r5.xy * float2(0.16, 0.16) + r4.yz;

                r10.x = saturate(((lodScaleFactor / 50.0) - abs(r0.w)) * (50.0 / lodScaleFactor));
                r10.yz = pow(r7.y, 2.0) * r4.yz + (1.0 - r7.y) * (r10.yz / 5.0);
                r11.x = 0;
                r11.yz = float2(0.5, 0.5) * r5.xy;
                r10.xyz = isGlassDome ? r10.xyz : r11.xyz;
                r10.w = r10.z * (_ScreenTexLate_TexelSize.z / _ScreenTexLate_TexelSize.w);

                r3.x = (0.5 * (i.clipPos.x + i.clipPos.w)) / i.clipPos.w;
                r3.y = (0.5 * (i.clipPos.w - i.clipPos.y)) / i.clipPos.w;
                r3.xy = (i.clipPos.ww * (((i.time_state_unk.yy * r10.yw) / i.clipPos.ww) + r3.xy)) / i.clipPos.ww; //wtf
                float3 screenTex = tex2D(_ScreenTexLate, r3.xy).xyz; //r4.xyz

                float smoothness = 0.01; //r8.y
                float metallic = 0.01; // r8.x
                float3 albedo = r4.xyz; // r7.yzw
                float3 specularColor = float3(0, 0, 0); //r3.xyw
                if (r9.w > 0.001)
                {
                    r1.w = 1.0 - somethingRimRelated;
                    
                    if (i.time_state_unk.y > 0.5)
                    {
                        float fluidTex2UV;
                        fluidTex2UV.x = power * (1.0 / 512.0) + (1.0 / 1024.0);
                        fluidTex2UV.y = (19.0 / 32.0);
                        float3 fluidTex2 = tex2Dlod(_FluidTex, float4(fluidTex2UV.xy, 0, 0)).xyz; //r5.xzw
                        fluidTex2 = lerp(waterColor.xyz, fluidTex2, saturate(r5.y));
                        fluidTex2 = isGlassDome ? fluidTex2 : waterColor.xyz;
                        
                        r3.y = isGlassDome ? _RimColor.x : waterColor.x;
                        albedo = lerp(r3.yyy, float3(1.2, 1.2, 1.2) - r3.zzz * (float3(1.2, 1.2, 1.2) + fluidTex2), somethingRimRelated);

                        smoothness = (int)glassPart == 2 ? 0.5 : _Smoothness;

                        r3.y = r10.x * 4.0 + r3.z;
                        r4.w = isGlassDome ? 1.0 : min(1.0, 0.1 + saturate(0.3 + dot(upDir.xyz, _Global_SunDir.xyz)));
                        r10.xyz = float3(0.2, 0.2, 0.2) * fluidTex2 * r3.yyy * r4.www * min(1, 10 * somethingRimRelated);
                        
                        r0.x = isGlassDome ? saturate((r5.y * 0.5 + 0.5) * (r0.w - 50.0)) * 0.14 + 0.08 : 0.03;
                        r5.xyz = fluidTex2 * (screenTex.xyz * float3(2.5, 2.5, 2.5) + r0.xxx);
                        r4.xyz = lerp(screenTex.xyz, r5.xyz, r7.x * r7.y);

                        r0.x = 1.0 - saturate(1.0 - _RimColor.w) * (1.0 - r1.w);
                        r0.x = (int)glassPart == 2 ? 1.0 : r0.x;
                        r0.x = r7.x < 0.5 && (int)glassPart == 2 ? 0.1 : r0.x;
                        
                        specularColor.xyz = _SpecularColor.xyz;
                    }
                    else
                    {
                        smoothness = 0.7 * _Smoothness;
                        specularColor.xyz = float3(0.4, 0.4, 0.4) * _SpecularColor.xyz;
                        r4.xyz = float3(0.5, 0.5, 0.5) * r4.xyz;
                        
                        r0.w = 1.0 - (1.0 - r1.w) * saturate(1.0 - _RimColor.w) * 0.2;
                        r0.w = (int)glassPart == 2 ? 1 : r0.w;
                        
                        r0.x = (int)glassPart == 2 && r7.x < 0.5 ? 0.1 : r0.w;
                        
                        albedo = float3(0.3, 0.3, 0.3);
                        r10.xyz = float3(0, 0, 0);
                    }
                    
                    metallic = _Metallic;
                }
                else
                {
                    r1.xyz = float3(0, 0, 0); // fluidTex?
                    r10.xyz = float3(0, 0, 0);
                    r3.z = 0;
                    r0.x = 0;
                }
                
                UNITY_LIGHT_ATTENUATION(atten, inp, worldPos); //r1.w = atten
                //r1.w = saturate(dot(r5.xyzw, unity_OcclusionMaskSelector.xyzw));

                float upDotL = dot(upDir.xyz, _WorldSpaceLightPos0.xyz); //r0.y

                float3 sunsetColor = calculateSunlightColor(_LightColor0.xyz, upDotL, _Global_SunsetColor0.xyz, _Global_SunsetColor1.xyz, _Global_SunsetColor2);

                if (r9.w < 0.05) discard;

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

                worldNormal.xyz = glassPartUInt < 0.5 ? fromCenterDir.xyz : worldNormal.xyz; //r6 == sphereNormal?
                float unclamped_nDotL = dot(worldNormal.xyz, _WorldSpaceLightPos0.xyz); //r6.x
                float nDotV = max(0, dot(worldNormal.xyz, viewDir.xyz)); //r6.z
                float nDotL = max(0, unclamped_nDotL); //r6.y
                
                float nDotH = max(0, dot(worldNormal.xyz, halfDir.xyz)); //r8.w
                float vDotH = max(0, dot(viewDir.xyz, halfDir.xyz)); //r8.x

                float nDotUp = dot(worldNormal.xyz, upDir.xyz); // r8.y

                float reflectivity; //r5.x
                float3 reflectColor = reflection(perceptualRoughness, metallicLow, upDir, viewDir, worldNormal, /*out*/ reflectivity); //r5.yzw

                float reflectLum = dot(reflectColor.xyz, float3(0.3, 0.6, 0.1)); //r8.z
                reflectColor.xyz = (reflectLum - upDir * reflectivity) * float3(0.5, 0.5, 0.5) + reflectColor.xyz;
                reflectColor.xyz = r7.xxx ? float3(1, 1, 1) / rsqrt(reflectColor.xyz) : reflectColor.xyz;
                reflectColor.xyz = lerp(reflectColor.xyz, reflectColor.xyz * r1.xyz, 0.5);
                
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

                r0.w = saturate(_RimSoftness * r2.w);
                r1.w = saturate(_RimSoftness * (r2.w - _RimThickness));
                r2.w = min(1.0, 0.9 + r1.w);
                
                r0.w = min(1, (1.0 - abs(r0.w - 0.5)) * nDotH);
                r13.xyz = _RimColor.xyz * (pow(r0.w, 10) * 8.0 + 1.2);
                r0.w = pow(r3.z, 8.0) * saturate(1.0 - (0.4 + upDotL) * 3.0);
                r1.xyz = glassPartUInt > 0.5 ? float3(0.15, 0.15, 0.15) * r1.xyz : lerp(r13.xyz, 25.0 * r1.xyz, r0.w);
                
                float ambientLightLum = dot(ambientLightColor, float3(0.3, 0.6, 0.1)); //r0.z
                
                float ambientColorLum = 0.003 + dot(ambientColor.xyx, float3(0.3, 0.6, 0.1)); // r0.w
                float maxAmbient = 0.003 + max(_Global_AmbientColor0.z, max(_Global_AmbientColor0.x, _Global_AmbientColor0.y)); //r3.z
                reflectColor.xyz = reflectColor.xyz * float3(1.7, 1.7, 1.7) * lerp(ambientColorLum, ambientColor.xyz, 0.4) / maxAmbient;
                float reflectStrength = saturate(upDotL * 2.0 + 0.5) * 0.7 + 0.3; //r0.y
                reflectColor.xyz = reflectColor.xyz * reflectStrength;
                
                r0.yzw = nDotL * lightColor * albedo * pow(1.0 - metallicLow, 0.6) + specularColor + ambientLightLum;

                r5.yzw = lerp(albedo, float3(1, 1, 1), r1.www);
                r0.yzw = lerp(r0.yzw, reflectColor.xyz * r5.yzw, reflectivity);

                r2.xyz = saturate(_LightColor0.xyz * sunsetColor.xyz + float3(0.5, 0.5, 0.5));
                r3.xyz = saturate(specularColor * float3(0.2, 0.2, 0.2) - float3(0.05, 0.05, 0.05));
                r0.yzw = lerp(r1.xyz * r2.xyz + r3.xyz, r0.yzw, r2.www);
                r0.xyz = lerp(r4.xyz, r0.yzw, r0.xxx);

                r0.w = dot(r0.xyz, float3(0.3, 0.6, 0.1));
                r1.x = r0.w > 1;
                r1.yzw = r0.xyz / r0.www;
                r0.w = log(log(r0.w) + 1.0) + 1.0;
                r9.xyz = r1.xxx ? r1.yzw * r0.www : r0.xyz;
                
                r0.xyz = i.indirectLight.xyz * albedo;
                r0.w = 0;
                r0.xyzw = r0.xyzw + r9.xyzw;

                o.sv_target.xyz = r0.xyz + r10.xyz;
                o.sv_target.w = r0.w;

                return o;
            }
            ENDCG
        }
    }
    Fallback "Diffuse"
}