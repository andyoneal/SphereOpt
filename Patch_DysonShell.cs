﻿using HarmonyLib;

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
    private static void DysonShell_GenerateModelObjects(DysonShell __instance)
    {
        var instDysonShellRenderer = SphereOpt.getInstDysonShellRendererForSphere(__instance.dysonSphere);
        var layerId = __instance.layerId;
        var instShellLayer = instDysonShellRenderer.getOrCreateInstShellLayer(layerId);
        var shellIndex = __instance.id;
        var verts = __instance.verts;
        var polygon = __instance.polygon;

        for (int i = 0; i < verts.Length; i++)
        {
            var hexPos = verts[i];
            var mesh = __instance.mesh;
            var hex = new InstDysonShellLayer.HexData
            {
                pos = hexPos,
                shellIndex = shellIndex,
                nodeIndex = (int)mesh.uv[i].x,
                vertFillOrder = mesh.uv[i].y,
                closestPolygon = __instance.clockwise ? (int)mesh.uv2[i].y : polygon.Count - (int)mesh.uv2[i].y - 1,
                axialCoords_xy =
                    (uint)((int)__instance.mesh.uv3[i].x & 0x0000ffff | (int)__instance.mesh.uv3[i].y << 16)
            };
            instShellLayer.hexPool.Add(hex);
        }

        instShellLayer.hexBufferIsDirty = true;
        int progressBaseIndex = instShellLayer.progressBaseCursor;
        instShellLayer.progressBaseCursor = progressBaseIndex + __instance.nodecps.Length - 1;

        int polygonIndex = instShellLayer.AddPolygonData(polygon, __instance.polyn, __instance.clockwise);
        var shellData = new InstDysonShellLayer.ShellData
        {
            color = (__instance.color.a << 24) | (__instance.color.b << 16) | (__instance.color.g << 8) | __instance.color.r,
            progressBaseIndex = progressBaseIndex,
            state = __instance.state,
            polygonIndex = polygonIndex,
            polyCount = polygon.Count,
            //clockwise = __instance.clockwise ? 1 : -1,
            center = __instance.center
        };
        instShellLayer.AddShellData(shellIndex, shellData);
        instShellLayer.shellBufferIsDirty = true;

        instShellLayer.radius = (float)__instance.radius;
        instShellLayer.gridScale = __instance.gridScale;
        instShellLayer.gridSize = __instance.gridSize;

        for (int i = 0; i < __instance.nodecps.Length - 1; i++)
        {
            var hexProgress = new InstDysonShellLayer.HexProgressData
            {
                progress = __instance.nodecps[i] / (float)((__instance.vertsqOffset[i + 1] - __instance.vertsqOffset[i]) * __instance.cpPerVertex)
            };
            instShellLayer.AddHexProgressData(progressBaseIndex + i, hexProgress);
        }
        instShellLayer.hexProgressBufferIsDirty = true;


    }

    [HarmonyPatch(typeof(DysonShell), "Construct")]
    [HarmonyPrefix]
    private static bool DysonShell_Construct(DysonShell __instance, int nodeIndex, bool fastBuild = false)
    {
        var instDysonShellRenderer = SphereOpt.getInstDysonShellRendererForSphere(__instance.dysonSphere);
        var instShellLayer = instDysonShellRenderer.getOrCreateInstShellLayer(__instance.layerId);

        var progress = __instance.nodecps[nodeIndex] / (float)((__instance.vertsqOffset[nodeIndex + 1] - __instance.vertsqOffset[nodeIndex]) * __instance.cpPerVertex);
        instShellLayer.UpdateHexProgress(__instance.id, nodeIndex, progress);
        return true;
    }

    [HarmonyPatch(typeof(DysonSphereLayer), "RemoveDysonShell")]
    [HarmonyPostfix]
    private static void DysonSphereLayer_RemoveDysonShell(DysonSphereLayer __instance, int shellId)
    {
        var instDysonShellRenderer = SphereOpt.getInstDysonShellRendererForSphere(__instance.dysonSphere);
        var instShellLayer = instDysonShellRenderer.getInstShellLayer(__instance.id);
        instShellLayer?.RemoveDysonShell(shellId);
    }

    [HarmonyPatch(typeof(DysonSphere), "UpdateStates",  typeof(DysonShell), typeof(uint), typeof(bool), typeof(bool))]
    [HarmonyPostfix]
    public static void DysonSphere_UpdateStates(DysonSphere __instance, DysonShell shell)
    {
        var instDysonShellRenderer = SphereOpt.getInstDysonShellRendererForSphere(__instance);
        var instShellLayer = instDysonShellRenderer.getInstShellLayer(shell.layerId);
        instShellLayer?.UpdateState(shell.id, shell.state);
    }

    [HarmonyPatch(typeof(DysonSphereSegmentRenderer), "Free")]
    [HarmonyPrefix]
    private static void DysonSphereSegmentRenderer_Free(DysonSphereSegmentRenderer __instance)
    {
        var instDysonShellRenderer = SphereOpt.getInstDysonShellRendererForSphere(__instance.dysonSphere);
        instDysonShellRenderer?.Free();
        SphereOpt.RemoveRenderer(__instance.dysonSphere);
    }
    
    [HarmonyPatch(typeof(DysonSphereLayer), "Free")]
    [HarmonyPrefix]
    private static void DysonSphereLayer_Free(DysonSphereLayer __instance)
    {
        var instDysonShellRenderer = SphereOpt.getInstDysonShellRendererForSphere(__instance.dysonSphere);
        instDysonShellRenderer?.RemoveLayer(__instance.id);
    }
}