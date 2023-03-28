using System;
using UnityEngine;
using UnityEngine.Rendering;

namespace SphereOpt
{
    internal static class InstDysonShell
    {
        public static Mesh HexMesh;
        public static Material HexMat;

        private static ComputeBuffer argsBuffer;
        private static uint[] args = new uint[50];

        private static InstDysonShellLayer[] instShellLayers = new InstDysonShellLayer[10];

        private static bool argsBufferIsDirty = true;

        public static InstDysonShellLayer getInstShellLayer(int layerId)
        {
            if (instShellLayers[layerId] == null)
            {
                instShellLayers[layerId]?.Init(layerId);
            }
            return instShellLayers[layerId];
        }

        public static void UpdateLayerArgs(int layerId, uint hexCount)
        {
            args[layerId * 5 + 1] = hexCount;
            
        }

        public static void Init()
        {
            SetupMesh();
            argsBuffer = new ComputeBuffer(10, 5 * sizeof(uint), ComputeBufferType.IndirectArguments);
            for (int i = 0; i < 10; i++)
            {
                args[i * 5 + 0] = HexMesh.GetIndexCount(0);
                args[i * 5 + 1] = 0u;
                args[i * 5 + 2] = HexMesh.GetIndexStart(0);
                args[i * 5 + 3] = HexMesh.GetBaseVertex(0);
                args[i * 5 + 4] = 0u;
            }
        }

        private static void SetupMesh()
        {
            throw new NotImplementedException();
        }

        public static void RenderShells()
        {
            for (int i = 0; i < 10; i++)
            {
                if (instShellLayers[i].hexCount > 0) instShellLayers[i].SyncBufferData();

            }

            if (argsBufferIsDirty)
            {
                argsBuffer.SetData(args);
                argsBufferIsDirty = false;
            }

            Vector4 localRot = new Vector4(0f, 0f, 0f, 1f);
            Vector3 pos = Vector3.zero;
            if (starData != null && gameData != null)
            {
                PlanetData localPlanet = gameData.localPlanet;
                Player mainPlayer = gameData.mainPlayer;
                pos = localPlanet == null ? (Vector3)(starData.uPosition - mainPlayer.uPosition) : (Vector3)Maths.QInvRotateLF(localPlanet.runtimeRotation, starData.uPosition - localPlanet.uPosition);
                if (DysonSphere.renderPlace == ERenderPlace.Starmap)
                {
                    vector2 = (starData.uPosition - UIStarmap.viewTargetStatic) * 0.00025;
                }
                if (localPlanet != null)
                {
                    localRot = new Vector4(localPlanet.runtimeRotation.x, localPlanet.runtimeRotation.y, localPlanet.runtimeRotation.z, localPlanet.runtimeRotation.w);
                }
            }
            int layer = 16;
            if (DysonSphere.renderPlace == ERenderPlace.Starmap)
            {
                layer = 20;
            }
            else if (DysonSphere.renderPlace == ERenderPlace.Dysonmap)
            {
                layer = 21;
            }

            for (int i = 0; i < 10; i++)
            {
                HexMat.SetVector("_LocalRot", localRot);
                if (instShellLayers[i].hexCount > 0)
                {
                    HexMat.SetVector("_LayerRotation", dysonSphereLayer2.currentRotation);
                    HexMat.
                    Graphics.DrawMeshInstancedIndirect(HexMesh, 0, HexMat, new Bounds(Vector3.zero, new Vector3(300000f, 300000f, 300000f)), argsBuffer, i * 5 * 4, null, ShadowCastingMode.Off, receiveShadows: false, layer);
                    Graphics.DrawMesh(dysonShell.mesh, Matrix4x4.TRS(pos, new Quaternion(localRot.x, localRot.y, localRot.z, 0f - localRot.w) * dysonSphereLayer2.currentRotation, Vector3.one), dysonShell.material, layer, null, 0, null, castShadows: false, receiveShadows: false);
                }
            }



        }
    }
}
