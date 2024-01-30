Shader "VF Shaders/Batching/Cargo Instancing" {
    Properties {
        _Color ("Color", Color) = (1,1,1,1)
        _Multiplier ("Multiplier", Float) = 1.6
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0, 1)) = 0.5
        _Metallic ("Metallic", Range(0, 1)) = 0
        _InstOfs ("Instance Offset", Float) = 0
        _IncArrowColor ("Inc Arrow Color", Vector) = (1,1,1,1)
        _StackNumber1 ("Stack Number 1", 2D) = "black" {}
        _StackNumber2 ("Stack Number 2", 2D) = "black" {}
        _StackNumber3 ("Stack Number 3", 2D) = "black" {}
        _StackNumber4 ("Stack Number 4", 2D) = "black" {}
        _IncArrowNumber1 ("Inc Arrow 1", 2D) = "black" {}
        _IncArrowNumber2 ("Inc Arrow 2", 2D) = "black" {}
        _IncArrowNumber3 ("Inc Arrow 3", 2D) = "black" {}
    }
    SubShader {
        LOD 200
        Tags { "DisableBatching" = "true" "QUEUE" = "Geometry+20" "RenderType" = "Opaque" }
        GrabPass {
            "_ScreenTex"
        }
        Pass {
            Name "FORWARD"
            LOD 200
            Tags { "DisableBatching" = "true" "LIGHTMODE" = "FORWARDBASE" "QUEUE" = "Geometry+20" "RenderType" = "Opaque" "SHADOWSUPPORT" = "true" }
            GpuProgramID 57752
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 5.0
            #pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight
            #pragma enable_d3d11_debug_symbols
            
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "CGIncludes/DSPCommon.cginc"
            
            struct Cargo
            {
                uint stack_inc_item;
                float3 position;
                float4 rotation;
            };
            
            /*
            struct IconSet {
                float4 faceColor; //[0-3] //only xyz is used on colors
                float4 sideColor; //[4-7]
                float4 faceEmission; //[8-11]
                float4 sideEmission; //[12-15]
                float4 iconEmission; //[16-19]
                float4 reserved0; //[20-23]
                float4 reserved1; //[24-27]
                float metallic; //[28]
                float smoothness; //[29]
                float solidAlpha; //[30]
                float iconAlpha; //[31]
                float iconVari; //[32]
                float liquidity; //[33] //used by vertex
                float prop0; //[34]
                float prop1; //[35]
                float prop2; //[36]
                float prop3; //[37]
                float prop4; //[38]
                float prop5; //[39]
            };
            */
            
            StructuredBuffer<Cargo> _Buffer;
            StructuredBuffer<uint> _IndexBuffer;
            StructuredBuffer<float> _Global_ItemDescBuffer;
            
            struct v2f {
                float4 pos : SV_POSITION;
                float4 TBNW0 : TEXCOORD0;
                float4 TBNW1 : TEXCOORD1;
                float4 TBNW2 : TEXCOORD2;
                float4 uv_height_itemId : TEXCOORD3;
                float4 iconCol_Row_Idx_itemId : TEXCOORD4;
                float3 upDir : TEXCOORD5;
                float4 grabScreenPos : TEXCOORD6;
                float3 normal : TEXCOORD7;
                float4 vertZY_inc_stack : TEXCOORD8;
                float4 indirectLight : TEXCOORD9;
                UNITY_SHADOW_COORDS(11)
                float4 unkUnused : TEXCOORD12;
            };
            
            struct fout
            {
                float4 sv_target : SV_Target0;
            };
            
            float _InstOfs;
            float4 _LightColor0;
            float4 _Global_AmbientColor0;
            float4 _Global_AmbientColor1;
            float4 _Global_AmbientColor2;
            float4 _Global_SunsetColor0;
            float4 _Global_SunsetColor1;
            float4 _Global_SunsetColor2;
            float4 _Global_PointLightPos;
            float4 _IncArrowColor;
            float _Multiplier;

            sampler2D _MainTex;
            sampler2D _IncArrowNumber3;
            sampler2D _IncArrowNumber2;
            sampler2D _IncArrowNumber1;
            sampler2D _ScreenTex;
            //samplerCUBE _Global_PGI;
            
            v2f vert(appdata_full v, uint instanceID: SV_InstanceID)
            {
                v2f o;
                
                uint instanceOffset = 0.4 + _InstOfs;
                int cargoId = (int)instanceOffset + (int)instanceID; //r0.z
                
                uint stack_inc_item = _Buffer[cargoId].stack_inc_item; //r1.x
                float3 pos = _Buffer[cargoId].position; //r1.yzw
                
                int itemId = (uint)stack_inc_item >> 16; //r0.w
                int stack = (int)stack_inc_item & 255; //r2.x
                int inc = (uint)stack_inc_item << 16;
                inc = (uint)inc >> 24; //r1.x
                
                o.vertZY_inc_stack.z = (uint)inc;
                o.vertZY_inc_stack.w = (uint)stack;
                uint itemIdUINT = (uint)itemId; //r3.w
                
                uint itemIconIndex = _IndexBuffer[itemId]; //r4.z
                
                float4 rot = _Buffer[cargoId].rotation; // r5.xyzw
                
                float stackOffsets[4];
                stackOffsets[0] = -0.05;
                stackOffsets[1] = 0.02;
                stackOffsets[2] = 0.07;
                stackOffsets[3] = 0.15;
                
                float3 stackedVertex = v.vertex.xyz;
                if (v.vertex.y > 0.1) {
                    uint stackIndex = min(3, (uint)((int)stack - 1)); //r0.w
                    stackedVertex.y += stackOffsets[stackIndex];
                }
                
                float3 worldPos = rotate_vector_fast(stackedVertex, rot) + pos; //r6.xyz
                float3 worldNormal = rotate_vector_fast(v.normal.xyz, rot); //r7.xyz
                
                bool isValidItem = itemIdUINT > 0.5;
                worldNormal = isValidItem ? worldNormal : float3(0, 0, 0); //r2.xyw
                worldPos = isValidItem ? worldPos : float3(0, 0, 0); //r5.xyz
                
                float iconColumn = itemIconIndex / 25.0; //r4.x
                float iconRow = floor(0.001 + iconColumn) / 25.0; //r4.y
                float2 uv;
                uv.x = ((0.5 - 2.0 * v.vertex.z) / 25.0) + iconColumn;
                uv.y = ((0.5 + 2.0 * v.vertex.x) / 25.0) + iconRow; //r3.xy
                
                float4 clipPos = UnityObjectToClipPos(worldPos);
                float4 grabScreenPos = ComputeGrabScreenPos(clipPos);
                
                int idxLiquidity = (uint)(0.49999 + itemIconIndex) * 40 + 33;
                float liquidity = _Global_ItemDescBuffer[idxLiquidity]; //r0.z
                
                float2 screenPosOffset = uv.xy * float2(1000,1000) + (uint)cargoId; //r7.xy
                screenPosOffset.x = sin(screenPosOffset.x * 10.0 + 2.0 * _Time.y * liquidity) * 0.4 + worldNormal.x;
                screenPosOffset.y = sin(screenPosOffset.y * 10.0 + 2.0 * _Time.z * liquidity) * 0.4 + worldNormal.y;
                screenPosOffset *= float2(0.2, 0.35554);
                grabScreenPos.xy = grabScreenPos.xy + screenPosOffset.xy;
                
                worldNormal = UnityObjectToWorldNormal(worldNormal); //r2.xyz
                float3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz); //r0.yzw
                float3 worldBinormal = calculateBinormal(float4(worldTangent, v.tangent.w), worldNormal); //r7.xyz
                
                o.pos.xyzw = clipPos.xyzw;
                o.indirectLight.xyz = ShadeSH9(float4(worldNormal.xyz, 1));
                UNITY_TRANSFER_SHADOW(o, float(0,0))
                
                o.TBNW0.x = worldTangent.x;
                o.TBNW0.y = worldBinormal.x;
                o.TBNW0.z = worldNormal.x;
                o.TBNW0.w = worldPos.x;
                
                o.TBNW1.x = worldTangent.y;
                o.TBNW1.y = worldBinormal.y;
                o.TBNW1.z = worldNormal.y;
                o.TBNW1.w = worldPos.y;
                
                o.TBNW2.x = worldTangent.z;
                o.TBNW2.y = worldBinormal.z;
                o.TBNW2.z = worldNormal.z;
                o.TBNW2.w = worldPos.z;
                
                o.uv_height_itemId.xy = uv.xy;
                o.uv_height_itemId.z = 1.0 - v.vertex.y * 4.0;
                o.uv_height_itemId.w = itemIdUINT;
                
                o.iconCol_Row_Idx_itemId.x = iconColumn;
                o.iconCol_Row_Idx_itemId.y = iconRow;
                o.iconCol_Row_Idx_itemId.z = itemIconIndex;
                o.iconCol_Row_Idx_itemId.w = itemIdUINT;
                
                o.upDir.xyz = normalize(pos);
                o.grabScreenPos.xyzw = grabScreenPos.xyzw;
                o.normal.xyz = v.normal.xyz;
                o.vertZY_inc_stack.xy = v.vertex.zy;
                
                
                o.unkUnused.xyzw = float4(0,0,0,0);
                
                return o;
            }
            
            fout frag(v2f i)
            {
                fout o;
                
                if (i.iconCol_Row_Idx_itemId.w < 0.5) //v4.w
                    discard;
                
                float4 color = tex2D(_MainTex, i.uv_height_itemId.xy).xyzw; //r0.xyzw //icon grid
                
                uint itemIconIndex = (uint)(0.49999 + i.iconCol_Row_Idx_itemId.z); //r1.x
                int itemDescBaseIndex = (int)itemIconIndex * 40;
                
                int idxIconVari = itemDescBaseIndex + 32; //r2.x
                float iconVari = _Global_ItemDescBuffer[idxIconVari]; //r1.z
                color.xyz = lerp(color.xyz, float3(1,1,1), iconVari);
                color.xyz = color.xyz / _Multiplier; //cb0[46]
                
                (iconVari * (color - 1) + 1) / multiplier
                
                int idxIconAlpha = itemDescBaseIndex + 31;
                float iconAlpha = _Global_ItemDescBuffer[idxIconAlpha];
                color.w = iconAlpha * color.w;
                
                uint inc = (uint)round(i.vertZY_inc_stack.z); //v9.zw //r1.z // r2.x
                uint stack = (uint)round(i.vertZY_inc_stack.w); //v9.zw //r1.w //r2.y
                
                uint effectiveInc = round(inc / stack); //r1.z
                
                float2 arrowUV;
                arrowUV.y = saturate(4.0 * i.vertZY_inc_stack.y); //v9.y vertex.zy
                float texIncArrow = 0;
                float vertZ = i.vertZY_inc_stack.x;
                if (effectiveInc >= 4) {
                    arrowUV.x = vertZ * 2.0 + 0.5;
                    texIncArrow = tex2D(_IncArrowNumber3, arrowUV).w;
                    texIncArrow = 2.0 * texIncArrow;
                } else if (effectiveInc >= 2) {
                    arrowUV.x = vertZ * 2.0 + 0.5;
                    texIncArrow = tex2D(_IncArrowNumber2, arrowUV).w;
                    texIncArrow = 2.0 * texIncArrow;
                } else if (effectiveInc >= 1) {
                    arrowUV.x = vertZ * 2.0 + 0.5;
                    texIncArrow = tex2D(_IncArrowNumber1, arrowUV).w;
                    texIncArrow = 2.0 * texIncArrow;
                }
                
                float height = i.uv_height_itemId.z;
                float2 normalDir = float2(0,0);
                if (stack == 2) {
                    float heightX = 0.5 - height;
                    normalDir.x = abs(heightX) < 0.04 ? (int)-sign(heightX) : (int)sign(heightX);
                    normalDir.y = abs(heightX) < 0.04 ? heightX : 0;
                } else if (stack == 3) {
                    float heightX = 0.333 - height; //r3.x
                    float heightY = 0.666 - height; //r3.y
                    normalDir.x = abs(heightY) < 0.03666 ? -sign(heightY) : (abs(heightX) < 0.03666 ? -sign(heightX) : 0);
                    normalDir.y = abs(heightY) < 0.03666 ? sign(heightY) : (abs(heightX) < 0.03666 ? sign(heightX) : 0);
                } else if (stack == 4) {
                    float heightX = 0.25 - height; //r3.x
                    float heightY = 0.5 - height; //r3.y
                    float heightZ = 0.75 - height; //r3.z
                    normalDir.x = abs(heightZ) < 0.0333 ? -sign(heightZ) : (abs(heightY) < 0.0333 ? -sign(heightY) : (abs(heightX) < 0.0333 ? -sign(heightX) : 0));
                    normalDir.y = abs(heightZ) < 0.0333 ? sign(heightZ) : (abs(heightY) < 0.0333 ? sign(heightY) : (abs(heightX) < 0.0333 ? sign(heightX) : 0));
                }
                
                float3 normal;
                normal.x = 1.1 * i.normal.x * normalDir.x;
                normal.y = abs(i.normal.z) * normalDir.y;
                normal.z = 1;
                normal.xyz = normalize(normal.xyz);
                
                color.w = saturate(color.w * 1.05 - 0.05);
                
                float3 faceColor; //r4.xyz
                int idxFaceColor = itemDescBaseIndex;
                faceColor.x = _Global_ItemDescBuffer[idxFaceColor];
                idxFaceColor = itemDescBaseIndex + 1;
                faceColor.y = _Global_ItemDescBuffer[idxFaceColor];
                idxFaceColor = itemDescBaseIndex + 2;
                faceColor.z = _Global_ItemDescBuffer[idxFaceColor];
                faceColor = GammaToLinear_Approx(faceColor);
                
                float3 sideColor;
                int idxSideColor = itemDescBaseIndex + 4;
                sideColor.x = _Global_ItemDescBuffer[idxSideColor];
                idxSideColor = itemDescBaseIndex + 5;
                sideColor.y = _Global_ItemDescBuffer[idxSideColor]
                idxSideColor = itemDescBaseIndex + 6;
                sideColor.z = _Global_ItemDescBuffer[idxSideColor]
                sideColor = GammaToLinear_Approx(sideColor);
                
                float3 faceEmission;
                int idxFaceEmission = itemDescBaseIndex + 8;
                faceEmission.x = _Global_ItemDescBuffer[idxFaceEmission];
                idxFaceEmission = itemDescBaseIndex + 9;
                faceEmission.y = _Global_ItemDescBuffer[idxFaceEmission];
                idxFaceEmission = itemDescBaseIndex + 10;
                faceEmission.z = _Global_ItemDescBuffer[idxFaceEmission];
                faceEmission = GammaToLinear_Approx(faceEmission);
                
                float3 sideEmission;
                int idxSideEmission = itemDescBaseIndex + 12;
                sideEmission.x = _Global_ItemDescBuffer[idxSideEmission];
                idxSideEmission = itemDescBaseIndex + 13;
                sideEmission.y = _Global_ItemDescBuffer[idxSideEmission];
                idxSideEmission = itemDescBaseIndex + 14;
                sideEmission.z = _Global_ItemDescBuffer[idxSideEmission];
                sideEmission = GammaToLinear_Approx(sideEmission);
                
                float3 iconEmission;
                int idxIconEmission = itemDescBaseIndex + 16;
                iconEmission.x = _Global_ItemDescBuffer[idxIconEmission];
                idxIconEmission = itemDescBaseIndex + 17;
                iconEmission.y = _Global_ItemDescBuffer[idxIconEmission];
                idxIconEmission = itemDescBaseIndex + 18;
                iconEmission.z = _Global_ItemDescBuffer[idxIconEmission];
                iconEmission = GammaToLinear_Approx(iconEmission);
                iconEmission = iconEmission * color.xyz * color.www; //r1.xyw
                
                float faceOrSide = 1.0 - min(1, abs(i.normal.y)); //r2.y
                float3 emission = lerp(faceEmission, sideEmission, faceOrSide); //r2.yzw
                emission = emission * float3(5,5,5) + iconEmission * float3(10,10,10); //r1.xyw
                
                float3 albedo = lerp(faceColor, sideColor, faceOrSide); //r4.xyz
                albedo = lerp(albedo.xyz, color.xyz, color.w); //r4.xyz
                albedo = _Multiplier * albedo; //r5.xyz
                
                float metalSmoothModifier = 1.0 - color.w * (0.4 + dot(color.xyz, float3(0.15, -0.2, -0.1))); //r0.x
                
                float2 grabUV = i.grabScreenPos.xy / i.grabScreenPos.ww; //r0.yz
                float3 screenTex = tex2D(_ScreenTex, grabUV).xyz; //r0.yzw

                int idxMetallic = itemDescBaseIndex + 28;
                float metallic = _Global_ItemDescBuffer[idxMetallic];
                metallic = metallic * metalSmoothModifier; //r3.w
                
                int idxSmoothness = itemDescBaseIndex + 29;
                float smoothness = _Global_ItemDescBuffer[idxSmoothness];
                smoothness = smoothness * metalSmoothModifier; //r0.x
                
                int idxSolidAlpha = itemDescBaseIndex + 30;
                float solidAlpha = _Global_ItemDescBuffer[idxSolidAlpha];
                solidAlpha = 1.0 - solidAlpha; //r2.y
                
                emission = texIncArrow * _IncArrowColor.xyz + screenTex * albedo * solidAlpha + emission;
                
                uint itemId = round(i.iconCol_Row_Idx_itemId.w);
                bool isWhiteCube = (int)itemId == 6006;
                emission = isWhiteCube ? (1.0 - saturate(texIncArrow)) * emission : emission; //r0.yzw
                
                float3 worldPos;
                worldPos.x = i.TBNW0.w;
                worldPos.y = i.TBNW1.w;
                worldPos.z = i.TBNW2.w;
                
                UNITY_LIGHT_ATTENUATION(atten, i, worldPos); // r1.y
                
                float3 viewDir = normalize(_WorldSpaceCameraPos - worldPos); //r6.xyz
                
                float3 worldNormal;
                worldNormal.x = dot(i.TBNW0.xyz, normal.xyz);
                worldNormal.y = dot(i.TBNW1.xyz, normal.xyz);
                worldNormal.z = dot(i.TBNW2.xyz, normal.xyz);
                worldNormal = normalize(worldNormal.xyz); //r3.xyz
                
                metallic = saturate(metallic * 0.85 + 0.149); //r1.z
                float perceptualRoughness = saturate(1.0 - smoothness * 0.97); //r1.w
                
                float3 halfDir = viewDir + _WorldSpaceLightPos0.xyz;
                halfDir = normalize(halfDir); //r2.xyz
                
                float roughness = perceptualRoughness * perceptualRoughness; //r1.x
                //r2.w = r1.x * r1.x;

                float3 lightDir = _WorldSpaceLightPos0.xyz;
                
                float unclamped_NdotL = dot(worldNormal.xyz, lightDir); //r3.w
                float NdotL = max(0, unclamped_NdotL); //r4.w
                float NdotV = max(0, dot(worldNormal, viewDir)); //r5.w
                float NdotH = max(0, dot(worldNormal, halfDir)); //r6.w
                float VdotH = max(0, dot(viewDir, halfDir)); //r2.x
                
                float UpdotL = dot(i.upDir.xyz, lightDir); //r2.z
                float NdotUp = dot(worldNormal.xyz, i.upDir.xyz); //r3.w
                float UpdotUp = dot(i.upDir.xyz, i.upDir.xyz); //r7.x
                
                float reflectivity; //r1.w
                float3 reflectColor = reflection(perceptualRoughness, metallic, i.upDir.xyz, viewDir, worldNormal, /*out*/ reflectivity); //r7.xyz
                
                float3 sunlightColor = calculateSunlightColor(_LightColor0, UpdotL, _Global_SunsetColor0.xyz, _Global_SunsetColor1.xyz, _Global_SunsetColor2.xyz); //r8.xyz
                
                atten = 0.8 * lerp(atten, 1.0, saturate(0.15 * UpdotL)); //r1.y
                sunlightColor = atten * sunlightColor; //r8.xyz
                
                float specularTerm = INV_TEN_PI + GGX(roughness, metallic + 0.5, NdotH, NdotV, NdotL, VdotH);
                
                float3 ambientColor = calculateAmbientColor(i.upDir, lightDir, _Global_AmbientColor0.xyz, _Global_AmbientColor0.xyz, _Global_AmbientColor0.xyz); //r2.xyw
                //dim light on surfaces that are not pointing up
                float3 ambientLight = ambientColor * saturate(NdotUp * 0.3 + 0.7);
                //multiply light (up to 2.5x) on surfaces that are facing the sun, dim those pointing away (down to 0.3x)
                ambientLight *= pow(unclamped_NdotL * 0.35 + 1.0, 3.0); //r2.xyw
                
                float3 headlampLight = float3(0, 0, 0); //r3.xyz
                if (_Global_PointLightPos.w >= 0.5) {
                    float fadeIn = saturate(5 * dot(-i.upDir.xyz, lightDir));
                    float headlampPower = fadeIn * saturate(length(_Global_PointLightPos.xyz) - 5.0);
                    
                    float3 objToHeadlamp = _Global_PointLightPos.xyz - i.upDir.xyz * (length(_Global_PointLightPos.xyz) - 5);
                    float distToHeadlamp = length(objToHeadlamp.xyz);
                    
                    float falloff = pow(max(0, (20 - distToHeadlamp) / 20.0), 2.0);
                    
                    float3 headlampDir = objToHeadlamp / distToHeadlamp;
                    
                    float scaledHeadlampPower = saturate(dot(headlampDir, worldNormal));
                    scaledHeadlampPower = scaledHeadlampPower * falloff * headlampPower;
                    
                    headlampLight = distToHeadlamp < 0.001 ? float3(1.3, 1.1, 0.6) * headlampPower : float3(1.3, 1.1, 0.6) * scaledHeadlampPower;
                }
                
                float3 diffuseLight = sunlightColor * NdotL * pow(1.0 - metallic, 0.6) + (pow(1.0 - metallic, 0.6) * 0.2 + 0.8) * headlampLight; //r10.xyz
                float3 specularLight = (NdotL + headlampLight) * lerp(float3(1,1,1), albedo.xyz, metallic) * sunlightColor * specularTerm; //r4.xyz
                
                float3 reflectedHeadlampLight = float3(0, 0, 0);
                if (_Global_PointLightPos.w >= 0.5) {
                    float fadeIn = saturate(5 * dot(-i.upDir.xyz, lightDir));
                    float headlampPower = fadeIn * saturate(length(_Global_PointLightPos.xyz) - 20.0);
                    
                    float3 objToHeadlamp = _Global_PointLightPos.xyz - i.upDir.xyz * (length(_Global_PointLightPos.xyz) - 20);
                    float distToHeadlamp = length(objToHeadlamp);
                    
                    float falloff = pow(max(0, (40 - distToHeadlamp) / 40.0), 2.0);
                    
                    float3 headlampDir = objToHeadlamp / distToHeadlamp;
                    float3 reflectDir = reflect(-viewDir, worldNormal);
                    
                    float scaledHeadlampPower = saturate(dot(headlampDir, reflectDir));
                    scaledHeadlampPower = smoothness * 20.0 * pow(scaledHeadlampPower, pow(1000.0, smoothness));
                    scaledHeadlampPower = scaledHeadlampPower * falloff * headlampPower;
                    
                    reflectedHeadlampLight = distToHeadlamp < 0.001 ? float3(1.3, 1.1, 0.6) * headlampPower : float3(1.3, 1.1, 0.6) * scaledHeadlampPower;
                }
                
                specularLight = specularLight * lerp(metallic, 1.0, 0.2 * albedo.x) + (albedo.xyz * float3(0.5,0.5,0.5) + float3(0.5,0.5,0.5)) * reflectedHeadlampLight * lerp(metallic, 1.0, 0.2 * albedo.x); //r4.xyz
                ambientLight = ambientLight * albedo.xyz;
                
                float greyscaleAmbient = 0.003 + dot(ambientColor.xyx, float3(0.3, 0.6, 0.1)); //r1.x
                float maxAmbient = 0.003 + max(_Global_AmbientColor0.z, max(_Global_AmbientColor0.x, _Global_AmbientColor0.y)); //r1.y
                float3 reflectAmbient = lerp(greyscaleAmbient.xxx, ambientColor.xyz, float3(0.4, 0.4, 0.4)) / maxAmbient; //r1.xyz
                
                reflectColor = albedo.xyz * (saturate(UpdotL * 2.0 + 0.5) * 0.7 + 0.3 + headlampLight) * reflectColor * float3(1.7, 1.7, 1.7) * reflectAmbient;
                float3 finalColor = ambientLight * (1.0 - metallic * 0.6) + diffuseLight * albedo.xyz + specularLight;
                
                finalColor = lerp(finalColor, reflectColor, reflectivity);
                
                float luminance = dot(finalColor.xyz, float3(0.3, 0.6, 0.1)); //r0.x
                finalColor = luminance > 1.0 ? (finalColor / luminance) * (log(log(luminance) + 1) + 1) : finalColor; //r1.xyz
                
                o.sv_target.xyz = albedo.xyz * i.indirectLight.xyz + finalColor.xyz + emission;
                o.sv_target.w = 1;
                
                return o;
            }
            ENDCG
        }
        Pass {
            Name "ShadowCaster"
            LOD 200
            Tags { "DisableBatching" = "true" "LIGHTMODE" = "SHADOWCASTER" "QUEUE" = "Geometry+20" "RenderType" = "Opaque" "SHADOWSUPPORT" = "true" }
            GpuProgramID 166528
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 5.0
            #pragma multi_compile_shadowcaster
            #pragma enable_d3d11_debug_symbols
            
            #include "UnityCG.cginc"
            #include "CGIncludes/DSPCommon.cginc"

            struct Cargo
            {
                uint stack_inc_item;
                float3 position;
                float4 rotation;
            };
            
            StructuredBuffer<Cargo> _Buffer;
            StructuredBuffer<uint> _IndexBuffer;
            StructuredBuffer<float> _Global_ItemDescBuffer;
            
            struct v2f_shadow {
                float4 pos : SV_POSITION;
                float4 uv_height_itemId : TEXCOORD1;
                float4 iconCol_Row_Idx_itemId : TEXCOORD2;
                float3 upDir : TEXCOORD3;
                float4 grabScreenPos : TEXCOORD4;
                float3 normal : TEXCOORD5;
                float4 vertZY_inc_stack : TEXCOORD6;
            };
            
            struct fout
            {
                float4 sv_target : SV_Target0;
            };
            
            float _InstOfs;
            
            v2f_shadow vert(appdata_full v, uint instanceID : SV_InstanceID)
            {
                v2f_shadow o;
                
                uint instanceOffset = 0.4 + _InstOfs.x;
                int cargoId = (int)instanceOffset + (int)instanceID;
                
                uint stack_inc_item = _Buffer[cargoId].stack_inc_item;
                float3 pos = _Buffer[cargoId].position;
                
                int itemId = (uint)stack_inc_item >> 16; //r0.w
                int stack = (int)stack_inc_item & 255; //r2.x
                int inc = (uint)stack_inc_item << 16;
                inc = (uint)inc >> 24; //r1.x
                
                o.vertZY_inc_stack.z = (uint)inc;
                o.vertZY_inc_stack.w = (uint)stack;
                uint itemIdUINT = (uint)itemId; //r3.w
                
                uint itemIconIndex = _IndexBuffer[itemId];
                
                float4 rot = _Buffer[cargoId].rotation;
                
                float stackOffsets[4];
                stackOffsets[0] = -0.05;
                stackOffsets[1] = 0.02;
                stackOffsets[2] = 0.07;
                stackOffsets[3] = 0.15;
                
                float3 stackedVertex = v.vertex.xyz;
                if (v.vertex.y > 0.1) {
                    uint stackIndex = min(3, (uint)((int)stack - 1.0));
                    stackedVertex.y += stackOffsets[stackIndex];
                }
                
                float3 worldPos = rotate_vector_fast(stackedVertex, rot) + pos;
                float3 worldNormal = rotate_vector_fast(v.normal.xyz, rot);
                
                bool isValidItem = itemIdUINT > 0.5;
                worldNormal = isValidItem ? worldNormal : float3(0, 0, 0);
                worldPos = isValidItem ? worldPos : float3(0, 0, 0);
                
                //max/min for vertex.x/z is -0.25 to 0.25
                //y from just under 0.0 to 0.30, "cap" starts at 0.26
                float iconColumn = itemIconIndex / 25.0;
                float iconRow = floor(0.001 + iconColumn) / 25.0;
                float2 uv;
                uv.x = ((0.5 - 2.0 * v.vertex.z) / 25.0) + iconColumn;
                uv.y = ((0.5 + 2.0 * v.vertex.x) / 25.0) + iconRow;
                
                float4 clipPos = UnityObjectToClipPos(worldPos);
                float4 grabScreenPos = ComputeGrabScreenPos(clipPos);
                
                int idxLiquidity = (uint)(0.49999 + itemIconIndex) * 40 + 33;
                float liquidity = _Global_ItemDescBuffer[idxLiquidity]; //r0.z
                
                float2 screenPosOffset = uv.xy * float2(1000,1000) + (uint)cargoId; //r7.xy
                screenPosOffset.x = sin(screenPosOffset.x * 10.0 + 2.0 * _Time.y * liquidity) * 0.4 + worldNormal.x;
                screenPosOffset.y = sin(screenPosOffset.y * 10.0 + 2.0 * _Time.z * liquidity) * 0.4 + worldNormal.y;
                screenPosOffset *= float2(0.2, 0.35554);
                grabScreenPos.xy = grabScreenPos.xy + screenPosOffset.xy;
                
                float4 shadowClipPos = UnityClipSpaceShadowCasterPos(float4(worldPos, 1), worldNormal);
                
                o.pos.xyzw = UnityApplyLinearShadowBias(shadowClipPos);
                
                o.uv_height_itemId.xy = uv.xy;
                o.uv_height_itemId.z = 1.0 - 4.0 * v.vertex.y;
                o.uv_height_itemId.w = itemId;
                
                o.iconCol_Row_Idx_itemId.x = iconColumn;
                o.iconCol_Row_Idx_itemId.y = iconRow;
                o.iconCol_Row_Idx_itemId.z = itemIconIndex;
                o.iconCol_Row_Idx_itemId.w = itemId;
                
                o.upDir.xyz = normalize(pos);
                o.grabScreenPos.xyzw = grabScreenPos.xyzw;
                o.vertZY_inc_stack.xy = v.vertex.zy;
                o.normal.xyz = v.normal.xyz;
                
                return o;
            }
            
            float4 frag(v2f_shadow i) : SV_Target
            {
                if (i.uv_height_itemId.w < 0.5)
                    discard;
                    
                return float4(0.0, 0.0, 0.0, 0.0);
            }
            ENDCG
        }
    }
    Fallback "Diffuse"
}