#include "UnityCG.cginc"

struct GPUOBJECT
{
  uint objId;
  float3 pos;
  float4 rot;
};

struct AnimData
{
  float time;
  float prepare_length;
  float working_length;
  uint state;
  float power;
};

inline float3 rotate_vector_fast(float3 v, float4 r){ 
    return v + cross(2.0 * r.xyz, cross(r.xyz, v) + r.w * v);
}

inline float SchlickFresnel_Approx(float F0, float vDotH)
{
    return F0 + (1 - F0) * exp2((-5.55473 * vDotH - 6.98316) * vDotH);
}

inline float3 calculateLightFromHeadlamp(float4 headlampPos, float3 upDir, float3 lightDir, float3 worldNormal) {
    float isHeadlampOn = headlampPos.w >= 0.5 ? 1.0 : 0.0;
    if (headlampPos.w < 0.5) return float3(0, 0, 0);
    
    float distanceFromHeadlamp = length(headlampPos) - 5.0;
    float headlampVisibility = saturate(distanceFromHeadlamp);
    float daylightDimFactor = saturate(dot(-upDir, lightDir) * 5.0);

    float3 directionToPlayer = headlampPos - upDir * distanceFromHeadlamp;
    float distObjToPlayer = length(directionToPlayer);
    directionToPlayer /= distObjToPlayer;

    float falloff = pow(max((20.0 - distObjToPlayer) * 0.05, 0), 2);
    float3 lightColor = float3(1.3, 1.1, 0.6);

    float lightIntensity = headlampVisibility * daylightDimFactor * falloff * saturate(dot(directionToPlayer, worldNormal));
    float3 computedLight = lightIntensity * lightColor;

    return distObjToPlayer < 0.001 ? daylightDimFactor * lightColor : computedLight;
}

inline float distributionGGX(float roughness, float nDotH) {
    float a = roughness; //NDF formula says `a` should be roughness^2
        //"We also adopted Disney’s reparameterization of α = Roughness2."
        //but a = Roughness here
    float denom = rcp(nDotH * nDotH * (a * a - 1.0) + 1); //r0.w
    return denom * denom * a * a; //r0.w
    //missing (1/PI) *
}

inline float geometrySchlickGGX(float roughness, float nDotV, float nDotL) {
    float k = pow(roughness * roughness + 1.0, 2) * 0.125; //r2.w does "roughness" mean perceptualroughness^2 or ^4?
        //"We also chose to use Disney’s modification to reduce “hotness” by remapping roughness using (Roughness+1)/2 before squaring."
        //but this is doing (Roughness^2+1)/2 before squaring
    float ggxNV = nDotV * (1.0 - k) + k; //r5.x
    float ggxNL = nDotL * (1.0 - k) + k; //r1.z
    return rcp(ggxNL * ggxNV); //r1.x
    //missing (nDotL * nDotV) *
}

inline float GGX(float roughness, float metallic, float nDotH, float nDotV, float nDotL, float vDotH) {
    
    float D = distributionGGX(roughness, nDotH);   
    float G = geometrySchlickGGX(roughness, nDotV, nDotL); //r1.x
    float F = SchlickFresnel_Approx(metallic, vDotH);
    
    return (D * F * G) / 4.0;
    //should be (4.0 * nDotV * nDotL)
}

int _VertexSize;
uint _VertexCount;
uint _FrameCount;
StructuredBuffer<float> _VertaBuffer;

inline void animateWithVerta(uint vertexID, float time, float prepare_length, float working_length, inout float3 pos, inout float3 normal, inout float3 tangent) {
    float frameCount = prepare_length > 0 ? _FrameCount - 1 : _FrameCount; //r0.w
    bool skipVerta = frameCount <= 0 || (_VertexSize != 9 && _VertexSize != 6 && _VertexSize != 3) || _VertexCount <= 0 || working_length <= 0; //r0.x
    if (!skipVerta) {
      float prepareTime = time >= prepare_length && prepare_length > 0 ? 1.0 : 0; //r0.x
      prepareTime = frac(time / (prepare_length + working_length)) * (frameCount - 1) + prepareTime;
      prepareTime = frameCount - 1 <= 0 ? 0 : prepareTime; //r0.x
      uint prepareTimeSec = (uint)prepareTime; //r0.z
      float prepareTimeFrac = frac(prepareTime); //r0.x
      int frameStride = _VertexSize * _VertexCount; //r0.w
      int offset = vertexID * _VertexSize; //r1.x
      uint frameIdx = mad(frameStride, prepareTimeSec, offset); //r3.y
      uint nextFrameIdx = mad(frameStride, prepareTimeSec + 1, offset); //r0.z
      
      if (_VertexSize == 3) {
        pos.x = lerp(_VertaBuffer[frameIdx], _VertaBuffer[nextFrameIdx], prepareTimeFrac);
        pos.y = lerp(_VertaBuffer[frameIdx + 1], _VertaBuffer[nextFrameIdx + 1], prepareTimeFrac);
        pos.z = lerp(_VertaBuffer[frameIdx + 2], _VertaBuffer[nextFrameIdx + 2], prepareTimeFrac);
      } else {
        if (_VertexSize == 6) {
          pos.x = lerp(_VertaBuffer[frameIdx], _VertaBuffer[nextFrameIdx], prepareTimeFrac);
          pos.y = lerp(_VertaBuffer[frameIdx + 1], _VertaBuffer[nextFrameIdx + 1], prepareTimeFrac);
          pos.z = lerp(_VertaBuffer[frameIdx + 2], _VertaBuffer[nextFrameIdx + 2], prepareTimeFrac);
          normal.x = lerp(_VertaBuffer[frameIdx + 3], _VertaBuffer[nextFrameIdx + 3], prepareTimeFrac);
          normal.y = lerp(_VertaBuffer[frameIdx + 4], _VertaBuffer[nextFrameIdx + 4], prepareTimeFrac);
          normal.z = lerp(_VertaBuffer[frameIdx + 5], _VertaBuffer[nextFrameIdx + 5], prepareTimeFrac);
        } else {
          if (_VertexSize == 9) {
            pos.x = lerp(_VertaBuffer[frameIdx], _VertaBuffer[nextFrameIdx], prepareTimeFrac);
            pos.y = lerp(_VertaBuffer[frameIdx + 1], _VertaBuffer[nextFrameIdx + 1], prepareTimeFrac);
            pos.z = lerp(_VertaBuffer[frameIdx + 2], _VertaBuffer[nextFrameIdx + 2], prepareTimeFrac);
            normal.x = lerp(_VertaBuffer[frameIdx + 3], _VertaBuffer[nextFrameIdx + 3], prepareTimeFrac);
            normal.y = lerp(_VertaBuffer[frameIdx + 4], _VertaBuffer[nextFrameIdx + 4], prepareTimeFrac);
            normal.z = lerp(_VertaBuffer[frameIdx + 5], _VertaBuffer[nextFrameIdx + 5], prepareTimeFrac);
            tangent.x = lerp(_VertaBuffer[frameIdx + 6], _VertaBuffer[nextFrameIdx + 6], prepareTimeFrac);
            tangent.y = lerp(_VertaBuffer[frameIdx + 7], _VertaBuffer[nextFrameIdx + 7], prepareTimeFrac);
            tangent.z = lerp(_VertaBuffer[frameIdx + 8], _VertaBuffer[nextFrameIdx + 8], prepareTimeFrac);
          }
        }
      }
    }
}

inline float3 calculateBinormal(float4 tangent, float3 normal ) {
    float sign = tangent.w * unity_WorldTransformParams.w;
    float3 binormal = cross(normal.xyz, tangent.xyz) * sign;
}