Shader "VF Shaders/Dyson Sphere/Dyson Shell Unlit REPLACE Huge" {
  Properties {
    _Color ("Color", Vector) = (1,1,1,1)
    _MainTex ("Albedo (RGB)", 2D) = "white" {}
    _NormalTex ("Normal Map", 2D) = "bump" {}
    _MSTex ("Metallic Smoothness (RA)", 2D) = "white" {}
    _EmissionTex ("Emission (RGB)", 2D) = "black" {}
    _EmissionTex2 ("Emission Large (RGB)", 2D) = "black" {}
    _NoiseTex ("Noise Texture (R)", 2D) = "gray" {}
    _ColorControlTex ("Color Control", 2D) = "black" {}
    _ColorControlTex2 ("Color Control Large", 2D) = "black" {}
    _AlbedoMultiplier ("漫反射倍率", Float) = 1
    _NormalMultiplier ("法线倍率", Float) = 1
    _EmissionMultiplier ("自发光倍率", Float) = 5.5
    _CellSize ("细胞大小（是否有间隙）", Float) = 1
  }
  SubShader {
    Tags { "LIGHTMODE" = "FORWARDBASE" "QUEUE" = "Geometry" "RenderType" = "DysonShell" }
    Pass {
      Tags { "LIGHTMODE" = "FORWARDBASE" "QUEUE" = "Geometry" "RenderType" = "DysonShell" }
      Cull Off
      Stencil {
        CompFront Always
        PassFront Replace
        FailFront Keep
        ZFailFront Keep
      }
      GpuProgramID 41389
      CGPROGRAM
      #pragma vertex vert
      #pragma geometry geom
      #pragma fragment frag
      #include "UnityCG.cginc"
      #pragma target 5.0
      //#pragma enable_d3d11_debug_symbols

      struct v2g
      {
        float4 vertex : POSITION;
        float2 uv : TEXCOORD0;
          //x [0,3] node index
          //y [0,1] vert# / total#verts
        float2 uv2 : TEXCOORD1; //u1.x is unused?
          //x [0 or 1] (!s_outvmap.ContainsKey(item.Key)) ? 1 : 0)
          //y [0,2] polygon index - which edge it is closest to?
        float2 uv3 : TEXCOORD2; //axial coordinates on a grid of hexagons
      };

      struct g2f
      {
        float4 vertex : SV_POSITION;
        float4 vertPos_axialCoords : TEXCOORD0;
        float3 objectPos : TEXCOORD1;
        float3 worldPos : TEXCOORD2;
        float3 tangent : TEXCOORD3;
        float3 binormal : TEXCOORD4;
        float3 normal : TEXCOORD5;
        float4 screenPos : TEXCOORD6;
        float2 polyGroup_pctComplete : TEXCOORD7;
        float4 color : TEXCOORD8;
      };

      struct fout
      {
        float4 sv_target : SV_Target0;
      };

      float4 _SunColor;
      float4 _DysonEmission;
      float3 _Global_DS_SunPosition;
      float3 _Global_DS_SunPosition_Map;
      int _Global_IsMenuDemo;
      int _Global_DS_RenderPlace; // -1=Demo, 0=In-Game (Universe), 1=StarMap, or 2=DysonMap
      int _Global_DS_HideFarSide;
      int _Global_DS_PaintingLayerId;
      int _Global_DS_PaintingGridMode;
      float _Global_VMapEnabled; //(always 1f if gameData != null)
      float _CellSize; ////always 1 except dyson-shell-unlit-0 which is 0.94
      int _Color32Int;
      float _AlbedoMultiplier;
      float _NormalMultiplier;
      float _EmissionMultiplier;
      float _State; // bitfield for selection/tool state
      int _LayerId;
      float _Radius; //Radius of dyson sphere
      float _Scale; //(int)(Math.Pow(radius / 4000.0, 0.75) + 0.5); //4000 radius = 1.
      float _GridSize; //_Scale * 80
      float4 _Center; //Center of the shell that this point is a member of.
      // xaxis = normalize(cross(normalize(_Center), vector3.up))
      // yaxis = normalize(cross(xaxis, normalize(_Center)))
      // t0axis = yaxis * _GridSize * rsqrt(3);
      // t1axis = yaxis * _GridSize * rsqrt(3) * 0.5 - xaxis * _GridSize * 0.5;
      // t2axis = yaxis * _GridSize * rsqrt(3) * 0.5 + xaxis * _GridSize * 0.5;
      float3 _t0Axis; //in an axial coordinate system, the "q" axis. relative to center of shell.
      float3 _t1Axis; //in an axial coordinate system, the "r" axis. relative to center of shell.
      float3 _t2Axis; //in an axial coordinate system, the "s" axis. relative to center of shell.
      float _PolyCount; //number of nodes that make of the shape of this shell
      float _Clockwise;
      float _NodeProgressArr[256];
      float4 _PolygonArr[256]; // points that make up the shape of the polygon. repeated PolyCount times.
      float4 _PolygonNArr[256]; // normals
      sampler2D _NoiseTex;
      sampler2D _MainTex;
      sampler2D _NormalTex;
      sampler2D _MSTex;
      sampler2D _EmissionTex;
      sampler2D _EmissionTex2;
      sampler2D _ColorControlTex;
      sampler2D _ColorControlTex2;

      v2g vert(appdata_full v)
      {
        v2g o;

        o.vertex.xyzw = v.vertex.xyzw;
        o.uv.xy = v.texcoord.xy;
        o.uv2.xy = v.texcoord1.xy;
        o.uv3.xy = v.texcoord2.xy;

        return o;
      }

      [maxvertexcount(12)]
      void geom(point v2g input[1], inout TriangleStream<g2f> triStream)
      {
        g2f o;

        uint nodeIndex = (uint)input[0].uv.x;
        float vertFillOrder = input[0].uv.y; //sorted by which vert should appear first, if this is vert 3 of 8, vertFillOrder = (3/8) = 0.375.
        float pctNodeComplete = _NodeProgressArr[nodeIndex];
        float weighted_vertFillOrder = pow(vertFillOrder, 1.25); //fill early verts a little faster than later verts
        uint renderPlace = asuint(_Global_DS_RenderPlace);
        bool isDysonMap = renderPlace > 1.5;

        float hexPctComplete = saturate(pctNodeComplete + (_Scale/.28) * (pctNodeComplete - weighted_vertFillOrder));
        bool shouldRenderHex = hexPctComplete > 0.0001;

        if (isDysonMap || shouldRenderHex) { // Always render in DysonMap
          bool isDysonOrStarMap = renderPlace > 0.5;
          bool isInGame = renderPlace < 0.5;

          float triangleVertPos = (1.0 / 3.0) * _Scale;
          float3 normal =  normalize(mul((float3x3)unity_ObjectToWorld, input[0].vertex.xyz));

          float3 worldMidPtPos = mul(unity_ObjectToWorld, input[0].vertex.xyz);
          float scaleGridFactor = min(1.0, (min(1.0, 30.0 * saturate((length(worldMidPtPos) / (_GridSize * 18.0)) - 0.5)) * 0.07 + 1) - min(0.1, 0.2 / _Scale)) * saturate(length(worldMidPtPos) / (_GridSize * 1.5));

          float distFromCam = length(_WorldSpaceCameraPos.xyz - input[0].vertex.xyz);
          float cellSizeFalloff = 1.0 - saturate(distFromCam / 40000.0 - 0.075);

          float AngleCenterToPoint = dot(normalize(_Center.xyz), normalize(input[0].vertex.xyz));

          AngleCenterToPoint = isDysonMap ? AngleCenterToPoint : AngleCenterToPoint * scaleGridFactor;

          float centerToEdgeLength = AngleCenterToPoint * lerp(1.0, _CellSize, cellSizeFalloff);

          float3 t0_up_pos = normalize(input[0].vertex.xyz + _t0Axis.xyz * centerToEdgeLength) * _Radius;
          float3 t1_up_pos = normalize(input[0].vertex.xyz + _t1Axis.xyz * centerToEdgeLength) * _Radius;
          float3 t2_up_pos = normalize(input[0].vertex.xyz + _t2Axis.xyz * centerToEdgeLength) * _Radius;
          float3 t0_down_pos = normalize(input[0].vertex.xyz - _t0Axis.xyz * centerToEdgeLength) * _Radius;
          float3 t1_down_pos = normalize(input[0].vertex.xyz - _t1Axis.xyz * centerToEdgeLength) * _Radius;
          float3 t2_down_pos = normalize(input[0].vertex.xyz - _t2Axis.xyz * centerToEdgeLength) * _Radius;
          float3 midPtPos = input[0].vertex.xyz;

          if (isDysonOrStarMap) { // not demoscene and not ingame, so starmap and dysonmap
            t0_up_pos.xyz = t0_up_pos.xyz / 4000.0;
            t1_up_pos.xyz = t1_up_pos.xyz / 4000.0;
            t2_up_pos.xyz = t2_up_pos.xyz / 4000.0;
            t0_down_pos.xyz = t0_down_pos.xyz / 4000.0;
            t1_down_pos.xyz = t1_down_pos.xyz / 4000.0;
            t2_down_pos.xyz = t2_down_pos.xyz / 4000.0;
            midPtPos.xyz = midPtPos.xyz / 4000.0;
          }

          float3 worldTangent  = normalize(mul(unity_ObjectToWorld, t1_down_pos.xyz - t1_up_pos.xyz));
          float3 worldBinormal = normalize(mul(unity_ObjectToWorld, t0_up_pos.xyz - t0_down_pos.xyz));

          //unpack and convert gamma to linear color
          float4 gamma_color = float4(asuint(_Color32Int) & 255, (asuint(_Color32Int) >> 8) & 255, (asuint(_Color32Int) >> 16) & 255, (asuint(_Color32Int) >> 24) & 255) * (1.0f / 255); //asuint(_Color32Int)?
          float4 linear_color = pow((gamma_color.xyzw + 0.055F)/1.055F, 2.4F); //GammaToLinearSpaceExact

          float4 worldPos = mul(unity_ObjectToWorld, float4(t0_up_pos.xyz, 1.0));
          float3 ray = worldPos.xyz - _WorldSpaceCameraPos.xyz;
          float3 adjustedRay = ray.xyz * ((10000 * (log(length(ray.xyz) / 10000.0) + 1)) / length(ray.xyz));
          ray.xyz = length(ray.xyz) > 10000 ? adjustedRay.xyz : ray.xyz;
          worldPos.xyzw = _Global_VMapEnabled >= 1 ? float4(_WorldSpaceCameraPos.xyz + ray.xyz, 1.0) : worldPos.xyzw;

          float3 objPos = mul(unity_WorldToObject, worldPos.xyzw);
          float3 t0up_final_worldpos = isInGame ? worldPos.xyz : objPos.xyz;
          float3 final_objpos = isInGame ? objPos.xyz : t0_up_pos.xyz;

          float4 t0up_clipPos = mul(unity_MatrixVP, mul(unity_ObjectToWorld, float4(final_objpos, 1.0)));
          float4 t0up_screenPos = ComputeScreenPos(t0up_clipPos);

          o.vertex.xyzw = t0up_clipPos.xyzw;
          o.vertPos_axialCoords.xy = float2(0, triangleVertPos);
          o.vertPos_axialCoords.zw = input[0].uv3.xy;
          o.objectPos.xyz = t0_up_pos.xyz;
          o.worldPos.xyz = t0up_final_worldpos.xyz;
          o.tangent.xyz = worldTangent.xyz;
          o.binormal.xyz = worldBinormal.xyz;
          o.normal.xyz = normal;
          o.screenPos = t0up_screenPos;
          o.polyGroup_pctComplete.x = input[0].uv2.y;
          o.polyGroup_pctComplete.y = hexPctComplete;
          o.color.xyzw = linear_color.xyzw;
          triStream.Append(o);



          //midPtPos
          worldPos.xyzw = mul(unity_ObjectToWorld, float4(midPtPos.xyz, 1.0));
          ray.xyz = worldPos.xyz - _WorldSpaceCameraPos.xyz;
          adjustedRay.xyz = ray.xyz * ((10000 * (log(length(ray.xyz) / 10000.0) + 1)) / length(ray.xyz));
          ray.xyz = length(ray.xyz) > 10000 ? adjustedRay.xyz : ray.xyz;
          worldPos.xyzw = _Global_VMapEnabled >= 1 ? float4(_WorldSpaceCameraPos.xyz + ray.xyz, 1.0) : worldPos.xyzw;

          objPos.xyz = mul(unity_WorldToObject, worldPos.xyzw);
          float3 center_final_worldpos = isInGame ? worldPos.xyz : objPos.xyz;
          final_objpos = isInGame ? objPos.xyz : midPtPos.xyz;

          float4 center_clipPos = mul(unity_MatrixVP, mul(unity_ObjectToWorld, float4(final_objpos, 1.0)));
          float4 center_screenPos = ComputeScreenPos(center_clipPos);

          o.vertex.xyzw = center_clipPos.xyzw;
          o.vertPos_axialCoords.xy = float2(0, 0);
          o.vertPos_axialCoords.zw = input[0].uv3.xy;
          o.objectPos.xyz = midPtPos.xyz;
          o.worldPos.xyz = center_final_worldpos.xyz;
          o.tangent.xyz = worldTangent.xyz;
          o.binormal.xyz = worldBinormal.xyz;
          o.normal.xyz = normal.xyz;
          o.screenPos = center_screenPos;
          o.polyGroup_pctComplete.x = input[0].uv2.y;
          o.polyGroup_pctComplete.y = hexPctComplete;
          o.color.xyzw = linear_color.xyzw;
          triStream.Append(o);


          

          //t1_up_pos
          worldPos.xyzw = mul(unity_ObjectToWorld, float4(t1_up_pos.xyz, 1.0));
          ray.xyz = worldPos.xyz - _WorldSpaceCameraPos.xyz;
          adjustedRay.xyz = ray.xyz * ((10000 * (log(length(ray.xyz) / 10000.0) + 1)) / length(ray.xyz));
          ray.xyz = length(ray.xyz) > 10000 ? adjustedRay.xyz : ray.xyz;
          worldPos.xyzw = _Global_VMapEnabled >= 1 ? float4(_WorldSpaceCameraPos.xyz + ray.xyz, 1.0) : worldPos.xyzw;

          objPos.xyz = mul(unity_WorldToObject, worldPos.xyzw);
          float3 final_worldpos = isInGame ? worldPos.xyz : objPos.xyz;
          final_objpos = isInGame ? objPos.xyz : t1_up_pos.xyz;

          float4 clipPos = mul(unity_MatrixVP, mul(unity_ObjectToWorld, float4(final_objpos, 1.0)));
          float4 screenPos = ComputeScreenPos(clipPos);

          o.vertex.xyzw = clipPos.xyzw;
          o.vertPos_axialCoords.xy = float2(-triangleVertPos, 0);
          o.vertPos_axialCoords.zw = input[0].uv3.xy;
          o.objectPos.xyz = t1_up_pos.xyz;
          o.worldPos.xyz = final_worldpos.xyz;
          o.tangent.xyz = worldTangent.xyz;
          o.binormal.xyz = worldBinormal.xyz;
          o.normal.xyz = normal.xyz;
          o.screenPos = screenPos;
          o.polyGroup_pctComplete.x = input[0].uv2.y;
          o.polyGroup_pctComplete.y = hexPctComplete;
          o.color.xyzw = linear_color.xyzw;

          triStream.Append(o);

          // t2_down_pos
          worldPos.xyzw = mul(unity_ObjectToWorld, float4(t2_down_pos.xyz, 1.0));
          ray.xyz = worldPos.xyz - _WorldSpaceCameraPos.xyz;
          adjustedRay.xyz = ray.xyz * ((10000 * (log(length(ray.xyz) / 10000.0) + 1)) / length(ray.xyz));
          ray.xyz = length(ray.xyz) > 10000 ? adjustedRay.xyz : ray.xyz;
          worldPos.xyzw = _Global_VMapEnabled >= 1 ? float4(_WorldSpaceCameraPos.xyz + ray.xyz, 1.0) : worldPos.xyzw;

          objPos.xyz = mul(unity_WorldToObject, worldPos.xyzw);
          final_worldpos = isInGame ? worldPos.xyz : objPos.xyz;
          final_objpos = isInGame ? objPos.xyz : t2_down_pos.xyz;

          clipPos.xyzw = mul(unity_MatrixVP, mul(unity_ObjectToWorld, float4(final_objpos, 1.0)));
          screenPos = ComputeScreenPos(clipPos);

          o.vertex.xyzw = clipPos.xyzw;
          o.vertPos_axialCoords.xy = float2(-triangleVertPos, -triangleVertPos);
          o.vertPos_axialCoords.zw = input[0].uv3.xy;
          o.objectPos.xyz = t2_down_pos.xyz;
          o.worldPos.xyz = final_worldpos.xyz;
          o.tangent.xyz = worldTangent.xyz;
          o.binormal.xyz = worldBinormal.xyz;
          o.normal.xyz = normal.xyz;
          o.screenPos = screenPos;
          o.polyGroup_pctComplete.x = input[0].uv2.y;
          o.polyGroup_pctComplete.y = hexPctComplete;
          o.color.xyzw = linear_color.xyzw;
          triStream.Append(o);

          triStream.RestartStrip();

          //t2_down_pos
          o.vertex.xyzw = clipPos.xyzw;
          o.vertPos_axialCoords.xy = float2(-triangleVertPos, -triangleVertPos);
          o.vertPos_axialCoords.zw = input[0].uv3.xy;
          o.objectPos.xyz = t2_down_pos.xyz;
          o.worldPos.xyz = final_worldpos.xyz;
          o.tangent.xyz = worldTangent.xyz;
          o.binormal.xyz = worldBinormal.xyz;
          o.normal.xyz = normal.xyz;
          o.screenPos = screenPos;
          o.polyGroup_pctComplete.x = input[0].uv2.y;
          o.polyGroup_pctComplete.y = hexPctComplete;
          o.color.xyzw = linear_color.xyzw;
          triStream.Append(o);

          //midPtPos
          o.vertex.xyzw = center_clipPos.xyzw;
          o.vertPos_axialCoords.xy = float2(0, 0);
          o.vertPos_axialCoords.zw = input[0].uv3.xy;
          o.objectPos.xyz = midPtPos.xyz;
          o.worldPos.xyz = center_final_worldpos.xyz;
          o.tangent.xyz = worldTangent.xyz;
          o.binormal.xyz = worldBinormal.xyz;
          o.normal.xyz = normal.xyz;
          o.screenPos = center_screenPos;
          o.polyGroup_pctComplete.x = input[0].uv2.y;
          o.polyGroup_pctComplete.y = hexPctComplete;
          o.color.xyzw = linear_color.xyzw;
          triStream.Append(o);

          //t0_down_pos
          worldPos.xyzw = mul(unity_ObjectToWorld, float4(t0_down_pos.xyz, 1.0));
          ray.xyz = worldPos.xyz - _WorldSpaceCameraPos.xyz;
          adjustedRay.xyz = ray.xyz * ((10000 * (log(length(ray.xyz) / 10000.0) + 1)) / length(ray.xyz));
          ray.xyz = length(ray.xyz) > 10000 ? adjustedRay.xyz : ray.xyz;
          worldPos.xyzw = _Global_VMapEnabled >= 1 ? float4(_WorldSpaceCameraPos.xyz + ray.xyz, 1.0) : worldPos.xyzw;

          objPos.xyz = mul(unity_WorldToObject, worldPos.xyzw);
          final_worldpos = isInGame ? worldPos.xyz : objPos.xyz;
          final_objpos = isInGame ? objPos.xyz : t0_down_pos.xyz;

          clipPos.xyzw = mul(unity_MatrixVP, mul(unity_ObjectToWorld, float4(final_objpos, 1.0)));
          screenPos = ComputeScreenPos(clipPos);

          o.vertex.xyzw = clipPos.xyzw;
          o.vertPos_axialCoords.xy = float2(0, -triangleVertPos);
          o.vertPos_axialCoords.zw = input[0].uv3.xy;
          o.objectPos.xyz = t0_down_pos.xyz;
          o.worldPos.xyz = final_worldpos.xyz;
          o.tangent.xyz = worldTangent.xyz;
          o.binormal.xyz = worldBinormal.xyz;
          o.normal.xyz = normal.xyz;
          o.screenPos = screenPos;
          o.polyGroup_pctComplete.x = input[0].uv2.y;
          o.polyGroup_pctComplete.y = hexPctComplete;
          o.color.xyzw = linear_color.xyzw;
          triStream.Append(o);

          //t1_down_pos
          worldPos.xyzw = mul(unity_ObjectToWorld, float4(t1_down_pos.xyz, 1.0));
          ray.xyz = worldPos.xyz - _WorldSpaceCameraPos.xyz;
          adjustedRay.xyz = ray.xyz * ((10000 * (log(length(ray.xyz) / 10000.0) + 1)) / length(ray.xyz));
          ray.xyz = length(ray.xyz) > 10000 ? adjustedRay.xyz : ray.xyz;
          worldPos.xyzw = _Global_VMapEnabled >= 1 ? float4(_WorldSpaceCameraPos.xyz + ray.xyz, 1.0) : worldPos.xyzw;

          objPos.xyz = mul(unity_WorldToObject, worldPos.xyzw);
          final_worldpos = isInGame ? worldPos.xyz : objPos.xyz;
          final_objpos = isInGame ? objPos.xyz : t1_down_pos.xyz;

          clipPos.xyzw = mul(unity_MatrixVP, mul(unity_ObjectToWorld, float4(final_objpos, 1.0)));
          screenPos = ComputeScreenPos(clipPos);

          o.vertex.xyzw = clipPos.xyzw;
          o.vertPos_axialCoords.xy = float2(triangleVertPos, 0);
          o.vertPos_axialCoords.zw = input[0].uv3.xy;
          o.objectPos.xyz = t1_down_pos.xyz;
          o.worldPos.xyz = final_worldpos.xyz;
          o.tangent.xyz = worldTangent.xyz;
          o.binormal.xyz = worldBinormal.xyz;
          o.normal.xyz = normal.xyz;
          o.screenPos = screenPos;
          o.polyGroup_pctComplete.x = input[0].uv2.y;
          o.polyGroup_pctComplete.y = hexPctComplete;
          o.color.xyzw = linear_color.xyzw;
          triStream.Append(o);

          triStream.RestartStrip(); 

          //t1_down_pos
          o.vertex.xyzw = clipPos.xyzw;
          o.vertPos_axialCoords.xy = float2(triangleVertPos, 0);
          o.vertPos_axialCoords.zw = input[0].uv3.xy;
          o.objectPos.xyz = t1_down_pos.xyz;
          o.worldPos.xyz = final_worldpos.xyz;
          o.tangent.xyz = worldTangent.xyz;
          o.binormal.xyz = worldBinormal.xyz;
          o.normal.xyz = normal.xyz;
          o.screenPos = screenPos;
          o.polyGroup_pctComplete.x = input[0].uv2.y;
          o.polyGroup_pctComplete.y = hexPctComplete;
          o.color.xyzw = linear_color.xyzw;
          triStream.Append(o);

          //midPtPos
          o.vertex.xyzw = center_clipPos.xyzw;
          o.vertPos_axialCoords.xy = float2(0, 0);
          o.vertPos_axialCoords.zw = input[0].uv3.xy;
          o.objectPos.xyz = midPtPos.xyz;
          o.worldPos.xyz = center_final_worldpos.xyz;
          o.tangent.xyz = worldTangent.xyz;
          o.binormal.xyz = worldBinormal.xyz;
          o.normal.xyz = normal.xyz;
          o.screenPos = center_screenPos;
          o.polyGroup_pctComplete.x = input[0].uv2.y;
          o.polyGroup_pctComplete.y = hexPctComplete;
          o.color.xyzw = linear_color.xyzw;
          triStream.Append(o);

          worldPos.xyzw = mul(unity_ObjectToWorld, float4(t2_up_pos.xyz, 1.0));
          ray.xyz = worldPos.xyz - _WorldSpaceCameraPos.xyz;
          adjustedRay.xyz = ray.xyz * ((10000 * (log(length(ray.xyz) / 10000.0) + 1)) / length(ray.xyz));
          ray.xyz = length(ray.xyz) > 10000 ? adjustedRay.xyz : ray.xyz;
          worldPos.xyzw = _Global_VMapEnabled >= 1 ? float4(_WorldSpaceCameraPos.xyz + ray.xyz, 1.0) : worldPos.xyzw;

          objPos.xyz = mul(unity_WorldToObject, worldPos.xyzw);
          final_worldpos = isInGame ? worldPos.xyz : objPos.xyz;
          final_objpos = isInGame ? objPos.xyz : t2_up_pos.xyz;

          clipPos.xyzw = mul(unity_MatrixVP, mul(unity_ObjectToWorld, float4(final_objpos, 1.0)));
          screenPos = ComputeScreenPos(clipPos);

          //t2_up_pos
          o.vertex.xyzw = clipPos.xyzw;
          o.vertPos_axialCoords.xy = float2(triangleVertPos, triangleVertPos);
          o.vertPos_axialCoords.zw = input[0].uv3.xy;
          o.objectPos.xyz = t2_up_pos.xyz;
          o.worldPos.xyz = final_worldpos.xyz;
          o.tangent.xyz = worldTangent.xyz;
          o.binormal.xyz = worldBinormal.xyz;
          o.normal.xyz = normal.xyz;
          o.screenPos = screenPos;
          o.polyGroup_pctComplete.x = input[0].uv2.y;
          o.polyGroup_pctComplete.y = hexPctComplete;
          o.color.xyzw = linear_color.xyzw;
          triStream.Append(o);

          //t0_up_pos
          o.vertex.xyzw = t0up_clipPos.xyzw;
          o.vertPos_axialCoords.xy = float2(0, triangleVertPos);
          o.vertPos_axialCoords.zw = input[0].uv3.xy;
          o.objectPos.xyz = t0_up_pos.xyz;
          o.worldPos.xyz = t0up_final_worldpos.xyz;
          o.tangent.xyz = worldTangent.xyz;
          o.binormal.xyz = worldBinormal.xyz;
          o.normal.xyz = normal.xyz;
          o.screenPos = t0up_screenPos;
          o.polyGroup_pctComplete.x = input[0].uv2.y;
          o.polyGroup_pctComplete.y = hexPctComplete;
          o.color.xyzw = linear_color.xyzw;
          triStream.Append(o);

        }
        return;
      }

      fout frag(g2f i)
      {

        fout o;
        const float4 icb[16] = {
          float4(16.0, 0.0, 0.0, 0.0),
          float4(8.0, 0.0, 0.0, 0.0),
          float4(14.0, 0.0, 0.0, 0.0),
          float4(6.0, 0.0, 0.0, 0.0),
          float4(4.0, 0.0, 0.0, 0.0),
          float4(12.0, 0.0, 0.0, 0.0),
          float4(2.0, 0.0, 0.0, 0.0),
          float4(10.0, 0.0, 0.0, 0.0),
          float4(13.0, 0.0, 0.0, 0.0),
          float4(5.0, 0.0, 0.0, 0.0),
          float4(15.0, 0.0, 0.0, 0.0),
          float4(7.0, 0.0, 0.0, 0.0),
          float4(1.0, 0.0, 0.0, 0.0),
          float4(9.0, 0.0, 0.0, 0.0),
          float4(3.0, 0.0, 0.0, 0.0),
          float4(11.0, 0.0, 0.0, 0.0)
        };

        float2 triangleVertPos = i.vertPos_axialCoords.xy;
        float2 axialCoords = i.vertPos_axialCoords.zw;
        int polygonGroup = (int)((uint)(0.5 + i.polyGroup_pctComplete.x));
        float hexPctComplete = i.polyGroup_pctComplete.y;

        uint renderPlace = asuint(_Global_DS_RenderPlace);

        bool isDysonMap = renderPlace > 1.5;
        bool isDysonOrStarMap = renderPlace > 0.5;
        bool isInGame = renderPlace < 0.5;
        bool isMenuDemo = 0.5 < asuint(_Global_IsMenuDemo);

        if ((int)(asint(_Global_DS_PaintingLayerId) != asint(_LayerId)) | (int)(asuint(_Global_DS_PaintingGridMode) > 0.5) ? asuint(_Global_DS_PaintingLayerId) > 0 ? isDysonMap : 0 : 0 != 0) discard;

        float3 rayPosToCamera = _WorldSpaceCameraPos.xyz - i.worldPos.xyz;

        //if a ray from the the vert to the camera and a ray from the vert to the sun are pointing in the same direction, must be far side.
        bool isFarSide = dot(rayPosToCamera, _Global_DS_SunPosition_Map.xyz - i.worldPos.xyz) > 0;
        bool hideFarSideEnabled = asuint(_Global_DS_HideFarSide) > 0.5;
        if (isDysonMap && hideFarSideEnabled && isFarSide) discard;

        /* remove pixels that fall outside the bounds of the frame that surrounds this shell */
        uint polyCount = (uint)(0.5 + _PolyCount) < 1 ? 1 : min(380, (uint)(0.5 + _PolyCount));
        int polygonIndex = (int)polyCount + (int)(0.5 + polygonGroup);

        float3 prevLineNormal = _PolygonNArr[polygonIndex - 1].xyz;
        float3 prevLineToPoint = i.objectPos.xyz - _PolygonArr[polygonIndex - 1].xyz;

        float3 thisLineDir = _PolygonArr[polygonIndex + 1].xyz - _PolygonArr[polygonIndex].xyz;
        float3 thisLineNormal = _PolygonNArr[polygonIndex].xyz;

        float3 nextLineDir = _PolygonArr[polygonIndex + 2].xyz - _PolygonArr[polygonIndex + 1].xyz;
        float3 nextLineNormal = _PolygonNArr[polygonIndex + 1].xyz;
        float3 nextLineToPoint = i.objectPos.xyz - _PolygonArr[polygonIndex + 1].xyz;

        float3 nextnextLineToPoint = i.objectPos.xyz - _PolygonArr[polygonIndex + 2].xyz;


        float prevLineIsConcave = dot(thisLineDir, prevLineNormal);
        float nextLineIsConcave = dot(nextLineDir, thisLineNormal);
        // <0 means convex
        // >0 means concave
        // 0 means parallel
        int prevLineIsConvex = prevLineIsConcave > 0 ? 1 : prevLineIsConcave < 0 ? -1 : 0;
        int nextLineIsConvex = nextLineIsConcave > 0 ? 1 : nextLineIsConcave < 0 ? -1 : 0;
        //set to int, flip sign. 1=convex, -1=concave

        float prevLineInside = dot(prevLineToPoint, prevLineNormal);
        float thisLineInside = dot(nextLineToPoint, thisLineNormal);
        float nextLineInside = dot(nextnextLineToPoint, nextLineNormal);
        // inside if >0, outside if <0

        prevLineIsConvex *= _Clockwise;
        nextLineIsConvex *= _Clockwise;
        prevLineInside *= _Clockwise;
        thisLineInside *= _Clockwise;
        nextLineInside *= _Clockwise;
        // flip sign if counterclockwise (_Clockwise = -1)

        float insideBounds = -1;
        if (nextLineIsConvex > 0 && prevLineIsConvex > 0) {
          if (nextLineInside > 0 && thisLineInside > 0 && prevLineInside > 0) {
            insideBounds = 1;
          } else {
            insideBounds = -1;
          }
        } else {
          if (nextLineIsConvex > 0 && prevLineIsConvex <= 0) {
            insideBounds = nextLineInside > 0 && (prevLineInside > 0 || thisLineInside > 0) ? 1 : -1;
          } else {
            if (nextLineIsConvex <= 0 && prevLineIsConvex > 0) {
              insideBounds = prevLineInside > 0 && (thisLineInside > 0 || nextLineInside > 0) ? 1 : -1;      
            } else {
              insideBounds = (nextLineInside > 0 || prevLineInside > 0 || thisLineInside > 0) ? 1 : -1;
            }
          }
        }
        if (insideBounds < 0) discard;
        /* end shell/frame bounds check */


        float distancePosToCamera = length(rayPosToCamera);
        
        float4 cubeCoords = _Scale * float4(0.666666687,0.333333343,-0.333333343,0.333333343) * axialCoords.xxyy;
        cubeCoords.xy = cubeCoords.yx + cubeCoords.wz;

        float gridFalloff = 0.99 - saturate((distancePosToCamera / _GridSize) / 15.0 - 0.2) * 0.03;

        float2 adjustPoint = triangleVertPos.yx * gridFalloff + cubeCoords.xy;
        adjustPoint.xy = adjustPoint.yx * float2(2,2) - adjustPoint.xy;
        float adjustPoint_z = -adjustPoint.x - adjustPoint.y;
        float2 roundedAdjustPoint = round(adjustPoint.xy);
        float roundedAdjustPoint_z = round(adjustPoint_z);
        float2 roundedPointDiff = -roundedAdjustPoint.yx - round(adjustPoint_z);
        adjustPoint.xy = roundedAdjustPoint.xy < adjustPoint.xy ? adjustPoint.xy - roundedAdjustPoint.xy : roundedAdjustPoint.xy - adjustPoint.xy;
        adjustPoint_z = roundedAdjustPoint_z < adjustPoint_z ? adjustPoint_z - roundedAdjustPoint_z : roundedAdjustPoint_z - adjustPoint_z;
        adjustPoint.xy = adjustPoint_z < adjustPoint.xy ? adjustPoint.yx < adjustPoint.xy : 0;

        float alternatePointY = adjustPoint.y ? roundedPointDiff.y : roundedAdjustPoint.y;
        float2 correctedCoords = roundedAdjustPoint.x + roundedAdjustPoint.y + roundedAdjustPoint_z != 0.000000 ? (adjustPoint.xx ? float2(roundedPointDiff.x, roundedAdjustPoint.y) : float2(roundedAdjustPoint.x, alternatePointY)) : roundedAdjustPoint.xy;

        float2 randomSampleCoords = float2(0.001953125,0.001953125) * correctedCoords.xy;
        float random_num = tex2Dlod(_NoiseTex, float4(randomSampleCoords.xy, 0, 0)).x;


        int bitmask;
        float cutOut = 0;
        if (hexPctComplete - random_num * 0.999 < 0.00005) {
          if (isDysonMap) {
            float2 pixelPos = (_ScreenParams.xy * (i.screenPos.xy / i.screenPos.ww));
            pixelPos = (int2)pixelPos;
            bitmask = ((~(-1 << 2)) << 2) & 0xffffffff; // 12
            cutOut = (((uint)pixelPos.x << 2) & bitmask) | ((uint)0 & ~bitmask);
            bitmask = ((~(-1 << 2)) << 0) & 0xffffffff; // 3
            cutOut = (((uint)pixelPos.y << 0) & bitmask) | ((uint)cutOut & ~bitmask);
            if (0.2499 - (icb[cutOut].x * 0.0588) < 0) discard;
            cutOut = 1;
          } else {
            if (-1 != 0) discard;
            cutOut = 0;
          }
        } else {
          cutOut = 0;
        }

        float2 triPosAdjusted;
        triPosAdjusted.x = triangleVertPos.x / _Scale + (2.0 * axialCoords.x - axialCoords.y) / 3.0;
        triPosAdjusted.y = triangleVertPos.y / _Scale +       (axialCoords.x + axialCoords.y) / 3.0;

        float lodBias = min(4, max(0, log(0.0001 * distancePosToCamera)));

        float4 albedoTex = tex2Dbias(_MainTex, float4(triangleVertPos.xy, 0, lodBias)).xyzw;

        float4 normalTex = tex2Dbias(_NormalTex, float4(triangleVertPos.xy, 0, lodBias)).xyzw;
        float3 unpackedNormal = UnpackNormal(normalTex);

        float2 msTex = tex2D(_MSTex, triangleVertPos.xy).xw;

        float3 emissionTex_A = tex2Dbias(_EmissionTex, float4(triangleVertPos.xy, 0, lodBias)).xyz;
        float3 emissionTex_B = tex2Dbias(_EmissionTex, float4(float2(1,1) - triangleVertPos.yx, 0, lodBias)).xyz;

        float3 emissionTex = lerp(emissionTex_A.xyz, emissionTex_B.xyz, sin(_Time.y + _Time.y) * 0.5 + 0.5);
        float3 emissionTexTwo = tex2Dbias(_EmissionTex2, float4(triPosAdjusted.xy, 0, lodBias)).xyz;

        float colorControlTex_A = tex2Dbias(_ColorControlTex, float4(triangleVertPos.xy, 0, lodBias)).x;
        float colorControlTex_B = tex2Dbias(_ColorControlTex, float4(float2(1,1) - triangleVertPos.yx, 0, lodBias)).x;
        float colorControlTex = lerp(colorControlTex_A, colorControlTex_B, sin(_Time.y + _Time.y) * 0.5 + 0.5);
        float colorControlTexTwo = tex2Dbias(_ColorControlTex2, float4(triPosAdjusted.xy, 0, lodBias)).x;

        unpackedNormal.xy = (-1.5 * _NormalMultiplier) * unpackedNormal.xy;
        float3 worldNormal = normalize(i.normal.xyz * unpackedNormal.z + i.tangent.xyz * unpackedNormal.x + i.binormal.xyz * unpackedNormal.y);

        float3 triPosNew;
        triPosNew.x = 1.0 - abs(frac(0.5 * (0.6666666 + triPosAdjusted.x)) * 2.0 - 1.0);
        triPosNew.y = 1.0 - abs(frac(0.5 * (0         + triPosAdjusted.y)) * 2.0 - 1.0);
        triPosNew.z = 1.0 - abs(frac(0.5 * (1.6666666 + triPosAdjusted.x)) * 2.0 - 1.0);

        float2 newPosOne;
        newPosOne.x = ((triPosNew.x + triPosNew.y) / sqrt(2)) / sqrt(3);
        newPosOne.y =  (triPosNew.y - triPosNew.x) / sqrt(2);

        float2 newPosTwo;
        newPosTwo.x = ((triPosNew.z + triPosNew.y) / sqrt(2)) / sqrt(3);
        newPosTwo.y =  (triPosNew.y - triPosNew.z) / sqrt(2);

        float3 viewDir = normalize(rayPosToCamera);
        bool viewingSunFacingSide = dot(i.normal.xyz, viewDir.xyz) < 0;

        float emissionAnim = saturate(30.0 * (0.05 - abs(length(newPosOne.xy) - frac(2.9 * _Time.x)))) * min(1, 5 * (1 - frac(2.9 * _Time.x)))
             + saturate(30.0 * (0.05 - abs(length(newPosTwo.xy) - frac(_Time.x * 3.7 + 0.5)))) * min(1, 5 * (1 - frac(_Time.x * 3.7 + 0.5)));
        emissionAnim = viewingSunFacingSide ? saturate((emissionTexTwo.y * 2 + emissionTex.y) * emissionAnim) : 0;

        float3 dysonEmission = viewingSunFacingSide ? _DysonEmission.xyz : float3(1,1,1);
        float colorControl = saturate(colorControlTex + colorControlTexTwo);
        float3 colorOutwardFacing = lerp(colorControl * i.color.xyz, i.color.xyz, 0.01 / _EmissionMultiplier);
        float3 emissionOutwardFacing = lerp(emissionTexTwo.xyz * float3(0.3, 0.3, 0.3) + emissionTex.xyz, colorOutwardFacing, i.color.w);
        float3 emissionSunFacing = float3(3,3,3) * (emissionTexTwo.x + emissionTex.x) * dysonEmission.xyz;
        float3 emission = viewingSunFacingSide ? emissionSunFacing.xyz : emissionOutwardFacing.xyz;

        emission = _EmissionMultiplier * lerp(emission.xyz, dysonEmission.xyz, emissionAnim);

        float3 albedo = _AlbedoMultiplier * albedoTex.xyz * lerp(float3(1,1,1), albedoTex.xyz, saturate(1.25 * (albedoTex.w - 0.1)));
        float specularStrength = dot(albedo, float3(0.3, 0.6, 0.1));

        float scaledDistancePosToCamera = isMenuDemo ? distancePosToCamera : isDysonOrStarMap ? 3999.9998 * distancePosToCamera : distancePosToCamera;
        float scaleMetallic = isMenuDemo ? 0.1 : isDysonOrStarMap ? 0.93 : 0.7;
        scaleMetallic = saturate(pow(0.25 * log(scaledDistancePosToCamera + 1) - 1.5, 3.0)) * scaleMetallic;
        float multiplyEmission = isDysonMap ? 2.2 : isDysonOrStarMap ? 1.8  : 2.5;

        float3 shellColor = i.color.w > 0.5 ? i.color.xyz : (asint(_Global_DS_PaintingLayerId) == asint(_LayerId) ? float3(0, 0.3, 0.65) : float3(0, 0.8, 0.6));
        float3 shellEmissionColor = lerp(emission.xyz * multiplyEmission, shellColor, 0.8 * cutOut);

        specularStrength       = _State > 0.5 ? 0   : 0.8 * specularStrength * (1.0 - cutOut);
        float fadeOut          = _State > 0.5 ? 0   : 0.03                   * (1.0 - cutOut);
        float metallic         = _State > 0.5 ? 0   : msTex.x                * (1.0 - scaleMetallic);
        float smoothness       = _State > 0.5 ? 0.5 : min(0.8, msTex.y);

        float3 defaultColor   = isDysonMap ? i.color.xyz * (viewingSunFacingSide ? 2 : 1.5) : float3(0,0,0);
        float3 highStateColor = i.color.w > 0.5 ? defaultColor : float3(2.59, 0.0525, 0.0875);
        float3 medStateColor  = i.color.w > 0.5 ? defaultColor : float3(0.525,0.875, 3.5);
        float3 lowStateColor  = i.color.w > 0.5 ? defaultColor : float3(0.35, 0.7, 3.5);
        float3 zeroStateColor = i.color.w > 0.5 ? defaultColor : float3(1.05, 1.05, 1.05);
        float3 finalColor = 3.5 < _State ? highStateColor :
                            2.5 < _State ? medStateColor  :
                            1.5 < _State ? lowStateColor  :
                            0.5 < _State ? zeroStateColor :
                            shellEmissionColor;
        
        float emissionFactor = (int)(_State > 0.5) | (int)(cutOut > 0.5) ? (1.0 / _EmissionMultiplier) : saturate(colorControlTex + colorControlTexTwo.x);
        float metallicFactor = saturate(metallic * 0.85 + 0.149);

        float perceptualRoughness = min(1, 1 - smoothness * 0.97);
        float roughness = perceptualRoughness * perceptualRoughness;
        float roughnessSqr = roughness * roughness;

        float NdotV = viewingSunFacingSide ? -dot(worldNormal.xyz, viewDir.xyz) : dot(worldNormal.xyz, viewDir.xyz);
        worldNormal.xyz = viewingSunFacingSide ? -worldNormal.xyz : worldNormal.xyz;

        float3 lightDir = -i.normal.xyz;
        float3 halfDir = normalize(normalize(rayPosToCamera) + lightDir.xyz);

        float NdotL = dot(worldNormal.xyz, lightDir.xyz);
        float NdotH = dot(worldNormal.xyz, halfDir.xyz);
        float VdotH = dot(viewDir, halfDir.xyz);
        float clamp_NdotL = max(0, NdotL);
        float clamp_NdotH = max(0, NdotH);
        float clamp_VdotH = max(0, VdotH);

        float D = 0.25 * pow(rcp(clamp_NdotH * clamp_NdotH * (roughnessSqr - 1) + 1),2) * roughnessSqr;

        float gv = lerp(pow(roughnessSqr + 1, 2) * 0.125, 1.0, NdotV);
        float gl = lerp(pow(roughnessSqr + 1, 2) * 0.125, 1.0, clamp_NdotL);
        float G = rcp(gv * gl);

        float fk = exp2((clamp_VdotH * -5.55472994 - 6.98316002) * clamp_VdotH);
        float F = lerp(0.5 + metallicFactor, 1.0, fk);

        float sunStrength = isInGame ? pow(saturate(1.05 + dot(normalize(_WorldSpaceCameraPos.xyz - _Global_DS_SunPosition.xyz), i.normal.xyz)), 0.4) : 1.0;
        float3 sunColor = float3(1.5625,1.5625,1.5625) * _SunColor.xyz;
        float intensity = saturate(pow(NdotL * 0.6 + 1, 3));
        float3 sunColorIntensity = float3(0.07, 0.07, 0.07) * _SunColor * (intensity * 1.5 + 1) * intensity;
        float3 sunSpecular = sunColor.xyz * clamp_NdotL * specularStrength;

        float3 finalLight = lerp(1, specularStrength, metallicFactor) * fadeOut * sunColor.xyz * (F * D * G + (0.1 / UNITY_PI)) * clamp_NdotL;
        finalLight = finalLight.xyz * lerp(metallicFactor, 1, specularStrength * 0.2);
        finalLight = float3(5,5,5) * lerp(float3(1,1,1), _SunColor, float3(0.3,0.3,0.3)) * finalLight.xyz;
        finalLight = (sunColorIntensity.xyz * specularStrength * (1 - metallicFactor * 0.6) + sunSpecular.xyz * pow(1 - metallicFactor, 0.6) + finalLight.xyz) * sunStrength;

        float finalStength = dot(finalLight, float3(0.3, 0.6, 0.1));
        float3 normalizedLight = finalLight / finalStength;
        float megaLog = log(log(log(log(log(log(log(log(finalStength / 0.32) + 1) + 1) + 1) + 1) + 1) + 1) + 1) + 1;
        finalLight = 0.32 < finalStength ? normalizedLight * megaLog * 0.32 : finalLight;

        float finalAlpha = _EmissionMultiplier * emissionFactor;
        o.sv_target.xyzw = float4(finalColor, 0.0) + float4(finalLight, finalAlpha);

        return o;
      }
      ENDCG
    }
  }
  Fallback "Diffuse"
}