Shader "VF Shaders/Forward/VFF Water GI" {
    Properties {
        _Color ("Color 0", Vector) = (1,1,1,1)
        _Color1 ("Color 1", Vector) = (1,1,1,1)
        _Color2 ("Color 2", Vector) = (1,1,1,1)
        _Color3 ("Color 3", Vector) = (1,1,1,1)
        _ShoreIntens ("Shore Intens", Float) = 1.5
        _FresnelColor ("Fresnel Color", Vector) = (1,1,1,1)
        _DepthFactor ("Depth Factor", Vector) = (0.3,0.5,0.5,0.15)
        _GITex ("GI Texture", Cube) = "black" {}
        _BumpTex ("Bump Texture", 2D) = "bump" {}
        _FoamColor ("Foam Color", Vector) = (1,1,1,1)
        _FoamSpeed ("Foam Speed", Float) = 0.15
        _FoamSync ("Foam Sync", Float) = 10
        _FoamInvThickness ("Foam Inv Thickness", Float) = 4
        _CausticsTex ("Caustics Texture", 2D) = "black" {}
        _RefractionStrength ("Refraction Strength", Float) = 1
        _NormalStrength ("Normal Strength", Float) = 1
        _NormalTiling ("Normal Tiling", Float) = 0.1
        _NormalSpeed ("Normal Speed", Float) = 1.4
        _SpeclColor ("Spec Color", Vector) = (1,1,1,1)
        _SpeclColor1 ("Spec Color 1", Vector) = (1,1,1,1)
        _CausticsColor ("Caustics Color", Vector) = (1,1,1,1)
        _CausticsTiling ("Caustics Tiling", Float) = 0.1
        _GIStrengthDay ("全局光照（白天）", Range(0, 1)) = 1
        _GIStrengthNight ("全局光照（夜晚）", Range(0, 1)) = 0.2
        _GISaturate ("全局光照饱和度", Range(0, 1)) = 1
        _GIGloss ("全局光照清晰度", Range(0, 1)) = 0.7
        _Radius ("Radius", Float) = 200
    }
    SubShader {
        Tags { "DisableBatching" = "true" "IGNOREPROJECTOR" = "true" "QUEUE" = "Transparent-10" }
        GrabPass {
            "_ScreenTex"
        }
        Pass {
            Tags { "DisableBatching" = "true" "IGNOREPROJECTOR" = "true" "QUEUE" = "Transparent-10" }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 5.0
            #pragma enable_d3d11_debug_symbols

            #include "../../Downloads/builtin_shaders-2018/CGIncludes/UnityCG.cginc"

            struct v2f
            {
                float4 position : SV_POSITION0;
                float3 normal : NORMAL0;
                float3 tangent : TANGENT0;
                float3 bitangent : TEXCOORD2;
                float3 worldPos : TEXCOORD0;
                float4 clipPos : TEXCOORD1;
            };

            struct fout
            {
                float4 sv_target : SV_Target0;
            };

            float4 _Global_SunsetColor0;
            float4 _Global_SunsetColor1;
            float4 _Global_SunsetColor2;
            float4 _Planet_WaterAmbientColor0;
            float4 _Planet_WaterAmbientColor1;
            float4 _Planet_WaterAmbientColor2;
            float4 _Color;
            float4 _Color1;
            float4 _Color2;
            float4 _Color3;
            float _ShoreIntens;
            float4 _FresnelColor;
            float4 _DepthFactor;
            float4 _FoamColor;
            float _FoamSpeed;
            float _FoamSync;
            float _FoamInvThickness;
            float _RefractionStrength;
            float _NormalStrength;
            float _NormalTiling;
            float _NormalSpeed;
            float4 _SpeclColor;
            float4 _SpeclColor1;
            float4 _CausticsColor;
            float _CausticsTiling;
            float _GIStrengthDay;
            float _GIStrengthNight;
            float _GISaturate;
            float _GIGloss;
            float _Radius;
            float _Global_Water_Hint;
            float _Global_WhiteMode0;
            float4 _ScreenTex_TexelSize;
            float4 _Global_SunDir;
            float _GlobalWhiteMode0;

            sampler2D _BumpTex;
            sampler2D _CameraDepthTexture;
            sampler2D _CausticsTex;
            sampler2D _ScreenTex;
            samplerCUBE _GITex;

            v2f vert(appdata_full v) {
                v2f o;

                float3 worldPos = mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1)).xyz;
                o.worldPos.xyz = worldPos;

                float camDistance = distance(_WorldSpaceCameraPos, worldPos); //r0.x
                float distanceScale = saturate((camDistance - 10000.0) / 10000.0); //r0.x

                float3 upDir = normalize(v.vertex.xyz); //r0.yzw
                float3 offset = (distanceScale * upDir) / 800.0;
                float3 offsetVertPos = offset + v.vertex.xyz; //r0.xyz
                float4 offsetWorldPos = mul(unity_ObjectToWorld, float4(offsetVertPos, 1)); //r0.xyzw
                float4 clipPos = mul(unity_MatrixVP, offsetWorldPos); //r0

                o.position = clipPos;
                o.clipPos = clipPos;

                float3 worldNormal = normalize(mul(v.normal.xyz, (float3x3)unity_WorldToObject)); //r0.xyz
                o.normal.xyz = worldNormal.xyz;

                float3 worldTangent = normalize(mul((float3x3)unity_ObjectToWorld, v.tangent.xyz)); //r1
                o.tangent.xyz = worldTangent.xyz;

                o.bitangent.xyz = normalize(worldNormal.yzx * worldTangent.zxy - worldNormal.zxy * worldTangent.yzx);

                return o;
            }

            fout frag(v2f inp) {
                fout o;

                float4 r1;
                float4 r2;
                float4 r3;
                float4 r4;
                float4 r8;
                float4 r9;

                float3 axisWeights = saturate(abs(normalize(inp.normal.xyz)) - float3(0.1, 0.1, 0.1)); //r0.xyz
                axisWeights.xyz /= axisWeights.z + axisWeights.y + axisWeights.x;

                float normalSpeed = _NormalSpeed / _Radius; //r0.w
                float normalTiling = _NormalTiling * _Radius; //r1.x

                r2.z = inp.normal.z;
                r2.w = inp.normal.x;
                r2.x = _Time.y * normalSpeed + inp.normal.y;
                r2.y = _Time.y * normalSpeed + inp.normal.z;
                r4.x = _Time.y * normalSpeed - inp.normal.z;
                r4.y = _Time.y * normalSpeed - inp.normal.x;
                r4.z = inp.normal.y - _Time.y * normalSpeed;
                r4.w = inp.normal.z - _Time.y * normalSpeed;

                r3.xy = normalTiling * r2.zx;
                float2 bumpX1 = tex2D(_BumpTex, r3.xy).wy;
                bumpX1 = bumpX1 * float2(2.0, 2.0) - float2(1.0, 1.0); //r1.yz
                bumpX1 = bumpX1 + (1.0 / 255.0); //r1.yz

                r2.yz = normalTiling * r4.xz + bumpX1 * float2(0.15, 0.15);
                float2 bumpX2 = tex2D(_BumpTex, r2.yz).wy;
                bumpX2 = bumpX2 * float2(2.0, 2.0) - float2(0.996078, 0.996078); //r2.yz

                r3.zw = normalTiling * r2.wy;
                float2 bumpY1 = tex2D(_BumpTex, r3.zw).wy; //r3.xy
                bumpY1 = bumpY1 * float2(2.0, 2.0) - float2(0.996078, 0.996078); //r3.xy

                r3.zw = normalTiling * r4.yw + bumpY1.xy * float2(0.15, 0.15);
                float2 bumpY2 = tex2D(_BumpTex, r3.zw).wy; //r5.xy
                bumpY2 = bumpY2 * float2(2.0, 2.0) - float2(0.996078, 0.996078);

                r2.xw = normalTiling * r2.wx;
                float2 bumpZ1 = tex2D(_BumpTex, r2.xw).wy; //r5.xy
                bumpZ1 = bumpZ1 * float2(2.0, 2.0) - float2(0.996078, 0.996078);

                r1.xw = normalTiling * r4.yz + bumpZ1 * float2(0.15, 0.15);
                float2 bumpZ2 = tex2D(_BumpTex, r1.xw).wy; //r4.xy
                bumpZ2 = bumpZ2 * float2(2.0, 2.0) - float2(0.996078, 0.996078); //r1.xw

                float3 blendedNormalMap; //r1.xyz (z defined later)
                blendedNormalMap.xy = (bumpX1 + bumpX2) * axisWeights.xx
                    + (bumpY1 + bumpY2) * axisWeights.yy
                    + (bumpZ1 + bumpZ2) * axisWeights.zz; //r1.xy
                float screenAspectRatio = _ScreenTex_TexelSize.z / _ScreenTex_TexelSize.w; //r8.x defined below
                blendedNormalMap.z = -blendedNormalMap.y * screenAspectRatio; //1.z

                float nDotLUNK = dot(inp.normal.xyz, _Global_SunDir.xyz); //r1.w //negative nDotL? lightDir should be -_Global_SunDir.xyz I think

                float normalStr = (abs(nDotLUNK) + 0.2) * _NormalStrength; //r2.x

                float3 worldNormalWeak = normalize(
                    (blendedNormalMap.x * normalStr * 0.5) * inp.tangent.xyz
                    - (blendedNormalMap.y * normalStr * 0.5) * inp.bitangent.xyz
                    + inp.normal.xyz
                ); //r2.yzw  //some kind of normal vec

                float3 worldNormalStrong = normalize(
                    (blendedNormalMap.x * normalStr * 1.5) * inp.tangent.xyz
                    - (blendedNormalMap.y * normalStr * 1.5) * inp.bitangent.xyz
                    + inp.normal.xyz
                ); //r3.xyz  //some kind of normal vec

                float3 eyeVec = normalize(inp.worldPos.xyz - _WorldSpaceCameraPos); //r5.xyz

                float bumpedNdotL = dot(worldNormalWeak, _Global_SunDir.xyz); //r3.w
                float bumpedNDotV = saturate(dot(eyeVec.xyz, -worldNormalWeak)); //r4.w
                float nDotV = saturate(dot(eyeVec.xyz, -inp.normal.xyz)); //r5.w

                float3 reflectVec = reflect(eyeVec.xyz, worldNormalWeak); //r2.yzw

                //func
                float4 screenPos; //r6.xyzw
                // r6.xz = inp.clipPos.xw * float2(0.5, 0.5);
                // r6.w = (inp.clipPos.y * _ProjectionParams.x) * 0.5;
                // r6.xy = r6.zz + r6.xw;
                screenPos = ComputeScreenPos(inp.clipPos.xyzw); //r6.xyzw // r6.z = screenPos.w

                /* sample depth at pixel pos */
                float2 pixelPos = screenPos.xy / inp.clipPos.ww; //r6.xy
                float sceneDepth = tex2D(_CameraDepthTexture, pixelPos.xy).x; // r7.x
                sceneDepth = LinearEyeDepth(sceneDepth);

                float depthMod1 = max(0, inp.clipPos.w * 0.0007 - 0.9); // 0 until 1286, then linear up. is 1 when .w is 2714
                depthMod1 = depthMod1 < 1.0 ? pow(depthMod1, 2.0) : depthMod1; //r7.y

                float viewedDistWatertoGround = max(0.0, sceneDepth - inp.clipPos.w);
                float viewDepthAngle = nDotV * viewedDistWatertoGround * depthMod1;

                /* sample depth at pixel pos offset for refraction */
                float2 pixelPosRefracted = pixelPos.xy + (0.4 * _RefractionStrength * blendedNormalMap.xz) / inp.clipPos.ww; //r6.xy
                float sceneDepthRefracted = tex2D(_CameraDepthTexture, pixelPosRefracted).x; //r8.x
                sceneDepthRefracted = LinearEyeDepth(sceneDepthRefracted);

                float depthMod2 = max(0, inp.clipPos.w * 0.0009 - 0.9); // 0 until 1000, then linear up. is 1 when .w is 2111
                depthMod2 = depthMod2 < 1.0 ? pow(depthMod2, 2.0) : depthMod2; //r7.z

                float viewedDistWaterToGroundRefracted = sceneDepthRefracted - inp.clipPos.w;
                float viewDepthAngleRefracted = nDotV * viewedDistWaterToGroundRefracted + depthMod2;

                /* combine to determine depth and angle at viewed angle */
                viewDepthAngleRefracted = pixelPosRefracted.x < 0.0 ? viewDepthAngle : viewDepthAngleRefracted; //r6.x //is r6.x = pixelPosRefracted at this point?
                viewDepthAngleRefracted = lerp(viewDepthAngle, viewDepthAngleRefracted, min(viewDepthAngle, 1.0));
                viewDepthAngleRefracted = viewDepthAngleRefracted > 1.0 ? log(viewDepthAngleRefracted) + 1.0: viewDepthAngleRefracted; //r6.x

                float3 worldPosRefracted = eyeVec.xyz * min(viewDepthAngleRefracted, 50.0) + inp.worldPos.xyz; //r9.xyz
                float2 causticsUV_X1, causticsUV_X2, causticsUV_Y1, causticsUV_Y2, causticsUV_Z1, causticsUV_Z2;
                float2 scaledNormal = blendedNormalMap.xy / 5.0;

                causticsUV_X1.x = _CausticsTiling * (worldPosRefracted.z + scaledNormal.x); //r11.x
                causticsUV_X1.y = _CausticsTiling * (worldPosRefracted.x + scaledNormal.y); //r11.y

                causticsUV_X2.x = _CausticsTiling * (worldPosRefracted.z - _Time.y * normalSpeed + scaledNormal.x); // r14.x
                causticsUV_X2.y = _CausticsTiling * (worldPosRefracted.x - _Time.y * normalSpeed + scaledNormal.x); // r14.y

                causticsUV_Y1.x = _CausticsTiling * (worldPosRefracted.x + scaledNormal.x); //r5.x
                causticsUV_Y1.y = _CausticsTiling * (worldPosRefracted.y - _Time.y * 0.56 - scaledNormal.y); //r5.y

                causticsUV_Y2.x = _CausticsTiling * (worldPosRefracted.z + _Time.y * 0.7 - scaledNormal.y); //r14.z
                causticsUV_Y2.y = _CausticsTiling * (worldPosRefracted.z - _Time.y * 0.56 - scaledNormal.y); //r14.w

                causticsUV_Z1.x = _CausticsTiling * (worldPosRefracted.y + _Time.y * 0.7 - scaledNormal.x); //r11.z
                causticsUV_Z1.y = _CausticsTiling * (worldPosRefracted.y + _Time.y * 0.7 - scaledNormal.y); //r11.w

                causticsUV_Z2.x = _CausticsTiling * (worldPosRefracted.x - _Time.y * normalSpeed + scaledNormal.x); //r5.xy
                causticsUV_Z2.y = _CausticsTiling * (worldPosRefracted.z + _Time.y * 0.7 - scaledNormal.y); //r5.xy


                float2 causticsX1 = tex2D(_CausticsTex, causticsUV_X1.xy).xz; //r12.xy
                float2 causticsX2 = tex2D(_CausticsTex, causticsUV_X2.xy).xz; //r15.xy
                float2 causticsY1 = tex2D(_CausticsTex, causticsUV_Y1.xy).xz; //r9.xy
                float2 causticsY2 = tex2D(_CausticsTex, causticsUV_Y2.xy).xz; //r10.xy
                float2 causticsZ1 = tex2D(_CausticsTex, causticsUV_Z1.xy).xz; //r11.xy
                float2 causticsZ2 = tex2D(_CausticsTex, causticsUV_Z2.xy).xz; //r13.xy

                float2 blendedCaustics = (causticsX1 + causticsX2) * axisWeights.xx
                    + (causticsY1 + causticsY2) * axisWeights.yy
                    + (causticsZ1 + causticsZ2) * axisWeights.zz; //r0.xy

                float foamAnim = frac(_FoamSync * (inp.normal.y - _Time.y)) * 1.3 - 0.3; //r0.z
                float foamAnimMod1 = saturate((foamAnim - nDotV) * _FoamInvThickness + 1.0); // is r5.w = nDotV? //r1.y
                float foamAnimMod2 = saturate((nDotV - foamAnim) * _FoamInvThickness * 5.0 + 1.0); // is r5.w = nDotV? //r0.z
                float foam = pow(1.0 - foamAnim, 1.3) * foamAnimMod2 * foamAnimMod1 * saturate(nDotV * 20.0) * blendedCaustics.y * 1.25; //r0.y

                float refractFactor = _RefractionStrength * min(1.0, 2.0 * pow(saturate(viewDepthAngleRefracted * _DepthFactor.y), _DepthFactor.z) * saturate(viewDepthAngleRefracted * 4.0)); //r0.z

                float2 screenUV = (refractFactor * blendedNormalMap.xz + inp.clipPos.xy * float2(0.5, -0.5)) / inp.clipPos.ww; // (this screen.w and clip.w are the same??) + screenPos.ww / inp.clipPos.ww); //r0.zw
                float3 groundColor = tex2D(_ScreenTex, screenUV.xy).xyz; //r5.xyz

                float depthFactUNK = blendedNormalMap.x * _DepthFactor.w + saturate(viewDepthAngleRefracted * _DepthFactor.x); //r0.z

                float3 shallowColor = lerp(_Color.xyz, _Color1.xyz, depthFactUNK * 5.0); //r1.xyz
                float3 mediumColor = lerp(_Color1.xyz, _Color2.xyz, (depthFactUNK - 0.2) * 2.5); //r7.xyz
                float3 deepColor = lerp(_Color.xyz, _Color3.xyz, (depthFactUNK - 0.6) * 2.5); //r9.xyz

                float3 waterColor = depthFactUNK < 1.0 ? deepColor.xyz : _Color3.xyz; //r9.xyz
                waterColor = depthFactUNK < 0.6 ? mediumColor.xyz : waterColor; //r7.xyz
                waterColor = depthFactUNK < 0.2 ? shallowColor.xyz : waterColor; //r1.xyz
                waterColor = depthFactUNK < 0.0 ? _Color.xyz : waterColor; //r1.xyz

                waterColor = lerp(_ShoreIntens, 1.0, saturate(viewDepthAngleRefracted * 3.0)) - 1.0 + waterColor; //r1.xyz
                waterColor = lerp(waterColor, float3(0.7, 0.7, 0.7), _Global_WhiteMode0); //r1.xyz
                waterColor = foam * _FoamColor.xyz + lerp(waterColor, _FresnelColor.xyz, pow(max(1.0 - bumpedNDotV * 1.7, 0.0), 3.0)); //r0.yzw

                float3 sunsetColor = float3(1.0, 1.0, 1.0); //r7.xyz
                if (nDotLUNK <= 1.0) {
                    float4 r11;
                    float4 r10;
                    float4 r7;
                    float4 r12;
                    r8.xyzw = nDotLUNK + float4(-0.2, -0.1, 0.1, 0.3);
                    r8.xyzw = saturate(r8.xyzw * float4(5.0, 10.0, 5.0, 5.0));
                    r7.xyz = float3(1.0, 1.0, 1.0) - _Global_SunsetColor0.xyz;
                    r7.xyz = r8.xxx * r7.xyz + _Global_SunsetColor0.xyz;
                    r9.xyz = _Global_SunsetColor1.xyz * float3(1.25, 1.25, 1.25);
                    r10.xyz = -_Global_SunsetColor1.xyz * float3(1.25, 1.25, 1.25) + _Global_SunsetColor0.xyz;
                    r9.xyz = r8.yyy * r10.xyz + r9.xyz;
                    r10.xyz = nDotLUNK > float3(0.2, 0.1, -0.1);
                    r11.xyz = _Global_SunsetColor2.xyz * float3(1.5, 1.5, 1.5);
                    r12.xyz = _Global_SunsetColor1.xyz * float3(1.25, 1.25, 1.25) - r11.xyz;
                    r8.xyz = r8.zzz * r12.xyz + r11.xyz;
                    r11.xyz = r8.www * r11.xyz;
                    r8.xyz = r10.zzz ? r8.xyz : r11.xyz;
                    r8.xyz = r10.yyy ? r9.xyz : r8.xyz;
                    sunsetColor.xyz = r10.xxx ? r7.xyz : r8.xyz;
                }
                sunsetColor.xyz = lerp(sunsetColor.xyz, float3(1.0, 1.0, 1.0), float3(0.7, 0.7, 0.7)); //r7.xyz


                r8.xyz = lerp(_Planet_WaterAmbientColor1.xyz, _Planet_WaterAmbientColor0.xyz, saturate(nDotLUNK * 4.0));
                r9.xyz = lerp(_Planet_WaterAmbientColor2.xyz, _Planet_WaterAmbientColor1.xyz, saturate(nDotLUNK * 4.0 + 1.0));
                float3 ambientColor = nDotLUNK > 0.0 ? r8.xyz : r9.xyz; //r8.xyz
                ambientColor = min(max(bumpedNdotL, 0.0), 0.7) * sunsetColor.xyz + pow(bumpedNdotL * 0.35 + 1.0, 3.0) * ambientColor.xyz;

                float3 eyeToSunDir = normalize(_Global_SunDir.xyz - eyeVec); //r4.xyz
                float nDotEyeSun = saturate(dot(worldNormalStrong, eyeToSunDir.xyz)) * saturate(bumpedNdotL * 4.5 + 0.7); //r1.x
                float3 specColor = lerp(_SpeclColor1.xyz, _SpeclColor.xyz, saturate(r9.x));
                //r3.xyz //what's r9.x? is it red from the color? weird.
                float specPower = pow(min(2.0 * bumpedNDotV, 1.0), 2.0) * 98.0 + 2.0; //r1.z
                float3 finalColor = waterColor * ambientColor + max(pow(1.3 - nDotLUNK, 3.0), 0.0) * specColor * pow(nDotEyeSun, specPower); //r0.yzw

                float lod = pow(1.0 - _GIGloss, 0.4) + 10.0; //r1.y
                float4 reflectColor = texCUBElod(_GITex, float4(reflectVec, lod)); //r2.xyzw

                float4 giReflect = reflectColor.xyzw * lerp(_GIStrengthNight, _GIStrengthDay, pow(saturate(nDotLUNK * 0.7 + 0.5), 3.0)); //r1.xyzw
                float giReflectGrey = dot(giReflect.xyz, float3(0.12, 0.24, 0.04));
                giReflect.xyzw = lerp(giReflectGrey.xxxx, giReflect.xyzw * float4(0.4, 0.4, 0.4, 0.4), _GISaturate); //r1.xyzw

                groundColor = lerp(groundColor, finalColor, min(viewDepthAngle, 1.0));
                float causticsPower = saturate(viewDepthAngleRefracted * 2.0 - 0.1) * (1.0 - pow(saturate(viewDepthAngleRefracted * _DepthFactor.y * 0.8), _DepthFactor.z * 0.5)) * blendedCaustics.x * 1.5; //r0.x
                float4 finalColorAndAlpha = giReflect.xyzw * saturate((depthFactUNK - 0.25) * 1.333)
                    + causticsPower * _CausticsColor * saturate(bumpedNdotL * 3.0 + 0.2)
                    + float4(groundColor.xyz, 1.0); //r0.xyzw

                float luminance = dot(finalColorAndAlpha.xyz, float3(0.3, 0.6, 0.1)); //r1.x
                finalColorAndAlpha.xyz = lerp(finalColorAndAlpha.xyz, luminance * float3(0.75, 0.75, 0.75), _GlobalWhiteMode0);

                float mainColorStr = max(0.01 - abs(0.27 - viewDepthAngle), 0.0) * _Global_Water_Hint * 100.0; //r7.w
                o.sv_target = mainColorStr * _Color1 + finalColorAndAlpha.xyzw;

                return o;
            }
            ENDCG
        }
    }
}