Shader "VF Shaders/Dyson Sphere/Node Inst REPLACE" {
  Properties {
    _Color ("Color", Vector) = (1,1,1,1)
    _MainTex ("Albedo (RGB)", 2D) = "white" {}
    _NormalTex ("Normal Map", 2D) = "bump" {}
    _MSTex ("Metallic Smoothness (RA)", 2D) = "white" {}
    _EmissionTex ("Emission (RGB)", 2D) = "black" {}
    _Size ("Size", Float) = 400
    _Thickness ("Thickness", Float) = 100
    _AlbedoMultiplier ("漫反射倍率", Float) = 1
    _NormalMultiplier ("法线倍率", Float) = 1
    _EmissionMultiplier ("自发光倍率", Float) = 5.5
    _AlphaClip ("透明通道剪切", Float) = 0
  }
  SubShader {
    LOD 200
    Tags { "RenderType" = "DysonNode" }
    Pass {
      LOD 200
      Tags { "LIGHTMODE" = "FORWARDBASE" "RenderType" = "DysonNode" "SHADOWSUPPORT" = "true" }
      //Keywords {"DIRECTIONAL" "LIGHTPROBE_SH"}
      GpuProgramID 7626
      CGPROGRAM
      #pragma vertex vert
      #pragma fragment frag
      #include "UnityCG.cginc"
      #include "AutoLight.cginc"
      #pragma target 5.0
      #pragma enable_d3d11_debug_symbols

      float3 rotate_vector_fast(float3 v, float4 r){ 
        return v + cross(2.0 * r.xyz, cross(r.xyz, v) + r.w * v);
      }

      struct Segment {
        uint layer;
        uint state;
        float3 pos0;
        float3 pos1;
        float progress0;
        float progress1;
        int color;
      };

      struct appdata_part {
          float4 vertex : POSITION;
          float4 tangent : TANGENT;
          float3 normal : NORMAL;
          float4 texcoord : TEXCOORD0;
      };

      struct v2f
      {
        float4 position : SV_POSITION;
        float4 tbnw_matrix_x : TEXCOORD0;
        float4 tbnw_matrix_y : TEXCOORD1;
        float4 tbnw_matrix_z : TEXCOORD2;
        float4 screenPos : TEXCOORD3;
        float4 u_v_radius_state : TEXCOORD4;
        float4 lightray_layer : TEXCOORD5;
        float2 progress : TEXCOORD6;
        float4 color : TEXCOORD7;
        float4 shadowCoords : TEXCOORD8;
      };

      struct fout
      {
        float4 sv_target : SV_Target0;
      };

      StructuredBuffer<Segment> _InstBuffer;

      float3 _SunPosition;
      float4 _LocalRot;
      float3 _SunPosition_Map;
      int _Global_DS_RenderPlace;
      float _Global_VMapEnabled;
      float _Size;
      float _Thickness;
      float4 _SunColor;
      float4 _DysonEmission;
      float3 _Global_DS_SunPosition;
      float3 _Global_DS_SunPosition_Map;
      int _Global_DS_EditorMaskL;
      int _Global_DS_GameMaskL;
      int _Global_DS_HideFarSide;
      int _Global_DS_PaintingLayerId;
      float4 _Color;
      float _AlbedoMultiplier;
      float _NormalMultiplier;
      float _EmissionMultiplier;
      float _AlphaClip;
      float4 _LayerRotations[10];
      sampler2D _MainTex;
      sampler2D _MSTex;
      sampler2D _NormalTex;
      sampler2D _EmissionTex;


      v2f vert( appdata_part v, uint instanceID : SV_InstanceID)
      {
        v2f o;

        //_Size is always 100
        // float3 vertPos = _Size * v.vertex.xyz;
        float3 vertPos = 100 * v.vertex.xyz;

        uint layer = _InstBuffer[instanceID].layer;
        uint state = _InstBuffer[instanceID].state;
        float3 pos0 = _InstBuffer[instanceID].pos0;
        float progress0 = _InstBuffer[instanceID].progress0;
        uint color = _InstBuffer[instanceID].color;

        o.lightray_layer.w = layer;
        o.u_v_radius_state.w = state;

        float4 gamma_color = ((asuint(color) >> int4(0,8,16,24)) & int4(255,255,255,255)) / 255.0;
        o.color.xyzw = pow((float4(0.055, 0.055, 0.055, 0.055) + gamma_color) / float4(1.05, 1.05, 1.05, 1.05), 2.4);

        uint renderPlace = asuint(_Global_DS_RenderPlace);
        float progress1 = renderPlace > 1.5 ? 1 : progress0;
        vertPos.xz = progress1 < 0.999 ? (progress1 * 0.5 + 0.2) * vertPos.xz : vertPos.xz;

        float3 y_axis = normalize(pos0.xyz);
        float3 x_axis = normalize(cross(y_axis, float3(0,1,0)));
        float3 z_axis = cross(x_axis, y_axis);
        int flipSign = pos0.y < 0 ? 1 : pos0.y > 0 ? -1 : 0;
        x_axis.xyz = abs(y_axis.x) > 0.001 || abs(y_axis.z) > 0.001 ? x_axis : float3(1,0,0);
        y_axis.xyz = abs(y_axis.x) > 0.001 || abs(y_axis.z) > 0.001 ? y_axis : float3(0, flipSign, 0);
        z_axis.xyz = abs(y_axis.x) > 0.001 || abs(y_axis.z) > 0.001 ? z_axis : float3(0, 0, flipSign);
        pos0.xz = abs(y_axis.x) > 0.001 || abs(y_axis.z) > 0.001 ? pos0.xz : 0;

        vertPos.xyz = vertPos.zzz * z_axis.xyz + vertPos.xxx * x_axis.xyz + vertPos.yyy * y_axis.xyz;

        float3 transformPos = vertPos + pos0.xyz;

        float3 transformNormal;
        transformNormal.xyz = v.normal.yyy * y_axis.xyz;
        transformNormal.xyz = v.normal.xxx * x_axis.xyz + transformNormal.xyz;
        transformNormal.xyz = v.normal.zzz * z_axis.xyz + transformNormal.xyz;

        float3 transformTangent;
        transformTangent.xyz = v.tangent.yyy * y_axis.xyz;
        transformTangent.xyz = v.tangent.xxx * x_axis.xyz + transformTangent.xyz;
        transformTangent.xyz = v.tangent.zzz * z_axis.xyz + transformTangent.xyz;

        float3 worldPos = rotate_vector_fast(transformPos.xyz, _LayerRotations[layer].xyzw);
        float3 worldNormal = rotate_vector_fast(transformNormal.xyz, _LayerRotations[layer].xyzw);
        float3 worldTangent = rotate_vector_fast(transformTangent.xyz, _LayerRotations[layer].xyzw);

        float frameRadius = length(worldPos.xyz);

        float falloffDistance = pow(1 + min(4, max(0, (5000 / frameRadius) - 0.2)), 2);

        if (renderPlace < 0.5) {
          float4 localRot = _LocalRot.xyzw;
          localRot.w = -localRot.w;
          worldPos = rotate_vector_fast(worldPos.xyz, localRot);
          worldNormal = rotate_vector_fast(worldNormal.xyz, localRot);
          worldTangent = rotate_vector_fast(worldTangent.xyz, localRot);
        }

        float3 universePos = renderPlace < 1.5 ? worldPos.xyz / 4000.0 + _SunPosition_Map.xyz : worldPos.xyz / 4000.0;
        universePos = renderPlace < 0.5 ? worldPos.xyz + _SunPosition.xyz : universePos.xyz;

        float3 lightPos_Normal = normalize(universePos.xyz - _SunPosition.xyz) * falloffDistance;
        float3 lightPos_DysonMap = normalize(universePos.xyz - _SunPosition_Map.xyz) * falloffDistance;

        o.lightray_layer.xyz = renderPlace < 1.5 ? lightPos_Normal.xyz : lightPos_DysonMap.xyz;

        float3 rayViewToUPos = universePos.xyz - _WorldSpaceCameraPos.xyz;
        float distViewToUpos = length(rayViewToUPos.xyz);
        rayViewToUPos.xyz = distViewToUpos > 10000 ? rayViewToUPos.xyz * (10000 * log(0.0001 * distViewToUpos) + 10000) / distViewToUpos : rayViewToUPos.xyz;
        worldPos = _Global_VMapEnabled > 0.5 ? _WorldSpaceCameraPos.xyz + rayViewToUPos.xyz : universePos;

        float4 clipPos = UnityWorldToClipPos(worldPos.xyz);

        worldNormal = normalize(worldNormal.xyz);
        worldTangent = normalize(worldTangent.xyz);
        float3 worldBinormal = cross(worldNormal.xyz, worldTangent.xyz) * v.tangent.w * unity_WorldTransformParams.w;

        o.screenPos.xyzw = ComputeScreenPos(clipPos.xyzw);
        o.shadowCoords.xyz = ShadeSH9(float4(worldNormal.xyz, 1));
        o.shadowCoords.w = 1.0;
        o.position.xyzw = clipPos.xyzw;

        o.tbnw_matrix_x.x = worldTangent.x;
        o.tbnw_matrix_x.y = worldBinormal.x;
        o.tbnw_matrix_x.z = worldNormal.x;
        o.tbnw_matrix_x.w = worldPos.x;
        o.tbnw_matrix_y.x = worldTangent.y;
        o.tbnw_matrix_y.y = worldBinormal.y;
        o.tbnw_matrix_y.z = worldNormal.y;
        o.tbnw_matrix_y.w = worldPos.y;
        o.tbnw_matrix_z.x = worldTangent.z;
        o.tbnw_matrix_z.y = worldBinormal.z;
        o.tbnw_matrix_z.z = worldNormal.z;
        o.tbnw_matrix_z.w = worldPos.z;

        o.u_v_radius_state.xy = v.texcoord.xy;
        o.u_v_radius_state.z = frameRadius;

        o.progress.xy = float2(progress0, progress1);
        return o;
      }

      fout frag(v2f i)
      {
        const float4 icb[16] = { { 1.000000, 0, 0, 0},
                                    { 9.000000, 0, 0, 0},
                                    { 3.000000, 0, 0, 0},
                                    { 11.000000, 0, 0, 0},
                                    { 13.000000, 0, 0, 0},
                                    { 5.000000, 0, 0, 0},
                                    { 15.000000, 0, 0, 0},
                                    { 7.000000, 0, 0, 0},
                                    { 4.000000, 0, 0, 0},
                                    { 12.000000, 0, 0, 0},
                                    { 2.000000, 0, 0, 0},
                                    { 10.000000, 0, 0, 0},
                                    { 16.000000, 0, 0, 0},
                                    { 8.000000, 0, 0, 0},
                                    { 14.000000, 0, 0, 0},
                                    { 6.000000, 0, 0, 0} };

        fout o;

        float layer = round(i.lightray_layer.w);
        layer = (uint)layer;

        float shift_layer = 1 << (int)layer;
        uint renderPlace = asuint(_Global_DS_RenderPlace);
        bool isInGameOrStarMap = renderPlace < 1.5;

        float gameMask = (int)shift_layer & asint(_Global_DS_GameMaskL);
        float editorMask = (int)shift_layer & asint(_Global_DS_EditorMaskL);

        float3 worldPos;
        worldPos.x = i.tbnw_matrix_x.w;
        worldPos.y = i.tbnw_matrix_y.w;
        worldPos.z = i.tbnw_matrix_z.w;

        float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - worldPos.xyz);
        float3 lightDir = normalize(_Global_DS_SunPosition_Map.xyz - worldPos.xyz);
        float VdotL = dot(viewDir, lightDir);

        bool shouldHide = asuint(_Global_DS_HideFarSide) > 0.5 && VdotL > 0;
        bool notPaintingLayer = (int)layer != asint(_Global_DS_PaintingLayerId) && asuint(_Global_DS_PaintingLayerId) > 0;
        if ((isInGameOrStarMap && (uint)gameMask <= 0) || notPaintingLayer || shouldHide || (uint)editorMask <= 0) discard;

        float3 mstex = tex2D(_MSTex, i.u_v_radius_state.xy).xwy;

        if (mstex.z < _AlphaClip - 0.001) discard;

        uint2 bitmask;
        float cutOut = 0;
        if (i.progress.x < 0.01) {
          if (renderPlace > 1.5) {
            if (i.u_v_radius_state.w < 0.5) {
              int2 screen = _ScreenParams.yx * (i.screenPos.yx / i.screenPos.ww);
              bitmask.y = ((~(-1 << 2)) << 2) & 0xffffffff;  screen.y = (((uint)screen.y << 2) & bitmask.y) | ((uint)0 & ~bitmask.y);
              bitmask.x = ((~(-1 << 2)) << 0) & 0xffffffff;  screen.x = (((uint)screen.x << 0) & bitmask.x) | ((uint)screen.y & ~bitmask.x);
              screen.x = 0.499 - icb[screen.x].x / 17.0;
              if (screen.x < 0) discard;
            }
            cutOut = 1;
          } else {
            if (-1 != 0) discard;
          }
        }
        float4 maintex = tex2D(_MainTex, i.u_v_radius_state.xy).xyzw;
        float3 normaltex = tex2Dbias(_NormalTex, float4(i.u_v_radius_state.xy, 0,  -1)).xyw;

        float3 unpackedNormal;
        normaltex.x = normaltex.x * normaltex.z;
        unpackedNormal.xy = normaltex.xy * float2(2,2) - float2(1,1);
        unpackedNormal.z = sqrt(1 - min(1, dot(unpackedNormal.xy, unpackedNormal.xy)));
        unpackedNormal.xy = _NormalMultiplier * unpackedNormal.xy;
        float3 tangentNormal = normalize(unpackedNormal);

        float3 emissiontex = tex2Dbias(_EmissionTex, float4(i.u_v_radius_state.xy, 0,  -1)).xyz;
        float3 emissionTintGreen = dot(emissiontex.xyz, float3(0.3, 0.6, 0.1));
        float fade = min(1, 0.5 / dot(i.color.xyz, float3(0.3, 0.6, 0.1)));
        float3 emission = lerp(emissiontex.xyz, emissionTintGreen * i.color.xyz, i.color.www) * fade;
        float albedoAlpha = saturate(1.25 * (maintex.w - 0.1));
        float3 albedoColor = (1 - cutOut) * lerp(float3(1,1,1), _Color.xyz, albedoAlpha) * _AlbedoMultiplier * maintex.xyz;

        float adjustColorAlpha = isInGameOrStarMap ? 0.2 : 0.6;
        float colorAlpha = i.color.w * adjustColorAlpha;
        albedoColor.xyz = lerp(lerp(albedoColor.xyz, i.color.xyz, colorAlpha), lerp(albedoColor.xyz, i.color.xyz * albedoColor.xyz, colorAlpha), isInGameOrStarMap ? 0.7 : 1);
        emission.xyz = lerp(_EmissionMultiplier * emission.xyz, i.color.w > 0.5 ? i.color.xyz : float3(0, 3, 0.75), cutOut);

        float3 defaultColor = isInGameOrStarMap ? float3(0,0,0) : float3(5,5,5) * i.color.xyz * fade;
        float3 highStateColor = i.color.w > 0.5 ? defaultColor : isInGameOrStarMap ? float3(0,0,0) : float3(3.7, 0.075, 0.125);
        float3 medStateColor = i.color.w > 0.5 ? defaultColor : isInGameOrStarMap ? float3(0,0,0) : float3(0.75, 1.25, 3.9);
        float3 lowStateColor = i.color.w > 0.5 ? defaultColor : isInGameOrStarMap ? float3(0,0,0) : float3(0.5, 1, 3.85);

        float state = i.u_v_radius_state.w;
        float3 finalColor = i.color.w > 0.5 ? defaultColor : isInGameOrStarMap ? float3(0,0,0) : float3(3.5, 2, 1);
        finalColor = state > 0.5 ? finalColor : emission;
        finalColor = state > 1.5 ? lowStateColor : finalColor;
        finalColor = state > 2.5 ? medStateColor : finalColor;
        finalColor = state > 3.5 ? highStateColor : finalColor;

        float3 rayPosToCam = _WorldSpaceCameraPos.xyz - worldPos.xyz;
        float3 worldViewDir = normalize(rayPosToCam);

        float shadowMaskAttenuation = UnitySampleBakedOcclusion(float2(0,0), worldPos);

        float3 worldNormal;
        worldNormal.x = dot(i.tbnw_matrix_x.xyz, tangentNormal);
        worldNormal.y = dot(i.tbnw_matrix_y.xyz, tangentNormal);
        worldNormal.z = dot(i.tbnw_matrix_z.xyz, tangentNormal);
        worldNormal.xyz = normalize(worldNormal.xyz);

        float lengthLightRay = length(i.lightray_layer.xyz);
        float3 worldLightDir = -i.lightray_layer.xyz / lengthLightRay;

        float3 sunColor = _SunColor.xyz * lengthLightRay;

        float metallic = saturate(mstex.x * 0.85 + 0.15);
        float perceptualRoughness = saturate(1 - mstex.y * 0.97);

        float3 halfDir = normalize(worldViewDir.xyz + worldLightDir.xyz);

        float roughness = pow(perceptualRoughness, 2);
        float roughnessSqr = pow(roughness, 2);

        float3 lightToCam = normalize(_WorldSpaceCameraPos.xyz - _Global_DS_SunPosition.xyz);

        sunColor.xyz = float3(1.25, 1.25, 1.25) * sunColor.xyz;
        float anotherFalloff = renderPlace < 0.5 ? pow(saturate(1.02 + dot(lightToCam.xyz, worldLightDir)), 0.4) : 1.0;

        float3 sunViewDir = normalize(float3(0,3,0) + _WorldSpaceCameraPos.xyz);

        float NdotV = dot(worldNormal.xyz, worldViewDir.xyz);
        float NdotL = dot(worldNormal.xyz, worldLightDir.xyz);
        float NdotH = dot(worldNormal.xyz, halfDir.xyz);
        float VdotH = dot(worldViewDir.xyz, halfDir.xyz);
        float NdotSV = dot(worldNormal.xyz, sunViewDir.xyz);
        float clamp_NdotV = max(0, NdotV);
        float clamp_NdotL = max(0, NdotL);
        float clamp_NdotH = max(0, NdotH);
        float clamp_VdotH = max(0, VdotH);
        float clamp_NdotSV = max(0, NdotSV);

        float NdotLFalloff = saturate(pow(NdotL * 0.5 + 0.6, 3));
        float lightFalloff = renderPlace > 1.5 ? NdotLFalloff + clamp_NdotSV : NdotLFalloff;

        sunColor.xyz = sunColor.xyz * shadowMaskAttenuation;

        float D = 0.25 * pow(rcp(pow(clamp_NdotH,2) * (roughnessSqr - 1) + 1),2) * roughnessSqr;

        float gv = lerp(pow(roughnessSqr + 1, 2) * 0.125, 1, clamp_NdotV);
        float gl = lerp(pow(roughnessSqr + 1, 2) * 0.125, 1, clamp_NdotL);
        float G = rcp(gv * gl);

        float fk = exp2((-6.98316002 + clamp_VdotH * -5.55472994) * clamp_VdotH);
        float F = lerp(0.5 + metallic, 1, fk);

        float3 sunLight = float3(0.2, 0.2, 0.2) * _SunColor.xyz * lerp(1, lengthLightRay, lightFalloff) * lightFalloff;
        float3 anotherLight = float3(0.5, 0.5, 0.5) * lerp(float3(1,1,1), albedoColor.xyz, metallic) * sunColor.xyz;
        float3 ggx = anotherLight.xyz * (D * F * G + (1.0 / (10 * UNITY_PI))) * clamp_NdotL;

        float3 finalLight = (sunLight.xyz * albedoColor.xyz * (1 - metallic * 0.6) + sunColor.xyz * clamp_NdotL * albedoColor.xyz * pow(1 - metallic, 0.6) + lerp(metallic, 1, 0.2 * albedoColor) * ggx.xyz) * anotherFalloff;

        float lightStrength = dot(finalLight.xyz, float3(0.3, 0.6, 0.1));

        float3 normalizedLight = finalLight.xyz / lightStrength;
        float bigLog = log(log(lightStrength) + 1) + 1;

        finalLight.xyz = 1 < lightStrength ? normalizedLight.xyz * bigLog : finalLight.xyz;

        o.sv_target.xyz = albedoColor.xyz * i.shadowCoords.xyz + finalLight.xyz + finalColor.xyz;
        o.sv_target.w = 1;
        
        return o;
      }
      ENDCG
    }
  }
}