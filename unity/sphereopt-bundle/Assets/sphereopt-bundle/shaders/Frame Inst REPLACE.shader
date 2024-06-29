Shader "VF Shaders/Dyson Sphere/Frame Inst REPLACE" {
  Properties {
    _MainTex ("Albedo (RGB)", 2D) = "white" {}
    _NormalTex ("Normal Map", 2D) = "bump" {}
    _MSTex ("Metallic Smoothness (RA)", 2D) = "white" {}
    _EmissionTex ("Emission (RGB)", 2D) = "black" {}
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
      
      struct FrameSegment {
        uint layer_state_progress_color; //layer [0-3], state [4-6], progress [7], color [8-31]
        float3 pos0;
        float3 pos1;
        uint padding;
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

      StructuredBuffer<FrameSegment> _InstBuffer;
      StructuredBuffer<uint> _InstIndexBuffer;

      float4 _SunColor;
      float4 _DysonEmission;
      int _Global_DS_EditorMaskL;
      int _Global_DS_GameMaskL;
      uint _Global_DS_HideFarSide;
      int _Global_DS_PaintingLayerId;
      float3 _Global_DS_SunPosition;
      uint _Global_DS_RenderPlace;
      float3 _Global_DS_SunPosition_Map;
      float4 _LayerRotations[11 * 3];
      sampler2D _MainTex;
      sampler2D _MSTex;
      sampler2D _NormalTex;
      sampler2D _EmissionTex;

        bool HandleHideOptions(int layer, bool isFarSide)
        {
            int layerMask = 1 << layer;
            
            UNITY_BRANCH
            if (_Global_DS_RenderPlace >= 2u) {
                if ((layerMask & _Global_DS_EditorMaskL) <= 0)
                    return false;
                    
                if (isFarSide && _Global_DS_HideFarSide >= 1u)
                    return false;
                
                bool isPainting = _Global_DS_PaintingLayerId > 0;
                if (isPainting && layer != _Global_DS_PaintingLayerId)
                    return false;
                
                return true;
            } else {
                return (layerMask & _Global_DS_GameMaskL) > 0;
            }
        }

      v2f vert( appdata_part v, uint instanceID : SV_InstanceID)
      {
        v2f o;

        uint instIndex = _InstIndexBuffer[instanceID];

        uint layer_state_progress_color = _InstBuffer[instIndex].layer_state_progress_color;
        uint layer = BitFieldExtract(layer_state_progress_color, 0, 4);
        
        unity_ObjectToWorld._m00_m01_m02_m03 = _LayerRotations[layer * 3];
        unity_ObjectToWorld._m10_m11_m12_m13 = _LayerRotations[layer * 3 + 1];
        unity_ObjectToWorld._m20_m21_m22_m23 = _LayerRotations[layer * 3 + 2];
        unity_ObjectToWorld._m30_m31_m32_m33 = float4(0,0,0,1);
        
        float3 pos0 = _InstBuffer[instIndex].pos0;
        float3 pos1 = _InstBuffer[instIndex].pos1;
        float3 stretchedPos = lerp(pos0.xyz, pos1.xyz, v.vertex.z * 0.98 + 0.01);
        
        float3 z_axis = pos1.xyz - pos0.xyz;
        
        int compare_instanceID = v.vertex.z < 0.5 ? (int)instIndex - 1 : (int)instIndex + 1;
        float3 compare_pos0 = _InstBuffer[compare_instanceID].pos0;
        float3 compare_pos1 = _InstBuffer[compare_instanceID].pos1;

        float3 rayToNeighborFrame = v.vertex.z < 0.5 ? compare_pos1.xyz - pos0.xyz : pos1.xyz - compare_pos0.xyz;
        bool IsTouchingNeighbor = length(rayToNeighborFrame) < 0.01;
        
        float3 rayEndToEnd = v.vertex.z < 0.5 ? pos0.xyz - compare_pos0.xyz : compare_pos1.xyz - pos1.xyz;
        bool IsParallelWithNeightbor = dot(normalize(z_axis), normalize(rayEndToEnd)) > 0.9;
        
        float3 smoothedZAxis = v.vertex.z < 0.5 ? pos1.xyz - compare_pos0.xyz : compare_pos1.xyz - pos0.xyz;

        z_axis = IsTouchingNeighbor && IsParallelWithNeightbor ? smoothedZAxis : z_axis;

        z_axis.xyz = normalize(z_axis.xyz);
        float3 y_axis = normalize(stretchedPos.xyz);
        float3 x_axis = normalize(cross(y_axis.xyz, z_axis.xyz));
        z_axis.xyz = cross(x_axis.xyz, y_axis.xyz);

        float3x3 rotateMatrix = transpose(float3x3(x_axis, y_axis, z_axis));

        float3 vertPos = 100 * v.vertex.x * x_axis.xyz
                       + 100 * v.vertex.y * y_axis.xyz
                       + stretchedPos.xyz;
                       
        float3 objNormal = mul(rotateMatrix, v.normal.xyz);
        float3 objTangent = mul(rotateMatrix, v.tangent.xyz);

        float3 worldPos = mul(unity_ObjectToWorld, float4(vertPos, 1));
        float3 worldNormal = normalize(mul((float3x3)unity_ObjectToWorld, objNormal));
        float3 worldTangent = normalize(mul((float3x3)unity_ObjectToWorld, objTangent));
        float3 worldBinormal = calculateBinormal(float4(worldTangent, v.tangent.w), worldNormal);

        float invFrameRadius = rsqrt(dot(vertPos.xyz, vertPos.xyz));
        float falloffDistance = pow(1 + min(4, max(0, 5000 * invFrameRadius - 0.2)), 2);

        float3 lightray = _Global_DS_RenderPlace <= 1u ? normalize(worldPos.xyz - _Global_DS_SunPosition.xyz) * falloffDistance : normalize(worldPos.xyz - _Global_DS_SunPosition_Map.xyz) * falloffDistance;

        float3 rayViewToPos = worldPos.xyz - _WorldSpaceCameraPos.xyz;
        float distViewToPos = length(rayViewToPos.xyz);
        //float scaled_distViewToPos = 10000 * (log(0.0001 * distViewToPos) + 1) / distViewToPos;
        float scaled_distViewToPos = (10000.0 * log(distViewToPos) - 82103.4) / distViewToPos;
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
            
            int layer = round(i.lightray_layer.w);
            float3 worldPos = float3(
                i.tbnw_matrix_x.w,
                i.tbnw_matrix_y.w,
                i.tbnw_matrix_z.w
            );
            
            float3 viewDir = normalize(_WorldSpaceCameraPos - worldPos);
            float3 lightDir = normalize(-i.lightray_layer.xyz);
            bool isFarSide = dot(viewDir, lightDir) > 0;
            
            bool isShowing = HandleHideOptions(layer, isFarSide);
            if (!isShowing)
                discard;
            
            uint instIndex = (uint)(i.u_v_index.z + 0.5);
            uint layer_state_progress_color = _InstBuffer[instIndex].layer_state_progress_color;
            uint state = BitFieldExtract(layer_state_progress_color, 4, 3);
            bool hasProgress = BitFieldExtract(layer_state_progress_color, 7, 1) > 0u;
            
        
            float isPlanned = 0;
            if (!hasProgress) {
                if (_Global_DS_RenderPlace >= 2u) {
                    if (state <= 1u) {
                    uint2 pixelPos = screenPos.xy;
                    int mask = (pixelPos.x & 1) - (pixelPos.y & 1);
                    if (mask != 0) discard;
                }
                    isPlanned = 1;
                } else {
                    discard;
                }
            }
        
            uint color = BitFieldExtract(layer_state_progress_color, 8, 24);
            float3 gamma_color = ((color >> int3(0,8,16)) & int3(255,255,255)) / 255.0;
            float4 painted_color = float4(GammaToLinearSpace(gamma_color.xyz), 0);
            painted_color.w = gamma_color.x + gamma_color.y + gamma_color.z > 0.01 ? 1.0 : 0.0;
            
            float3 emissionTex = tex2Dbias(_EmissionTex, float4(i.u_v_index.xy, 0,  -1)).xyz;
            float emissionLuminance = dot(emissionTex, float3(0.3, 0.6, 0.1));
            float3 emissionColor = lerp(_DysonEmission.xyz * emissionLuminance, painted_color.xyz * emissionLuminance, painted_color.w);
            float emissionBoost = _Global_DS_RenderPlace >= 1u ? 9.0 : 6.0;
            emissionColor = emissionColor * emissionBoost;
            
            float3 albedo = tex2D(_MainTex, i.u_v_index.xy).xyz;
            float albedoLuminance = dot(albedo, float3(0.3, 0.6, 0.1));
        
            UNITY_BRANCH
            if (_Global_DS_RenderPlace <= 1u) {
                float3 standardStrength = lerp(albedoLuminance, painted_color.xyz, painted_color.w * 0.2);
                float3 boostedStrength = lerp(albedoLuminance, painted_color.xyz * albedoLuminance, painted_color.w * 0.2);
                albedo = lerp(standardStrength, boostedStrength, 0.7);
            } else {
                albedoLuminance = albedoLuminance * (1.0 - isPlanned);
                float3 standardStrength = lerp(albedoLuminance, painted_color.xyz, painted_color.w * 0.3);
                float3 boostedStrength = lerp(albedoLuminance, painted_color.xyz * albedoLuminance, painted_color.w * 0.3);
                albedo = lerp(standardStrength, boostedStrength, 0.6);
                
                bool usePaintedColor = painted_color.w > 0.5;
                
                float3 dysonEditorDefaultColor = usePaintedColor ? painted_color.xyz : float3(0, 3, 0.75);
                emissionColor = lerp(emissionColor, dysonEditorDefaultColor, isPlanned);
                
                float paintedColorLuminance = dot(painted_color.xyz, float3(0.3, 0.6, 0.1));
                float paintedColorLumAdjust = 5.0 * saturate(0.1 / paintedColorLuminance);
                float3 dysonEditorPaintedTint = painted_color.xyz * paintedColorLumAdjust;
                
                float3 dysonEditorHoverDeleteColor = usePaintedColor ? dysonEditorPaintedTint : float3(3.7, 0.075, 0.125);
                float3 dysonEditorHoverWhileSelectedColor = usePaintedColor ? dysonEditorPaintedTint : float3(0.75, 1.25, 3.9);
                float3 dysonEditorSelectedColor = usePaintedColor ? dysonEditorPaintedTint : float3(0.5, 1.0, 3.85);
                float3 dysonEditorHoverColor = usePaintedColor ? dysonEditorPaintedTint : float3(3.5, 2.0, 1.0);

                UNITY_FLATTEN
                switch(state)
                {
                    case 1u: // hover select
                        emissionColor = dysonEditorHoverColor;
                        break;
                    case 2u: // selected
                        emissionColor = dysonEditorSelectedColor;
                        break;
                    case 3u: // hover select while selected
                        emissionColor = dysonEditorHoverWhileSelectedColor;
                        break;
                    case 4u: // hover delete
                        emissionColor = dysonEditorHoverDeleteColor;
                        break;
                }
            }
        
            float3 sunToCamDir = normalize(_WorldSpaceCameraPos - _Global_DS_SunPosition);
            float sideInView = dot(sunToCamDir, -lightDir); // 1 if top of frame is facing player, 0 if viewing side on, -1 if bottom of frame is facing player (directly behind sun)
            float innerFalloff = _Global_DS_RenderPlace >= 1u ? 1.0 : pow(saturate(1.02 + sideInView), 0.4); // 1 until view side on, then falloff as we view the bottom of frame until it moves behind the star. minimum .2
            
            float3 unpackedNormal = UnpackNormal(tex2Dbias(_NormalTex, float4(i.u_v_index.xy, 0, -1)));
            float3 tangentNormal = normalize(unpackedNormal);
        
            float3 worldNormal = normalize(float3(
                dot(i.tbnw_matrix_x.xyz, tangentNormal),
                dot(i.tbnw_matrix_y.xyz, tangentNormal),
                dot(i.tbnw_matrix_z.xyz, tangentNormal)
            ));
        
            float nDotL = dot(worldNormal, lightDir);
            float3 halfDir = normalize(viewDir + lightDir);
            float nDotV = max(0, dot(worldNormal, viewDir));
            float nDotH = max(0, dot(worldNormal, halfDir));
            float vDotH = max(0, dot(viewDir, halfDir));
            float clamped_nDotL = max(0, nDotL);
            
            float2 msTex = tex2D(_MSTex, i.u_v_index.xy).xw;
            float metallic = saturate(msTex.x * 0.85 + 0.149);
            float perceptualRoughness = saturate(1 - msTex.y * 0.97);
            float roughness = perceptualRoughness * perceptualRoughness;
            float scaledMetallic = 0.5 + metallic;
            
            float specularTerm = GGX(roughness, scaledMetallic, nDotH, nDotV, clamped_nDotL, vDotH);
            
            float ambientLightFalloff = saturate(pow(nDotL * 0.5 + 0.6, 3.0)); //expo: -1=0, 0=0.2, 0.8=1
            
            if (_Global_DS_RenderPlace >= 1u)
            {
                float3 editorViewDir = normalize(float3(0,3,0) + _WorldSpaceCameraPos);//direction to camera but slightly higher
                float editorNDotV = max(0, dot(worldNormal, editorViewDir));
                ambientLightFalloff = ambientLightFalloff + editorNDotV;
            }
            
            float distFromStar = length(i.lightray_layer.xyz);
            float3 ambientLightStrength = lerp(1.0, distFromStar, ambientLightFalloff);
            float3 ambientLight = _SunColor.xyz * 0.2 * ambientLightFalloff * ambientLightStrength;
            float3 ambientColor = ambientLight * albedo;
            
            float3 sunColor = _SunColor.xyz * (1.25 * distFromStar);
            float3 highlightColor = sunColor * clamped_nDotL * albedo;
        
            float dielectric = 1.0 - metallic;
            float3 specularColor = 0.3 * lerp(albedo, float3(1,1,1), dielectric);
            specularColor = specularColor * sunColor;
            specularColor = specularColor * clamped_nDotL * (specularTerm + INV_TEN_PI);
            
            float3 specColorMod = 0.2 * albedo * dielectric + metallic;
            specularColor = specularColor * specColorMod;
            
            float3 finalColor = ambientColor * (dielectric * 0.6)
              + highlightColor * pow(dielectric, 0.6)
              + specularColor;
            finalColor = finalColor * innerFalloff;
            
            float finalColorLuminance = dot(finalColor, float3(0.3, 0.6, 0.1));
            finalColor = finalColorLuminance > 1 ? (finalColor / finalColorLuminance) * (log(log(finalColorLuminance) + 1) + 1) : finalColor;
            
            finalColor = finalColor + emissionColor;
            
            o.sv_target.xyz = finalColor;
            o.sv_target.w = 1;
            return o;
        }
      ENDCG
    }
  }
}