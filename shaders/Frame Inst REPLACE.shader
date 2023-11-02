Shader "VF Shaders/Dyson Sphere/Frame Inst REPLACE" {
  Properties {
    _Color ("Color", Color) = (1,1,1,1)
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
      #include "CGIncludes/DSPCommon.cginc"
      #pragma target 5.0
      #pragma enable_d3d11_debug_symbols

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
        o.tbnw_matrix_x.w = worldPos.x;
        o.tbnw_matrix_y.x = worldTangent.y;
        o.tbnw_matrix_y.y = worldBinormal.y;
        o.tbnw_matrix_y.z = worldNormal.y;
        o.tbnw_matrix_y.w = worldPos.y;
        o.tbnw_matrix_z.x = worldTangent.z;
        o.tbnw_matrix_z.y = worldBinormal.z;
        o.tbnw_matrix_z.z = worldNormal.z;
        o.tbnw_matrix_z.w = worldPos.z;

        o.u_v_index.xy = v.texcoord.xy;
        o.u_v_index.z = instIndex;

        o.lightray_layer.xyz = lightray;
        o.lightray_layer.w = layer;

        

        return o;
      }

      fout frag(v2f i, float4 screenPos : SV_POSITION)
      {
          fout o;
      
          int layer = round(i.lightray_layer.w); //layer //r0.x
          int layerMask = 1 << layer; //r0.y
          uint renderPlace = asuint(_Global_DS_RenderPlace); //r0.z
          
          bool hideLayerInGame = layerMask & asint(_Global_DS_GameMaskL) > 0; //r1.x
          bool hideLayerInEditor = layerMask & asint(_Global_DS_EditorMaskL) > 0; //r0.y
          
          float3 worldPos;
          worldPos.x = i.tbnw_matrix_x.w;
          worldPos.y = i.tbnw_matrix_y.w;
          worldPos.z = i.tbnw_matrix_z.w;
          
          float3 viewDir = normalize(_WorldSpaceCameraPos - worldPos.xyz); //r1.yzw
          //float3 lightDir = normalize(_Global_DS_SunPosition_Map.xyz - worldPosv7.xyz); //r2.xyz //wouldnt v6.xyz serve this purpose? it's a ray from sun to obj
          float3 lightDir = normalize(-i.lightray_layer.xyz);
          
          bool isFarSide = dot(viewDir, lightDir) > 0; //r1.y
          bool hideFarSide = asuint(_Global_DS_HideFarSide) > 0.5;
          bool isPainting = asuint(_Global_DS_PaintingLayerId) > 0; //r1.z
          bool notPaintingLayer = layer != asint(_Global_DS_PaintingLayerId);
          bool showInEditor = (!(notPaintingLayer && isPainting) || !(hideFarSide && isFarSide)) && !hideLayerInEditor; //r0.x
          bool isShowing = renderPlace < 1.5 ? !hideLayerInGame : showInEditor; // not Dyson screen
          if (!isShowing) discard;
          
          float3 msTex = tex2D(_MSTex, i.u_v_index.xy).xwy; //r1.xyz
          //if (msTex.z < _AlphaClip - 0.001) discard;
          if (msTex.z < -0.001) discard;
          
          uint instIndex = (uint)(i.u_v_index.z + 0.5);
          
          uint state = _InstBuffer[instIndex].state;
          float progress0 = _InstBuffer[instIndex].progress0;
          float progress1 = _InstBuffer[instIndex].progress1;
          float progress = progress0 + progress1; //r0.x
        
          float isPlanned = 0; //r0.x
          if (progress < 0.01) {
              if (renderPlace > 1.5) {
                if (state < 0.5) { //state //when not not highlighted during edit
                  uint2 pixelPos = screenPos.xy;
                  int mask = (pixelPos.x & 1) - (pixelPos.y & 1);
                  if (mask != 0) discard;
                }
                isPlanned = 1;
              } else {
                discard;
              }
          }
          
          uint color = _InstBuffer[instIndex].color;
          
          float4 gamma_color = ((asuint(color) >> int4(0,8,16,24)) & int4(255,255,255,255)) / 255.0;
          float4 painted_color = float4(GammaToLinearSpace(gamma_color.xyz), gamma_color.w);
          
          float paintedColorLuminance = dot(painted_color.xyz, float3(0.3, 0.6, 0.1)); //r4.x
          float paintedColorLumAdjust = min(1.0, 0.1 / paintedColorLuminance); // r4.x
          
          float3 emissionTex = tex2Dbias(_EmissionTex, float4(i.u_v_index.xy, 0,  -1)).xyz; //r4.xyz
          float emissionLuminance = dot(emissionTex.xyz, float3(0.3, 0.6, 0.1)); //r3.w
          
          // _DysonEmission = based on, but not the same as, color of star
          // color of emission?
          float3 emissionColor = lerp(_DysonEmission.xyz * emissionLuminance, painted_color.xyz * emissionLuminance, painted_color.w); //r4.yzw
          
          float4 mainTex = tex2D(_MainTex, i.u_v_index.xy).xyzw;//r2.xyzw
          
          //float3 albedo = _AlbedoMultiplier * mainTex.xyz; //_AlbedoMultiplier //r2.xyz //always 1?
          float3 albedo = mainTex.xyz;
          //float3 tint = lerp(float3(1,1,1), _Color.xyz, saturate(1.25 * (mainTex.w - 0.1))); //r5.xyz //always white?
          //albedo.xyz = tint * albedo.xyz; // * normal //r2.xyz
          
          float albedoLuminance = dot(albedo.xyz, float3(0.3, 0.6, 0.1)); //r1.z
          albedoLuminance = albedoLuminance * (1.0 - isPlanned); //r1.z
          
          float colorStrength = renderPlace < 1.5 ? 0.7 : 0.6; // not Dyson screen //r2.x
          float paintedColorStrength = renderPlace < 1.5 ? 0.2 : 0.3; // not Dyson screen //r2.y
          float3 standardStrength = lerp(albedoLuminance, painted_color.xyz, painted_color.w * paintedColorStrength); //r2.yzw
          float3 boostedStrength = lerp(albedoLuminance, painted_color.xyz * albedoLuminance, painted_color.w * paintedColorStrength); //r5.xyz
          albedo = lerp(standardStrength, boostedStrength, colorStrength); //r2.xyz
          
          //emissionColor = _EmissionMultiplier * emissionColor; //emissionmultiplier always 2? //r4.yzw
          
          bool usePaintedColor = painted_color.w > 0.5; // custom color exists? is it always 0 or 1? //r1.z
          float3 dysonEditorDefaultColor = usePaintedColor ? painted_color.xyz : float3(0, 3, 0.75); //r6.xyz
          
          float emissionBoost = renderPlace > 0.5 ? 4.5 : 3; //r0.y
          emissionColor = lerp(emissionColor * emissionBoost, dysonEditorDefaultColor, isPlanned); //r4.yzw
          
          float3 dysonEditorPaintedTint = renderPlace < 1.5 ? float3(0,0,0) : float3(5,5,5) * painted_color.xyz * paintedColorLumAdjust; //r5.xyz
          
          float3 dysonEditorHoverDeleteColor = renderPlace < 1.5 ? float3(0,0,0) : float3(3.7, 0.075, 0.125); //r6.xyz
          dysonEditorHoverDeleteColor = usePaintedColor ? dysonEditorPaintedTint : dysonEditorHoverDeleteColor;
          float3 dysonEditorHoverWhileSelectedColor = renderPlace < 1.5 ? float3(0,0,0) : float3(0.75, 1.25, 3.9); //r7.xyz
          dysonEditorHoverWhileSelectedColor = usePaintedColor ? dysonEditorPaintedTint : dysonEditorHoverWhileSelectedColor;
          float3 dysonEditorSelectedColor = renderPlace < 1.5 ? float3(0,0,0) : float3(0.5, 1.0, 3.85); //r8.xyz
          dysonEditorSelectedColor = usePaintedColor ? dysonEditorPaintedTint : dysonEditorSelectedColor;
          float3 dysonEditorHoverColor = renderPlace < 1.5 ? float3(0,0,0) : float3(3.5, 2.0, 1.0); //r0.xyw
          dysonEditorHoverColor = usePaintedColor ? dysonEditorPaintedTint : dysonEditorHoverColor;
          
          emissionColor = state > 0.5 ? dysonEditorHoverColor : emissionColor; //state == 1 (hover select)
          emissionColor = state > 1.5 ? dysonEditorSelectedColor : emissionColor; //state == 2 (selected)
          emissionColor = state > 2.5 ? dysonEditorHoverWhileSelectedColor : emissionColor; //state == 3 (hover select while selected)
          emissionColor = state > 3.5 ? dysonEditorHoverDeleteColor : emissionColor; //state == 4 (hover delete) //r0.xyw
          
          //float3 unpackedNormal = UnpackNormalWithScale(tex2Dbias(_NormalTex, float4(i.u_v_index.xy, 0, -1)), _NormalMultiplier); //r3.xyz //_NormalMultiplier is always 1?
          float3 unpackedNormal = UnpackNormal(tex2Dbias(_NormalTex, float4(i.u_v_index.xy, 0, -1)));
          float3 tangentNormal = normalize(unpackedNormal); //r3.xyz
          
          float3 worldNormal; //r5.xyz
          worldNormal.x = dot(i.tbnw_matrix_x.xyz, tangentNormal);
          worldNormal.y = dot(i.tbnw_matrix_y.xyz, tangentNormal);
          worldNormal.z = dot(i.tbnw_matrix_z.xyz, tangentNormal);
          worldNormal.xyz = normalize(worldNormal.xyz); //r3.xyz
          
          float metallic = saturate(msTex.x * 0.85 + 0.149); //r1.x
          float perceptualRoughness = saturate(1 - msTex.y * 0.97); //r1.y
          
          float3 halfDir = normalize(viewDir + lightDir); //r6.xyz
          
          //roughness
          float roughness = perceptualRoughness * perceptualRoughness; //r1.y
          float roughnessSqr = roughness * roughness; //r1.z
          
          float nDotV = dot(worldNormal.xyz, viewDir.xyz); //r3.w
          
          float3 viewFromSunDir = normalize(_WorldSpaceCameraPos.xyz - _Global_DS_SunPosition.xyz); //r8.xyz
            
          float sideInView = dot(viewFromSunDir.xyz, -lightDir); //r5.w // 1 if top of frame is facing player, 0 if viewing side on, -1 if bottom of frame is facing player (directly behind sun)
          float innerFalloff = pow(saturate(1.02 + sideInView), 0.4); //r5.w // 1 until view side on, then falloff as we view the bottom of frame until it moves behind the star. minimum .2
          innerFalloff = renderPlace < 0.5 ? innerFalloff : 1; //r4.w
          
          float nDotL = dot(worldNormal.xyz, lightDir.xyz); //r4.x
          float nDotH = dot(worldNormal.xyz, halfDir.xyz); //r4.z
          float clamped_nDotL = max(0, nDotL); //r4.y
          nDotH = max(0, nDotH); //r4.z
          float vDotH = dot(viewDir.xyz, halfDir.xyz); //r5.w
          vDotH = max(0, vDotH); //r5.w
          
          float ambientLightFalloff = saturate(pow(nDotL * 0.5 + 0.6, 3.0)); //expo: -1=0, 0=0.2, 0.8=1 //r4.x
          float3 editorViewDir = normalize(float3(0,3,0) + _WorldSpaceCameraPos.xyz); //r6.xyz //direction to camera but slightly higher
          float editorNDotV = dot(worldNormal.xyz, editorViewDir); //r3.x
          editorNDotV = max(0, editorNDotV); //r3.x
          nDotV = max(0, nDotV); //r3.w
          ambientLightFalloff = renderPlace > 1.5 ? ambientLightFalloff + editorNDotV : ambientLightFalloff; //r0.z
          
          float scaledMetallic = 0.5 + metallic;
          float specularTerm = GGX(roughness, scaledMetallic, nDotH, nDotV, clamped_nDotL, vDotH);
          
          float starLightStrength = length(i.lightray_layer.xyz); //r2.w //upDir scaled by 25 if nearby, approaching 1 if very far. (mostly relative to star when it matters, but could technically be distance from planet)
          //float3 lightDir = -i.lightray_layer.xyz / starLightStrength; //r4.xyz
          float3 sunColor = _SunColor.xyz * starLightStrength; //r5.xyz
          
          float3 ambientLightStrength = lerp(1.0, starLightStrength, ambientLightFalloff); // r1.w
          float3 ambientLight = float3(0.2, 0.2, 0.2) * _SunColor.xyz * ambientLightStrength * ambientLightFalloff; //r3.xyz
          
          sunColor.xyz = float3(1.25, 1.25, 1.25) * sunColor.xyz; //r5.xyz
          
          float3 highlightColor = sunColor * clamped_nDotL * albedo.xyz; //either normal luminance or painted color //r6.xyz
          
          float3 specularColor = float3(0.3, 0.3, 0.3) * lerp(float3(1,1,1), albedo.xyz, metallic); //r7.xyz
          specularColor = specularColor.xyz * sunColor; //r5.xyz
          float INV_TEN_PI = 0.0318309888;
          specularColor.xyz = specularColor.xyz * clamped_nDotL * (specularTerm + INV_TEN_PI); //ndotl //r4.xyz
          
          float3 specColorMod = 0.2 * albedo.xyz * (1.0 - metallic) + metallic; //either normal luminance or painted color //r5.xyz
          specularColor = specularColor * specColorMod.xyz; //r4.xyz
          
          float3 ambientColor = ambientLight.xyz * albedo.xyz; //either normal luminance or painted color //r3.xyz
          
          float3 finalColor = ambientColor.xyz * (1.0 - metallic * 0.6)
              + highlightColor.xyz * pow(1.0 - metallic, 0.6)
              + specularColor.xyz;
          finalColor = finalColor.xyz * innerFalloff; //r1.xyz
          
          float finalColorLuminance = dot(finalColor.xyz, float3(0.3, 0.6, 0.1)); //r0.z
          finalColor.xyz = finalColorLuminance > 1 ? (finalColor.xyz / finalColorLuminance) * (log(log(finalColorLuminance) + 1) + 1) : finalColor.xyz;
          
          finalColor.xyz = finalColor.xyz + emissionColor;
          
          o.sv_target.xyz = finalColor;
          o.sv_target.w = 1;
          return o;
      }
      ENDCG
    }
  }
}
