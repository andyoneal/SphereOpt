using HarmonyLib;
using System.Collections.Generic;
using UnityEngine;

namespace SphereOpt;

internal class Patch_DysonSphereLayer
{
    [HarmonyPatch(typeof(DysonSphereLayer), "NewDysonShell")]
    [HarmonyPostfix]
    private static int DysonSphereLayer_NewDysonShell(DysonSphereLayer __instance, int protoId, List<int> nodeIds, ref int __result)
    {
        var layerId = __instance.id;
        var instShellLayer = InstDysonShell.getInstShellLayer(layerId);
        var shellIndex = __result; //shellPoolIndex
        DysonShell shell = __instance.shellPool[shellIndex];
        for (int i = 0; i < shell.verts.Length; i++)
        {
            var hex = new InstDysonShellLayer.HexData();
            hex.pos = shell.verts[i];
            hex.shellIndex = shellIndex;
            hex.nodeIndex = (int)shell.mesh.uv[i].x;
            hex.vertFillOrder = shell.mesh.uv[i].y;
            hex.polygonIndex = (int)shell.mesh.uv2[i].y;
            hex.axialCoords_x = (int)shell.mesh.uv3[i].x;
            hex.axialCoords_y = (int)shell.mesh.uv3[i].y;
            InstDysonShell.hexCount++;
            InstDysonShell.hexPool.Add(hex);
        };
        InstDysonShell.hexBufferIsDirty = true;

        var shellBuff = new InstDysonShellLayer.ShellData();
        shellBuff.color = (shell.color.a << 24) | (shell.color.b << 16) | (shell.color.g << 8) | shell.color.r;
        int progressBaseIndex = InstDysonShell.progressBaseCursor;
        shellBuff.progressBaseIndex = InstDysonShell.progressBaseCursor;
        InstDysonShell.progressBaseCursor = progressBaseIndex + shell.nodecps.Length - 1;
        shellBuff.state = shell.state;
        shellBuff.clockwise = shell.clockwise; //needs to be translated to negative or positive
        shellBuff.layerId = shell.layerId;
        shellBuff.polyCount = shell.polygon.Count;
        shellBuff.t0axis = new Vector3((float)shell.t0axis.x, (float)shell.t0axis.y, (float)shell.t0axis.z);
        shellBuff.t1axis = new Vector3((float)shell.t1axis.x, (float)shell.t1axis.y, (float)shell.t1axis.z);
        shellBuff.t2axis = new Vector3((float)shell.t2axis.x, (float)shell.t2axis.y, (float)shell.t2axis.z);
        shellBuff.radius = (float)shell.radius;
        shellBuff.scale = shell.gridScale;
        InstDysonShell.shellPool.Add(shellBuff);
        InstDysonShell.shellBufferIsDirty = true;

        for (int i = 0; i < shell.nodecps.Length - 1; i++)
        {
            var hexProgress = new InstDysonShellLayer.HexProgressData();
            hexProgress.progress = shell.nodecps[progressBaseIndex + i] / ((shell.vertsqOffset[progressBaseIndex + i + 1] - shell.vertsqOffset[progressBaseIndex + i]) * shell.cpPerVertex);
            InstDysonShell.hexProgressPool.Insert(progressBaseIndex + i, hexProgress);
        }
        InstDysonShell.hexProgressBufferIsDirty = true;

        return shellIndex;
    }
}