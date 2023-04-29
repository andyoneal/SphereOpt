Shader "VF Shaders/Dyson Sphere/Frame Inst REPLACE" {
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
    Tags { "RenderType" = "DysonFrame" }
    Pass {
      LOD 200
      Tags { "RenderType" = "DysonFrame" }
      GpuProgramID 24323
      CGPROGRAM
      #pragma vertex vert
      #pragma fragment frag
      #include "UnityCG.cginc"
      #pragma target 5.0
      //#pragma enable_d3d11_debug_symbols

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
          float3 vertex : POSITION;
          float4 tangent : TANGENT;
          float3 normal : NORMAL;
          float2 texcoord : TEXCOORD0;
      };

      struct v2f
      {
        float4 position : SV_POSITION;
        float4 tbnw_matrix_x : TEXCOORD0;
        float4 tbnw_matrix_y : TEXCOORD1;
        float4 tbnw_matrix_z : TEXCOORD2;
        float3 u_v_index : TEXCOORD3;
        float4 lightray_layer : TEXCOORD4;
      };

      struct fout
      {
        float4 sv_target : SV_Target0;
      };

      StructuredBuffer<Segment> _InstBuffer;
      StructuredBuffer<uint> _InstIndexBuffer;

      float4 _SunColor;
      float4 _DysonEmission;
      float4 _Color;
      float _AlbedoMultiplier;
      float _NormalMultiplier;
      float _EmissionMultiplier;
      float _AlphaClip;
      int _Global_DS_EditorMaskL;
      int _Global_DS_GameMaskL;
      int _Global_DS_HideFarSide;
      int _Global_DS_PaintingLayerId;
      float3 _Global_DS_SunPosition;
      int _Global_DS_RenderPlace;
      float3 _Global_DS_SunPosition_Map;
      float4 _LayerRotations[11 * 3];
      sampler2D _MainTex;
      sampler2D _MSTex;
      sampler2D _NormalTex;
      sampler2D _EmissionTex;


      v2f vert( appdata_part v, uint instanceID : SV_InstanceID)
      {
        v2f o;

        uint instIndex = _InstIndexBuffer[instanceID];

        uint layer = _InstBuffer[instIndex].layer;
        unity_ObjectToWorld._m00_m01_m02_m03 = _LayerRotations[layer * 3];
        unity_ObjectToWorld._m10_m11_m12_m13 = _LayerRotations[layer * 3 + 1];
        unity_ObjectToWorld._m20_m21_m22_m23 = _LayerRotations[layer * 3 + 2];
        unity_ObjectToWorld._m30_m31_m32_m33 = float4(0,0,0,1);
        
        float3 pos0 = _InstBuffer[instIndex].pos0;
        float3 pos1 = _InstBuffer[instIndex].pos1;
        float3 pos0topos1 = pos1.xyz - pos0.xyz;
        float3 stretchedPos = lerp(pos0.xyz, pos1.xyz, v.vertex.z * 0.98 + 0.01);

        int compare_instanceID = v.vertex.z < 0.5 ? (int)instIndex - 1 : (int) instIndex + 1;

        float3 compare_pos0 = _InstBuffer[compare_instanceID].pos0;
        float3 compare_pos1 = _InstBuffer[compare_instanceID].pos1;

        float3 rayToNeighborFrame = v.vertex.z < 0.5 ? compare_pos1.xyz - pos0.xyz : pos1.xyz - compare_pos0.xyz;
        float3 rayEndToEnd = v.vertex.z < 0.5 ? pos0.xyz - compare_pos0.xyz : compare_pos1.xyz - pos1.xyz;
        float3 rayTwoFrames = v.vertex.z < 0.5 ? pos1.xyz - compare_pos0.xyz : compare_pos1.xyz - pos0.xyz;

        float3 z_axis = length(rayToNeighborFrame) < 0.01 && dot(normalize(pos0topos1), normalize(rayEndToEnd)) > 0.9 ? rayTwoFrames : pos0topos1.xyz;

        z_axis.xyz = normalize(z_axis.xyz);
        float3 y_axis = normalize(stretchedPos.xyz);
        float3 x_axis = normalize(cross(y_axis.xyz, z_axis.xyz));
        z_axis.xyz = cross(x_axis.xyz, y_axis.xyz);

        float3x3 rotateMatrix = transpose(float3x3(x_axis, y_axis, z_axis));

        float3 vertPos = 100 * v.vertex.y * y_axis.xyz + 100 * v.vertex.x * x_axis.xyz + stretchedPos.xyz;
        float3 objNormal = mul(rotateMatrix, v.normal.xyz);
        float3 objTangent = mul(rotateMatrix, v.tangent.xyz);

        float3 worldPos = mul(unity_ObjectToWorld, float4(vertPos.xyz, 1));
        float3 worldNormal = normalize(mul((float3x3)unity_ObjectToWorld, objNormal.xyz));
        float3 worldTangent = normalize(mul((float3x3)unity_ObjectToWorld, objTangent.xyz));
        float3 worldBinormal = cross(worldNormal.xyz, worldTangent.xyz) * unity_WorldTransformParams.w * v.tangent.w;

        float invFrameRadius = rsqrt(dot(vertPos.xyz, vertPos.xyz));
        float falloffDistance = pow(1 + min(4, max(0, (5000 * invFrameRadius) - 0.2)), 2);

        uint renderPlace = asuint(_Global_DS_RenderPlace);

        float3 lightray = renderPlace < 0.5 ? normalize(worldPos.xyz - _Global_DS_SunPosition.xyz) * falloffDistance : normalize(worldPos.xyz - _Global_DS_SunPosition_Map.xyz) * falloffDistance;

        float3 rayViewToPos = worldPos.xyz - _WorldSpaceCameraPos.xyz;
        float distViewToPos = length(rayViewToPos.xyz);
        float scaled_distViewToPos = 10000 * (log(0.0001 * distViewToPos) + 1) / distViewToPos;
        rayViewToPos.xyz = distViewToPos > 10000 ? rayViewToPos.xyz * scaled_distViewToPos : rayViewToPos.xyz;
        worldPos = _WorldSpaceCameraPos.xyz + rayViewToPos.xyz;

        float4 clipPos = UnityWorldToClipPos(worldPos.xyz);

        o.position.xyzw = clipPos.xyzw;

        o.tbnw_matrix_x.x = worldTangent.x;
        o.tbnw_matrix_x.y = worldBinormal.x;
        o.tbnw_matrix_x.z = worldNormal.x;
        o.tbnw_matrix_x.w = uPos.x;
        o.tbnw_matrix_y.x = worldTangent.y;
        o.tbnw_matrix_y.y = worldBinormal.y;
        o.tbnw_matrix_y.z = worldNormal.y;
        o.tbnw_matrix_y.w = uPos.y;
        o.tbnw_matrix_z.x = worldTangent.z;
        o.tbnw_matrix_z.y = worldBinormal.z;
        o.tbnw_matrix_z.z = worldNormal.z;
        o.tbnw_matrix_z.w = uPos.z;

        o.u_v_index.xy = v.texcoord.xy;
        o.u_v_index.z = instIndex;

        o.lightray_layer.xyz = lightray;
        o.lightray_layer.w = layer;

        

        return o;
      }

      fout frag(v2f i, float4 screenPos : SV_POSITION)
      {
        fout o;

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

        float layer = round(i.lightray_layer.w);
        layer = (uint)layer;

        float shift_layer = 1 << (int)layer;

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
        uint renderPlace = asuint(_Global_DS_RenderPlace);
        if ((renderPlace < 1.5 && (uint)gameMask <= 0) || notPaintingLayer || shouldHide || (uint)editorMask <= 0) discard;

        float3 mstex = tex2D(_MSTex, i.u_v_index.xy).xwy;
        
        if (mstex.z < _AlphaClip - 0.001) discard;

        uint instIndex = (uint)(i.u_v_index.z + 0.5);
        uint state = _InstBuffer[instIndex].state;
        float progress0 = _InstBuffer[instIndex].progress0;
        float progress1 = _InstBuffer[instIndex].progress1;

        uint2 bitmask;
        float progress = progress0 + progress1;
        float cutOut = 0;
        if (progress < 0.01) {
          UNITY_BRANCH
          if (renderPlace < 1.5) {
            discard;
          }
          else {
            if (state < 0.5) {
              int2 screen = (_ScreenParams.yx * screenPos.yx);
              bitmask.y = ((~(-1 << 2)) << 2) & 0xffffffff;  screen.y = (((uint)screen.y << 2) & bitmask.y) | ((uint)0 & ~bitmask.y);
              bitmask.x = ((~(-1 << 2)) << 0) & 0xffffffff;  screen.x = (((uint)screen.x << 0) & bitmask.x) | ((uint)screen.y & ~bitmask.x);
              screen.x = 0.499 - icb[bitmask.x].x * 0.0588235296;
              if (screen.x < 0) discard;
            }
            cutOut = 1;
          }
        }

        float4 maintex = tex2D(_MainTex, i.u_v_index.xy).xyzw;
        float3 normaltex = tex2Dbias(_NormalTex, float4(i.u_v_index.xy, 0,  -1)).xyw;

        float3 unpackedNormal;
        normaltex.x = normaltex.x * normaltex.z;
        unpackedNormal.xy = normaltex.xy * float2(2,2) - float2(1,1);
        unpackedNormal.z = sqrt(1 - min(1, dot(unpackedNormal.xy, unpackedNormal.xy)));
        unpackedNormal.xy = _NormalMultiplier * unpackedNormal.xy;
        
        float3 emissiontex = tex2Dbias(_EmissionTex, float4(i.u_v_index.xy, 0,  -1)).xyz;
        float3 emissionLuminance = dot(emissiontex.xyz, float3(0.3, 0.6, 0.1));

        uint color = _InstBuffer[instIndex].color;

        float4 gamma_color = ((asuint(color) >> int4(0,8,16,24)) & int4(255,255,255,255)) / 255.0;
        float4 linear_color = float4(GammaToLinearSpace(gamma_color.xyz), gamma_color.w);

        float3 emission = _EmissionMultiplier * lerp(_DysonEmission.xyz * emissionLuminance, linear_color.xyz * emissionLuminance, linear_color.www);
        
        float3 albedoColor = lerp(float3(1,1,1), _Color.xyz, saturate(1.25 * (maintex.w - 0.1))) * _AlbedoMultiplier * maintex.xyz;
        

        float3 tangentNormal = normalize(unpackedNormal);

        float emissionMod = renderPlace > 0.5 ? 4.5 : 3.0;
        
        float3 defaultColor = float3(0,0,0);
        float3 highStateColor = float3(0,0,0);
        float3 medStateColor = float3(0,0,0);
        float3 lowStateColor = float3(0,0,0);
        float3 finalColor;

        UNITY_BRANCH
        if (renderPlace < 1.5)
        {
          float albedoLuminance = dot(albedoColor.xyz, float3(0.3, 0.6, 0.1));
          float3 colorLerp1 = lerp(albedoLuminance, linear_color.xyz, linear_color.w * 0.2);
          float3 colorLerp2 = albedoLuminance * lerp(float3(1,1,1), linear_color.xyz, linear_color.w * 0.2);
          albedoColor.xyz = lerp(colorLerp1, colorLerp2, 0.7);
          finalColor = emission * emissionMod;
        }
        else
        {
          float albedoLuminance = dot(albedoColor.xyz, float3(0.3, 0.6, 0.1)) * (1.0 - cutOut);
          float3 colorLerp1 = lerp(albedoLuminance, linear_color.xyz, linear_color.w * 0.3);
          float3 colorLerp2 = albedoLuminance * lerp(float3(1,1,1), linear_color.xyz, linear_color.w * 0.3);
          albedoColor.xyz = lerp(colorLerp1, colorLerp2, 0.6);
          emission = lerp(emission * emissionMod, linear_color.w > 0.5 ? linear_color.xyz : float3(0, 3, 0.75), cutOut);
          defaultColor = float3(5,5,5) * linear_color.xyz * min(1, 0.1 / dot(linear_color.xyz, float3(0.3, 0.6, 0.1)));
          highStateColor = linear_color.w > 0.5 ? defaultColor : float3(3.7, 0.075, 0.125);
          medStateColor = linear_color.w > 0.5 ? defaultColor : float3(0.75, 1.25, 3.9);
          lowStateColor = linear_color.w > 0.5 ? defaultColor : float3(0.5, 1.0, 3.85);
          finalColor = linear_color.w > 0.5 ? defaultColor : float3(3.5, 2.0, 1.0);

          finalColor = state > 0.5 ? finalColor : emission;
          finalColor = state > 1.5 ? lowStateColor : finalColor;
          finalColor = state > 2.5 ? medStateColor : finalColor;
          finalColor = state > 3.5 ? highStateColor : finalColor;
        }
        

        float3 rayPosToCam = _WorldSpaceCameraPos.xyz - worldPos.xyz;
        float3 worldViewDir = normalize(rayPosToCam);

        //float shadowMaskAttenuation = UnitySampleBakedOcclusion(float2(0,0), worldPos);

        float3 worldNormal;
        worldNormal.x = dot(i.tbnw_matrix_x.xyz, tangentNormal);
        worldNormal.y = dot(i.tbnw_matrix_y.xyz, tangentNormal);
        worldNormal.z = dot(i.tbnw_matrix_z.xyz, tangentNormal);
        worldNormal.xyz = normalize(worldNormal.xyz);

        float lengthLightRay = length(i.lightray_layer.xyz);
        
        float metallic = saturate(mstex.x * 0.85 + 0.149);
        float perceptualRoughness = saturate(1 - mstex.y * 0.97);

        float roughness = pow(perceptualRoughness, 2);
        float roughnessSqr = pow(roughness, 2);
        
        float3 sunViewDir = normalize(float3(0,3,0) + _WorldSpaceCameraPos.xyz);

        float3 worldLightDir = -normalize(i.lightray_layer.xyz);
        float3 halfDir = normalize(worldViewDir + worldLightDir);

        float NdotV = dot(worldNormal.xyz, worldViewDir.xyz);
        float NdotSV = dot(worldNormal.xyz, sunViewDir.xyz);
        float NdotL = dot(worldNormal.xyz, worldLightDir.xyz);
        float NdotH = dot(worldNormal.xyz, halfDir.xyz);
        float VdotH = dot(worldViewDir.xyz, halfDir.xyz);
        float clamp_NdotL = max(0, NdotL);
        float clamp_NdotH = max(0, NdotH);
        float clamp_VdotH = max(0, VdotH);
        float clamp_NdotSV = max(0, NdotSV);
        float clamp_NdotV = max(0, NdotV);
        
        float D = 0.25 * pow(rcp(pow(clamp_NdotH,2) * (roughnessSqr - 1) + 1),2) * roughnessSqr;

        float gv = lerp(pow(roughnessSqr + 1, 2) * 0.125, 1, clamp_NdotV);
        float gl = lerp(pow(roughnessSqr + 1, 2) * 0.125, 1, clamp_NdotL);
        float G = rcp(gv * gl);
        
        float fk = exp2((-6.98316002 + clamp_VdotH * -5.55472994) * clamp_VdotH);
        float F = lerp(0.5 + metallic, 1, fk);

        float sunStrength = renderPlace < 0.5 ? pow(saturate(1.02 + dot(normalize(_WorldSpaceCameraPos.xyz - _Global_DS_SunPosition.xyz), -worldLightDir.xyz)), 0.4) : 1;
        float3 sunColor = float3(1.25,1.25,1.25) * _SunColor.xyz * lengthLightRay;
        float intensity = renderPlace > 1.5 ? saturate(pow(NdotL * 0.5 + 0.6, 3)) + clamp_NdotSV : saturate(pow(NdotL * 0.5 + 0.6, 3));
        float3 sunLight = float3(0.2, 0.2, 0.2) * _SunColor.xyz * lerp(1, lengthLightRay, intensity) * intensity;
        float3 anotherLight = float3(0.3, 0.3, 0.3) * lerp(float3(1,1,1), albedoColor.xyz, metallic) * sunColor.xyz;
        float3 ggx = anotherLight.xyz * (F * D * G + (1.0 / (10 * UNITY_PI))) * clamp_NdotL;

        float3 finalLight = (sunLight.xyz * albedoColor.xyz * (1 - metallic * 0.6) + sunColor.xyz * clamp_NdotL * albedoColor.xyz * pow(1 - metallic, 0.6) + lerp(metallic, 1, albedoColor.xyz * 0.2) * ggx.xyz) * sunStrength;

        float luminance = dot(finalLight.xyz, float3(0.3, 0.6, 0.1));

        float3 lightNormalized = finalLight.xyz / luminance;
        float bigLog = log(log(luminance) + 1) + 1;

        finalLight.xyz = luminance > 1 ? lightNormalized.xyz * bigLog : finalLight.xyz;

        o.sv_target.xyz = finalLight.xyz + finalColor.xyz;
        o.sv_target.w = 1;
        return o;
      }
      ENDCG
    }
  }
}
