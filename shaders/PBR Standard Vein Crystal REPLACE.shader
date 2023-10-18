fractal silicon: vert

// ---- Created with 3Dmigoto v1.3.16 on Wed Oct 18 04:24:52 2023
struct t5_t {
  float val[3];
};
StructuredBuffer<t5_t> t5 : register(t5);

struct t4_t {
  float val[5];
};
StructuredBuffer<t4_t> t4 : register(t4);

struct t3_t {
  float val[1];
};
StructuredBuffer<t3_t> t3 : register(t3);

struct t2_t {
  float val[1];
};
StructuredBuffer<t2_t> t2 : register(t2);

struct t1_t {
  float val[8];
};
StructuredBuffer<t1_t> t1 : register(t1);

TextureCube<float4> t0 : register(t0);

SamplerState s1_s : register(s1);

cbuffer cb4 : register(b4)
{
  float4 cb4[21];
}

cbuffer cb3 : register(b3)
{
  float4 cb3[10];
}

cbuffer cb2 : register(b2)
{
  float4 cb2[46];
}

cbuffer cb1 : register(b1)
{
  float4 cb1[6];
}

cbuffer cb0 : register(b0)
{
  float4 cb0[47];
}




// 3Dmigoto declarations
#define cmp -


void main(
  float4 v0 : POSITION0,
  float3 v1 : NORMAL0,
  float4 v2 : TANGENT0,
  float4 v3 : COLOR0,
  uint v4 : SV_VertexID0,
  uint v5 : SV_InstanceID0,
  float4 v6 : TEXCOORD0,
  float4 v7 : TEXCOORD1,
  float2 v8 : TEXCOORD2,
  out float4 o0 : SV_POSITION0,
  out float4 o1 : TEXCOORD0,
  out float4 o2 : TEXCOORD1,
  out float4 o3 : TEXCOORD2,
  out float4 o4 : TEXCOORD3,
  out float4 o5 : TEXCOORD4,
  out float4 o6 : TEXCOORD5,
  out float4 o7 : TEXCOORD6,
  out float4 o8 : TEXCOORD7,
  out float4 o9 : TEXCOORD8,
  out float4 o10 : TEXCOORD10,
  out float4 o11 : TEXCOORD11)
{

  r0.x = t2[v5.x].val[0/4];
  r1.x = t1[r0.x].val[0/4];
  r1.y = t1[r0.x].val[0/4+1];
  r1.z = t1[r0.x].val[0/4+2];
  r1.w = t1[r0.x].val[0/4+3];
  r2.x = t1[r0.x].val[16/4];
  r2.y = t1[r0.x].val[16/4+1];
  r2.z = t1[r0.x].val[16/4+2];
  r2.w = t1[r0.x].val[16/4+3];
  r3.x = t4[r1.x].val[0/4];
  r3.y = t4[r1.x].val[0/4+1];
  r3.z = t4[r1.x].val[0/4+2];
  r3.w = t4[r1.x].val[0/4+3];
  r0.y = t4[r1.x].val[16/4];
  r0.z = cmp(0 < r3.y);
  r0.w = asuint(cb0[4].z);
  r1.x = -1 + r0.w;
  r0.w = r0.z ? r1.x : r0.w;
  r1.x = cmp(0.5 < cb0[4].w);
  r4.x = t5[r0.x].val[0/4];
  r4.y = t5[r0.x].val[0/4+1];
  r4.z = t5[r0.x].val[0/4+2];
  r5.xyz = v0.xyz * r4.xyz;
  r4.xyz = v1.xyz * r4.xyz;
  r5.xyz = r1.xxx ? r5.xyz : v0.xyz;
  r4.xyz = r1.xxx ? r4.xyz : v1.xyz;
  r0.x = cmp(0 >= r0.w);
  r6.xyz = cmp(asint(cb0[4].xxx) != int3(3,6,9));
  r1.x = r6.y ? r6.x : 0;
  r1.x = r6.z ? r1.x : 0;
  r0.x = (int)r0.x | (int)r1.x;
  r1.x = cmp(0 >= asuint(cb0[4].y));
  r0.x = (int)r0.x | (int)r1.x;
  r1.x = cmp(0 >= r3.z);
  r0.x = (int)r0.x | (int)r1.x;
  if (r0.x == 0) {
    r0.x = cmp(r3.x >= r3.y);
    r0.x = r0.x ? r0.z : 0;
    r0.x = r0.x ? 1.000000 : 0;
    r0.z = -1 + r0.w;
    r0.w = cmp(0 >= r0.z);
    r1.x = r3.y + r3.z;
    r1.x = r3.x / r1.x;
    r1.x = frac(r1.x);
    r0.x = r1.x * r0.z + r0.x;
    r0.x = r0.w ? 0 : r0.x;
    r0.z = (uint)r0.x;
    r0.x = frac(r0.x);
    r0.w = asint(cb0[4].x) * asint(cb0[4].y);
    r1.x = (int)v4.x * asint(cb0[4].x);
    r3.y = mad((int)r0.w, (int)r0.z, (int)r1.x);
    r0.z = (int)r0.z + 1;
    r0.z = mad((int)r0.w, (int)r0.z, (int)r1.x);
    r0.w = cmp(asint(cb0[4].x) == 3);
    if (r0.w != 0) {
      r0.w = t3[r3.y].val[0/4];
      r1.x = t3[r0.z].val[0/4];
      r1.x = r1.x + -r0.w;
      r5.x = r0.x * r1.x + r0.w;
      r6.xy = (int2)r3.yy + int2(1,2);
      r0.w = t3[r6.x].val[0/4];
      r6.xz = (int2)r0.zz + int2(1,2);
      r1.x = t3[r6.x].val[0/4];
      r1.x = r1.x + -r0.w;
      r5.y = r0.x * r1.x + r0.w;
      r0.w = t3[r6.y].val[0/4];
      r1.x = t3[r6.z].val[0/4];
      r1.x = r1.x + -r0.w;
      r5.z = r0.x * r1.x + r0.w;
      r6.xyz = v2.xyz;
    } else {
      r0.w = cmp(asint(cb0[4].x) == 6);
      if (r0.w != 0) {
        r0.w = t3[r3.y].val[0/4];
        r1.x = t3[r0.z].val[0/4];
        r1.x = r1.x + -r0.w;
        r5.x = r0.x * r1.x + r0.w;
        r7.xyzw = (int4)r3.yyyy + int4(1,2,3,4);
        r0.w = t3[r7.x].val[0/4];
        r8.xyzw = (int4)r0.zzzz + int4(1,2,3,4);
        r1.x = t3[r8.x].val[0/4];
        r1.x = r1.x + -r0.w;
        r5.y = r0.x * r1.x + r0.w;
        r0.w = t3[r7.y].val[0/4];
        r1.x = t3[r8.y].val[0/4];
        r1.x = r1.x + -r0.w;
        r5.z = r0.x * r1.x + r0.w;
        r0.w = t3[r7.z].val[0/4];
        r1.x = t3[r8.z].val[0/4];
        r1.x = r1.x + -r0.w;
        r4.x = r0.x * r1.x + r0.w;
        r0.w = t3[r7.w].val[0/4];
        r1.x = t3[r8.w].val[0/4];
        r1.x = r1.x + -r0.w;
        r4.y = r0.x * r1.x + r0.w;
        r0.w = (int)r3.y + 5;
        r0.w = t3[r0.w].val[0/4];
        r1.x = (int)r0.z + 5;
        r1.x = t3[r1.x].val[0/4];
        r1.x = r1.x + -r0.w;
        r4.z = r0.x * r1.x + r0.w;
        r6.xyz = v2.xyz;
      } else {
        r0.w = cmp(asint(cb0[4].x) == 9);
        if (r0.w != 0) {
          r0.w = t3[r3.y].val[0/4];
          r1.x = t3[r0.z].val[0/4];
          r1.x = r1.x + -r0.w;
          r5.x = r0.x * r1.x + r0.w;
          r7.xyzw = (int4)r3.yyyy + int4(1,2,3,4);
          r0.w = t3[r7.x].val[0/4];
          r8.xyzw = (int4)r0.zzzz + int4(1,2,3,4);
          r1.x = t3[r8.x].val[0/4];
          r1.x = r1.x + -r0.w;
          r5.y = r0.x * r1.x + r0.w;
          r0.w = t3[r7.y].val[0/4];
          r1.x = t3[r8.y].val[0/4];
          r1.x = r1.x + -r0.w;
          r5.z = r0.x * r1.x + r0.w;
          r0.w = t3[r7.z].val[0/4];
          r1.x = t3[r8.z].val[0/4];
          r1.x = r1.x + -r0.w;
          r4.x = r0.x * r1.x + r0.w;
          r0.w = t3[r7.w].val[0/4];
          r1.x = t3[r8.w].val[0/4];
          r1.x = r1.x + -r0.w;
          r4.y = r0.x * r1.x + r0.w;
          r7.xyzw = (int4)r3.yyyy + int4(5,6,7,8);
          r0.w = t3[r7.x].val[0/4];
          r8.xyzw = (int4)r0.zzzz + int4(5,6,7,8);
          r0.z = t3[r8.x].val[0/4];
          r0.z = r0.z + -r0.w;
          r4.z = r0.x * r0.z + r0.w;
          r0.z = t3[r7.y].val[0/4];
          r0.w = t3[r8.y].val[0/4];
          r0.w = r0.w + -r0.z;
          r6.x = r0.x * r0.w + r0.z;
          r0.z = t3[r7.z].val[0/4];
          r0.w = t3[r8.z].val[0/4];
          r0.w = r0.w + -r0.z;
          r6.y = r0.x * r0.w + r0.z;
          r0.z = t3[r7.w].val[0/4];
          r0.w = t3[r8.w].val[0/4];
          r0.w = r0.w + -r0.z;
          r6.z = r0.x * r0.w + r0.z;
        } else {
          r6.xyz = v2.xyz;
        }
      }
    }
  } else {
    r6.xyz = v2.xyz;
  }
  r7.xyzw = r2.zzxy + r2.zzxy;
  r0.xzw = r7.zwy * r2.xyz;
  r8.xyzw = r7.xyzw * r2.xyww;
  r1.x = r7.y * r2.w;
  r0.xzw = r0.zxx + r0.wwz;
  r0.xzw = float3(1,1,1) + -r0.xzw;
  r2.zw = r0.xz * r5.xy;
  r3.y = r2.x * r7.w + -r1.x;
  r2.z = r3.y * r5.y + r2.z;
  r8.xy = r8.xy + r8.wz;
  r3.z = r8.y * r5.y;
  r9.x = r8.x * r5.z + r2.z;
  r1.x = r2.x * r7.w + r1.x;
  r2.z = r1.x * r5.x + r2.w;
  r2.xy = r2.yx * r7.yx + -r8.zw;
  r9.y = r2.x * r5.z + r2.z;
  r2.z = r2.y * r5.x + r3.z;
  r9.z = r0.w * r5.z + r2.z;
  r5.xyz = r9.xyz + r1.yzw;
  r2.zw = r0.xz * r4.xy;
  r2.z = r3.y * r4.y + r2.z;
  r3.z = r8.y * r4.y;
  r7.x = r8.x * r4.z + r2.z;
  r2.z = r1.x * r4.x + r2.w;
  r7.y = r2.x * r4.z + r2.z;
  r2.z = r2.y * r4.x + r3.z;
  r7.z = r0.w * r4.z + r2.z;
  r0.xz = r0.xz * r6.xy;
  r0.x = r3.y * r6.y + r0.x;
  r2.z = r8.y * r6.y;
  r4.y = r8.x * r6.z + r0.x;
  r0.x = r1.x * r6.x + r0.z;
  r4.z = r2.x * r6.z + r0.x;
  r0.x = r2.y * r6.x + r2.z;
  r4.x = r0.w * r6.z + r0.x;
  r0.x = dot(r1.yzw, r1.yzw);
  r0.x = sqrt(r0.x);
  r0.z = cmp(0.100000001 < r0.x);
  if (r0.z != 0) {
    r2.xyz = r1.yzw / r0.xxx;
    r0.z = dot(r5.xyz, r5.xyz);
    r0.z = rsqrt(r0.z);
    r6.xyz = r5.xyz * r0.zzz;
    r0.z = t0.SampleLevel(s1_s, r6.xyz, 0).x;
    r0.z = cb0[24].x + r0.z;
    r0.x = r0.z + -r0.x;
    r5.xyz = r0.xxx * r2.xyz + r5.xyz;
    r0.xzw = cb1[4].xyz + -r1.yzw;
    r0.x = dot(r0.xzw, r0.xzw);
    r0.x = sqrt(r0.x);
    r0.x = -180 + r0.x;
    r2.w = saturate(0.00999999978 * r0.x);
  } else {
    r2.xyzw = float4(0,1,0,0);
  }
  r0.xzw = cb3[1].xyz * r5.yyy;
  r0.xzw = cb3[0].xyz * r5.xxx + r0.xzw;
  r0.xzw = cb3[2].xyz * r5.zzz + r0.xzw;
  r0.xzw = cb3[3].xyz + r0.xzw;
  r1.x = dot(r7.xyz, r7.xyz);
  r1.x = rsqrt(r1.x);
  r1.yzw = r7.xyz * r1.xxx;
  r3.y = 0.200000003 * r2.w;
  r6.xyz = -r7.xyz * r1.xxx + r2.xyz;
  r1.xyz = r3.yyy * r6.xyz + r1.yzw;
  o6.y = (uint)r3.w;
  r0.y = -1 + r0.y;
  o6.z = cb0[46].z * r0.y + 1;
  r6.xyzw = cb3[1].xyzw * r5.yyyy;
  r6.xyzw = cb3[0].xyzw * r5.xxxx + r6.xyzw;
  r6.xyzw = cb3[2].xyzw * r5.zzzz + r6.xyzw;
  r6.xyzw = cb3[3].xyzw + r6.xyzw;
  r7.xyzw = cb4[18].xyzw * r6.yyyy;
  r7.xyzw = cb4[17].xyzw * r6.xxxx + r7.xyzw;
  r7.xyzw = cb4[19].xyzw * r6.zzzz + r7.xyzw;
  r6.xyzw = cb4[20].xyzw * r6.wwww + r7.xyzw;
  r7.xz = float2(0.5,0.5) * r6.xw;
  r0.y = cb1[5].x * r6.y;
  o8.xy = r6.xy * float2(0.5,-0.5) + r7.zz;
  r3.yzw = cb1[4].xyz + -r5.xyz;
  r1.w = dot(r3.yzw, r3.yzw);
  r1.w = rsqrt(r1.w);
  r3.yzw = r3.yzw * r1.www;
  o4.z = dot(r4.yzx, r3.yzw);
  r5.xyz = r4.xyz * r1.yzx;
  r5.xyz = r4.zxy * r1.zxy + -r5.xyz;
  r1.w = dot(r5.xyz, r5.xyz);
  r1.w = rsqrt(r1.w);
  r5.xyz = r5.xyz * r1.www;
  o4.w = dot(r5.xyz, r3.yzw);
  r5.x = dot(r1.xyz, cb3[4].xyz);
  r5.y = dot(r1.xyz, cb3[5].xyz);
  r5.z = dot(r1.xyz, cb3[6].xyz);
  r1.x = dot(r5.xyz, r5.xyz);
  r1.x = rsqrt(r1.x);
  r1.xyz = r5.xyz * r1.xxx;
  r3.yzw = cb3[1].yzx * r4.zzz;
  r3.yzw = cb3[0].yzx * r4.yyy + r3.yzw;
  r3.yzw = cb3[2].yzx * r4.xxx + r3.yzw;
  r4.x = dot(r3.yzw, r3.yzw);
  r4.x = rsqrt(r4.x);
  r3.yzw = r4.xxx * r3.yzw;
  r4.x = cb3[9].w * v2.w;
  r4.yzw = r3.yzw * r1.zxy;
  r4.yzw = r1.yzx * r3.zwy + -r4.yzw;
  r4.xyz = r4.yzw * r4.xxx;
  r1.w = 1;
  r5.x = dot(cb2[39].xyzw, r1.xyzw);
  r5.y = dot(cb2[40].xyzw, r1.xyzw);
  r5.z = dot(cb2[41].xyzw, r1.xyzw);
  r8.xyzw = r1.xyzz * r1.yzzx;
  r9.x = dot(cb2[42].xyzw, r8.xyzw);
  r9.y = dot(cb2[43].xyzw, r8.xyzw);
  r9.z = dot(cb2[44].xyzw, r8.xyzw);
  r1.w = r1.y * r1.y;
  r1.w = r1.x * r1.x + -r1.w;
  r8.xyz = cb2[45].xyz * r1.www + r9.xyz;
  o9.xyz = r8.xyz + r5.xyz;
  r7.w = 0.5 * r0.y;
  o10.xy = r7.xw + r7.zz;
  o0.xyzw = r6.xyzw;
  o1.x = r3.w;
  o1.y = r4.x;
  o1.z = r1.x;
  o1.w = r0.x;
  o2.x = r3.y;
  o2.y = r4.y;
  o2.z = r1.y;
  o2.w = r0.z;
  o3.x = r3.z;
  o3.y = r4.z;
  o3.z = r1.z;
  o3.w = r0.w;
  o4.xy = v6.xy;
  o5.xyzw = r2.xyzw;
  o8.zw = r6.zw;
  o10.zw = r6.zw;
  o11.xyzw = float4(0,0,0,0);
  o6.x = r3.x;
  o7.xyz = r0.xzw;
  return;
}



fractal silicon: frag

// ---- Created with 3Dmigoto v1.3.16 on Wed Oct 18 04:25:19 2023
Texture3D<float4> t11 : register(t11);

TextureCube<float4> t10 : register(t10);

Texture2D<float4> t9 : register(t9);

Texture2D<float4> t8 : register(t8);

TextureCube<float4> t7 : register(t7);

Texture2D<float4> t6 : register(t6);

Texture2D<float4> t5 : register(t5);

Texture2D<float4> t4 : register(t4);

Texture2D<float4> t3 : register(t3);

Texture2D<float4> t2 : register(t2);

Texture2D<float4> t1 : register(t1);

Texture2D<float4> t0 : register(t0);

SamplerState s11_s : register(s11);

SamplerState s10_s : register(s10);

SamplerState s9_s : register(s9);

SamplerState s8_s : register(s8);

SamplerState s7_s : register(s7);

SamplerState s6_s : register(s6);

SamplerState s5_s : register(s5);

SamplerState s4_s : register(s4);

SamplerState s3_s : register(s3);

SamplerState s2_s : register(s2);

SamplerState s1_s : register(s1);

SamplerState s0_s : register(s0);

cbuffer cb5 : register(b5)
{
  float4 cb5[7];
}

cbuffer cb4 : register(b4)
{
  float4 cb4[12];
}

cbuffer cb3 : register(b3)
{
  float4 cb3[26];
}

cbuffer cb2 : register(b2)
{
  float4 cb2[47];
}

cbuffer cb1 : register(b1)
{
  float4 cb1[5];
}

cbuffer cb0 : register(b0)
{
  float4 cb0[52];
}




// 3Dmigoto declarations
#define cmp -


void main(
  float4 v0 : SV_POSITION0,
  float4 v1 : TEXCOORD0,
  float4 v2 : TEXCOORD1,
  float4 v3 : TEXCOORD2,
  float4 v4 : TEXCOORD3,
  float4 v5 : TEXCOORD4,
  float4 v6 : TEXCOORD5,
  float4 v7 : TEXCOORD6,
  float4 v8 : TEXCOORD7,
  float4 v9 : TEXCOORD8,
  float4 v10 : TEXCOORD10,
  float4 v11 : TEXCOORD11,
  out float4 o0 : SV_Target0)
{
  float4 r0,r1,r2,r3,r4,r5,r6,r7,r8,r9,r10,r11,r12;
  uint4 bitmask, uiDest;
  float4 fDest;

  r0.x = cmp(0.949999988 < v6.y);
  r0.y = cmp(v6.y < 1.04999995);
  r0.x = r0.y ? r0.x : 0;
  if (r0.x != 0) {
    r0.xyz = cb0[31].xyz;
  } else {
    r0.w = cmp(1.95000005 < v6.y);
    r1.x = cmp(v6.y < 2.04999995);
    r0.w = r0.w ? r1.x : 0;
    if (r0.w != 0) {
      r0.xyz = cb0[32].xyz;
    } else {
      r0.w = cmp(2.95000005 < v6.y);
      r1.x = cmp(v6.y < 3.04999995);
      r0.w = r0.w ? r1.x : 0;
      if (r0.w != 0) {
        r0.xyz = cb0[33].xyz;
      } else {
        r0.w = cmp(3.95000005 < v6.y);
        r1.x = cmp(v6.y < 4.05000019);
        r0.w = r0.w ? r1.x : 0;
        if (r0.w != 0) {
          r0.xyz = cb0[34].xyz;
        } else {
          r0.w = cmp(4.94999981 < v6.y);
          r1.x = cmp(v6.y < 5.05000019);
          r0.w = r0.w ? r1.x : 0;
          if (r0.w != 0) {
            r0.xyz = cb0[35].xyz;
          } else {
            r0.w = cmp(5.94999981 < v6.y);
            r1.x = cmp(v6.y < 6.05000019);
            r0.w = r0.w ? r1.x : 0;
            if (r0.w != 0) {
              r0.xyz = cb0[36].xyz;
            } else {
              r0.w = cmp(8.94999981 < v6.y);
              r1.x = cmp(v6.y < 9.05000019);
              r0.w = r0.w ? r1.x : 0;
              if (r0.w != 0) {
                r0.xyz = cb0[37].xyz;
              } else {
                r1.xyzw = cmp(float4(9.94999981,10.9499998,11.9499998,12.9499998) < v6.yyyy);
                r2.xyzw = cmp(v6.yyyy < float4(10.0500002,11.0500002,12.0500002,13.0500002));
                r1.xyzw = r1.xyzw ? r2.xyzw : 0;
                r0.w = cmp(13.9499998 < v6.y);
                r2.x = cmp(v6.y < 14.0500002);
                r0.w = r0.w ? r2.x : 0;
                r2.xyz = r0.www ? cb0[42].xyz : cb0[30].xyz;
                r2.xyz = r1.www ? cb0[41].xyz : r2.xyz;
                r2.xyz = r1.zzz ? cb0[40].xyz : r2.xyz;
                r1.yzw = r1.yyy ? cb0[39].xyz : r2.xyz;
                r0.xyz = r1.xxx ? cb0[38].xyz : r1.yzw;
              }
            }
          }
        }
      }
    }
  }
  r1.xyz = t3.Sample(s9_s, v4.xy).xyw;
  r0.w = -0.00100000005 + cb0[46].w;
  r0.w = cmp(r1.y < r0.w);
  if (r0.w != 0) discard;
  r2.xyz = t0.Sample(s5_s, v4.xy).xyz;
  r2.xyz = r2.xyz * r0.xyz;
  r3.xyzw = t1.Sample(s6_s, v4.xy).xyzw;
  r1.yw = t2.Sample(s7_s, v4.xy).xw;
  r2.xyz = float3(6,6,6) * r2.xyz;
  r0.w = 1 + -v5.w;
  r0.w = r3.w * r0.w;
  r3.xyz = r3.xyz * float3(1.70000005,1.70000005,1.70000005) + -r2.xyz;
  r2.xyz = r0.www * r3.xyz + r2.xyz;
  r0.w = -1 + r1.y;
  r0.w = r1.w * r0.w + 1;
  r0.w = log2(r0.w);
  r0.w = cb0[43].z * r0.w;
  r0.w = exp2(r0.w);
  r2.xyz = r2.xyz * r0.www;
  r3.xyz = t4.SampleBias(s8_s, v4.xy, -1).xyw;
  r3.x = r3.x * r3.z;
  r1.yw = r3.xy * float2(2,2) + float2(-1,-1);
  r0.w = dot(r1.yw, r1.yw);
  r0.w = min(1, r0.w);
  r0.w = 1 + -r0.w;
  r3.z = sqrt(r0.w);
  r4.xyzw = t5.SampleBias(s10_s, v4.xy, -1).xyzw;
  r5.x = v6.x;
  r5.y = 0;
  r0.w = t6.Sample(s11_s, r5.xy).x;
  r2.w = saturate(v6.y);
  r3.w = cmp(0.100000001 < v6.z);
  r5.x = cmp(cb0[46].y < 0.5);
  r3.w = (int)r3.w | (int)r5.x;
  r3.w = r3.w ? 1.000000 : 0;
  r3.xy = cb0[43].ww * r1.yw;
  r1.y = dot(v7.xyz, v7.xyz);
  r1.w = rsqrt(r1.y);
  r5.xyz = v7.xyz * r1.www;
  r5.xy = t7.Sample(s4_s, r5.xyz).xy;
  r1.w = frac(r5.y);
  r5.z = 3 + -r1.w;
  r5.yz = r5.yz + -r1.ww;
  r1.w = r1.w * r1.w;
  r1.w = r1.w * r5.z + r5.y;
  r5.yz = saturate(float2(1,2) + -r1.ww);
  r5.w = saturate(r1.w);
  r5.z = min(r5.z, r5.w);
  r1.w = saturate(-1 + r1.w);
  r6.xyzw = cb0[22].xyzw * r5.zzzz;
  r6.xyzw = cb0[21].xyzw * r5.yyyy + r6.xyzw;
  r6.xyzw = cb0[23].xyzw * r1.wwww + r6.xyzw;
  r5.yzw = cb0[47].yyy * r6.xyz;
  r1.w = cb0[24].x + r5.x;
  r1.y = sqrt(r1.y);
  r1.y = r1.y + -r1.w;
  r1.y = cb0[47].z + -r1.y;
  r1.y = saturate(r1.y / cb0[47].z);
  r1.y = r1.y * r1.y;
  r1.w = r1.y * r6.w;
  r6.xyz = cb0[43].yyy * r2.xyz;
  r7.xyz = r5.yzw * r6.xyz + -r5.yzw;
  r5.xyz = cb0[47].xxx * r7.xyz + r5.yzw;
  r5.w = cb0[51].z / cb0[51].w;
  r7.xy = -v4.wz;
  r7.z = r7.x * r5.w;
  r7.xw = v8.xy / v8.ww;
  r7.yz = cb0[49].yy * r7.yz;
  r7.yz = r7.yz / v8.ww;
  r7.xy = r7.xw + r7.yz;
  r7.xy = v8.ww * r7.xy;
  r7.xy = r7.xy / v8.ww;
  r7.xyz = t8.Sample(s0_s, r7.xy).xyz;
  r2.xyz = -r2.xyz * cb0[43].yyy + r5.xyz;
  r2.xyz = r1.www * r2.xyz + r6.xyz;
  r5.xyz = cb0[49].xxx * r7.xyz;
  r6.xy = saturate(float2(-0.300000012,-0.300000012) + v4.zw);
  r6.xy = float2(4,4) * r6.xy;
  r1.w = dot(r6.xy, r6.xy);
  r1.w = sqrt(r1.w);
  r1.w = saturate(3 + -r1.w);
  r5.xyz = r5.xyz * r1.www;
  r1.y = -r1.y * r6.w + 1;
  r2.xyz = r5.xyz * r1.yyy + r2.xyz;
  r1.y = dot(r3.xyz, r3.xyz);
  r1.y = rsqrt(r1.y);
  r3.xyz = r3.xyz * r1.yyy;
  r1.xy = saturate(cb0[44].xy * r1.xz);
  r4.xyz = cb0[44].zzz * r4.xyz;
  r1.zw = cb0[46].yx * r4.ww;
  r2.w = -1 + r2.w;
  r1.z = r1.z * r2.w + 1;
  r4.xyz = r4.xyz * r1.zzz;
  r1.z = cb0[46].y * r1.w;
  r0.w = -1 + r0.w;
  r0.w = r1.z * r0.w + 1;
  r4.xyz = r4.xyz * r0.www;
  r4.xyz = r4.xyz * r3.www;
  r5.y = v1.w;
  r5.z = v2.w;
  r5.w = v3.w;
  r6.xyz = cb1[4].xyz + -r5.yzw;
  r0.w = dot(r6.xyz, r6.xyz);
  r0.w = rsqrt(r0.w);
  r7.xyz = r6.xyz * r0.www;
  r8.x = cb4[9].z;
  r8.y = cb4[10].z;
  r8.z = cb4[11].z;
  r1.z = dot(r6.xyz, r8.xyz);
  r8.xyz = -cb3[25].xyz + r5.yzw;
  r1.w = dot(r8.xyz, r8.xyz);
  r1.w = sqrt(r1.w);
  r1.w = r1.w + -r1.z;
  r1.z = cb3[25].w * r1.w + r1.z;
  r1.z = saturate(r1.z * cb3[24].z + cb3[24].w);
  r1.w = cmp(cb5[0].x == 1.000000);
  if (r1.w != 0) {
    r1.w = cmp(cb5[0].y == 1.000000);
    r8.xyz = cb5[2].xyz * v2.www;
    r8.xyz = cb5[1].xyz * v1.www + r8.xyz;
    r8.xyz = cb5[3].xyz * v3.www + r8.xyz;
    r8.xyz = cb5[4].xyz + r8.xyz;
    r5.xyz = r1.www ? r8.xyz : r5.yzw;
    r5.xyz = -cb5[6].xyz + r5.xyz;
    r5.yzw = cb5[5].xyz * r5.xyz;
    r1.w = r5.y * 0.25 + 0.75;
    r2.w = cb5[0].z * 0.5 + 0.75;
    r5.x = max(r2.w, r1.w);
    r5.xyzw = t11.Sample(s1_s, r5.xzw).xyzw;
  } else {
    r5.xyzw = float4(1,1,1,1);
  }
  r1.w = saturate(dot(r5.xyzw, cb2[46].xyzw));
  r5.xy = v10.xy / v10.ww;
  r2.w = t9.Sample(s2_s, r5.xy).x;
  r1.w = -r2.w + r1.w;
  r1.z = r1.z * r1.w + r2.w;
  r5.x = dot(v1.xyz, r3.xyz);
  r5.y = dot(v2.xyz, r3.xyz);
  r5.z = dot(v3.xyz, r3.xyz);
  r1.w = dot(r5.xyz, r5.xyz);
  r1.w = rsqrt(r1.w);
  r3.xyz = r5.xyz * r1.www;
  r1.xw = r1.xx * float2(0.850000024,0.850000024) + float2(0.648999989,0.149000004);
  r1.y = -r1.y * 0.970000029 + 1;
  r5.xyz = r6.xyz * r0.www + cb2[0].xyz;
  r0.w = dot(r5.xyz, r5.xyz);
  r0.w = rsqrt(r0.w);
  r5.xyz = r5.xyz * r0.www;
  r0.w = r1.y * r1.y;
  r2.w = r0.w * r0.w;
  r3.w = dot(r3.xyz, cb2[0].xyz);
  r4.w = max(0, r3.w);
  r5.w = dot(r3.xyz, r7.xyz);
  r6.x = dot(r3.xyz, r5.xyz);
  r6.x = max(0, r6.x);
  r5.x = dot(r7.xyz, r5.xyz);
  r5.xw = max(float2(0,0), r5.xw);
  r3.w = r3.w * 0.349999994 + 1;
  r5.y = r3.w * r3.w;
  r3.w = r5.y * r3.w;
  r5.y = dot(v5.xyz, cb2[0].xyz);
  r5.z = dot(r3.xyz, v5.xyz);
  r6.y = dot(v5.xyz, v5.xyz);
  r6.z = cmp(v5.y < 0.999899983);
  r6.y = cmp(0.00999999978 < r6.y);
  r6.z = r6.y ? r6.z : 0;
  r8.xyz = float3(0,1,0) * v5.yzx;
  r8.xyz = v5.xyz * float3(1,0,0) + -r8.xyz;
  r6.w = dot(r8.xy, r8.xy);
  r6.w = rsqrt(r6.w);
  r8.xyz = r8.xyz * r6.www;
  r8.xyz = r6.zzz ? r8.xyz : float3(0,1,0);
  r6.z = dot(r8.xy, r8.xy);
  r6.z = cmp(0.00999999978 < r6.z);
  r6.y = r6.z ? r6.y : 0;
  r9.xyz = v5.yzx * r8.xyz;
  r9.xyz = r8.zxy * v5.zxy + -r9.xyz;
  r6.z = dot(r9.xyz, r9.xyz);
  r6.z = rsqrt(r6.z);
  r9.xyz = r9.xyz * r6.zzz;
  r6.z = dot(-r7.xyz, r3.xyz);
  r6.z = r6.z + r6.z;
  r7.xyz = r3.xyz * -r6.zzz + -r7.xyz;
  r8.x = dot(r7.zx, -r8.xy);
  r8.y = dot(r7.xyz, v5.xyz);
  r6.yzw = r6.yyy ? -r9.xyz : float3(-0,-0,-1);
  r8.z = dot(r7.xyz, r6.yzw);
  r6.y = log2(r1.y);
  r6.y = 0.400000006 * r6.y;
  r6.y = exp2(r6.y);
  r6.y = 10 * r6.y;
  r6.yzw = t10.SampleLevel(s3_s, r8.xyz, r6.y).xyz;
  r7.x = r1.w * 0.699999988 + 0.300000012;
  r1.y = 1 + -r1.y;
  r1.y = r7.x * r1.y;
  r6.yzw = r6.yzw * r1.yyy;
  r7.x = cmp(1 >= r5.y);
  if (r7.x != 0) {
    r7.xyzw = float4(-0.200000003,-0.100000001,0.100000001,0.300000012) + r5.yyyy;
    r7.xyzw = saturate(float4(5,10,5,5) * r7.xyzw);
    r8.xyz = float3(1,1,1) + -cb0[12].xyz;
    r8.xyz = r7.xxx * r8.xyz + cb0[12].xyz;
    r9.xyz = float3(1.25,1.25,1.25) * cb0[13].xyz;
    r10.xyz = -cb0[13].xyz * float3(1.25,1.25,1.25) + cb0[12].xyz;
    r9.xyz = r7.yyy * r10.xyz + r9.xyz;
    r10.xyz = cmp(float3(0.200000003,0.100000001,-0.100000001) < r5.yyy);
    r11.xyz = float3(1.5,1.5,1.5) * cb0[14].xyz;
    r12.xyz = cb0[13].xyz * float3(1.25,1.25,1.25) + -r11.xyz;
    r7.xyz = r7.zzz * r12.xyz + r11.xyz;
    r11.xyz = r11.xyz * r7.www;
    r7.xyz = r10.zzz ? r7.xyz : r11.xyz;
    r7.xyz = r10.yyy ? r9.xyz : r7.xyz;
    r7.xyz = r10.xxx ? r8.xyz : r7.xyz;
  } else {
    r7.xyz = float3(1,1,1);
  }
  r7.xyz = cb0[2].xyz * r7.xyz;
  r8.xy = float2(0.150000006,3) * r5.yy;
  r8.xy = saturate(r8.xy);
  r7.w = 1 + -r1.z;
  r1.z = r8.x * r7.w + r1.z;
  r1.z = 0.800000012 * r1.z;
  r7.xyz = r1.zzz * r7.xyz;
  r1.z = r6.x * r6.x;
  r8.xz = r0.ww * r0.ww + float2(-1,1);
  r0.w = r1.z * r8.x + 1;
  r0.w = rcp(r0.w);
  r0.w = r0.w * r0.w;
  r0.w = r0.w * r2.w;
  r0.w = 0.25 * r0.w;
  r1.z = r8.z * r8.z;
  r2.w = 0.125 * r1.z;
  r1.z = -r1.z * 0.125 + 1;
  r5.w = r5.w * r1.z + r2.w;
  r1.z = r4.w * r1.z + r2.w;
  r8.xz = float2(1,1) + -r1.xw;
  r2.w = r5.x * -5.55472994 + -6.98316002;
  r2.w = r2.w * r5.x;
  r2.w = exp2(r2.w);
  r1.x = r8.x * r2.w + r1.x;
  r0.w = r1.x * r0.w;
  r1.x = r5.w * r1.z;
  r1.x = rcp(r1.x);
  r1.z = cmp(0 < r5.y);
  r9.xyz = -cb0[7].xyz + cb0[6].xyz;
  r8.xyw = r8.yyy * r9.xyz + cb0[7].xyz;
  r2.w = saturate(r5.y * 3 + 1);
  r9.xyz = -cb0[8].xyz + cb0[7].xyz;
  r9.xyz = r2.www * r9.xyz + cb0[8].xyz;
  r8.xyw = r1.zzz ? r8.xyw : r9.xyz;
  r1.z = saturate(r5.z * 0.300000012 + 0.699999988);
  r5.xzw = r8.xyw * r1.zzz;
  r5.xzw = r5.xzw * r3.www;
  r1.z = 1 + cb0[43].x;
  r5.xzw = r5.xzw * r1.zzz;
  r1.z = cmp(cb0[29].w >= 0.5);
  r2.w = dot(cb0[29].xyz, cb0[29].xyz);
  r2.w = sqrt(r2.w);
  r2.w = -5 + r2.w;
  r3.w = saturate(r2.w);
  r6.x = dot(-v5.xyz, cb2[0].xyz);
  r6.x = saturate(5 * r6.x);
  r3.w = r6.x * r3.w;
  r9.xyz = -v5.xyz * r2.www + cb0[29].xyz;
  r2.w = dot(r9.xyz, r9.xyz);
  r2.w = sqrt(r2.w);
  r6.x = 20 + -r2.w;
  r6.x = 0.0500000007 * r6.x;
  r6.x = max(0, r6.x);
  r6.x = r6.x * r6.x;
  r7.w = cmp(r2.w < 0.00100000005);
  r10.xyz = float3(1.29999995,1.10000002,0.600000024) * r3.www;
  r9.xyz = r9.xyz / r2.www;
  r2.w = saturate(dot(r9.xyz, r3.xyz));
  r2.w = r2.w * r6.x;
  r2.w = r2.w * r3.w;
  r3.xyz = float3(1.29999995,1.10000002,0.600000024) * r2.www;
  r3.xyz = r7.www ? r10.xyz : r3.xyz;
  r3.xyz = r1.zzz ? r3.xyz : 0;
  r3.xyz = r4.www * r7.xyz + r3.xyz;
  r3.xyz = r3.xyz * r2.xyz;
  r1.z = log2(r8.z);
  r1.z = 0.600000024 * r1.z;
  r1.z = exp2(r1.z);
  r9.xyz = float3(-1,-1,-1) + r2.xyz;
  r9.xyz = r1.www * r9.xyz + float3(1,1,1);
  r9.xyz = cb0[48].xyz * r9.xyz;
  r7.xyz = r9.xyz * r7.xyz;
  r0.w = r0.w * r1.x + 0.0318309888;
  r7.xyz = r7.xyz * r0.www;
  r7.xyz = r7.xyz * r4.www;
  r0.w = 0.200000003 * r8.z;
  r9.xyz = r0.www * r2.xyz + r1.www;
  r7.xyz = r9.xyz * r7.xyz;
  r5.xzw = r5.xzw * r2.xyz;
  r0.w = -r1.w * 0.600000024 + 1;
  r9.xyz = r5.xzw * r0.www;
  r1.x = dot(r9.xyz, float3(0.300000012,0.600000024,0.100000001));
  r5.xzw = -r5.xzw * r0.www + r1.xxx;
  r5.xzw = r5.xzw * float3(0.5,0.5,0.5) + r9.xyz;
  r0.w = dot(r8.xyx, float3(0.300000012,0.600000024,0.100000001));
  r0.w = 0.00300000003 + r0.w;
  r1.x = max(cb0[6].x, cb0[6].y);
  r1.x = max(cb0[6].z, r1.x);
  r1.x = 0.00300000003 + r1.x;
  r1.x = 1 / r1.x;
  r8.xyz = r8.xyw + -r0.www;
  r8.xyz = r8.xyz * float3(0.400000006,0.400000006,0.400000006) + r0.www;
  r8.xyz = r8.xyz * r1.xxx;
  r8.xyz = float3(1.70000005,1.70000005,1.70000005) * r8.xyz;
  r6.xyz = r8.xyz * r6.yzw;
  r0.w = saturate(r5.y * 2 + 0.5);
  r0.w = r0.w * 0.699999988 + 0.300000012;
  r8.xyz = r6.xyz * r0.www;
  r1.x = dot(r8.xyz, float3(0.300000012,0.600000024,0.100000001));
  r6.xyz = -r6.xyz * r0.www + r1.xxx;
  r6.xyz = r6.xyz * float3(0.800000012,0.800000012,0.800000012) + r8.xyz;
  r0.xyz = float3(-1,-1,-1) + r0.xyz;
  r0.xyz = r0.xyz * float3(0.800000012,0.800000012,0.800000012) + float3(1,1,1);
  r0.xyz = r6.xyz * r0.xyz;
  r1.xzw = r3.xyz * r1.zzz + r7.xyz;
  r1.xzw = r1.xzw + r5.xzw;
  r0.xyz = r0.xyz * r2.xyz + -r1.xzw;
  r0.xyz = r1.yyy * r0.xyz + r1.xzw;
  r0.w = dot(r0.xyz, float3(0.300000012,0.600000024,0.100000001));
  r1.x = cmp(1 < r0.w);
  r1.yzw = r0.xyz / r0.www;
  r0.w = log2(r0.w);
  r0.w = r0.w * 0.693147182 + 1;
  r0.w = log2(r0.w);
  r0.w = r0.w * 0.693147182 + 1;
  r1.yzw = r1.yzw * r0.www;
  r0.xyz = r1.xxx ? r1.yzw : r0.xyz;
  r0.xyz = r2.xyz * v9.xyz + r0.xyz;
  o0.xyz = r4.xyz * cb0[45].xyz + r0.xyz;
  o0.w = 1;
  return;
}