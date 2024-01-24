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
            #pragma enable_d3d11_debug_symbols
            
            #include "UnityCG.cginc"
            #include "CGIncludes/DSPCommon.cginc"
            
            struct BeltAnchor
            {
                float t;
                float3 pos;
                float4 rot;
            };
            
            struct v2f
            {
                float4 pos : SV_POSITION,
                float4 TBNW0 : TEXCOORD0; //o1
                float4 TBNW1 : TEXCOORD1; //o2
                float4 TBNW2 : TEXCOORD2; //o3
                float4 texUV_t_state : TEXCOORD3; //o4
                float4 worldPos : TEXCOORD4;
                float2 emissUV : TEXCOORD5;
                float4 indirectLight : TEXCOORD6;
                float4 screenPos : TEXCOORD8;
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
            float _PGI_Gray;
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
            samplerCUBE _Global_PGI;
            
            
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
                
                float sign = sign(0.1 + v.normal.x); //r0.y
                
                //r0.z = 1.0 - ((0.5 + v.vertex.x) - (v.normal.x * v.vertex.y) / 1.5);
                float texV = 0.5 - v.vertex.x + (v.vertex.y * v.normal.x) / 1.5; //r0.z
                //v.normal.x for up/down/forward/back will be 0, so this is just a side thing? on sides, either -1 or 1 (left/right)
                //on sides, v.vertex.y will be -0.15 on bottom and ~0 on top
                //so vert.y * normal.x = 0.15 to 0 bottom to top on left, -0.15 to 0 from bottom to top on right. div 1.5, so ±0.1 to 0
                //0.5 - vert.x = 0.5 - [-0.4, 0.4] = [0.9, 0.1], left to right
                //on up/down/forward/back, it's +0, so just [0.9, 0.1] left to right all the way from back to front
                //on left side, it'll be 0.9 + [0.1, 0] = [1.0, 0.9] from bottom to top.
                //on right side, itll be 0.1 + [-0.1, 0] = [0.0, 0.1] from bottom to top.
                
                float4 worldPos2 = mul(unity_ObjectToWorld, float4(worldPos, 1.0); //r5
                float4 clipPos = mul(UNITY_MATRIX_VP, worldPos2); //r6
                
                worldNormal = UnityObjectToWorldNormal(worldNormal);
                worldTangent = UnityObjectToWorldDir(worldTangent);; //r2.xyz
                float sign = sign(0.1 + v.normal.x); //r0.y
                float3 worldBinormal(calculateBinormal(float4(worldTangent, sign), worldNormal);
                
                o.indirectLight.xyz shadeSH9(float4(worldNormal.xyz, 1));
                
                o.screenPos.xyzw = ComputeScreenPos(clipPos); //shadowcoords?
                
                o.pos.xyzw = clipPos.xyzw;
                
                TBNW0.x = worldTangent.x;
                TBNW0.y = worldBinormal.x;
                TBNW0.z = worldNormal.x;
                TBNW0.w = worldPos2.x;
                
                TBNW1.x = worldTangent.y;
                TBNW1.y = worldBinormal.y;
                TBNW1.z = worldNormal.y;
                TBNW1.w = worldPos2.y;
                
                TBNW2.x = worldTangent.z;
                TBNW2.y = worldBinormal.z;
                TBNW2.z = worldNormal.z;
                TBNW2.w = worldPos2.z;
                
                float texU = t / 17.0;
                o.texUV_t_state.x = texU;
                o.texUV_t_state.y = texV;
                
                o.texUV_t_state.z = t;
                
                o.texUV_t_state.w = _BeltStateBuffer[nodeIndex];
                
                o.worldPos.xyz = worldPos.yzw;
                
                o.emissUV.x = v.vertex.z; //z = 0 to 1 in the direction of travel
                o.emissUV.y = texV;
                
                o.unk.xyzw = float4(0,0,0,0);
                
                return o;

            }

            fout frag(v2f inp)
            {
                fout o;
                
                float t = texUV_t_state.z;
                if (t < 0.5)
                    discard;
                
                float2 texUV = texUV_t_state.xy;
                float2 clip = tex2Dlod(_ClipTex, float4(texUV, 0, 0)).xz; //r0.xy
                if (clip.x < 0.5)
                    discard;
                    
                distCamToPos = distance(i.worldPos, _WorldSpaceCameraPos); //r0.z
                
                float2 deriv;
                deriv.x = ddx_coarse(texUV.y);
                deriv.y = ddy_coarse(texUV.y);
                float mip = log2(length(deriv.xy)) + 8.0; //r0.w
                
                texUV.x = abs(texUV.y - 0.5) < 0.34 ? texUV.x - frac(_Time.y * (60.0 / 17.0) * _UVSpeed) : texUV.x; //r1.xy
                
                float albedo = tex2Dlod(_MainTex, float4(texUV.xy, 0, mip).xyz); //r2.xyz
                albedo.xyz = albedo.xyz * lerp(float3(1, 1, 1), _Color.xyz, clip.y); //r2.xyz
                
                float3 unpackedNormal = UnpackNormal(tex2Dlod(_NormalTex, float4(texUV.xy, 0, mip)));
                unpackedNormal = normalize(unpackedNormal); //r3.xyz
                
                float2 metalSmooth = tex2Dlod(_MSTex, float4(texUV.xy, 0, mip)).xw; //r0.xy
                float3 emiss = tex2D(_EmissionTex, i.uv.xy); //r1.xyz
                
                float3 upDir = normalize(i.worldPos.xyz); //r4.xyz
                
                emiss.xyz = emiss.xyz * min(10, max(1, 1000 / distCamToPos)); //r1.xyz
                
                float sunAngle = dot(upDir.xyz, _Global_SunDir.xyz); //noon = 1, perpendicular = 0, midnight = -1 (sundir is planet to star, right?)
                float3 nightLightColor = _EmissionColor.xyz * saturate(-500 * sunAngle); //r5.xyz
                nightLightColor = nightLightColor.xyz * emiss.xyz; //r6.xyz
                
                //state is set in BuildTool_BlueprintCopy.UpdatePreviewModels(BuildModel model) and CargoTraffic.SetBeltSelected(int beltId)
                float state = texUV_t_state.w;
                bool isOrangeBelt = state > 0.5 && state < 1.5 // == 1
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
                
                UNITY_LIGHT_ATTENUATION(atten, inp, worldPos); //r0.w
                
                float3 viewDir = normalize(_WorldSpaceCameraPos - worldPos); //r6.xyz
                
                //tranform normal from tangent to world space
                float3 worldNormal;
                worldNormal.x = dot(TBNW0.xyz, unpackedNormal.xyz);
                worldNormal.y = dot(TBNW1.xyz, unpackedNormal.xyz);
                worldNormal.z = dot(TBNW2.xyz, unpackedNormal.xyz);
                worldNormal.xyz = normalize(worldNormal.xyz); //r1.xyz
                
                //light vars
                float metallic = saturate(metalSmooth.x * 0.85 + 0.149); //r0.x
                float perceptualRoughness = saturate(1.0 - metalSmooth.y * 0.97); //r1.w
                
                float3 lightDir = _WorldSpaceLightPos0.xyz;
                float halfDir = nomalize(viewDir + lightDir); //r3.xyz
                
                float roughness = perceptualRoughness * perceptualRoughness; //r0.z
                float roughnessSqr = roughness * roughness; //r2.w
                
                float unclamped_NdotL = dot(worldNormal, lightDir); //r3.w
                float NdotL = max(0, unclamped_NdotL); //r4.w
                float NdotV = max(0, dot(worldNormal, viewDir)); //r5.x
                float NdotH = max(0, dot(worldNormal, halfDir)); //r5.y
                float VdotH = max(0, dot(viewDir, halfDir)); //r3.x
                
                r3.y = ;
                
                float UpdotL = dot(upDir, lightDir); //r3.z
                float NdotUp = dot(worldNormal, upDir); //r3.w
                //float UpdotUp = dot(upDir, upDir); //r5.z
                
                
                float reflectivity; //r1.w
                float3 reflectColor = reflection(perceptualRoughness, metallic, upDir, viewDir, worldNormal, /*out*/ reflectivity); //r8.xyz
                
                float3 sunlightColor = calculateSunlightColor(_LightColor0.xyz, UpdotL, _Global_SunsetColor0.xyz, _Global_SunsetColor1.xyz, _Global_SunsetColor2.xyz); //r9.xyz
                
                //r5.z = saturate(0.15 * UpdotL);
                //r5.w = saturate(3.0 * UpdotL);
                
                r0.w = 0.8 * lerp(atten, 1.0, saturate(0.15 * UpdotL));
                
                r5.z = 0.5 + metallic; //metallic high
                sunlightColor.xyz = r0.www * sunlightColor.xyz;
                
                //PBR 
                r0.w = r5.y * r5.y;
                r10.xy = r0.zz * r0.zz + float2(-1,1);
                r0.z = r0.w * r10.x + 1;
                r0.z = rcp(r0.z);
                r0.z = r0.z * r0.z;
                r0.z = r0.z * r2.w;
                r0.z = 0.25 * r0.z;
                r0.w = r10.y * r10.y;
                r2.w = 0.125 * r0.w;
                r0.w = -r0.w * 0.125 + 1;
                r5.x = r5.x * r0.w + r2.w;
                r0.w = r4.w * r0.w + r2.w;
                r2.w = 1 + -r5.z;
                r5.y = r3.x * -5.55472994 + -6.98316002;
                r3.x = r5.y * r3.x;
                r3.x = exp2(r3.x);
                r2.w = r2.w * r3.x + r5.z;
                r0.z = r2.w * r0.z;
                r0.w = r5.x * r0.w;
                r0.w = rcp(r0.w);
                
                float3 ambientTwilight = lerp(_Global_AmbientColor2.xyz, _Global_AmbientColor1.xyz, saturate(upDotL * 3.0 + 1)); //-33% to 0%
                float3 ambientLowSun = lerp(_Global_AmbientColor1.xyz, _Global_AmbientColor0.xyz, saturate(upDotL * 3.0)); // 0% - 33%
                float3 ambientColor = upDotL > 0 ? ambientLowSun : ambientTwilight; //r5.xyz
                
                float3 ambientLightColor = ambientColor * saturate(NdotUp * 0.3 + 0.7); //r10.xyz
                ambientLightColor = ambientLightColor * pow(unclamped_NdotL * 0.35 + 1.0, 3.0); //r3.xyw
                
                //headlamp
                float3 headlampLight = float3(0, 0, 0); //r1.xyz
                if (_Global_PointLightPos.w >= 0.5) {
                    float fadeIn = saturate(5 * dot(-upDir.xyz, _WorldSpaceLightPos0.xyz))
                    float headlampPower = fadeIn * saturate(length(_Global_PointLightPos.xyz) - 5); //r7.w //diff
                    
                    float3 objToHeadlamp = _Global_PointLightPos.xyz - upDir.xyz * (length(_Global_PointLightPos.xyz) - 5); //r10.xyz
                    float distToHeadlamp = length(objToHeadlamp.xyz); //r6.w
                    
                    float falloff = pow(max(0, (20 - distToHeadlamp) / 20.0), 2.0); //r9.w
                    
                    float3 headlampDir = objToHeadlamp.xyz / distToHeadlamp; //r10.xyz
                    
                    float scaledHeadlampPower = saturate(dot(headlampDir, worldNormal)); //r1.x
                    scaledHeadlampPower = scaledHeadlampPower * falloff * headlampPower; //r1.x
                    
                    headlampLight = distToHeadlamp < 0.001 ? float3(1.3, 1.1, 0.6) * headlampPower : float3(1.3, 1.1, 0.6) * scaledHeadlampPower;
                }
                
                //mix lighting
                r10.xyz = sunlightColor * NdotL * pow(1.0 - metallic, 0.6) + (pow(1.0 - metallic, 0.6) * 0.2 + 0.8) * headlampLight.xyz;
                
                r9.xyz = sunlightColor * lerp(albedo, float3(1,1,1), (1.0 - metallic));
                r9.xyz = (NdotL + headlampLight) * r9.xyz * (r0.z * r0.w + 0.0318309888);
                  
                //extra headlamp
                float3 reflectedHeadlampLight = float3(0, 0, 0); //r0.yzw
                if (_Global_PointLightPos.w >= 0.5) {
                    float fadeIn = saturate(5 * dot(-upDir.xyz, _WorldSpaceLightPos0.xyz));
                    float headlampPower = fadeIn * saturate(length(_Global_PointLightPos.xyz) - 20); //r0.w
                    
                    float3 objToHeadlamp = _Global_PointLightPos.xyz - upDir.xyz * (length(_Global_PointLightPos.xyz) - 20); //r4.xyz
                    float distToHeadlamp = length(objToHeadlamp); //r0.z
                    
                    float falloff = pow(max(0, (40 - distToHeadlamp) / 40.0), 2.0); //r2.w
                    
                    float3 headlampDir = objToHeadlamp / distToHeadlamp; //r4.xyz
                    float3 reflectDir = reflect(-viewDir, worldNormal);
                    
                    float scaledHeadlampPower = saturate(dot(reflectDir, headlampDir)); //r6 = reflect() from reflection() :(
                    scaledHeadlampPower = metalSmooth.y * 20.0 * pow(scaledHeadlampPower, pow(1000.0, metalsmooth.y));
                    scaledHeadlampPower = scaledHeadlampPower * falloff * headlampPower;
                    
                    reflectedHeadlampLight = distToHeadlamp < 0.001 ? float3(1.3, 1.1, 0.6) * headlampPower : float3(1.3, 1.1, 0.6) * scaledHeadlampPower;
                }
                //reflectedHeadlampLight = reflectedHeadlampLight * ((1.0 - metallic) * albedo.x * 0.2 + metallic); //r0.yzw
                
                //mix lighting
                float3 scaledAlbedo = albedo.xyz * float3(0.5, 0.5, 0.5) + float3(0.5, 0.5, 0.5); //r4.xyz
                float scaleUNK = (1 - metallic) * albedo.x * 0.2 + metallic;
                r0.yzw = scaleUNK * (r9.xyz + scaledAlbedo * reflectedHeadlampLight);
                
                float greyscaleAmbient = 0.003 + dot(ambientColor.xyx, float3(0.3, 0.6, 0.1)); //r2.w
                float maxAmbient = 0.003 + max(_Global_AmbientColor0.z, max(_Global_AmbientColor0.x, _Global_AmbientColor0.y)); //r4.x
                
                float3 reflectAmbient = lerp(greyscaleAmbient.xxx, ambientColor.xyz, float3(0.4, 0.4, 0.4)) / maxAmbient; //r4.xyz
                reflectColor = albedo * (reflectColor * float3(1.7, 1.7, 1.7) * reflectAmbient * (saturate(UpdotL * 2.0 + 0.5) * 0.7 + 0.3) + headlampLight);
                
                r0.xyz = ambientLightColor * albedo * (1.0 - metallic * 0.6) + r10.xyz * albedo + r0.yzw;
                r0.xyz = lerp(r0.xyz, reflectColor, reflectivity);
                
                
                //finalize
                r0.w = dot(r0.xyz, float3(0.3, 0.6, 0.1));
                r1.x = r0.w > 1.0;
                r1.yzw = r0.xyz / r0.www;
                r0.w = log2(r0.w);
                r0.w = r0.w * 0.693147182 + 1;
                r0.w = log2(r0.w);
                r0.w = r0.w * 0.693147182 + 1;
                r1.yzw = r1.yzw * r0.www;
                r0.xyz = r1.xxx ? r1.yzw : r0.xyz;
                
                o0.xyz = albedo * i.indirectLight + r0.xyz + nightLightColor;
                o0.w = 1;
                return o;
            }
            ENDCG
        }
        
        Pass {
            Name "ShadowCaster"
            LOD 200
            Tags { "LIGHTMODE" = "SHADOWCASTER" "RenderType" = "Opaque" "SHADOWSUPPORT" = "true" }
            GpuProgramID 190269
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 5.0
            
            #include "UnityCG.cginc"
            
            struct v2f
            {
                float4 position : SV_POSITION0;
                float4 texcoord1 : TEXCOORD1;
                float3 texcoord2 : TEXCOORD2;
                float2 texcoord3 : TEXCOORD3;
            };
            
            struct fout
            {
                float4 sv_target : SV_Target0;
            };

            float _NodeWidth;
            sampler2D _ClipTex;
            
            v2f vert(appdata_full v)
            {
                v2f o;
                float4 r0;
                float4 r1;
                float4 r2;
                float4 r3;
                float4 r4;
                float4 r5;
                float4 r6;
                r0.x = _NodeWidth - 1.0;
                r0.x = v.vertex.z * r0.x + 0.4;
                r0.x = r0.y * _NodeWidth + r0.x;
                r1 = ((float4[1])rsc0.Load(r0.x))[0];
                o.texcoord1.w = ((float4[1])rsc1.xxxx.Load(r0.x))[0];
                r0.y = r1.x > 0.5;
                if (r0.y) {
                    r0 = ((float4[1])rsc0.Load(r0.x))[1];
                    r2 = r0.zzxy + r0.zzxy;
                    r3.xyz = r0.xyz * r2.zwy;
                    r4 = r0.xyww * r2;
                    r0.z = r0.w * r2.y;
                    r3.xyz = r3.zzy + r3.yxx;
                    r3.xyz = float3(1.0, 1.0, 1.0) - r3.xyz;
                    r5.xy = r3.xy * v.vertex.xy;
                    r0.w = r0.x * r2.w + -r0.z;
                    r6.x = r0.w * v.vertex.y + r5.x;
                    r0.z = r0.x * r2.w + r0.z;
                    r6.y = r0.z * v.vertex.x + r5.y;
                    r0.xy = r0.yx * r2.yx + -r4.zw;
                    r2.xy = r4.wz + r4.xy;
                    r2.z = r2.y * v.vertex.y;
                    r6.z = r0.y * v.vertex.x + r2.z;
                    r1.yzw = r1.yzw + r6.xyz;
                    r2.zw = r3.xy * v.normal.xy;
                    r0.w = r0.w * v.normal.y + r2.z;
                    r2.y = r2.y * v.normal.y;
                    r4.x = r2.x * v.normal.z + r0.w;
                    r0.z = r0.z * v.normal.x + r2.w;
                    r4.y = r0.x * v.normal.z + r0.z;
                    r0.x = r0.y * v.normal.x + r2.y;
                    r4.z = r3.z * v.normal.z + r0.x;
                } else {
                    r4.xyz = float3(0.0, 0.0, 0.0);
                    r1.yzw = float3(0.0, 0.0, 0.0);
                }
                r0.x = v.vertex.x + 0.5;
                r0.y = v.vertex.y * v.normal.x;
                r0.x = -r0.y * 0.666666 + r0.x;
                r0.x = 1.0 - r0.x;
                r2 = r1.zzzz * unity_ObjectToWorld._m01_m11_m21_m31;
                r2 = unity_ObjectToWorld._m00_m10_m20_m30 * r1.yyyy + r2;
                r2 = unity_ObjectToWorld._m02_m12_m22_m32 * r1.wwww + r2;
                r2 = r2 + unity_ObjectToWorld._m03_m13_m23_m33;
                r0.y = unity_LightShadowBias.z != 0.0;
                r3.x = dot(r4.xyz, unity_WorldToObject._m00_m10_m20);
                r3.y = dot(r4.xyz, unity_WorldToObject._m01_m11_m21);
                r3.z = dot(r4.xyz, unity_WorldToObject._m02_m12_m22);
                r0.z = dot(r3.xyz, r3.xyz);
                r0.z = rsqrt(r0.z);
                r3.xyz = r0.zzz * r3.xyz;
                r4.xyz = -r2.xyz * _WorldSpaceLightPos0.www + _WorldSpaceLightPos0.xyz;
                r0.z = dot(r4.xyz, r4.xyz);
                r0.z = rsqrt(r0.z);
                r4.xyz = r0.zzz * r4.xyz;
                r0.z = dot(r3.xyz, r4.xyz);
                r0.z = -r0.z * r0.z + 1.0;
                r0.z = sqrt(r0.z);
                r0.z = r0.z * unity_LightShadowBias.z;
                r3.xyz = -r3.xyz * r0.zzz + r2.xyz;
                r0.yzw = r0.yyy ? r3.xyz : r2.xyz;
                r3 = r0.zzzz * unity_MatrixVP._m01_m11_m21_m31;
                r3 = unity_MatrixVP._m00_m10_m20_m30 * r0.yyyy + r3;
                r3 = unity_MatrixVP._m02_m12_m22_m32 * r0.wwww + r3;
                r2 = unity_MatrixVP._m03_m13_m23_m33 * r2.wwww + r3;
                r0.y = unity_LightShadowBias.x / r2.w;
                r0.y = min(r0.y, 0.0);
                r0.y = max(r0.y, -1.0);
                r0.y = r0.y + r2.z;
                r0.z = min(r2.w, r0.y);
                r0.z = r0.z - r0.y;
                o.position.z = unity_LightShadowBias.y * r0.z + r0.y;
                o.position.xyw = r2.xyw;
                o.texcoord1.xz = r1.xx * float2(0.0588235, 1.0);
                o.texcoord1.y = r0.x;
                o.texcoord2.xyz = r1.yzw;
                o.texcoord3.x = v.vertex.z;
                o.texcoord3.y = r0.x;
                return o;
            }
            
            fout frag(v2f i)
            {
                fout o;
                
                if (i.texcoord1.z < 0.5)
                    discard;

                float clip = tex2Dlod(_ClipTex, float4(i.texcoord1.xy, 0, 0)).x;
                if (clip < 0.5)
                    discard;
                    
                o.sv_target = float4(0.0, 0.0, 0.0, 0.0);
                
                return o;
            }
            ENDCG
        }
    }
    Fallback "Diffuse"
}