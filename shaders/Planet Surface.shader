Shader "VF Shaders/Forward/Planet Surface" {
    Properties {
        _Multiplier ("Multiplier", Float) = 1
        _AmbientInc ("Ambient Increase", Float) = 1
        _Color ("Color", Vector) = (1,1,1,1)
        _BioTex0A ("Bio 0 Albedo", 2D) = "white" {}
        _BioTex0N ("Bio 0 Normal", 2D) = "bump" {}
        _BioTex1A ("Bio 1 Albedo", 2D) = "white" {}
        _BioTex1N ("Bio 1 Normal", 2D) = "bump" {}
        _BioTex2A ("Bio 2 Albedo", 2D) = "white" {}
        _BioTex2N ("Bio 2 Normal", 2D) = "bump" {}
        _BioShift ("Bio Shift", 2D) = "black" {}
        _NormalStrength ("Normal Strength", Float) = 1
        _EmissionStrength ("Emission Strength", Float) = 0
        _BioFuzzStrength ("Bio Fuzz Strength", Range(0, 1)) = 0
        _BioFuzzMask ("Bio Fuzz Mask", Range(-1, 1)) = 1
        _StepBlend ("Step Blend", Float) = 1
        _SunDir ("Sun Dir", Vector) = (0,1,0,0)
        _Rotation ("Rotation ", Vector) = (0,0,0,1)
        _AmbientColor0 ("Ambient Color 0", Vector) = (0,0,0,0)
        _AmbientColor1 ("Ambient Color 1", Vector) = (0,0,0,0)
        _AmbientColor2 ("Ambient Color 2", Vector) = (0,0,0,0)
        _LightColorScreen ("阳光颜色（滤色）", Vector) = (0,0,0,1)
        _Distance ("Distance", Float) = 0
        _Radius ("Radius", Float) = 200
        _HeightEmissionColor ("Height Emission Color", Vector) = (0,0,0,0)
        _HeightEmissionRadius ("Height Emission Radius", Float) = 50
    }
    SubShader {
        LOD 200
        Tags { "DisableBatching" = "true" "RenderType" = "Opaque" "ReplaceTag" = "Terrain Planet" }
        Pass {
            Name "FORWARD"
            LOD 200
            Tags { "DisableBatching" = "true" "LIGHTMODE" = "FORWARDBASE" "RenderType" = "Opaque" "ReplaceTag" = "Terrain Planet" "SHADOWSUPPORT" = "true" }
            GpuProgramID 54138
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma target 5.0
            #pragma multi_compile DIRECTIONAL
            #pragma multi_compile SHADOWS_SCREEN
            #pragma multi_compile LIGHTPROBE_SH
            #include "UnityCG.cginc"
            #include "Autolight.cginc"
            #include "CGIncludes/DSPCommon.cginc"

            float4 _LightColor0;
            float _Multiplier;
            float _AmbientInc;
            float4 _Color;
            float _NormalStrength;
            float _EmissionStrength;
            float _BioFuzzStrength;
            float _BioFuzzMask;
            float _StepBlend;
            float3 _SunDir;
            float4 _Rotation;
            float4 _AmbientColor0;
            float4 _AmbientColor1;
            float4 _AmbientColor2;
            float4 _LightColorScreen;
            float _Distance;
            float4 _HeightEmissionColor;
            float _HeightEmissionRadius;
            float _Global_WhiteMode0;
            float4 _Global_SunsetColor0;
            float4 _Global_SunsetColor1;
            float4 _Global_SunsetColor2;
            float4 _Global_PointLightPos;

            UNITY_DECLARE_TEX2D(_BioShift); //planet tex
            UNITY_DECLARE_TEX2D(_BioTex0A); //sand tex
            UNITY_DECLARE_TEX2D(_BioTex1A); //grass 1 tex
            UNITY_DECLARE_TEX2D(_BioTex2A); //grass 2 tex
            UNITY_DECLARE_TEX2D(_BioTex0N); //sand normal tex
            UNITY_DECLARE_TEX2D(_BioTex1N); //grass 1 tex
            UNITY_DECLARE_TEX2D(_BioTex2N); //grass 2 tex

            struct vin
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float3 color : COLOR;
                float4 unused_v4 : TEXCOORD0;
                float4 bioSelect : TEXCOORD1;
                float4 unused_v6 : TEXCOORD2;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 tbnw0 : TEXCOORD0;
                float4 tbnw1 : TEXCOORD1;
                float4 tbnw2 : TEXCOORD2;
                float3 objectPos : TEXCOORD3; //o4
                float3 worldPos : TEXCOORD4; //o5
                float3 objectNormal : TEXCOORD5; //o6
                float3 objectTangent : TEXCOORD6; //o7
                float3 objectBitangent : TEXCOORD7; //o8 //not used in frag
                float2 bioSelect : TEXCOORD8; //o9 //only x is used in frag
                //x = [0, 200] / 100
                float3 color : TEXCOORD9; //o10 //not used in frag
                float3 ambient : TEXCOORD10; //o11
                //float4 screenPos : TEXCOORD12; //o12 //transfer_shadow? //no texcoord11 because used UNITY_LIGHTING_COORDS
                SHADOW_COORDS(12)
                float4 unk_unused : TEXCOORD11; //o13
            };

            struct fout
            {
                float4 sv_target : SV_Target;
            };


            v2f vert(vin v)
            {
                v2f o;

                float4 clipPos = mul(UNITY_MATRIX_VP, mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1.0))); //r0.xyzw
                o.pos = clipPos;

                float3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz); //r1.xyz

                o.worldPos.xyz = mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1)).xyz;
                float3 worldPos2 = mul(unity_ObjectToWorld, v.vertex.xyzw).xyz; //r3.xyz

                float3 worldNormal = UnityObjectToWorldNormal(v.normal.xyz); //r2.xyz
                float3 worldBitangent = calculateBinormal(float4(worldTangent, v.tangent.w), worldNormal.xyz); //r4.xyz

                //TBNW
                o.tbnw0.x = worldTangent.x; //is tan.x
                o.tbnw0.y = worldBitangent.x; //bitan.x
                o.tbnw0.z = worldNormal.x; //normal.x
                o.tbnw0.w = worldPos2.x; //worldPos.x

                o.tbnw1.x = worldTangent.y;
                o.tbnw1.y = worldBitangent.y;
                o.tbnw1.z = worldNormal.y;
                o.tbnw1.w = worldPos2.y;

                o.tbnw2.x = worldTangent.z;
                o.tbnw2.y = worldBitangent.z;
                o.tbnw2.z = worldNormal.z;
                o.tbnw2.w = worldPos2.z;

                o.objectPos.xyz = v.vertex.xyz; //pos
                o.objectNormal.xyz = v.normal.xyz; //normal
                o.objectTangent.xyz = v.tangent.xyz; //tan

                //bitan
                float3 objectBitangent = cross(v.normal.xyz, v.tangent.xyz); //r1.xyz
                o.objectBitangent.xyz = normalize(objectBitangent.xyz);

                o.bioSelect.xy = v.bioSelect.xy; //uv?
                o.color.xyz = v.color.xyz; //color

                o.ambient.xyz = ShadeSH9(float4(worldNormal,1));

                //o.screenPos.xyzw = computeScreenPos(clipPos); //not sure about cb. is it projectionparams.x?
                TRANSFER_SHADOW(o);

                o.unk_unused.xyzw = float4(0,0,0,0);

                return o;
            }

            fout frag(v2f i)
            {
                fout o;

                //triplanar mapping
                //is this swizzle right?
                float2 planetUV_x = i.objectPos.zy / 25.0; //r0.xy
                float2 planetUV_y = i.objectPos.xz / 25.0; //r0.zw
                float2 planetUV_z = i.objectPos.xy / 25.0; //r1.xy

                //select projection direction with normal
                float3 projDirSelect = saturate(normalize(abs(i.objectNormal.xyz)) - float3(0.5, 0.5, 0.5)); //r2.xyz
                projDirSelect.xyz = saturate(normalize(projDirSelect.xyz) - float3(0.5, 0.5, 0.5));
                projDirSelect /= dot(projDirSelect, 1);; //r2.xyz

                //linear or smoothstep
                float blendFactor = lerp(frac(i.bioSelect.x), pow(frac(i.bioSelect.x), 2) * (3.0 - 2.0 * frac(i.bioSelect.x)), _StepBlend); //r1.z
                //_StepBlend most commonly 1, continuous

                float bioFuzz = saturate(0.5 - abs(blendFactor - 0.5) * (1 - _BioFuzzStrength)); //r2.w
                //_BioFuzzStrength usually 0 but frequently not (especially oceans). highest is 1 (desert9), next highest is 0.37 (ocean6)

                float bioShift_x = UNITY_SAMPLE_TEX2D(_BioShift, planetUV_x).x; //r3.x
                float bioShift_y = UNITY_SAMPLE_TEX2D(_BioShift, planetUV_y).x; //r3.y
                float bioShift_z = UNITY_SAMPLE_TEX2D(_BioShift, planetUV_z).x; //r3.y
                float bioShift = bioShift_x * projDirSelect.x
                               + bioShift_y * projDirSelect.y
                               + bioShift_z * projDirSelect.z;  //r3.x

                //r2.w = r3.x * r2.w;
                float baseBioSelect = (i.bioSelect.x - frac(i.bioSelect.x));
                //0, 1, or 2
                float bioTexSelect = (bioShift - 0.5) * bioFuzz * _BioFuzzMask //adds noise to the transition
                            + baseBioSelect //base level = 0, 1, or 2
                            + blendFactor; //linear or smoothstep transition //r1.z
                //_BioFuzzMask is almost always 1 except for:
                //  desert 5 = -0.759
                //  desert 7 = 0.23
                //  desert 9 = -0.2

                //0 is lowest (sand), 1 is mid (light grass), 2 is top (heavy grass)
                float bioTexSelect0 = saturate(1.0 - bioTexSelect); //r3.x
                float bioTexSelect1 = min(saturate(2.0 - bioTexSelect), saturate(bioTexSelect)); //r1.w
                float bioTexSelect2 = saturate(bioTexSelect - 1.0); //r1.z

                //sample the three textures from the x, y, and z directions. blend together.
                float4 bioTex0A_x = UNITY_SAMPLE_TEX2D(_BioTex0A, planetUV_x).xyzw; //t1 //r4.xyzw
                float4 bioTex1A_x = UNITY_SAMPLE_TEX2D(_BioTex1A, planetUV_x).xyzw; //t2 //r5.xyzw
                float4 bioTex2A_x = UNITY_SAMPLE_TEX2D(_BioTex2A, planetUV_x).xyzw; //t3 //r5.xyzw
                float4 bioTexA_x = bioTex0A_x.xyzw * bioTexSelect0
                                 + bioTex1A_x.xyzw * bioTexSelect1
                                 + bioTex2A_x.xyzw * bioTexSelect2; //r4.xyzw

                float4 bioTex0A_y = UNITY_SAMPLE_TEX2D(_BioTex0A, planetUV_y).xyzw; //t1 //r5.xyzw
                float4 bioTex1A_y = UNITY_SAMPLE_TEX2D(_BioTex1A, planetUV_y).xyzw; //t2 //r6.xyzw
                float4 bioTex2A_y = UNITY_SAMPLE_TEX2D(_BioTex2A, planetUV_y).xyzw; //t3 //r6.xyzw
                float4 bioTexA_y = bioTex0A_y.xyzw * bioTexSelect0
                                 + bioTex1A_y.xyzw * bioTexSelect1
                                 + bioTex2A_y.xyzw * bioTexSelect2; //r5.xyzw

                float4 bioTex0A_z = UNITY_SAMPLE_TEX2D(_BioTex0A, planetUV_z).xyzw; //t1 //r6.xyzw
                float4 bioTex1A_z = UNITY_SAMPLE_TEX2D(_BioTex1A, planetUV_z).xyzw; //t2 //r7.xyzw
                float4 bioTex2A_z = UNITY_SAMPLE_TEX2D(_BioTex2A, planetUV_z).xyzw; //t3 //r7.xyzw
                float4 bioTexA_z = bioTex0A_z.xyzw * bioTexSelect0
                                + bioTex1A_z.xyzw * bioTexSelect1
                                + bioTex2A_z.xyzw * bioTexSelect2;  //r6.xyzw

                float2 bioTex0N_x = UNITY_SAMPLE_TEX2D(_BioTex0N, planetUV_x).yw; //t4 //r3.yz
                bioTex0N_x.xy = bioTex0N_x.xy * float2(2,2) - float2(1, 1); //x * 2 - 1 moves [0,1] to [-1,1] //r3.yz

                float2 bioTex0N_y = UNITY_SAMPLE_TEX2D(_BioTex0N, planetUV_y).yw; //t4 //r7.xy
                bioTex0N_y.xy = bioTex0N_y.xy * float2(2,2) - float2(1, 1); //r7.xy

                float2 bioTex0N_z = UNITY_SAMPLE_TEX2D(_BioTex0N, planetUV_z).yw; //t4 //r7.zw
                bioTex0N_z.xy = bioTex0N_z.xy * float2(2,2) - float2(1, 1); //r7.zw

                float2 bioTex1N_x = UNITY_SAMPLE_TEX2D(_BioTex1N, planetUV_x).yw; //t5 //r8.xy
                bioTex1N_x.xy = bioTex1N_x.xy * float2(2,2) - float2(1, 1); //r8.xy

                float2 bioTex1N_y = UNITY_SAMPLE_TEX2D(_BioTex1N, planetUV_y).yw; //t5 //r8.zw
                bioTex1N_y.xy = bioTex1N_y.xy * float2(2,2) - float2(1, 1); //r8.zw

                float2 bioTex1N_z = UNITY_SAMPLE_TEX2D(_BioTex1N, planetUV_z).yw; //t5 //r9.xy
                bioTex1N_z.xy = bioTex1N_z.xy * float2(2,2) - float2(1, 1); //r9.xy

                float2 bioTex2N_x = UNITY_SAMPLE_TEX2D(_BioTex2N, planetUV_x).yw; //t6 //r0.xy
                bioTex2N_x.xy = bioTex2N_x.xy * float2(2,2) - float2(1, 1); //r0.xy

                float2 bioTex2N_y = UNITY_SAMPLE_TEX2D(_BioTex2N, planetUV_y).yw; //t6 //r0.xy
                bioTex2N_y.xy = bioTex2N_y.xy * float2(2,2) - float2(1, 1); //r0.xy

                float2 bioTex2N_z = UNITY_SAMPLE_TEX2D(_BioTex2N, planetUV_z).yw; //t6 //r0.zw
                bioTex2N_z.xy = bioTex2N_z.xy * float2(2,2) - float2(1, 1); //r0.zw

                float3 bioTexN_x = float3(
                    0,
                    bioTex0N_x.x * bioTexSelect0 + bioTex1N_x.x * bioTexSelect1 + bioTex2N_x.x * bioTexSelect2,
                    bioTex0N_x.y * bioTexSelect0 + bioTex1N_x.y * bioTexSelect1 + bioTex2N_x.y * bioTexSelect2
                ); //r1.xyw

                float3 bioTexN_y = float3(
                    bioTex0N_y.y * bioTexSelect0 + bioTex1N_y.y * bioTexSelect1 + bioTex2N_y.y * bioTexSelect2,
                    0,
                    bioTex0N_y.x * bioTexSelect0 + bioTex1N_y.x * bioTexSelect1 + bioTex2N_y.x * bioTexSelect2
                ); //r8.xyz

                float3 bioTexN_z = float3(
                    bioTex0N_z.y * bioTexSelect0 + bioTex1N_z.y * bioTexSelect1 + bioTex2N_z.y * bioTexSelect2,
                    bioTex0N_z.x * bioTexSelect0 + bioTex1N_z.x * bioTexSelect1 + bioTex2N_z.x * bioTexSelect2,
                    0
                ); //r0.xyz

                float4 albedo = bioTexA_x.xyzw * projDirSelect.xxxx
                              + bioTexA_y.xyzw * projDirSelect.yyyy
                              + bioTexA_z.xyzw * projDirSelect.zzzz; //r3.xyzw

                float3 normal = bioTexN_x.xyz * projDirSelect.xxx
                              + bioTexN_y.xyz * projDirSelect.yyy
                              + bioTexN_z.xyz * projDirSelect.zzz; //r0.xyz
                normal.xyz = normal.xyz * float3(1.5, 1.5, 1.5) + i.objectNormal.xyz;

                float3 objectBitangent = cross(i.objectNormal.xyz, i.objectTangent.xyz); //r1.xyz //recalculate bitangent in frag?
                float3 tangentNormal;
                //isnt this the wrong order for the usual TBN transform? is it moving it TO tangent space instead of from?
                tangentNormal.x = dot(normal.xyz, i.objectTangent.xyz); //r2.x
                tangentNormal.y = dot(normal.xyz, objectBitangent.xyz); //r2.y
                tangentNormal.z = dot(normal.xyz, i.objectNormal.xyz); //r0.x

                //_NormalStrength can be negative (desert1)
                tangentNormal.xy = _NormalStrength * tangentNormal.xy;
                tangentNormal.z = lerp(1.0, max(0.01, tangentNormal.z), saturate(2.0 * _NormalStrength));
                tangentNormal.xyz = normalize(tangentNormal.xyz); //r0.xyz

                // _Rotation is 0 if it's the local planet, otherwise its inverse(localplanet.rotation) [if any] * planet.rotation
                float3 rotatedObjectPos = rotate_vector_fast(i.objectPos, _Rotation); //r5.xyz
                float3 upDir = normalize(rotatedObjectPos.xyz); //r1.xyz

                float3 albedoColor = _Multiplier * _Color.xyz * albedo.xyz; //r4.xyz
                //_Color is always white except for desert9

                float3 emission = albedo.xyz * pow(saturate(1 - albedo.w), 2); //r3.xyz
                //_EmissionStrength is usually 0, except ocean3/ocean6/ocean2=50, volcanic1=60, lava1=70
                float emissionLuminance = dot(_EmissionStrength * emission.xyz, float3(0.3, 0.6, 0.1)); //r0.w
                emission = lerp(emissionLuminance, emission.xyz * _EmissionStrength, 2.0); //r3.xyz

                float heightOffset = _HeightEmissionRadius - length(i.objectPos.xyz); // r0.w
                //_HeightEmissionRadius is almost always 50 except for lava1=199.7 and lava2=200.2
                // that means heightOffset is negative on most planets?
                float emissionHeightFactor = pow(saturate(2.0 - (_Distance / 1000.0)), 2) * pow(saturate(0.4 * heightOffset), 5); //r0.w
                //_Distance is planet to camera

                float3 emissionHeightColor = float3(15, 15, 15) * _HeightEmissionColor.xyz; //r5.xyz
                //_HeightEmissionColor is always black except lava1 and lava2
                float albedoSum = albedoColor.z + albedoColor.x + albedoColor.y; //r1.w
                emission.xyz = lerp(emission.xyz, emissionHeightColor.xyz * albedoSum, emissionHeightFactor); //r3.xyz

                emission.xyz = emission.xyz - _Global_WhiteMode0 * emission.xyz; //r3.xyz
                //_Global_WhiteMode0 is 0 or 1. 1 means blueprint build mode
                //sets emission to black if in blueprint mode

                //r0.w = length(i.worldPos.xyz) > 1000; //used near the bottom

                float3 worldPosFromTBNW; //r5.yzw
                worldPosFromTBNW.x = i.tbnw0.w;
                worldPosFromTBNW.y = i.tbnw1.w;
                worldPosFromTBNW.z = i.tbnw2.w;

                //float atten; //r1.w
                UNITY_LIGHT_ATTENUATION(atten, i, worldPosFromTBNW); //r1.w

                //TBN
                float3 worldNormal;
                worldNormal.x = dot(i.tbnw0.xyz, tangentNormal.xyz);
                worldNormal.y = dot(i.tbnw1.xyz, tangentNormal.xyz);
                worldNormal.z = dot(i.tbnw2.xyz, tangentNormal.xyz);
                worldNormal.xyz = normalize(worldNormal.xyz); //worldNormal? //r0.xyz

                float3 albedoColorWhiteMode = lerp(albedoColor.xyz, float3(0.6, 0.6, 0.6), _Global_WhiteMode0); // sets emission color to grey if in blueprint mode?

                //float3 lightColorMask = float3(1,1,1) - _LightColorScreen.xyz; //r6.xyz

                //use the mask to move sun color closer to white
                //included in sunlightColor()
                //float3 sunLightColor = lerp(_LightColor0.xyz, float3(1,1,1), _LightColorScreen.xyz); //r5.xyz
                //_LightColor0 is sun light color

                //r3.w = pow(r2.w * 0.25 + 1.0, 3); moved down to where it's used
                float3 lightDir = _SunDir;
                float3 nDotL = dot(worldNormal.xyz, lightDir);

                float scaled_nDotL = pow(max(0, nDotL), 0.63); //r2.w
                scaled_nDotL = scaled_nDotL > 0.5 ? 0.5 * (log(log(2.0 * scaled_nDotL) + 1) + 1) : scaled_nDotL; //r2.w

                float upDotL = dot(upDir.xyz, lightDir); //r4.w
                float nDotUp = dot(worldNormal.xyz, upDir.xyz); //r5.w

                float3 sunlightColor = calculateSunlightColor(
                    _LightColor0.xyz,
                    upDotL,
                    _Global_SunsetColor0.xyz,
                    _Global_SunsetColor1.xyz,
                    _Global_SunsetColor2.xyz,
                    _LightColorScreen.xyz); //r5.xyz

                sunlightColor *= scaled_nDotL;

                atten = 0.8 * lerp(atten, 1, saturate(0.15 * upDotL)); //r1.w
                sunlightColor *= atten;

                //_Distance is from planet to camera
                float nightAmbientMod = min(1, 0.4 + max(0, (400.0 - _Distance) / 150.0)); //r6.x
                // transitions from 1 to 0.4 from 310 to 400

                float dayAmbientMod = saturate(0.5 * log(_Distance) - 4.2) * 2.0 + 1.0; //r6.z
                //0 to ~5k = 1
                //~5k to ~32.5k from 1 to 3
                //after ~32.5k = 3

                //why is the conversion to gamma necessary here but not PBR shaders?
                //not using _Global_AmbientColor0. maybe global is already gamma?
                //why are we converting to gamma at all? colors should be in linear right?
                float3 ambientColor0 = pow(_AmbientColor0.xyz, 1.0 / 2.4) * float3(1.055, 1.055, 1.055) - float3(0.055, 0.055, 0.055); //r7.xyz
                ambientColor0 = lerp(ambientColor0 * dayAmbientMod, float3(0.08, 0.08, 0.08), _Global_WhiteMode0);

                float3 ambientColor1 = pow(_AmbientColor1.xyz, 1.0 / 2.4) * float3(1.055, 1.055, 1.055) - float3(0.055, 0.055, 0.055); //r8.xyz
                ambientColor1 = lerp(ambientColor1, float3(0.08, 0.08, 0.08), _Global_WhiteMode0);

                float3 ambientColor2 = pow(_AmbientColor2.xyz, 1.0 / 2.4) * float3(1.055, 1.055, 1.055) - float3(0.055, 0.055, 0.055); //r9.xyz
                ambientColor2 = lerp(ambientColor2 * nightAmbientMod, float3(0.08, 0.08, 0.08), _Global_WhiteMode0); //r6.xzw

                float3 ambientTwilight  = lerp(ambientColor2, ambientColor1, saturate(upDotL * 3.0 + 1.0)); //r6.xyz
                float3 ambientLowSun = lerp(ambientColor1, ambientColor0, saturate(upDotL * 3.0)); //r7.xyz
                float3 ambientColor = upDotL > 0 ? ambientLowSun.xyz : ambientTwilight.xyz; //r6.xyz

                ambientColor.xyz = ambientColor.xyz * saturate(nDotUp * 0.3 + 0.7);
                ambientColor.xyz = ambientColor.xyz * (1 + _AmbientInc); //r6.xyz
                //_AmbientInc is usually 0.5. can be negative (desert10=-0.5)
                ambientColor.xyz = ambientColor.xyz * pow(nDotL * 0.25 + 1.0, 3);

                //float finalColor = (sunLightColor.xyz * worldNDotL) * atten + ambientColor.xyz; //r5.xyz //moved sunlightColor and atten up
                float3 finalColor = sunlightColor + ambientColor; //r5.xyz

                //calculateLightFromHeadlamp
                // except need to add input for lightColor.
                float3 headlampLight = calculateLightFromHeadlamp(_Global_PointLightPos, upDir, lightDir, worldNormal, 0.9); //r0.xyz

                // no light on gas planet? what is this.
                // no light on other planets when on another planet or in space?
                headlampLight.xyz = length(i.worldPos.xyz) > 1000 ? float3(0,0,0) : headlampLight.xyz; //r0.xyz;

                finalColor.xyz = albedoColor.xyz * i.ambient.xyz //color plus ambient light?
                    + (albedoColorWhiteMode.xyz * (finalColor.xyz + headlampLight.xyz)) //color plus ??
                    + emission.xyz; //emission //r0.xyz

                o.sv_target.xyz = finalColor.xyz;
                o.sv_target.w = 1;

                return o;
            }
            ENDCG
        }
    }
    Fallback "Diffuse"
}