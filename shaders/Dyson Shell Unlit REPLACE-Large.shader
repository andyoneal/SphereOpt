Shader "VF Shaders/Dyson Sphere/Dyson Shell Unlit REPLACE Large" {
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
      #pragma fragment frag
      #pragma target 5.0
      #pragma enable_d3d11_debug_symbols

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
      float _NodeProgressArr[128];
      float4 _PolygonArr[128]; // points that make up the shape of the polygon. repeated PolyCount times.
      float4 _PolygonNArr[128]; // normals
      sampler2D _NoiseTex;
      sampler2D _MainTex;
      sampler2D _NormalTex;
      sampler2D _MSTex;
      sampler2D _EmissionTex;
      sampler2D _EmissionTex2;
      sampler2D _ColorControlTex;
      sampler2D _ColorControlTex2;

      #include "CGIncludes/DysonShellUnlit.cginc"
      
      ENDCG
    }
  }
  Fallback "Diffuse"
}