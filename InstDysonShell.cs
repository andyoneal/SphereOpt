using System;
using UnityEngine;
using UnityEngine.Rendering;

namespace SphereOpt
{
    public class InstDysonShellRenderer
    {
        public Mesh HexMesh;
        public Material HexMat;

        private ComputeBuffer argsBuffer;
        private uint[] args = new uint[50];

        private InstDysonShellLayer[] instShellLayers = new InstDysonShellLayer[11];

        private bool argsBufferIsDirty = true;

        public DysonSphere dysonSphere;
        private GameData gameData;
        private StarData starData;


        private void SetupMesh()
        {
            HexMesh = new Mesh();
            var newVerts = new Vector3[7];

            var t1axis = new Vector3(-40f, (float)(40.0 / Math.Sqrt(3)), 0);
            var t2axis = new Vector3(40f, (float)(40.0 / Math.Sqrt(3)), 0);
            var t0axis = new Vector3(0, (float)(80.0 / Math.Sqrt(3)), 0);

            
            newVerts[0] = Vector3.zero;
            newVerts[1] = t0axis;
            newVerts[2] = Vector3.zero - t0axis;
            newVerts[3] = t1axis;
            newVerts[4] = Vector3.zero - t1axis;
            newVerts[5] = t2axis;
            newVerts[6] = Vector3.zero - t2axis;

            var newTris = new[] {
                1, 0, 3,
                3, 0, 6,
                6, 0, 2,
                2, 0, 4,
                4, 0, 5,
                5, 0, 1
            };

            HexMesh.vertices = newVerts;
            HexMesh.triangles = newTris;
            HexMesh.RecalculateNormals();
            HexMesh.RecalculateTangents();

            HexMat = UnityEngine.Object.Instantiate(
                Resources.Load<Material>("Dyson Sphere/Materials/dyson-shell-unlit-0"));
            CustomShaderManager.ApplyCustomShaderToMaterial(HexMat, "dysonshell-inst");

            HexMat.SetColor("_DysonEmission", dysonSphere.emissionColor);
            HexMat.SetColor("_SunColor", dysonSphere.sunColor);
        }

        public InstDysonShellLayer getInstShellLayer(int layerId)
        {
            if (instShellLayers[layerId] == null)
            {
                instShellLayers[layerId] = new InstDysonShellLayer(layerId);
            }
            return instShellLayers[layerId];
        }

        public InstDysonShellRenderer(DysonSphere _dysonSphere)
        {
            SphereOpt.OneRun = false;
            dysonSphere = _dysonSphere;
            gameData = dysonSphere.gameData;
            starData = dysonSphere.starData;

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

        public void UpdateLayerArgs(int layerId, uint hexCount)
        {
            args[layerId * 5 + 1] = hexCount;
            argsBufferIsDirty = true;

        }

        public void RenderShells(ERenderPlace place, int editorMask, int gameMask)
        {
            for (var i = 1; i <= 10; i++)
            {
                var instLayer = instShellLayers[i];
                if (instLayer == null) continue;
                if (instLayer.hexCount > 0)
                {
                    instLayer.SyncBufferData();
                    if (instLayer.cachedHexCount != instLayer.hexCount)
                    {
                        UpdateLayerArgs(i, instLayer.hexCount);
                        instLayer.cachedHexCount = (int)instLayer.hexCount;
                    }
                }

            }

            if (argsBufferIsDirty)
            {
                argsBuffer.SetData(args);
                argsBufferIsDirty = false;
            }

            var localRot = new Quaternion(0f, 0f, 0f, 1f);
            var sunPos = Vector3.zero;
            var sunPosMap = Vector3.zero;
            if (starData != null && gameData != null)
            {
                var localPlanet = gameData.localPlanet;
                var mainPlayer = gameData.mainPlayer;
                sunPos = ((localPlanet == null) ? ((Vector3)(starData.uPosition - mainPlayer.uPosition)) : ((Vector3)Maths.QInvRotateLF(localPlanet.runtimeRotation, starData.uPosition - localPlanet.uPosition)));
                if (DysonSphere.renderPlace == ERenderPlace.Starmap)
                {
                    sunPosMap = (starData.uPosition - UIStarmap.viewTargetStatic) * 0.00025;
                }
                if (localPlanet != null)
                {
                    localRot = new Quaternion(localPlanet.runtimeRotation.x, localPlanet.runtimeRotation.y, localPlanet.runtimeRotation.z, 0f - localPlanet.runtimeRotation.w);
                }
            }

            var layer = 16;
            switch (DysonSphere.renderPlace)
            {
                case ERenderPlace.Starmap:
                    layer = 20;
                    break;
                case ERenderPlace.Dysonmap:
                    layer = 21;
                    break;
            }
            Shader.SetGlobalVector("_Global_DS_SunPosition", sunPos);
            Shader.SetGlobalVector("_Global_DS_SunPosition_Map", sunPosMap);
            var pos = DysonSphere.renderPlace == ERenderPlace.Universe ? sunPos : sunPosMap;

            for (var i = 1; i <= 10; i++)
            {
                if (instShellLayers[i] == null) continue;
                var shiftLayer = 1 << i;
                if (!((layer != 16 && layer != 20) ? ((editorMask & shiftLayer) > 0) : ((gameMask & shiftLayer) > 0)))
                {
                    continue;
                }
                var instLayer = instShellLayers[i];
                if (instLayer.hexCount <= 0) continue;
                instLayer.SetProps();
                //TODO: No need to reset the props every time, I think.
                var dysonSphereLayer = dysonSphere.layersIdBased[i];
                instLayer.props.SetMatrix("_ObjectToWorld", Matrix4x4.TRS(pos, localRot * dysonSphereLayer.currentRotation, Vector3.one));
                //TODO: create localRot matrix ahead of time

                Graphics.DrawMeshInstancedIndirect(HexMesh, 0, HexMat,
                    new Bounds(Vector3.zero, new Vector3(300000f, 300000f, 300000f)), argsBuffer, i * 5 * 4,
                    instLayer.props, ShadowCastingMode.Off, receiveShadows: false, layer);
            }
        }
    }
}
