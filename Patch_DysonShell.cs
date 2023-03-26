using HarmonyLib;
using System;
using UnityEngine;

namespace SphereOpt;

internal class Patch_DysonShell
{
    [HarmonyPatch(typeof(DysonShell), "SetProtoId")]
    [HarmonyPostfix]
    static void DysonShell_SetProtoId(DysonShell __instance)
    {
        var arraySizeNeeded = __instance.polygon.Count * 3;
        if (arraySizeNeeded > 256) CustomShaderManager.ApplyCustomShaderToMaterial(__instance.material, "dysonshell-max");
        else if (arraySizeNeeded > 128) CustomShaderManager.ApplyCustomShaderToMaterial(__instance.material, "dysonshell-huge");
        else if (arraySizeNeeded > 16) CustomShaderManager.ApplyCustomShaderToMaterial(__instance.material, "dysonshell-large");
        else CustomShaderManager.ApplyCustomShaderToMaterial(__instance.material, "dysonshell-small");
    }

    [HarmonyPatch(typeof(DysonShell), "GenerateModelObjects")]
    [HarmonyPostfix]
    static void DysonShell_GenerateModelObjects(DysonShell __instance)
    {
        var verts = __instance.verts;
        var mesh = __instance.mesh;
        var newMesh = new Mesh();
        var newVerts = new Vector3[verts.Length * 7];
        var newUVs = new Vector2[verts.Length * 7];
        var newUV2s = new Vector2[verts.Length * 7];
        var newUV3s = new Vector2[verts.Length * 7];
        var newUV4s = new Vector2[verts.Length * 7];
        var newTris = new int[verts.Length * 18];

        //var cellSize = 0.94f; //TODO: other shell protos besides the default are 1.0f
        var gridSize = __instance.gridSize; //80 * gridScale

        for (var i = 0; i < verts.Length; i++) {
            var baseVertIndex = i * 7;
            newVerts[baseVertIndex + 0] = Vector3.Normalize(verts[i]) * (float)__instance.radius;
	        newVerts[baseVertIndex + 1] = Vector3.Normalize(verts[i] + (Vector3)__instance.t0axis) * (float)__instance.radius;
            newVerts[baseVertIndex + 2] = Vector3.Normalize(verts[i] - (Vector3)__instance.t0axis) * (float)__instance.radius;
            newVerts[baseVertIndex + 3] = Vector3.Normalize(verts[i] + (Vector3)__instance.t1axis) * (float)__instance.radius;
            newVerts[baseVertIndex + 4] = Vector3.Normalize(verts[i] - (Vector3)__instance.t1axis) * (float)__instance.radius;
            newVerts[baseVertIndex + 5] = Vector3.Normalize(verts[i] + (Vector3)__instance.t2axis) * (float)__instance.radius;
            newVerts[baseVertIndex + 6] = Vector3.Normalize(verts[i] - (Vector3)__instance.t2axis) * (float)__instance.radius;

            newUVs[baseVertIndex+0] = mesh.uv[i];
            newUVs[baseVertIndex+1] = mesh.uv[i];
            newUVs[baseVertIndex+2] = mesh.uv[i];
            newUVs[baseVertIndex+3] = mesh.uv[i];
            newUVs[baseVertIndex+4] = mesh.uv[i];
            newUVs[baseVertIndex+5] = mesh.uv[i];
            newUVs[baseVertIndex+6] = mesh.uv[i];

            newUV2s[baseVertIndex+0] = mesh.uv2[i];
            newUV2s[baseVertIndex+1] = mesh.uv2[i];
            newUV2s[baseVertIndex+2] = mesh.uv2[i];
            newUV2s[baseVertIndex+3] = mesh.uv2[i];
            newUV2s[baseVertIndex+4] = mesh.uv2[i];
            newUV2s[baseVertIndex+5] = mesh.uv2[i];
            newUV2s[baseVertIndex+6] = mesh.uv2[i];

            newUV3s[baseVertIndex+0] = mesh.uv3[i];
            newUV3s[baseVertIndex+1] = mesh.uv3[i];
            newUV3s[baseVertIndex+2] = mesh.uv3[i];
            newUV3s[baseVertIndex+3] = mesh.uv3[i];
            newUV3s[baseVertIndex+4] = mesh.uv3[i];
            newUV3s[baseVertIndex+5] = mesh.uv3[i];
            newUV3s[baseVertIndex+6] = mesh.uv3[i];

            var hexUVOffset = __instance.gridScale / 3.0f;
            newUV4s[baseVertIndex+0] = new Vector2( 0,            0);
            newUV4s[baseVertIndex+1] = new Vector2( 0,            hexUVOffset);
            newUV4s[baseVertIndex+2] = new Vector2( 0,           -hexUVOffset);
            newUV4s[baseVertIndex+3] = new Vector2(-hexUVOffset,  0);
            newUV4s[baseVertIndex+4] = new Vector2( hexUVOffset,  0);
            newUV4s[baseVertIndex+5] = new Vector2( hexUVOffset,  hexUVOffset);
            newUV4s[baseVertIndex+6] = new Vector2(-hexUVOffset, -hexUVOffset);


            var baseTriIndex = i * 18;
            var triangles = new[] {
                    baseVertIndex+1, baseVertIndex+0, baseVertIndex+3,
                    baseVertIndex+3, baseVertIndex+0, baseVertIndex+6,
                    baseVertIndex+6, baseVertIndex+0, baseVertIndex+2,
                    baseVertIndex+2, baseVertIndex+0, baseVertIndex+4,
                    baseVertIndex+4, baseVertIndex+0, baseVertIndex+5,
                    baseVertIndex+5, baseVertIndex+0, baseVertIndex+1
            };
            Array.Copy(triangles, 0, newTris, baseTriIndex, 18);
        }

        newMesh.vertices = newVerts;
        newMesh.SetTriangles(newTris, 0, calculateBounds: false);
        newMesh.uv = newUVs;
        newMesh.uv2 = newUV2s;
        newMesh.uv3 = newUV3s;
        newMesh.uv4 = newUV4s;
        newMesh.RecalculateNormals();
        newMesh.RecalculateTangents();
        newMesh.bounds = new Bounds(Vector3.zero, new Vector3(50000000f, 50000000f, 50000000f));
        __instance.mesh = newMesh;
    }
}