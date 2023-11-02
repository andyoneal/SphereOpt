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

inline float3 calculateBinormal(float4 tangent, float3 normal ) {
    float sign = tangent.w * unity_WorldTransformParams.w;
    float3 binormal = cross(normal.xyz, tangent.xyz) * sign;
    return binormal;
}

UNITY_DECLARE_TEXCUBE(_Global_PGI);

/* What image is reflected in metallic surfaces and how reflective is it? */
inline float3 reflection(float perceptualRoughness, float3 metallicLow, float3 upDir, float3 viewDir, float3 worldNormal, out float reflectivity) {
    float upDirMagSqr = dot(upDir, upDir);
    bool validUpDirY = upDirMagSqr > 0.01 && upDir.y < 0.9999;
    float3 xaxis = validUpDirY ? normalize(cross(upDir.zxy, float3(0, 0, 1))) : float3(0, 1, 0);
    bool validUpDirXY = dot(xaxis, xaxis) > 0.01 && upDirMagSqr > 0.01;
    float3 zaxis = validUpDirXY ? normalize(cross(xaxis.yzx, upDir)) : float3(0, 0, 1);
    
    float3 worldReflect = reflect(-viewDir, worldNormal);
    float3 reflectDir;
    reflectDir.x = dot(worldReflect.zxy, -xaxis);
    reflectDir.y = dot(worldReflect, upDir);
    reflectDir.z = dot(worldReflect, -zaxis);
    
    float reflectLOD = 10.0 * pow(perceptualRoughness, 0.4);
    float3 g_PGI = UNITY_SAMPLE_TEXCUBE_LOD(_Global_PGI, reflectDir, reflectLOD);
    
    float scaled_metallicLow = metallicLow * 0.7 + 0.3;
    reflectivity = scaled_metallicLow * (1.0 - perceptualRoughness);
    
    return g_PGI * reflectivity;
}