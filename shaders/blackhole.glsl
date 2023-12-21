Texture2D/*<float4>*/ _AcdiskTex;

cull off
src alpha one add


void main(
  float3 v0 : TEXCOORD0,
  float4 v1 : SV_POSITION0,
  out float4 o0 : SV_Target0)
{
  float4 r0,r1,r2,r3,r4,r5,r6,r7,r8;

  float3 posToCam = _WorldSpaceCameraPos.xyz - _Position.xyz; //r0.xyz
  
  //qrot
  r1.xyz = _Rotation.zxy + _Rotation.zxy;
  r2.xyz = _Rotation.xyz * r1.yzx;
  r3.xyz = -_Rotation.www * r1.xyz;
  r2.xyz = r2.yxx + r2.zzy;
  r2.xyz = float3(1,1,1) + -r2.xyz;
  r1.yw = r2.xy * posToCam.xy;
  r0.w = _Rotation.x * r1.z + -r3.x;
  r1.y = r0.w * posToCam.y + r1.y;
  r4.xy = _Rotation.xy * r1.xx + r3.zy;
  r0.y = r4.y * posToCam.y;
  r5.x = r4.x * posToCam.z + r1.y;
  r1.y = _Rotation.x * r1.z + r3.x;
  r1.z = r1.y * posToCam.x + r1.w;
  r1.xw = _Rotation.yx * r1.xx + -r3.yz;
  r5.y = r1.x * posToCam.z + r1.z;
  r0.x = r1.w * posToCam.x + r0.y;
  r5.z = r2.z * posToCam.z + r0.x;
  float3 rotatedPosToCam = r5.xyz; //r5.xyz
  
  float3 camToVert = v0.xyz - _WorldSpaceCameraPos.xyz; // r0.xyz
  //qrot
  r2.xy = r2.xy * camToVert.xy;
  r0.w = camToVert.w * camToVert.y + r2.x;
  r0.y = r4.y * camToVert.y;
  r3.y = r4.x * camToVert.z + r0.w;
  r0.w = r1.y * camToVert.x + r2.y;
  r3.z = r1.x * camToVert.z + r0.w;
  r0.x = r1.w * camToVert.x + r0.y;
  r3.x = r2.z * camToVert.z + r0.x;
  float3 rotatedCamToVert = r3.yzx; //swizzle //r3.yzx
  
  float3 rotatedCamToVertDir = normalize(r3.xyz); //yzx //r0.xyz
  
  r0.w = max(0, dot(-rotatedPosToCam.zxy, rotatedCamToVertDir.yzx));
  r1.xyz = _AcdiskRadius < r0.w ? rotatedCamToVertDir.zxy * (r0.w - _AcdiskRadius) + rotatedPosToCam.xyz : rotatedPosToCam.xyz;
  
  r0.w = rotatedCamToVertDir.x < -0.00002 || rotatedCamToVertDir.x > 0.00002 ? -r1.y / rotatedCamToVertDir.x : 0;
  
  r2.y = r0.w > 0;
  
  if (r0.w > 0.00002) {
    r2.x = rotatedCamToVertDir.z * r0.w + r1.x;
    r2.z = rotatedCamToVertDir.y * r0.w + r1.z;
    
    float unkLenByDiskRadius = length(r2.xz) / _AcdiskRadius; //r3.z
    
    if (unkLenByDiskRadius < 1.3) {
      float horzDiskRatio = _EventHorzRadius / _AcdiskRadius; //r1.w
      
      if (unkLenByDiskRadius >= horzDiskRatio) {
      
        r2.w = min(abs(r2.x), abs(r2.z)) / max(abs(r2.x), abs(r2.z));
        
        r3.w = pow(r2.w, 2.0);
        r3.w = r3.w * (r3.w * (r3.w * (r3.w * 0.0208351 - 0.085133) + 0.180141) - 0.3302995) + 0.999866;
        
        r4.x = abs(r2.z) < abs(r2.x) ? r2.w * r3.w * -2.0 + UNITY_HALF_PI : 0;
        r2.w = r2.w * r3.w + r4.x;
        r3.w = r2.z < -r2.z ? r2.w - UNITY_PI : r2.w;
        
        r4.x = min(r2.x, r2.z);
        r4.y = max(r2.x, r2.z);
        
        r4.x = r4.y >= -r4.y ? r4.x < -r4.x : 0;
        r3.w = r4.x ? -r3.w : r3.w;
        r3.y = UNITY_INV_PI * r3.w;
        
        r3.w = -r2.z < r2.z ? -UNITY_PI : 0;
        r2.w = r3.w + r2.w;
        
        r3.w = min(-r2.x, -r2.z);
        r2.x = max(-r2.x, -r2.z);
        
        r2.x = r2.x >= -r2.x ? r3.w < -r3.w : 0;
        r2.x = r2.x ? -r2.w : r2.w;
        r3.x = UNITY_INV_PI * r2.x;
        
        r2.x = saturate(r2.z * 20 + 0.5);
        
        r2.w = saturate(80.0 * ( (unkLenByDiskRadius - horzDiskRatio) / horzDiskRatio));
        
        float animStep = frac(3.0 * _Time.x * _RotateSpeed); //r4.x
        float animStepOpposite frac(3.0 * _Time.x * _RotateSpeed + 0.5);
        
        r5.x = (animStep / 3.0 + _Whirl) / pow(max(unkLenByDiskRadius, horzDiskRatio), 0.7);
        
        r6.x = r5.x + r3.y;
        r6.y = unkLenByDiskRadius;
        
        r6.z = r5.x + r3.x;
        r6.w = unkLenByDiskRadius;
        
        r7.xyzw = r2.x * _AcdiskTex.Sample(s0_s, r6.xy).xyzw;
        r6.xyzw = (1.0 - r2.x) * _AcdiskTex.Sample(s0_s, r6.zw).xyzw;
        
        r5.z = (animStepOpposite / 3.0 + _Whirl) / pow(max(unkLenByDiskRadius, horzDiskRatio), 0.7);
                
        r3.x = r5.z + r3.y;
        r3.y = unkLenByDiskRadius;
        
        r3.z = r5.z + r3.x;
        r3.w = unkLenByDiskRadius;
        
        r5.xyzw = r2.x * _AcdiskTex.Sample(s0_s, r3.xy).xyzw;
        r3.xyzw = (1.0 - r2.x) * _AcdiskTex.Sample(s0_s, r3.zw).xyzw;
        
        r4.x = 2.0 * abs(animStep - 0.5);
        r5.xyzw = lerp(r7.xyzw, r5.xyzw, r4.x);
        r3.xyzw = lerp(r6.xyzw, r3.xyzw, r4.x);
        r3.xyzw = r5.xyzw + r3.xyzw;
        
        r1.w = saturate(1.0 - ( (unkLenByDiskRadius - horzDiskRatio) / (1.0 - horzDiskRatio)));
        r1.w = pow(r1.w, _AcdiskAtten);
        
        r3.xyzw = r3.xyzw * r1.w * r2.w;
      } else {
        r3.xyzw = float4(0,0,0,0);
      }
    } else {
      r3.xyzw = float4(0,0,0,0);
    }
  } else {
    r3.xyzw = float4(0,0,0,0);
  }
  
  r1.w = max(0, dot(-r1.zxy, rotatedCamToVertDir.yzx));
  r2.z = _EventHorzRadius * pow(r1.w / _EventHorzRadius, 1.8)
  r1.w = r1.w < _EventHorzRadius ? r2.z : r1.w;
  
  r2.xzw = rotatedCamToVertDir.yzx * r1.www + r1.zxy;
  //r4.x = dot(r2.xzw, r2.xzw);
  r4.y = length(r2.xzw);
  
  r5.xyz = rotatedCamToVertDir.xyz * -r1.zxy - (-r1.yzx * rotatedCamToVertDir.yzx);
  r5.xyz = normalize(r5.xyz);
  
  r4.z = rsqrt(dot(float2(-1,1) * r5.zx, float2(-1,1) * r5.zx));
  
  r6.x = 0;
  r6.y = r5.x * r4.z;
  r6.z = -r5.z * r4.z;
  
  r7.xyz = r2.wxz * r6.yzx - r6.xyz * r2.xzw;
  
  r4.z = dot(r5.xyz, r7.xyz);
  r4.w = cmp(r4.z > 0);
  r4.z = cmp(r4.z < 0);
  r4.z = (int)r4.z - (int)r4.w;
  r4.z = (int)r4.z;
  
  r4.zw = r6.zy * r4.yy * r4.zz;
  
  r4.x = rsqrt(dot(r2.xzw, r2.xzw));
  r6.xy = r4.xx * r2.zx;
  //normalize(r2.xzw).yx ?
  
  r4.xz = normalize(r4.zw);
  
  r4.x = dot(r6.xy, r4.xz);
  r4.z = sqrt(1.0 - abs(r4.x));
  r4.w = ((abs(r4.x) * -0.0187293 + 0.074261) * abs(r4.x) - 0.2121144) * abs(r4.x) + 1.5707288;
  
  r4.x = r4.x < -r4.x ? (r4.w * r4.z) * -2.0 + UNITY_PI : 0;
  r4.x = r4.w * r4.z + r4.x;
  
  r1.x = length(r1.xyz) / _EventHorzRadius;
  r1.x = max(0, 1.0 - pow(r1.x, 2.0));
  
  r1.y = _EventHorzRadius / max(_EventHorzRadius, r4.y);
  r1.y = 1.011 * (pow(r1.y, _LightCurve) - 0.01);
  
  r1.x = 0.5 * r4.x * min(max(0, r1.y), r1.x * 0.015 + 0.99);
  
  r4.x = cos(r1.x);
  
  r5.x = r5.x * sin(r1.x);
  r5.y = r5.z * sin(r1.x);
  r5.z = r5.x * sin(r1.x);
  r5.w = r5.y * sin(r1.x);
  
  r6.x = 2.0 * r5.z;
  r6.y = 2.0 * r5.y;
  r6.z = 2.0 * r5.w;
  r6.w = 2.0 * r5.y;
  
  r1.x = 2.0 * r5.z * r5.x;
  r1.y = 2.0 * r5.y * r5.y;
  r4.y = 2.0 * r5.z * r4.x;
  r4.z = 2.0 * r5.y * r4.x;
  r1.z = r5.z * 2.0 * r5.w + r4.z;
  r5.y = r5.w * 2.0 * r5.y - r4.y;
  r5.x = r5.y * r2.x + r1.z * r2.z + (1 - r1.x - r1.y) * r2.w;
  
  r1.z = r5.y * rotatedCamToVertDir.y + r1.z * rotatedCamToVertDir.z + (1 - r1.x - r1.y) * rotatedCamToVertDir.x;
  
  r4.w = cmp(r1.z < -0.00002);
  r5.y = cmp(r1.z > 0.00002);
  r4.w = (int)r4.w | (int)r5.y;
  r1.z = r4.w ? -r5.x / r1.z : 0;
  
  if (0.00002 < r1.z) {
    r4.x = r6.z * r4.x;
    
    r1.xy = float2(1,1) - (r5.ww * r6.zz + r1.yx);
    
    r4.w = r1.x * r2.z;
    r4.z = r5.z * r6.z - r4.z;
    r4.w = r4.z * r2.w + r4.w;
    r5.x = r5.z * r6.w + r4.x;
    r6.x = r5.x * r2.x + r4.w;
    r4.x = r5.z * r6.w - r4.x;
    r4.y = r5.w * r6.w + r4.y;
    r2.w = r4.y * r2.w;
    r2.z = r4.x * r2.z + r2.w;
    r6.y = r1.y * r2.x + r2.z;
    r1.x = r1.x * rotatedCamToVertDir.z;
    r1.x = r4.z * rotatedCamToVertDir.x + r1.x;
    r5.x = r5.x * rotatedCamToVertDir.y + r1.x;
    r0.z = r4.y * rotatedCamToVertDir.x;
    r0.y = r4.x * rotatedCamToVertDir.z + r0.z;
    r5.y = r1.y * rotatedCamToVertDir.y + r0.y;
    r0.xy = r5.xy * r1.zz + r6.xy;
    
    r1.z = length(r0.xy) / _AcdiskRadius;
    if (r1.z <= 1.3) {
      r0.z = _EventHorzRadius / _AcdiskRadius;
      
      if (r1.z >= r0.z) {
        r2.x = min(abs(r0.x), abs(r0.y));
        r2.z = max(abs(r0.x), abs(r0.y));
        
        r2.x = r2.x / r2.z;
        r2.z = pow(r2.x, 2);
        
        r2.z = r2.z * (r2.z * (r2.z * (r2.z * 0.0208350997 - 0.0851330012) + 0.180141002) - 0.330299497) + 0.999866;
        
        r2.w = abs(r0.y) < abs(r0.x) ? r2.x * r2.z * -2.0 + UNITY_HALF_PI : 0;
        
        r2.x = r2.x * r2.z + r2.w;
        r2.z = r0.y < -r0.y ? r2.x - UNITY_PI : r2.x;
        
        r2.w = min(r0.x, r0.y);
        r4.x = max(r0.x, r0.y);
        r2.w = cmp(r2.w < -r2.w);
        r4.x = cmp(r4.x >= -r4.x);
        r2.w = r2.w ? r4.x : 0;
        r2.z = r2.w ? -r2.z : r2.z;
        r1.y = UNITY_INV_PI * r2.z;
        
        r2.z = -r0.y < r0.y ? -UNITY_PI : 0;
        r2.x = r2.x + r2.z;
        r2.z = min(-r0.x, -r0.y);
        r0.x = max(-r0.x, -r0.y);
        r2.z = cmp(r2.z < -r2.z);
        r0.x = cmp(r0.x >= -r0.x);
        r0.x = r0.x ? r2.z : 0;
        r0.x = r0.x ? -r2.x : r2.x;
        r1.x = UNITY_INV_PI * r0.x;
        
        r0.x = saturate(r0.y * 20 + 0.5);
        
        r0.y = r1.z - r0.z;
        r2.x = saturate(80 * (r0.y / r0.z));
        
        r4.x = frac(3.0 * _Time.x * _RotateSpeed) / 3.0 + _Whirl;
        r2.z = frac(3.0 * _Time.x * _RotateSpeed + 0.5) / 3.0 + _Whirl;
        r2.w = 2.0 * abs(frac(3.0 * _Time.x * _RotateSpeed) - 0.5);
        
        r4.y = 1.0 / pow(max(r1.z, r0.z), 0.7);
        
        r5.x = r4.x * r4.y;
        r5.yw = float2(0,0);
        r6.xy = r5.xy + r1.yz;
        r6.zw = r5.xy + r1.xz;
        
        r7.xyzw = r0.x * _AcdiskTex.Sample(s0_s, r6.xy).xyzw;
        r6.xyzw = (1 - r0.x) * _AcdiskTex.Sample(s0_s, r6.zw).xyzw;
        
        r5.z = r4.y * r2.z;
        r5.xy = r5.zw + r1.yz;
        r5.zw = r5.zw + r1.xz;
        
        r8.xyzw = r0.x * _AcdiskTex.Sample(s0_s, r5.xy).xyzw;
        r5.xyzw = (1 - r0.x) * _AcdiskTex.Sample(s0_s, r5.zw).xyzw;
        
        r7.xyzw = lerp(r7.xyzw, r8.xyzw, r2.w);
        r4.xyzw = lerp(r6.xyzw, r5.xyzw, r2.w);
        r4.xyzw = r7.xyzw + r4.xyzw;
        
        r0.x = saturate(1.0 - (r0.y / (1.0 - r0.z)));
        r0.x = pow(r0.x, _AcdiskAtten);
        
        r4.xyzw = r4.xyzw * r0.x * r2.x;
        
      } else {
        r4.xyzw = float4(0,0,0,0);
      }
    } else {
      r4.xyzw = float4(0,0,0,0);
    }
  } else {
    r4.xyzw = float4(0,0,0,0);
  }
  
  r0.x = r0.w < r1.w ? r2.y : 0;
  r0.xyzw = r0.w < r1.w ? max(r4.xyzw, r3.xyzw) : r4.xyzw;
  
  o0.xyz = _Color.xyz * _Multiplier * r0.xyz;
  o0.w = saturate(r0.w);
  
  return;
}
