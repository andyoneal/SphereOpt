struct v2f
{   
    float4 pos : SV_POSITION0;
    float4 TBN0 : TEXCOORD0;
    float4 TBN1 : TEXCOORD1;
    float4 TBN2 : TEXCOORD2;
    float4 uv_controlUV : TEXCOORD3;
    float4 upDir_lodDist : TEXCOORD4;
    float3 time_state_emiss : TEXCOORD5;
    float3 worldPos : TEXCOORD6;
    float4 screenPosIsh : TEXCOORD7;
    float3 indirectLight : TEXCOORD8;
    UNITY_SHADOW_COORDS(10)
    float4 unk : TEXCOORD11;
};


// void main(
//   float4 v0 : POSITION0,
//   float3 v1 : NORMAL0,
//   float4 v2 : TANGENT0,
//   float4 v3 : COLOR0,
//   uint v4 : SV_VertexID0,
//   uint v5 : SV_InstanceID0,
//   float4 v6 : TEXCOORD0,
//   float4 v7 : TEXCOORD1,
//   float2 v8 : TEXCOORD2,
//   out float4 o0 : SV_POSITION0,
//   out float4 o1 : TEXCOORD0,
//   out float4 o2 : TEXCOORD1,
//   out float4 o3 : TEXCOORD2,
//   out float4 o4 : TEXCOORD3,
//   out float4 o5 : TEXCOORD4,
//   out float4 o6 : TEXCOORD5,
//   out float4 o7 : TEXCOORD6,
//   out float4 o8 : TEXCOORD7,
//   out float4 o9 : TEXCOORD8,
//   out float4 o10 : TEXCOORD10,
//   out float4 o11 : TEXCOORD11)
// {
v2f vert(appdata_full v, uint instanceID : SV_InstanceID, uint vertexID : SV_VertexID)
{
    
    v2f o
    
    float objIndex = _IdBuffer[instanceID]; //r0.x
    
    float objId = _InstBuffer[objIndex].objId; //r1.x
    float3 pos = _InstBuffer[objIndex].pos; //r1.yzw
    float4 rot = _InstBuffer[objIndex].rot; //r2.xyzw
    
    float time = _AnimBuffer[objId].time; //r3.x
    float prepare_length = _AnimBuffer[objId].prepare_length; //r3.y
    float working_length = _AnimBuffer[objId].working_length; //r3.z
    uint state = _AnimBuffer[objId].state; //r3.w
    float power = _AnimBuffer[objId].power; //r0.y
    
    float3 scale = _ScaleBuffer[objIndex]; //r4.xyz
    bool useScale = _UseScale > 0.5;
    float3 scaledVPos = useScale ? v.vertex.xyz * scale.xyz : v.vertex.xyz; //r5.xyz
    float3 scaledVNormal = useScale ? v.normal.xyz * scale.xyz : v.normal.xyz; //r4.xyz
    float3 scaledVTan = v.tangent.xyz; //r6.xyz
    
    animateWithVerta(vertexID, time, prepare_length, working_length, /*inout*/ scaledVPos, /*inout*/ scaledVNormal, /*inout*/ scaledVTan);
    
    float3 worldVPos = rotate_vector_fast(scaledVPos, rot) + pos; //r5.xyz
    float3 worldVNormal = rotate_vector_fast(scaledVNormal, rot); //r7.xyz
    float3 worldTangent = rotate_vector_fast(scaledVTan, rot); //r4.yzx
    
    float posHeight = length(pos); //r0.x
    float3 upDir = float3(0,1,0); //r2.xyz
    float lodDist = 0; //r2.w
    if (posHeight > 0) {
        upDir = pos / posHeight;
        float g_heightMap = UNITY_SAMPLE_TEXCUBE_LOD(_Global_LocalPlanetHeightmap, normalize(worldVPos), 0).x; //r0.z
        float g_adjustHeight = (_Global_Planet_Radius + g_heightMap) - posHeight; //r0.x
        worldVPos = g_adjustHeight * upDir + worldVPos.xyz;
        lodDist = saturate(0.01 * (distance(pos, _WorldSpaceCameraPos) - 180)); //r2.w
    }
    
    //float3 worldVPos = mul(unity_ObjectToWorld, float4(worldVPos,1)).xyz; //r0.xzw
    //float4 clipPos = UnityObjectToClipPos(worldVPos); //r6.xyzw
    
    worldVNormal = lerp(normalize(worldVNormal), upDir, 0.2 * lodDist); //r1.xyz
    
    float4 clipPos = mul(UNITY_MATRIX_VP, float4(worldVPos,1)); //r6.xyzw
    
    float viewDir = normalize(_WorldSpaceCameraPos.xyz - worldVPos.xyz); //r3.yzw
    float controlU = dot(worldTangent, viewDir);
    // r5.xyz = r4.xyz * r1.yzx;
    // r5.xyz = r4.zxy * r1.zxy - r5.xyz;
    // r1.w = dot(r5.xyz, r5.xyz);
    // r1.w = rsqrt(r1.w);
    // r5.xyz = r5.xyz * r1.www;
    float3 worldBitangent = normalize(cross(worldVNormal, worldTangent)); //r5.xyz
    float controlV = dot(worldBitangent, viewDir);
    
    //worldVNormal = UnityObjectToWorldNormal(worldVNormal);
    worldVNormal = normalize(worldVNormal); //r1.xyz
    worldTangent = float4(UnityObjectToWorldDir(worldTangent.xyz), v.tangent.w); //r3.yzw
    float3 worldBinormal = calculateBinormal(float4(worldTangent.xyz, v.tangent.w), worldVNormal); //r4.xyz
    
    // o8.x = clipPos.x * 0.5 + (clipPos.w * 0.5);
    // o8.y = clipPos.y * -0.5 + (clipPos.w * 0.5);
    // o8.zw = clipPos.zw;
    
    // o10.xy = float2(clipPos.x * 0.5, clipPos.y * 0.5 * _ProjectionParams.x) + (clipPos.w * 0.5);
    // o10.zw = clipPos.zw;
    
    o.pos.xyzw = clipPos.xyzw;
    
    o.TBN0.x = worldTangent.x;
    o.TBN0.y = worldBinormal.x;
    o.TBN0.z = worldVNormal.x;
    o.TBN0.w = worldVPos.x;
    o.TBN1.x = worldTangent.y;
    o.TBN1.y = worldBinormal.y;
    o.TBN1.z = worldVNormal.y;
    o.TBN1.w = worldVPos.y;
    o.TBN2.x = worldTangent.z;
    o.TBN2.y = worldBinormal.z;
    o.TBN2.z = worldVNormal.z;
    o.TBN2.w = worldVPos.z; //tex2
    
    o.uv_controlUV.xy = v.texcoord.xy;
    o.uv_controlUV.z = controlU;
    o.uv_controlUV.w = controlV;
    
    o.upDir_lodDist.xyz = upDir.xyz; //o5 //tex4
    o.upDir_lodDist.w = lodDist; //o5
    
    o.time_state_emiss.x = time; //o6.x //tex5
    o.time_state_emiss.y = state; //o6.y
    o.time_state_emiss.z = lerp(1, power, _EmissionUsePower); //o6.z
    o.worldPos1.xyz = worldVPos; //o7 //tex6
    o.screenPosIsh.x = clipPos.x * 0.5 + (clipPos.w * 0.5); // ??
    o.screenPosIsh.y = clipPos.y * -0.5 + (clipPos.w * 0.5); // ??
    o.screenPosIsh.zw = clipPos.zw; //tex7
    o.indirectLight.xyz = ShadeSH9(float4(worldVNormal, 1.0));
    UNITY_TRANSFER_SHADOW(o, float(0,0));
    //o10.xyzw = ComputeScreenPos(o.pos);
    o11.xyzw = float4(0,0,0,0);
    
    return o;
}

fout frag(v2f inp)
{
  
  fout o;
  
  float2 uv = inp.uv_viewAngle.xy;
  float2 controlUV = inp.uv_controlUV.zw;
  float3 upDir = inp.upDir_lodDist.xyz;
  float lodDist = inp.upDir_lodDist.w;
  float time = inp.time_state_emiss.x;
  float veinType = inp.time_state_emiss.y;
  float emissionPower = inp.time_state_emiss.z;
  float3 worldPos1 = inp.worldPos.xyz;
  float3 worldPos1 = inp.screenPosIsh.xyz;
  float3 indirectLight = inp.indirectLight.xyz;
  
  
  float3 veinColor = float3(0,0,0); //r0.xyz
  if (veinType < 1.05 && 0.95 < veinType) { //iron
    veinColor = _Color1.xyz;
  } else {
    if (veinType < 2.05 && 1.95 < veinType) { //copper
      veinColor = _Color2.xyz;
    } else {
      if (veinType < 3.05 && 2.95 < veinType) { //Silicon
        veinColor = _Color3.xyz;
      } else {
        if (veinType < 4.05 && 3.95 < veinType) { //titanium
          veinColor = _Color4.xyz;
        } else {
          if (veinType < 5.05 && 4.95 < veinType) { //stone
            veinColor = _Color5.xyz;
          } else {
            if (veinType < 6.05 && 5.95 < veinType) { //coal
              veinColor = _Color6.xyz;
            } else {
              if (veinType < 9.05 && 8.95 < veinType) { //diamond
                veinColor = _Color9.xyz;
              } else {
                veinColor = veinType < 14.05 && 13.95 < veinType ? _Color14.xyz : _Color0.xyz; //mag, then none
                veinColor = veinType < 13.05 && 12.95 < veinType ? _Color13.xyz : veinColor; //bamboo
                veinColor = veinType < 12.05 && 11.95 < veinType ? _Color12.xyz : veinColor; //grat
                veinColor = veinType < 11.05 && 10.95 < veinType ? _Color11.xyz : veinColor; //crysrub
                veinColor = veinType < 10.05 && 9.95 < veinType ? _Color10.xyz : veinColor; //frac
              }
            }
          }
        }
      }
    }
  }
  
  // r0.x = cmp(0.949999988 < v6.y);
  // r0.y = cmp(v6.y < 1.04999995);
  // r0.x = r0.y ? r0.x : 0;
  // if (r0.x != 0) {
  //   r0.xyz = cb0[31].xyz;
  // } else {
  //   r0.w = cmp(1.95000005 < v6.y);
  //   r1.x = cmp(v6.y < 2.04999995);
  //   r0.w = r0.w ? r1.x : 0;
  //   if (r0.w != 0) {
  //     r0.xyz = cb0[32].xyz;
  //   } else {
  //     r0.w = cmp(2.95000005 < v6.y);
  //     r1.x = cmp(v6.y < 3.04999995);
  //     r0.w = r0.w ? r1.x : 0;
  //     if (r0.w != 0) {
  //       r0.xyz = cb0[33].xyz;
  //     } else {
  //       r0.w = cmp(3.95000005 < v6.y);
  //       r1.x = cmp(v6.y < 4.05000019);
  //       r0.w = r0.w ? r1.x : 0;
  //       if (r0.w != 0) {
  //         r0.xyz = cb0[34].xyz;
  //       } else {
  //         r0.w = cmp(4.94999981 < v6.y);
  //         r1.x = cmp(v6.y < 5.05000019);
  //         r0.w = r0.w ? r1.x : 0;
  //         if (r0.w != 0) {
  //           r0.xyz = cb0[35].xyz;
  //         } else {
  //           r0.w = cmp(5.94999981 < v6.y);
  //           r1.x = cmp(v6.y < 6.05000019);
  //           r0.w = r0.w ? r1.x : 0;
  //           if (r0.w != 0) {
  //             r0.xyz = cb0[36].xyz;
  //           } else {
  //             r0.w = cmp(8.94999981 < v6.y);
  //             r1.x = cmp(v6.y < 9.05000019);
  //             r0.w = r0.w ? r1.x : 0;
  //             if (r0.w != 0) {
  //               r0.xyz = cb0[37].xyz;
  //             } else {
  //               r1.xyzw = cmp(float4(9.94999981,10.9499998,11.9499998,12.9499998) < v6.yyyy);
  //               r2.xyzw = cmp(v6.yyyy < float4(10.0500002,11.0500002,12.0500002,13.0500002));
  //               r1.xyzw = r1.xyzw ? r2.xyzw : 0;
  //               r0.w = cmp(13.9499998 < v6.y);
  //               r2.x = cmp(v6.y < 14.0500002);
  //               r0.w = r0.w ? r2.x : 0;
  //               r2.xyz = r0.www ? cb0[42].xyz : cb0[30].xyz;
  //               r2.xyz = r1.www ? cb0[41].xyz : r2.xyz;
  //               r2.xyz = r1.zzz ? cb0[40].xyz : r2.xyz;
  //               r1.yzw = r1.yyy ? cb0[39].xyz : r2.xyz;
  //               r0.xyz = r1.xxx ? cb0[38].xyz : r1.yzw;
  //             }
  //           }
  //         }
  //       }
  //     }
  //   }
  // }
  
  float3 mstex = UNITY_SAMPLE_TEX2D(_MS_Tex, uv).xyw; //r1.xyz
  
  if (mstex.y < _AlphaClip - 0.001) discard;
  
  float3 colorA = tex2D(_MainTexA, uv).xyz * veinColor; //r2.xyz
  float4 colorB = tex2D(_MainTexB, uv); //r3.xyzw
  float2 occTex = tex2D(_OcclusionTex, uv).xw; //r1.yw
  float3 albedo = lerp(colorA.xyz * float3(6.0, 6.0, 6.0), colorB.xyz * float3(1.7, 1.7, 1.7), (1.0 - lodDist) * colorB.w); //r2.xyz
  
  albedo = albedo * pow(lerp(1.0, occTex.x, occTex.y), _OcclusionPower); //r2.xyz
  
  float3 unpackedNormal = UnpackNormal(tex2Dbias(_NormalTex, float4(uv, 0, -1))); //r3.xyz
  float3 normal = float3(_NormalMultiplier * unpackedNormal.xy, unpackedNormal.z); //r3.xyz
  
  float4 emmTex = tex2Dbias(_EmissionTex, float4(uv,0,-1)); //r4.xyzw
  
  float emmJitTex = UNITY_SAMPLE_TEX2D(_EmissionJitterTex, float2(time, 0)).x; //r0.w
  
  float canEmit = (int)(emissionPower > 0.1) | (int)(_EmissionSwitch < 0.5) ? 1.0 : 0.0; //r3.w
  
  float2 g_heightMap = UNITY_SAMPLE_TEXCUBE(_Global_LocalPlanetHeightmap, normalize(worldPos1)).xy; //r5.xy
  float frac_heightMap = frac(g_heightMap.y);
  float int_heightMap = g_heightMap.y - frac_heightMap;
  float biomoThreshold = (frac_heightMap * frac_heightMap) * (frac_heightMap * -2.0 + 3.0) + int_heightMap;
  float biomoThreshold0 = saturate(1.0 - biomoThreshold);
  float biomoThreshold1 = min(saturate(2.0 - biomoThreshold), saturate(biomoThreshold));
  float biomoThreshold2 = saturate(biomoThreshold - 1);
  float4 biomoColor = biomoThreshold1 * _Global_Biomo_Color1; //r6.xyzw
  biomoColor = _Global_Biomo_Color0 * biomoThreshold0 + biomoColor;
  biomoColor = _Global_Biomo_Color2 * biomoThreshold2 + biomoColor;
  biomoColor.xyz = biomoColor.xyz * _BiomoMultiplier; //r5.yzw
  
  float heightOffset = saturate((_BiomoHeight - length(worldPos1) - g_heightMap.x + _Global_Planet_Radius) / _BiomoHeight); //r1.y
  heightOffset = biomoColor.w * pow(heightOffset, 2); //r1.w
  
  multiAlbedo = _AlbedoMultiplier * albedo; //r6.xyz
  
  biomoColor.xyz = lerp(biomoColor.xyz, biomoColor.xyz * albedo, _Biomo); //r5.xyz //r6.w
  
  r5.w = _ScreenTex_TexelSize.z / _ScreenTex_TexelSize.w;
  r7.xw = screenPosIsh.xy / screenPosIsh.ww;
  r7.y = _CrystalRefrac * -controlUV.x;
  r7.z = _CrystalRefrac * -controlUV.y * r5.w;
  r7.xy = screenPosIsh.ww * (r7.xw + (r7.yz / screenPosIsh.ww));
  r7.xy = r7.xy / screenPosIsh.ww;
  
  r7.xyz = _ScreenTex.Sample(s0_s, r7.xy).xyz;
  
  r2.xyz = lerp(multiAlbedo, r5.xyz, heightOffset); //r2.xyz
  
  r5.xyz = _Crystal * r7.xyz;
  r6.xy = float2(4,4) * saturate(controlUV.xy - float2(0.3, 0.3));
  r1.w = saturate(3.0 - length(r6.xy));
  
  r5.xyz = r5.xyz * r1.www;
  r1.y = 1 - heightOffset * biomoColor.w;
  r2.xyz = r5.xyz * r1.yyy + r2.xyz;
  
  normal = normalize(normal);
  
  r1.xy = saturate(cb0[44].xy * r1.xz);
  
  // r4.xyz = cb0[44].zzz * r4.xyz;
  // r1.zw = cb0[46].yx * r4.ww;
  // r2.w = -1 + r2.w;
  // r1.z = r1.z * r2.w + 1;
  // r4.xyz = r4.xyz * r1.zzz;
  // r1.z = cb0[46].y * r1.w;
  // r0.w = -1 + r0.w;
  // r0.w = r1.z * r0.w + 1;
  // r4.xyz = r4.xyz * r0.www;
  // r4.xyz = r4.xyz * r3.www;
  
  /* calculate emission/glow from the textures and the various properties that control emission. */
  float3 emissionColor = _EmissionMultiplier * emmTex.xyz;
  float emissionSwitch = _EmissionSwitch * emmTex.w;
  float emissionJitter = _EmissionJitter * emmTex.w;
  float emmIsOn = lerp(1, saturate(veinType), emissionSwitch);
  emissionColor = emissionColor * emmIsOn;
  float jitterRatio = _EmissionSwitch * emissionJitter;
  float jitter = lerp(1.0, emmJitTex, jitterRatio);
  emissionColor = emissionColor * jitter;
  emissionColor = emissionColor * canEmit; // r4.xyz
  
  float3 worldPos = float3(inp.TBN0.w, inp.TBN1.w, inp.TBN2.w); //r5.yzw
  
  // r6.xyz = cb1[4].xyz + -r5.yzw;
  // r0.w = dot(r6.xyz, r6.xyz);
  // r0.w = rsqrt(r0.w);
  // r7.xyz = r6.xyz * r0.www;
  // r8.x = cb4[9].z;
  // r8.y = cb4[10].z;
  // r8.z = cb4[11].z;
  // r1.z = dot(r6.xyz, r8.xyz);
  // r8.xyz = -cb3[25].xyz + r5.yzw;
  // r1.w = dot(r8.xyz, r8.xyz);
  // r1.w = sqrt(r1.w);
  // r1.w = r1.w + -r1.z;
  // r1.z = cb3[25].w * r1.w + r1.z;
  // r1.z = saturate(r1.z * cb3[24].z + cb3[24].w);
  // r1.w = cmp(cb5[0].x == 1.000000);
  // if (r1.w != 0) {
  //   r1.w = cmp(cb5[0].y == 1.000000);
  //   r8.xyz = cb5[2].xyz * v2.www;
  //   r8.xyz = cb5[1].xyz * v1.www + r8.xyz;
  //   r8.xyz = cb5[3].xyz * v3.www + r8.xyz;
  //   r8.xyz = cb5[4].xyz + r8.xyz;
  //   r5.xyz = r1.www ? r8.xyz : r5.yzw;
  //   r5.xyz = -cb5[6].xyz + r5.xyz;
  //   r5.yzw = cb5[5].xyz * r5.xyz;
  //   r1.w = r5.y * 0.25 + 0.75;
  //   r2.w = cb5[0].z * 0.5 + 0.75;
  //   r5.x = max(r2.w, r1.w);
  //   r5.xyzw = t11.Sample(s1_s, r5.xzw).xyzw;
  // } else {
  //   r5.xyzw = float4(1,1,1,1);
  // }
  // r1.w = saturate(dot(r5.xyzw, cb2[46].xyzw));
  // r5.xy = v10.xy / v10.ww;
  // r2.w = t9.Sample(s2_s, r5.xy).x;
  // r1.w = -r2.w + r1.w;
  // r1.z = r1.z * r1.w + r2.w;
  UNITY_LIGHT_ATTENUATION(atten, inp, worldPos); //r1.z
  
  float3 viewDir = normalize(_WorldSpaceCameraPos - worldPos); //r7.xyz or (r6.xyz * r0.www)
  
  float3 worldNormal;
  worldNormal.x = dot(inp.TBN0.xyz, normal.xyz);
  worldNormal.y = dot(inp.TBN1.xyz, normal.xyz);
  worldNormal.z = dot(inp.TBN2.xyz, normal.xyz);
  worldNormal = normalize(worldNormal); //r3.xyz
  
  float metallicLow = metallic * 0.85 + 0.149; //r1.w
  float metallicHigh = metallic * 0.85 + 0.649; //r1.x
  
  float perceptualRoughness = 1 - smoothness * 0.97; //r1.y
  
  float3 lightDir = _WorldSpaceLightPos0;
  
  float3 halfDir = normalize(viewDir + lightDir); //r5.xyz
  
  float roughness = perceptualRoughness * perceptualRoughness; //r0.w
  //r2.w = r0.w * r0.w;
  
  float unclamped_nDotL = dot(worldNormal, lightDir); //r3.w
  float nDotL = max(0, unclamped_nDotL); //r4.w
  float unclamped_nDotV = dot(worldNormal, viewDir); //r5.w
  float nDotV = max(0, unclamped_nDotV); //r5.w
  float unclamped_nDotH = dot(worldNormal, halfDir); //r6.x
  float nDotH = max(0, unclamped_nDotH); //r6.x
  float unclamped_vDotH = dot(viewDir, halfDir); //r5.x
  float vDotH = max(0, unclamped_vDotH); //r5.x
  
  //cubed_ndotl
  r3.w = r3.w * 0.349999994 + 1;
  r5.y = r3.w * r3.w;
  r3.w = r5.y * r3.w;
  
  float upDotL = dot(upDir, lightDir); //r5.y
  float nDotUp = dot(worldNormal, upDir); //r5.z
  
  //float upDotUp = dot(upDir, upDir); //r6.y
  // r6.z = cmp(v5.y < 0.999899983);
  // r6.y = cmp(0.00999999978 < r6.y);
  // r6.z = r6.y ? r6.z : 0;
  // r8.xyz = float3(0,1,0) * v5.yzx;
  // r8.xyz = v5.xyz * float3(1,0,0) + -r8.xyz;
  // r6.w = dot(r8.xy, r8.xy);
  // r6.w = rsqrt(r6.w);
  // r8.xyz = r8.xyz * r6.www;
  // r8.xyz = r6.zzz ? r8.xyz : float3(0,1,0);
  // r6.z = dot(r8.xy, r8.xy);
  // r6.z = cmp(0.00999999978 < r6.z);
  // r6.y = r6.z ? r6.y : 0;
  // r9.xyz = v5.yzx * r8.xyz;
  // r9.xyz = r8.zxy * v5.zxy + -r9.xyz;
  // r6.z = dot(r9.xyz, r9.xyz);
  // r6.z = rsqrt(r6.z);
  // r9.xyz = r9.xyz * r6.zzz;
  // r6.z = dot(-viewDir, r3.xyz);
  // r6.z = r6.z + r6.z;
  // r7.xyz = r3.xyz * -r6.zzz + -viewDir;
  // r8.x = dot(r7.zx, -r8.xy);
  // r8.y = dot(r7.xyz, v5.xyz);
  // r6.yzw = r6.yyy ? -r9.xyz : float3(-0,-0,-1);
  // r8.z = dot(r7.xyz, r6.yzw);
  // r6.y = log2(r1.y);
  // r6.y = 0.400000006 * r6.y;
  // r6.y = exp2(r6.y);
  // r6.y = 10 * r6.y;
  // r6.yzw = t10.SampleLevel(s3_s, r8.xyz, r6.y).xyz;
  // r7.x = r1.w * 0.699999988 + 0.300000012;
  // r1.y = 1 + -r1.y;
  // r1.y = r7.x * r1.y;
  // r6.yzw = r6.yzw * r1.yyy;
  
  float reflectivity; //r1.y
  float3 reflectColor = reflection(perceptualRoughness, metallicLow, upDir, viewDir, worldNormal, /*out*/ reflectivity); //r6.yzw
  
  // r7.x = cmp(1 >= r5.y);
  // if (r7.x != 0) {
  //   r7.xyzw = float4(-0.200000003,-0.100000001,0.100000001,0.300000012) + r5.yyyy;
  //   r7.xyzw = saturate(float4(5,10,5,5) * r7.xyzw);
  //   r8.xyz = float3(1,1,1) + -cb0[12].xyz;
  //   r8.xyz = r7.xxx * r8.xyz + cb0[12].xyz;
  //   r9.xyz = float3(1.25,1.25,1.25) * cb0[13].xyz;
  //   r10.xyz = -cb0[13].xyz * float3(1.25,1.25,1.25) + cb0[12].xyz;
  //   r9.xyz = r7.yyy * r10.xyz + r9.xyz;
  //   r10.xyz = cmp(float3(0.200000003,0.100000001,-0.100000001) < r5.yyy);
  //   r11.xyz = float3(1.5,1.5,1.5) * cb0[14].xyz;
  //   r12.xyz = cb0[13].xyz * float3(1.25,1.25,1.25) + -r11.xyz;
  //   r7.xyz = r7.zzz * r12.xyz + r11.xyz;
  //   r11.xyz = r11.xyz * r7.www;
  //   r7.xyz = r10.zzz ? r7.xyz : r11.xyz;
  //   r7.xyz = r10.yyy ? r9.xyz : r7.xyz;
  //   r7.xyz = r10.xxx ? r8.xyz : r7.xyz;
  // } else {
  //   r7.xyz = float3(1,1,1);
  // }
  float3 sunsetColor = float3(1, 1, 1); //r7.xyz
  if (upDotL <= 1) {
      float3 sunsetColor0 = _Global_SunsetColor0.xyz;
      float3 sunsetColor1 = _Global_SunsetColor1.xyz * float3(1.25, 1.25, 1.25);
      float3 sunsetColor2 = _Global_SunsetColor2.xyz * float3(1.5, 1.5, 1.5);
      
      float3 sunsetBlendDawn    = lerp(float3(0,0,0), sunsetColor2,  saturate(5  * (upDotL + 0.3))); // -30% to -10%
      float3 sunsetBlendSunrise = lerp(sunsetColor2,  sunsetColor1,  saturate(5  * (upDotL + 0.1))); // -10% to  10%
      float3 sunsetBlendMorning = lerp(sunsetColor1,  sunsetColor0,  saturate(10 * (upDotL - 0.1))); //  10% to  20%
      float3 sunsetBlendDay     = lerp(sunsetColor0,  float3(1,1,1), saturate(5  * (upDotL - 0.2))); //  20% to  40%
      
      sunsetColor = upDotL > -0.1 ? sunsetBlendSunrise : sunsetBlendDawn;
      sunsetColor = upDotL >  0.1 ? sunsetBlendMorning : sunsetColor;
      sunsetColor = upDotL >  0.2 ? sunsetBlendDay     : sunsetColor; //r7.xyz
  }
  sunsetColor = _LightColor0.xyz * sunsetColor;
  
  r8.xy = float2(0.150000006,3) * r5.yy;
  r8.xy = saturate(r8.xy);
  
  atten = 0.8 * lerp(atten, 1, saturate(0.15 * upDotL)); //r1.z
  lightColor = atten * lightColor; //r7.xyz
  
  // r1.z = r6.x * r6.x;
  // r8.xz = r0.ww * r0.ww + float2(-1,1);
  // r0.w = r1.z * r8.x + 1;
  // r0.w = rcp(r0.w);
  // r0.w = r0.w * r0.w;
  // r0.w = r0.w * r2.w;
  // r0.w = 0.25 * r0.w;
  // r1.z = r8.z * r8.z;
  // r2.w = 0.125 * r1.z;
  // r1.z = -r1.z * 0.125 + 1;
  // r5.w = r5.w * r1.z + r2.w;
  // r1.z = r4.w * r1.z + r2.w;
  // r8.xz = float2(1,1) + -r1.xw;
  // r2.w = r5.x * -5.55472994 + -6.98316002;
  // r2.w = r2.w * r5.x;
  // r2.w = exp2(r2.w);
  // r1.x = r8.x * r2.w + r1.x;
  // r0.w = r1.x * r0.w;
  // r1.x = r5.w * r1.z;
  // r1.x = rcp(r1.x);
  
  float specularTerm = GGX(roughness, metallicHigh, nDotH, nDotV, nDotL, vDotH);
  
  // r1.z = cmp(0 < r5.y);
  // r9.xyz = -cb0[7].xyz + cb0[6].xyz;
  // r8.xyw = r8.yyy * r9.xyz + cb0[7].xyz;
  // r2.w = saturate(r5.y * 3 + 1);
  // r9.xyz = -cb0[8].xyz + cb0[7].xyz;
  // r9.xyz = r2.www * r9.xyz + cb0[8].xyz;
  // r8.xyw = r1.zzz ? r8.xyw : r9.xyz;
  
  float3 ambientTwilight = lerp(_Global_AmbientColor2.xyz, _Global_AmbientColor1.xyz, saturate(upDotL * 3.0 + 1)); //-33% to 0%
  float3 ambientLowSun = lerp(_Global_AmbientColor1.xyz, _Global_AmbientColor0.xyz, saturate(upDotL * 3.0)); // 0% - 33%
  float3 ambientColor = upDotL > 0 ? ambientLowSun : ambientTwilight; //r8.xyw
  
  // r1.z = saturate(r5.z * 0.300000012 + 0.699999988);
  // r5.xzw = r8.xyw * r1.zzz;
  // r5.xzw = r5.xzw * r3.www;
  // r1.z = 1 + cb0[43].x;
  // r5.xzw = r5.xzw * r1.zzz;
  float3 ambientLightColor = ambientColor * saturate(nDotUp * 0.3 + 0.7);
  ambientLightColor = ambientLightColor * pow(unclamped_nDotL * 0.35 + 1, 3);
  ambientLightColor = ambientLightColor * (_AmbientInc + 1); //r5.xzw
  
  // r1.z = cmp(cb0[29].w >= 0.5);
  // r2.w = dot(cb0[29].xyz, cb0[29].xyz);
  // r2.w = sqrt(r2.w);
  // r2.w = -5 + r2.w;
  // r3.w = saturate(r2.w);
  // r6.x = dot(-v5.xyz, lightDir);
  // r6.x = saturate(5 * r6.x);
  // r3.w = r6.x * r3.w;
  // r9.xyz = -v5.xyz * r2.www + cb0[29].xyz;
  // r2.w = dot(r9.xyz, r9.xyz);
  // r2.w = sqrt(r2.w);
  // r6.x = 20 + -r2.w;
  // r6.x = 0.0500000007 * r6.x;
  // r6.x = max(0, r6.x);
  // r6.x = r6.x * r6.x;
  // r7.w = cmp(r2.w < 0.00100000005);
  // r10.xyz = float3(1.29999995,1.10000002,0.600000024) * r3.www;
  // r9.xyz = r9.xyz / r2.www;
  // r2.w = saturate(dot(r9.xyz, r3.xyz));
  // r2.w = r2.w * r6.x;
  // r2.w = r2.w * r3.w;
  // r3.xyz = float3(1.29999995,1.10000002,0.600000024) * r2.www;
  // r3.xyz = r7.www ? r10.xyz : r3.xyz;
  // r3.xyz = r1.zzz ? r3.xyz : 0;
  float3 headlampLight = calculateLightFromHeadlamp(_Global_PointLightPos, upDir, lightDir, worldNormal); //r3.xyz
  
  // r3.xyz = r4.www * r7.xyz + r3.xyz;
  // r3.xyz = r3.xyz * r2.xyz;
  float3 headlampLightColor = nDotL * lightColor + headlampLight;
  headlampLightColor = albedo * headlampLightColor; //r3.xyz
  
  // r1.z = log2(r8.z);
  // r1.z = 0.600000024 * r1.z;
  // r1.z = exp2(r1.z);
  
  // r9.xyz = float3(-1,-1,-1) + r2.xyz;
  // r9.xyz = r1.www * r9.xyz + float3(1,1,1);
  // r9.xyz = cb0[48].xyz * r9.xyz;
  // r7.xyz = r9.xyz * r7.xyz;
  // r0.w = specularTerm + 0.0318309888;
  // r7.xyz = r7.xyz * r0.www;
  // r7.xyz = r7.xyz * r4.www;
  float3 specularColor = _SpecularColor.xyz * lerp(float3(1.0, 1.0, 1.0), albedo, metallicLow);
  specularColor = specularColor * lightColor;
  float INV_TEN_PI = 0.0318309888;
  specularColor = specularColor * nDotL * (specularTerm + INV_TEN_PI); //r7.xyz
  
  // r0.w = 0.200000003 * r8.z;
  // r9.xyz = r0.www * r2.xyz + r1.www;
  // r7.xyz = r9.xyz * r7.xyz;
  float3 specColorMod = (1.0 - metallicLow) * 0.2 * albedo + metallicLow;
  specularColor = specularColor * specColorMod; //r7.xyz
  
  //r5.xzw = r5.xzw * r2.xyz; //r5.xzw
  ambientLightColor = albedo * ambientLightColor; //r5.xzw
  
  float3 ambientSpecularLight = ambientLightColor * (1.0 - metallicLow * 0.6); //r9.xyz
  float ambientSpecularLuminance = dot(ambientSpecularLight, float3(0.3, 0.6, 0.1)); //r1.x
  r5.xzw = lerp(ambientSpecularLight, ambientSpecularLuminance, float3(0.5, 0.5, 0.5)); //r5.xzw
  
  // r0.w = dot(ambientColor.xyx, float3(0.3, 0.6, 0.1));
  // r0.w = 0.00300000003 + r0.w;
  // r1.x = max(cb0[6].x, cb0[6].y);
  // r1.x = max(cb0[6].z, r1.x);
  // r1.x = 0.00300000003 + r1.x;
  float ambientLuminance = 0.003 + dot(ambientColor.xyx, float3(0.3, 0.6, 0.1)); //r0.w
  float maxAmbient = 0.003 + max(_Global_AmbientColor0.z, max(_Global_AmbientColor0.x, _Global_AmbientColor0.y)); //r1.x
  
  // r1.x = 1 / r1.x;
  // r8.xyz = r8.xyw + -r0.www;
  // r8.xyz = r8.xyz * float3(0.400000006,0.400000006,0.400000006) + r0.www;
  // r8.xyz = r8.xyz * r1.xxx;
  float3 greyedAmbient = lerp(ambientLuminance, ambientColor, float3(0.4, 0.4, 0.4)) / maxAmbient; //r8.xyz
  // r8.xyz = float3(1.70000005,1.70000005,1.70000005) * r8.xyz;
  // r6.xyz = r8.xyz * r6.yzw;
  reflectColor = reflectColor * float3(1.7, 1.7, 1.7) * greyedAmbient; //r6.xyz
  
  //r0.w = saturate(r5.y * 2 + 0.5);
  //r0.w = r0.w * 0.699999988 + 0.300000012;
  float reflectStrength = saturate(upDotL * 2.0 + 0.5) * 0.7 + 0.3; //r0.w
  //r8.xyz = r6.xyz * r0.www;
  float reflectLuminance = dot(reflectColor * reflectStrength, float3(0.3, 0.6, 0.1)); //r1.x
  reflectColor = lerp(reflectColor * reflectStrength, reflectLuminance, float3(0.8, 0.8, 0.8); //r6.xyz
  reflectColor = reflectColor * lerp(float3(1,1,1), veinColor, float3(0.8, 0.8, 0.8)); //r0.xyz
  
  float3 finalColor = headlampLightColor * pow(1.0 - metallicLow, 0.6) + specularColor + r5.xzw; //r1.xzw
  finalColor = lerp(finalColor, reflectColor * albedo, reflectivity);
  
  //r0.w = dot(r0.xyz, float3(0.3, 0.6, 0.1));
  float colorIntensity = dot(finalColor, float3(0.3, 0.6, 0.1)); //r0.w
  // r1.x = r0.w > 1.0;
  // r1.yzw = r0.xyz / r0.www;
  // r0.w = log2(r0.w);
  // r0.w = r0.w * 0.693147182 + 1;
  // r0.w = log2(r0.w);
  // r0.w = r0.w * 0.693147182 + 1;
  // r1.yzw = r1.yzw * r0.www;
  // r0.xyz = r1.xxx ? r1.yzw : r0.xyz;
  finalColor = colorIntensity > 1.0 ? (finalColor / colorIntensity) * (log(log(colorIntensity) + 1) + 1) : finalColor; //r0.xyz
  
  o.sv_target.xyz = emissionColor * _EmissionMask.xyz
    + albedo * indirectLight
    + finalColor;
  o.sv_target.w = 1;
  return;
}