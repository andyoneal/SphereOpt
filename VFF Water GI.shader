Shader "VF Shaders/Forward/VFF Water GI" {
    Properties {
        _Color ("Color 0", Vector) = (1,1,1,1)
        _Color1 ("Color 1", Vector) = (1,1,1,1)
        _Color2 ("Color 2", Vector) = (1,1,1,1)
        _Color3 ("Color 3", Vector) = (1,1,1,1)
        _ShoreIntens ("Shore Intens", Float) = 1.5
        _FresnelColor ("Fresnel Color", Vector) = (1,1,1,1)
        _DepthFactor ("Depth Factor", Vector) = (0.3,0.5,0.5,0.15)
        _GITex ("GI Texture", Cube) = "black" {}
        _BumpTex ("Bump Texture", 2D) = "bump" {}
        _FoamColor ("Foam Color", Vector) = (1,1,1,1)
        _FoamSpeed ("Foam Speed", Float) = 0.15
        _FoamSync ("Foam Sync", Float) = 10
        _FoamInvThickness ("Foam Inv Thickness", Float) = 4
        _CausticsTex ("Caustics Texture", 2D) = "black" {}
        _RefractionStrength ("Refraction Strength", Float) = 1
        _NormalStrength ("Normal Strength", Float) = 1
        _NormalTiling ("Normal Tiling", Float) = 0.1
        _NormalSpeed ("Normal Speed", Float) = 1.4
        _SpeclColor ("Spec Color", Vector) = (1,1,1,1)
        _SpeclColor1 ("Spec Color 1", Vector) = (1,1,1,1)
        _CausticsColor ("Caustics Color", Vector) = (1,1,1,1)
        _CausticsTiling ("Caustics Tiling", Float) = 0.1
        _GIStrengthDay ("全局光照（白天）", Range(0, 1)) = 1
        _GIStrengthNight ("全局光照（夜晚）", Range(0, 1)) = 0.2
        _GISaturate ("全局光照饱和度", Range(0, 1)) = 1
        _GIGloss ("全局光照清晰度", Range(0, 1)) = 0.7
        _Radius ("Radius", Float) = 200
    }
    SubShader {
        Tags { "DisableBatching" = "true" "IGNOREPROJECTOR" = "true" "QUEUE" = "Transparent-10" }
        GrabPass {
            "_ScreenTex"
        }
        Pass {
            Tags { "DisableBatching" = "true" "IGNOREPROJECTOR" = "true" "QUEUE" = "Transparent-10" }
            GpuProgramID 15630
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 5.0
            #pragma enable_d3d11_debug_symbols
            
            #include "UnityCG.cginc"
            struct v2f
            {   
                float4 pos : SV_POSITION0;
                float3 normal : NORMAL0;
                float3 tangent : TANGENT0;
                float3 binormal : TEXCOORD2;
                float3 worldPos : TEXCOORD0;
                float4 clipPos : TEXCOORD1;
            };
            
            struct fout
            {
                float4 sv_target : SV_Target0;
            };
            
            float4 _Global_WaterAmbientColor0;
            float4 _Global_WaterAmbientColor1;
            float4 _Global_WaterAmbientColor2;
            float4 _Global_SunsetColor0;
            float4 _Global_SunsetColor1;
            float4 _Global_SunsetColor2;
            float4 _Color;
            float4 _Color1;
            float4 _Color2;
            float4 _Color3;
            float _ShoreIntens;
            float4 _FresnelColor;
            float4 _DepthFactor;
            float4 _FoamColor;
            float _FoamSpeed;
            float _FoamSync;
            float _FoamInvThickness;
            float _RefractionStrength;
            float _NormalStrength;
            float _NormalTiling;
            float _NormalSpeed;
            float4 _SpeclColor;
            float4 _SpeclColor1;
            float4 _CausticsColor;
            float _CausticsTiling;
            float _GIStrengthDay;
            float _GIStrengthNight;
            float _GISaturate;
            float _GIGloss;
            float _Radius;
            float _Global_Water_Hint;
            float _Global_WhiteMode0;
            float4 _ScreenTex_TexelSize;
            float4 _Global_SunDir;

            sampler2D _BumpTex;
            sampler2D _CameraDepthTexture;
            sampler2D _CausticsTex;
            sampler2D _ScreenTex;
            samplerCUBE _GITex;
            
            v2f vert(appdata_full v) {
              v2f o;
              
              float3 worldPos = mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1)).xyz; //r0.xyz
              
              float distCamToVert = distance(_WorldSpaceCameraPos, worldPos);
              float scale = saturate((distCamToVert - 10000) / 10000);
              float3 scaledVertPos = (normalize(v.vertex.xyz) * scale) / 800.0;
              float3 vertPos = v.vertex.xyz + scaledVertPos; //if camera is far away, increase size by a tiny bit?
              
              float4 clipPos = UnityObjectToClipPos(vertPos); //r0.xyzw
              float3 worldNormal = UnityObjectToWorldNormal(v.normal.xyz); //r0.xyz
              float3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz); //r1.xyz
              
              o.pos.xyzw = clipPos;
              o.normal.xyz = worldNormal;
              o.tangent.xyz = worldTangent.xyz;
              o.binormal.xyz = normalize(cross(worldNormal, worldTangent));
              o.worldPos.xyz = worldPos;
              o.clipPos.xyzw = clipPos;
              
              return o;
            }
            
            fout frag(v2f inp)
            {
                fout o;
                float4 tmp0;
                float4 tmp1;
                float4 tmp2;
                float4 tmp3;
                float4 tmp4;
                float4 tmp5;
                float4 tmp6;
                float4 tmp7;
                float4 tmp8;
                float4 tmp9;
                float4 tmp10;
                float4 tmp11;
                float4 tmp12;
                float4 tmp13;
                float4 tmp14;
                tmp0.xz = inp.texcoord1.xw * float2(0.5, 0.5);
                tmp0.y = inp.texcoord1.y * _ProjectionParams.x;
                tmp0.w = tmp0.y * 0.5;
                tmp0.xy = tmp0.zz + tmp0.xw;
                tmp0.xy = tmp0.xy / inp.texcoord1.ww;
                tmp1 = tex2D(_CameraDepthTexture, tmp0.xy);
                tmp0.w = _ZBufferParams.z * tmp1.x + _ZBufferParams.w;
                tmp0.w = 1.0 / tmp0.w;
                tmp0.w = tmp0.w - inp.texcoord1.w;
                tmp0.w = max(tmp0.w, 0.0);
                tmp1.x = tmp0.w <= 0.0;
                if (tmp1.x) {
                    discard;
                }
                tmp1.x = dot(abs(inp.normal.xyz), abs(inp.normal.xyz));
                tmp1.x = rsqrt(tmp1.x);
                tmp1.xyz = saturate(abs(inp.normal.xyz) * tmp1.xxx + float3(-0.1, -0.1, -0.1));
                tmp1.w = tmp1.y + tmp1.x;
                tmp1.w = tmp1.z + tmp1.w;
                tmp1.xyz = tmp1.xyz / tmp1.www;
                tmp1.w = _NormalSpeed / _Radius;
                tmp2.x = _NormalTiling * _Radius;
                tmp3.xy = _Time.yy * tmp1.ww + inp.normal.yz;
                tmp3.zw = inp.normal.zx;
                tmp4 = tmp2.xxxx * tmp3.zxwy;
                tmp5 = tex2D(_BumpTex, tmp4.xy);
                tmp2.yz = tmp5.wy * float2(2.0, 2.0) + float2(-0.996078, -0.996078);
                tmp5.xy = _Time.yy * tmp1.ww + -inp.normal.zx;
                tmp5.zw = -_Time.yy * tmp1.ww + inp.normal.yz;
                tmp6 = tmp2.xxxx * tmp5.xzyw;
                tmp3.yz = tmp2.yz * float2(0.15, 0.15) + tmp6.xy;
                tmp7 = tex2D(_BumpTex, tmp3.yz);
                tmp3.yz = tmp7.wy * float2(2.0, 2.0) + float2(-0.996078, -0.996078);
                tmp4 = tex2D(_BumpTex, tmp4.zw);
                tmp4.xy = tmp4.wy * float2(2.0, 2.0) + float2(-0.996078, -0.996078);
                tmp4.zw = tmp4.xy * float2(0.15, 0.15) + tmp6.zw;
                tmp6 = tex2D(_BumpTex, tmp4.zw);
                tmp4.zw = tmp6.wy * float2(2.0, 2.0) + float2(-0.996078, -0.996078);
                tmp3.xw = tmp2.xx * tmp3.wx;
                tmp6 = tex2D(_BumpTex, tmp3.xw);
                tmp3.xw = tmp6.wy * float2(2.0, 2.0) + float2(-0.996078, -0.996078);
                tmp5.xw = tmp3.xw * float2(0.15, 0.15);
                tmp2.xw = tmp5.yz * tmp2.xx + tmp5.xw;
                tmp5 = tex2D(_BumpTex, tmp2.xw);
                tmp2.xw = tmp5.wy * float2(2.0, 2.0) + float2(-0.996078, -0.996078);
                tmp2.yz = tmp2.yz + tmp3.yz;
                tmp3.yz = tmp4.zw + tmp4.xy;
                tmp3.yz = tmp1.yy * tmp3.yz;
                tmp2.yz = tmp2.yz * tmp1.xx + tmp3.yz;
                tmp2.xw = tmp2.xw + tmp3.xw;
                tmp2.xy = tmp2.xw * tmp1.zz + tmp2.yz;
                tmp2.w = dot(inp.normal.xyz, _Global_SunDir.xyz);
                tmp3.x = abs(tmp2.w) + 0.2;
                tmp3.x = tmp3.x * _NormalStrength;
                tmp3.yz = tmp2.xy * float2(0.5, -0.5);
                tmp3.yz = tmp3.xx * tmp3.yz;
                tmp4.xyz = tmp3.yyy * inp.tangent.xyz + inp.normal.xyz;
                tmp3.yzw = tmp3.zzz * inp.texcoord2.xyz + tmp4.xyz;
                tmp4.x = dot(tmp3.xyz, tmp3.xyz);
                tmp4.x = rsqrt(tmp4.x);
                tmp3.yzw = tmp3.yzw * tmp4.xxx;
                tmp4.x = tmp2.x * tmp3.x;
                tmp4.x = tmp4.x * 1.5;
                tmp4.xyz = tmp4.xxx * inp.tangent.xyz + inp.normal.xyz;
                tmp3.x = -tmp2.y * tmp3.x;
                tmp3.x = tmp3.x * 1.5;
                tmp4.xyz = tmp3.xxx * inp.texcoord2.xyz + tmp4.xyz;
                tmp3.x = dot(tmp4.xyz, tmp4.xyz);
                tmp3.x = rsqrt(tmp3.x);
                tmp4.xyz = tmp3.xxx * tmp4.xyz;
                tmp5.xyz = inp.texcoord.xyz - _WorldSpaceCameraPos;
                tmp3.x = dot(tmp5.xyz, tmp5.xyz);
                tmp3.x = rsqrt(tmp3.x);
                tmp6.xyz = tmp3.xxx * tmp5.xyz;
                tmp4.w = dot(tmp3.xyz, _Global_SunDir.xyz);
                tmp5.w = saturate(dot(tmp6.xyz, -tmp3.xyz));
                tmp6.w = saturate(dot(tmp6.xyz, -inp.normal.xyz));
                tmp7.x = dot(tmp6.xyz, tmp3.xyz);
                tmp7.x = tmp7.x + tmp7.x;
                tmp3.yzw = tmp3.yzw * -tmp7.xxx + tmp6.xyz;
                tmp7.xy = inp.texcoord1.xy * float2(0.5, -0.5) + tmp0.zz;
                tmp0.z = tmp0.w * tmp6.w;
                tmp7.z = -tmp0.w * tmp6.w + 0.27;
                tmp7.z = 0.01 - abs(tmp7.z);
                tmp7.z = max(tmp7.z, 0.0);
                tmp7.z = tmp7.z * _Global_Water_Hint;
                tmp7.z = tmp7.z * 100.0;
                tmp7.w = _ScreenTex_TexelSize.z / _ScreenTex_TexelSize.w;
                tmp8.x = _RefractionStrength * 0.4;
                tmp2.z = -tmp2.y * tmp7.w;
                tmp8.xy = tmp2.xz * tmp8.xx;
                tmp8.xy = tmp8.xy / inp.texcoord1.ww;
                tmp0.xy = tmp0.xy + tmp8.xy;
                tmp0.xy = tmp0.xy * inp.texcoord1.ww;
                tmp0.xy = tmp0.xy / inp.texcoord1.ww;
                tmp8 = tex2D(_CameraDepthTexture, tmp0.xy);
                tmp0.x = _ZBufferParams.z * tmp8.x + _ZBufferParams.w;
                tmp0.x = 1.0 / tmp0.x;
                tmp0.x = tmp0.x - inp.texcoord1.w;
                tmp0.x = tmp6.w * tmp0.x;
                tmp0.y = tmp0.x < 0.0;
                tmp0.x = tmp0.y ? tmp0.z : tmp0.x;
                tmp0.y = min(tmp0.z, 1.0);
                tmp0.x = -tmp0.w * tmp6.w + tmp0.x;
                tmp0.x = tmp0.y * tmp0.x + tmp0.z;
                tmp0.y = tmp0.x > 1.0;
                tmp0.z = log(tmp0.x);
                tmp0.z = tmp0.z * 0.6931472 + 1.0;
                tmp0.y = tmp0.y ? tmp0.z : tmp0.x;
                tmp0.zw = tmp0.yy * _DepthFactor.xy;
                tmp8.xy = saturate(tmp0.zw);
                tmp0.z = log(tmp8.y);
                tmp0.z = tmp0.z * _DepthFactor.z;
                tmp0.z = exp(tmp0.z);
                tmp8.yz = saturate(tmp0.yy * float2(4.0, 3.0));
                tmp0.z = tmp0.z * tmp8.y;
                tmp0.w = saturate(tmp0.w * 0.8);
                tmp6.w = _DepthFactor.z * 0.5;
                tmp0.w = log(tmp0.w);
                tmp0.w = tmp0.w * tmp6.w;
                tmp0.w = exp(tmp0.w);
                tmp0.w = 1.0 - tmp0.w;
                tmp6.w = saturate(tmp0.y * 2.0 + -0.1);
                tmp0.w = tmp0.w * tmp6.w;
                tmp0.y = min(tmp0.y, 50.0);
                tmp6.xyz = tmp6.xyz * tmp0.yyy + inp.texcoord.xyz;
                tmp9 = _Time * float4(0.7, 0.7, -0.56, -0.56) + tmp6.yzyz;
                tmp6.w = tmp9.x;
                tmp10 = tmp2.xyxy * float4(0.2, -0.2, 0.2, -0.2) + tmp6.zwxw;
                tmp10 = tmp10 * _CausticsTiling.xxxx;
                tmp11 = tex2D(_CausticsTex, tmp10.xy);
                tmp12.xy = _Time.yy * tmp1.ww + -tmp6.zx;
                tmp12.zw = tmp9.zw;
                tmp13 = tmp2.xyxy * float4(0.2, -0.2, 0.2, -0.2) + tmp12.xzyw;
                tmp13 = tmp13 * _CausticsTiling.xxxx;
                tmp14 = tex2D(_CausticsTex, tmp13.xy);
                tmp9.x = tmp6.x;
                tmp6.xy = tmp2.xy * float2(0.2, -0.2) + tmp9.xy;
                tmp6.xy = tmp6.xy * _CausticsTiling.xx;
                tmp6 = tex2D(_CausticsTex, tmp6.xy);
                tmp9 = tex2D(_CausticsTex, tmp13.zw);
                tmp10 = tex2D(_CausticsTex, tmp10.zw);
                tmp6.zw = tmp2.xy * float2(0.2, -0.2) + tmp12.yz;
                tmp6.zw = tmp6.zw * _CausticsTiling.xx;
                tmp12 = tex2D(_CausticsTex, tmp6.zw);
                tmp6.zw = tmp11.xy + tmp14.xy;
                tmp6.xy = tmp6.xy + tmp9.xy;
                tmp1.yw = tmp1.yy * tmp6.xy;
                tmp1.xy = tmp6.zw * tmp1.xx + tmp1.yw;
                tmp6.xy = tmp10.xy + tmp12.xy;
                tmp1.xy = tmp6.xy * tmp1.zz + tmp1.xy;
                tmp0.y = tmp0.w * tmp1.x;
                tmp0.w = inp.normal.y * _FoamSync;
                tmp0.w = -_Time.y * _FoamSpeed + tmp0.w;
                tmp0.w = frac(tmp0.w);
                tmp0.w = tmp0.w * 1.3 + -0.3;
                tmp1.x = 1.0 - tmp0.w;
                tmp1.x = log(tmp1.x);
                tmp1.x = tmp1.x * 1.3;
                tmp1.x = exp(tmp1.x);
                tmp1.z = tmp0.w - tmp0.x;
                tmp1.z = saturate(tmp1.z * _FoamInvThickness + 1.0);
                tmp0.w = tmp0.x - tmp0.w;
                tmp0.w = tmp0.w * _FoamInvThickness;
                tmp0.w = saturate(tmp0.w * 5.0 + 1.0);
                tmp0.w = tmp0.w * tmp1.z;
                tmp0.x = saturate(tmp0.x * 20.0);
                tmp0.x = tmp0.x * tmp0.w;
                tmp0.x = tmp1.x * tmp0.x;
                tmp0.x = tmp0.x * tmp1.y;
                tmp0.xy = tmp0.xy * float2(1.25, 1.5);
                tmp0.w = tmp0.z + tmp0.z;
                tmp0.w = min(tmp0.w, 1.0);
                tmp0.w = tmp0.w * _RefractionStrength;
                tmp1.xy = tmp7.xy / inp.texcoord1.ww;
                tmp1.zw = tmp0.ww * tmp2.xz;
                tmp1.zw = tmp1.zw / inp.texcoord1.ww;
                tmp1.xy = tmp1.zw + tmp1.xy;
                tmp1.xy = tmp1.xy * inp.texcoord1.ww;
                tmp1.xy = tmp1.xy / inp.texcoord1.ww;
                tmp1 = tex2D(_ScreenTex, tmp1.xy);
                tmp0.w = tmp2.x * _DepthFactor.w + tmp8.x;
                tmp1.w = tmp0.w >= 0.0;
                tmp2.x = tmp0.w * 5.0;
                tmp6.xyz = _Color1.xyz - _Color.xyz;
                tmp2.xyz = tmp2.xxx * tmp6.xyz + _Color.xyz;
                tmp6.xyz = tmp0.www - float3(0.2, 0.6, 0.25);
                tmp6.xyz = tmp6.zxy * float3(1.333, 2.5, 2.5);
                tmp7.xyw = _Color2.xyz - _Color1.xyz;
                tmp7.xyw = tmp6.yyy * tmp7.xyw + _Color1.xyz;
                tmp8.xyw = tmp0.www < float3(0.2, 0.6, 1.0);
                tmp9.xyz = _Color3.xyz - _Color2.xyz;
                tmp6.yzw = tmp6.zzz * tmp9.xyz + _Color2.xyz;
                tmp6.yzw = tmp8.www ? tmp6.yzw : _Color3.xyz;
                tmp6.yzw = tmp8.yyy ? tmp7.xyw : tmp6.yzw;
                tmp2.xyz = tmp8.xxx ? tmp2.xyz : tmp6.yzw;
                tmp2.xyz = tmp1.www ? tmp2.xyz : _Color.xyz;
                tmp0.w = 1.0 - _ShoreIntens;
                tmp0.w = tmp8.z * tmp0.w + _ShoreIntens;
                tmp0.w = tmp0.w - 1.0;
                tmp2.xyz = tmp0.www + tmp2.xyz;
                tmp6.yzw = float3(0.7, 0.7, 0.7) - tmp2.xyz;
                tmp2.xyz = _Global_WhiteMode0.xxx * tmp6.yzw + tmp2.xyz;
                tmp0.w = -tmp5.w * 1.7 + 1.0;
                tmp0.w = max(tmp0.w, 0.0);
                tmp1.w = tmp0.w * tmp0.w;
                tmp0.w = tmp0.w * tmp1.w;
                tmp6.yzw = _FresnelColor.xyz - tmp2.xyz;
                tmp2.xyz = tmp0.www * tmp6.yzw + tmp2.xyz;
                tmp2.xyz = tmp0.xxx * _FoamColor.xyz + tmp2.xyz;
                tmp0.x = max(tmp4.w, 0.0);
                tmp0.x = min(tmp0.x, 0.7);
                tmp0.w = tmp2.w <= 1.0;
                if (tmp0.w) {
                    tmp8 = tmp2.wwww + float4(-0.2, -0.1, 0.1, 0.3);
                    tmp8 = saturate(tmp8 * float4(5.0, 10.0, 5.0, 5.0));
                    tmp6.yzw = float3(1.0, 1.0, 1.0) - _Global_SunsetColor0.xyz;
                    tmp6.yzw = tmp8.xxx * tmp6.yzw + _Global_SunsetColor0.xyz;
                    tmp7.xyw = _Global_SunsetColor1.xyz * float3(1.25, 1.25, 1.25);
                    tmp9.xyz = -_Global_SunsetColor1.xyz * float3(1.25, 1.25, 1.25) + _Global_SunsetColor0.xyz;
                    tmp7.xyw = tmp8.yyy * tmp9.xyz + tmp7.xyw;
                    tmp9.xyz = tmp2.www > float3(0.2, 0.1, -0.1);
                    tmp10.xyz = _Global_SunsetColor2.xyz * float3(1.5, 1.5, 1.5);
                    tmp11.xyz = _Global_SunsetColor1.xyz * float3(1.25, 1.25, 1.25) + -tmp10.xyz;
                    tmp8.xyz = tmp8.zzz * tmp11.xyz + tmp10.xyz;
                    tmp10.xyz = tmp8.www * tmp10.xyz;
                    tmp8.xyz = tmp9.zzz ? tmp8.xyz : tmp10.xyz;
                    tmp7.xyw = tmp9.yyy ? tmp7.xyw : tmp8.xyz;
                    tmp6.yzw = tmp9.xxx ? tmp6.yzw : tmp7.xyw;
                } else {
                    tmp6.yzw = float3(1.0, 1.0, 1.0);
                }
                tmp7.xyw = float3(1.0, 1.0, 1.0) - tmp6.yzw;
                tmp6.yzw = tmp7.xyw * float3(0.7, 0.7, 0.7) + tmp6.yzw;
                tmp0.w = tmp2.w > 0.0;
                tmp1.w = tmp2.w * 4.0;
                tmp1.w = saturate(tmp1.w);
                tmp7.xyw = _Global_WaterAmbientColor0.xyz - _Global_WaterAmbientColor1.xyz;
                tmp7.xyw = tmp1.www * tmp7.xyw + _Global_WaterAmbientColor1.xyz;
                tmp8.xy = saturate(tmp2.ww * float2(4.0, 0.7) + float2(1.0, 0.5));
                tmp9.xyz = _Global_WaterAmbientColor1.xyz - _Global_WaterAmbientColor2.xyz;
                tmp8.xzw = tmp8.xxx * tmp9.xyz + _Global_WaterAmbientColor2.xyz;
                tmp7.xyw = tmp0.www ? tmp7.xyw : tmp8.xzw;
                tmp8.x = tmp4.w * 1.5;
                tmp8.zw = tmp4.ww * float2(3.0, 0.35) + float2(0.7, 1.0);
                tmp0.w = tmp8.w * tmp8.w;
                tmp0.w = tmp8.w * tmp0.w;
                tmp7.xyw = tmp0.www * tmp7.xyw;
                tmp6.yzw = tmp0.xxx * tmp6.yzw + tmp7.xyw;
                tmp5.xyz = -tmp5.xyz * tmp3.xxx + _Global_SunDir.xyz;
                tmp0.x = dot(tmp5.xyz, tmp5.xyz);
                tmp0.x = rsqrt(tmp0.x);
                tmp5.xyz = tmp0.xxx * tmp5.xyz;
                tmp0.x = saturate(dot(tmp4.xyz, tmp5.xyz));
                tmp8.xz = saturate(tmp8.xz);
                tmp0.x = tmp0.x * tmp8.z;
                tmp4.xyz = _SpeclColor.xyz - _SpeclColor1.xyz;
                tmp4.xyz = tmp8.xxx * tmp4.xyz + _SpeclColor1.xyz;
                tmp0.w = 1.3 - tmp2.w;
                tmp1.w = tmp0.w * tmp0.w;
                tmp0.w = tmp0.w * tmp1.w;
                tmp0.w = max(tmp0.w, 0.0);
                tmp1.w = tmp5.w + tmp5.w;
                tmp1.w = min(tmp1.w, 1.0);
                tmp1.w = tmp1.w * tmp1.w;
                tmp1.w = tmp1.w * 98.0 + 2.0;
                tmp0.x = log(tmp0.x);
                tmp0.x = tmp0.x * tmp1.w;
                tmp0.x = exp(tmp0.x);
                tmp4.xyz = tmp4.xyz * tmp0.xxx;
                tmp4.xyz = tmp0.www * tmp4.xyz;
                tmp2.xyz = tmp2.xyz * tmp6.yzw + tmp4.xyz;
                tmp0.x = tmp8.y * tmp8.y;
                tmp0.x = tmp0.x * tmp8.y;
                tmp0.w = 1.0 - _GIGloss;
                tmp0.w = log(tmp0.w);
                tmp0.w = tmp0.w * 0.4;
                tmp0.w = exp(tmp0.w);
                tmp0.w = tmp0.w * 10.0;
                tmp3 = texCUBElod(_GITex, float4(tmp3.yzw, tmp0.w));
                tmp0.w = _GIStrengthDay - _GIStrengthNight;
                tmp0.x = tmp0.x * tmp0.w + _GIStrengthNight;
                tmp3 = tmp0.xxxx * tmp3;
                tmp0.x = dot(tmp3.xyz, float3(0.12, 0.24, 0.04));
                tmp3 = tmp3 * float4(0.4, 0.4, 0.4, 0.4) + -tmp0.xxxx;
                tmp3 = _GISaturate.xxxx * tmp3 + tmp0.xxxx;
                tmp6.x = saturate(tmp6.x);
                tmp2.xyz = tmp2.xyz - tmp1.xyz;
                tmp1.xyz = tmp0.zzz * tmp2.xyz + tmp1.xyz;
                tmp0 = tmp0.yyyy * _CausticsColor;
                tmp2.x = saturate(tmp4.w * 2.0 + 0.2);
                tmp1.w = 1.0;
                tmp0 = tmp0 * tmp2.xxxx + tmp1;
                tmp0 = tmp3 * tmp6.xxxx + tmp0;
                tmp1.x = dot(tmp0.xyz, float3(0.3, 0.6, 0.1));
                tmp1.xyz = tmp1.xxx * float3(0.75, 0.75, 0.75) + -tmp0.xyz;
                tmp0.xyz = _Global_WhiteMode0.xxx * tmp1.xyz + tmp0.xyz;
                o.sv_target = tmp7.zzzz * _Color1 + tmp0;
                return o;
            }
            ENDCG
        }
    }
}