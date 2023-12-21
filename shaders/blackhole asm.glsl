
Texture2D<float4> t0 : register(t0);

SamplerState s0_s : register(s0);

cbuffer cb1 : register(b1)
{
  float4 cb1[5];
}

cbuffer cb0 : register(b0)
{
  float4 cb0[8];
}


void main(
  float3 v0 : TEXCOORD0,
  float4 v1 : SV_POSITION0,
  out float4 o0 : SV_Target0)
{
  float4 r0,r1,r2,r3,r4,r5,r6,r7,r8;
  uint4 bitmask, uiDest;
  float4 fDest;

  r0.xyz = cb1[4].xyz + -cb0[6].xyz;
  r1.xyz = cb0[7].zxy + cb0[7].zxy;
  r2.xyz = cb0[7].xyz * r1.yzx;
  r3.xyz = -cb0[7].www * r1.xyz;
  r2.xyz = r2.yxx + r2.zzy;
  r2.xyz = float3(1,1,1) + -r2.xyz;
  r1.yw = r2.xy * r0.xy;
  r0.w = cb0[7].x * r1.z + -r3.x;
  r1.y = r0.w * r0.y + r1.y;
  r4.xy = cb0[7].xy * r1.xx + r3.zy;
  r0.y = r4.y * r0.y;
  r5.x = r4.x * r0.z + r1.y;
  r1.y = cb0[7].x * r1.z + r3.x;
  r1.z = r1.y * r0.x + r1.w;
  r1.xw = cb0[7].yx * r1.xx + -r3.yz;
  r5.y = r1.x * r0.z + r1.z;
  r0.x = r1.w * r0.x + r0.y;
  r5.z = r2.z * r0.z + r0.x;
  r0.xyz = -cb1[4].xyz + v0.xyz;
  r2.xy = r2.xy * r0.xy;
  r0.w = r0.w * r0.y + r2.x;
  r0.y = r4.y * r0.y;
  r3.y = r4.x * r0.z + r0.w;
  r0.w = r1.y * r0.x + r2.y;
  r3.z = r1.x * r0.z + r0.w;
  r0.x = r1.w * r0.x + r0.y;
  r3.x = r2.z * r0.z + r0.x;
  r0.x = dot(r3.xyz, r3.xyz);
  r0.x = rsqrt(r0.x);
  r0.xyz = r3.xyz * r0.xxx;
  r0.w = dot(-r5.zxy, r0.xyz);
  r0.w = max(0, r0.w);
  r1.x = cmp(cb0[4].y < r0.w);
  r0.w = -cb0[4].y + r0.w;
  r1.yzw = r0.yzx * r0.www + r5.xyz;
  r1.xyz = r1.xxx ? r1.yzw : r5.xyz;
  r0.w = cmp(r0.z < -1.99999995e-05);
  r1.w = cmp(1.99999995e-05 < r0.z);
  r0.w = (int)r0.w | (int)r1.w;
  r1.w = -r1.y / r0.z;
  r0.w = r0.w ? r1.w : 0;
  r2.xy = cmp(float2(1.99999995e-05,0) < r0.ww);
  if (r2.x != 0) {
    r2.xz = r0.yx * r0.ww + r1.xz;
    r1.w = dot(r2.xz, r2.xz);
    r1.w = sqrt(r1.w);
    r3.z = r1.w / cb0[4].y;
    r1.w = cmp(1.29999995 >= r3.z);
    if (r1.w != 0) {
      r1.w = cb0[4].x / cb0[4].y;
      r2.w = cmp(r3.z >= r1.w);
      if (r2.w != 0) {
        r2.w = min(abs(r2.x), abs(r2.z));
        r3.w = max(abs(r2.x), abs(r2.z));
        r3.w = 1 / r3.w;
        r2.w = r3.w * r2.w;
        r3.w = r2.w * r2.w;
        r4.x = r3.w * 0.0208350997 + -0.0851330012;
        r4.x = r3.w * r4.x + 0.180141002;
        r4.x = r3.w * r4.x + -0.330299497;
        r3.w = r3.w * r4.x + 0.999866009;
        r4.x = r3.w * r2.w;
        r4.y = cmp(abs(r2.z) < abs(r2.x));
        r4.x = r4.x * -2 + 1.57079637;
        r4.x = r4.y ? r4.x : 0;
        r2.w = r2.w * r3.w + r4.x;
        r3.w = cmp(r2.z < -r2.z);
        r3.w = r3.w ? -3.141593 : 0;
        r3.w = r3.w + r2.w;
        r4.x = min(r2.x, r2.z);
        r4.y = max(r2.x, r2.z);
        r4.x = cmp(r4.x < -r4.x);
        r4.y = cmp(r4.y >= -r4.y);
        r4.x = r4.y ? r4.x : 0;
        r3.w = r4.x ? -r3.w : r3.w;
        r3.y = 0.318309873 * r3.w;
        r3.w = cmp(-r2.z < r2.z);
        r3.w = r3.w ? -3.141593 : 0;
        r2.w = r3.w + r2.w;
        r3.w = min(-r2.x, -r2.z);
        r2.x = max(-r2.x, -r2.z);
        r3.w = cmp(r3.w < -r3.w);
        r2.x = cmp(r2.x >= -r2.x);
        r2.x = r2.x ? r3.w : 0;
        r2.x = r2.x ? -r2.w : r2.w;
        r3.x = 0.318309873 * r2.x;
        r2.x = saturate(r2.z * 20 + 0.5);
        r2.z = r3.z + -r1.w;
        r2.w = r2.z / r1.w;
        r2.w = saturate(80 * r2.w);
        r3.w = cb1[0].x * cb0[5].x;
        r4.x = 3 * r3.w;
        r4.x = frac(r4.x);
        r4.y = r4.x * 0.333333343 + cb0[5].y;
        r3.w = r3.w * 3 + 0.5;
        r3.w = frac(r3.w);
        r3.w = r3.w * 0.333333343 + cb0[5].y;
        r4.x = -0.5 + r4.x;
        r4.x = abs(r4.x) + abs(r4.x);
        r4.z = max(r3.z, r1.w);
        r4.z = log2(r4.z);
        r4.z = -0.699999988 * r4.z;
        r4.z = exp2(r4.z);
        r5.x = r4.y * r4.z;
        r5.yw = float2(0,0);
        r6.xyzw = r5.xyxy + r3.yzxz;
        r7.xyzw = t0.Sample(s0_s, r6.xy).xyzw;
        r7.xyzw = r7.xyzw * r2.xxxx;
        r6.xyzw = t0.Sample(s0_s, r6.zw).xyzw;
        r4.y = 1 + -r2.x;
        r6.xyzw = r6.xyzw * r4.yyyy;
        r5.z = r4.z * r3.w;
        r3.xyzw = r5.zwzw + r3.yzxz;
        r5.xyzw = t0.Sample(s0_s, r3.xy).xyzw;
        r3.xyzw = t0.Sample(s0_s, r3.zw).xyzw;
        r5.xyzw = r5.xyzw * r2.xxxx + -r7.xyzw;
        r5.xyzw = r4.xxxx * r5.xyzw + r7.xyzw;
        r3.xyzw = r3.xyzw * r4.yyyy + -r6.xyzw;
        r3.xyzw = r4.xxxx * r3.xyzw + r6.xyzw;
        r3.xyzw = r5.xyzw + r3.xyzw;
        r1.w = 1 + -r1.w;
        r1.w = r2.z / r1.w;
        r1.w = saturate(1 + -r1.w);
        r1.w = log2(r1.w);
        r1.w = cb0[4].z * r1.w;
        r1.w = exp2(r1.w);
        r3.xyzw = r3.xyzw * r1.wwww;
        r3.xyzw = r3.xyzw * r2.wwww;
      } else {
        r3.xyzw = float4(0,0,0,0);
      }
    } else {
      r3.xyzw = float4(0,0,0,0);
    }
  } else {
    r3.xyzw = float4(0,0,0,0);
  }
  r1.w = dot(-r1.zxy, r0.xyz);
  r1.w = max(0, r1.w);
  r2.x = cmp(r1.w < cb0[4].x);
  r2.z = r1.w / cb0[4].x;
  r2.z = log2(r2.z);
  r2.z = 1.79999995 * r2.z;
  r2.z = exp2(r2.z);
  r2.z = cb0[4].x * r2.z;
  r1.w = r2.x ? r2.z : r1.w;
  r2.xzw = r0.xyz * r1.www + r1.zxy;
  r4.x = dot(r2.xzw, r2.xzw);
  r4.y = sqrt(r4.x);
  r5.xyz = -r1.yzx * r0.xyz;
  r5.xyz = r0.zxy * -r1.zxy + -r5.xyz;
  r4.z = dot(r5.xyz, r5.xyz);
  r4.z = rsqrt(r4.z);
  r5.xyz = r5.xyz * r4.zzz;
  r5.w = -r5.z;
  r4.zw = float2(-1,1) * r5.zx;
  r4.z = dot(r5.wx, r4.zw);
  r4.z = rsqrt(r4.z);
  r6.z = -r5.z * r4.z;
  r6.x = 0;
  r6.y = r5.x * r4.z;
  r7.xyz = r6.xyz * r2.xzw;
  r7.xyz = r2.wxz * r6.yzx + -r7.xyz;
  r4.z = dot(r5.xyz, r7.xyz);
  r4.w = cmp(0 < r4.z);
  r4.z = cmp(r4.z < 0);
  r4.z = (int)-r4.w + (int)r4.z;
  r4.z = (int)r4.z;
  r6.xy = r6.zy * r4.yy;
  r4.zw = r6.xy * r4.zz;
  r4.x = rsqrt(r4.x);
  r6.xy = r4.xx * r2.zx;
  r4.x = dot(r4.zw, r4.zw);
  r4.x = rsqrt(r4.x);
  r4.xz = r4.zw * r4.xx;
  r4.x = dot(r6.xy, r4.xz);
  r4.z = 1 + -abs(r4.x);
  r4.z = sqrt(r4.z);
  r4.w = abs(r4.x) * -0.0187292993 + 0.0742610022;
  r4.w = r4.w * abs(r4.x) + -0.212114394;
  r4.w = r4.w * abs(r4.x) + 1.57072878;
  r5.w = r4.w * r4.z;
  r5.w = r5.w * -2 + 3.14159274;
  r4.x = cmp(r4.x < -r4.x);
  r4.x = r4.x ? r5.w : 0;
  r4.x = r4.w * r4.z + r4.x;
  r1.x = dot(r1.xyz, r1.xyz);
  r1.x = sqrt(r1.x);
  r1.x = r1.x / cb0[4].x;
  r1.x = -r1.x * r1.x + 1;
  r1.x = max(0, r1.x);
  r1.y = max(cb0[4].x, r4.y);
  r1.y = cb0[4].x / r1.y;
  r1.y = log2(r1.y);
  r1.y = cb0[4].w * r1.y;
  r1.y = exp2(r1.y);
  r1.y = -0.00999999978 + r1.y;
  r1.y = 1.01100004 * r1.y;
  r1.x = r1.x * 0.0149999997 + 0.99000001;
  r1.y = max(0, r1.y);
  r1.x = min(r1.y, r1.x);
  r1.x = r4.x * r1.x;
  r1.x = 0.5 * r1.x;
  sincos(r1.x, r1.x, r4.x);
  r5.xyzw = r5.xzxy * r1.xxxx;
  r6.xyzw = r5.zywy + r5.zywy;
  r1.xy = r6.xy * r5.xy;
  r4.yz = r6.xw * r4.xx;
  r1.z = r5.z * r6.z + r4.z;
  r4.w = r1.x + r1.y;
  r4.w = 1 + -r4.w;
  r5.x = r4.w * r2.w;
  r5.x = r1.z * r2.z + r5.x;
  r5.y = r5.w * r6.w + -r4.y;
  r5.x = r5.y * r2.x + r5.x;
  r4.w = r4.w * r0.z;
  r1.z = r1.z * r0.y + r4.w;
  r1.z = r5.y * r0.x + r1.z;
  r4.w = cmp(r1.z < -1.99999995e-05);
  r5.y = cmp(1.99999995e-05 < r1.z);
  r4.w = (int)r4.w | (int)r5.y;
  r1.z = -r5.x / r1.z;
  r1.z = r4.w ? r1.z : 0;
  r4.w = cmp(1.99999995e-05 < r1.z);
  if (r4.w != 0) {
    r4.x = r6.z * r4.x;
    r1.xy = r5.ww * r6.zz + r1.yx;
    r1.xy = float2(1,1) + -r1.xy;
    r4.w = r1.x * r2.z;
    r4.z = r5.z * r6.z + -r4.z;
    r4.w = r4.z * r2.w + r4.w;
    r5.x = r5.z * r6.w + r4.x;
    r6.x = r5.x * r2.x + r4.w;
    r4.x = r5.z * r6.w + -r4.x;
    r4.y = r5.w * r6.w + r4.y;
    r2.w = r4.y * r2.w;
    r2.z = r4.x * r2.z + r2.w;
    r6.y = r1.y * r2.x + r2.z;
    r1.x = r1.x * r0.y;
    r1.x = r4.z * r0.z + r1.x;
    r5.x = r5.x * r0.x + r1.x;
    r0.z = r4.y * r0.z;
    r0.y = r4.x * r0.y + r0.z;
    r5.y = r1.y * r0.x + r0.y;
    r0.xy = r5.xy * r1.zz + r6.xy;
    r0.z = dot(r0.xy, r0.xy);
    r0.z = sqrt(r0.z);
    r1.z = r0.z / cb0[4].y;
    r0.z = cmp(1.29999995 >= r1.z);
    if (r0.z != 0) {
      r0.z = cb0[4].x / cb0[4].y;
      r2.x = cmp(r1.z >= r0.z);
      if (r2.x != 0) {
        r2.x = min(abs(r0.x), abs(r0.y));
        r2.z = max(abs(r0.x), abs(r0.y));
        r2.z = 1 / r2.z;
        r2.x = r2.x * r2.z;
        r2.z = r2.x * r2.x;
        r2.w = r2.z * 0.0208350997 + -0.0851330012;
        r2.w = r2.z * r2.w + 0.180141002;
        r2.w = r2.z * r2.w + -0.330299497;
        r2.z = r2.z * r2.w + 0.999866009;
        r2.w = r2.x * r2.z;
        r4.x = cmp(abs(r0.y) < abs(r0.x));
        r2.w = r2.w * -2 + 1.57079637;
        r2.w = r4.x ? r2.w : 0;
        r2.x = r2.x * r2.z + r2.w;
        r2.z = cmp(r0.y < -r0.y);
        r2.z = r2.z ? -3.141593 : 0;
        r2.z = r2.x + r2.z;
        r2.w = min(r0.x, r0.y);
        r4.x = max(r0.x, r0.y);
        r2.w = cmp(r2.w < -r2.w);
        r4.x = cmp(r4.x >= -r4.x);
        r2.w = r2.w ? r4.x : 0;
        r2.z = r2.w ? -r2.z : r2.z;
        r1.y = 0.318309873 * r2.z;
        r2.z = cmp(-r0.y < r0.y);
        r2.z = r2.z ? -3.141593 : 0;
        r2.x = r2.x + r2.z;
        r2.z = min(-r0.x, -r0.y);
        r0.x = max(-r0.x, -r0.y);
        r2.z = cmp(r2.z < -r2.z);
        r0.x = cmp(r0.x >= -r0.x);
        r0.x = r0.x ? r2.z : 0;
        r0.x = r0.x ? -r2.x : r2.x;
        r1.x = 0.318309873 * r0.x;
        r0.x = saturate(r0.y * 20 + 0.5);
        r0.y = r1.z + -r0.z;
        r2.x = r0.y / r0.z;
        r2.x = saturate(80 * r2.x);
        r2.z = cb1[0].x * cb0[5].x;
        r2.w = 3 * r2.z;
        r2.w = frac(r2.w);
        r4.x = r2.w * 0.333333343 + cb0[5].y;
        r2.z = r2.z * 3 + 0.5;
        r2.z = frac(r2.z);
        r2.z = r2.z * 0.333333343 + cb0[5].y;
        r2.w = -0.5 + r2.w;
        r2.w = abs(r2.w) + abs(r2.w);
        r4.y = max(r1.z, r0.z);
        r4.y = log2(r4.y);
        r4.y = -0.699999988 * r4.y;
        r4.y = exp2(r4.y);
        r5.x = r4.x * r4.y;
        r5.yw = float2(0,0);
        r6.xyzw = r5.xyxy + r1.yzxz;
        r7.xyzw = t0.Sample(s0_s, r6.xy).xyzw;
        r7.xyzw = r7.xyzw * r0.xxxx;
        r6.xyzw = t0.Sample(s0_s, r6.zw).xyzw;
        r4.x = 1 + -r0.x;
        r6.xyzw = r6.xyzw * r4.xxxx;
        r5.z = r4.y * r2.z;
        r5.xyzw = r5.zwzw + r1.yzxz;
        r8.xyzw = t0.Sample(s0_s, r5.xy).xyzw;
        r5.xyzw = t0.Sample(s0_s, r5.zw).xyzw;
        r8.xyzw = r8.xyzw * r0.xxxx + -r7.xyzw;
        r7.xyzw = r2.wwww * r8.xyzw + r7.xyzw;
        r4.xyzw = r5.xyzw * r4.xxxx + -r6.xyzw;
        r4.xyzw = r2.wwww * r4.xyzw + r6.xyzw;
        r4.xyzw = r7.xyzw + r4.xyzw;
        r0.x = 1 + -r0.z;
        r0.x = r0.y / r0.x;
        r0.x = saturate(1 + -r0.x);
        r0.x = log2(r0.x);
        r0.x = cb0[4].z * r0.x;
        r0.x = exp2(r0.x);
        r4.xyzw = r4.xyzw * r0.xxxx;
        r4.xyzw = r4.xyzw * r2.xxxx;
      } else {
        r4.xyzw = float4(0,0,0,0);
      }
    } else {
      r4.xyzw = float4(0,0,0,0);
    }
  } else {
    r4.xyzw = float4(0,0,0,0);
  }
  r0.x = cmp(r0.w < r1.w);
  r0.x = r0.x ? r2.y : 0;
  r1.xyzw = max(r4.xyzw, r3.xyzw);
  r0.xyzw = r0.xxxx ? r1.xyzw : r4.xyzw;
  r1.xyz = cb0[3].xyz * cb0[2].xxx;
  o0.xyz = r1.xyz * r0.xyz;
  o0.w = saturate(r0.w);
  return;
}



Shader hash 9a1f6254-6fe7a6aa-acdd92eb-a0c3a8aa

ps_5_0
      dcl_globalFlags refactoringAllowed
      dcl_constantbuffer cb0[8], immediateIndexed
      dcl_constantbuffer cb1[5], immediateIndexed
      dcl_sampler s0, mode_default
      dcl_resource_texture2d (float,float,float,float) t0
      dcl_input_ps linear v0.xyz
      dcl_output o0.xyzw
      dcl_temps 9
   0: add r0.xyz, -cb0[6].xyzx, cb1[4].xyzx
   1: add r1.xyz, cb0[7].zxyz, cb0[7].zxyz
   2: mul r2.xyz, r1.yzxy, cb0[7].xyzx
   3: mul r3.xyz, r1.xyzx, -cb0[7].wwww
   4: add r2.xyz, r2.zzyz, r2.yxxy
   5: add r2.xyz, -r2.xyzx, l(1.0000, 1.0000, 1.0000, 0.0000)
   6: mul r1.yw, r0.xxxy, r2.xxxy
   7: mad r0.w, cb0[7].x, r1.z, -r3.x
   8: mad r1.y, r0.w, r0.y, r1.y
   9: mad r4.xy, cb0[7].xyxx, r1.xxxx, r3.zyzz
  10: mul r0.y, r0.y, r4.y
  11: mad r5.x, r4.x, r0.z, r1.y
  12: mad r1.y, cb0[7].x, r1.z, r3.x
  13: mad r1.z, r1.y, r0.x, r1.w
  14: mad r1.xw, cb0[7].yyyx, r1.xxxx, -r3.yyyz
  15: mad r5.y, r1.x, r0.z, r1.z
  16: mad r0.x, r1.w, r0.x, r0.y
  17: mad r5.z, r2.z, r0.z, r0.x
  18: add r0.xyz, v0.xyzx, -cb1[4].xyzx
  19: mul r2.xy, r0.xyxx, r2.xyxx
  20: mad r0.w, r0.w, r0.y, r2.x
  21: mul r0.y, r0.y, r4.y
  22: mad r3.y, r4.x, r0.z, r0.w
  23: mad r0.w, r1.y, r0.x, r2.y
  24: mad r3.z, r1.x, r0.z, r0.w
  25: mad r0.x, r1.w, r0.x, r0.y
  26: mad r3.x, r2.z, r0.z, r0.x
  27: dp3 r0.x, r3.xyzx, r3.xyzx
  28: rsq r0.x, r0.x
  29: mul r0.xyz, r0.xxxx, r3.xyzx
  30: dp3 r0.w, -r5.zxyz, r0.xyzx
  31: max r0.w, r0.w, l(0)
  32: lt r1.x, cb0[4].y, r0.w
  33: add r0.w, r0.w, -cb0[4].y
  34: mad r1.yzw, r0.yyzx, r0.wwww, r5.xxyz
  35: movc r1.xyz, r1.xxxx, r1.yzwy, r5.xyzx
  36: lt r0.w, r0.z, l(-0.0000)
  37: lt r1.w, l(0.0000), r0.z
  38: or r0.w, r0.w, r1.w
  39: div r1.w, -r1.y, r0.z
  40: and r0.w, r0.w, r1.w
  41: lt r2.xy, l(0.0000, 0.0000, 0.0000, 0.0000), r0.wwww
  42: if_nz r2.x
  43:   mad r2.xz, r0.yyxy, r0.wwww, r1.xxzx
  44:   dp2 r1.w, r2.xzxx, r2.xzxx
  45:   sqrt r1.w, r1.w
  46:   div r3.z, r1.w, cb0[4].y
  47:   ge r1.w, l(1.3000), r3.z
  48:   if_nz r1.w
  49:     div r1.w, cb0[4].x, cb0[4].y
  50:     ge r2.w, r3.z, r1.w
  51:     if_nz r2.w
  52:       min r2.w, abs(r2.z), abs(r2.x)
  53:       max r3.w, abs(r2.z), abs(r2.x)
  54:       div r3.w, l(1.0000, 1.0000, 1.0000, 1.0000), r3.w
  55:       mul r2.w, r2.w, r3.w
  56:       mul r3.w, r2.w, r2.w
  57:       mad r4.x, r3.w, l(0.0208), l(-0.0851)
  58:       mad r4.x, r3.w, r4.x, l(0.1801)
  59:       mad r4.x, r3.w, r4.x, l(-0.3303)
  60:       mad r3.w, r3.w, r4.x, l(0.9999)
  61:       mul r4.x, r2.w, r3.w
  62:       lt r4.y, abs(r2.z), abs(r2.x)
  63:       mad r4.x, r4.x, l(-2.0000), l(1.5708)
  64:       and r4.x, r4.y, r4.x
  65:       mad r2.w, r2.w, r3.w, r4.x
  66:       lt r3.w, r2.z, -r2.z
  67:       and r3.w, r3.w, l(-3.1416)
  68:       add r3.w, r2.w, r3.w
  69:       min r4.x, r2.z, r2.x
  70:       max r4.y, r2.z, r2.x
  71:       lt r4.x, r4.x, -r4.x
  72:       ge r4.y, r4.y, -r4.y
  73:       and r4.x, r4.y, r4.x
  74:       movc r3.w, r4.x, -r3.w, r3.w
  75:       mul r3.y, r3.w, l(0.3183)
  76:       lt r3.w, -r2.z, r2.z
  77:       and r3.w, r3.w, l(-3.1416)
  78:       add r2.w, r2.w, r3.w
  79:       min r3.w, -r2.z, -r2.x
  80:       max r2.x, -r2.z, -r2.x
  81:       lt r3.w, r3.w, -r3.w
  82:       ge r2.x, r2.x, -r2.x
  83:       and r2.x, r2.x, r3.w
  84:       movc r2.x, r2.x, -r2.w, r2.w
  85:       mul r3.x, r2.x, l(0.3183)
  86:       mad_sat r2.x, r2.z, l(20.0000), l(0.5000)
  87:       add r2.z, -r1.w, r3.z
  88:       div r2.w, r2.z, r1.w
  89:       mul_sat r2.w, r2.w, l(80.0000)
  90:       mul r3.w, cb0[5].x, cb1[0].x
  91:       mul r4.x, r3.w, l(3.0000)
  92:       frc r4.x, r4.x
  93:       mad r4.y, r4.x, l(0.3333), cb0[5].y
  94:       mad r3.w, r3.w, l(3.0000), l(0.5000)
  95:       frc r3.w, r3.w
  96:       mad r3.w, r3.w, l(0.3333), cb0[5].y
  97:       add r4.x, r4.x, l(-0.5000)
  98:       add r4.x, abs(r4.x), abs(r4.x)
  99:       max r4.z, r1.w, r3.z
 100:       log r4.z, r4.z
 101:       mul r4.z, r4.z, l(-0.7000)
 102:       exp r4.z, r4.z
 103:       mul r5.x, r4.z, r4.y
 104:       mov r5.yw, l(0, 0, 0, 0)
 105:       add r6.xyzw, r3.yzxz, r5.xyxy
 106:       sample_indexable(texture2d)(float,float,float,float) r7.xyzw, r6.xyxx, t0.xyzw, s0
 107:       mul r7.xyzw, r2.xxxx, r7.xyzw
 108:       sample_indexable(texture2d)(float,float,float,float) r6.xyzw, r6.zwzz, t0.xyzw, s0
 109:       add r4.y, -r2.x, l(1.0000)
 110:       mul r6.xyzw, r4.yyyy, r6.xyzw
 111:       mul r5.z, r3.w, r4.z
 112:       add r3.xyzw, r3.yzxz, r5.zwzw
 113:       sample_indexable(texture2d)(float,float,float,float) r5.xyzw, r3.xyxx, t0.xyzw, s0
 114:       sample_indexable(texture2d)(float,float,float,float) r3.xyzw, r3.zwzz, t0.xyzw, s0
 115:       mad r5.xyzw, r5.xyzw, r2.xxxx, -r7.xyzw
 116:       mad r5.xyzw, r4.xxxx, r5.xyzw, r7.xyzw
 117:       mad r3.xyzw, r3.xyzw, r4.yyyy, -r6.xyzw
 118:       mad r3.xyzw, r4.xxxx, r3.xyzw, r6.xyzw
 119:       add r3.xyzw, r3.xyzw, r5.xyzw
 120:       add r1.w, -r1.w, l(1.0000)
 121:       div r1.w, r2.z, r1.w
 122:       add_sat r1.w, -r1.w, l(1.0000)
 123:       log r1.w, r1.w
 124:       mul r1.w, r1.w, cb0[4].z
 125:       exp r1.w, r1.w
 126:       mul r3.xyzw, r1.wwww, r3.xyzw
 127:       mul r3.xyzw, r2.wwww, r3.xyzw
 128:     else
 129:       mov r3.xyzw, l(0, 0, 0, 0)
 130:     endif
 131:   else
 132:     mov r3.xyzw, l(0, 0, 0, 0)
 133:   endif
 134: else
 135:   mov r3.xyzw, l(0, 0, 0, 0)
 136: endif
 137: dp3 r1.w, -r1.zxyz, r0.xyzx
 138: max r1.w, r1.w, l(0)
 139: lt r2.x, r1.w, cb0[4].x
 140: div r2.z, r1.w, cb0[4].x
 141: log r2.z, r2.z
 142: mul r2.z, r2.z, l(1.8000)
 143: exp r2.z, r2.z
 144: mul r2.z, r2.z, cb0[4].x
 145: movc r1.w, r2.x, r2.z, r1.w
 146: mad r2.xzw, r0.xxyz, r1.wwww, r1.zzxy
 147: dp3 r4.x, r2.xzwx, r2.xzwx
 148: sqrt r4.y, r4.x
 149: mul r5.xyz, r0.xyzx, -r1.yzxy
 150: mad r5.xyz, r0.zxyz, -r1.zxyz, -r5.xyzx
 151: dp3 r4.z, r5.xyzx, r5.xyzx
 152: rsq r4.z, r4.z
 153: mul r5.xyz, r4.zzzz, r5.xyzx
 154: mov r5.w, -r5.z
 155: mul r4.zw, r5.zzzx, l(0.0000, 0.0000, -1.0000, 1.0000)
 156: dp2 r4.z, r5.wxww, r4.zwzz
 157: rsq r4.z, r4.z
 158: mul r6.z, r4.z, -r5.z
 159: mov r6.x, l(0)
 160: mul r6.y, r4.z, r5.x
 161: mul r7.xyz, r2.xzwx, r6.xyzx
 162: mad r7.xyz, r2.wxzw, r6.yzxy, -r7.xyzx
 163: dp3 r4.z, r5.xyzx, r7.xyzx
 164: lt r4.w, l(0), r4.z
 165: lt r4.z, r4.z, l(0)
 166: iadd r4.z, -r4.w, r4.z
 167: itof r4.z, r4.z
 168: mul r6.xy, r4.yyyy, r6.zyzz
 169: mul r4.zw, r4.zzzz, r6.xxxy
 170: rsq r4.x, r4.x
 171: mul r6.xy, r2.zxzz, r4.xxxx
 172: dp2 r4.x, r4.zwzz, r4.zwzz
 173: rsq r4.x, r4.x
 174: mul r4.xz, r4.xxxx, r4.zzwz
 175: dp2 r4.x, r6.xyxx, r4.xzxx
 176: add r4.z, -abs(r4.x), l(1.0000)
 177: sqrt r4.z, r4.z
 178: mad r4.w, abs(r4.x), l(-0.0187), l(0.0743)
 179: mad r4.w, r4.w, abs(r4.x), l(-0.2121)
 180: mad r4.w, r4.w, abs(r4.x), l(1.5707)
 181: mul r5.w, r4.z, r4.w
 182: mad r5.w, r5.w, l(-2.0000), l(3.1416)
 183: lt r4.x, r4.x, -r4.x
 184: and r4.x, r4.x, r5.w
 185: mad r4.x, r4.w, r4.z, r4.x
 186: dp3 r1.x, r1.xyzx, r1.xyzx
 187: sqrt r1.x, r1.x
 188: div r1.x, r1.x, cb0[4].x
 189: mad r1.x, -r1.x, r1.x, l(1.0000)
 190: max r1.x, r1.x, l(0)
 191: max r1.y, r4.y, cb0[4].x
 192: div r1.y, cb0[4].x, r1.y
 193: log r1.y, r1.y
 194: mul r1.y, r1.y, cb0[4].w
 195: exp r1.y, r1.y
 196: add r1.y, r1.y, l(-0.0100)
 197: mul r1.y, r1.y, l(1.0110)
 198: mad r1.x, r1.x, l(0.0150), l(0.9900)
 199: max r1.y, r1.y, l(0)
 200: min r1.x, r1.x, r1.y
 201: mul r1.x, r1.x, r4.x
 202: mul r1.x, r1.x, l(0.5000)
 203: sincos r1.x, r4.x, r1.x
 204: mul r5.xyzw, r1.xxxx, r5.xzxy
 205: add r6.xyzw, r5.zywy, r5.zywy
 206: mul r1.xy, r5.xyxx, r6.xyxx
 207: mul r4.yz, r4.xxxx, r6.xxwx
 208: mad r1.z, r5.z, r6.z, r4.z
 209: add r4.w, r1.y, r1.x
 210: add r4.w, -r4.w, l(1.0000)
 211: mul r5.x, r2.w, r4.w
 212: mad r5.x, r1.z, r2.z, r5.x
 213: mad r5.y, r5.w, r6.w, -r4.y
 214: mad r5.x, r5.y, r2.x, r5.x
 215: mul r4.w, r0.z, r4.w
 216: mad r1.z, r1.z, r0.y, r4.w
 217: mad r1.z, r5.y, r0.x, r1.z
 218: lt r4.w, r1.z, l(-0.0000)
 219: lt r5.y, l(0.0000), r1.z
 220: or r4.w, r4.w, r5.y
 221: div r1.z, -r5.x, r1.z
 222: and r1.z, r1.z, r4.w
 223: lt r4.w, l(0.0000), r1.z
 224: if_nz r4.w
 225:   mul r4.x, r4.x, r6.z
 226:   mad r1.xy, r5.wwww, r6.zzzz, r1.yxyy
 227:   add r1.xy, -r1.xyxx, l(1.0000, 1.0000, 0.0000, 0.0000)
 228:   mul r4.w, r2.z, r1.x
 229:   mad r4.z, r5.z, r6.z, -r4.z
 230:   mad r4.w, r4.z, r2.w, r4.w
 231:   mad r5.x, r5.z, r6.w, r4.x
 232:   mad r6.x, r5.x, r2.x, r4.w
 233:   mad r4.x, r5.z, r6.w, -r4.x
 234:   mad r4.y, r5.w, r6.w, r4.y
 235:   mul r2.w, r2.w, r4.y
 236:   mad r2.z, r4.x, r2.z, r2.w
 237:   mad r6.y, r1.y, r2.x, r2.z
 238:   mul r1.x, r0.y, r1.x
 239:   mad r1.x, r4.z, r0.z, r1.x
 240:   mad r5.x, r5.x, r0.x, r1.x
 241:   mul r0.z, r0.z, r4.y
 242:   mad r0.y, r4.x, r0.y, r0.z
 243:   mad r5.y, r1.y, r0.x, r0.y
 244:   mad r0.xy, r5.xyxx, r1.zzzz, r6.xyxx
 245:   dp2 r0.z, r0.xyxx, r0.xyxx
 246:   sqrt r0.z, r0.z
 247:   div r1.z, r0.z, cb0[4].y
 248:   ge r0.z, l(1.3000), r1.z
 249:   if_nz r0.z
 250:     div r0.z, cb0[4].x, cb0[4].y
 251:     ge r2.x, r1.z, r0.z
 252:     if_nz r2.x
 253:       min r2.x, abs(r0.y), abs(r0.x)
 254:       max r2.z, abs(r0.y), abs(r0.x)
 255:       div r2.z, l(1.0000, 1.0000, 1.0000, 1.0000), r2.z
 256:       mul r2.x, r2.z, r2.x
 257:       mul r2.z, r2.x, r2.x
 258:       mad r2.w, r2.z, l(0.0208), l(-0.0851)
 259:       mad r2.w, r2.z, r2.w, l(0.1801)
 260:       mad r2.w, r2.z, r2.w, l(-0.3303)
 261:       mad r2.z, r2.z, r2.w, l(0.9999)
 262:       mul r2.w, r2.z, r2.x
 263:       lt r4.x, abs(r0.y), abs(r0.x)
 264:       mad r2.w, r2.w, l(-2.0000), l(1.5708)
 265:       and r2.w, r4.x, r2.w
 266:       mad r2.x, r2.x, r2.z, r2.w
 267:       lt r2.z, r0.y, -r0.y
 268:       and r2.z, r2.z, l(-3.1416)
 269:       add r2.z, r2.z, r2.x
 270:       min r2.w, r0.y, r0.x
 271:       max r4.x, r0.y, r0.x
 272:       lt r2.w, r2.w, -r2.w
 273:       ge r4.x, r4.x, -r4.x
 274:       and r2.w, r2.w, r4.x
 275:       movc r2.z, r2.w, -r2.z, r2.z
 276:       mul r1.y, r2.z, l(0.3183)
 277:       lt r2.z, -r0.y, r0.y
 278:       and r2.z, r2.z, l(-3.1416)
 279:       add r2.x, r2.z, r2.x
 280:       min r2.z, -r0.y, -r0.x
 281:       max r0.x, -r0.y, -r0.x
 282:       lt r2.z, r2.z, -r2.z
 283:       ge r0.x, r0.x, -r0.x
 284:       and r0.x, r0.x, r2.z
 285:       movc r0.x, r0.x, -r2.x, r2.x
 286:       mul r1.x, r0.x, l(0.3183)
 287:       mad_sat r0.x, r0.y, l(20.0000), l(0.5000)
 288:       add r0.y, -r0.z, r1.z
 289:       div r2.x, r0.y, r0.z
 290:       mul_sat r2.x, r2.x, l(80.0000)
 291:       mul r2.z, cb0[5].x, cb1[0].x
 292:       mul r2.w, r2.z, l(3.0000)
 293:       frc r2.w, r2.w
 294:       mad r4.x, r2.w, l(0.3333), cb0[5].y
 295:       mad r2.z, r2.z, l(3.0000), l(0.5000)
 296:       frc r2.z, r2.z
 297:       mad r2.z, r2.z, l(0.3333), cb0[5].y
 298:       add r2.w, r2.w, l(-0.5000)
 299:       add r2.w, abs(r2.w), abs(r2.w)
 300:       max r4.y, r0.z, r1.z
 301:       log r4.y, r4.y
 302:       mul r4.y, r4.y, l(-0.7000)
 303:       exp r4.y, r4.y
 304:       mul r5.x, r4.y, r4.x
 305:       mov r5.yw, l(0, 0, 0, 0)
 306:       add r6.xyzw, r1.yzxz, r5.xyxy
 307:       sample_indexable(texture2d)(float,float,float,float) r7.xyzw, r6.xyxx, t0.xyzw, s0
 308:       mul r7.xyzw, r0.xxxx, r7.xyzw
 309:       sample_indexable(texture2d)(float,float,float,float) r6.xyzw, r6.zwzz, t0.xyzw, s0
 310:       add r4.x, -r0.x, l(1.0000)
 311:       mul r6.xyzw, r4.xxxx, r6.xyzw
 312:       mul r5.z, r2.z, r4.y
 313:       add r5.xyzw, r1.yzxz, r5.zwzw
 314:       sample_indexable(texture2d)(float,float,float,float) r8.xyzw, r5.xyxx, t0.xyzw, s0
 315:       sample_indexable(texture2d)(float,float,float,float) r5.xyzw, r5.zwzz, t0.xyzw, s0
 316:       mad r8.xyzw, r8.xyzw, r0.xxxx, -r7.xyzw
 317:       mad r7.xyzw, r2.wwww, r8.xyzw, r7.xyzw
 318:       mad r4.xyzw, r5.xyzw, r4.xxxx, -r6.xyzw
 319:       mad r4.xyzw, r2.wwww, r4.xyzw, r6.xyzw
 320:       add r4.xyzw, r4.xyzw, r7.xyzw
 321:       add r0.x, -r0.z, l(1.0000)
 322:       div r0.x, r0.y, r0.x
 323:       add_sat r0.x, -r0.x, l(1.0000)
 324:       log r0.x, r0.x
 325:       mul r0.x, r0.x, cb0[4].z
 326:       exp r0.x, r0.x
 327:       mul r4.xyzw, r0.xxxx, r4.xyzw
 328:       mul r4.xyzw, r2.xxxx, r4.xyzw
 329:     else
 330:       mov r4.xyzw, l(0, 0, 0, 0)
 331:     endif
 332:   else
 333:     mov r4.xyzw, l(0, 0, 0, 0)
 334:   endif
 335: else
 336:   mov r4.xyzw, l(0, 0, 0, 0)
 337: endif
 338: lt r0.x, r0.w, r1.w
 339: and r0.x, r0.x, r2.y
 340: max r1.xyzw, r3.xyzw, r4.xyzw
 341: movc r0.xyzw, r0.xxxx, r1.xyzw, r4.xyzw
 342: mul r1.xyz, cb0[2].xxxx, cb0[3].xyzx
 343: mul o0.xyz, r0.xyzx, r1.xyzx
 344: mov_sat o0.w, r0.w
 345: ret
