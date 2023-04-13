using System;
using HarmonyLib;
using UnityEngine;
using Clipper2Lib;

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

    public static VectorLF2 CartToGrid(VectorLF3 cartCoords, double radius)
    {
        VectorLF2 gridCoords;
        gridCoords.x = Math.Atan2(cartCoords.z, cartCoords.x) * radius;
        gridCoords.y = Math.Asin( cartCoords.y / radius) * radius;
        return gridCoords;
    }

    [HarmonyPatch(typeof(DysonShell), "GenerateModelObjects")]
    [HarmonyPostfix]
    private static void DysonShell_GenerateModelObjects(DysonShell __instance)
    {
        var instDysonShellRenderer = SphereOpt.getInstDysonShellRendererForStar(__instance.dysonSphere);
        var layerId = __instance.layerId;
        var instShellLayer = instDysonShellRenderer.getInstShellLayer(layerId);
        var shellIndex = __instance.id;
        var verts = __instance.verts;

        var nodes = __instance.nodes;
        var radius = __instance.radius;

        if (DSPGame.IsMenuDemo) SphereOpt.OneRun = true;

        var centerXY = CartToGrid(__instance.center, radius);
        if (!SphereOpt.OneRun) SphereOpt.logger.LogWarning($"center: {centerXY}");
        var normTranslate = VectorLF2.zero - centerXY;
        var clip = new PathsD();
        var nodesXY = new double[nodes.Count * 2];
        for (var j = 0; j < nodes.Count; j++)
        {
            //are these in CCW order?
            var XY = CartToGrid(nodes[j].pos, radius) + normTranslate;
            nodesXY[j*2] = XY.x;
            nodesXY[j*2+1] = XY.y;
            if (!SphereOpt.OneRun) SphereOpt.logger.LogWarning($"nodes[{j}]: {XY}");
        }
        
        clip.Add(Clipper.MakePath(nodesXY));

        for (int i = 0; i < verts.Length; i++)
        {
            var hexPos = verts[i];
            var hex = new InstDysonShellLayer.HexData
            {
                pos = hexPos,
                shellIndex = shellIndex,
                nodeIndex = (int)__instance.mesh.uv[i].x,
                vertFillOrder = __instance.mesh.uv[i].y,
                //polygonIndex = (int)__instance.mesh.uv2[i].y,
                cutoutIndex = 0,
                axialCoords_xy =  (uint)((int)__instance.mesh.uv3[i].x & 0x0000ffff | (int)__instance.mesh.uv3[i].y << 16)
            };

            if (!SphereOpt.OneRun)
            {
                

                //var vertsXY = new VectorLF2[verts.Length];
                var vertXY = CartToGrid(verts[i], radius) + normTranslate;
                SphereOpt.logger.LogWarning($"vertXY: {vertXY}");
                var gridSize = __instance.gridSize;

                var subj = new PathsD();
                var hexVertsXY = new double[12];
                hexVertsXY[0]  = vertXY.x;					hexVertsXY[1]  = vertXY.y - gridSize/Math.Sqrt(3.0);
                hexVertsXY[2]  = vertXY.x + gridSize / 2.0;	hexVertsXY[3]  = vertXY.y - gridSize/Math.Sqrt(3.0)/2.0;
                hexVertsXY[4]  = vertXY.x + gridSize / 2.0;	hexVertsXY[5]  = vertXY.y + gridSize/Math.Sqrt(3.0)/2.0;
                hexVertsXY[6]  = vertXY.x;					hexVertsXY[7]  = vertXY.y + gridSize/Math.Sqrt(3.0);
                hexVertsXY[8]  = vertXY.x - gridSize / 2.0;	hexVertsXY[9]  = vertXY.y + gridSize/Math.Sqrt(3.0)/2.0;
                hexVertsXY[10] = vertXY.x - gridSize / 2.0;	hexVertsXY[11] = vertXY.y - gridSize/Math.Sqrt(3.0)/2.0;
                subj.Add(Clipper.MakePath(hexVertsXY));

                SphereOpt.logger.LogWarning($"hexvertsxy: {hexVertsXY.Join()}");

                var clipper = new ClipperD(8)
                {
                    PreserveCollinear = true
                };
                clipper.AddSubject(subj);
                clipper.AddClip(clip);
                var solution = new PathsD();
                clipper.Execute(ClipType.Intersection, FillRule.NonZero, solution);

                //PathsD solution = Clipper.Intersect(subj, clip, FillRule.NonZero, 3);
                SphereOpt.logger.LogWarning($"solution: {solution}");

            }
            //var intersectRadius = (float)(__instance.gridScale * 80f / Math.Sqrt(3));
            // Vector2 cutoutPoint = Vector2.zero;
            // Vector2 intersectDirOne = Vector2.zero;
            // Vector2 intersectDirTwo = Vector2.zero;
            // var foundIntersect = false;
            //
            // var sphereRadius = __instance.radius;

            /*var hexPosNormalized = getXYDist(hexPos, sphereRadius);

            var clockwise = __instance.clockwise ? 1 : -1;

            for (int j = 0; Math.Abs(j) < nodes.Count; j += clockwise )
            {
                var nodeIndex = mod((int)__instance.mesh.uv[i].x + j, nodes.Count);
                //SphereOpt.logger.LogWarning($"nodeIndex: {nodeIndex}");
                var prevNodeIndex = mod((nodeIndex - 1), nodes.Count);
                //SphereOpt.logger.LogWarning($"prevNodeIndex: {prevNodeIndex}");
                //if(prevNodeIndex < 0) prevNodeIndex = nodes.Count-1;
                var nextNodeIndex = mod((nodeIndex + 1), nodes.Count);
                //SphereOpt.logger.LogWarning($"nextNodeIndex: {nextNodeIndex}");
                //if(nextNodeIndex >= nodes.Count) nextNodeIndex = 0;

                var from_node = nodes[nodeIndex];
                var fromNode_distxy = getXYDist(from_node.pos, sphereRadius) - hexPosNormalized;
                //SphereOpt.logger.LogWarning($"A");
                var to_node = nodes[prevNodeIndex];
                var toNode_distxy = getXYDist(to_node.pos, sphereRadius) - hexPosNormalized;
                var dir = (Vector2)(toNode_distxy - fromNode_distxy).normalized;
                //SphereOpt.logger.LogWarning($"B");

                if (raySphereIntersect(fromNode_distxy, dir, intersectRadius))
                {
                    //SphereOpt.logger.LogWarning($"Found one. fromNode_distxy:{fromNode_distxy}, toNode: {toNode_distxy}, scale: {__instance.gridScale}, dir: {dir}");
                    cutoutPoint = fromNode_distxy / __instance.gridScale;
                    intersectDirOne = dir;
                    foundIntersect = true;
                }

                to_node = nodes[nextNodeIndex];
                toNode_distxy = getXYDist(to_node.pos, sphereRadius) - hexPosNormalized;
                dir = (Vector2)(toNode_distxy - fromNode_distxy).normalized;

                if (raySphereIntersect(fromNode_distxy, dir, intersectRadius))
                {
                    //SphereOpt.logger.LogWarning($"Found one. fromNode_distxy:{fromNode_distxy}, toNode: {toNode_distxy}, scale: {__instance.gridScale}, dir: {dir}");
                    cutoutPoint = fromNode_distxy / __instance.gridScale;
                    intersectDirTwo = dir;
                    foundIntersect = true;
                }

                if (foundIntersect) break;
            }*/

            /*foreach (var from_node in nodes)
            {
                bool foundOneIntersect = false;
                var fromNode_distxy = getXYDist(from_node.pos - hexPos, sphereRadius);
                foreach (var to_node in nodes)
                {
                    if (from_node == to_node) continue;

                    var toNode_distxy = getXYDist(to_node.pos - hexPos, sphereRadius);
                    var dir = (Vector2)(toNode_distxy - fromNode_distxy).normalized;
                    if (raySphereIntersect(fromNode_distxy, dir, intersectRadius))
                    {
                        if (foundOneIntersect == false)
                        {
                            SphereOpt.logger.LogWarning($"Found one. fromNode_distxy:{fromNode_distxy}, toNode: {toNode_distxy}, scale: {__instance.gridScale}, dir: {dir}");
                            cutoutPoint = (fromNode_distxy / __instance.gridScale);
                            intersectDirOne = dir;
                            foundOneIntersect = true;
                            foundIntersect = true;
                        }
                        else
                        {
                            intersectDirTwo = dir;
                            break;
                        }
                    }
                    if (!intersectDirTwo.Equals(Vector3.zero)) break;
                }
            }*/

            /*if (foundIntersect)
            {
                var angleToOne = Vector2.SignedAngle(Vector2.right, intersectDirOne) * Mathf.Deg2Rad;
                //angleToOne = __instance.clockwise ? angleToOne : (float)(angleToOne - 2.0 * Math.PI);
                //SphereOpt.logger.LogWarning($"angleToOne:{angleToOne}");
                var angleToTwo = Vector2.SignedAngle(Vector2.right, intersectDirTwo) * Mathf.Deg2Rad;
                //angleToTwo = __instance.clockwise ? angleToTwo : (float)(angleToTwo - 2.0 * Math.PI);
                var cutout = new InstDysonShellLayer.HexCutoutData()
                {
                    cutoutPoint = cutoutPoint,
                    angleToCutoutDirOne = angleToOne,// * (__instance.clockwise ? 1f : -1f),
                    angleToCutoutDirTwo = angleToTwo// * (__instance.clockwise ? 1f : -1f)
                };

                hex.cutoutIndex = instShellLayer.cutoutCursor;
                instShellLayer.cutoutCursor++;
                instShellLayer.AddCutoutData(hex.cutoutIndex, cutout);

            }
            if(SphereOpt.intersectionsFound < 30) SphereOpt.logger.LogWarning($@"...");

            SphereOpt.intersectionsFound++;*/

            instShellLayer.hexCount++;
            instShellLayer.hexPool.Add(hex);

        }

        SphereOpt.OneRun = true;

        instShellLayer.hexBufferIsDirty = true;

        int progressBaseIndex = instShellLayer.progressBaseCursor;
        instShellLayer.progressBaseCursor = progressBaseIndex + __instance.nodecps.Length - 1;
        var shellData = new InstDysonShellLayer.ShellData
        {
            color = (__instance.color.a << 24) | (__instance.color.b << 16) | (__instance.color.g << 8) | __instance.color.r,
            progressBaseIndex = instShellLayer.progressBaseCursor,
            state = __instance.state,
            //clockwise = __instance.clockwise ? 1 : -1, //needs to be translated to negative or positive
            //polyCount = (uint)__instance.polygon.Count,
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

    public static int mod(int a,  int b)
    {
        int c = a % b;
        return c < 0 ? c + b : c;
    }

    public static VectorLF2 getXYDist(VectorLF3 cartCoords, double sphereRadius)
    {
        if (cartCoords.x == 0)
            cartCoords.x = Mathf.Epsilon;
        var outPolar = Math.Atan2(cartCoords.z, cartCoords.x);
        if (cartCoords.x < 0)
            outPolar += Math.PI;
        var outElevation = Math.Asin(cartCoords.y / sphereRadius);
        return new VectorLF2(outPolar * sphereRadius, outElevation * sphereRadius);
    }

    public static bool raySphereIntersect(Vector2 nodePos, Vector2 dirToNode, float radius) {
        float A = Vector2.Dot(dirToNode,dirToNode);
        float B = 2 * Vector2.Dot(dirToNode, nodePos);
        float C = Vector2.Dot(nodePos, nodePos) - radius * radius;
        float disc = B * B - 4 * A * C;
        return !(disc < 0);
    }

    [HarmonyPatch(typeof(DysonShell), "Construct")]
    [HarmonyPrefix]
    private static bool DysonShell_Construct(DysonShell __instance, int nodeIndex, bool fastBuild = false)
    {
        var instDysonShellRenderer = SphereOpt.getInstDysonShellRendererForStar(__instance.dysonSphere);
        var instShellLayer = instDysonShellRenderer.getInstShellLayer(__instance.layerId);

        var progress = __instance.nodecps[nodeIndex] / (float)((__instance.vertsqOffset[nodeIndex + 1] - __instance.vertsqOffset[nodeIndex]) * __instance.cpPerVertex);
        instShellLayer.UpdateHexProgress(__instance.id, nodeIndex, progress);
        return true;
    }

    [HarmonyPatch(typeof(DysonSphereLayer), "RemoveDysonShell")]
    [HarmonyPostfix]
    private static void DysonSphereLayer_RemoveDysonShell(DysonSphereLayer __instance, int shellId)
    {
        var instDysonShellRenderer = SphereOpt.getInstDysonShellRendererForStar(__instance.dysonSphere);
        var instShellLayer = instDysonShellRenderer.getInstShellLayer(__instance.id);
        instShellLayer.RemoveDysonShell(shellId);
    }

    [HarmonyPatch(typeof(DysonSphere), "UpdateStates",  typeof(DysonShell), typeof(uint), typeof(bool), typeof(bool))]
    [HarmonyPostfix]
    public static void DysonSphere_UpdateStates(DysonSphere __instance, DysonShell shell)
    {
        var instDysonShellRenderer = SphereOpt.getInstDysonShellRendererForStar(__instance);
        var instShellLayer = instDysonShellRenderer.getInstShellLayer(shell.layerId);
        instShellLayer.UpdateState(shell.id, shell.state);
    }

    [HarmonyPatch(typeof(DysonSphereSegmentRenderer), "DrawModels")]
    [HarmonyPrefix]
    private static bool DysonSphereSegmentRenderer_DrawModels(DysonSphereSegmentRenderer __instance, ERenderPlace place, int editorMask, int gameMask)
    {
        //Vector3 vector = Vector3.zero;
        //Vector4 value = new Vector4(0f, 0f, 0f, 1f);
        //Vector3 vector2 = Vector3.zero;
        //var starData = __instance.starData;
        //var gameData = __instance.gameData;
        //var dysonSphere = __instance.dysonSphere;
        //var layerRotations = __instance.layerRotations;
        //if (starData != null && gameData != null)
        //{
        //    PlanetData localPlanet = gameData.localPlanet;
        //    Player mainPlayer = gameData.mainPlayer;
        //    vector = ((localPlanet == null) ? ((Vector3)(starData.uPosition - mainPlayer.uPosition)) : ((Vector3)Maths.QInvRotateLF(localPlanet.runtimeRotation, starData.uPosition - localPlanet.uPosition)));
        //    if (DysonSphere.renderPlace == ERenderPlace.Starmap)
        //    {
        //        vector2 = (starData.uPosition - UIStarmap.viewTargetStatic) * 0.00025;
        //    }
        //    if (localPlanet != null)
        //    {
        //        value = new Vector4(localPlanet.runtimeRotation.x, localPlanet.runtimeRotation.y, localPlanet.runtimeRotation.z, localPlanet.runtimeRotation.w);
        //    }
        //}
        //for (uint num = 1u; num <= 10; num++)
        //{
        //    DysonSphereLayer dysonSphereLayer = dysonSphere.layersIdBased[num];
        //    if (dysonSphereLayer != null)
        //    {
        //        layerRotations[num].x = dysonSphereLayer.currentRotation.x;
        //        layerRotations[num].y = dysonSphereLayer.currentRotation.y;
        //        layerRotations[num].z = dysonSphereLayer.currentRotation.z;
        //        layerRotations[num].w = dysonSphereLayer.currentRotation.w;
        //    }
        //    else
        //    {
        //        layerRotations[num].x = 0f;
        //        layerRotations[num].y = 0f;
        //        layerRotations[num].z = 0f;
        //        layerRotations[num].w = 1f;
        //    }
        //}
        //bool flag = true;
        //switch (place)
        //{
        //    case ERenderPlace.Universe:
        //    case ERenderPlace.Starmap:
        //        flag = gameMask != 0;
        //        break;
        //    case ERenderPlace.Dysonmap:
        //        flag = editorMask != 0;
        //        break;
        //}
        //_ = GameCamera.main;
        //int num2 = 16;
        //if (DysonSphere.renderPlace == ERenderPlace.Starmap)
        //{
        //    _ = UIRoot.instance.uiGame.starmap.screenCamera;
        //    num2 = 20;
        //}
        //else if (DysonSphere.renderPlace == ERenderPlace.Dysonmap)
        //{
        //    _ = UIRoot.instance.uiGame.dysonEditor.screenCamera;
        //    num2 = 21;
        //}
        //var batches = __instance.batches;
        //var argArr = __instance.argArr;
        //for (int i = 0; i < DysonSphereSegmentRenderer.totalProtoCount; i++)
        //{
        //    if (batches[i] != null)
        //    {
        //        argArr[i * 5 + 1] = (uint)batches[i].cursor;
        //    }
        //}

        //var argBuffer = __instance.argBuffer;
        //argBuffer.SetData(argArr);
        //var instMats = __instance.instMats;
        //for (int j = 0; j < DysonSphereSegmentRenderer.totalProtoCount; j++)
        //{
        //    if (batches[j] == null || batches[j].cursor <= 0)
        //    {
        //        continue;
        //    }
        //    batches[j].SyncBufferData();
        //    instMats[j].SetBuffer("_InstBuffer", batches[j].buffer);
        //    instMats[j].SetVectorArray("_LayerRotations", layerRotations);
        //    instMats[j].SetVector("_SunPosition", vector);
        //    instMats[j].SetVector("_SunPosition_Map", vector2);
        //    instMats[j].SetVector("_LocalRot", value);
        //    instMats[j].SetColor("_SunColor", dysonSphere.sunColor);
        //    instMats[j].SetColor("_DysonEmission", dysonSphere.emissionColor);
        //    if (flag)
        //    {
        //        Graphics.DrawMeshInstancedIndirect(DysonSphereSegmentRenderer.protoMeshes[j], 0, instMats[j], new Bounds(Vector3.zero, new Vector3(300000f, 300000f, 300000f)), argBuffer, j * 5 * 4, null, ShadowCastingMode.Off, receiveShadows: false, num2);
        //        if (PerformanceMonitor.GpuProfilerOn)
        //        {
        //            int cursor = batches[j].cursor;
        //            int vertexCount = DysonSphereSegmentRenderer.protoMeshes[j].vertexCount;
        //            PerformanceMonitor.RecordGpuWork((j < DysonSphereSegmentRenderer.nodeProtoCount) ? EGpuWorkEntry.DysonNode : EGpuWorkEntry.DysonFrame, cursor, cursor * vertexCount);
        //        }
        //    }
        //}
        SphereOpt.getInstDysonShellRendererForStar(__instance.dysonSphere).RenderShells(place, editorMask, gameMask);
        return false;
    }
}