#include "UnityCG.cginc"

float3 HexPointWorldPos (float3 objPos, bool inGame)
{
    float3 worldPos = mul(unity_ObjectToWorld, float4(objPos, 1.0)).xyz;
    float3 rayCamToHexPoint = worldPos - _WorldSpaceCameraPos;
    rayCamToHexPoint = length(rayCamToHexPoint) > 10000 ? rayCamToHexPoint * ((10000 * (log(0.0001 * length(rayCamToHexPoint)) + 1)) / length(rayCamToHexPoint)) : rayCamToHexPoint;
    float3 adjustedWorldHexPointPos = _WorldSpaceCameraPos + rayCamToHexPoint;
    worldPos = inGame ? adjustedWorldHexPointPos : worldPos;
    return worldPos;
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

struct v2g
{
    float4 vertex : POSITION;
    float2 uv : TEXCOORD0;
    //x [0, #ofNodes) node index
    //y [0, 1] vert# / total#verts
    float2 uv2 : TEXCOORD1; //u1.x is unused?
    //x [0 or 1] (!s_outvmap.ContainsKey(item.Key)) ? 1 : 0)
    //y [0, #ofSegments) polygon index - which edge it is closest to?
    float2 uv3 : TEXCOORD2; //axial coordinates on a grid of hexagons
};

struct g2f
{
    float4 vertex : SV_POSITION;
    float4 uv_axialCoords : TEXCOORD0;
    float3 objectPos : TEXCOORD1;
    float3 worldPos : TEXCOORD2;
    float3 tangent : TEXCOORD3;
    float3 binormal : TEXCOORD4;
    float3 normal : TEXCOORD5;
    float4 screenPos : TEXCOORD6;
    float2 polyGroup_pctComplete : TEXCOORD7;
    float4 color : TEXCOORD8;
};

struct fout
{
    float4 sv_target : SV_Target0;
};

v2g vert(appdata_full v)
{
    v2g o;

    o.vertex.xyzw = v.vertex.xyzw;
    o.uv.xy = v.texcoord.xy;
    o.uv2.xy = v.texcoord1.xy;
    o.uv3.xy = v.texcoord2.xy;

    return o;
}

  [maxvertexcount(12)]
  void geom(point v2g input[1], inout TriangleStream<g2f> triStream)
  {
    g2f o;

      uint index = input[0].uv.x + 0.5;
      float scaleProgress = saturate(((1 + (0.28 / _Scale)) * _NodeProgressArr[index] - pow(input[0].uv.y, 1.25)) / (0.28 / _Scale));
      float renderPlace = asuint(_Global_DS_RenderPlace);

      if (renderPlace > 1.5 || scaleProgress > 0.0001) {    

        float hexSize = _Scale / 3.0;

        float3 worldHexCenterPos = mul(unity_ObjectToWorld, float4(input[0].vertex.xyz, 1.0)).xyz;

        float scaleGrid = min(1, 30 * saturate((length(worldHexCenterPos) / (18.0 * _GridSize)) - 0.5)) * 0.07 + 1;
        scaleGrid = saturate(length(worldHexCenterPos) / (1.5 * _GridSize)) * min(1, scaleGrid - min(0.1, 0.2 / _Scale));
        float distFromCenter = dot(normalize(_Center.xyz), normalize(input[0].vertex.xyz));
        distFromCenter = renderPlace > 1.5 ? distFromCenter : distFromCenter * scaleGrid;
        
        float viewDistFalloff = 1 - min(4, max(0, 0.0001 * (length(_WorldSpaceCameraPos - input[0].vertex.xyz) - 3000))) * 0.25;
        float scaledCellSize = distFromCenter * lerp(1, _CellSize, viewDistFalloff);

        float3 t0TopPos = normalize(input[0].vertex.xyz + _t0Axis.xyz * scaledCellSize) * _Radius;
        float3 t1TopPos = normalize(input[0].vertex.xyz + _t1Axis.xyz * scaledCellSize) * _Radius;
        float3 t2TopPos = normalize(input[0].vertex.xyz + _t2Axis.xyz * scaledCellSize) * _Radius;
        float3 t0BtmPos = normalize(input[0].vertex.xyz - _t0Axis.xyz * scaledCellSize) * _Radius;
        float3 t1BtmPos = normalize(input[0].vertex.xyz - _t1Axis.xyz * scaledCellSize) * _Radius;
        float3 t2BtmPos = normalize(input[0].vertex.xyz - _t2Axis.xyz * scaledCellSize) * _Radius;
        
        float3 hexCenter = renderPlace < 0.5 ? input[0].vertex.xyz : input[0].vertex.xyz * 0.00025;
        t0TopPos = renderPlace < 0.5 ? t0TopPos : t0TopPos * 0.00025;
        t1TopPos = renderPlace < 0.5 ? t1TopPos : t1TopPos * 0.00025;
        t2TopPos = renderPlace < 0.5 ? t2TopPos : t2TopPos * 0.00025;
        t0BtmPos = renderPlace < 0.5 ? t0BtmPos : t0BtmPos * 0.00025;
        t1BtmPos = renderPlace < 0.5 ? t1BtmPos : t1BtmPos * 0.00025;
        t2BtmPos = renderPlace < 0.5 ? t2BtmPos : t2BtmPos * 0.00025;
        
        float3 worldTangent = UnityObjectToWorldDir(t1BtmPos - t1TopPos);
        float3 worldBinormal = UnityObjectToWorldDir(t0TopPos - t0BtmPos);
        float3 worldNormal = UnityObjectToWorldDir(input[0].vertex.xyz);

        float4 gamma_color = ((asuint(_Color32Int) >> int4(0,8,16,24)) & int4(255,255,255,255)) / 255.0;
        float4 linear_color = pow((float4(0.055, 0.055, 0.055, 0.055) + gamma_color) / float4(1.05, 1.05, 1.05, 1.05), 2.4);

        float3 worldHexPointPos_t0top = HexPointWorldPos(t0TopPos, renderPlace < 0.5);
        float4 clipPos_t0top = UnityWorldToClipPos(worldHexPointPos_t0top);
        float4 screenPos_t0top = ComputeScreenPos(clipPos_t0top);

        o.vertex.xyzw = clipPos_t0top;
        o.uv_axialCoords.xy = float2(0, hexSize);
        o.uv_axialCoords.zw = input[0].uv3.xy;
        o.objectPos.xyz = t0TopPos;
        o.worldPos.xyz = worldHexPointPos_t0top;
        o.tangent.xyz = worldTangent;
        o.binormal.xyz = worldBinormal;
        o.normal.xyz = worldNormal;
        o.screenPos.xyzw = screenPos_t0top;
        o.polyGroup_pctComplete.x = input[0].uv2.y;
        o.polyGroup_pctComplete.y = scaleProgress;
        o.color.xyzw = linear_color;
        triStream.Append(o);


        float3 worldHexPointPos_hexcenter = HexPointWorldPos(hexCenter, renderPlace < 0.5);
        float4 clipPos_hexcenter = UnityWorldToClipPos(worldHexPointPos_hexcenter);
        float4 screenPos_hexcenter = ComputeScreenPos(clipPos_hexcenter);

        o.vertex.xyzw = clipPos_hexcenter;
        o.uv_axialCoords.xy = float2(0, 0);
        o.uv_axialCoords.zw = input[0].uv3.xy;
        o.objectPos.xyz = hexCenter;
        o.worldPos.xyz = worldHexPointPos_hexcenter;
        o.tangent.xyz = worldTangent;
        o.binormal.xyz = worldBinormal;
        o.normal.xyz = worldNormal;
        o.screenPos.xyzw = screenPos_hexcenter.xyzw;
        o.polyGroup_pctComplete.x = input[0].uv2.y;
        o.polyGroup_pctComplete.y = scaleProgress;
        o.color.xyzw = linear_color;
        triStream.Append(o);


        float3 worldHexPointPos_t1top = HexPointWorldPos(t1TopPos, renderPlace < 0.5);
        float4 clipPos_t1top = UnityWorldToClipPos(worldHexPointPos_t1top);
        float4 screenPos_t1top = ComputeScreenPos(clipPos_t1top);

        o.vertex.xyzw = clipPos_t1top;
        o.uv_axialCoords.xy = float2(-hexSize, 0);
        o.uv_axialCoords.zw = input[0].uv3.xy;
        o.objectPos.xyz = t1TopPos;
        o.worldPos.xyz = worldHexPointPos_t1top;
        o.tangent.xyz = worldTangent;
        o.binormal.xyz = worldBinormal;
        o.normal.xyz = worldNormal;
        o.screenPos.xyzw = screenPos_t1top;
        o.polyGroup_pctComplete.x = input[0].uv2.y;
        o.polyGroup_pctComplete.y = scaleProgress;
        o.color.xyzw = linear_color;
        triStream.Append(o);


        float3 worldHexPointPos_t2btm = HexPointWorldPos(t2BtmPos, renderPlace < 0.5);
        float4 clipPos_t2btm = UnityWorldToClipPos(worldHexPointPos_t2btm);
        float4 screenPos_t2btm = ComputeScreenPos(clipPos_t2btm);

        o.vertex.xyzw = clipPos_t2btm; //r18
        o.uv_axialCoords.xy = float2(-hexSize, -hexSize); //r17.ww
        o.uv_axialCoords.zw = input[0].uv3.xy;
        o.objectPos.xyz = t2BtmPos;
        o.worldPos.xyz = worldHexPointPos_t2btm;
        o.tangent.xyz = worldTangent;
        o.binormal.xyz = worldBinormal;
        o.normal.xyz = worldNormal;
        o.screenPos.xyzw = screenPos_t2btm;
        o.polyGroup_pctComplete.x = input[0].uv2.y;
        o.polyGroup_pctComplete.y = scaleProgress;
        o.color.xyzw = linear_color;
        triStream.Append(o);

        triStream.RestartStrip();


        o.vertex.xyzw = clipPos_t2btm;
        o.uv_axialCoords.xy = float2(-hexSize, -hexSize);
        o.uv_axialCoords.zw = input[0].uv3.xy;
        o.objectPos.xyz = t2BtmPos;
        o.worldPos.xyz = worldHexPointPos_t2btm;
        o.tangent.xyz = worldTangent;
        o.binormal.xyz = worldBinormal;
        o.normal.xyz = worldNormal;
        o.screenPos.xyzw = screenPos_t2btm;
        o.polyGroup_pctComplete.x = input[0].uv2.y;
        o.polyGroup_pctComplete.y = scaleProgress;
        o.color.xyzw = linear_color;
        triStream.Append(o);


        o.vertex.xyzw = clipPos_hexcenter;
        o.uv_axialCoords.xy = float2(0, 0);
        o.uv_axialCoords.zw = input[0].uv3.xy;
        o.objectPos.xyz = hexCenter;
        o.worldPos.xyz = worldHexPointPos_hexcenter;
        o.tangent.xyz = worldTangent;
        o.binormal.xyz = worldBinormal;
        o.normal.xyz = worldNormal;
        o.screenPos.xyzw = screenPos_hexcenter;
        o.polyGroup_pctComplete.x = input[0].uv2.y;
        o.polyGroup_pctComplete.y = scaleProgress;
        o.color.xyzw = linear_color;
        triStream.Append(o);


        float3 worldHexPointPos_t0btm = HexPointWorldPos(t0BtmPos, renderPlace < 0.5);
        float4 clipPos_t0btm = UnityWorldToClipPos(worldHexPointPos_t0btm);
        float4 screenPos_t0btm = ComputeScreenPos(clipPos_t0btm);

        o.vertex.xyzw = clipPos_t0btm;
        o.uv_axialCoords.xy = float2(0, -hexSize); //
        o.uv_axialCoords.zw = input[0].uv3.xy;
        o.objectPos.xyz = t0BtmPos;
        o.worldPos.xyz = worldHexPointPos_t0btm;
        o.tangent.xyz = worldTangent;
        o.binormal.xyz = worldBinormal;
        o.normal.xyz = worldNormal;
        o.screenPos.xyzw = screenPos_t0btm;
        o.polyGroup_pctComplete.x = input[0].uv2.y;
        o.polyGroup_pctComplete.y = scaleProgress;
        o.color.xyzw = linear_color;
        triStream.Append(o);


        float3 worldHexPointPos_t1btm = HexPointWorldPos(t1BtmPos, renderPlace < 0.5);
        float4 clipPos_t1btm = UnityWorldToClipPos(worldHexPointPos_t1btm);
        float4 screenPos_t1btm = ComputeScreenPos(clipPos_t1btm);

        o.vertex.xyzw = clipPos_t1btm;
        o.uv_axialCoords.xy = float2(hexSize, 0); //
        o.uv_axialCoords.zw = input[0].uv3.xy;
        o.objectPos.xyz = t1BtmPos;
        o.worldPos.xyz = worldHexPointPos_t1btm;
        o.tangent.xyz = worldTangent;
        o.binormal.xyz = worldBinormal;
        o.normal.xyz = worldNormal;
        o.screenPos.xyzw = screenPos_t1btm;
        o.polyGroup_pctComplete.x = input[0].uv2.y;
        o.polyGroup_pctComplete.y = scaleProgress;
        o.color.xyzw = linear_color;
        triStream.Append(o);

        triStream.RestartStrip();


        o.vertex.xyzw = clipPos_t1btm;
        o.uv_axialCoords.xy = float2(hexSize, 0); //
        o.uv_axialCoords.zw = input[0].uv3.xy;
        o.objectPos.xyz = t1BtmPos;
        o.worldPos.xyz = worldHexPointPos_t1btm;
        o.tangent.xyz = worldTangent;
        o.binormal.xyz = worldBinormal;
        o.normal.xyz = worldNormal;
        o.screenPos.xyzw = screenPos_t1btm;
        o.polyGroup_pctComplete.x = input[0].uv2.y;
        o.polyGroup_pctComplete.y = scaleProgress;
        o.color.xyzw = linear_color;
        triStream.Append(o);


        o.vertex.xyzw = clipPos_hexcenter;
        o.uv_axialCoords.xy = float2(0, 0);
        o.uv_axialCoords.zw = input[0].uv3.xy;
        o.objectPos.xyz = hexCenter;
        o.worldPos.xyz = worldHexPointPos_hexcenter;
        o.tangent.xyz = worldTangent;
        o.binormal.xyz = worldBinormal;
        o.normal.xyz = worldNormal;
        o.screenPos.xyzw = screenPos_hexcenter;
        o.polyGroup_pctComplete.x = input[0].uv2.y;
        o.polyGroup_pctComplete.y = scaleProgress;
        o.color.xyzw = linear_color;
        triStream.Append(o);


        float3 worldHexPointPos_t2top = HexPointWorldPos(t2TopPos, renderPlace < 0.5);
        float4 clipPos_t2top = UnityWorldToClipPos(worldHexPointPos_t2top);
        float4 screenPos_t2top = ComputeScreenPos(clipPos_t2top);

        o.vertex.xyzw = clipPos_t2top;
        o.uv_axialCoords.xy = float2(hexSize, hexSize);
        o.uv_axialCoords.zw = input[0].uv3.xy;
        o.objectPos.xyz = t2TopPos;
        o.worldPos.xyz = worldHexPointPos_t2top;
        o.tangent.xyz = worldTangent;
        o.binormal.xyz = worldBinormal;
        o.normal.xyz = worldNormal;
        o.screenPos.xyzw = screenPos_t2top;
        o.polyGroup_pctComplete.x = input[0].uv2.y;
        o.polyGroup_pctComplete.y = scaleProgress;
        o.color.xyzw = linear_color;
        triStream.Append(o);


        o.vertex.xyzw = clipPos_t0top;
        o.uv_axialCoords.xy = float2(0, hexSize);
        o.uv_axialCoords.zw = input[0].uv3.xy;
        o.objectPos.xyz = t0TopPos;
        o.worldPos.xyz = worldHexPointPos_t0top;
        o.tangent.xyz = worldTangent;
        o.binormal.xyz = worldBinormal;
        o.normal.xyz = worldNormal;
        o.screenPos.xyzw = screenPos_t0top;
        o.polyGroup_pctComplete.x = input[0].uv2.y;
        o.polyGroup_pctComplete.y = scaleProgress;
        o.color.xyzw = linear_color;
        triStream.Append(o);
      }
    return;
  }

  fout frag(g2f i)
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

    /* remove pixels that fall outside the bounds of the frame that surrounds this shell */
    uint polyCount = (uint)(0.5 + _PolyCount) < 1 ? 1 : min(380, (uint)(0.5 + _PolyCount));
    int polygonGroup = (int)((uint)(0.5 + i.polyGroup_pctComplete.x));
    int polygonIndex = (int)polyCount + (int)(0.5 + polygonGroup);

    
    float3 prevLineNormal = _PolygonNArr[polygonIndex - 1].xyz;
    float3 thisLineDir = _PolygonArr[polygonIndex + 1].xyz - _PolygonArr[polygonIndex].xyz;
    //float prevLineIsConvex = sign(dot(thisLineDir, prevLineNormal)) * _Clockwise;
    float3 prevLineToPoint = i.objectPos.xyz - _PolygonArr[polygonIndex - 1].xyz;
    //float prevLineInside = sign(dot(prevLineToPoint, prevLineNormal)) * _Clockwise;

    float3 thisLineNormal = _PolygonNArr[polygonIndex].xyz;
    float3 nextLineDir = _PolygonArr[polygonIndex + 2].xyz - _PolygonArr[polygonIndex + 1].xyz;
    //float nextLineIsConvex = sign(dot(nextLineDir, thisLineNormal)) * _Clockwise;
    float3 nextLineToPoint = i.objectPos.xyz - _PolygonArr[polygonIndex + 1].xyz;
    //float thisLineInside = sign(dot(nextLineToPoint, thisLineNormal)) * _Clockwise;

    float3 nextLineNormal = _PolygonNArr[polygonIndex + 1].xyz;
    float3 nextnextLineToPoint = i.objectPos.xyz - _PolygonArr[polygonIndex + 2].xyz;
    //float nextLineInside = sign(dot(nextnextLineToPoint, nextLineNormal)) * _Clockwise;

    //float insideBounds = isInside(nextLineIsConvex, prevLineIsConvex, nextLineInside, thisLineInside, prevLineInside);

    float prevLineIsConcave = dot(thisLineDir, prevLineNormal);
    float nextLineIsConcave = dot(nextLineDir, thisLineNormal);
    // <0 means convex
    // >0 means concave
    // 0 means parallel
    int prevLineIsConvex = prevLineIsConcave > 0 ? 1 : prevLineIsConcave < 0 ? -1 : 0;
    int nextLineIsConvex = nextLineIsConcave > 0 ? 1 : nextLineIsConcave < 0 ? -1 : 0;
    //set to int, flip sign. 1=convex, -1=concave

    float prevLineInside = dot(prevLineToPoint, prevLineNormal);
    float thisLineInside = dot(nextLineToPoint, thisLineNormal);
    float nextLineInside = dot(nextnextLineToPoint, nextLineNormal);
    // inside if >0, outside if <0

    // flip sign if counterclockwise (_Clockwise = -1)

    float insideBounds = -1;
    if (nextLineIsConvex > 0 && prevLineIsConvex > 0) {
      if (nextLineInside > 0 && thisLineInside > 0 && prevLineInside > 0) {
        insideBounds = 1;
      } else {
        insideBounds = -1;
      }
    } else {
      if (nextLineIsConvex > 0 && prevLineIsConvex <= 0) {
        insideBounds = nextLineInside > 0 && (prevLineInside > 0 || thisLineInside > 0) ? 1 : -1;
      } else {
        if (nextLineIsConvex <= 0 && prevLineIsConvex > 0) {
          insideBounds = prevLineInside > 0 && (thisLineInside > 0 || nextLineInside > 0) ? 1 : -1;      
        } else {
          insideBounds = (nextLineInside > 0 || prevLineInside > 0 || thisLineInside > 0) ? 1 : -1;
        }
      }
    }

    if (insideBounds < 0) discard;
    /* end shell/frame bounds check */


    float distancePosToCamera = length(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
    
    float2 axialCoords = i.uv_axialCoords.zw;
    float4 cubeCoords = _Scale * float4(0.666666687,0.333333343,-0.333333343,0.333333343) * axialCoords.xxyy;
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

    float cutOut = 0;
    if (i.polyGroup_pctComplete.y - random_num * 0.999 < 0.00005) {
      UNITY_BRANCH
      if (renderPlace > 1.5) {
        float2 pixelPos = (_ScreenParams.xy * (i.screenPos.xy / i.screenPos.ww));
        pixelPos = (int2)pixelPos;
        cutOut = (((uint)pixelPos.x << 2) & 12) | ((uint)0 & ~12);
        cutOut = (((uint)pixelPos.y << 0) & 3) | ((uint)cutOut & ~3);
        if(any((uint)cutOut == uint4(4,6,12,14))) discard;
        //clip(0.2499 - icb[cutOut].x * 0.0588);

        cutOut = 1;
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
    
    float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
    float3 emissionTex_A = tex2Dbias(_EmissionTex, float4(uv.xy, 0, lodBias)).xyz;
    float3 emissionTex_B = tex2Dbias(_EmissionTex, float4(float2(1,1) - uv.yx, 0, lodBias)).xyz;
    float3 emissionTex = lerp(emissionTex_A.xyz, emissionTex_B.xyz, sin(_Time.y + _Time.y) * 0.5 + 0.5);
    float3 emissionTexTwo = tex2Dbias(_EmissionTex2, float4(scaledUV.xy, 0, lodBias)).xyz;
    bool viewingSunFacingSide = dot(i.normal.xyz, viewDir.xyz) < 0;
    emissionAnim = viewingSunFacingSide ? saturate((emissionTexTwo.y * 2 + emissionTex.y) * emissionAnim) : 0;

    float colorControlTex_A = tex2Dbias(_ColorControlTex, float4(uv.xy, 0, lodBias)).x;
    float colorControlTex_B = tex2Dbias(_ColorControlTex, float4(float2(1,1) - uv.yx, 0, lodBias)).x;
    float colorControlTex = lerp(colorControlTex_A, colorControlTex_B, sin(_Time.y + _Time.y) * 0.5 + 0.5);
    float colorControlTexTwo = tex2Dbias(_ColorControlTex2, float4(scaledUV.xy, 0, lodBias)).x;
    float colorControl = saturate(colorControlTex + colorControlTexTwo);
    
    float3 colorOutwardFacing = lerp(colorControl * i.color.xyz, i.color.xyz, 0.01 / _EmissionMultiplier);
    float3 emissionOutwardFacing = lerp(emissionTexTwo.xyz * float3(0.3, 0.3, 0.3) + emissionTex.xyz, colorOutwardFacing, i.color.w);
    float3 dysonEmission = viewingSunFacingSide ? _DysonEmission.xyz : float3(1,1,1);
    float3 emissionSunFacing = float3(3,3,3) * (emissionTexTwo.x + emissionTex.x) * dysonEmission.xyz;
    float3 emission = viewingSunFacingSide ? emissionSunFacing.xyz : emissionOutwardFacing.xyz;

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
      float3 shellEmissionColor = lerp(emission.xyz * 2.2, shellColor, 0.8 * cutOut);
      specularStrength       = _State > 0.5 ? 0   : 0.8 * specularStrength * (1.0 - cutOut);
      fadeOut                = _State > 0.5 ? 0   : 0.03                   * (1.0 - cutOut);
      float metallic         = _State > 0.5 ? 0   : msTex.x                * (1.0 - scaleMetallic);
      float smoothness       = _State > 0.5 ? 0.5 : min(0.8, msTex.y);

      finalColor.xyz = i.color.w > 0.5 ? i.color.xyz * (viewingSunFacingSide ? 2 : 1.5) :
                       _State > 3.5 ? float3(2.59, 0.0525, 0.0875) :
                       _State > 2.5 ? float3(0.525,0.875, 3.5)     :
                       _State > 1.5 ? float3(0.35, 0.7, 3.5)       :
                       _State > 0.5 ? float3(1.05, 1.05, 1.05)     :
                       shellEmissionColor;
      float emissionFactor = _State > 0.5 || cutOut > 0.5 ? 1.0 : colorControl;
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

    float NdotV = viewingSunFacingSide ? -dot(worldNormal.xyz, viewDir.xyz) : dot(worldNormal.xyz, viewDir.xyz);
    worldNormal.xyz = viewingSunFacingSide ? -worldNormal.xyz : worldNormal.xyz;

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