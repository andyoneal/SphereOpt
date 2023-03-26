#include "UnityCG.cginc"

inline float3 HexPointWorldPos (float3 objPos, bool inGameAndVMap)
{
    float3 worldPos = mul(unity_ObjectToWorld, float4(objPos, 1.0)).xyz;
    float3 rayCamToHexPoint = worldPos - _WorldSpaceCameraPos;
    rayCamToHexPoint = length(rayCamToHexPoint) > 10000 ? rayCamToHexPoint * ((10000 * (log(0.0001 * length(rayCamToHexPoint)) + 1)) / length(rayCamToHexPoint)) : rayCamToHexPoint;
    float3 adjustedWorldHexPointPos = _WorldSpaceCameraPos + rayCamToHexPoint;
    worldPos = inGameAndVMap ? adjustedWorldHexPointPos : worldPos;
    return worldPos;
}

struct v2f
{
    float4 vertex : SV_POSITION;
    float4 vertPos_axialCoords : TEXCOORD0;
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

v2f vert(appdata_full v)
{
    v2f o;

    uint index = v.texcoord.x + 0.5;
    float scaleProgress = 1.0; //saturate(((1 + (0.28 / _Scale)) * _NodeProgressArr[index] - pow(v.texcoord.y, 1.25)) / (0.28 / _Scale));
    float renderPlace = asuint(_Global_DS_RenderPlace);

    // TODO: 
    // float3 worldPos = mul(unity_ObjectToWorld, float4(vertPos, 1)).xyz;

    // float scaleGrid = min(1, 30 * saturate((length(worldPos) / (18.0 * _GridSize)) - 0.5)) * 0.07 + 1; //TODO: should be worldPos of center of hex
    // scaleGrid = saturate(length(worldPos) / (1.5 * _GridSize)) * min(1, scaleGrid - min(0.1, 0.2 / _Scale)); //TODO: should be worldPos of center of hex
    // float distFromCenter = dot(normalize(_Center.xyz), normalize(v.vertex.xyz)); //TODO: should be vertPos of center of hex
    // distFromCenter = renderPlace < 1.5 ? distFromCenter * scaleGrid : distFromCenter;
    // float viewDistFalloff = 1 - min(4, max(0, 0.0001 * (length(_WorldSpaceCameraPos - v.vertex.xyz) - 3000))) * 0.25;
    // float scaledCellSize = distFromCenter * lerp(1, _CellSize, viewDistFalloff);

    float3 vertPos = renderPlace > 0.5 ? v.vertex.xyz / 4000.0 : v.vertex.xyz;

    float inGame = renderPlace < 0.5;
    float vmapEnabled = _Global_VMapEnabled > 0.5;
    float3 worldPos = HexPointWorldPos(vertPos, inGame && vmapEnabled);

    float3 worldTangent = UnityObjectToWorldDir(v.tangent);
    float3 worldNormal = UnityObjectToWorldNormal(v.normal);
    float3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w * unity_WorldTransformParams.w;

    float4 clipPos = UnityWorldToClipPos(worldPos);
    float4 screenPos = ComputeScreenPos(clipPos);

    float4 gamma_color = ((asuint(_Color32Int) >> int4(0,8,16,24)) & int4(255,255,255,255)) / 255.0;
    float4 linear_color = pow((float4(0.055, 0.055, 0.055, 0.055) + gamma_color) / float4(1.05, 1.05, 1.05, 1.05), 2.4);

    o.vertex.xyzw = clipPos;
    o.vertPos_axialCoords.xy = v.texcoord3.xy;
    o.vertPos_axialCoords.zw = v.texcoord2.xy;
    o.objectPos.xyz = vertPos;
    o.worldPos.xyz = worldPos;
    o.tangent.xyz = worldTangent;
    o.binormal.xyz = worldBinormal;
    o.normal.xyz = worldNormal;
    o.screenPos.xyzw = screenPos;
    o.polyGroup_pctComplete.x = v.texcoord1.y;
    o.polyGroup_pctComplete.y = scaleProgress;
    o.color.xyzw = linear_color;


    return o;
}

fout frag(v2f i)
{

  fout o;
  const float4 icb[16] = {
    float4(16.0, 0.0, 0.0, 0.0),
    float4(8.0, 0.0, 0.0, 0.0),
    float4(14.0, 0.0, 0.0, 0.0),
    float4(6.0, 0.0, 0.0, 0.0),
    float4(4.0, 0.0, 0.0, 0.0),
    float4(12.0, 0.0, 0.0, 0.0),
    float4(2.0, 0.0, 0.0, 0.0),
    float4(10.0, 0.0, 0.0, 0.0),
    float4(13.0, 0.0, 0.0, 0.0),
    float4(5.0, 0.0, 0.0, 0.0),
    float4(15.0, 0.0, 0.0, 0.0),
    float4(7.0, 0.0, 0.0, 0.0),
    float4(1.0, 0.0, 0.0, 0.0),
    float4(9.0, 0.0, 0.0, 0.0),
    float4(3.0, 0.0, 0.0, 0.0),
    float4(11.0, 0.0, 0.0, 0.0)
  };

  float2 triangleVertPos = i.vertPos_axialCoords.xy;
  float2 axialCoords = i.vertPos_axialCoords.zw;
  int polygonGroup = (int)((uint)(0.5 + i.polyGroup_pctComplete.x));
  float hexPctComplete = i.polyGroup_pctComplete.y;

  uint renderPlace = asuint(_Global_DS_RenderPlace);

  bool isDysonMap = renderPlace > 1.5;
  bool isDysonOrStarMap = renderPlace > 0.5;
  bool isInGame = renderPlace < 0.5;
  bool isMenuDemo = 0.5 < asuint(_Global_IsMenuDemo);

  if ((int)(asint(_Global_DS_PaintingLayerId) != asint(_LayerId)) | (int)(asuint(_Global_DS_PaintingGridMode) > 0.5) ? asuint(_Global_DS_PaintingLayerId) > 0 ? isDysonMap : 0 : 0 != 0) discard;

  float3 rayPosToCamera = _WorldSpaceCameraPos.xyz - i.worldPos.xyz;

  //if a ray from the the vert to the camera and a ray from the vert to the sun are pointing in the same direction, must be far side.
  bool isFarSide = dot(rayPosToCamera, _Global_DS_SunPosition_Map.xyz - i.worldPos.xyz) > 0;
  bool hideFarSideEnabled = asuint(_Global_DS_HideFarSide) > 0.5;
  if (isDysonMap && hideFarSideEnabled && isFarSide) discard;

  /* remove pixels that fall outside the bounds of the frame that surrounds this shell */
  uint polyCount = (uint)(0.5 + _PolyCount) < 1 ? 1 : min(380, (uint)(0.5 + _PolyCount));
  int polygonIndex = (int)polyCount + (int)(0.5 + polygonGroup);

  float3 prevLineNormal = _PolygonNArr[polygonIndex - 1].xyz;
  float3 prevLineToPoint = i.objectPos.xyz - _PolygonArr[polygonIndex - 1].xyz;

  float3 thisLineDir = _PolygonArr[polygonIndex + 1].xyz - _PolygonArr[polygonIndex].xyz;
  float3 thisLineNormal = _PolygonNArr[polygonIndex].xyz;

  float3 nextLineDir = _PolygonArr[polygonIndex + 2].xyz - _PolygonArr[polygonIndex + 1].xyz;
  float3 nextLineNormal = _PolygonNArr[polygonIndex + 1].xyz;
  float3 nextLineToPoint = i.objectPos.xyz - _PolygonArr[polygonIndex + 1].xyz;

  float3 nextnextLineToPoint = i.objectPos.xyz - _PolygonArr[polygonIndex + 2].xyz;


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

  prevLineIsConvex *= _Clockwise;
  nextLineIsConvex *= _Clockwise;
  prevLineInside *= _Clockwise;
  thisLineInside *= _Clockwise;
  nextLineInside *= _Clockwise;
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


  float distancePosToCamera = length(rayPosToCamera);
  
  float4 cubeCoords = _Scale * float4(0.666666687,0.333333343,-0.333333343,0.333333343) * axialCoords.xxyy;
  cubeCoords.xy = cubeCoords.yx + cubeCoords.wz;

  float gridFalloff = 0.99 - saturate((distancePosToCamera / _GridSize) / 15.0 - 0.2) * 0.03;

  float2 adjustPoint = triangleVertPos.yx * gridFalloff + cubeCoords.xy;
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


  int bitmask;
  float cutOut = 0;
  if (hexPctComplete - random_num * 0.999 < 0.00005) {
    if (isDysonMap) {
      float2 pixelPos = (_ScreenParams.xy * (i.screenPos.xy / i.screenPos.ww));
      pixelPos = (int2)pixelPos;
      bitmask = ((~(-1 << 2)) << 2) & 0xffffffff; // 12
      cutOut = (((uint)pixelPos.x << 2) & bitmask) | ((uint)0 & ~bitmask);
      bitmask = ((~(-1 << 2)) << 0) & 0xffffffff; // 3
      cutOut = (((uint)pixelPos.y << 0) & bitmask) | ((uint)cutOut & ~bitmask);
      if (0.2499 - (icb[cutOut].x * 0.0588) < 0) discard;
      cutOut = 1;
    } else {
      if (-1 != 0) discard;
      cutOut = 0;
    }
  } else {
    cutOut = 0;
  }

  float2 triPosAdjusted;
  triPosAdjusted.x = triangleVertPos.x / _Scale + (2.0 * axialCoords.x - axialCoords.y) / 3.0;
  triPosAdjusted.y = triangleVertPos.y / _Scale +       (axialCoords.x + axialCoords.y) / 3.0;

  float lodBias = min(4, max(0, log(0.0001 * distancePosToCamera)));

  float4 albedoTex = tex2Dbias(_MainTex, float4(triangleVertPos.xy, 0, lodBias)).xyzw;

  float4 normalTex = tex2Dbias(_NormalTex, float4(triangleVertPos.xy, 0, lodBias)).xyzw;
  float3 unpackedNormal = UnpackNormal(normalTex);

  float2 msTex = tex2D(_MSTex, triangleVertPos.xy).xw;

  float3 emissionTex_A = tex2Dbias(_EmissionTex, float4(triangleVertPos.xy, 0, lodBias)).xyz;
  float3 emissionTex_B = tex2Dbias(_EmissionTex, float4(float2(1,1) - triangleVertPos.yx, 0, lodBias)).xyz;

  float3 emissionTex = lerp(emissionTex_A.xyz, emissionTex_B.xyz, sin(_Time.y + _Time.y) * 0.5 + 0.5);
  float3 emissionTexTwo = tex2Dbias(_EmissionTex2, float4(triPosAdjusted.xy, 0, lodBias)).xyz;

  float colorControlTex_A = tex2Dbias(_ColorControlTex, float4(triangleVertPos.xy, 0, lodBias)).x;
  float colorControlTex_B = tex2Dbias(_ColorControlTex, float4(float2(1,1) - triangleVertPos.yx, 0, lodBias)).x;
  float colorControlTex = lerp(colorControlTex_A, colorControlTex_B, sin(_Time.y + _Time.y) * 0.5 + 0.5);
  float colorControlTexTwo = tex2Dbias(_ColorControlTex2, float4(triPosAdjusted.xy, 0, lodBias)).x;

  unpackedNormal.xy = (-1.5 * _NormalMultiplier) * unpackedNormal.xy;
  float3 worldNormal = normalize(i.normal.xyz * unpackedNormal.z + i.tangent.xyz * unpackedNormal.x + i.binormal.xyz * unpackedNormal.y);

  float3 triPosNew;
  triPosNew.x = 1.0 - abs(frac(0.5 * (0.6666666 + triPosAdjusted.x)) * 2.0 - 1.0);
  triPosNew.y = 1.0 - abs(frac(0.5 * (0         + triPosAdjusted.y)) * 2.0 - 1.0);
  triPosNew.z = 1.0 - abs(frac(0.5 * (1.6666666 + triPosAdjusted.x)) * 2.0 - 1.0);

  float2 newPosOne;
  newPosOne.x = ((triPosNew.x + triPosNew.y) / sqrt(2)) / sqrt(3);
  newPosOne.y =  (triPosNew.y - triPosNew.x) / sqrt(2);

  float2 newPosTwo;
  newPosTwo.x = ((triPosNew.z + triPosNew.y) / sqrt(2)) / sqrt(3);
  newPosTwo.y =  (triPosNew.y - triPosNew.z) / sqrt(2);

  float3 viewDir = normalize(rayPosToCamera);
  bool viewingSunFacingSide = dot(i.normal.xyz, viewDir.xyz) < 0;

  float emissionAnim = saturate(30.0 * (0.05 - abs(length(newPosOne.xy) - frac(2.9 * _Time.x)))) * min(1, 5 * (1 - frac(2.9 * _Time.x)))
       + saturate(30.0 * (0.05 - abs(length(newPosTwo.xy) - frac(_Time.x * 3.7 + 0.5)))) * min(1, 5 * (1 - frac(_Time.x * 3.7 + 0.5)));
  emissionAnim = viewingSunFacingSide ? saturate((emissionTexTwo.y * 2 + emissionTex.y) * emissionAnim) : 0;

  float3 dysonEmission = viewingSunFacingSide ? _DysonEmission.xyz : float3(1,1,1);
  float colorControl = saturate(colorControlTex + colorControlTexTwo);
  float3 colorOutwardFacing = lerp(colorControl * i.color.xyz, i.color.xyz, 0.01 / _EmissionMultiplier);
  float3 emissionOutwardFacing = lerp(emissionTexTwo.xyz * float3(0.3, 0.3, 0.3) + emissionTex.xyz, colorOutwardFacing, i.color.w);
  float3 emissionSunFacing = float3(3,3,3) * (emissionTexTwo.x + emissionTex.x) * dysonEmission.xyz;
  float3 emission = viewingSunFacingSide ? emissionSunFacing.xyz : emissionOutwardFacing.xyz;

  emission = _EmissionMultiplier * lerp(emission.xyz, dysonEmission.xyz, emissionAnim);

  float3 albedo = _AlbedoMultiplier * albedoTex.xyz * lerp(float3(1,1,1), albedoTex.xyz, saturate(1.25 * (albedoTex.w - 0.1)));
  float specularStrength = dot(albedo, float3(0.3, 0.6, 0.1));

  float scaledDistancePosToCamera = isMenuDemo ? distancePosToCamera : isDysonOrStarMap ? 3999.9998 * distancePosToCamera : distancePosToCamera;
  float scaleMetallic = isMenuDemo ? 0.1 : isDysonOrStarMap ? 0.93 : 0.7;
  scaleMetallic = saturate(pow(0.25 * log(scaledDistancePosToCamera + 1) - 1.5, 3.0)) * scaleMetallic;
  
  float metallicFactor, fadeOut, roughnessSqr, finalAlpha;
  float4 finalColor;
  if(isDysonMap) {
    float3 shellColor = i.color.w > 0.5 ? i.color.xyz : (asint(_Global_DS_PaintingLayerId) == asint(_LayerId) ? float3(0, 0.3, 0.65) : float3(0, 0.8, 0.6));
    float3 shellEmissionColor = lerp(emission.xyz * 2.2, shellColor, 0.8 * cutOut);
    specularStrength       = _State > 0.5 ? 0   : 0.8 * specularStrength * (1.0 - cutOut);
    fadeOut          = _State > 0.5 ? 0   : 0.03                   * (1.0 - cutOut);
    float metallic         = _State > 0.5 ? 0   : msTex.x                * (1.0 - scaleMetallic);
    float smoothness       = _State > 0.5 ? 0.5 : min(0.8, msTex.y);

    float3 defaultColor   = i.color.xyz * (viewingSunFacingSide ? 2 : 1.5);
    float3 highStateColor = i.color.w > 0.5 ? defaultColor : float3(2.59, 0.0525, 0.0875);
    float3 medStateColor  = i.color.w > 0.5 ? defaultColor : float3(0.525,0.875, 3.5);
    float3 lowStateColor  = i.color.w > 0.5 ? defaultColor : float3(0.35, 0.7, 3.5);
    float3 zeroStateColor = i.color.w > 0.5 ? defaultColor : float3(1.05, 1.05, 1.05);
    finalColor.xyz = 3.5 < _State ? highStateColor :
                        2.5 < _State ? medStateColor  :
                        1.5 < _State ? lowStateColor  :
                        0.5 < _State ? zeroStateColor :
                        shellEmissionColor;
    float emissionFactor = (int)(_State > 0.5) | (int)(cutOut > 0.5) ? 1.0 : saturate(colorControlTex + colorControlTexTwo.x);
    finalAlpha = _EmissionMultiplier * emissionFactor;
    metallicFactor = saturate(metallic * 0.85 + 0.149);
    float perceptualRoughness = min(1, 1 - smoothness * 0.97);
    roughnessSqr = pow(min(1, 1 - smoothness * 0.97), 4);
  }
  else {
    float multiplyEmission = isDysonOrStarMap ? 1.8  : 2.5;
    specularStrength = 0.8 * specularStrength;
    fadeOut = 0.03;
    finalColor.xyz = emission.xyz * multiplyEmission;
    finalAlpha = _EmissionMultiplier * saturate(colorControlTex + colorControlTexTwo.x);
    metallicFactor = saturate(msTex.x * (0.85 - 0.85 * scaleMetallic) + 0.149);
    roughnessSqr = pow(1 - 0.97 * min(0.8, msTex.y), 4); //pow(min(1, 1 - min(0.8, msTex.y) * 0.97), 2);
  }
  finalColor.w = 0.0;
  
  //float metallicFactor = saturate(metallic * 0.85 + 0.149);
  //float roughnessSqr = roughness * roughness;

  float NdotV = viewingSunFacingSide ? -dot(worldNormal.xyz, viewDir.xyz) : dot(worldNormal.xyz, viewDir.xyz);
  worldNormal.xyz = viewingSunFacingSide ? -worldNormal.xyz : worldNormal.xyz;

  float3 lightDir = -i.normal.xyz;
  float3 halfDir = normalize(normalize(rayPosToCamera) + lightDir.xyz);

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

  float sunStrength = isInGame ? pow(saturate(1.05 + dot(normalize(_WorldSpaceCameraPos.xyz - _Global_DS_SunPosition.xyz), i.normal.xyz)), 0.4) : 1.0;
  float3 sunColor = float3(1.5625,1.5625,1.5625) * _SunColor.xyz;
  float intensity = saturate(pow(NdotL * 0.6 + 1, 3));
  float3 sunColorIntensity = float3(0.07, 0.07, 0.07) * _SunColor * (intensity * 1.5 + 1) * intensity;
  float3 sunSpecular = sunColor.xyz * clamp_NdotL * specularStrength;

  float3 finalLight = lerp(1, specularStrength, metallicFactor) * fadeOut * sunColor.xyz * (F * D * G + (0.1 / UNITY_PI)) * clamp_NdotL;
  finalLight = finalLight.xyz * lerp(metallicFactor, 1, specularStrength * 0.2);

  finalLight = float3(5,5,5) * lerp(float3(1,1,1), _SunColor, float3(0.3,0.3,0.3)) * finalLight.xyz;
  finalLight = (sunColorIntensity.xyz * specularStrength * (1 - metallicFactor * 0.6) + sunSpecular.xyz * pow(1 - metallicFactor, 0.6) + finalLight.xyz) * sunStrength;

  float finalStength = dot(finalLight, float3(0.3, 0.6, 0.1));
  float3 normalizedLight = finalLight / finalStength;
  float megaLog = log(log(log(log(log(log(log(log(finalStength / 0.32) + 1) + 1) + 1) + 1) + 1) + 1) + 1) + 1;
  finalLight = 0.32 < finalStength ? normalizedLight * megaLog * 0.32 : finalLight;

  //float finalAlpha = _EmissionMultiplier * emissionFactor;
  o.sv_target.xyzw = finalColor + float4(finalLight, finalAlpha);

  return o;
}