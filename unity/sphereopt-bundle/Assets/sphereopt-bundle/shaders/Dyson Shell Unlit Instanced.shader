Shader "VF Shaders/Dyson Sphere/Dyson Shell Unlit Instanced" {
  Properties {
    _Color ("Color", Vector) = (1,1,1,1)
    _MainTex ("Albedo (RGB)", 2D) = "white" {}
    _NormalTex ("Normal Map", 2D) = "bump" {}
    _MSTex ("Metallic Smoothness (RA)", 2D) = "white" {}
    _EmissionTex ("Emission (RGB)", 2D) = "black" {}
    _EmissionTex2 ("Emission Large (RGB)", 2D) = "black" {}
    _NoiseTex ("Noise Texture (R)", 2D) = "gray" {}
    _ColorControlTex ("Color Control", 2D) = "black" {}
    _ColorControlTex2 ("Color Control Large", 2D) = "black" {}
    _AlbedoMultiplier ("漫反射倍率", Float) = 1
    _NormalMultiplier ("法线倍率", Float) = 1
    _EmissionMultiplier ("自发光倍率", Float) = 5.5
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
      GpuProgramID 41389
      CGPROGRAM
      #pragma vertex vert
      #pragma fragment frag
      #pragma target 5.0
      #pragma enable_d3d11_debug_symbols

    struct PolygonData
    {
        float3 pos;
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
      float _EmissionMultiplier;
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
      sampler2D _EmissionTex2;
      sampler2D _ColorControlTex;
      sampler2D _ColorControlTex2;

      #include "UnityCG.cginc"

float3 rotate_vector_fast(float3 v, float4 r){ 
    return v + cross(2.0 * r.xyz, cross(r.xyz, v) + r.w * v);
}

int isInside(int nextLineIsConvex, int prevLineIsConvex, int nextLineInside, int thisLineInside, int prevLineInside)
{
    bool nextConvex = nextLineIsConvex > 0;
    bool prevConvex = prevLineIsConvex > 0;

    bool nextInside = nextLineInside > 0;
    bool thisInside = thisLineInside > 0;
    bool prevInside = prevLineInside > 0;

    return nextConvex && prevConvex && nextInside && thisInside && prevInside ? 1 : 
                    nextConvex && !prevConvex && nextInside && (prevInside || thisInside) ? 1 :
                    !nextConvex && prevConvex && prevInside && (thisInside || nextInside) ? 1 :
                    !nextConvex && !prevConvex && (nextInside || prevInside || thisInside) ? 1 :
                    -1;
}

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
    float2 state_clock : TEXCOORD7;
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
    float cellSize = _CellSize;
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

    o.state_clock.x = state;
    o.state_clock.y = 1;

    o.color.xyzw = linear_color; //move to frag?

    return o;
}

  fout frag(v2f i, bool viewingOutwardFacingSide : SV_IsFrontFace, float4 screenPos : SV_POSITION)
  {

    fout o;

    uint renderPlace = asuint(_Global_DS_RenderPlace);

    UNITY_BRANCH
    if (renderPlace > 1.5) {
      if((asint(_Global_DS_PaintingLayerId) != asint(_LayerId) || asuint(_Global_DS_PaintingGridMode) > 0.5) && asuint(_Global_DS_PaintingLayerId) > 0) discard;
      bool isFarSide = dot(_WorldSpaceCameraPos.xyz - i.worldPos.xyz, _Global_DS_SunPosition_Map.xyz - i.worldPos.xyz) > 0;
      bool hideFarSideEnabled = asuint(_Global_DS_HideFarSide) > 0.5;
      if (hideFarSideEnabled && isFarSide) discard;
    }

    float state = i.state_clock.x;

    uint polyCount = 0.5 + polyCount; //28 //r0.z
    polyCount = polyCount < 1 ? 1 : min(380, polyCount);
    uint closestPolygon = 0.5 + closestPolygon; //r0.w
    int polyIndex = polyCount + closestPolygon; //r0.z
    int prevIndex = polyIndex - 1; //r2.x
    int nextIndex = polyIndex + 1; //r2.y
    int nextnextIndex = polyIndex + 2; //r2.z
    
    float3 prevVert = polygonArr[prevIndex].xyz;
    float3 thisVert = polygonArr[polyIndex].xyz;
    float3 nextVert = polygonArr[nextIndex].xyz;
    float3 nextnextVert = polygonArr[nextnextIndex].xyz;
    
    float3 prevNormal = polygonN[prevIndex].xyz;
    float3 thisNormal = polygonN[polyIndex].xyz;
    float3 nextNormal = polygonN[nextIndex].xyz;
    
    float3 thisToNext = nextVert - thisVert; //r3.xyz
    int signThisToNext_Dot_PrevN = sign(dot(thisToNext, prevNormal)); //r0.w
    
    float3 prevToPoint = i.objectPos.xyz - prevVert; //r3.xyz
    float prevToPoint_Dot_PrevN = dot(prevToPoint, prevNormal); //r1.w
    
    float3 nextToPoint = i.objectPos.xyz.xyz - nextVert; //r3.xyz
    float nextToPoint_Dot_ThisN = dot(nextToPoint.xyz, thisNormal); //r2.x
    
    float3 nextToNextnext = nextnextVert - nextVert; //r3.xyz
    int signNextToNextnext_Dot_ThisN = sign(dot(nextToNextnext.xyz, thisNormal)); //r0.z
    
    float3 nextnextToPoint = i.objectPos.xyz.xyz - nextnextVert; //r3.xyz
    float nextnextToPoint_Dot_NextN = dot(nextnextToPoint.xyz, nextNormal); //r2.y
    
    signNextToNextnext_Dot_ThisN = _Clockwise * signNextToNextnext_Dot_ThisN; //r0.z
    signThisToNext_Dot_PrevN = _Clockwise * signThisToNext_Dot_PrevN; //r0.w
    
    prevToPoint_Dot_PrevN = _Clockwise * prevToPoint_Dot_PrevN; //r1.w
    nextToPoint_Dot_ThisN = _Clockwise * nextToPoint_Dot_ThisN; //r2.x
    nextnextToPoint_Dot_NextN = _Clockwise * nextnextToPoint_Dot_NextN; //r2.y
    
    float shouldDiscard = -1; //r3.x
    if (signNextToNextnext_Dot_ThisN > 0 && signThisToNext_Dot_PrevN > 0) {
      shouldDiscard = nextnextToPoint_Dot_NextN > 0 && nextToPoint_Dot_ThisN > 0 && prevToPoint_Dot_PrevN > 0 ? 1 : -1;
    } else {
      
      float cond1 = (prevToPoint_Dot_PrevN > 0 || nextToPoint_Dot_ThisN > 0) && nextnextToPoint_Dot_NextN > 0 ? 1 : -1; //r3.y
      float cond2 = prevToPoint_Dot_PrevN > 0 && (nextToPoint_Dot_ThisN > 0 || nextnextToPoint_Dot_NextN > 0) ? 1 : -1; //r1.w
      float cond3 = (prevToPoint_Dot_PrevN > 0 || nextToPoint_Dot_ThisN > 0) && nextnextToPoint_Dot_NextN > 0 ? 1 : -1; //r2.x
      
      float cond4 = signNextToNextnext_Dot_ThisN <= 0 && signThisToNext_Dot_PrevN > 0 ? cond2 : cond3;
      shouldDiscard = signNextToNextnext_Dot_ThisN > 0 && signThisToNext_Dot_PrevN <= 0 ? cond1 : cond4;
    }
    
    if (shouldDiscard < 0)
      discard;

    float distancePosToCamera = length(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
    
    float2 axialCoords = i.uv_axialCoords.zw;
    float4 cubeCoords = _Scale * float4(0.66666666,0.333333333,-0.333333333,0.333333333) * axialCoords.xxyy;
    cubeCoords.xy = cubeCoords.yx + cubeCoords.wz;

    float gridFalloff = 0.99 - saturate((distancePosToCamera / _GridSize) / 15.0 - 0.2) * 0.03;

    float2 uv = i.uv_axialCoords.xy;
    float2 adjustPoint = uv.yx * gridFalloff + cubeCoords.xy;
    adjustPoint.xy = adjustPoint.yx * float2(2,2) - adjustPoint.xy;
    float adjustPoint_z = -adjustPoint.x - adjustPoint.y;
    float2 roundedAdjustPoint = round(adjustPoint.xy);
    float roundedAdjustPoint_z = round(adjustPoint_z);
    float2 roundedPointDiff = -roundedAdjustPoint.yx - round(adjustPoint_z);
    adjustPoint.xy = roundedAdjustPoint.xy < adjustPoint.xy ? adjustPoint.xy - roundedAdjustPoint.xy : roundedAdjustPoint.xy - adjustPoint.xy;
    adjustPoint_z = roundedAdjustPoint_z < adjustPoint_z ? adjustPoint_z - roundedAdjustPoint_z : roundedAdjustPoint_z - adjustPoint_z;
    adjustPoint.xy = adjustPoint_z < adjustPoint.xy ? adjustPoint.yx < adjustPoint.xy : 0;

    float alternatePointY = adjustPoint.y ? roundedPointDiff.y : roundedAdjustPoint.y;
    float2 correctedCoords = roundedAdjustPoint.x + roundedAdjustPoint.y + roundedAdjustPoint_z != 0.000000 ? (adjustPoint.xx ? float2(roundedPointDiff.x, roundedAdjustPoint.y) : float2(roundedAdjustPoint.x, alternatePointY)) : roundedAdjustPoint.xy;

    float2 randomSampleCoords = float2(0.001953125,0.001953125) * correctedCoords.xy;
    float random_num = tex2Dlod(_NoiseTex, float4(randomSampleCoords.xy, 0, 0)).x;

    float isPlanned = 0;
    if (i.pidx_close_pct_cnt.z - random_num * 0.999 < 0.00005) {
        UNITY_BRANCH
        if (renderPlace > 1.5) {
          uint2 pixelPos = screenPos.xy;
          int mask = (pixelPos.x & 1) - (pixelPos.y & 1);
          if (mask != 0) discard;
          isPlanned = 1;
        } else {
          discard;
        }
    }

    float2 scaledUV = uv.xy / _Scale;
    scaledUV.xy = scaledUV.xy + axialCoords.xx / 3.0 + float2(axialCoords.x - axialCoords.y, axialCoords.y) / 3.0;

    float lodBias = min(4, max(0, log(0.0001 * distancePosToCamera)));
   
    float3 triPosNew = 1.0 - abs(frac(0.5 * (float3(0.6666666, 0.0, 1.6666666) + scaledUV.xyx)) * 2.0 - 1.0);

    float2 newPosOne;
    newPosOne.x = ((triPosNew.x + triPosNew.y) / sqrt(2)) / sqrt(3);
    newPosOne.y =  (triPosNew.y - triPosNew.x) / sqrt(2);

    float2 newPosTwo;
    newPosTwo.x = ((triPosNew.z + triPosNew.y) / sqrt(2)) / sqrt(3);
    newPosTwo.y =  (triPosNew.y - triPosNew.z) / sqrt(2);

    float emissionAnim = saturate(30.0 * (0.05 - abs(length(newPosOne.xy) - frac(2.9 * _Time.x)))) * min(1, 5 * (1 - frac(2.9 * _Time.x)))
         + saturate(30.0 * (0.05 - abs(length(newPosTwo.xy) - frac(_Time.x * 3.7 + 0.5)))) * min(1, 5 * (1 - frac(_Time.x * 3.7 + 0.5)));
    
    
    float3 emissionTex_A = tex2Dbias(_EmissionTex, float4(uv.xy, 0, lodBias)).xyz;
    float3 emissionTex_B = tex2Dbias(_EmissionTex, float4(float2(1,1) - uv.yx, 0, lodBias)).xyz;
    float3 emissionTex = lerp(emissionTex_A.xyz, emissionTex_B.xyz, sin(_Time.y + _Time.y) * 0.5 + 0.5);
    float3 emissionTexTwo = tex2Dbias(_EmissionTex2, float4(scaledUV.xy, 0, lodBias)).xyz;
    //bool viewingSunFacingSide = dot(i.normal.xyz, viewDir.xyz) < 0;
    emissionAnim = viewingOutwardFacingSide ? 0 : saturate((emissionTexTwo.y * 2 + emissionTex.y) * emissionAnim);

    float colorControlTex_A = tex2Dbias(_ColorControlTex, float4(uv.xy, 0, lodBias)).x;
    float colorControlTex_B = tex2Dbias(_ColorControlTex, float4(float2(1,1) - uv.yx, 0, lodBias)).x;
    float colorControlTex = lerp(colorControlTex_A, colorControlTex_B, sin(_Time.y + _Time.y) * 0.5 + 0.5);
    float colorControlTexTwo = tex2Dbias(_ColorControlTex2, float4(scaledUV.xy, 0, lodBias)).x;
    float colorControl = saturate(colorControlTex + colorControlTexTwo);
    
    float3 colorOutwardFacing = lerp(colorControl * i.color.xyz, i.color.xyz, 0.01 / _EmissionMultiplier);
    float3 emissionOutwardFacing = lerp(emissionTexTwo.xyz * float3(0.3, 0.3, 0.3) + emissionTex.xyz, colorOutwardFacing, i.color.w);
    float3 dysonEmission = viewingOutwardFacingSide ? float3(1,1,1) : _DysonEmission.xyz;
    float3 emissionSunFacing = float3(3,3,3) * (emissionTexTwo.x + emissionTex.x) * dysonEmission.xyz;
    float3 emission = viewingOutwardFacingSide ? emissionOutwardFacing.xyz : emissionSunFacing.xyz;

    emission = _EmissionMultiplier * lerp(emission.xyz, dysonEmission.xyz, emissionAnim);

    float scaledDistancePosToCamera = 0.5 < asuint(_Global_IsMenuDemo) ? distancePosToCamera : renderPlace > 0.5 ? 3999.9998 * distancePosToCamera : distancePosToCamera;
    float scaleMetallic = 0.5 < asuint(_Global_IsMenuDemo) ? 0.1 : renderPlace > 0.5 ? 0.93 : 0.7;
    scaleMetallic = saturate(pow(0.25 * log(scaledDistancePosToCamera + 1) - 1.5, 3.0)) * scaleMetallic;

    float4 albedoTex = tex2Dbias(_MainTex, float4(uv.xy, 0, lodBias)).xyzw;
    float3 albedo = _AlbedoMultiplier * albedoTex.xyz * lerp(float3(1,1,1), albedoTex.xyz, saturate(1.25 * (albedoTex.w - 0.1)));
    float specularStrength = dot(albedo, float3(0.3, 0.6, 0.1));
    float2 msTex = tex2D(_MSTex, uv.xy).xw;
    
    float metallicFactor, fadeOut, roughnessSqr, finalAlpha;
    float3 finalColor;
    if(renderPlace > 1.5) {
      float3 shellColor = i.color.w > 0.5 ? i.color.xyz : (asint(_Global_DS_PaintingLayerId) == asint(_LayerId) ? float3(0, 0.3, 0.65) : float3(0, 0.8, 0.6));
      float3 shellEmissionColor = lerp(emission.xyz * 2.2, shellColor, 0.8 * isPlanned);
      specularStrength       = state > 0.5 ? 0   : 0.8 * specularStrength * (1.0 - isPlanned);
      fadeOut                = state > 0.5 ? 0   : 0.03                   * (1.0 - isPlanned);
      float metallic         = state > 0.5 ? 0   : msTex.x                * (1.0 - scaleMetallic);
      float smoothness       = state > 0.5 ? 0.5 : min(0.8, msTex.y);

      finalColor.xyz = i.color.w > 0.5 ? i.color.xyz * (viewingOutwardFacingSide ? 1.5 : 2) :
                       state > 3.5 ? float3(2.59, 0.0525, 0.0875) :
                       state > 2.5 ? float3(0.525,0.875, 3.5)     :
                       state > 1.5 ? float3(0.35, 0.7, 3.5)       :
                       state > 0.5 ? float3(1.05, 1.05, 1.05)     :
                       shellEmissionColor;
      float emissionFactor = state > 0.5 || isPlanned > 0.5 ? 1.0 : colorControl;
      finalAlpha = _EmissionMultiplier * emissionFactor;
      metallicFactor = saturate(metallic * 0.85 + 0.149);
      float perceptualRoughness = min(1, 1 - smoothness * 0.97);
      roughnessSqr = pow(min(1, 1 - smoothness * 0.97), 4);
    }
    else {
      float multiplyEmission = renderPlace > 0.5 ? 1.8  : 2.5;
      specularStrength = 0.8 * specularStrength;
      fadeOut = 0.03;
      finalColor.xyz = emission.xyz * multiplyEmission;
      finalAlpha = _EmissionMultiplier * colorControl;
      metallicFactor = saturate(msTex.x * (0.85 - 0.85 * scaleMetallic) + 0.149);
      roughnessSqr = pow(1 - 0.97 * min(0.8, msTex.y), 4); //pow(min(1, 1 - min(0.8, msTex.y) * 0.97), 2);
    }

    float4 normalTex = tex2Dbias(_NormalTex, float4(uv.xy, 0, lodBias)).xyzw;
    float3 unpackedNormal = UnpackNormal(normalTex);
    unpackedNormal.xy = (-1.5 * _NormalMultiplier) * unpackedNormal.xy;
    float3 worldNormal = normalize(i.normal.xyz * unpackedNormal.z + i.tangent.xyz * unpackedNormal.x + i.binormal.xyz * unpackedNormal.y);

    float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
    float NdotV = viewingOutwardFacingSide ? dot(worldNormal.xyz, viewDir.xyz) : -dot(worldNormal.xyz, viewDir.xyz);
    worldNormal.xyz = viewingOutwardFacingSide ? worldNormal.xyz : -worldNormal.xyz;

    float3 lightDir = -i.normal.xyz;
    float3 halfDir = normalize(viewDir + lightDir.xyz);

    float NdotL = dot(worldNormal.xyz, lightDir.xyz);
    float NdotH = dot(worldNormal.xyz, halfDir.xyz);
    float VdotH = dot(viewDir, halfDir.xyz);
    float clamp_NdotL = max(0, NdotL);
    float clamp_NdotH = max(0, NdotH);
    float clamp_VdotH = max(0, VdotH);

    float D = 0.25 * pow(rcp(clamp_NdotH * clamp_NdotH * (roughnessSqr - 1) + 1),2) * roughnessSqr;

    float gv = lerp(pow(roughnessSqr + 1, 2) * 0.125, 1.0, NdotV);
    float gl = lerp(pow(roughnessSqr + 1, 2) * 0.125, 1.0, clamp_NdotL);
    float G = rcp(gv * gl);

    float fk = exp2((clamp_VdotH * -5.55472994 - 6.98316002) * clamp_VdotH);
    float F = lerp(0.5 + metallicFactor, 1.0, fk);

    float sunStrength = renderPlace < 0.5 ? pow(saturate(1.05 + dot(normalize(_WorldSpaceCameraPos.xyz - _Global_DS_SunPosition.xyz), i.normal.xyz)), 0.4) : 1.0;
    float3 sunColor = float3(1.5625,1.5625,1.5625) * _SunColor.xyz;
    float intensity = saturate(pow(NdotL * 0.6 + 1, 3));
    float3 sunColorIntensity = float3(0.07, 0.07, 0.07) * _SunColor * (intensity * 1.5 + 1) * intensity;
    float3 sunSpecular = sunColor.xyz * clamp_NdotL * specularStrength;

    float3 finalLight = lerp(1, specularStrength, metallicFactor) * fadeOut * sunColor.xyz * (F * D * G + (0.1 / UNITY_PI)) * clamp_NdotL;
    finalLight = finalLight.xyz * lerp(metallicFactor, 1, specularStrength * 0.2);

    finalLight = float3(5,5,5) * lerp(float3(1,1,1), _SunColor, float3(0.3,0.3,0.3)) * finalLight.xyz;
    finalLight = (sunColorIntensity.xyz * specularStrength * (1 - metallicFactor * 0.6) + sunSpecular.xyz * pow(1 - metallicFactor, 0.6) + finalLight.xyz) * sunStrength;

    float luminance = dot(finalLight, float3(0.3, 0.6, 0.1));
    float3 normalizedLight = finalLight / luminance;
    float megaLog = log(log(log(log(log(log(log(log(luminance / 0.32) + 1) + 1) + 1) + 1) + 1) + 1) + 1) + 1;
    finalLight = 0.32 < luminance ? normalizedLight * megaLog * 0.32 : finalLight;

    o.sv_target.xyzw = float4(finalColor,0) + float4(finalLight, finalAlpha);

    return o;
  }

      ENDCG
    }
  }
}