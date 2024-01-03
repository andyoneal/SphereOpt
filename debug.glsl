v0 = SV_POSITION (1157.50, 1350.50, 0.0223, 26.89876)
v1 = TBNW0 (-0.60563, 0.38956, 0.60739, 106.1024)
v2 = TBNW1 (-0.51627, 0.42874, -0.72515, 62.37029)
v3 = TBNW2 (-0.60167, -0.76879, -0.10055, -164.57939)
v4 = worldSpherePos (105.09829, 63.22248, -164.16367)
v4.w = WL = 33.00
v5.x = time = 1.39999
v5.y = state = 1.00
v5.z = unk = 1116.00
v6 = vertPos (-2.29182, 5.29324, -1.1888)
v7 = worldPos = (106.1024, 62.37029, -164.57939)
v7.w = animTime = 0.69999 // worldpos + animtime
v8 = worldNormal = (0.60739, -0.72515, -0.10055)
v9 = clippos?? = (-10.68246, -6.73715, 0.5999, 26.89875)
v10 = o10 = (-0.40467, 0.65297, 0.97152)
v11 and v12 are all 0s

_WorldSpaceCameraPos = (126.47839, 55.63731, -182.06929, 0.00)

_RimThickness = 0.6
_RimSoftness = 1.2
.z = 1
.w = 1

_SpherePos = (-2.90, 4.70, -0.10, 2.67)

_SphereThickness 0.07
??.yzw = 0.00, 0.00, 0.20

VTX 190

r0.xyz = cmp(float3(4,2,1.5) < i.vertPos.yxz);
r0.z = r0.z ? 2 : 3;
r0.y = r0.y ? 5 : r0.z;
r0.y = r0.x ? 0 : r0.y;
//0
r0.z = (uint)r0.y;
//0
r0.w = 0.5 + r0.z;
r1.y = 0.0625 * r0.w;
r1.x = v4.w * 0.001953125 + 0.0009765625;
r1.xyz = t0.SampleLevel(s3_s, r1.xy, 0).xyz;
//0.19141, 0.15625, 0.16797

r0.w = dot(v4.xyz, v4.xyz); //dot(worldSpherePos, worldSpherePos)
r0.w = rsqrt(r0.w);
r2.xyz = v4.xyz * r0.www; //normalize(worldSpherePos)
//r2.xyz = (0.512873, 0.308522, -0.801109)

r3.xyz = float3(0.5,0.5,-0.5) * v9.xwy;
r3.xy = r3.xz + r3.yy;
//r3.xyz = 8.10814, 16.81796, 3.36858


r4.xyz = -cb1[4].xyz + v7.xyz; //worldpos - _WorldSpaceCameraPos
r0.w = dot(r4.xyz, r4.xyz);
r0.w = sqrt(r0.w); //length(worldpos - _WorldSpaceCameraPos) //distance
//27.68412
r4.xyz = r4.xyz / r0.www; //normalize(worldpos - _WorldSpaceCameraPos)
// (-0.73602, 0.24321, 0.63177)

//scaledByDistFromCam
r1.w = 0.05 * r0.w; //length(camToPos) / 20
r1.w = max(1, r1.w);
r1.w = log2(r1.w);
r1.w = 0.200000003 * r1.w;
r1.w = exp2(r1.w);
r1.w = min(1.60000002, r1.w);
//1.06719

if (r0.x != 0) {
    r2.w = 0.5 * _SpherePos.w;
    //1.335
    r3.z = -cb0[51].x * 0.5 + r2.w; // (0.5 * _SpherePos.w) - (_SphereThickness * 0.5)
    //1.3
    r5.xyz = -cb1[4].xyz + v4.xyz; // worldSpherePos - _WorldSpaceCameraPos
    //-21.3801, 7.58517, 17.90562
    r3.w = dot(r4.xyz, r5.xyz); // dot(camToPosDir, rayCamToSpherePos)
    //28.89306

    r5.xyz = r4.xyz * r3.www + cb1[4].xyz; // camToPosDir * dot(camToPosDir, rayCamToSpherePos) + _WorldSpaceCameraPos
    r5.xyz = -v4.xyz + r5.xyz; // camToPosDir * dot(camToPosDir, rayCamToSpherePos) + _WorldSpaceCameraPos - worldSpherePos
    //0.1143, -0.55816, 0.34805
    r4.w = dot(r5.xyz, r5.xyz);
    r4.w = sqrt(r4.w); //viewedDistFromCenter = distance(camToSpherePos, projSpherePosOnPos)
    //0.66765
    
    r4.w = r2.w < r4.w ? r2.w : r4.w; // viewedDistFromCenter = outerSphereRadius < viewedDistFromCenter ? outerSphereRadius : viewedDistFromCenter
    // 0.66765
    r5.x = cb0[50].w * 0.5 + -r4.w; //  outerSphereRadius - viewedDistFromCenter
    r0.w = 800 / r0.w; //
    r0.w = saturate(r5.x * r0.w);
    // 1.0
    
    r5.x = r4.w * r4.w; //viewedDistFromCenter^2
    //0.44575
    r2.w = r2.w * r2.w + -r5.x; // outerSphereRadius^2 - viewedDistFromCenter^2
    r2.w = 9.99999975e-05 + r2.w; // plus sigma
    r2.w = sqrt(r2.w); // a = sqrt(0.00001 + c^2 - b^2)
    //1.1561

    //r5.x = r3.z < r4.w;
    // 0.0
    r4.w = r3.z < r4.w ? r3.z : r4.w;
    r4.w = r4.w * r4.w;
    r4.w = r3.z * r3.z + -r4.w;
    r4.w = 9.99999975e-05 + r4.w;
    r4.w = sqrt(r4.w);
    // 1.1155
    
    r5.x = r3.w + -r2.w; // dot(camToPosDir, rayCamToSpherePos) - outerSphereRadiusOffset
    // 27.73696
    r5.yzw = r5.xxx * r4.xyz; // dot(camToPosDir, rayCamToSpherePos) - outerSphereRadiusOffset * normalize(worldpos - _WorldSpaceCameraPos)
    // -20.41488, 6.74583, 17.52328
    r6.xyz = r4.xyz * r5.xxx + cb1[4].xyz; // _WorldSpaceCameraPos + dot(camToPosDir, rayCamToSpherePos) - outerSphereRadiusOffset * normalize(worldpos - _WorldSpaceCameraPos)
    // 106.06351, 62.38314, -164.54601
    
    r3.w = -r4.w + r3.w; // dot(camToPosDir, rayCamToSpherePos) - inner...
    r7.xyz = r4.xyz * r3.www + cb1[4].xyz;
    // 106.03362, 62.39302, -164.52036
    
    r3.w = dot(r5.yzw, r5.yzw);
    r3.w = sqrt(r3.w);
    // 27.73696
    r5.xyz = r5.yzw / r3.www;
    // -0.73602, 0.24321, 0.63177
    
    r8.w = r2.w + r2.w;
    //2.31221
    r2.w = r4.w + r4.w;
    //2.23101

    r6.xyz = -v4.xyz + r6.xyz;
    // 0.96522, -0.83934, -0.38234
    r7.xyz = -v4.xyz + r7.xyz;
    // 0.93533, -0.82946, -0.35669
    
    r9.xyz = float3(0,1,0) * r2.yzx;
    r9.xyz = r2.xyz * float3(1,0,0) + -r9.xyz;
    r3.w = dot(r9.xy, r9.xy);
    r3.w = rsqrt(r3.w);
    //1.05128
    r9.xyz = r9.xyz * r3.www;
    //0.53918, 0.84219, 0.00
    r10.xyz = r9.xyz * r2.yzx;
    r10.xyz = r9.zxy * r2.zxy + -r10.xyz;
    //-0.16635, 0.95122, 0.25984
    r8.x = dot(r7.zx, r9.xy);
    //0.59541
    r8.y = dot(r7.xyz, r2.xyz);
    //0.50955
    r8.z = dot(r7.xyz, r10.xyz);
    //-1.03727

    r7.x = dot(r5.zx, r9.xy);
    //-0.27924
    r7.y = dot(r5.xyz, r2.xyz);
    //-0.80856
    r7.z = dot(r5.xyz, r10.xyz);
    //0.51793
    
    
