struct DroneData {
    float3 begin;
    float3 end;
    int endId;
    float direction;
    float maxt;
    float t;
    int itemId;
    int itemCount;
    int inc;
    int gene;
};

sampler2D _NoiseMap;

// u,v are normalized
float3 vector_slerp(float3 u, float3 v, float t)
{
    float dotuv = dot(u, v);
    float rad = acos(dotuv);
    
    float3 axis = 0;
    if (dotuv + 1 < 1e-5)
        axis = abs(u.x) > abs(u.z) ? float3(-u.y, u.x, 0) : float3(0, -u.z, u.y);
    else
        axis = cross(u, v);
    axis = normalize(axis);
    rad *= t;
    float half_rad = rad * 0.5;
    float cosr = cos(half_rad);
    float sinr = sin(half_rad);
    
    float4 q = float4(axis.xyz * sinr, cosr);
    
    float num = q.x * 2;
    float num2 = q.y * 2;
    float num3 = q.z * 2;
    float num4 = q.x * num;
    float num5 = q.y * num2;
    float num6 = q.z * num3;
    float num7 = q.x * num2;
    float num8 = q.x * num3;
    float num9 = q.y * num3;
    float num10 = q.w * num;
    float num11 = q.w * num2;
    float num12 = q.w * num3;
    
    float3 result = 0;
    result.x = (1 - (num5 + num6)) * u.x + (num7 - num12) * u.y + (num8 + num11) * u.z;
    result.y = (num7 + num12) * u.x + (1 - (num4 + num6)) * u.y + (num9 - num10) * u.z;
    result.z = (num8 - num11) * u.x + (num9 + num10) * u.y + (1 - (num4 + num5)) * u.z;
    
    return result;
}

void transform(DroneData obj, out float3 pos, out float3 axisx, out float3 axisy, out float3 axisz)
{
    float3 u = obj.begin;
    float3 v = obj.end;
    float lu = length(u);
    float lv = length(v);
    float t = obj.t;
    float ct = clamp(t, 0, obj.maxt);
    float ot = abs(t - ct);
    float st = saturate(t / obj.maxt);
    st = (3 - st - st) * st * st; // ease in-out
    u /= lu;
    v /= lv;
    float3 tv = vector_slerp(u, v, st);
    float alt = lerp(lu, lv, st) + 8;
    float biasCoef = pow((0.5 - abs(st - 0.5)) * 4, 0.4);
    
    alt += biasCoef * 1.3;
    alt -= pow(ot, 1.5) * (st * lv + (1 - st) * lu - 200) * 0.4;
    
    pos = tv * alt;
    
    axisy = normalize(pos);
    axisz = normalize(obj.end - obj.begin) * obj.direction;
    axisx = normalize(cross(axisy, axisz));
    axisz = normalize(cross(axisx, axisy));
    
    float gene = (float)obj.gene;
    float2 rand = tex2Dlod(_NoiseMap, float4(gene * 0.0078125 + 0.00390625, gene*0.001, 0, 0)).rg - 0.5;
    pos += rand.y * axisy * 3;
    pos += rand.x * (axisx * obj.direction) * 7 * biasCoef;
}