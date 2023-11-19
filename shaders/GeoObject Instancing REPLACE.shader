Shader "VF Shaders/Forward/GeoObject Instancing"
{
    Properties
    {
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
    SubShader
    {
        LOD 200
        Tags
        {
            "DisableBatching" = "true" "RenderType" = "Opaque"
        }
        Pass
        {
            Name "FORWARD"
            LOD 200
            Tags
            {
                "DisableBatching" = "true" "LIGHTMODE" = "FORWARDBASE" "RenderType" = "Opaque" "SHADOWSUPPORT" = "true"
            }
            //GpuProgramID 31749
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 5.0
            #pragma enable_d3d11_debug_symbols

            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
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

            v2f vert(appdata_full v, uint instanceID : SV_InstanceID)
            {
                v2f o;

                float3 objectPos = _Size.xyz * v.vertex.xyz; //cb0[33]

                float objId = _InstBuffer[instanceID].objId; //r1.x
                float3 pos = _InstBuffer[instanceID].pos; //r1.yzw

                objectPos = objId < 0.5 ? float3(0, 0, 0) : objectPos; //r0.xyz
                float3 objectNormal = objId < 0.5 ? float3(0, 0, 0) : v.normal.xyz; //r3.xyz
                float3 objectTangent = objId < 0.5 ? float3(0, 0, 0) : v.tangent.xyz; //r4.xyz

                float3 worldPos = objectPos;
                float3 worldNormal = objectNormal;
                float3 worldTangent = objectTangent;
                if (objId > 0.5)
                {
                    float4 rot = _InstBuffer[instanceID].rot; //r5.xyzw
                    worldPos = pos + rotate_vector_fast(objectPos, rot); //r0.xyz
                    worldNormal = rotate_vector_fast(objectNormal, rot); //r6.xyz //r3.xyz
                    worldTangent = rotate_vector_fast(objectTangent, rot); //float3(r1.x, r4.yz);
                }

                worldNormal = normalize(worldNormal); //r1.xyz

                float vertw = objId < 0.5 ? 0 : 1;
                worldPos = mul(unity_ObjectToWorld, float4(worldPos, vertw)); //r0.xyz
                float4 clipPos = mul(unity_MatrixVP, worldPos); //r3.xyzw

                worldNormal = UnityObjectToWorldNormal(worldNormal); //r1.xyz
                worldTangent = UnityObjectToWorldDir(worldTangent.xyz); //r4.xyz
                float tanw = objId < 0.5 ? 0 : v.tangent.w;
                float3 worldBinormal = calculateBinormal(float4(worldTangent, tanw), worldNormal); //r5.xyz

                o.pos.xyzw = clipPos.xyzw;

                o.TBNW0.x = worldTangent.x; //t
                o.TBNW0.y = worldBinormal.x; //b
                o.TBNW0.z = worldNormal.x; //n
                o.TBNW0.w = worldPos.x; //w

                o.TBNW1.x = worldTangent.y;
                o.TBNW1.y = worldBinormal.y;
                o.TBNW1.z = worldNormal.y;
                o.TBNW1.w = worldPos.y;

                o.TBNW2.x = worldTangent.z;
                o.TBNW2.y = worldBinormal.z;
                o.TBNW2.z = worldNormal.z;
                o.TBNW2.w = worldPos.z;

                o.uv_objId.xy = v.texcoord.xy;
                o.uv_objId.zw = uint2(objId, objId); //r2.xy
                o.upDir.xyz = normalize(pos); //updir?
                o.indirectLight.xyz = ShadeSH9(float4(worldNormal, 1.0));
                UNITY_TRANSFER_SHADOW(o, float(0,0))
                o.unused_unk.xyzw = float4(0, 0, 0, 0);

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
                float3 viewDir = normalize(rayPosToCam.xyz); //r2.xyz

                float4 albedo = tex2D(_MainTex, i.uv_objId.xy); //r3.xyzw
                albedo.xyz = _AlbedoMultiplier * albedo.xyz;

                float3 tangentNormal = UnpackNormal(tex2D(_NormalTex, i.uv_objId.xy)); //r5.xyz
                tangentNormal.xy = _NormalMultiplier * tangentNormal.xy; //r5.xyz
                tangentNormal = normalize(tangentNormal); //r5.xyz

                float2 metal_smooth = tex2D(_MS_Tex, i.uv_objId.xy).xw; //r4.zw
                metal_smooth = saturate(float2(_MetallicMultiplier, _SmoothMultiplier) * metal_smooth); //r4.xy

                float3 emission = tex2D(_EmissionTex, i.uv_objId.xy).xyz; //r6.xyz

                float3 premulAlpha = lerp(float3(1, 1, 1), _Color.xyz, saturate(1.25 * (albedo.w - 0.1))); //r7.xyz
                albedo.xyz = albedo.xyz * premulAlpha; //r8.xyz

                //shadow stuff
                // r9.x = cb4[9].z; //unity_MatrixV
                // r9.y = cb4[10].z; //unity_MatrixV
                // r9.z = cb4[11].z; //unity_MatrixV
                // r1.w = dot(r1.xyz, r9.xyz);
                // r9.xyz = -cb3[25].xyz + worldPos; //unity_ShadowFadeCenterAndType
                // r2.w = dot(r9.xyz, r9.xyz);
                // r2.w = sqrt(r2.w);
                // r2.w = r2.w + -r1.w;
                // r1.w = cb3[25].w * r2.w + r1.w; //unity_ShadowFadeCenterAndType
                // r1.w = saturate(r1.w * cb3[24].z + cb3[24].w); //_LightShadowData
                // r2.w = cmp(cb5[0].x == 1.000000);
                // if (r2.w != 0) {
                //     r2.w = cmp(cb5[0].y == 1.000000);
                //     r9.xyz = cb5[2].xyz * i.TBNW1.www;
                //     r9.xyz = cb5[1].xyz * i.TBNW0.www + r9.xyz;
                //     r9.xyz = cb5[3].xyz * i.TBNW2.www + r9.xyz;
                //     r9.xyz = cb5[4].xyz + r9.xyz;
                //     r0.yzw = r2.www ? r9.xyz : worldPos;
                //     r0.yzw = -cb5[6].xyz + r0.yzw;
                //     r9.yzw = cb5[5].xyz * r0.yzw;
                //     r0.y = r9.y * 0.25 + 0.75;
                //     r0.z = cb5[0].z * 0.5 + 0.75;
                //     r9.x = max(r0.y, r0.z);
                //     r9.xyzw = t6.Sample(s0_s, r9.xzw).xyzw;
                // } else {
                //     r9.xyzw = float4(1,1,1,1);
                // }
                // r0.y = saturate(dot(r9.xyzw, cb2[46].xyzw)); //unity_OcclusionMaskSelector
                // r0.zw = v7.xy / v7.ww;
                // r0.z = t4.Sample(s1_s, r0.zw).x;
                // r0.y = r0.y + -r0.z;
                // r0.y = r1.w * r0.y + r0.z;

                UNITY_LIGHT_ATTENUATION(atten, inp, worldPos); //r0.y

                float3 worldNormal;
                worldNormal.x = dot(i.TBNW0.xyz, tangentNormal.xyz);
                worldNormal.y = dot(i.TBNW1.xyz, tangentNormal.xyz);
                worldNormal.z = dot(i.TBNW2.xyz, tangentNormal.xyz);
                worldNormal = normalize(worldNormal); //r5.xyz

                float metallicHigh = metal_smooth.x * 0.85 + 0.649; //r0.z
                float metallicLow = metal_smooth.x * 0.85 + 0.149; //r0.w

                float perceptualRoughness = 1 - metal_smooth.y * 0.97; //r1.w

                float3 lightDir = _WorldSpaceLightPos0.xyz;

                float3 halfDir = normalize(viewDir + lightDir); //r1.xyz

                float roughness = perceptualRoughness * perceptualRoughness; //r0.x
                //float roughnessSqr = roughness * roughness; //r2.w

                float nDotL = dot(worldNormal, lightDir); //r3.w
                float clamped_nDotL = max(0, nDotL); //r4.x
                float nDotV = dot(worldNormal, viewDir); //r4.z
                float clamped_nDotV = max(0, nDotV); //r4.z
                float nDotH = dot(worldNormal, halfDir); //r4.w
                float clamped_nDotH = max(0, nDotH); //r4.w
                float vDotH = dot(viewDir, halfDir); //r1.x
                float clamped_vDotH = max(0, vDotH); //r1.x
                float upDotL = dot(i.upDir, lightDir); //r1.z
                float nDotUp = dot(worldNormal, i.upDir); //r3.w

                // float magSqrUpDir = dot(i.upDir, i.upDir);
                // //rearranged cross()
                // r9.xyz = float3(0,1,0) * i.upDir.yzx;
                // r9.xyz = i.upDir.xyz * float3(1,0,0) - r9.xyz;
                // 
                // r7.w = dot(r9.xy, r9.xy);
                // r7.w = rsqrt(r7.w);
                // r9.xyz = r9.xyz * r7.www;
                // 
                // r9.xyz = magSqrUpDir > 0.01 && i.upDir.y < 0.9999 ? r9.xyz : float3(0,1,0);
                // 
                // r6.w = dot(r9.xy, r9.xy); //magSqr
                // r5.w = magSqrUpDir > 0.01 && r6.w > 0.01 : 0;
                // 
                // //rearranged cross()
                // r10.xyz = i.upDir.yzx * r9.xyz;
                // r10.xyz = r9.zxy * i.upDir.zxy + -r10.xyz;
                // r10.xyz = normalize(r10.xyz);
                // 
                // r6.w = 2 * dot(-r2.xyz, worldNormal);
                // r2.xyz = worldNormal * -r6.www - r2.xyz;
                // 
                // r9.x = dot(r2.zx, -r9.xy);
                // r9.y = dot(r2.xyz, i.upDir.xyz);
                // 
                // r10.xyz = r5.www ? -r10.xyz : float3(-0,-0,-1);
                // r9.z = dot(r2.xyz, r10.xyz);
                // 
                // r5.w = 10 * pow(perceptualRoughness, 0.4);
                // r9.xyz = _Global_PGI.SampleLevel(s2_s, r9.xyz, r5.w).xyz;
                // r1.w = (r0.w * 0.7 + 0.3) * (1 - perceptualRoughness);
                // r9.xyz = r9.xyz * r1.www;

                float reflectivity; //r1.w
                float3 reflectColor = reflection(perceptualRoughness, metallicLow, i.upDir, viewDir, worldNormal,
                                                /*out*/ reflectivity); //r9.xyz

                // if (upDotL <= 1) {
                //     r10.xyzw = saturate(float4(5,10,5,5) * (upDotL + float4(-0.2, -0.1, 0.1, 0.3)));
                //     
                //     r11.xyz = lerp(_Global_SunsetColor0.xyz, float3(1,1,1), r10.xxx);
                //     
                //     r12.xyz = float3(1.25,1.25,1.25) * _Global_SunsetColor1.xyz;
                //     r13.xyz = _Global_SunsetColor0.xyz - _Global_SunsetColor1.xyz * float3(1.25,1.25,1.25);
                //     r12.xyz = r10.yyy * r13.xyz + r12.xyz;
                //     r13.xyz = cmp(float3(0.200000003,0.100000001,-0.100000001) < upDotL);
                //     r14.xyz = float3(1.5,1.5,1.5) * _Global_SunsetColor2.xyz;
                //     r15.xyz = _Global_SunsetColor1.xyz * float3(1.25,1.25,1.25) + -r14.xyz;
                //     r10.xyz = r10.zzz * r15.xyz + r14.xyz;
                //     r14.xyz = r14.xyz * r10.www;
                //     r10.xyz = r13.zzz ? r10.xyz : r14.xyz;
                //     r10.xyz = r13.yyy ? r12.xyz : r10.xyz;
                //     r10.xyz = r13.xxx ? r11.xyz : r10.xyz;
                // } else {
                //     r10.xyz = float3(1,1,1);
                // }
                // r10.xyz = _LightColor0.xyz * r10.xyz;

                float3 sunlightColor = calculateSunlightColor(_LightColor0.xyz, upDotL, _Global_SunsetColor0.xyz,
                                                      _Global_SunsetColor1.xyz, _Global_SunsetColor2.xyz); //r10.xyz

                atten = 0.8 * lerp(atten, 1, saturate(0.15 * upDotL)); //r0.y
                sunlightColor = atten * sunlightColor.xyz; //r10.xyz

                // r0.y = clamped_nDotH * clamped_nDotH;
                // r11.xz = roughness * roughness + float2(-1,1);
                // r0.x = r0.y * r11.x + 1;
                // r0.x = rcp(r0.x);
                // r0.x = r0.x * r0.x;
                // r0.x = r0.x * roughnessSqr;
                // r0.x = 0.25 * r0.x;
                // r0.y = r11.z * r11.z;
                // r2.w = 0.125 * r0.y;
                // r0.y = -r0.y * 0.125 + 1;
                // r4.z = r4.z * r0.y + r2.w;
                // r0.y = clamped_nDotL * r0.y + r2.w;
                // r2.w = r1.x * -5.55472994 + -6.98316002;
                // r1.x = r2.w * r1.x;
                // r1.x = exp2(r1.x);
                // r0.z = (1 - metallicHigh) * r1.x + metallicHigh;
                // r0.x = r0.x * r0.z;
                // 
                // r0.y = rcp(r4.z * r0.y);

                float specularTerm = GGX(roughness, metallicHigh, clamped_nDotH, clamped_nDotV, clamped_nDotL,
                                clamped_vDotH);

                float3 ambientTwilight = lerp(_Global_AmbientColor2.xyz, _Global_AmbientColor1.xyz,
                                saturate(upDotL * 3 + 1)); //r12.xyz
                float3 ambientLowSun = lerp(_Global_AmbientColor1.xyz, _Global_AmbientColor0.xyz,
           saturate(upDotL * 3)); //r11.xyw
                float3 ambientColor = upDotL > 0 ? ambientLowSun : ambientTwilight; //r11.xyw

                float3 ambientLightColor = ambientColor * saturate(nDotUp * 0.3 + 0.7); //r12.xyz
                ambientLightColor = ambientLightColor.xyz * pow(nDotL * 0.35 + 1, 3); //r12.xyz
                ambientLightColor = ambientLightColor * albedo.xyz; //r2.xyz

                //r0.z = _Global_PointLightPos.w >= 0.5;
                //r1.x = length(_Global_PointLightPos.xyz);
                // float distanceFromHeadlamp = length(_Global_PointLightPos.xyz) - 5; //r1.y
                // float headlampVisibility = saturate(distanceFromHeadlamp); //r2.w
                // float daylightDimFactor = saturate(5 * dot(-i.upDir.xyz, _WorldSpaceLightPos0.xyz)); //r3.w
                // 
                // //r2.w = daylightDimFactor * headlampVisibility;
                // 
                // float3 directionToPlayer = _Global_PointLightPos.xyz - i.upDir.xyz * distanceFromHeadlamp; //r13.xyz
                // distObjToPlayer = length(directionToPlayer); //r1.y
                // directionToPlayer /= distObjToPlayer; //r13.xyz
                // 
                // float falloff = pow(max(0, 0.05 * (20 - distObjToPlayer)), 2); //r4.z
                // float lightIntensity = falloff * saturate(dot(directionToPlayer, worldNormal)); //r1.y
                // lightIntensity = distObjToPlayer < 0.001 ? 1 : lightIntensity;
                // lightIntensity = lightIntensity * daylightDimFactor * headlampVisibility;
                // 
                // float3 lightColor = float3(1.3, 1.1, 0.6);
                // lightColor = lightColor * lightIntensity;
                // lightColor = _Global_PointLightPos.w >= 0.5 ? lightColor : float3(0,0,0);

                float3 headlampLight =
                    calculateLightFromHeadlamp(_Global_PointLightPos, i.upDir, lightDir, worldNormal); //r5.xyz

                float3 lightColor = sunlightColor * pow(1 - metallicLow, 0.6)
                    + headlampLight * (pow(1 - metallicLow, 0.6) * 0.2 + 0.8); //r13.xyz

                float3 specularColor = _SpecularColor.xyz * lerp(float3(1, 1, 1), albedo.xyz, metallicLow); //r3.xyz
                specularColor *= sunlightColor; //r3.xyz
                specularColor *= clamped_nDotL * (specularTerm + INV_TEN_PI); //r3.xyz
                specularColor *= headlampLight + clamped_nDotL; //r3.xyz

                float3 highlightLight;
                if (_Global_PointLightPos.w >= 0.5)
                {
                    float distanceFromHeadlamp = length(_Global_PointLightPos.xyz) - 20; //r0.x
                    float daylightDimFactor = saturate(dot(-i.upDir, lightDir) * 5.0);

                    float3 directionToPlayer = _Global_PointLightPos.xyz - i.upDir * distanceFromHeadlamp; //r4.xzw
                    float distObjToPlayer = length(directionToPlayer); //r0.x
                    directionToPlayer /= distObjToPlayer;

                    float falloff = pow(max(0, 0.025 * (40 - distObjToPlayer)), 2); //r0.z
                    float lightIntensity = 20 * metal_smooth.y * falloff * pow(
                        max(0, dot(worldNormal, directionToPlayer)), exp2(9.965784 * metal_smooth.y)); //r0.x
                    lightIntensity = distObjToPlayer < 0.001 ? 1 : lightIntensity;
                    lightIntensity *= saturate(distanceFromHeadlamp) * daylightDimFactor;

                    highlightLight = float3(1.3, 1.1, 0.6);
                    highlightLight *= lightIntensity; //r0.xyz
                }
                else
                {
                    highlightLight = float3(0, 0, 0);
                }

                float3 scaledAlbedo = albedo.xyz * float3(0.5, 0.5, 0.5) + float3(0.5, 0.5, 0.5); //r2.xyz
                specularColor = lerp(metallicLow, 1, albedo.r * 0.2) * (specularColor + scaledAlbedo * highlightLight.
                    xyz); //r0.xyz

                float lumAmbient = 0.003 + dot(ambientColor.xyx, float3(0.3, 0.6, 0.1)); //r1.x
                float maxAmbient = 0.003 + max(_Global_AmbientColor0.z,
                                         max(_Global_AmbientColor0.x, _Global_AmbientColor0.y));
                reflectColor = reflectColor * float3(1.7, 1.7, 1.7) * lerp(
                    lumAmbient, ambientColor, float3(0.4, 0.4, 0.4)) * (1 / maxAmbient); //r3.xyz

                float reflectStrength = saturate(upDotL * 2 + 0.5) * 0.7 + 0.3 + headlampLight;
                reflectColor = reflectColor * reflectStrength; //r1.xyz

                float3 finalColor = ambientLightColor * (1 - metallicLow * 0.6)
                    + lightColor * albedo.xyz
                    + specularColor; //r0.xyz

                finalColor = lerp(finalColor, reflectColor * albedo.xyz, reflectivity); //r0.xyz

                float luminance = dot(finalColor.xyz, float3(0.3, 0.6, 0.1)); //r0.w
                finalColor = luminance > 1 ? (finalColor / luminance) * (log(log(luminance) + 1) + 1) : finalColor;
                //r0.xyz

                finalColor = finalColor
                    + i.indirectLight.xyz * albedo.xyz
                    + emission;

                o.sv_target.xyz = finalColor.xyz;
                o.sv_target.w = 1;

                return o;
            }
            ENDCG
        }
        Pass
        {
            Name "ShadowCaster"
            LOD 200
            Tags
            {
                "DisableBatching" = "true" "LIGHTMODE" = "SHADOWCASTER" "RenderType" = "Opaque" "SHADOWSUPPORT" = "true"
            }
            //GpuProgramID 152883
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 5.0
            #pragma enable_d3d11_debug_symbols

            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "CGIncludes/DSPCommon.cginc"

            struct v2f
            {
                float4 pos : SV_POSITION0;
                float4 uv_objId : TEXCOORD1;
                float3 upDir : TEXCOORD2;
            };

            struct fout
            {
                float4 sv_target : SV_Target0;
            };

            StructuredBuffer<GPUOBJECT> _InstBuffer;

            float4 _Size;

            v2f vert(appdata_full v, uint instanceID : SV_InstanceID)
            {
                v2f o;

                float3 objectPos = _Size * v.vertex.xyz; //r0.xyz
                
                float objId = _InstBuffer[instanceID].objId; //r1.x
                float3 pos = _InstBuffer[instanceID].pos; //r1.yzw
                
                objectPos = objId < 0.5 ? float3(0, 0, 0) : objectPos.xyz;
                float3 objectNormal = objId < 0.5 ? float3(0, 0, 0) : v.normal.xyz; //r3.xyz

                float3 worldPos = objectPos;
                float3 worldNormal = objectNormal;
                if (objId > 0.5)
                {
                    float4 rot = _InstBuffer[instanceID].rot; //r4.xyzw
                    worldPos = pos + rotate_vector_fast(objectPos, rot); //r0.xyz
                    worldNormal = rotate_vector_fast(objectNormal, rot); //r6.xyz //r3.xyz
                }

                o.upDir.xyz = normalize(pos);
                worldNormal = normalize(worldNormal); //r1.xyz
                
                worldPos = mul(unity_ObjectToWorld, float4(worldPos, 1)); //r0.xyzw
                
                worldNormal = UnityObjectToWorldNormal(worldNormal.xyz); //r1.xyz

                float vertw = objId < 0.5 ? 0 : v.vertex.w; //r3.w
                float4 clipPos = UnityClipSpaceShadowCasterPos(float4(worldPos.xyz, vertw), worldNormal);
                o.pos.xyzw = UnityApplyLinearShadowBias(clipPos);
                
                o.uv_objId.xy = v.texcoord.xy;
                o.uv_objId.z = (uint)objId;
                o.uv_objId.w = (uint)objId;
                return o;
            }
            
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