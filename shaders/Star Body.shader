Shader "VF Shaders/Star Shaders/Star Body" {
    Properties {
        _Color0 ("Sun Color 0", Color) = (1,1,1,1)
        _Color1 ("Sun Color 1", Color) = (1,1,1,1)
        _Color2 ("Sun Color 2", Color) = (1,1,1,1)
        _Color3 ("Sun Color 3", Color) = (1,1,1,1)
        _Multiplier ("Multiplier", Float) = 2.5
        _NoiseTile ("Noise Tile", Float) = 50
        _NoiseSpeed ("Noise Speed", Float) = 0.2
        _ChaosTile ("Chaos Tile", Float) = 1
        _ChaosDistort ("Chaos Distort", Float) = 0.2
        _ChaosOverlay ("Chaos Overlay", Float) = 0.4
        _SpotIntens ("Spots Intensity", Float) = 4
        _RimPower ("Rim Power", Float) = 5
        _RotSpeed ("Rotate Speed", Float) = 0.04
    }
    SubShader {
        LOD 100
        Tags { "RenderType" = "Opaque" }
        Pass {
            LOD 100
            Tags { "RenderType" = "Opaque" }
            Blend One One, One One
            //GpuProgramID 55340
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "UnityCG.cginc"
            #pragma target 5.0
            struct v2f
            {
                float4 pos : SV_Position0;
                float3 upDir : TEXCOORD0; //v1
                float3 worldPos : TEXCOORD1; //v2
                float3 worldNormal : TEXCOORD2; //v3
            };
            
            struct fout
            {
                float4 sv_target : SV_Target0;
            };
            
            float4 _Color0;
            float4 _Color1;
            float4 _Color2;
            float4 _Color3;
            float _Multiplier;
            float _NoiseTile;
            float _NoiseSpeed;
            float _ChaosTile;
            float _ChaosDistort;
            float _ChaosOverlay;
            float _SpotIntens;
            float _RimPower;
            float _RotSpeed;
            
            v2f vert(appdata_full v)
            {
                v2f o;

                o.pos.xyzw = UnityObjectToClipPos(float4(v.vertex.xyz, 1));
                o.upDir.xyz = normalize(v.vertex.xyz);
                o.worldPos.xyz = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldNormal.xyz = mul((float3x3)unity_ObjectToWorld, v.normal.xyz);
                
                return o;
            }
            
            fout frag(v2f i)
            {
                fout o;
                float4 r0,r1,r2,r3,r4,r5,r6,r7,r8,r9,r10,r11,r12,r13,r14,r15,r16,r17,r18,r19,r20,r21,r22,r23,r24,r25;
                
                r4.xyz = (_NoiseTile * i.upDir) / 8.0;
                r4.w = _Time.y * _NoiseSpeed;
                
                r6.x = sin(_RotSpeed * -r4.w);
                r7.x = cos(_RotSpeed * -r4.w);
                r5.x = sin(0.25 * _RotSpeed * -r4.w);
                r8.x = cos(0.25 * _RotSpeed * -r4.w);
                
                r4.z = r4.z * r7.x + r4.x * r6.x;
                r4.x = r4.x * r7.x - r4.x * r6.x;
                
                r5.y = dot(r4.xyzw, float4(0.309017003,0.309017003,0.309017003,0.309017003)); // 1/(1+sqrt(5))
                r6.xyzw = floor(r5.yyyy + r4.xyzw);
                r7.xyzw = r4.xyzw - r6.xyzw;
                
                r3.xzw = r4.xzw;
                
                r4.x = dot(r6.xyzw, float4(0.138196602,0.138196602,0.138196602,0.138196602)); // 1/(5+sqrt(5))
                r7.xyzw = r7.xyzw + r4.xxxx;
                r5.yzw = r7.xxx >= r7.yzw ? float3(0,0,0) : float3(1,1,1);
                r4.xyz = r7.xxx >= r7.yzw ? float3(1,1,1) : 0;
                r9.xyz = r7.yyz >= r7.zww ? float3(1,1,1) : float3(0,0,0);
                r2.xyz = r7.yyz >= r7.zww ? float3(1,1,1) : 0;
                r2.w = 1;
                
                r10.z = r5.w - r9.y + r2.z;
                r2.y = r5.y + r2.x + r2.y;
                r2.z = 1 + r10.z;
                r10.w = r5.z - r9.x + r2.w - r9.z;
                r2.w = 1 + r10.w;
                r2.x = r4.x + r4.y + r4.z;
                r9.xyzw = min(float4(1,1,1,1), r2.xyzw);
                
                r10.xy = r2.xy;
                
                r2.xyzw = r10.xyzw - float4(2,2,1,1);
                r10.xyzw = saturate(r10.xyzw - float4(1,1,0,0));
                r2.xyzw = max(float4(0,0,0,0), r2.xyzw);

                r6.xyzw = r6.xyzw - floor(r6.xyzw / 289.0) * 289;
                
                r1.x = r2.w;
                r1.y = r10.w;
                r1.z = r9.w;
                r1.w = 1;
                
                r1.xyzw = pow(r1.xyzw, 2) * 34.0 + r6.wwww + r1.xyzw;
                r1.xyzw = r1.xyzw - floor(r1.xyzw / 289.0) * 289.0 + r6.zzzz;
                
                r0.x = r2.z;
                r0.y = r10.z;
                r0.z = r9.z;
                r0.w = 1;
                
                r0.xyzw = pow(r1.xyzw + r0.xyzw, 2) * 34.0 + r1.xyzw + r0.xyzw;
                r0.xyzw = r0.xyzw - floor(r0.xyzw / 289.0) * 289.0 + r6.yyyy;

                r1.x = r2.y;
                r1.y = r10.y;
                r1.z = r9.y;
                r1.w = 1;
                
                r0.xyzw = pow(r1.xyzw + r0.xyzw, 2) * 34.0 + r1.xyzw + r0.xyzw;
                r0.xyzw = r0.xyzw - floor(r0.xyzw / 289.0) * 289.0 + r6.xxxx;
                
                r1.z = r9.x;
                r1.w = 1;
                
                r9.xyzw = 3.0 / (5.0 + sqrt(5.0)) + r7.xyzw - r9.xyzw; //0.414589792
                
                r1.x = r2.x;
                
                r2.xyzw = 1.0 / (5.0 + sqrt(5.0)) + r7.xyzw - r2.xyzw; //0.138196602
                
                r1.y = r10.x;
                
                r10.xyzw = 2.0 / (5.0 + sqrt(5.0)) + r7.xyzw - r10.xyzw; //0.2763932023
                
                r0.xyzw = pow(r1.xyzw + r0.xyzw, 2) * 34.0 + r1.xyzw + r0.xyzw;
                r0.xyzw = r0.xyzw - floor(r0.xyzw / 289.0) * 289.0;
                
                r1.xyz = float3(0.00340136047,0.0204081628,0.142857149) * r0.xxx;
                r1.xyz = floor(float3(7,7,7) * frac(r1.xyz));
                r1.xyz = (r1.xyz / 7.0) - float3(1,1,1); //0.14285715
                
                r0.x = dot(-r1.xyz, float3(1,1,1));
                r11.w = 1.5 - r0.x;
                r0.x = r11.w >= 0 ? 0 : 1;
                r11.xyz = r1.xyz + r0.xxx;
                r1.y = dot(r11.xyzw, r11.xyzw);
                
                r4.xyz = r0.yyy / float3(294, 49, 7);
                r4.xyz = floor(float3(7,7,7) * frac(r4.xyz));
                r4.xyz = r4.xyz / 7.0 - float3(1,1,1);
                
                r0.x = dot(-r4.xyz, float3(1,1,1));
                r12.w = 1.5 - r0.x;
                r0.x = r12.w >= 0 ? 0 : 1;
                r12.xyz = r4.xyz + r0.xxx;
                r1.z = dot(r12.xyzw, r12.xyzw);
                
                r0.xyz = r0.zzz / float3(294, 49, 7);
                r4.xyz = r0.www / float3(294, 49, 7);
                r4.xyz = floor(float3(7,7,7) * frac(r4.xyz));
                r4.xyz = r4.xyz / 7.0 - float3(1,1,1);
                r0.xyz = floor(float3(7,7,7) * frac(r0.xyz));
                r0.xyz = r0.xyz / 7.0 - float3(1,1,1);
                
                r13.w = 1.5 + dot(r0.xyz, float3(1,1,1));
                r0.w = r13.w >= 0 ? 0 : 1;
                r13.xyz = r0.xyz + r0.www;
                r1.w = dot(r13.xyzw, r13.xyzw);
                
                r0.x = pow(r6.w, 2) * 34 + r6.w;
                r0.x = r0.x - floor(r0.x / 289.0) * 289 + r6.z;
                r0.x = pow(r0.x, 2) * 34 + r0.x;
                r0.x = r0.x - floor(r0.x / 289.0) * 289 + r6.y;
                r0.x = pow(r0.x, 2) * 34 + r0.x;
                r0.x = r0.x - floor(r0.x / 289.0) * 289 + r6.x;
                r0.x = pow(r0.x, 2) * 34 + r0.x;
                r0.x = r0.x - floor(r0.x / 289.0) * 289;
                
                r0.xyz = floor(float3(7,7,7) * frac(r0.xxx / float3(294, 49, 7)));
                r0.xyz = (r0.xyz / 7.0) - float3(1,1,1);
                r6.w = 1.5 + dot(r0.xyz, float3(1,1,1));
                r0.w = r6.w >= 0 ? 0 : 1;
                r6.xyz = r0.xyz + r0.www;
                r1.x = dot(r6.xyzw, r6.xyzw);
                
                r0.xyzw = float4(1.79284286,1.79284286,1.79284286,1.79284286) - r1.xyzw * float4(0.853734732,0.853734732,0.853734732,0.853734732);
                
                r1.y = dot(r11.xyzw * r0.y, r2.xyzw);
                r2.y = dot(r2.xyzw, r2.xyzw);
                
                r1.z = dot(r12.xyzw * r0.z, r10.xyzw);
                r2.z = dot(r10.xyzw, r10.xyzw);
                
                r0.x = dot(r13.xyzw * r0.w, r9.xyzw);
                r9.x = dot(r9.xyzw, r9.xyzw);
                
                r1.x = dot(r6.xyzw * r0.x, r7.xyzw);
                r2.x = dot(r7.xyzw, r7.xyzw);
                
                r6.xyzw = r7.xyzw - (1.0 / sqrt(5));
                
                r2.xyz = max(float3(0,0,0), float3(0.6, 0.6, 0.6) - r2.xyz);
                r2.xyz = pow(r2.xyz, 4);
                r0.z = dot(r2.xyz, r1.xyz);
                
                r1.w = 1.5 + dot(r4.xyz, float3(1,1,1));
                r0.w = r1.w >= 0 ? 0 : 1;
                r1.xyz = r4.xyz + r0.www;
                
                r0.w = 1.79284286 - dot(r1.xyzw, r1.xyzw) * 0.853734732;
                r0.y = dot(r1.xyzw * r0.w, r6.xyzw);
                r9.y = dot(r6.xyzw, r6.xyzw);
                
                r1.xy = max(float2(0,0), float2(0.6, 0.6) - r9.xy);
                r1.xy = pow(r1.xy,5);
                r0.x = r0.z + dot(r1.xy, r0.xy);
                r0.y = r0.x * 9.8 - r4.w;
                
                r1.xyzw = float4(2, 0.25, 2, 2) * r3.xyzw;
                r0.z = r1.x * r8.x - r1.z * r5.x;
                r1.z = r1.z * r8.x + r1.x * r5.x;
                r1.x = r0.z + r0.y;
                
                r0.y = dot(r1.xyzw, float4(0.309017003,0.309017003,0.309017003,0.309017003)); // 1/(1+sqrt(5))
                r2.xyzw = floor(r1.xyzw + r0.yyyy);
                r5.xyzw = r2.xyzw - floor(r2.xyzw / 289.0) * 289.0;
                
                r0.y = pow(r5.w, 2) * 34 + r5.w;
                r0.y = r0.y - floor(r0.y / 289.0) * 289 + r5.z;
                
                r0.y = pow(r0.y, 2) * 34 + r0.y;
                r0.y = r0.y - floor(r0.y / 289.0) * 289 + r5.y;
                
                r0.y = pow(r0.y, 2) * 34 + r0.y;
                r0.y = r0.y - floor(r0.y / 289.0) * 289 + r5.x;
                
                r0.y = pow(r0.y, 2) * 34 + r0.y;
                r0.y = r0.y - floor(r0.y / 289.0) * 289;
                
                r0.yzw = r0.yyy / float3(294, 49, 7);  // 1/294, 1/49, 1/7
                r0.yzw = floor(float3(7,7,7) * frac(r0.yzw));
                r0.yzw = r0.yzw / 7.0 - float3(1,1,1);
                
                r6.w = 1.5 + dot(r0.yzw, float3(1,1,1));
                r4.x = r6.w >= 0 ? 0 : 1;
                r6.xyz = r4.xxx + r0.yzw;
                r7.x = dot(r6.xyzw, r6.xyzw);
                
                r0.y = dot(r2.xyzw, float4(0.138196602,0.138196602,0.138196602,0.138196602)); //1/(5+sqrt(5))
                r2.xyzw = r1.xyzw - r2.xyzw + r0.yyyy;
                r4.xyz = r2.xxx >= r2.yzw ? float3(1,1,1) : 0;
                r0.yzw = r2.xxx >= r2.yzw ? float3(0,0,0) : float3(1,1,1);
                
                r8.x = r4.x + r4.y + r4.z;
                
                r9.xyz = r2.yyz >= r2.zww ? float3(1,1,1) : 0;
                r4.xyz = r2.yyz >= r2.zww ? float3(1,1,1) : float3(0,0,0);
                
                r8.y = r9.x + r9.y + r0.y;
                r9.x = 1 - r4.y + r0.w;
                r9.z = r9.z - r4.x + r0.z;
                r9.w = r9.x - r4.z;
                r8.z = 1 + r9.z;
                r8.w = 1 + r9.w;
                
                r10.xyzw = min(float4(1,1,1,1), r8.yzxw);
                r9.xy = r8.xy;
                r8.z = r10.y;
                r11.xyzw = r9.xyzw - float4(2,2,1,1);
                r9.xyzw = saturate(r9.xyzw - float4(1,1,0,0));
                
                r11.xyzw = max(float4(0,0,0,0), r11.xyzw);
                r12.x = r11.w;
                r12.y = r9.w;
                r12.z = r10.w;
                r12.w = 1;
                
                r12.xyzw = pow(r12.xyzw, 2) * 34.0 + r12.xyzw + r5.wwww;
                r12.xyzw = r12.xyzw - floor(r12.xyzw / 289.0) * 289.0 + r5.zzzz;
                
                r8.x = r11.z;
                r8.y = r9.z;
                r8.w = 1;
                
                r8.xyzw = pow(r8.xyzw, 2) * 34.0 + r12.xyzw + r8.xyzw;
                r8.xyzw = r8.xyzw - floor(r8.xyzw / 289.0) * 289.0 + r5.yyyy;
                
                r12.z = r10.x;
                r12.x = r11.y;
                r12.y = r9.y;
                r12.w = 1;
                
                r8.xyzw = pow(r8.xyzw, 2) * 34.0 + r12.xyzw + r8.xyzw;
                r5.xyzw = r8.xyzw - floor(r8.xyzw / 289.0) * 289.0 + r5.xxxx;
                
                r8.xyzw = float4(0.414589792,0.414589792,0.414589792,0.414589792) + (r2.xyzw - r10.zxyw); // 3/(5+sqrt(5)
                
                r10.x = r11.x;
                
                r11.xyzw = float4(0.138196602,0.138196602,0.138196602,0.138196602) + (r2.xyzw - r11.xyzw); // 1/(5+sqrt(5)
                
                r10.y = r9.x;
                
                r9.xyzw = float4(0.276393205,0.276393205,0.276393205,0.276393205) + (r2.xyzw - r9.xyzw); // 2/(5+sqrt(5)
                
                r10.w = 1;
                
                r5.xyzw = pow(r5.xyzw, 2) * 34.0 + r10.xyzw + r5.xyzw;
                r5.xyzw = r5.xyzw - floor(r5.xyzw / 289.0) * 289.0;
                
                r0.yzw = float3(0.00340136047,0.0204081628,0.142857149) * r5.xxx; // 1/294, 1/49, 1/7
                r0.yzw = floor(float3(7,7,7) * frac(r0.yzw));
                r0.yzw = r0.yzw / 7.0 - float3(1,1,1);
                r4.x = dot(-r0.yzw, float3(1,1,1));
                r10.w = 1.5 - r4.x;
                r4.x = r10.w >= 0 ? 0 : 1;
                r10.xyz = r4.xxx + r0.yzw;
                r7.y = dot(r10.xyzw, r10.xyzw);
                
                r0.yzw = float3(0.00340136047,0.0204081628,0.142857149) * r5.yyy;  // 1/294, 1/49, 1/7
                r0.yzw = floor(float3(7,7,7) * frac(r0.yzw));
                r0.yzw = r0.yzw / 7.0 - float3(1,1,1);
                r4.x = dot(-r0.yzw, float3(1,1,1));
                r12.w = 1.5 - r4.x;
                r4.x = r12.w >= 0 ? 0 : 1;
                r12.xyz = r4.xxx + r0.yzw;
                r7.z = dot(r12.xyzw, r12.xyzw);
                
                r0.yzw = float3(0.00340136047,0.0204081628,0.142857149) * r5.zzz;
                r4.xyz = float3(0.00340136047,0.0204081628,0.142857149) * r5.www;
                r4.xyz = floor(float3(7,7,7) * frac(r4.xyz));
                r4.xyz = r4.xyz / 7.0 - float3(1,1,1);
                r0.yzw = floor(float3(7,7,7) * frac(r0.yzw));
                r0.yzw = r0.yzw / 7.0 - float3(1,1,1);
                r5.x = dot(-r0.yzw, float3(1,1,1));
                r5.w = 1.5 - r5.x;
                r13.x = r5.w >= 0 ? 0 : 1;
                r5.xyz = r13.xxx + r0.yzw;
                r7.w = dot(r5.xyzw, r5.xyzw);
                
                r7.xyzw = float4(1.79284286,1.79284286,1.79284286,1.79284286) - r7.xyzw * float4(0.853734732,0.853734732,0.853734732,0.853734732);
                
                r10.xyzw = r10.xyzw * r7.yyyy;
                r10.y = dot(r10.xyzw, r11.xyzw);
                r11.y = dot(r11.xyzw, r11.xyzw);
                
                r12.xyzw = r12.xyzw * r7.zzzz;
                r10.z = dot(r12.xyzw, r9.xyzw);
                r11.z = dot(r9.xyzw, r9.xyzw);
                
                r6.xyzw = r7.xxxx * r6.xyzw;
                r5.xyzw = r7.wwww * r5.xyzw;
                r5.x = dot(r5.xyzw, r8.xyzw);
                r7.x = dot(r8.xyzw, r8.xyzw);
                r10.x = dot(r6.xyzw, r2.xyzw);
                r11.x = dot(r2.xyzw, r2.xyzw);
                
                r2.xyzw = r2.xyzw - float4(0.44721359,0.44721359,0.44721359,0.44721359); // 1/sqrt(5)
                r0.yzw = max(float3(0,0,0), float3(0.6, 0.6, 0.6) - r11.xyz);
                r0.yzw = pow(r0.yzw, 4);
                
                r0.y = dot(r0.yzw, r10.xyz);
                r0.z = dot(-r4.xyz, float3(1,1,1));
                r6.w = 1.5 - r0.z;
                r0.z = r6.w >= 0 ? 0 : 1;
                r6.xyz = r4.xyz + r0.zzz;
                r0.z = dot(r6.xyzw, r6.xyzw);
                
                r0.z = 1.79284286 - r0.z * 0.853734732;
                r6.xyzw = r6.xyzw * r0.zzzz;
                r5.y = dot(r6.xyzw, r2.xyzw);
                r7.y = dot(r2.xyzw, r2.xyzw);
                
                r0.zw = max(float2(0,0), float2(0.6, 0.6) - r7.xy);
                r0.zw = pow(r0.zw, 4);
                r0.y = r0.y + dot(r0.zw, r5.xy);
                r0.z = r0.y * 9.8 + r3.w;
                r0.y = 24.5 * r0.y;
                r0.x = r0.x * 49 + r0.y;
                r1.yw = r3.yw;
                r2.y = r1.y * 0.5 + r0.z;
                r2.xzw = float3(2,2,4) * r1.xzw;
                
                r0.y = dot(r2.xyzw, float4(0.309017003,0.309017003,0.309017003,0.309017003)); // 1/(1+sqrt(5))
                r5.xyzw = floor(r2.xyzw + r0.yyyy);
                
                r6.xyzw = r2.xyzw - r5.xyzw;
                r1.y = r2.y;
                r2.xyw = float3(4, 2, 8) * r1.xyw;
                
                r0.y = dot(r5.xyzw, float4(0.138196602,0.138196602,0.138196602,0.138196602)); // 1/(5+sqrt(5))
                r6.xyzw = r6.xyzw + r0.yyyy;
                r1.xyw = r6.xxx >= r6.yzw ? float3(1,1,1) : 0;
                r0.yzw = r6.xxx >= r6.yzw ? float3(0,0,0) : float3(1,1,1);
                
                r7.x = r1.x + r1.y + r1.w;
                r8.xyz = r6.yyz >= r6.zww ? float3(1,1,1) : 0;
                r1.xyw = r6.yyz >= r6.zww ? float3(-1,-1,-1) : float3(-0,-0,-0);
                
                r7.y = r8.x + r8.y + r0.y;
                r0.yz = r1.xy + r0.zw;
                r8.w = 1;
                r8.xz = r8.wz + r0.zy;
                r8.w = r8.x + r1.w;
                r7.w = 1 + r8.w;
                r8.xy = r7.xy;
                r7.z = 1 + r8.z;
                
                r7.xyzw = min(float4(1,1,1,1), r7.xyzw);
                r9.xyzw = saturate(r8.xyzw - float4(1,1,0,0));
                r8.xyzw = max(float4(0,0,0,0), r8.xyzw - float4(2,2,1,1));
                
                r10.xyzw = floor(r5.xyzw / 289.0);
                r5.xyzw = r5.xyzw - r10.xyzw * 289.0;
                r0.y = r5.w * r5.w;
                r0.y = r0.y * 34 + r5.w;
                r0.z = 0.00346020772 * r0.y;
                r0.z = floor(r0.z);
                r0.y = -r0.z * 289 + r0.y;
                r0.y = r0.y + r5.z;
                r0.z = r0.y * r0.y;
                r0.y = r0.z * 34 + r0.y;
                r0.z = 0.00346020772 * r0.y;
                r0.z = floor(r0.z);
                r0.y = -r0.z * 289 + r0.y;
                r0.y = r0.y + r5.y;
                r0.z = r0.y * r0.y;
                r0.y = r0.z * 34 + r0.y;
                r0.z = 0.00346020772 * r0.y;
                r0.z = floor(r0.z);
                r0.y = -r0.z * 289 + r0.y;
                r0.y = r0.y + r5.x;
                r0.z = r0.y * r0.y;
                r0.y = r0.z * 34 + r0.y;
                r10.x = r8.w;
                r10.y = r9.w;
                r10.z = r7.w;
                r10.w = 1;
                r10.xyzw = r10.xyzw + r5.wwww;
                r11.xyzw = r10.xyzw * r10.xyzw;
                r10.xyzw = r11.xyzw * float4(34,34,34,34) + r10.xyzw;
                r11.x = r8.z;
                r11.y = r9.z;
                r11.z = r7.z;
                r12.xyzw = float4(0.00346020772,0.00346020772,0.00346020772,0.00346020772) * r10.xyzw;
                r12.xyzw = floor(r12.xyzw);
                r10.xyzw = -r12.xyzw * float4(289,289,289,289) + r10.xyzw;
                r10.xyzw = r10.xyzw + r5.zzzz;
                r11.w = 1;
                r10.xyzw = r11.xyzw + r10.xyzw;
                r11.xyzw = r10.xyzw * r10.xyzw;
                r10.xyzw = r11.xyzw * float4(34,34,34,34) + r10.xyzw;
                r11.x = r8.y;
                r11.y = r9.y;
                r11.z = r7.y;
                r12.xyzw = float4(0.00346020772,0.00346020772,0.00346020772,0.00346020772) * r10.xyzw;
                r12.xyzw = floor(r12.xyzw);
                r10.xyzw = -r12.xyzw * float4(289,289,289,289) + r10.xyzw;
                r10.xyzw = r10.xyzw + r5.yyyy;
                r11.w = 1;
                r10.xyzw = r11.xyzw + r10.xyzw;
                r11.xyzw = r10.xyzw * r10.xyzw;
                r10.xyzw = r11.xyzw * float4(34,34,34,34) + r10.xyzw;
                r11.xyzw = -r8.xyzw + r6.xyzw;
                r11.xyzw = float4(0.138196602,0.138196602,0.138196602,0.138196602) + r11.xyzw;
                r8.y = r9.x;
                r9.xyzw = -r9.xyzw + r6.xyzw;
                r9.xyzw = float4(0.276393205,0.276393205,0.276393205,0.276393205) + r9.xyzw;
                r8.z = r7.x;
                r7.xyzw = -r7.xyzw + r6.xyzw;
                r7.xyzw = float4(0.414589792,0.414589792,0.414589792,0.414589792) + r7.xyzw;
                r12.xyzw = float4(0.00346020772,0.00346020772,0.00346020772,0.00346020772) * r10.xyzw;
                r12.xyzw = floor(r12.xyzw);
                r10.xyzw = -r12.xyzw * float4(289,289,289,289) + r10.xyzw;
                r5.xyzw = r10.xyzw + r5.xxxx;
                r8.w = 1;
                r5.xyzw = r8.xyzw + r5.xyzw;
                r8.xyzw = r5.xyzw * r5.xyzw;
                r5.xyzw = r8.xyzw * float4(34,34,34,34) + r5.xyzw;
                r4.x = dot(r6.xyzw, r6.xyzw);
                r4.y = dot(r11.xyzw, r11.xyzw);
                r4.z = dot(r9.xyzw, r9.xyzw);
                r1.xyw = float3(0.600000024,0.600000024,0.600000024) + -r4.xyz;
                r8.xyzw = float4(-0.44721359,-0.44721359,-0.44721359,-0.44721359) + r6.xyzw;
                r4.y = dot(r8.xyzw, r8.xyzw);
                r4.x = dot(r7.xyzw, r7.xyzw);
                r0.zw = float2(0.600000024,0.600000024) + -r4.xy;
                r1.xyw = max(float3(0,0,0), r1.xyw);
                r1.xyw = r1.xyw * r1.xyw;
                r1.xyw = r1.xyw * r1.xyw;
                r4.x = 0.00346020772 * r0.y;
                r4.x = floor(r4.x);
                r0.y = -r4.x * 289 + r0.y;
                r4.xyz = float3(0.00340136047,0.0204081628,0.142857149) * r0.yyy;
                r4.xyz = frac(r4.xyz);
                r4.xyz = float3(7,7,7) * r4.xyz;
                r4.xyz = floor(r4.xyz);
                r4.xyz = r4.xyz * float3(0.142857149,0.142857149,0.142857149) + float3(-1,-1,-1);
                r0.y = dot(-r4.xyz, float3(1,1,1));
                r10.w = 1.5 + -r0.y;
                r0.y = cmp(r10.w >= 0);
                r0.y = r0.y ? 0 : 1;
                r10.xyz = r4.xyz + r0.yyy;
                r12.x = dot(r10.xyzw, r10.xyzw);
                r13.xyzw = float4(0.00346020772,0.00346020772,0.00346020772,0.00346020772) * r5.xyzw;
                r13.xyzw = floor(r13.xyzw);
                r5.xyzw = -r13.xyzw * float4(289,289,289,289) + r5.xyzw;
                r4.xyz = float3(0.00340136047,0.0204081628,0.142857149) * r5.xxx;
                r4.xyz = frac(r4.xyz);
                r4.xyz = float3(7,7,7) * r4.xyz;
                r4.xyz = floor(r4.xyz);
                r4.xyz = r4.xyz * float3(0.142857149,0.142857149,0.142857149) + float3(-1,-1,-1);
                r0.y = dot(-r4.xyz, float3(1,1,1));
                r13.w = 1.5 + -r0.y;
                r0.y = cmp(r13.w >= 0);
                r0.y = r0.y ? 0 : 1;
                r13.xyz = r4.xyz + r0.yyy;
                r12.y = dot(r13.xyzw, r13.xyzw);
                r4.xyz = float3(0.00340136047,0.0204081628,0.142857149) * r5.yyy;
                r4.xyz = frac(r4.xyz);
                r4.xyz = float3(7,7,7) * r4.xyz;
                r4.xyz = floor(r4.xyz);
                r4.xyz = r4.xyz * float3(0.142857149,0.142857149,0.142857149) + float3(-1,-1,-1);
                r0.y = dot(-r4.xyz, float3(1,1,1));
                r14.w = 1.5 + -r0.y;
                r0.y = cmp(r14.w >= 0);
                r0.y = r0.y ? 0 : 1;
                r14.xyz = r4.xyz + r0.yyy;
                r12.z = dot(r14.xyzw, r14.xyzw);
                r4.xyz = float3(0.00340136047,0.0204081628,0.142857149) * r5.zzz;
                r5.xyz = float3(0.00340136047,0.0204081628,0.142857149) * r5.www;
                r5.xyz = frac(r5.xyz);
                r5.xyz = float3(7,7,7) * r5.xyz;
                r5.xyz = floor(r5.xyz);
                r5.xyz = r5.xyz * float3(0.142857149,0.142857149,0.142857149) + float3(-1,-1,-1);
                r4.xyz = frac(r4.xyz);
                r4.xyz = float3(7,7,7) * r4.xyz;
                r4.xyz = floor(r4.xyz);
                r4.xyz = r4.xyz * float3(0.142857149,0.142857149,0.142857149) + float3(-1,-1,-1);
                r0.y = dot(-r4.xyz, float3(1,1,1));
                r15.w = 1.5 + -r0.y;
                r0.y = cmp(r15.w >= 0);
                r0.y = r0.y ? 0 : 1;
                r15.xyz = r4.xyz + r0.yyy;
                r12.w = dot(r15.xyzw, r15.xyzw);
                r12.xyzw = -r12.xyzw * float4(0.853734732,0.853734732,0.853734732,0.853734732) + float4(1.79284286,1.79284286,1.79284286,1.79284286);
                r10.xyzw = r12.xxxx * r10.xyzw;
                r4.x = dot(r10.xyzw, r6.xyzw);
                r6.xyzw = r13.xyzw * r12.yyyy;
                r4.y = dot(r6.xyzw, r11.xyzw);
                r6.xyzw = r14.xyzw * r12.zzzz;
                r10.xyzw = r15.xyzw * r12.wwww;
                r7.x = dot(r10.xyzw, r7.xyzw);
                r4.z = dot(r6.xyzw, r9.xyzw);
                r0.y = dot(r1.xyw, r4.xyz);
                r1.x = dot(-r5.xyz, float3(1,1,1));
                r6.w = 1.5 + -r1.x;
                r1.x = cmp(r6.w >= 0);
                r1.x = r1.x ? 0 : 1;
                r6.xyz = r5.xyz + r1.xxx;
                r1.x = dot(r6.xyzw, r6.xyzw);
                r1.x = -r1.x * 0.853734732 + 1.79284286;
                r5.xyzw = r6.xyzw * r1.xxxx;
                r7.y = dot(r5.xyzw, r8.xyzw);
                r0.zw = max(float2(0,0), r0.zw);
                r0.zw = r0.zw * r0.zw;
                r0.zw = r0.zw * r0.zw;
                r0.z = dot(r0.zw, r7.xy);
                r0.y = r0.y + r0.z;
                r0.z = r0.y * 12.25 + -r4.w;
                r0.x = r0.y * 12.25 + r0.x;
                r2.z = r1.z * 4 + r0.z;
                r0.y = dot(r2.xyzw, float4(0.309017003,0.309017003,0.309017003,0.309017003));
                r1.xyzw = r2.xyzw + r0.yyyy;
                r1.xyzw = floor(r1.xyzw);
                r2.xyzw = r2.xyzw + -r1.xyzw;
                r0.y = dot(r1.xyzw, float4(0.138196602,0.138196602,0.138196602,0.138196602));
                r2.xyzw = r2.xyzw + r0.yyyy;
                r0.yzw = cmp(r2.xxx >= r2.yzw);
                r5.xyz = cmp(r2.yyz >= r2.zww);
                r6.xyz = r0.yzw ? float3(1,1,1) : 0;
                r0.yzw = r0.yzw ? float3(0,0,0) : float3(1,1,1);
                r5.w = r6.x + r6.y;
                r6.x = r5.w + r6.z;
                r7.xyz = r5.xyz ? float3(1,1,1) : 0;
                r5.xyz = r5.xyz ? float3(-1,-1,-1) : float3(-0,-0,-0);
                r5.w = r7.x + r7.y;
                r6.y = r5.w + r0.y;
                r0.yz = r5.xy + r0.zw;
                r8.xy = r6.xy;
                r7.w = 1;
                r0.yz = r7.zw + r0.yz;
                r8.w = r0.z + r5.z;
                r8.z = r0.y;
                r6.z = 1 + r0.y;
                r5.xyzw = float4(-2,-2,-1,-1) + r8.xyzw;
                r7.xyzw = saturate(float4(-1,-1,0,0) + r8.xyzw);
                r6.w = 1 + r8.w;
                r6.xyzw = min(float4(1,1,1,1), r6.yzxw);
                r5.xyzw = max(float4(0,0,0,0), r5.wxyz);
                r8.xyzw = -r5.yzwx + r2.xyzw;
                r9.xyzw = -r7.xyzw + r2.xyzw;
                r10.xyzw = -r6.zxyw + r2.xyzw;
                r11.xyzw = float4(-0.44721359,-0.44721359,-0.44721359,-0.44721359) + r2.xyzw;
                r12.xyzw = float4(0.00346020772,0.00346020772,0.00346020772,0.00346020772) * r1.xyzw;
                r12.xyzw = floor(r12.xyzw);
                r1.xyzw = -r12.xyzw * float4(289,289,289,289) + r1.xyzw;
                r12.x = dot(r2.xyzw, r2.xyzw);
                r13.x = r5.z;
                r13.y = r7.y;
                r13.z = r6.x;
                r14.x = r5.w;
                r14.y = r7.z;
                r14.z = r6.y;
                r6.x = r5.y;
                r5.y = r7.w;
                r6.y = r7.x;
                r5.z = r6.w;
                r5.w = 1;
                r5.xyzw = r5.xyzw + r1.wwww;
                r7.xyzw = r5.xyzw * r5.xyzw;
                r5.xyzw = r7.xyzw * float4(34,34,34,34) + r5.xyzw;
                r7.xyzw = float4(0.00346020772,0.00346020772,0.00346020772,0.00346020772) * r5.xyzw;
                r7.xyzw = floor(r7.xyzw);
                r5.xyzw = -r7.xyzw * float4(289,289,289,289) + r5.xyzw;
                r5.xyzw = r5.xyzw + r1.zzzz;
                r14.w = 1;
                r5.xyzw = r14.xyzw + r5.xyzw;
                r7.xyzw = r5.xyzw * r5.xyzw;
                r5.xyzw = r7.xyzw * float4(34,34,34,34) + r5.xyzw;
                r7.xyzw = float4(0.00346020772,0.00346020772,0.00346020772,0.00346020772) * r5.xyzw;
                r7.xyzw = floor(r7.xyzw);
                r5.xyzw = -r7.xyzw * float4(289,289,289,289) + r5.xyzw;
                r5.xyzw = r5.xyzw + r1.yyyy;
                r13.w = 1;
                r5.xyzw = r13.xyzw + r5.xyzw;
                r7.xyzw = r5.xyzw * r5.xyzw;
                r5.xyzw = r7.xyzw * float4(34,34,34,34) + r5.xyzw;
                r7.xyzw = float4(0.00346020772,0.00346020772,0.00346020772,0.00346020772) * r5.xyzw;
                r7.xyzw = floor(r7.xyzw);
                r5.xyzw = -r7.xyzw * float4(289,289,289,289) + r5.xyzw;
                r5.xyzw = r5.xyzw + r1.xxxx;
                r6.w = 1;
                r5.xyzw = r6.xyzw + r5.xyzw;
                r6.xyzw = r5.xyzw * r5.xyzw;
                r5.xyzw = r6.xyzw * float4(34,34,34,34) + r5.xyzw;
                r6.xyzw = float4(0.00346020772,0.00346020772,0.00346020772,0.00346020772) * r5.xyzw;
                r6.xyzw = floor(r6.xyzw);
                r5.xyzw = -r6.xyzw * float4(289,289,289,289) + r5.xyzw;
                r0.yzw = float3(0.00340136047,0.0204081628,0.142857149) * r5.xxx;
                r0.yzw = frac(r0.yzw);
                r0.yzw = float3(7,7,7) * r0.yzw;
                r0.yzw = floor(r0.yzw);
                r0.yzw = r0.yzw * float3(0.142857149,0.142857149,0.142857149) + float3(-1,-1,-1);
                r5.x = dot(-r0.yzw, float3(1,1,1));
                r6.w = 1.5 + -r5.x;
                r5.x = cmp(r6.w >= 0);
                r5.x = r5.x ? 0 : 1;
                r6.xyz = r5.xxx + r0.yzw;
                r7.y = dot(r6.xyzw, r6.xyzw);
                r0.yzw = float3(0.00340136047,0.0204081628,0.142857149) * r5.yyy;
                r0.yzw = frac(r0.yzw);
                r0.yzw = float3(7,7,7) * r0.yzw;
                r0.yzw = floor(r0.yzw);
                r0.yzw = r0.yzw * float3(0.142857149,0.142857149,0.142857149) + float3(-1,-1,-1);
                r5.x = dot(-r0.yzw, float3(1,1,1));
                r13.w = 1.5 + -r5.x;
                r5.x = cmp(r13.w >= 0);
                r5.x = r5.x ? 0 : 1;
                r13.xyz = r5.xxx + r0.yzw;
                r7.z = dot(r13.xyzw, r13.xyzw);
                r0.yzw = float3(0.00340136047,0.0204081628,0.142857149) * r5.zzz;
                r5.xyz = float3(0.00340136047,0.0204081628,0.142857149) * r5.www;
                r5.xyz = frac(r5.xyz);
                r5.xyz = float3(7,7,7) * r5.xyz;
                r5.xyz = floor(r5.xyz);
                r5.xyz = r5.xyz * float3(0.142857149,0.142857149,0.142857149) + float3(-1,-1,-1);
                r0.yzw = frac(r0.yzw);
                r0.yzw = float3(7,7,7) * r0.yzw;
                r0.yzw = floor(r0.yzw);
                r0.yzw = r0.yzw * float3(0.142857149,0.142857149,0.142857149) + float3(-1,-1,-1);
                r5.w = dot(-r0.yzw, float3(1,1,1));
                r14.w = 1.5 + -r5.w;
                r5.w = cmp(r14.w >= 0);
                r5.w = r5.w ? 0 : 1;
                r14.xyz = r5.www + r0.yzw;
                r7.w = dot(r14.xyzw, r14.xyzw);
                r0.y = r1.w * r1.w;
                r0.y = r0.y * 34 + r1.w;
                r0.z = 0.00346020772 * r0.y;
                r0.z = floor(r0.z);
                r0.y = -r0.z * 289 + r0.y;
                r0.y = r0.y + r1.z;
                r0.z = r0.y * r0.y;
                r0.y = r0.z * 34 + r0.y;
                r0.z = 0.00346020772 * r0.y;
                r0.z = floor(r0.z);
                r0.y = -r0.z * 289 + r0.y;
                r0.y = r0.y + r1.y;
                r0.z = r0.y * r0.y;
                r0.y = r0.z * 34 + r0.y;
                r0.z = 0.00346020772 * r0.y;
                r0.z = floor(r0.z);
                r0.y = -r0.z * 289 + r0.y;
                r0.y = r0.y + r1.x;
                r0.z = r0.y * r0.y;
                r0.y = r0.z * 34 + r0.y;
                r0.z = 0.00346020772 * r0.y;
                r0.z = floor(r0.z);
                r0.y = -r0.z * 289 + r0.y;
                r0.yzw = float3(0.00340136047,0.0204081628,0.142857149) * r0.yyy;
                r0.yzw = frac(r0.yzw);
                r0.yzw = float3(7,7,7) * r0.yzw;
                r0.yzw = floor(r0.yzw);
                r0.yzw = r0.yzw * float3(0.142857149,0.142857149,0.142857149) + float3(-1,-1,-1);
                r1.x = dot(-r0.yzw, float3(1,1,1));
                r1.w = 1.5 + -r1.x;
                r5.w = cmp(r1.w >= 0);
                r5.w = r5.w ? 0 : 1;
                r1.xyz = r5.www + r0.yzw;
                r7.x = dot(r1.xyzw, r1.xyzw);
                r7.xyzw = -r7.xyzw * float4(0.853734732,0.853734732,0.853734732,0.853734732) + float4(1.79284286,1.79284286,1.79284286,1.79284286);
                r1.xyzw = r7.xxxx * r1.xyzw;
                r1.x = dot(r1.xyzw, r2.xyzw);
                r2.w = 1;
                r15.w = 1;
                r16.w = 1;
                
                r17.xyzw = _ChaosTile * r3.xyzw;
                r4.xyzw = float4(0.09, 0.01125, 0.09, 0.36) * r3.xyzw;
                r3.xyzw = float4(0.25, 0.03125, 0.25, 0.25) * r17.xyzw;
                r0.y = dot(r3.xyzw, float4(0.309017003,0.309017003,0.309017003,0.309017003)); // 1/(1+sqrt(5))
                r18.xyzw = floor(r17.xyzw * float4(0.25,0.03125,0.25,0.25) + r0.yyyy);
                r19.xyzw = r17.xyzw * float4(0.25,0.03125,0.25,0.25) - r18.xyzw;
                r0.y = dot(r18.xyzw, float4(0.138196602,0.138196602,0.138196602,0.138196602)); // 1/(5+sqrt(5))
                r19.xyzw = r19.xyzw + r0.yyyy;
                r3.xzw = r19.xxx >= r19.yzw ? float3(0,0,0) : float3(1,1,1);
                r0.yzw = r19.xxx >= r19.yzw ? float3(1,1,1) : 0;
                r21.xyz = r19.yyz >= r19.zww ? float3(-1,-1,-1) : float3(-0,-0,-0);
                r16.xyz = r19.yyz >= r19.zww ? float3(1,1,1) : 0;
                
                r3.zw = r21.xy + r3.zw;
                r20.xz = r16.wz + r3.wz;
                r1.w = r16.x + r16.y;
                r16.y = r3.x + r1.w;
                r16.z = 1 + r20.z;
                r0.y = r0.y + r0.z;
                r16.x = r0.y + r0.w;
                r20.w = r20.x + r21.z;
                r16.w = 1 + r20.w;
                
                r21.xyzw = min(float4(1,1,1,1), r16.xyzw);
                r20.xy = r16.xy;
                r15.z = r21.w;
                r16.xyzw = r20.xyzw - float4(2,2,1,1);
                r20.xyzw = saturate(r20.xyzw - float4(1,1,0,0));
                r16.xyzw = max(float4(0,0,0,0), r16.xyzw);
                r15.x = r16.w;
                r15.y = r20.w;
                
                r22.xyzw = float4(0.00346020772,0.00346020772,0.00346020772,0.00346020772) * r18.xyzw;
                r22.xyzw = floor(r22.xyzw);
                r18.xyzw = -r22.xyzw * float4(289,289,289,289) + r18.xyzw;
                r15.xyzw = r18.wwww + r15.xyzw;
                r22.xyzw = r15.xyzw * r15.xyzw;
                r15.xyzw = r22.xyzw * float4(34,34,34,34) + r15.xyzw;
                r22.xyzw = float4(0.00346020772,0.00346020772,0.00346020772,0.00346020772) * r15.xyzw;
                r22.xyzw = floor(r22.xyzw);
                r15.xyzw = -r22.xyzw * float4(289,289,289,289) + r15.xyzw;
                r15.xyzw = r15.xyzw + r18.zzzz;
                r2.z = r21.z;
                r2.x = r16.z;
                r2.y = r20.z;
                r2.xyzw = r15.xyzw + r2.xyzw;
                r15.xyzw = r2.xyzw * r2.xyzw;
                r2.xyzw = r15.xyzw * float4(34,34,34,34) + r2.xyzw;
                r15.xyzw = float4(0.00346020772,0.00346020772,0.00346020772,0.00346020772) * r2.xyzw;
                r15.xyzw = floor(r15.xyzw);
                r2.xyzw = -r15.xyzw * float4(289,289,289,289) + r2.xyzw;
                r2.xyzw = r2.xyzw + r18.yyyy;
                r15.w = 1;
                r15.z = r21.y;
                r15.x = r16.y;
                r15.y = r20.y;
                r2.xyzw = r15.xyzw + r2.xyzw;
                r15.xyzw = r2.xyzw * r2.xyzw;
                r2.xyzw = r15.xyzw * float4(34,34,34,34) + r2.xyzw;
                r15.xyzw = float4(0.00346020772,0.00346020772,0.00346020772,0.00346020772) * r2.xyzw;
                r15.xyzw = floor(r15.xyzw);
                r2.xyzw = -r15.xyzw * float4(289,289,289,289) + r2.xyzw;
                r2.xyzw = r2.xyzw + r18.xxxx;
                r15.w = 1;
                r15.z = r21.x;
                r21.xyzw = -r21.xyzw + r19.xyzw;
                r21.xyzw = float4(0.414589792,0.414589792,0.414589792,0.414589792) + r21.xyzw;
                r15.x = r16.x;
                r16.xyzw = r19.xyzw + -r16.xyzw;
                r16.xyzw = float4(0.138196602,0.138196602,0.138196602,0.138196602) + r16.xyzw;
                r15.y = r20.x;
                r20.xyzw = -r20.xyzw + r19.xyzw;
                r20.xyzw = float4(0.276393205,0.276393205,0.276393205,0.276393205) + r20.xyzw;
                r2.xyzw = r15.xyzw + r2.xyzw;
                r15.xyzw = r2.xyzw * r2.xyzw;
                r2.xyzw = r15.xyzw * float4(34,34,34,34) + r2.xyzw;
                r15.xyzw = float4(0.00346020772,0.00346020772,0.00346020772,0.00346020772) * r2.xyzw;
                r15.xyzw = floor(r15.xyzw);
                r2.xyzw = -r15.xyzw * float4(289,289,289,289) + r2.xyzw;
                r0.yzw = float3(0.00340136047,0.0204081628,0.142857149) * r2.xxx;
                r0.yzw = frac(r0.yzw);
                r0.yzw = float3(7,7,7) * r0.yzw;
                r0.yzw = floor(r0.yzw);
                r0.yzw = r0.yzw * float3(0.142857149,0.142857149,0.142857149) + float3(-1,-1,-1);
                r1.w = dot(-r0.yzw, float3(1,1,1));
                r15.w = 1.5 + -r1.w;
                r1.w = cmp(r15.w >= 0);
                r1.w = r1.w ? 0 : 1;
                r15.xyz = r1.www + r0.yzw;
                r22.y = dot(r15.xyzw, r15.xyzw);
                r0.yzw = float3(0.00340136047,0.0204081628,0.142857149) * r2.yyy;
                r0.yzw = frac(r0.yzw);
                r0.yzw = float3(7,7,7) * r0.yzw;
                r0.yzw = floor(r0.yzw);
                r0.yzw = r0.yzw * float3(0.142857149,0.142857149,0.142857149) + float3(-1,-1,-1);
                r1.w = dot(-r0.yzw, float3(1,1,1));
                r23.w = 1.5 + -r1.w;
                r1.w = cmp(r23.w >= 0);
                r1.w = r1.w ? 0 : 1;
                r23.xyz = r1.www + r0.yzw;
                r22.z = dot(r23.xyzw, r23.xyzw);
                r0.yzw = float3(0.00340136047,0.0204081628,0.142857149) * r2.zzz;
                r2.xyz = float3(0.00340136047,0.0204081628,0.142857149) * r2.www;
                r2.xyz = frac(r2.xyz);
                r2.xyz = float3(7,7,7) * r2.xyz;
                r2.xyz = floor(r2.xyz);
                r2.xyz = r2.xyz * float3(0.142857149,0.142857149,0.142857149) + float3(-1,-1,-1);
                r0.yzw = frac(r0.yzw);
                r0.yzw = float3(7,7,7) * r0.yzw;
                r0.yzw = floor(r0.yzw);
                r0.yzw = r0.yzw * float3(0.142857149,0.142857149,0.142857149) + float3(-1,-1,-1);
                r1.w = dot(-r0.yzw, float3(1,1,1));
                r24.w = 1.5 + -r1.w;
                r1.w = cmp(r24.w >= 0);
                r1.w = r1.w ? 0 : 1;
                r24.xyz = r1.www + r0.yzw;
                r22.w = dot(r24.xyzw, r24.xyzw);
                r0.y = r18.w * r18.w;
                r0.y = r0.y * 34 + r18.w;
                r0.z = 0.00346020772 * r0.y;
                r0.z = floor(r0.z);
                r0.y = -r0.z * 289 + r0.y;
                r0.y = r0.y + r18.z;
                r0.z = r0.y * r0.y;
                r0.y = r0.z * 34 + r0.y;
                r0.z = 0.00346020772 * r0.y;
                r0.z = floor(r0.z);
                r0.y = -r0.z * 289 + r0.y;
                r0.y = r0.y + r18.y;
                r0.z = r0.y * r0.y;
                r0.y = r0.z * 34 + r0.y;
                r0.z = 0.00346020772 * r0.y;
                r0.z = floor(r0.z);
                r0.y = -r0.z * 289 + r0.y;
                r0.y = r0.y + r18.x;
                r0.z = r0.y * r0.y;
                r0.y = r0.z * 34 + r0.y;
                r0.z = 0.00346020772 * r0.y;
                r0.z = floor(r0.z);
                r0.y = -r0.z * 289 + r0.y;
                r0.yzw = float3(0.00340136047,0.0204081628,0.142857149) * r0.yyy;
                r0.yzw = frac(r0.yzw);
                r0.yzw = float3(7,7,7) * r0.yzw;
                r0.yzw = floor(r0.yzw);
                r0.yzw = r0.yzw * float3(0.142857149,0.142857149,0.142857149) + float3(-1,-1,-1);
                r1.w = dot(-r0.yzw, float3(1,1,1));
                r18.w = 1.5 + -r1.w;
                r1.w = cmp(r18.w >= 0);
                r1.w = r1.w ? 0 : 1;
                r18.xyz = r1.www + r0.yzw;
                r22.x = dot(r18.xyzw, r18.xyzw);
                r22.xyzw = -r22.xyzw * float4(0.853734732,0.853734732,0.853734732,0.853734732) + float4(1.79284286,1.79284286,1.79284286,1.79284286);
                r15.xyzw = r22.yyyy * r15.xyzw;
                r15.y = dot(r15.xyzw, r16.xyzw);
                r16.y = dot(r16.xyzw, r16.xyzw);
                r23.xyzw = r23.xyzw * r22.zzzz;
                r15.z = dot(r23.xyzw, r20.xyzw);
                r16.z = dot(r20.xyzw, r20.xyzw);
                r18.xyzw = r22.xxxx * r18.xyzw;
                r20.xyzw = r24.xyzw * r22.wwww;
                r20.x = dot(r20.xyzw, r21.xyzw);
                r21.x = dot(r21.xyzw, r21.xyzw);
                r15.x = dot(r18.xyzw, r19.xyzw);
                r16.x = dot(r19.xyzw, r19.xyzw);
                r18.xyzw = float4(-0.44721359,-0.44721359,-0.44721359,-0.44721359) + r19.xyzw;
                r0.yzw = float3(0.600000024,0.600000024,0.600000024) + -r16.xyz;
                r0.yzw = max(float3(0,0,0), r0.yzw);
                r0.yzw = r0.yzw * r0.yzw;
                r0.yzw = r0.yzw * r0.yzw;
                r0.y = dot(r0.yzw, r15.xyz);
                r0.z = dot(-r2.xyz, float3(1,1,1));
                r15.w = 1.5 + -r0.z;
                r0.z = cmp(r15.w >= 0);
                r0.z = r0.z ? 0 : 1;
                r15.xyz = r2.xyz + r0.zzz;
                r0.z = dot(r15.xyzw, r15.xyzw);
                r0.z = -r0.z * 0.853734732 + 1.79284286;
                r2.xyzw = r15.xyzw * r0.zzzz;
                r20.y = dot(r2.xyzw, r18.xyzw);
                r21.y = dot(r18.xyzw, r18.xyzw);
                r0.zw = float2(0.600000024,0.600000024) + -r21.xy;
                r0.zw = max(float2(0,0), r0.zw);
                r0.zw = r0.zw * r0.zw;
                r0.zw = r0.zw * r0.zw;
                r0.z = dot(r0.zw, r20.xy);
                r0.y = r0.y + r0.z;
                r0.y = 49 * r0.y;
                r0.z = abs(r0.y) + abs(r0.y);
                r17.y = r0.z * _ChaosDistort + r3.y;
                r2.xyzw = float4(0.5,2,0.5,0.5) * r17.xyzw;
                r0.z = dot(r2.xyzw, float4(0.309017003,0.309017003,0.309017003,0.309017003));
                r2.xyzw = r17.xyzw * float4(0.5,2,0.5,0.5) + r0.zzzz;
                r2.xyzw = floor(r2.xyzw);
                r3.xyzw = float4(0.00346020772,0.00346020772,0.00346020772,0.00346020772) * r2.xyzw;
                r3.xyzw = floor(r3.xyzw);
                r3.xyzw = -r3.xyzw * float4(289,289,289,289) + r2.xyzw;
                r0.z = r3.w * r3.w;
                r0.z = r0.z * 34 + r3.w;
                r0.w = 0.00346020772 * r0.z;
                r0.w = floor(r0.w);
                r0.z = -r0.w * 289 + r0.z;
                r0.z = r0.z + r3.z;
                r0.w = r0.z * r0.z;
                r0.z = r0.w * 34 + r0.z;
                r0.w = 0.00346020772 * r0.z;
                r0.w = floor(r0.w);
                r0.z = -r0.w * 289 + r0.z;
                r0.z = r0.z + r3.y;
                r0.w = r0.z * r0.z;
                r0.z = r0.w * 34 + r0.z;
                r0.w = 0.00346020772 * r0.z;
                r0.w = floor(r0.w);
                r0.z = -r0.w * 289 + r0.z;
                r0.z = r0.z + r3.x;
                r0.w = r0.z * r0.z;
                r0.z = r0.w * 34 + r0.z;
                r0.w = 0.00346020772 * r0.z;
                r0.w = floor(r0.w);
                r0.z = -r0.w * 289 + r0.z;
                r15.xyz = float3(0.00340136047,0.0204081628,0.142857149) * r0.zzz;
                r15.xyz = frac(r15.xyz);
                r15.xyz = float3(7,7,7) * r15.xyz;
                r15.xyz = floor(r15.xyz);
                r15.xyz = r15.xyz * float3(0.142857149,0.142857149,0.142857149) + float3(-1,-1,-1);
                r0.z = dot(-r15.xyz, float3(1,1,1));
                r16.w = 1.5 + -r0.z;
                r0.z = cmp(r16.w >= 0);
                r0.z = r0.z ? 0 : 1;
                r16.xyz = r15.xyz + r0.zzz;
                r15.x = dot(r16.xyzw, r16.xyzw);
                r18.xyzw = r17.xyzw * float4(0.5,2,0.5,0.5) + -r2.xyzw;
                r0.z = dot(r2.xyzw, float4(0.138196602,0.138196602,0.138196602,0.138196602));
                r2.xyzw = r18.xyzw + r0.zzzz;
                r18.xyz = cmp(r2.xxx >= r2.yzw);
                r19.xyz = r18.xyz ? float3(1,1,1) : 0;
                r18.xyz = r18.xyz ? float3(0,0,0) : float3(1,1,1);
                r0.z = r19.x + r19.y;
                r19.x = r0.z + r19.z;
                r20.xyz = cmp(r2.yyz >= r2.zww);
                r21.xyz = r20.xyz ? float3(1,1,1) : 0;
                r20.xyz = r20.xyz ? float3(-1,-1,-1) : float3(-0,-0,-0);
                r0.z = r21.x + r21.y;
                r19.y = r18.x + r0.z;
                r0.zw = r20.xy + r18.yz;
                r21.w = 1;
                r18.xz = r21.wz + r0.wz;
                r19.z = 1 + r18.z;
                r18.w = r18.x + r20.z;
                r19.w = 1 + r18.w;
                r20.xyzw = min(float4(1,1,1,1), r19.yzxw);
                r18.xy = r19.xy;
                r19.z = r20.y;
                r21.xyzw = float4(-2,-2,-1,-1) + r18.xyzw;
                r18.xyzw = saturate(float4(-1,-1,0,0) + r18.xyzw);
                r21.xyzw = max(float4(0,0,0,0), r21.xyzw);
                r22.x = r21.w;
                r22.y = r18.w;
                r22.z = r20.w;
                r22.w = 1;
                r22.xyzw = r22.xyzw + r3.wwww;
                r23.xyzw = r22.xyzw * r22.xyzw;
                r22.xyzw = r23.xyzw * float4(34,34,34,34) + r22.xyzw;
                r23.xyzw = float4(0.00346020772,0.00346020772,0.00346020772,0.00346020772) * r22.xyzw;
                r23.xyzw = floor(r23.xyzw);
                r22.xyzw = -r23.xyzw * float4(289,289,289,289) + r22.xyzw;
                r22.xyzw = r22.xyzw + r3.zzzz;
                r19.x = r21.z;
                r19.y = r18.z;
                r19.w = 1;
                r19.xyzw = r22.xyzw + r19.xyzw;
                r22.xyzw = r19.xyzw * r19.xyzw;
                r19.xyzw = r22.xyzw * float4(34,34,34,34) + r19.xyzw;
                r22.xyzw = float4(0.00346020772,0.00346020772,0.00346020772,0.00346020772) * r19.xyzw;
                r22.xyzw = floor(r22.xyzw);
                r19.xyzw = -r22.xyzw * float4(289,289,289,289) + r19.xyzw;
                r19.xyzw = r19.xyzw + r3.yyyy;
                r22.z = r20.x;
                r22.x = r21.y;
                r22.y = r18.y;
                r22.w = 1;
                r19.xyzw = r22.xyzw + r19.xyzw;
                r22.xyzw = r19.xyzw * r19.xyzw;
                r19.xyzw = r22.xyzw * float4(34,34,34,34) + r19.xyzw;
                r22.xyzw = float4(0.00346020772,0.00346020772,0.00346020772,0.00346020772) * r19.xyzw;
                r22.xyzw = floor(r22.xyzw);
                r19.xyzw = -r22.xyzw * float4(289,289,289,289) + r19.xyzw;
                r3.xyzw = r19.xyzw + r3.xxxx;
                r19.xyzw = -r20.zxyw + r2.xyzw;
                r19.xyzw = float4(0.414589792,0.414589792,0.414589792,0.414589792) + r19.xyzw;
                r20.x = r21.x;
                r21.xyzw = -r21.xyzw + r2.xyzw;
                r21.xyzw = float4(0.138196602,0.138196602,0.138196602,0.138196602) + r21.xyzw;
                r20.y = r18.x;
                r18.xyzw = -r18.xyzw + r2.xyzw;
                r18.xyzw = float4(0.276393205,0.276393205,0.276393205,0.276393205) + r18.xyzw;
                r20.w = 1;
                r3.xyzw = r20.xyzw + r3.xyzw;
                r20.xyzw = r3.xyzw * r3.xyzw;
                r3.xyzw = r20.xyzw * float4(34,34,34,34) + r3.xyzw;
                r20.xyzw = float4(0.00346020772,0.00346020772,0.00346020772,0.00346020772) * r3.xyzw;
                r20.xyzw = floor(r20.xyzw);
                r3.xyzw = -r20.xyzw * float4(289,289,289,289) + r3.xyzw;
                r20.xyz = float3(0.00340136047,0.0204081628,0.142857149) * r3.xxx;
                r20.xyz = frac(r20.xyz);
                r20.xyz = float3(7,7,7) * r20.xyz;
                r20.xyz = floor(r20.xyz);
                r20.xyz = r20.xyz * float3(0.142857149,0.142857149,0.142857149) + float3(-1,-1,-1);
                r0.z = dot(-r20.xyz, float3(1,1,1));
                r22.w = 1.5 + -r0.z;
                r0.z = cmp(r22.w >= 0);
                r0.z = r0.z ? 0 : 1;
                r22.xyz = r20.xyz + r0.zzz;
                r15.y = dot(r22.xyzw, r22.xyzw);
                r20.xyz = float3(0.00340136047,0.0204081628,0.142857149) * r3.yyy;
                r20.xyz = frac(r20.xyz);
                r20.xyz = float3(7,7,7) * r20.xyz;
                r20.xyz = floor(r20.xyz);
                r20.xyz = r20.xyz * float3(0.142857149,0.142857149,0.142857149) + float3(-1,-1,-1);
                r0.z = dot(-r20.xyz, float3(1,1,1));
                r23.w = 1.5 + -r0.z;
                r0.z = cmp(r23.w >= 0);
                r0.z = r0.z ? 0 : 1;
                r23.xyz = r20.xyz + r0.zzz;
                r15.z = dot(r23.xyzw, r23.xyzw);
                r3.xyz = float3(0.00340136047,0.0204081628,0.142857149) * r3.zzz;
                r20.xyz = float3(0.00340136047,0.0204081628,0.142857149) * r3.www;
                r20.xyz = frac(r20.xyz);
                r20.xyz = float3(7,7,7) * r20.xyz;
                r20.xyz = floor(r20.xyz);
                r20.xyz = r20.xyz * float3(0.142857149,0.142857149,0.142857149) + float3(-1,-1,-1);
                r3.xyz = frac(r3.xyz);
                r3.xyz = float3(7,7,7) * r3.xyz;
                r3.xyz = floor(r3.xyz);
                r3.xyz = r3.xyz * float3(0.142857149,0.142857149,0.142857149) + float3(-1,-1,-1);
                r0.z = dot(-r3.xyz, float3(1,1,1));
                r24.w = 1.5 + -r0.z;
                r0.z = cmp(r24.w >= 0);
                r0.z = r0.z ? 0 : 1;
                r24.xyz = r3.xyz + r0.zzz;
                r15.w = dot(r24.xyzw, r24.xyzw);
                r3.xyzw = -r15.xyzw * float4(0.853734732,0.853734732,0.853734732,0.853734732) + float4(1.79284286,1.79284286,1.79284286,1.79284286);
                r15.xyzw = r22.xyzw * r3.yyyy;
                r15.y = dot(r15.xyzw, r21.xyzw);
                r21.y = dot(r21.xyzw, r21.xyzw);
                r22.xyzw = r23.xyzw * r3.zzzz;
                r15.z = dot(r22.xyzw, r18.xyzw);
                r21.z = dot(r18.xyzw, r18.xyzw);
                r16.xyzw = r16.xyzw * r3.xxxx;
                r3.xyzw = r24.xyzw * r3.wwww;
                r3.x = dot(r3.xyzw, r19.xyzw);
                r18.x = dot(r19.xyzw, r19.xyzw);
                r15.x = dot(r16.xyzw, r2.xyzw);
                r21.x = dot(r2.xyzw, r2.xyzw);
                r2.xyzw = float4(-0.44721359,-0.44721359,-0.44721359,-0.44721359) + r2.xyzw;
                r16.xyz = float3(0.600000024,0.600000024,0.600000024) + -r21.xyz;
                r16.xyz = max(float3(0,0,0), r16.xyz);
                r16.xyz = r16.xyz * r16.xyz;
                r16.xyz = r16.xyz * r16.xyz;
                r0.z = dot(r16.xyz, r15.xyz);
                r0.w = dot(-r20.xyz, float3(1,1,1));
                r15.w = 1.5 + -r0.w;
                r0.w = cmp(r15.w >= 0);
                r0.w = r0.w ? 0 : 1;
                r15.xyz = r20.xyz + r0.www;
                r0.w = dot(r15.xyzw, r15.xyzw);
                r0.w = -r0.w * 0.853734732 + 1.79284286;
                r15.xyzw = r15.xyzw * r0.wwww;
                r3.y = dot(r15.xyzw, r2.xyzw);
                r18.y = dot(r2.xyzw, r2.xyzw);
                r2.xy = float2(0.600000024,0.600000024) + -r18.xy;
                r2.xy = max(float2(0,0), r2.xy);
                r2.xy = r2.xy * r2.xy;
                r2.xy = r2.xy * r2.xy;
                r0.w = dot(r2.xy, r3.xy);
                r0.z = r0.z + r0.w;
                r0.z = 49 * r0.z;
                r0.w = dot(abs(r0.zz), _ChaosDistort);
                r0.y = abs(r0.y) * 2 + abs(r0.z);
                r17.xz = r17.xz * float2(0.5,0.5) + r0.ww;
                r2.xyzw = float4(2,4,2,1) * r17.xyzw;
                r0.z = dot(r2.xyzw, float4(0.309017003,0.309017003,0.309017003,0.309017003));
                r2.xyzw = r17.xyzw * float4(2,4,2,1) + r0.zzzz;
                r2.xyzw = floor(r2.xyzw);
                r3.xyzw = r17.xyzw * float4(2,4,2,1) + -r2.xyzw;
                r0.z = dot(r2.xyzw, float4(0.138196602,0.138196602,0.138196602,0.138196602));
                r3.xyzw = r3.xyzw + r0.zzzz;
                r15.xyz = cmp(r3.xxx >= r3.yzw);
                r16.xyz = cmp(r3.yyz >= r3.zww);
                r17.xyz = r15.xyz ? float3(1,1,1) : 0;
                r15.xyz = r15.xyz ? float3(0,0,0) : float3(1,1,1);
                r0.z = r17.x + r17.y;
                r17.x = r0.z + r17.z;
                r18.xyz = r16.xyz ? float3(1,1,1) : 0;
                r16.xyz = r16.xyz ? float3(-1,-1,-1) : float3(-0,-0,-0);
                r0.z = r18.x + r18.y;
                r17.y = r15.x + r0.z;
                r0.zw = r16.xy + r15.yz;
                r15.xy = r17.xy;
                r18.w = 1;
                r0.zw = r18.zw + r0.zw;
                r15.w = r0.w + r16.z;
                r15.z = r0.z;
                r17.z = 1 + r0.z;
                r16.xyzw = float4(-2,-2,-1,-1) + r15.xyzw;
                r18.xyzw = saturate(float4(-1,-1,0,0) + r15.xyzw);
                r17.w = 1 + r15.w;
                r15.xyzw = min(float4(1,1,1,1), r17.xyzw);
                r16.xyzw = max(float4(0,0,0,0), r16.xyzw);
                r17.xyzw = -r16.xyzw + r3.xyzw;
                r19.xyzw = -r18.xyzw + r3.xyzw;
                r20.xyzw = -r15.xyzw + r3.xyzw;
                r21.xyzw = float4(-0.44721359,-0.44721359,-0.44721359,-0.44721359) + r3.xyzw;
                r22.x = dot(r3.xyzw, r3.xyzw);
                r23.x = r16.z;
                r23.y = r18.z;
                r23.z = r15.z;
                r24.xyzw = float4(0.00346020772,0.00346020772,0.00346020772,0.00346020772) * r2.xyzw;
                r24.xyzw = floor(r24.xyzw);
                r2.xyzw = -r24.xyzw * float4(289,289,289,289) + r2.xyzw;
                r24.x = r16.w;
                r24.y = r18.w;
                r24.z = r15.w;
                r24.w = 1;
                r24.xyzw = r24.xyzw + r2.wwww;
                r25.xyzw = r24.xyzw * r24.xyzw;
                r24.xyzw = r25.xyzw * float4(34,34,34,34) + r24.xyzw;
                r25.xyzw = float4(0.00346020772,0.00346020772,0.00346020772,0.00346020772) * r24.xyzw;
                r25.xyzw = floor(r25.xyzw);
                r24.xyzw = -r25.xyzw * float4(289,289,289,289) + r24.xyzw;
                r24.xyzw = r24.xyzw + r2.zzzz;
                r23.w = 1;
                r23.xyzw = r24.xyzw + r23.xyzw;
                r24.xyzw = r23.xyzw * r23.xyzw;
                r23.xyzw = r24.xyzw * float4(34,34,34,34) + r23.xyzw;
                r24.xyzw = float4(0.00346020772,0.00346020772,0.00346020772,0.00346020772) * r23.xyzw;
                r24.xyzw = floor(r24.xyzw);
                r23.xyzw = -r24.xyzw * float4(289,289,289,289) + r23.xyzw;
                r23.xyzw = r23.xyzw + r2.yyyy;
                r24.x = r16.y;
                r24.y = r18.y;
                r16.y = r18.x;
                r24.z = r15.y;
                r16.z = r15.x;
                r24.w = 1;
                r15.xyzw = r24.xyzw + r23.xyzw;
                r18.xyzw = r15.xyzw * r15.xyzw;
                r15.xyzw = r18.xyzw * float4(34,34,34,34) + r15.xyzw;
                r18.xyzw = float4(0.00346020772,0.00346020772,0.00346020772,0.00346020772) * r15.xyzw;
                r18.xyzw = floor(r18.xyzw);
                r15.xyzw = -r18.xyzw * float4(289,289,289,289) + r15.xyzw;
                r15.xyzw = r15.xyzw + r2.xxxx;
                r16.w = 1;
                r15.xyzw = r16.xyzw + r15.xyzw;
                r16.xyzw = r15.xyzw * r15.xyzw;
                r15.xyzw = r16.xyzw * float4(34,34,34,34) + r15.xyzw;
                r16.xyzw = float4(0.00346020772,0.00346020772,0.00346020772,0.00346020772) * r15.xyzw;
                r16.xyzw = floor(r16.xyzw);
                r15.xyzw = -r16.xyzw * float4(289,289,289,289) + r15.xyzw;
                r16.xyz = float3(0.00340136047,0.0204081628,0.142857149) * r15.xxx;
                r16.xyz = frac(r16.xyz);
                r16.xyz = float3(7,7,7) * r16.xyz;
                r16.xyz = floor(r16.xyz);
                r16.xyz = r16.xyz * float3(0.142857149,0.142857149,0.142857149) + float3(-1,-1,-1);
                r0.z = dot(-r16.xyz, float3(1,1,1));
                r18.w = 1.5 + -r0.z;
                r0.z = cmp(r18.w >= 0);
                r0.z = r0.z ? 0 : 1;
                r18.xyz = r16.xyz + r0.zzz;
                r16.y = dot(r18.xyzw, r18.xyzw);
                r23.xyz = float3(0.00340136047,0.0204081628,0.142857149) * r15.yyy;
                r23.xyz = frac(r23.xyz);
                r23.xyz = float3(7,7,7) * r23.xyz;
                r23.xyz = floor(r23.xyz);
                r23.xyz = r23.xyz * float3(0.142857149,0.142857149,0.142857149) + float3(-1,-1,-1);
                r0.z = dot(-r23.xyz, float3(1,1,1));
                r24.w = 1.5 + -r0.z;
                r0.z = cmp(r24.w >= 0);
                r0.z = r0.z ? 0 : 1;
                r24.xyz = r23.xyz + r0.zzz;
                r16.z = dot(r24.xyzw, r24.xyzw);
                r15.xyz = float3(0.00340136047,0.0204081628,0.142857149) * r15.zzz;
                r23.xyz = float3(0.00340136047,0.0204081628,0.142857149) * r15.www;
                r23.xyz = frac(r23.xyz);
                r23.xyz = float3(7,7,7) * r23.xyz;
                r23.xyz = floor(r23.xyz);
                r23.xyz = r23.xyz * float3(0.142857149,0.142857149,0.142857149) + float3(-1,-1,-1);
                r15.xyz = frac(r15.xyz);
                r15.xyz = float3(7,7,7) * r15.xyz;
                r15.xyz = floor(r15.xyz);
                r15.xyz = r15.xyz * float3(0.142857149,0.142857149,0.142857149) + float3(-1,-1,-1);
                r0.z = dot(-r15.xyz, float3(1,1,1));
                r25.w = 1.5 + -r0.z;
                r0.z = cmp(r25.w >= 0);
                r0.z = r0.z ? 0 : 1;
                r25.xyz = r15.xyz + r0.zzz;
                r16.w = dot(r25.xyzw, r25.xyzw);
                r0.z = r2.w * r2.w;
                r0.z = r0.z * 34 + r2.w;
                r0.w = 0.00346020772 * r0.z;
                r0.w = floor(r0.w);
                r0.z = -r0.w * 289 + r0.z;
                r0.z = r0.z + r2.z;
                r0.w = r0.z * r0.z;
                r0.z = r0.w * 34 + r0.z;
                r0.w = 0.00346020772 * r0.z;
                r0.w = floor(r0.w);
                r0.z = -r0.w * 289 + r0.z;
                r0.z = r0.z + r2.y;
                r0.w = r0.z * r0.z;
                r0.z = r0.w * 34 + r0.z;
                r0.w = 0.00346020772 * r0.z;
                r0.w = floor(r0.w);
                r0.z = -r0.w * 289 + r0.z;
                r0.z = r0.z + r2.x;
                r0.w = r0.z * r0.z;
                r0.z = r0.w * 34 + r0.z;
                r0.w = 0.00346020772 * r0.z;
                r0.w = floor(r0.w);
                r0.z = -r0.w * 289 + r0.z;
                r2.xyz = float3(0.00340136047,0.0204081628,0.142857149) * r0.zzz;
                r2.xyz = frac(r2.xyz);
                r2.xyz = float3(7,7,7) * r2.xyz;
                r2.xyz = floor(r2.xyz);
                r2.xyz = r2.xyz * float3(0.142857149,0.142857149,0.142857149) + float3(-1,-1,-1);
                r0.z = dot(-r2.xyz, float3(1,1,1));
                r15.w = 1.5 + -r0.z;
                r0.z = cmp(r15.w >= 0);
                r0.z = r0.z ? 0 : 1;
                r15.xyz = r2.xyz + r0.zzz;
                r16.x = dot(r15.xyzw, r15.xyzw);
                r2.xyzw = -r16.xyzw * float4(0.853734732,0.853734732,0.853734732,0.853734732) + float4(1.79284286,1.79284286,1.79284286,1.79284286);
                r15.xyzw = r15.xyzw * r2.xxxx;
                r3.x = dot(r15.xyzw, r3.xyzw);
                r15.xyzw = float4(0.138196602,0.138196602,0.138196602,0.138196602) + r17.xyzw;
                r22.y = dot(r15.xyzw, r15.xyzw);
                r16.xyzw = float4(0.276393205,0.276393205,0.276393205,0.276393205) + r19.xyzw;
                r22.z = dot(r16.xyzw, r16.xyzw);
                r17.xyz = float3(0.600000024,0.600000024,0.600000024) + -r22.xyz;
                r17.xyz = max(float3(0,0,0), r17.xyz);
                r17.xyz = r17.xyz * r17.xyz;
                r17.xyz = r17.xyz * r17.xyz;
                r18.xyzw = r18.xyzw * r2.yyyy;
                r3.y = dot(r18.xyzw, r15.xyzw);
                r15.xyzw = r24.xyzw * r2.zzzz;
                r2.xyzw = r25.xyzw * r2.wwww;
                r3.z = dot(r15.xyzw, r16.xyzw);
                r0.z = dot(r17.xyz, r3.xyz);
                r0.w = dot(-r23.xyz, float3(1,1,1));
                r3.w = 1.5 + -r0.w;
                r0.w = cmp(r3.w >= 0);
                r0.w = r0.w ? 0 : 1;
                r3.xyz = r23.xyz + r0.www;
                r0.w = dot(r3.xyzw, r3.xyzw);
                r0.w = -r0.w * 0.853734732 + 1.79284286;
                r3.xyzw = r3.xyzw * r0.wwww;
                r3.y = dot(r3.xyzw, r21.xyzw);
                r15.y = dot(r21.xyzw, r21.xyzw);
                r16.xyzw = float4(0.414589792,0.414589792,0.414589792,0.414589792) + r20.xyzw;
                r3.x = dot(r2.xyzw, r16.xyzw);
                r15.x = dot(r16.xyzw, r16.xyzw);
                r2.xy = float2(0.600000024,0.600000024) + -r15.xy;
                r2.xy = max(float2(0,0), r2.xy);
                r2.xy = r2.xy * r2.xy;
                r2.xy = r2.xy * r2.xy;
                r0.w = dot(r2.xy, r3.xy);
                r0.z = r0.z + r0.w;
                r0.z = 49 * r0.z;
                r0.y = abs(r0.z) * 0.5 + r0.y;
                r0.y = sin(-r0.y);
                r0.y = 1 + r0.y;
                r0.y = r0.y * 0.899999976 + 0.100000001;
                r0.y = min(1, r0.y);
                r2.xyzw = float4(0.138196602,0.138196602,0.138196602,0.138196602) + r8.xyzw;
                r12.y = dot(r2.xyzw, r2.xyzw);
                r3.xyzw = float4(0.276393205,0.276393205,0.276393205,0.276393205) + r9.xyzw;
                r12.z = dot(r3.xyzw, r3.xyzw);
                r8.xyz = float3(0.600000024,0.600000024,0.600000024) + -r12.xyz;
                r8.xyz = max(float3(0,0,0), r8.xyz);
                r8.xyz = r8.xyz * r8.xyz;
                r8.xyz = r8.xyz * r8.xyz;
                r6.xyzw = r7.yyyy * r6.xyzw;
                r1.y = dot(r6.xyzw, r2.xyzw);
                r2.xyzw = r13.xyzw * r7.zzzz;
                r6.xyzw = r14.xyzw * r7.wwww;
                r1.z = dot(r2.xyzw, r3.xyzw);
                r0.z = dot(r8.xyz, r1.xyz);
                r0.w = dot(-r5.xyz, float3(1,1,1));
                r1.w = 1.5 + -r0.w;
                r0.w = cmp(r1.w >= 0);
                r0.w = r0.w ? 0 : 1;
                r1.xyz = r5.xyz + r0.www;
                r0.w = dot(r1.xyzw, r1.xyzw);
                r0.w = -r0.w * 0.853734732 + 1.79284286;
                r1.xyzw = r1.xyzw * r0.wwww;
                r1.y = dot(r1.xyzw, r11.xyzw);
                r2.y = dot(r11.xyzw, r11.xyzw);
                r3.xyzw = float4(0.414589792,0.414589792,0.414589792,0.414589792) + r10.xyzw;
                r1.x = dot(r6.xyzw, r3.xyzw);
                r2.x = dot(r3.xyzw, r3.xyzw);
                r1.zw = float2(0.600000024,0.600000024) + -r2.xy;
                r1.zw = max(float2(0,0), r1.zw);
                r1.zw = r1.zw * r1.zw;
                r1.zw = r1.zw * r1.zw;
                r0.w = dot(r1.zw, r1.xy);
                r0.z = r0.z + r0.w;
                r0.x = r0.z * 6.125 + r0.x;
                r0.x = r0.x * 0.200000003 + 0.600000024;
                r0.x = max(0, r0.x);
                r0.z = dot(r4.xyzw, float4(0.309017003,0.309017003,0.309017003,0.309017003));
                r1.xyzw = r4.xyzw + r0.zzzz;
                r1.xyzw = floor(r1.xyzw);
                r2.xyzw = float4(0.00346020772,0.00346020772,0.00346020772,0.00346020772) * r1.xyzw;
                r2.xyzw = floor(r2.xyzw);
                r2.xyzw = -r2.xyzw * float4(289,289,289,289) + r1.xyzw;
                r0.z = r2.w * r2.w;
                r0.z = r0.z * 34 + r2.w;
                r0.w = 0.00346020772 * r0.z;
                r0.w = floor(r0.w);
                r0.z = -r0.w * 289 + r0.z;
                r0.z = r0.z + r2.z;
                r0.xw = r0.xz * r0.xz;
                r0.z = r0.w * 34 + r0.z;
                r0.w = 0.00346020772 * r0.z;
                r0.w = floor(r0.w);
                r0.z = -r0.w * 289 + r0.z;
                r0.z = r0.z + r2.y;
                r0.w = r0.z * r0.z;
                r0.z = r0.w * 34 + r0.z;
                r0.w = 0.00346020772 * r0.z;
                r0.w = floor(r0.w);
                r0.z = -r0.w * 289 + r0.z;
                r0.z = r0.z + r2.x;
                r0.w = r0.z * r0.z;
                r0.z = r0.w * 34 + r0.z;
                r0.w = 0.00346020772 * r0.z;
                r0.w = floor(r0.w);
                r0.z = -r0.w * 289 + r0.z;
                r3.xyz = float3(0.00340136047,0.0204081628,0.142857149) * r0.zzz;
                r3.xyz = frac(r3.xyz);
                r3.xyz = float3(7,7,7) * r3.xyz;
                r3.xyz = floor(r3.xyz);
                r3.xyz = r3.xyz * float3(0.142857149,0.142857149,0.142857149) + float3(-1,-1,-1);
                r0.z = dot(-r3.xyz, float3(1,1,1));
                r5.w = 1.5 + -r0.z;
                r0.z = cmp(r5.w >= 0);
                r0.z = r0.z ? 0 : 1;
                r5.xyz = r3.xyz + r0.zzz;
                r3.x = dot(r5.xyzw, r5.xyzw);
                r4.xyzw = r4.xyzw + -r1.xyzw;
                r0.z = dot(r1.xyzw, float4(0.138196602,0.138196602,0.138196602,0.138196602));
                r1.xyzw = r4.xyzw + r0.zzzz;
                r4.xyz = cmp(r1.xxx >= r1.yzw);
                r6.xyz = r4.xyz ? float3(1,1,1) : 0;
                r4.xyz = r4.xyz ? float3(0,0,0) : float3(1,1,1);
                r0.z = r6.x + r6.y;
                r6.x = r0.z + r6.z;
                r7.xyz = cmp(r1.yyz >= r1.zww);
                r8.xyz = r7.xyz ? float3(1,1,1) : 0;
                r7.xyz = r7.xyz ? float3(-1,-1,-1) : float3(-0,-0,-0);
                r0.z = r8.x + r8.y;
                r6.y = r4.x + r0.z;
                r0.zw = r7.xy + r4.yz;
                r8.w = 1;
                r4.xz = r8.wz + r0.wz;
                r6.z = 1 + r4.z;
                r4.w = r4.x + r7.z;
                r6.w = 1 + r4.w;
                r7.xyzw = min(float4(1,1,1,1), r6.yzxw);
                r4.xy = r6.xy;
                r6.z = r7.w;
                r8.xyzw = float4(-2,-2,-1,-1) + r4.xyzw;
                r4.xyzw = saturate(float4(-1,-1,0,0) + r4.xyzw);
                r8.xyzw = max(float4(0,0,0,0), r8.xyzw);
                r6.x = r8.w;
                r6.y = r4.w;
                r6.w = 1;
                r6.xyzw = r6.xyzw + r2.wwww;
                r9.xyzw = r6.xyzw * r6.xyzw;
                r6.xyzw = r9.xyzw * float4(34,34,34,34) + r6.xyzw;
                r9.xyzw = float4(0.00346020772,0.00346020772,0.00346020772,0.00346020772) * r6.xyzw;
                r9.xyzw = floor(r9.xyzw);
                r6.xyzw = -r9.xyzw * float4(289,289,289,289) + r6.xyzw;
                r6.xyzw = r6.xyzw + r2.zzzz;
                r9.z = r7.y;
                r9.x = r8.z;
                r9.y = r4.z;
                r9.w = 1;
                r6.xyzw = r9.xyzw + r6.xyzw;
                r9.xyzw = r6.xyzw * r6.xyzw;
                r6.xyzw = r9.xyzw * float4(34,34,34,34) + r6.xyzw;
                r9.xyzw = float4(0.00346020772,0.00346020772,0.00346020772,0.00346020772) * r6.xyzw;
                r9.xyzw = floor(r9.xyzw);
                r6.xyzw = -r9.xyzw * float4(289,289,289,289) + r6.xyzw;
                r6.xyzw = r6.xyzw + r2.yyyy;
                r9.z = r7.x;
                r9.x = r8.y;
                r9.y = r4.y;
                r9.w = 1;
                r6.xyzw = r9.xyzw + r6.xyzw;
                r9.xyzw = r6.xyzw * r6.xyzw;
                r6.xyzw = r9.xyzw * float4(34,34,34,34) + r6.xyzw;
                r9.xyzw = float4(0.00346020772,0.00346020772,0.00346020772,0.00346020772) * r6.xyzw;
                r9.xyzw = floor(r9.xyzw);
                r6.xyzw = -r9.xyzw * float4(289,289,289,289) + r6.xyzw;
                r2.xyzw = r6.xyzw + r2.xxxx;
                r6.xyzw = -r7.zxyw + r1.xyzw;
                r6.xyzw = float4(0.414589792,0.414589792,0.414589792,0.414589792) + r6.xyzw;
                r7.x = r8.x;
                r8.xyzw = -r8.xyzw + r1.xyzw;
                r8.xyzw = float4(0.138196602,0.138196602,0.138196602,0.138196602) + r8.xyzw;
                r7.y = r4.x;
                r4.xyzw = -r4.xyzw + r1.xyzw;
                r4.xyzw = float4(0.276393205,0.276393205,0.276393205,0.276393205) + r4.xyzw;
                r7.w = 1;
                r2.xyzw = r7.xyzw + r2.xyzw;
                r7.xyzw = r2.xyzw * r2.xyzw;
                r2.xyzw = r7.xyzw * float4(34,34,34,34) + r2.xyzw;
                r7.xyzw = float4(0.00346020772,0.00346020772,0.00346020772,0.00346020772) * r2.xyzw;
                r7.xyzw = floor(r7.xyzw);
                r2.xyzw = -r7.xyzw * float4(289,289,289,289) + r2.xyzw;
                r7.xyz = float3(0.00340136047,0.0204081628,0.142857149) * r2.xxx;
                r7.xyz = frac(r7.xyz);
                r7.xyz = float3(7,7,7) * r7.xyz;
                r7.xyz = floor(r7.xyz);
                r7.xyz = r7.xyz * float3(0.142857149,0.142857149,0.142857149) + float3(-1,-1,-1);
                r0.z = dot(-r7.xyz, float3(1,1,1));
                r9.w = 1.5 + -r0.z;
                r0.z = cmp(r9.w >= 0);
                r0.z = r0.z ? 0 : 1;
                r9.xyz = r7.xyz + r0.zzz;
                r3.y = dot(r9.xyzw, r9.xyzw);
                r7.xyz = float3(0.00340136047,0.0204081628,0.142857149) * r2.yyy;
                r7.xyz = frac(r7.xyz);
                r7.xyz = float3(7,7,7) * r7.xyz;
                r7.xyz = floor(r7.xyz);
                r7.xyz = r7.xyz * float3(0.142857149,0.142857149,0.142857149) + float3(-1,-1,-1);
                r0.z = dot(-r7.xyz, float3(1,1,1));
                r10.w = 1.5 + -r0.z;
                r0.z = cmp(r10.w >= 0);
                r0.z = r0.z ? 0 : 1;
                r10.xyz = r7.xyz + r0.zzz;
                r3.z = dot(r10.xyzw, r10.xyzw);
                r2.xyz = float3(0.00340136047,0.0204081628,0.142857149) * r2.zzz;
                r7.xyz = float3(0.00340136047,0.0204081628,0.142857149) * r2.www;
                r7.xyz = frac(r7.xyz);
                r7.xyz = float3(7,7,7) * r7.xyz;
                r7.xyz = floor(r7.xyz);
                r7.xyz = r7.xyz * float3(0.142857149,0.142857149,0.142857149) + float3(-1,-1,-1);
                r2.xyz = frac(r2.xyz);
                r2.xyz = float3(7,7,7) * r2.xyz;
                r2.xyz = floor(r2.xyz);
                r2.xyz = r2.xyz * float3(0.142857149,0.142857149,0.142857149) + float3(-1,-1,-1);
                r0.z = dot(-r2.xyz, float3(1,1,1));
                r11.w = 1.5 + -r0.z;
                r0.z = cmp(r11.w >= 0);
                r0.z = r0.z ? 0 : 1;
                r11.xyz = r2.xyz + r0.zzz;
                r3.w = dot(r11.xyzw, r11.xyzw);
                r2.xyzw = -r3.xyzw * float4(0.853734732,0.853734732,0.853734732,0.853734732) + float4(1.79284286,1.79284286,1.79284286,1.79284286);
                r3.xyzw = r9.xyzw * r2.yyyy;
                r3.y = dot(r3.xyzw, r8.xyzw);
                r8.y = dot(r8.xyzw, r8.xyzw);
                r9.xyzw = r10.xyzw * r2.zzzz;
                r3.z = dot(r9.xyzw, r4.xyzw);
                r8.z = dot(r4.xyzw, r4.xyzw);
                r4.xyzw = r5.xyzw * r2.xxxx;
                r2.xyzw = r11.xyzw * r2.wwww;
                r2.x = dot(r2.xyzw, r6.xyzw);
                r5.x = dot(r6.xyzw, r6.xyzw);
                r3.x = dot(r4.xyzw, r1.xyzw);
                r8.x = dot(r1.xyzw, r1.xyzw);
                r1.xyzw = float4(-0.44721359,-0.44721359,-0.44721359,-0.44721359) + r1.xyzw;
                r4.xyz = float3(0.6, 0.6, 0.6) + -r8.xyz;
                r4.xyz = max(float3(0,0,0), r4.xyz);
                r4.xyz = r4.xyz * r4.xyz;
                r4.xyz = r4.xyz * r4.xyz;
                r0.z = dot(r4.xyz, r3.xyz);
                r0.w = dot(-r7.xyz, float3(1,1,1));
                r3.w = 1.5 + -r0.w;
                r0.w = cmp(r3.w >= 0);
                r0.w = r0.w ? 0 : 1;
                r3.xyz = r7.xyz + r0.www;
                r0.w = dot(r3.xyzw, r3.xyzw);
                r0.w = -r0.w * 0.853734732 + 1.79284286;
                r3.xyzw = r3.xyzw * r0.wwww;
                r2.y = dot(r3.xyzw, r1.xyzw);
                r5.y = dot(r1.xyzw, r1.xyzw);
                
                r1.xy = max(float2(0,0), float2(0.6, 0.6) - r5.xy);
                r1.xy = pow(r1.xy, 4);
                
                r0.z = r0.z + dot(r1.xy, r2.xy);
                
                r0.w = r0.y * saturate(-r0.z * 49 - 0.55);
                r0.z = r0.y * saturate(r0.z * 49 - 0.7);
                r0.z = 1 - min(1, 0.7 * _SpotIntens * r0.z);
                r0.y = lerp(1, r0.y, _ChaosOverlay);
                r0.z = r0.w * _SpotIntens + r0.z;
                r0.x = min(1, r0.x * r0.z * r0.y);
                r0.yzw = lerp(_Color1, _Color0, r0.x);
                
                r0.xyz = r0.yzw * r0.xxx + _Color2.xyz;
                
                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz); //r1.xyz
                float3 worldNormal = normalize(i.worldNormal); //r2.xyz
                float nDotV = dot(worldNormal.xyz, viewDir.xyz); //r0.w
                
                r0.w = pow(max(0, 1.0 - abs(nDotV)), _RimPower);
                r0.xyz = r0.www * _Color3.xyz + r0.xyz;
                o.sv_target.xyz = _Multiplier * r0.xyz;
                o.sv_target.w = 1;
                return o;
            }
            ENDCG
        }
    }
}