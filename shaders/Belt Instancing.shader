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
            #pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight
            #pragma enable_d3d11_debug_symbols
            
            #include "UnityCG.cginc"
            #include "CGIncludes/DSPCommon.cginc"
            #include "AutoLight.cginc"
            
            struct BeltAnchor
            {
                float t;
                float3 pos;
                float4 rot;
            };
            
            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 TBNW0 : TEXCOORD0; //o1
                float4 TBNW1 : TEXCOORD1; //o2
                float4 TBNW2 : TEXCOORD2; //o3
                float4 texUV_t_state : TEXCOORD3; //o4
                float4 worldPos : TEXCOORD4;
                float2 emissUV : TEXCOORD5;
                float4 indirectLight : TEXCOORD6;
                UNITY_SHADOW_COORDS(8)
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
            //float _PGI_Gray;
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
            //samplerCUBE _Global_PGI;
            
            
            v2f vert(appdata_full v, uint instanceID : SV_InstanceID)
            {
                v2f o;
                
                uint offset = v.vertex.z * (_NodeWidth - 1.0) + 0.4; // (2,3,5,9) = (1.4*z, 2.4+z, 4.4*z, 8.4+z) z=[0,1] where 0 is beginning of belt, 1 is end
                uint nodeIndex = instanceID * _NodeWidth + offset; //r0.x
                
                float t = _Buffer[nodeIndex].t; //r1.x
                float3 pos = _Buffer[nodeIndex].pos; //r1.yzw

                float3 worldPos;
                float3 worldNormal;
                float3 worldTangent;
                if (t > 0.5) {
                    float4 rot = _Buffer[nodeIndex].rot;
                    worldPos = pos + rotate_vector_fast(float3(v.vertex.xy, 1), rot);
                    worldNormal = rotate_vector_fast(v.normal.xyz, rot);
                    worldTangent = rotate_vector_fast(float3(0,0,1), rot);
                } else {
                    worldNormal = float3(0,0,0);
                    worldPos = float3(0,0,0);
                    worldTangent = float3(0,0,1);
                }
                
                //r0.z = 1.0 - ((0.5 + v.vertex.x) - (v.normal.x * v.vertex.y) / 1.5);
                float texV = 0.5 - v.vertex.x + (v.vertex.y * v.normal.x) / 1.5; //r0.z
                //v.normal.x for up/down/forward/back will be 0, so this is just a side thing? on sides, either -1 or 1 (left/right)
                //on sides, v.vertex.y will be -0.15 on bottom and ~0 on top
                //so vert.y * normal.x = 0.15 to 0 bottom to top on left, -0.15 to 0 from bottom to top on right. div 1.5, so ±0.1 to 0
                //0.5 - vert.x = 0.5 - [-0.4, 0.4] = [0.9, 0.1], left to right
                //on up/down/forward/back, it's +0, so just [0.9, 0.1] left to right all the way from back to front
                //on left side, it'll be 0.9 + [0.1, 0] = [1.0, 0.9] from bottom to top.
                //on right side, itll be 0.1 + [-0.1, 0] = [0.0, 0.1] from bottom to top.
                
                float4 worldPos2 = mul(unity_ObjectToWorld, float4(worldPos, 1.0)); //r5
                float4 clipPos = mul(UNITY_MATRIX_VP, worldPos2); //r6
                
                worldNormal = UnityObjectToWorldNormal(worldNormal);
                worldTangent = UnityObjectToWorldDir(worldTangent); //r2.xyz
                float tsign = sign(0.1 + v.normal.x); //r0.y
                float3 worldBinormal = calculateBinormal(float4(worldTangent, tsign), worldNormal);
                
                o.indirectLight.xyz = ShadeSH9(float4(worldNormal.xyz, 1));
                
                o.pos.xyzw = clipPos.xyzw;
                UNITY_TRANSFER_SHADOW(o, float(0,0))
                
                o.TBNW0.x = worldTangent.x;
                o.TBNW0.y = worldBinormal.x;
                o.TBNW0.z = worldNormal.x;
                o.TBNW0.w = worldPos2.x;
                
                o.TBNW1.x = worldTangent.y;
                o.TBNW1.y = worldBinormal.y;
                o.TBNW1.z = worldNormal.y;
                o.TBNW1.w = worldPos2.y;
                
                o.TBNW2.x = worldTangent.z;
                o.TBNW2.y = worldBinormal.z;
                o.TBNW2.z = worldNormal.z;
                o.TBNW2.w = worldPos2.z;
                
                float texU = t / 17.0;
                o.texUV_t_state.x = texU;
                o.texUV_t_state.y = texV;
                
                o.texUV_t_state.z = t;
                
                o.texUV_t_state.w = _BeltStateBuffer[nodeIndex];
                
                o.worldPos.xyz = worldPos;
                
                o.emissUV.x = v.vertex.z; //z = 0 to 1 in the direction of travel
                o.emissUV.y = texV;
                
                o.unk.xyzw = float4(0,0,0,0);
                
                return o;

            }

            fout frag(v2f i)
            {
                fout o;
                
                float t = i.texUV_t_state.z;
                if (t < 0.5)
                    discard;
                
                float2 texUV = i.texUV_t_state.xy;
                float2 clip = tex2Dlod(_ClipTex, float4(texUV, 0, 0)).xz; //r0.xy
                if (clip.x < 0.5)
                    discard;
                    
                float distCamToPos = distance(i.worldPos, _WorldSpaceCameraPos); //r0.z
                
                float2 deriv;
                deriv.x = ddx_coarse(texUV.y);
                deriv.y = ddy_coarse(texUV.y);
                float mip = log2(length(deriv.xy)) + 8.0; //r0.w
                
                texUV.x = abs(texUV.y - 0.5) < 0.34 ? texUV.x - frac(_Time.y * (60.0 / 17.0) * _UVSpeed) : texUV.x; //r1.xy
                
                float3 albedo = tex2Dlod(_MainTex, float4(texUV.xy, 0, mip)).xyz; //r2.xyz
                albedo.xyz = albedo.xyz * lerp(float3(1, 1, 1), _Color.xyz, clip.y); //r2.xyz
                
                float3 unpackedNormal = UnpackNormal(tex2Dlod(_NormalTex, float4(texUV.xy, 0, mip)));
                unpackedNormal = normalize(unpackedNormal); //r3.xyz
                
                float2 metalSmooth = tex2Dlod(_MSTex, float4(texUV.xy, 0, mip)).xw; //r0.xy
                float3 emiss = tex2D(_EmissionTex, i.emissUV.xy).xyz; //r1.xyz
                
                float3 upDir = normalize(i.worldPos.xyz); //r4.xyz
                
                emiss.xyz = emiss.xyz * min(10, max(1, 1000 / distCamToPos)); //r1.xyz
                
                float sunAngle = dot(upDir.xyz, _Global_SunDir.xyz); //noon = 1, perpendicular = 0, midnight = -1 (sundir is planet to star, right?)
                float3 nightLightColor = _EmissionColor.xyz * saturate(-500 * sunAngle); //r5.xyz
                nightLightColor = nightLightColor.xyz * emiss.xyz; //r6.xyz
                
                //state is set in BuildTool_BlueprintCopy.UpdatePreviewModels(BuildModel model) and CargoTraffic.SetBeltSelected(int beltId)
                float state = i.texUV_t_state.w;
                bool isOrangeBelt = state > 0.5 && state < 1.5; // == 1
                bool isGreenBelt = state > 1.5 && state < 2.5; // == 2
                bool isBlueBelt = state > 4.5  && state < 5.5; // == 5
                bool isBlueprintPreview = (state > 9.5 && state < 10.5) || (state > 19.5 && state < 20.5) || (state > 49.5 && state < 50.5); // state = beltspeed * 10
                bool isBlueprintPreselect = state > 99.5 && state < 100.5; // == 100
                bool isBlueprintDelete = state > 999.5; // == 1000
                
                if (isOrangeBelt) {
                    nightLightColor.xyz = nightLightColor + float3(1.1, 0.4, 0);
                } else {
                    if (isGreenBelt) {
                        nightLightColor.xyz = nightLightColor + float3(0, 1.1, 0.3);
                    } else {
                        float3 deleteColor = isBlueprintDelete ? float3(0.15, 0.15, 0.15) : albedo;
                        albedo = isBlueBelt || isBlueprintPreselect || isBlueprintPreview ? albedo : deleteColor;
                        
                        nightLightColor = isBlueprintDelete ? float3(0.15, 0.15, 0.15) : nightLightColor;
                        nightLightColor = isBlueprintPreview ? nightLightColor + float3(0, 0.45, 4.95) : nightLightColor;
                        nightLightColor = isBlueprintPreselect ? nightLightColor + float3(0.5, 0.5, 0.5) : nightLightColor;
                        nightLightColor = isBlueBelt ? nightLightColor + float3(0, 0.4 ,1.1) : nightLightColor;
                    }
                }
                  
                //-- usual DSP Shader stuff --//
                
                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos); //r0.w
                
                float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos); //r6.xyz
                
                //tranform normal from tangent to world space
                float3 worldNormal;
                worldNormal.x = dot(i.TBNW0.xyz, unpackedNormal.xyz);
                worldNormal.y = dot(i.TBNW1.xyz, unpackedNormal.xyz);
                worldNormal.z = dot(i.TBNW2.xyz, unpackedNormal.xyz);
                worldNormal.xyz = normalize(worldNormal.xyz); //r1.xyz
                
                //light vars
                float metallic = saturate(metalSmooth.x * 0.85 + 0.149); //r0.x
                float perceptualRoughness = saturate(1.0 - metalSmooth.y * 0.97); //r1.w
                
                float3 lightDir = _WorldSpaceLightPos0.xyz;
                float halfDir = normalize(viewDir + lightDir); //r3.xyz
                
                float roughness = perceptualRoughness * perceptualRoughness; //r0.z
                float roughnessSqr = roughness * roughness; //r2.w
                
                float unclamped_NdotL = dot(worldNormal, lightDir); //r3.w
                float NdotL = max(0, unclamped_NdotL); //r4.w
                float NdotV = max(0, dot(worldNormal, viewDir)); //r5.x
                float NdotH = max(0, dot(worldNormal, halfDir)); //r5.y
                float VdotH = max(0, dot(viewDir, halfDir)); //r3.x
                
                float UpdotL = dot(upDir, lightDir); //r3.z
                float NdotUp = dot(worldNormal, upDir); //r3.w
                
                float reflectivity; //r1.w
                float3 reflectColor = reflection(perceptualRoughness, metallic, upDir, viewDir, worldNormal, /*out*/ reflectivity); //r8.xyz
                
                float3 sunlightColor = calculateSunlightColor(_LightColor0.xyz, UpdotL, _Global_SunsetColor0.xyz, _Global_SunsetColor1.xyz, _Global_SunsetColor2.xyz); //r9.xyz
                
                //fade shadows
                atten = 0.8 * lerp(atten, 1.0, saturate(0.15 * UpdotL));
                //apply shadows to sunlight
                sunlightColor = sunlightColor * NdotL;
                sunlightColor = atten * sunlightColor;
                
                float specularTerm = INV_TEN_PI + GGX(roughness, metallic + 0.5, NdotH, NdotV, NdotL, VdotH);
                
                float3 ambientTwilight = lerp(_Global_AmbientColor2.xyz, _Global_AmbientColor1.xyz, saturate(UpdotL * 3.0 + 1)); //-33% to 0%
                float3 ambientLowSun = lerp(_Global_AmbientColor1.xyz, _Global_AmbientColor0.xyz, saturate(UpdotL * 3.0)); // 0% - 33%
                float3 ambientColor = UpdotL > 0 ? ambientLowSun : ambientTwilight; //r5.xyz
                
                float3 ambientLight = ambientColor * saturate(NdotUp * 0.3 + 0.7); //r10.xyz
                ambientLight = ambientLight * pow(unclamped_NdotL * 0.35 + 1.0, 3.0); //r3.xyw
                
                float3 headlampLight = float3(0, 0, 0);
                if (_Global_PointLightPos.w >= 0.5) {
                    float fadeIn = saturate(5 * dot(-upDir.xyz, lightDir));
                    float headlampPower = fadeIn * saturate(length(_Global_PointLightPos.xyz) - 5.0);
                    
                    float3 objToHeadlamp = _Global_PointLightPos.xyz - upDir.xyz * (length(_Global_PointLightPos.xyz) - 5);
                    float distToHeadlamp = length(objToHeadlamp.xyz);
                    
                    float falloff = pow(max(0, (20 - distToHeadlamp) / 20.0), 2.0);
                    
                    float3 headlampDir = objToHeadlamp / distToHeadlamp;
                    
                    float scaledHeadlampPower = saturate(dot(headlampDir, worldNormal));
                    scaledHeadlampPower = scaledHeadlampPower * falloff * headlampPower;
                    
                    headlampLight = distToHeadlamp < 0.001 ? float3(1.3, 1.1, 0.6) * headlampPower : float3(1.3, 1.1, 0.6) * scaledHeadlampPower;
                }
                
                float3 reflectedHeadlampLight = float3(0, 0, 0);
                if (_Global_PointLightPos.w >= 0.5) {
                    float fadeIn = saturate(5 * dot(-upDir.xyz, lightDir));
                    float headlampPower = fadeIn * saturate(length(_Global_PointLightPos.xyz) - 20.0);
                    
                    float3 objToHeadlamp = _Global_PointLightPos.xyz - upDir.xyz * (length(_Global_PointLightPos.xyz) - 20);
                    float distToHeadlamp = length(objToHeadlamp);
                    
                    float falloff = pow(max(0, (40 - distToHeadlamp) / 40.0), 2.0);
                    
                    float3 headlampDir = objToHeadlamp / distToHeadlamp;
                    float3 reflectDir = reflect(-viewDir, worldNormal);
                    
                    float scaledHeadlampPower = saturate(dot(headlampDir, reflectDir));
                    scaledHeadlampPower = metalSmooth.y * 20.0 * pow(scaledHeadlampPower, pow(1000.0, metalSmooth.y));
                    scaledHeadlampPower = scaledHeadlampPower * falloff * headlampPower;
                    
                    reflectedHeadlampLight = distToHeadlamp < 0.001 ? float3(1.3, 1.1, 0.6) * headlampPower : float3(1.3, 1.1, 0.6) * scaledHeadlampPower;
                }
                
                //mix lighting
                float greyscaleAmbient = 0.003 + dot(ambientColor.xyx, float3(0.3, 0.6, 0.1)); //r2.w
                float maxAmbient = 0.003 + max(_Global_AmbientColor0.z, max(_Global_AmbientColor0.x, _Global_AmbientColor0.y)); //r4.x
                float3 reflectAmbient = lerp(greyscaleAmbient.xxx, ambientColor.xyz, float3(0.4, 0.4, 0.4)) / maxAmbient; //r4.xyz
                reflectColor = albedo * (reflectColor * float3(1.7, 1.7, 1.7) * reflectAmbient * (saturate(UpdotL * 2.0 + 0.5) * 0.7 + 0.3) + headlampLight);
                
                float ambientAndDiffuseLight = albedo * (ambientLight * (1.0 - metallic * 0.6) + sunlightColor * pow(1.0 - metallic, 0.6) + headlampLight * (pow(1.0 - metallic, 0.6) * 0.2 + 0.8));
                
                float3 specularLight = (sunlightColor + headlampLight * sunlightColor) * lerp(float3(1,1,1), albedo, metallic) * specularTerm + 0.5 * (albedo * reflectedHeadlampLight + reflectedHeadlampLight);
                float fadeSpecular = lerp(metallic, 1, 0.2 * albedo.x);
                specularLight = fadeSpecular * specularLight; 
                
                float3 finalColor = ambientAndDiffuseLight + specularLight; //r0.xyz
                finalColor = lerp(finalColor, reflectColor, reflectivity);
                
                float luminance = dot(finalColor.xyz, float3(0.3, 0.6, 0.1)); //r0.w
                finalColor.xyz = luminance > 1.0 ? (finalColor / luminance) * (log(log(luminance) + 1) + 1) : finalColor;
                
                o.sv_target.xyz = albedo * i.indirectLight + finalColor + nightLightColor;
                o.sv_target.w = 1;
                return o;
            }
            ENDCG
        }
        
        Pass {
            Name "ShadowCaster"
            LOD 200
            Tags { "LIGHTMODE" = "SHADOWCASTER" "RenderType" = "Opaque" "SHADOWSUPPORT" = "true" }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 5.0
            #pragma multi_compile_shadowcaster
            #pragma enable_d3d11_debug_symbols
            
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "CGIncludes/DSPCommon.cginc"
            
            struct BeltAnchor
            {
                float t;
                float3 pos;
                float4 rot;
            };
            
            struct v2f_shadow
            {
                float4 pos : SV_POSITION;
                float4 texUV_t_state : TEXCOORD1;
                float4 worldPos : TEXCOORD2;
                float2 emissUV : TEXCOORD3;
            };
            
            struct fout
            {
                float4 sv_target : SV_Target;
            };
            
            StructuredBuffer<BeltAnchor> _Buffer;
            StructuredBuffer<float> _BeltStateBuffer;

            float _NodeWidth;
            sampler2D _ClipTex;
            
            v2f_shadow vert(appdata_full v, uint instanceID : SV_InstanceID)
            {
                v2f_shadow o;
                
                uint offset = v.vertex.z * (_NodeWidth - 1.0) + 0.4; // (2,3,5,9) = (1.4*z, 2.4+z, 4.4*z, 8.4+z) z=[0,1] where 0 is beginning of belt, 1 is end
                uint nodeIndex = instanceID * _NodeWidth + offset; //r0.x
                
                float t = _Buffer[nodeIndex].t; //r1.x
                float3 pos = _Buffer[nodeIndex].pos; //r1.yzw
                
                float3 worldPos;
                float3 worldNormal;
                if (t > 0.5) {
                    float4 rot = _Buffer[nodeIndex].rot;
                    worldPos = pos + rotate_vector_fast(float3(v.vertex.xy, 1), rot);
                    worldNormal = rotate_vector_fast(v.normal.xyz, rot);
                } else {
                    worldNormal = float3(0,0,0);
                    worldPos = float3(0,0,0);
                }
                
                float texV = 0.5 - v.vertex.x + (v.vertex.y * v.normal.x) / 1.5; //r0.x
                
                float4 worldPos2 = mul(unity_ObjectToWorld, float4(worldPos, 1.0)); //r2
                worldNormal = UnityObjectToWorldNormal(worldNormal); //r3.xyz
                
                float4 shadowClipPos = UnityClipSpaceShadowCasterPos(worldPos2, worldNormal);
                o.pos.xyzw = UnityApplyLinearShadowBias(shadowClipPos);
                
                float texU = t / 17.0;
                o.texUV_t_state.x = texU;
                o.texUV_t_state.y = texV;
                
                o.texUV_t_state.z = t;
                
                o.texUV_t_state.w = _BeltStateBuffer[nodeIndex];
                
                o.worldPos.xyz = worldPos.xyz;
                
                o.emissUV.x = v.vertex.z;
                o.emissUV.y = texV;
                
                return o;
            }
            
            fout frag(v2f_shadow i)
            {
                fout o;
                
                float t = i.texUV_t_state.z;
                if (t < 0.5)
                    discard;
                
                float2 texUV = i.texUV_t_state.xy;
                float2 clip = tex2Dlod(_ClipTex, float4(texUV, 0, 0)).xz; //r0.xy
                if (clip.x < 0.5)
                    discard;
                
                o.sv_target.xyzw = float4(0,0,0,0);
                return o;
            }
            ENDCG
        }
    }
    Fallback "Diffuse"
}