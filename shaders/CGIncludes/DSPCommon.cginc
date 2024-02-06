#include "UnityCG.cginc"

#define INV_TEN_PI 0.0318309888

UNITY_DECLARE_TEXCUBE(_Global_PGI);
float _PGI_Gray;

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

float3 rotate_vector_fast(float3 v, float4 r){
    return v + cross(2.0 * r.xyz, cross(r.xyz, v) + r.w * v);
}

float3 GammaToLinear_Approx(float c)
{
    return pow((c + 0.055)/1.055, 2.4);
}

float3 GammaToLinear_Approx(float3 c)
{
    return pow((c + 0.055)/1.055, 2.4);
}

float SchlickFresnel_Approx(float F0, float vDotH)
{
    return F0 + (1 - F0) * exp2((-5.55473 * vDotH - 6.98316) * vDotH);
}

float3 calculateLightFromHeadlamp(float4 headlampPos, float3 upDir, float3 lightDir, float3 worldNormal, float brightness) {
    bool isHeadlampOn = headlampPos.w >= 0.5;
    if (!isHeadlampOn) return float3(0, 0, 0);

    float distanceFromHeadlamp = length(headlampPos) - 5.0;
    float headlampVisibility = saturate(distanceFromHeadlamp);
    float daylightDimFactor = saturate(dot(-upDir, lightDir) * 5.0);

    float3 directionToPlayer = headlampPos - upDir * distanceFromHeadlamp;
    float distObjToPlayer = length(directionToPlayer);
    directionToPlayer /= distObjToPlayer;
    
    float falloff = pow(max((20.0 - distObjToPlayer) * 0.05, 0), 2);
    float lightIntensity = falloff * saturate(dot(directionToPlayer, worldNormal));
    lightIntensity = distObjToPlayer < 0.001 ? 1 : lightIntensity;
    lightIntensity = lightIntensity * daylightDimFactor * headlampVisibility;
    
    float3 lightColor = float3(1.3, 1.1, 0.6) * brightness;
    return lightColor * lightIntensity;
}

float3 calculateLightFromHeadlamp(float4 headlampPos, float3 upDir, float3 lightDir, float3 worldNormal) {
    return calculateLightFromHeadlamp(headlampPos, upDir, lightDir, worldNormal, 1.0);
}

float distributionGGX(float roughness, float nDotH) {
    float a = roughness; //NDF formula says `a` should be roughness^2
        //"We also adopted Disney’s reparameterization of α = Roughness2."
        //but a = Roughness here
    float denom = rcp(nDotH * nDotH * (a * a - 1.0) + 1); //r0.w
    return denom * denom * a * a; //r0.w
    //missing (1/PI) *
}

float geometrySchlickGGX(float roughness, float nDotV, float nDotL) {
    float k = pow(roughness * roughness + 1.0, 2) * 0.125; //r2.w does "roughness" mean perceptualroughness^2 or ^4?
        //"We also chose to use Disney’s modification to reduce “hotness” by remapping roughness using (Roughness+1)/2 before squaring."
        //but this is doing (Roughness^2+1)/2 before squaring
    float ggxNV = nDotV * (1.0 - k) + k; //r5.x
    float ggxNL = nDotL * (1.0 - k) + k; //r1.z
    return rcp(ggxNL * ggxNV); //r1.x
    //missing (nDotL * nDotV) *
}

float GGX(float roughness, float metallic, float nDotH, float nDotV, float nDotL, float vDotH) {

    float D = distributionGGX(roughness, nDotH);
    float G = geometrySchlickGGX(roughness, nDotV, nDotL); //r1.x
    float F = SchlickFresnel_Approx(metallic, vDotH);

    return (D * F * G) / 4.0;
}

#if defined(_ENABLE_VFINST)

int _VertexSize;
uint _VertexCount;
uint _FrameCount;
StructuredBuffer<float> _VertaBuffer;

void animateWithVerta(uint vertexID, float time, float prepare_length, float working_length, inout float3 pos, inout float3 normal, inout float3 tangent) {
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

#else

void animateWithVerta(uint vertexID, float time, float prepare_length, float working_length, inout float3 pos, inout float3 normal, inout float3 tangent) {
    return;
}


#endif

float3 calculateBinormal(float4 tangent, float3 normal ) {
    float sign = tangent.w * unity_WorldTransformParams.w;
    float3 binormal = cross(normal.xyz, tangent.xyz) * sign;
    return binormal;
}



/* What image is reflected in metallic surfaces and how reflective is it? */
float3 reflection(float perceptualRoughness, float3 metallic, float3 upDir, float3 viewDir, float3 worldNormal, out float reflectivity) {
    bool validUpDir = dot(upDir, upDir) > 0.01;
    bool upDirNotStraightUp = upDir.y < 0.9999;
    
    float3 rightDir = normalize(cross(upDir, float3(0, 1, 0)));
    rightDir = validUpDir && upDirNotStraightUp ? rightDir : float3(1, 0, 0);
    
    bool validRightDir = dot(rightDir, rightDir) > 0.01;
    
    float3 fwdDir = normalize(cross(rightDir, upDir));
    fwdDir = validUpDir && validRightDir ? fwdDir : float3(0, 0, 1);
    
    float3 reflectDir = reflect(-viewDir, worldNormal);
    
    float3 worldReflect;
    worldReflect.x = dot(reflectDir, -rightDir);
    worldReflect.y = dot(reflectDir, upDir);
    worldReflect.z = dot(reflectDir, -fwdDir);
    
    float lod = 10.0 * pow(perceptualRoughness, 0.4);
    float3 reflectColor = UNITY_SAMPLE_TEXCUBE_LOD(_Global_PGI, worldReflect, lod).xyz;
    float greyscaleReflectColor = dot(reflectColor, float3(0.29, 0.58, 0.13));
    reflectColor = lerp(reflectColor, greyscaleReflectColor.xxx, _PGI_Gray);
    
    float scaledMetallic = metallic * 0.7 + 0.3;
    float smoothness = 1.0 - perceptualRoughness;
    reflectivity = scaledMetallic * smoothness;
    
    return reflectColor * reflectivity;
}

float3 calculateSunlightColor(float3 sunlightColor, float upDotL, float3 sunsetColor0, float3 sunsetColor1, float3 sunsetColor2, float3 lightColorScreen) {
    sunlightColor = lerp(sunlightColor, float3(1,1,1), lightColorScreen);

    float3 sunsetColor = float3(1,1,1);
    if (upDotL <= 1) {
        sunsetColor0 = lerp(sunsetColor0, float3(1,1,1), lightColorScreen);
        sunsetColor1 = lerp(sunsetColor1, float3(1,1,1), lightColorScreen) * float3(1.25, 1.25, 1.25);
        sunsetColor2 = lerp(sunsetColor2, float3(1,1,1), lightColorScreen) * float3( 1.5,  1.5,  1.5);

        float3 blendDawn     = lerp(float3(0,0,0), sunsetColor2,  saturate( 5 * (upDotL + 0.3)));
        float3 blendSunrise  = lerp(sunsetColor2,  sunsetColor1,  saturate( 5 * (upDotL + 0.1)));
        float3 blendMorning  = lerp(sunsetColor1,  sunsetColor0,  saturate(10 * (upDotL - 0.1)));
        float3 blendDay      = lerp(sunsetColor0,  float3(1,1,1), saturate( 5 * (upDotL - 0.2)));

        sunsetColor = upDotL > -0.1 ? blendSunrise : blendDawn;
        sunsetColor = upDotL >  0.1 ? blendMorning : sunsetColor.xyz;
        sunsetColor = upDotL >  0.2 ? blendDay     : sunsetColor.xyz;
    }

    return sunsetColor.xyz * sunlightColor.xyz;
}

float3 calculateSunlightColor(float3 sunlightColor, float upDotL, float3 sunsetColor0, float3 sunsetColor1, float3 sunsetColor2) {
    return calculateSunlightColor(sunlightColor, upDotL, sunsetColor0, sunsetColor1, sunsetColor2, float3(0,0,0));
}

float3 calculateAmbientColor(float3 upDir, float3 lightDir, float3 ambientColor0, float3 ambientColor1, float3 ambientColor2) {
    //UpdotL: position of star in the sky, relative to the object.
    //1 is noon
    //0 is sunrise/sunset
    //-1 is midnight
    float UpdotL = dot(upDir, lightDir);
    
    //starting when the star is below the horizon, lerp from ambient2 to ambient1 to ambient0 at noon, then back down again
    float3 ambientTwilight = lerp(ambientColor2, ambientColor1, saturate(UpdotL * 3.0 + 1)); //-33% to 0%
    float3 ambientLowSun = lerp(ambientColor1, ambientColor0, saturate(UpdotL * 3.0)); // 0% - 33%
    return UpdotL > 0 ? ambientLowSun : ambientTwilight;
}