Shader "VF Shaders/Dyson Sphere/Node Inst REPLACE" {
  Properties {
    _MainTex ("Albedo (RGB)", 2D) = "white" {}
    _NormalTex ("Normal Map", 2D) = "bump" {}
    _MSTex ("Metallic Smoothness (RA)", 2D) = "white" {}
    _EmissionTex ("Emission (RGB)", 2D) = "black" {}
  }
  SubShader {
    LOD 200
    Tags { "RenderType" = "DysonNode" }
    Pass {
      LOD 200
      Tags {"RenderType" = "DysonNode"}
      GpuProgramID 7626
      CGPROGRAM
      #pragma vertex vert
      #pragma fragment frag
      #include "UnityCG.cginc"
      #include "CGIncludes/DSPCommon.cginc"
      #pragma target 5.0
      #pragma enable_d3d11_debug_symbols

      struct NodeSegment {
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
        float4 u_v_radius_state : TEXCOORD4;
        float4 lightray_layer : TEXCOORD5;
        float2 progress : TEXCOORD6;
        float4 color : TEXCOORD7;
      };

      struct fout
      {
        float4 sv_target : SV_Target0;
      };

      StructuredBuffer<NodeSegment> _InstBuffer;
      StructuredBuffer<uint> _InstIndexBuffer;

      float4 _SunColor;
      float4 _DysonEmission;
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
      
      float4x4 BuildTransformFromPosition(float3 pos) {
          float3 up = normalize(pos);
        
          float3 tentativeForward = abs(up.z) < 0.999 ? float3(0, 0, 1) : float3(1, 0, 0);
          float3 right = cross(up, tentativeForward);
          right = normalize(right);
        
          float3 forward = cross(right, up);
          forward = normalize(forward);

          float4x4 transformMatrix;
          transformMatrix[0] = float4(right, 0);
          transformMatrix[1] = float4(up, 0);
          transformMatrix[2] = float4(forward, 0);
          transformMatrix[3] = float4(pos, 1);

          return transpose(transformMatrix);
      }

      v2f vert( appdata_part v, uint instanceID : SV_InstanceID)
      {
        v2f o;

        uint instIndex = _InstIndexBuffer[instanceID];
        
        uint layer = _InstBuffer[instIndex].layer;
        uint state = _InstBuffer[instIndex].state;
        float3 pos0 = _InstBuffer[instIndex].pos0;
        float progress0 = _InstBuffer[instIndex].progress0;
        uint color = _InstBuffer[instIndex].color;
        
        unity_ObjectToWorld._m00_m01_m02_m03 = _LayerRotations[layer * 3];
        unity_ObjectToWorld._m10_m11_m12_m13 = _LayerRotations[layer * 3 + 1];
        unity_ObjectToWorld._m20_m21_m22_m23 = _LayerRotations[layer * 3 + 2];
        unity_ObjectToWorld._m30_m31_m32_m33 = float4(0,0,0,1);
        
        uint renderPlace = asuint(_Global_DS_RenderPlace);
        float progress1 = renderPlace > 1.5 ? 1 : progress0;
        float3 vertPos = 100 * v.vertex.xyz;
        vertPos.xz = progress1 < 0.999 ? (progress1 * 0.5 + 0.2) * vertPos.xz : vertPos.xz;
        
        float4x4 transformMatrix = BuildTransformFromPosition(pos0.xyz);
        transformMatrix = mul(unity_ObjectToWorld, transformMatrix);
        
        float3 worldPos = mul(transformMatrix, float4(vertPos, 1));
        float3 worldNormal = mul((float3x3)transformMatrix, v.normal.xyz);
        worldNormal = normalize(worldNormal.xyz);
        float3 worldTangent = mul((float3x3)transformMatrix, v.tangent.xyz);
        worldTangent = normalize(worldTangent.xyz);
        float3 worldBinormal = calculateBinormal(float4(worldTangent, v.tangent.w), worldNormal);
        
        float invFrameRadius = rsqrt(dot(pos0.xyz, pos0.xyz));
        float falloffDistance = pow(1 + min(4, max(0, (5000 * invFrameRadius) - 0.2)), 2);
        float3 lightRay_Normal = normalize(worldPos.xyz - _Global_DS_SunPosition.xyz) * falloffDistance;
        float3 lightRay_DysonMap = normalize(worldPos.xyz - _Global_DS_SunPosition_Map.xyz) * falloffDistance;
        float3 lightray = renderPlace < 1.5 ? lightRay_Normal.xyz : lightRay_DysonMap.xyz;

        float3 rayCamToPos = worldPos.xyz - _WorldSpaceCameraPos.xyz;
        float distFromCam = length(rayCamToPos.xyz);
        rayCamToPos = distFromCam > 10000 ? rayCamToPos * (10000 * log(0.0001 * distFromCam) + 10000) / distFromCam : rayCamToPos;
        worldPos = _WorldSpaceCameraPos.xyz + rayCamToPos;

        float4 clipPos = UnityWorldToClipPos(worldPos.xyz);
        
        float4 gamma_color = ((asuint(color) >> int4(0,8,16,24)) & int4(255,255,255,255)) / 255.0;
        float4 linear_color = pow((float4(0.055, 0.055, 0.055, 0.055) + gamma_color) / float4(1.05, 1.05, 1.05, 1.05), 2.4);
        
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
        o.u_v_radius_state.z = 1;
        o.u_v_radius_state.w = state;

        o.lightray_layer.xyz = lightray;
        o.lightray_layer.w = layer;

        o.progress.xy = float2(progress0, progress1);
        
        o.color.xyzw = linear_color;
        
        return o;
      }

      fout frag(v2f i, float4 screenPos : SV_POSITION)
      {
        fout o;

        int layer = round(i.lightray_layer.w);
        int layerMask = 1 << layer;
        
        bool showLayerInGame = (layerMask & asint(_Global_DS_GameMaskL)) > 0;
        bool showLayerInEditor = (layerMask & asint(_Global_DS_EditorMaskL)) > 0;

        float3 worldPos;
        worldPos.x = i.tbnw_matrix_x.w;
        worldPos.y = i.tbnw_matrix_y.w;
        worldPos.z = i.tbnw_matrix_z.w;

        float3 viewDir = normalize(_WorldSpaceCameraPos - worldPos);
        float3 lightDir = normalize(-i.lightray_layer.xyz);

        bool isFarSide = dot(viewDir, lightDir) > 0;
        bool hideFarSide = asuint(_Global_DS_HideFarSide) > 0.5;
        hideFarSide = hideFarSide && isFarSide;
        bool isPainting = asuint(_Global_DS_PaintingLayerId) > 0;
        bool notPaintingLayer = layer != asint(_Global_DS_PaintingLayerId);
        bool hideNotPaintingLayer = notPaintingLayer && isPainting;
        
        bool showInEditor = !(hideNotPaintingLayer || hideFarSide) && showLayerInEditor;
        
        uint renderPlace = asuint(_Global_DS_RenderPlace);
        bool isShowing = renderPlace < 1.5 ? showLayerInGame : showInEditor;
        if (!isShowing) discard;

        float isPlanned = 0;
        if (i.progress.x < 0.01) {
            if (renderPlace > 1.5) {
              if (i.u_v_radius_state.w < 0.5) {
                uint2 pixelPos = screenPos.xy;
                int mask = (pixelPos.x & 1) - (pixelPos.y & 1);
                if (mask != 0) discard;
              }
              isPlanned = 1;
            } else {
              discard;
            }
        }
        float4 painted_color = i.color;
        
        float3 emissiontex = tex2Dbias(_EmissionTex, float4(i.u_v_radius_state.xy, 0,  -1)).xyz;
        float3 emissionLuminance = dot(emissiontex.xyz, float3(0.3, 0.6, 0.1));
        float paintedColorLuminance = dot(painted_color.xyz, float3(0.3, 0.6, 0.1));
        float paintedColorLumAdjust = min(1, 0.5 / paintedColorLuminance);
        float3 emissionColor = lerp(emissiontex.xyz, emissionLuminance * painted_color.xyz, painted_color.www) * paintedColorLumAdjust;

        float3 albedo = tex2D(_MainTex, i.u_v_radius_state.xy).xyz;

        UNITY_BRANCH
        if (renderPlace < 1.5) {
          float3 standardStrength = lerp(albedo, painted_color.xyz, painted_color.w * 0.2);
          float3 boostedStrength = lerp(albedo, painted_color.xyz * albedo, painted_color.w * 0.2);
          albedo = lerp(standardStrength, boostedStrength, 0.7);
        } else {
          albedo = albedo * (1.0 - isPlanned);
          float3 standardStrength = lerp(albedo, painted_color.xyz, painted_color.w * 0.3);
          float3 boostedStrength = lerp(albedo, painted_color.xyz * albedo, painted_color.w * 0.3);
          albedo = lerp(standardStrength, boostedStrength, 0.6);
          
          bool usePaintedColor = painted_color.w > 0.5;
          float paintedColorLuminance = dot(painted_color.xyz, float3(0.3, 0.6, 0.1));
          float paintedColorLumAdjust = min(1.0, 0.5 / paintedColorLuminance);
          
          float3 dysonEditorDefaultColor = usePaintedColor ? painted_color.xyz : float3(0, 3, 0.75);
          emissionColor = lerp(emissionColor, dysonEditorDefaultColor, isPlanned);
          
          float3 dysonEditorPaintedTint = float3(5,5,5) * painted_color.xyz * paintedColorLumAdjust;
          float3 dysonEditorHoverDeleteColor = float3(3.7, 0.075, 0.125);
          dysonEditorHoverDeleteColor = usePaintedColor ? dysonEditorPaintedTint : dysonEditorHoverDeleteColor;
          float3 dysonEditorHoverWhileSelectedColor = float3(0.75, 1.25, 3.9);
          dysonEditorHoverWhileSelectedColor = usePaintedColor ? dysonEditorPaintedTint : dysonEditorHoverWhileSelectedColor;
          float3 dysonEditorSelectedColor = float3(0.5, 1.0, 3.85);
          dysonEditorSelectedColor = usePaintedColor ? dysonEditorPaintedTint : dysonEditorSelectedColor;
          float3 dysonEditorHoverColor = float3(3.5, 2.0, 1.0);
          dysonEditorHoverColor = usePaintedColor ? dysonEditorPaintedTint : dysonEditorHoverColor;
          
          emissionColor = i.u_v_radius_state.w > 0.5 ? dysonEditorHoverColor : emissionColor; //state == 1 (hover select)
          emissionColor = i.u_v_radius_state.w > 1.5 ? dysonEditorSelectedColor : emissionColor; //state == 2 (selected)
          emissionColor = i.u_v_radius_state.w > 2.5 ? dysonEditorHoverWhileSelectedColor : emissionColor; //state == 3 (hover select while selected)
          emissionColor = i.u_v_radius_state.w > 3.5 ? dysonEditorHoverDeleteColor : emissionColor; //state == 4 (hover delete)
        }
        
        float3 viewFromSunDir = normalize(_WorldSpaceCameraPos.xyz - _Global_DS_SunPosition.xyz);
        float sideInView = dot(viewFromSunDir.xyz, -lightDir); // 1 if top of frame is facing player, 0 if viewing side on, -1 if bottom of frame is facing player (directly behind sun)
        float innerFalloff = pow(saturate(1.02 + sideInView), 0.4); // 1 until view side on, then falloff as we view the bottom of frame until it moves behind the star. minimum .2
        innerFalloff = renderPlace < 0.5 ? innerFalloff : 1;
        
        float3 unpackedNormal = UnpackNormal(tex2Dbias(_NormalTex, float4(i.u_v_radius_state.xy, 0, -1)));
        float3 tangentNormal = normalize(unpackedNormal);
        
        float3 worldNormal;
        worldNormal.x = dot(i.tbnw_matrix_x.xyz, tangentNormal);
        worldNormal.y = dot(i.tbnw_matrix_y.xyz, tangentNormal);
        worldNormal.z = dot(i.tbnw_matrix_z.xyz, tangentNormal);
        worldNormal.xyz = normalize(worldNormal.xyz);
        
        float nDotL = dot(worldNormal.xyz, lightDir.xyz);

        float3 halfDir = normalize(viewDir.xyz + lightDir.xyz);
        
        float ambientLightFalloff = saturate(pow(nDotL * 0.5 + 0.6, 3.0)); //expo: -1=0, 0=0.2, 0.8=1
        float3 editorViewDir = normalize(float3(0,3,0) + _WorldSpaceCameraPos.xyz);//direction to camera but slightly higher
        float editorNDotV = max(0, dot(worldNormal.xyz, editorViewDir));
        ambientLightFalloff = renderPlace > 1.5 ? ambientLightFalloff + editorNDotV : ambientLightFalloff;
        
        float nDotV = max(0, dot(worldNormal.xyz, viewDir.xyz));
        float nDotH = max(0, dot(worldNormal.xyz, halfDir.xyz));
        float vDotH = max(0, dot(viewDir.xyz, halfDir.xyz));
        float clamped_nDotL = max(0, nDotL);

        float2 mstex = tex2D(_MSTex, i.u_v_radius_state.xy).xw;
        float metallic = saturate(mstex.x * 0.85 + 0.149);
        float perceptualRoughness = saturate(1 - mstex.y * 0.97);
        float roughness = perceptualRoughness * perceptualRoughness;
        float scaledMetallic = 0.5 + metallic;
        float specularTerm = GGX(roughness, scaledMetallic, nDotH, nDotV, clamped_nDotL, vDotH);
        
        float starLightStrength = length(i.lightray_layer.xyz);
        
        float3 ambientLightStrength = lerp(1.0, starLightStrength, ambientLightFalloff);
        float3 ambientLight = float3(0.2, 0.2, 0.2) * _SunColor.xyz * ambientLightStrength * ambientLightFalloff;
        float3 ambientColor = ambientLight.xyz * albedo.xyz;
        
        float3 sunColor = _SunColor.xyz * starLightStrength;
        sunColor.xyz = float3(1.25, 1.25, 1.25) * sunColor.xyz;
        float3 highlightColor = sunColor * clamped_nDotL * albedo.xyz;
        
        float3 specularColor = float3(0.3, 0.3, 0.3) * lerp(float3(1,1,1), albedo.xyz, metallic);
        specularColor = specularColor.xyz * sunColor;
        specularColor.xyz = specularColor.xyz * clamped_nDotL * (specularTerm + INV_TEN_PI);
        
        float3 specColorMod = 0.2 * albedo.xyz * (1.0 - metallic) + metallic;
        specularColor = specularColor * specColorMod.xyz;
        
        float3 finalColor = ambientColor.xyz * (1.0 - metallic * 0.6)
            + highlightColor.xyz * pow(1.0 - metallic, 0.6)
            + specularColor.xyz;
        finalColor = finalColor.xyz * innerFalloff;
        
        float finalColorLuminance = dot(finalColor.xyz, float3(0.3, 0.6, 0.1));
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