Shader "VF Shaders/Dyson Sphere/Dyson Shell Unlit Instanced" {
  Properties {
    _Color ("Color", Color) = (1,1,1,1)
    _MainTex ("Albedo (RGB)", 2D) = "white" {}
    _NormalTex ("Normal Map", 2D) = "bump" {}
    _MSTex ("Metallic Smoothness (RA)", 2D) = "white" {}
    _EmissionTex ("Emission (RGB)", 2D) = "black" {}
    _NoiseTex ("Noise Texture (R)", 2D) = "gray" {}
    _ColorControlTex ("Color Control", 2D) = "black" {}
    _AlbedoMultiplier ("漫反射倍率", Float) = 1
    _NormalMultiplier ("法线倍率", Float) = 1
    _CellSize ("细胞大小（是否有间隙）", Float) = 1
  }
  SubShader {
    Pass {
      Tags { "LIGHTMODE" = "FORWARDBASE" "QUEUE" = "Geometry" "RenderType" = "DysonShell" }
      Cull Off
      Stencil {
        ref [_Stencil]
        CompFront Always
        PassFront Replace
        FailFront Keep
        ZFailFront Keep
      }
      CGPROGRAM
      #pragma vertex vert
      #pragma fragment frag
      #pragma target 5.0
      #pragma enable_d3d11_debug_symbols

    struct PolygonData
    {
        float3 pos;
        float3 normal;
    };

    struct HexProgressData
    {
        float progress;
    };

    struct HexData
    {
        float3 pos;
        int shellIndex;
        int nodeIndex;
        float vertFillOrder;
        int closestPolygon;
        uint axialCoords_xy;
    };

    struct ShellData
    {
        int color;
        uint state; 
        int progressBaseIndex;
        int polyCount;
        int polygonIndex;
        float3 center;
        int protoId;
    };

    struct appdata_part {
      float4 vertex : POSITION;
    };

      StructuredBuffer<PolygonData> _PolygonBuffer;
      StructuredBuffer<HexData> _HexBuffer;
      StructuredBuffer<HexProgressData> _HexProgressBuffer;
      StructuredBuffer<ShellData> _ShellBuffer;

      float4 _SunColor;
      float4 _DysonEmission;
      float3 _Global_DS_SunPosition;
      float3 _Global_DS_SunPosition_Map;
      int _Global_DS_HideFarSide;
      int _Global_DS_PaintingLayerId;
      int _LayerId;
      int _Global_DS_PaintingGridMode;
      float _AlbedoMultiplier;
      float _NormalMultiplier;
      float _EmissionMultiplier[7];
      int _Global_IsMenuDemo;
      int _Global_DS_RenderPlace;
      float _CellSize;
      float _Scale;
      float _GridSize;
      float _Radius;
      float4x4 _ObjectToWorld;

      sampler2D _NoiseTex;
      sampler2D _MainTex;
      sampler2D _NormalTex;
      sampler2D _MSTex;
      sampler2D _EmissionTex;
      UNITY_DECLARE_TEX2DARRAY(_EmissionTex2);
      sampler2D _ColorControlTex;
      UNITY_DECLARE_TEX2DARRAY(_ColorControlTex2);

      #include "UnityCG.cginc"
      #include "CGIncludes/DSPCommon.cginc"

struct v2f
{
    float4 vertex : SV_POSITION;
    float4 uv_axialCoords : TEXCOORD0;
    float3 objectPos : TEXCOORD1;
    float3 worldPos : TEXCOORD2;
    float3 tangent : TEXCOORD3;
    float3 binormal : TEXCOORD4;
    float3 normal : TEXCOORD5;
    float4 pidx_close_pct_cnt : TEXCOORD6;
    float3 state_clock_protoid : TEXCOORD7;
    float4 color : TEXCOORD8;
};

struct fout
{
    float4 sv_target : SV_Target0;
};

v2f vert(appdata_part v, uint instanceID : SV_InstanceID)
{
    v2f o;

    unity_ObjectToWorld = _ObjectToWorld;
    float renderPlace = asuint(_Global_DS_RenderPlace);

    float3 hexMidPtPos = _HexBuffer[instanceID].pos;
    uint shellIndex = _HexBuffer[instanceID].shellIndex;
    float worldHexMidPtLength = length(mul(unity_ObjectToWorld, float4(hexMidPtPos,1)).xyz);

    float scaleGrid = min(1, 30 * saturate((worldHexMidPtLength / (18.0 * 80.0 * _Scale)) - 0.5)) * 0.07 + 1;
    scaleGrid = saturate(worldHexMidPtLength / (1.5 * 80.0 * _Scale)) * min(1, scaleGrid - min(0.1, rcp(5.0 * _Scale)));
    float3 shellCenterPos = _ShellBuffer[shellIndex].center;
    float distFromCenter = dot(normalize(shellCenterPos.xyz), normalize(hexMidPtPos));
    distFromCenter = renderPlace > 1.5 ? distFromCenter : distFromCenter * scaleGrid;
    float viewDistFalloff = 1 - min(4, max(0, 0.0001 * (length(_WorldSpaceCameraPos - hexMidPtPos) - 3000))) * 0.25;
    int protoId = _ShellBuffer[shellIndex].protoId + 0.5;
    float cellSize = protoId > 0.5 ? 1.0 : 0.94;
    float scaledCellSize = distFromCenter * lerp(1, cellSize, viewDistFalloff) * _Scale;

    float3 z_axis = normalize(shellCenterPos);
    float3 x_axis = normalize(cross(z_axis, float3(0,1,0)));
    float3 y_axis = normalize(cross(x_axis, z_axis));
    int flipSign = -sign(shellCenterPos.z);
    x_axis.xyz = abs(z_axis.x) > 0.001 || abs(z_axis.y) > 0.001 ? x_axis : float3(1,0,0);
    y_axis.xyz = abs(z_axis.x) > 0.001 || abs(z_axis.y) > 0.001 ? y_axis : float3(0, flipSign, 0);
    z_axis.xyz = abs(z_axis.x) > 0.001 || abs(z_axis.y) > 0.001 ? z_axis : float3(0, 0, flipSign);
    //hexMidPtPos.xy = abs(z_axis.x) > 0.001 || abs(z_axis.y) > 0.001 ? hexMidPtPos.xy : float2(0, 0);
    float3x3 rotMatrix = float3x3(x_axis, y_axis, z_axis);

    float3 vertPos = any(v.vertex.xyz) ? normalize(mul(v.vertex.xyz, rotMatrix) * scaledCellSize + hexMidPtPos) * _Radius : hexMidPtPos;
    vertPos = renderPlace < 0.5 ? vertPos : vertPos * 0.00025;

    float3 normal = normalize(shellCenterPos);
    float3 tangent = mul(normalize(float3(sqrt(3) / 2.0, -1.0, 0)), rotMatrix);
    float3 binormal = mul(float3(0,1,0), rotMatrix);

    float3 worldPos =  mul(unity_ObjectToWorld, float4(vertPos,1)).xyz;
    float3 worldTangent = UnityObjectToWorldDir(tangent);
    float3 worldBinormal = UnityObjectToWorldDir(binormal);
    float3 worldNormal = UnityObjectToWorldDir(normal);

    float3 rayCamToHexPoint = worldPos - _WorldSpaceCameraPos;
    rayCamToHexPoint = length(rayCamToHexPoint) > 10000 ? rayCamToHexPoint * ((10000 * (log(0.0001 * length(rayCamToHexPoint)) + 1)) / length(rayCamToHexPoint)) : rayCamToHexPoint;
    float3 adjustedWorldHexPointPos = _WorldSpaceCameraPos + rayCamToHexPoint;
    worldPos = renderPlace < 0.5 ? adjustedWorldHexPointPos : worldPos;

    float4 clipPos = UnityWorldToClipPos(worldPos);

    int color = _ShellBuffer[shellIndex].color;
    float4 gamma_color = ((asuint(color) >> int4(0,8,16,24)) & int4(255,255,255,255)) / 255.0;
    float4 linear_color = float4(GammaToLinearSpace(gamma_color.xyz), gamma_color.w);

    uint packedAxialCoords = _HexBuffer[instanceID].axialCoords_xy;
    int2 axialCoords;
    axialCoords.x = (int)(packedAxialCoords << 16) >> 16;
    axialCoords.y = (int)(packedAxialCoords & 0xffff0000) >> 16;

    
    uint nodeIndex = _HexBuffer[instanceID].nodeIndex;
    float closestPolygon = _HexBuffer[instanceID].closestPolygon;
    float vertFillOrder = _HexBuffer[instanceID].vertFillOrder;
    uint progressBaseIndex = _ShellBuffer[shellIndex].progressBaseIndex;
    float polygonIndex = _ShellBuffer[shellIndex].polygonIndex;
    float polyCount = _ShellBuffer[shellIndex].polyCount;
    float state = _ShellBuffer[shellIndex].state;
    uint hexProgressIndex = progressBaseIndex + nodeIndex;
    float nodeProgress = _HexProgressBuffer[hexProgressIndex].progress;
    float scaleProgress = saturate(((1 + (0.28 / _Scale)) * nodeProgress - pow(vertFillOrder, 1.25)) / (0.28 / _Scale));
    float2 uv = float2(sign(v.vertex.x), sign(sign(v.vertex.x) + sign(v.vertex.y))) * (_Scale / 3.0);

    o.vertex.xyzw = clipPos;
    o.uv_axialCoords.xy = uv;
    o.uv_axialCoords.zw = axialCoords; //move to frag?
    o.objectPos.xyz = vertPos;
    o.worldPos.xyz = worldPos;
    o.tangent.xyz = worldTangent;
    o.binormal.xyz = worldBinormal;
    o.normal.xyz = worldNormal;

    o.pidx_close_pct_cnt.x = polygonIndex;
    o.pidx_close_pct_cnt.y = closestPolygon;
    o.pidx_close_pct_cnt.z = scaleProgress;
    o.pidx_close_pct_cnt.w = polyCount;

    o.state_clock_protoid.x = state;
    o.state_clock_protoid.y = 1;
    o.state_clock_protoid.z = protoId;

    o.color.xyzw = linear_color; //move to frag?

    return o;
}

  fout frag(v2f i, bool viewingOutwardFacingSide : SV_IsFrontFace, float4 screenPos : SV_POSITION)
  {

    fout o;

    uint renderPlace = asuint(_Global_DS_RenderPlace);

    if ((asint(_Global_DS_PaintingLayerId) != asint(_LayerId) || asuint(_Global_DS_PaintingGridMode) > 0.5) && (asuint(_Global_DS_PaintingLayerId) > 0 && renderPlace > 1.5))
        discard;

    if (renderPlace > 1.5 && _Global_DS_HideFarSide > 0.5 && dot(_WorldSpaceCameraPos.xyz - i.worldPos.xyz, _Global_DS_SunPosition_Map.xyz - i.worldPos.xyz) > 0.0))
        discard;

    //uint polyCount = i.polyGroup_pctComplete_polyCount_state.z;
    float state = i.state_clock_protoid.x;
    int protoId = i.state_clock_protoid.z + 0.5;

    /* remove pixels that fall outside the bounds of the frame that surrounds this shell */
    uint polyCount = i.pidx_close_pct_cnt.w + 0.5;
    polyCount = polyCount < 1 ? 1 : min(380, polyCount;

    int closestPolygon = i.pidx_close_pct_cnt.y + 0.5;
    int polygonBaseIndex = i.pidx_close_pct_cnt.x + 0.5;
    int thisIndex = polygonBaseIndex + closestPolygon;

    int prevIndexOffset = closestPolygon == 0 ? polyCount - 1 : closestPolygon - 1;
    int nextIndexOffset = fmod(closestPolygon + 1, polyCount); 
    int nextnextIndexOffset = fmod(closestPolygon + 2, polyCount);

    int prevIndex = (int)thisIndex - 1; //r2.x
  int nextIndex = (int)thisIndex + 1; //r2.y
  int nextnextIndex = (int)thisIndex + 2; //r2.z

  float3 thisEdge = _PolygonBuffer[nextIndex].pos - _PolygonBuffer[thisIndex].pos;
  float angleThisEdge = dot(thisEdge, _PolygonBuffer[prevIndex].normal); //r0.w

  float3 prevToPoint = i.objectPos.xyz - _PolygonBuffer[prevIndex].pos;
  float sideOfPrevEdge = dot(prevToPoint, _PolygonBuffer[prevIndex].normal); //r1.w

  float3 nextToPoint = i.objectPos.xyz - _PolygonBuffer[nextIndex].pos;
  float sideOfThisEdge = dot(nextToPoint, _PolygonBuffer[thisIndex].normal); //r2.x

  float3 nextEdge = _PolygonBuffer[nextnextIndex].pos - _PolygonBuffer[nextIndex].pos;
  float angleNextEdge = dot(nextEdge, _PolygonBuffer[thisIndex].normal); //r0.z

  float3 nextnextToPoint = i.objectPos.xyz - _PolygonBuffer[nextnextIndex].pos;
  float sideOfNextEdge = dot(nextnextToPoint, _PolygonBuffer[nextIndex].normal); //r2.y

  int acuteObtuseNextEdge = (int)(angleNextEdge < 0) - (int)(angleNextEdge > 0); //r0.z
  int acuteObtuseThisEdge = (int)(angleThisEdge < 0) - (int)(angleThisEdge > 0); //r0.w

  acuteObtuseNextEdge = _Clockwise * acuteObtuseNextEdge;
  acuteObtuseThisEdge = _Clockwise * acuteObtuseThisEdge;
  sideOfPrevEdge = _Clockwise * sideOfPrevEdge; //r1.w
  sideOfThisEdge = _Clockwise * sideOfThisEdge; //r2.x
  sideOfNextEdge = _Clockwise * sideOfNextEdge; //r2.y

  bool IsAcuteObtuseThis = acuteObtuseThisEdge > 0.0; //r2.z
  bool IsAcuteObtuseNext = acuteObtuseNextEdge > 0.0; //r2.w

  float clipVal; //r3.x
  if (IsAcuteObtuseNext && IsAcuteObtuseThis) {
    bool IsInsideOutsidePrev = sideOfPrevEdge > 0; //r3.x
    bool IsInsideOutsideThis = sideOfThisEdge > 0; //r3.y
    bool IsInsideOutsideNext = sideOfNextEdge > 0; //r3.y
    clipVal = IsInsideOutsideNext && IsInsideOutsideThis && IsInsideOutsidePrev ? 1 : -1;
  } else {
    bool IsInsideOutsidePrev = sideOfPrevEdge > 0; //r1.w
    bool IsInsideOutsideThis = sideOfThisEdge > 0; //r2.x
    bool IsInsideOutsideNext = sideOfNextEdge > 0; //r2.y

    if (IsAcuteObtuseNext && !IsAcuteObtuseThis) {
        clipVal = (IsInsideOutsidePrev || IsInsideOutsideThis) && IsInsideOutsideNext ? 1 : -1;
    }
    else if (!IsAcuteObtuseNext && IsAcuteObtuseThis) {
        clipVal = IsInsideOutsidePrev && (IsInsideOutsideThis || IsInsideOutsideNext) ? 1 : -1;
    }
    else {
        clipVal = IsInsideOutsideNext || IsInsideOutsidePrev || IsInsideOutsideThis ? 1 : -1;
    }
  }

  if (clipVal < 0)
    discard;


    float distToCam = length(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
    
    float2 uv = i.uv_axialCoords.xy;
      float2 axialCoords = i.uv_axialCoords.zw;

      float4 cubeCoords;
      cubeCoords.xy = _Scale * float2(2.0/3.0, 1.0/3.0) * axialCoords.xx;
      cubeCoords.zw = _Scale * float2(-1.0/3.0, 1.0/3.0) * axialCoords.yy;
      cubeCoords.xy = cubeCoords.yx + cubeCoords.wz;

      float gridFalloff = 0.99 - saturate((distToCam / _GridSize) / 15.0 - 0.2) * 0.03;

      float2 adjustPoint = cubeCoords.yx * float2(2.0, 2.0) - uv.yx * gridFalloff - cubeCoords.xy; //r4.xy
      float2 roundedAdjustPoint = round(adjustPoint.xy); //r5.zw

      float adjustPointZ = -adjustPoint.x - adjustPoint.y; //r0.w
      float roundedAdjustPointZ = round(adjustPointZ); //r1.w

      float2 correctedCoords = roundedAdjustPoint;;
      if (roundedAdjustPoint.x + roundedAdjustPoint.y + roundedAdjustPointZ == 0.0) {
          adjustPoint.xy = roundedAdjustPoint.xy < adjustPoint.xy ? adjustPoint.xy - roundedAdjustPoint.xy : roundedAdjustPoint.xy - adjustPoint.xy;
          adjustPointZ = roundedAdjustPointZ < adjustPointZ ? adjustPointZ - roundedAdjustPointZ : roundedAdjustPointZ - adjustPointZ;

          float adjustPointY = adjustPointZ < adjustPoint.y && adjustPoint.x < adjustPoint.y ? -roundedAdjustPoint.x - roundedAdjustPointZ : roundedAdjustPoint.y;
          correctedCoords.x  = adjustPointZ < adjustPoint.x && adjustPoint.y < adjustPoint.x ? -roundedAdjustPoint.y - roundedAdjustPointZ : roundedAdjustPoint.x;
          correctedCoords.y  = adjustPointZ < adjustPoint.x && adjustPoint.y < adjustPoint.x ?  roundedAdjustPoint.y : adjustPointY;
      }

      float2 randomSampleCoords = correctedCoords.xy / 512.0;
      float random_num = tex2Dlod(_NoiseTex, float4(randomSampleCoords.xy, 0, 0)).x;

    float isPlanned = 0;
    if ((i.pidx_close_pct_cnt.z - random_num * 0.999 < 0.00005) {
        UNITY_BRANCH
        if (renderPlace > 1.5) {
            uint2 pixelPos = screenPos.xy;
            int mask = (pixelPos.x & 1) - (pixelPos.y & 1);
            if (mask != 0)
                discard;

            isPlanned = 1;
        } else {
          discard;
        }
    }

    float lodBias = min(4, max(0, log(0.0001 * distToCam))); //r1.w

      float4 innerTex = tex2Dbias(_MainTex, float4(uv.xy, 0, lodBias)).xyzw; //r6.xyzw

      float3 unpackedNormal = UnpackNormal(tex2Dbias(_NormalTex, float4(uv.xy, 0, lodBias)));

      float2 msTex = tex2D(_MSTex, uv.xy).xw; //MS //r7.xy
      float metallic = msTex.x;
      float smoothness = msTex.y;

      float3 emissionTex_A = tex2Dbias(_EmissionTex, float4(uv.xy, 0, lodBias)).xyz; //r8.xyz
      float2 invUV = float2(1.0, 1.0) - uv.yx;
      float3 emissionTex_B = tex2Dbias(_EmissionTex, float4(invUV.xy, 0, lodBias)).xyz; //r9.xyz
      float emissAnim = sin(2.0 * _Time.y) * 0.5 + 0.5; //r4.w
      float3 emiss = lerp(emissionTex_A, emissionTex_B, emissAnim); //r8.xyz
      float3 emissStyled = UNITY_SAMPLE_TEX2DARRAY(_EmissionTex2, float3(scaledUV.xy, protoId)).xyz; //emission2 //r9.xyz

      float colorControlTex_A = tex2Dbias(_ColorControlTex, float4(uv.xy, 0, lodBias)).x;
      float colorControlTex_B = tex2Dbias(_ColorControlTex, float4(invUV.xy, 0, lodBias)).x;
      float colorControl = lerp(colorControlTex_A, colorControlTex_B, emissAnim); //r4.w
      float colorControlStyled = UNITY_SAMPLE_TEX2DARRAY(_ColorControlTex2, float3(scaledUV.xy, protoId)).x; //r1.w
      colorControl = saturate(colorControl + colorControlStyled); //r1.w

      float3 worldNormal = i.tangent.xyz * unpackedNormal.x * -0.5
                         + i.binormal.xyz * unpackedNormal.y * -0.5
                         + i.normal.xyz * unpackedNormal.z;
      float3 worldNormal = normalize(worldNormal.xyz); //r10.xyz
      worldNormal = viewingOutwardFacingSide ? worldNormal : -worldNormal; //r10.xyz

      float3 innerEmissionColor = viewingOutwardFacingSide ? float3(1, 1, 1) : _DysonEmission.xyz; //r11.xyz

    float2 scaledUV = uv.xy / _Scale;
  scaledUV.xy = scaledUV.xy + axialCoords.xx / 3.0 + float2(axialCoords.x - axialCoords.y, axialCoords.y) / 3.0

  float3 triPosNew = 1.0 - abs(frac(0.5 * (float3(0.6666666, 0.0, 1.6666666) + scaledUV.xyx)) * 2.0 - 1.0);

  float2 newPosOne;
  newPosOne.x = ((triPosNew.x + triPosNew.y) / sqrt(2)) / sqrt(3);
  newPosOne.y =  (triPosNew.y - triPosNew.x) / sqrt(2);

  float2 newPosTwo;
  newPosTwo.x = ((triPosNew.z + triPosNew.y) / sqrt(2)) / sqrt(3);
  newPosTwo.y =  (triPosNew.y - triPosNew.z) / sqrt(2);

  float innerEmissionAnim = saturate(30.0 * (0.05 - abs(length(newPosOne.xy) - frac(2.9 * _Time.x)))) * min(1, 5 * (1 - frac(2.9 * _Time.x)))
       + saturate(30.0 * (0.05 - abs(length(newPosTwo.xy) - frac(_Time.x * 3.7 + 0.5)))) * min(1, 5 * (1 - frac(_Time.x * 3.7 + 0.5)));
  float innerEmissionAnim = saturate(innerEmissionAnim * (2.0 * emissStyled.y + emiss.y));
  innerEmissionAnim = viewingOutwardFacingSide ? 0.0 : innerEmissionAnim; //r2.w

  float3 emissionOutwardFacing = emissStyled * float3(0.3, 0.3, 0.3) + emiss; //r8.yzw
  float3 colorOutwardFacing = lerp(colorControl * i.color.xyz, i.color.xyz, 1.0 / (100.0 * _EmissionMultiplier)); //r9.yzw
  emissionOutwardFacing = lerp(emissionOutwardFacing, colorOutwardFacing, i.color.www);

  float3 emissionInwardFacing = (emissStyled.x + emiss.x) * innerEmissionColor * float3(3.0, 3.0, 3.0)
  float3 emission = viewingOutwardFacingSide ? emissionOutwardFacing : emissionInwardFacing; //r3.yzw

  emission = lerp(emission, innerEmissionColor, innerEmissionAnim); //r3.yzw

  float innerTex_Luminance = dot(pow(innerTex.xyz, 2.0), float3(0.3, 0.6, 0.1)); //r2.w

  distToCam = asuint(isMenuDemo) > 0.5 ? distToCam : (renderPlace > 0.5 ? 3999.9998 * distToCam : distToCam);
  float scaleMetallic = asuint(isMenuDemo) > 0.5 ? 0.1 : (renderPlace > 0.5 ? 0.93 : 0.7);
  float distanceScale = saturate(pow(0.25 * log(1.0 + distToCam) - 1.5, 3.0));
  float scaleMetallic = scaleMetallic * (1.0 - distanceScale);

  float3 plannedShellColor = asint(_Global_DS_PaintingLayerId) == asint(_LayerId) ? float3(0.0, 0.3, 0.65) : float3(0.0, 0.8, 0.6); //r6.yzw
  plannedShellColor = i.color.w > 0.5 ? i.color.xyz : plannedShellColor; //r6.yzw
  float emissionBrightness = renderPlace > 1.5 ? 2.2 : (renderPlace > 0.5 ? 1.8 : 2.5); //r0.y
  emission = lerp(_EmissionMultiplier * emission * emissionBrightness, plannedShellColor, 0.8 * isPlanned); //r3.yzw

  innerTex_Luminance = state > 0.5 ? 0.0 : 0.8 * innerTex_Luminance * (1.0 - isPlanned); //r0.x
  float specularStrength = state > 0.5 ? 0.0 : 0.03 * (1.0 - isPlanned); //r2.z
  metallic = state > 0.5 ? 0.0 : metallic * scaleMetallic; //r2.x
  smoothness = state > 0.5 ? 0.5 : min(0.8, smoothness); //r2.y

  float colorMultiplier = viewingOutwardFacingSide ? 1.5 : 2.0;
  float3 dysonEditorColor = renderPlace < 1.5 ? float3(0, 0, 0) : i.color.xyz * colorMultiplier; //r5.xzw

  float3 deleteColor = i.color.w > 0.5 ? dysonEditorColor : float3(2.59, 0.0525, 0.0875); //r6.yzw
  float3 hoverSelectColor = i.color.w > 0.5 ? dysonEditorColor : float3(0.525, 0.875, 3.5); //r8.xyz
  float3 selectColor = i.color.w > 0.5 ? dysonEditorColor : float3(0.35, 0.7, 3.5); //r9.xyz
  float3 hoverColor = i.color.w > 0.5 ? dysonEditorColor : float3(1.05, 1.05, 1.05); //r5.xzw

  emission = state > 0.5 ? hoverColor : emission;
  emission = state > 1.5 ? selectColor : emission;
  emission = state > 2.5 ? hoverSelectColor : emission; //r3.yzw
  emission = state > 3.5 ? deleteColor : emission; //r6.xyz

  colorControl = state > 0.5 || isPlanned > 0.5 ? 1.0 / _EmissionMultiplier : colorControl;

  metallic = saturate(metallic * 0.85 + 0.149); //r0.w

  float perceptualRoughness = min(1.0, 1.0 - smoothness * 0.97); //r1.w

  float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz); //r4.xyz
  float3 lightDir = -i.normal.xyz;
  float3 halfDir = normalize(viewDir + lightDir); //r1.xyz

  float roughness = perceptualRoughness * perceptualRoughness; //r0.z

  float3 sunToCamDir = normalize(_WorldSpaceCameraPos.xyz - _Global_DS_SunPosition.xyz); //r2.xyw
  float innerSunReflectFalloff = pow(saturate(1.05 + dot(sunToCamDir, i.normal.xyz)), 0.4); //r2.x
  innerSunReflectFalloff = renderPlace < 0.5 ? innerSunReflectFalloff : 1.0; //r2.x

  float unclamped_NdotL = dot(worldNormal.xyz, lightDir); //r2.y
  float NdotL = max(0.0, unclamped_NdotL); //r2.w
  float NdotH = max(0.0, dot(worldNormal, halfDir)); //r4.w
  float NdotV = dot(worldNormal.xyz, viewDir.xyz); //r3.z
  NdotV = viewingOutwardFacingSide  ? NdotV : -NdotV; //r3.z
  float VdotH = max(0.0, dot(viewDir, halfDir); //r1.x

  float specularTerm = GGX(roughness, metallic + 0.5, NdotH, NdotV, NdotL, VdotH);

  float lightFalloff = saturate(pow(unclamped_NdotL * 0.6 + 1.0, 3.0));
  float3 diffuseLight = lightFalloff * (lightFalloff * 1.5 + 1.0) * float3(0.07, 0.07, 0.07) * _SunColor.xyz;

  float3 specularLight = (metallic * (metallic - 1.0) + 1.0) * specularStrength * (float3(1.5625,1.5625,1.5625) * _SunColor.xyz);
  specularLight = specularLight * (specularTerm + INV_TEN_PI) * NdotL * ((1.0 - metallic) * innerTex_Luminance * 0.2 + metallic);

  float3 finalLight = diffuseLight * innerTex_Luminance * (1.0 - metallic * 0.6)
        + pow(1.0 - metallic, 0.6) * float3(1.5625,1.5625,1.5625) * _SunColor.xyz * NdotL * innerTex_Luminance
        + float3(5,5,5) * lerp(float3(1,1,1), _SunColor.xyz, float3(0.3, 0.3, 0.3)) * specularLight;
  finalLight = finalLight * innerSunReflectFalloff;

  float luminance = dot(finalLight, float3(0.3,0.6, 0.1));
  if (luminance > 0.32) {
      float megaLog = log(log(log(log(log(log(log(log(luminance / 0.32) + 1) + 1) + 1) + 1) + 1) + 1) + 1) + 1;
      finalLight = (finalLight / luminance) * (0.32 * megaLog)
  }

  float finalAlpha = _EmissionMultiplier * colorControl;

  o.sv_target.xyz = emission + finalLight;
  o.sv_target.w = finalAlpha;

    return o;
  }

      ENDCG
    }
  }
}