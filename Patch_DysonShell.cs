using System.Collections.Generic;
using System.Reflection.Emit;
using HarmonyLib;

namespace SphereOpt
{
    internal static class Patch_DysonShell
    {
        [HarmonyPatch(typeof(DysonShell), "SetMaterialStaticVars")]
        [HarmonyPrefix]
        private static bool DysonShell_SetMaterialStaticVars()
        {
            return false;
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
                var hex = new InstDysonShellLayer.HexData
                {
                    pos = hexPos,
                    shellIndex = shellIndex,
                    nodeIndex = (int)__instance.uvs[i].x,
                    vertFillOrder = __instance.uvs[i].y,
                    closestPolygon = (int)__instance.uv2s[i].y,
                    axialCoords_xy =
                        (uint)(((__instance.vkeys[i] >> 16) - 10000) & 0x0000ffff | ((__instance.vkeys[i] & 0xFFFF) - 10000) << 16)
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
                center = __instance.center,
                protoId = __instance.protoId,
                clockwise = __instance.clockwise ? 1 : -1
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

        [HarmonyPatch(typeof(UIDEToolbox), "OnColorChange")]
        [HarmonyPostfix]
        private static void UIDEToolbox_OnColorChange(UIDEToolbox __instance)
        {
            foreach (DysonShell selectedShell in __instance.editor.selection.selectedShells)
            {
                SphereOpt.UpdateColor(selectedShell);
            }
        }
        
        [HarmonyTranspiler]
        [HarmonyPatch(typeof(UIDysonBrush_Paint), "_OnUpdate")]
        static IEnumerable<CodeInstruction> UIDysonBrush_Paint__OnUpdate(IEnumerable<CodeInstruction> instructions, ILGenerator generator)
        {
            CodeMatcher matcher = new CodeMatcher(instructions, generator);
            
            matcher.MatchForward(true,
                new CodeMatch(OpCodes.Stfld, AccessTools.Field(typeof(DysonShell), nameof(DysonShell.color)))
            ).Advance(-12);

            var shellVarOpCode = matcher.Opcode;
            var shellVarOperand = matcher.Operand;

            matcher.Advance(13).InsertAndAdvance(
                new CodeInstruction(shellVarOpCode, shellVarOperand),
                new CodeInstruction(OpCodes.Call, AccessTools.Method(typeof(SphereOpt), nameof(SphereOpt.UpdateColor)))
            );

            return matcher.InstructionEnumeration();
        }
    }
}