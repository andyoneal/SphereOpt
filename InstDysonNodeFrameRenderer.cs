using UnityEngine;
using UnityEngine.Rendering;
using UnityMeshSimplifier;

namespace SphereOpt
{
    public static class InstDysonNodeFrameRenderer
    {
        public static bool instBufferChangedSize;
        private static ComputeBuffer[][] lodBatchBuffers;
        private static Mesh[][] lodMeshes;
        private static readonly Vector4[] layerRotations = new Vector4[11 * 3];
        private static ComputeShader frameLODShader;
        private static int csKernelId;
        private static uint csThreads;
        private static ComputeBuffer argBuffer;

        private static StarData starData;
        private static GameData gameData;
        private static DysonSphere dysonSphere;
        private static DysonSphereSegmentRenderer currentDSSR;

        private static readonly int InstBuffer = Shader.PropertyToID("_InstBuffer");
        private static readonly int LayerRotations = Shader.PropertyToID("_LayerRotations");
        private static readonly int SunColor = Shader.PropertyToID("_SunColor");
        private static readonly int DysonEmission = Shader.PropertyToID("_DysonEmission");
        private static readonly int InstIndexBuffer = Shader.PropertyToID("_InstIndexBuffer");
        private static readonly int GlobalDSSunPosition = Shader.PropertyToID("_Global_DS_SunPosition");
        private static readonly int GlobalDSSunPositionMap = Shader.PropertyToID("_Global_DS_SunPosition_Map");
        private static readonly int CamPosition = Shader.PropertyToID("_CamPosition");
        private static readonly int Scale = Shader.PropertyToID("_Scale");
        private static readonly int UnityMatrixVp = Shader.PropertyToID("_UNITY_MATRIX_VP");
        private static readonly int FOV = Shader.PropertyToID("_FOV");
        private static readonly int LOD0IDBuffer = Shader.PropertyToID("_LOD0_ID_Buffer");
        private static readonly int LOD1IDBuffer = Shader.PropertyToID("_LOD1_ID_Buffer");
        private static readonly int LOD2IDBuffer = Shader.PropertyToID("_LOD2_ID_Buffer");

        public static void SetupMeshes()
        {
            if (lodMeshes != null) return;

            lodMeshes = new Mesh[DysonSphereSegmentRenderer.totalProtoCount][];
            var meshSimplifier = new MeshSimplifier();
            for (int i = 0; i < DysonSphereSegmentRenderer.totalProtoCount; i++)
            {
                lodMeshes[i] = new Mesh[3];
                lodMeshes[i][0] = DysonSphereSegmentRenderer.protoMeshes[i];
                meshSimplifier.Initialize(DysonSphereSegmentRenderer.protoMeshes[i]);
                var options = SimplificationOptions.Default;
                if (i == 0)
                {
                    options.PreserveBorderEdges = true;
                    options.PreserveUVFoldoverEdges = false;
                    options.PreserveUVSeamEdges = true;
                }
                else
                {
                    options.PreserveBorderEdges = true;
                    options.PreserveUVFoldoverEdges = true;
                    options.PreserveUVSeamEdges = false;  
                }
                options.MaxIterationCount = 1000;
                meshSimplifier.SimplificationOptions = options;
                meshSimplifier.SimplifyMesh(0.7f);
                lodMeshes[i][1] = meshSimplifier.ToMesh();
                meshSimplifier.Initialize(DysonSphereSegmentRenderer.protoMeshes[i]);
                meshSimplifier.SimplificationOptions = options;
                meshSimplifier.SimplifyMesh(0.2f);
                lodMeshes[i][2] = meshSimplifier.ToMesh();
            }
        }

        public static void SetupQuadMeshes()
        {
            if (lodMeshes == null) return;
            Mesh mesh = FrameQuadMesh();
            
            lodMeshes = new Mesh[DysonSphereSegmentRenderer.totalProtoCount][];

            for (int i = 0; i < DysonSphereSegmentRenderer.totalProtoCount; i++)
            {
                lodMeshes[i] = new Mesh[3];
                lodMeshes[i][0] = mesh;
                lodMeshes[i][1] = mesh;
                lodMeshes[i][2] = mesh;
            }
        }
        
        public static Mesh FrameQuadMesh()
        {
            Mesh quadMesh = new Mesh();
            
            Vector3[] vertices = new Vector3[4]
            {
                new Vector3(-0.5f, 0.015f, 0f),
                new Vector3(0.5f, 0.015f, 0f),
                new Vector3(-0.5f, 0.015f, 1f),
                new Vector3(0.5f, 0.015f, 1f)
            };
            quadMesh.vertices = vertices;
            
            int[] tris = new int[6]
            {
                0, 2, 1,
                2, 3, 1
            };
            quadMesh.triangles = tris;
            
            quadMesh.RecalculateNormals();
            quadMesh.RecalculateTangents();
            
            Vector2[] uv = new Vector2[4]
            {
                new Vector2(0.85688f, 0.4275f),
                new Vector2(0.81705f, 0.4351f),
                new Vector2(0.81705f, 0.4351f),
                new Vector2(0.85699f, 0.4275f)
            };
            quadMesh.uv = uv;
            
            return quadMesh;
        }

        public static void SetupBuffers()
        {
            if (lodBatchBuffers != null) return;

            var totalProtoCount = DysonSphereSegmentRenderer.totalProtoCount;

            lodBatchBuffers = new ComputeBuffer[totalProtoCount][];
            for (int i = 0; i < totalProtoCount; i++)
            {
                lodBatchBuffers[i] = new ComputeBuffer[3];
                lodBatchBuffers[i][0] = new ComputeBuffer(128, 4);
                lodBatchBuffers[i][1] = new ComputeBuffer(128, 4);
                lodBatchBuffers[i][2] = new ComputeBuffer(128, 4);
            }

            var argArr = new uint[5 * totalProtoCount * 3];
            for (int i = 0; i < totalProtoCount; i++)
            {
                for (int j = 0; j < 3; j++)
                {
                    if (DysonSphereSegmentRenderer.protoMeshes[i] != null &&
                        DysonSphereSegmentRenderer.protoMats[i] != null)
                    {
                        argArr[i * 15 + j * 5] = lodMeshes[i][j].GetIndexCount(0);
                        argArr[i * 15 + j * 5 + 1] = 0u;
                        argArr[i * 15 + j * 5 + 2] = lodMeshes[i][j].GetIndexStart(0);
                        argArr[i * 15 + j * 5 + 3] = lodMeshes[i][j].GetBaseVertex(0);
                        argArr[i * 15 + j * 5 + 4] = 0u;
                    }
                }
            }

            argBuffer?.Release();
            argBuffer = new ComputeBuffer(argArr.Length, 4, ComputeBufferType.IndirectArguments);
            argBuffer.SetData(argArr);
        }

        public static void SetupLODShader()
        {
            if (frameLODShader != null) return;

            frameLODShader = CustomShaderManager.LoadComputeShader("Frame LOD");
            csKernelId = frameLODShader.FindKernel("CSMain");
            frameLODShader.GetKernelThreadGroupSizes(csKernelId, out csThreads, out var _, out var _);
        }

        private static void switchDSSR(DysonSphereSegmentRenderer dssr)
        {
            instBufferChangedSize = true;

            starData = dssr.starData;
            gameData = dssr.gameData;
            dysonSphere = dssr.dysonSphere;

            currentDSSR = dssr;
        }

        private static void rebuildInstBuffers()
        {
            for (int b = 0; b < DysonSphereSegmentRenderer.totalProtoCount; b++)
            {
                if (currentDSSR.batches[b] == null || currentDSSR.batches[b].cursor <= 0) continue;
                var bufferCount = currentDSSR.batches[b].buffer.count;
                if (lodBatchBuffers[b][0] == null || bufferCount != lodBatchBuffers[b][0].count)
                {
                    for (int i = 0; i < 3; i++)
                    {
                        lodBatchBuffers[b][i]?.Release();
                        lodBatchBuffers[b][i] = new ComputeBuffer(bufferCount, 4, ComputeBufferType.Append);
                    }
                }
            }
        }

        public static void Render(DysonSphereSegmentRenderer dssr, ERenderPlace place, int editorMask, int gameMask)
        {
            if (currentDSSR == null || currentDSSR != dssr) switchDSSR(dssr);

            if (instBufferChangedSize)
            {
                rebuildInstBuffers();
                instBufferChangedSize = false;
            }

            var localRot = new Quaternion(0f, 0f, 0f, 1f);
            var sunPos = Vector3.zero;
            var sunPosMap = Vector3.zero;
            if (starData != null && gameData != null)
            {
                var localPlanet = gameData.localPlanet;
                var mainPlayer = gameData.mainPlayer;
                sunPos = localPlanet == null
                    ? (Vector3)(starData.uPosition - mainPlayer.uPosition)
                    : (Vector3)Maths.QInvRotateLF(localPlanet.runtimeRotation,
                        starData.uPosition - localPlanet.uPosition);
                if (place == ERenderPlace.Starmap)
                {
                    sunPosMap = (starData.uPosition - UIStarmap.viewTargetStatic) * 0.00025;
                }

                if (localPlanet != null && place == ERenderPlace.Universe)
                {
                    localRot = new Quaternion(localPlanet.runtimeRotation.x, localPlanet.runtimeRotation.y,
                        localPlanet.runtimeRotation.z, 0f - localPlanet.runtimeRotation.w);
                }
            }

            bool shouldRender = true;
            var layer = 16;
            var cam = GameCamera.main;
            switch (place)
            {
                case ERenderPlace.Universe:
                    shouldRender = gameMask != 0;
                    break;
                case ERenderPlace.Starmap:
                    shouldRender = gameMask != 0;
                    cam = UIRoot.instance.uiGame.starmap.screenCamera;
                    layer = 20;
                    break;
                case ERenderPlace.Dysonmap:
                    shouldRender = editorMask != 0;
                    cam = UIRoot.instance.uiGame.dysonEditor.screenCamera;
                    layer = 21;
                    break;
                case ERenderPlace.DemoScene:
                default:
                    break;
            }
            Shader.SetGlobalVector(GlobalDSSunPosition, sunPos);
            Shader.SetGlobalVector(GlobalDSSunPositionMap, sunPosMap);

            var pos = place == ERenderPlace.Universe ? sunPos : sunPosMap;
            var scale = place == ERenderPlace.Starmap || place == ERenderPlace.Dysonmap
                ? new Vector3(0.00025f, 0.00025f, 0.00025f)
                : Vector3.one;
            for (var l = 1; l <= 10; l++)
            {
                var dysonSphereLayer = dysonSphere.layersIdBased[l];
                var transformMatrix = dysonSphereLayer == null
                    ? Matrix4x4.identityMatrix
                    : Matrix4x4.TRS(pos, localRot * dysonSphereLayer.currentRotation, scale);
                layerRotations[l * 3] = transformMatrix.GetRow(0);
                layerRotations[l * 3 + 1] = transformMatrix.GetRow(1);
                layerRotations[l * 3 + 2] = transformMatrix.GetRow(2);
            }

            var batches = dssr.batches;
            var instMats = dssr.instMats;
            frameLODShader.SetVectorArray(LayerRotations, layerRotations);
            frameLODShader.SetVector(CamPosition, cam.transform.position);
            frameLODShader.SetFloat(Scale, scale.x);
            Matrix4x4 v = cam.worldToCameraMatrix;
            Matrix4x4 p = cam.projectionMatrix;
            frameLODShader.SetMatrix(UnityMatrixVp, p * v);
            float fov = cam.fieldOfView;
            frameLODShader.SetFloat(FOV, fov);
            var mpb = new MaterialPropertyBlock();
            mpb.SetVectorArray(LayerRotations, layerRotations);
            for (var b = 0; b < DysonSphereSegmentRenderer.totalProtoCount; b++)
            {
                if (batches[b] == null || batches[b].cursor <= 0) continue;
                batches[b].SyncBufferData();
                frameLODShader.SetBuffer(csKernelId, InstBuffer, batches[b].buffer);
                frameLODShader.SetBuffer(csKernelId, LOD0IDBuffer, lodBatchBuffers[b][0]);
                frameLODShader.SetBuffer(csKernelId, LOD1IDBuffer, lodBatchBuffers[b][1]);
                frameLODShader.SetBuffer(csKernelId, LOD2IDBuffer, lodBatchBuffers[b][2]);
                for (int i = 0; i < 3; i++)
                {
                    lodBatchBuffers[b][i].SetCounterValue(0u);
                }

                frameLODShader.Dispatch(csKernelId,
                    Mathf.Max(1, Mathf.CeilToInt(batches[b].cursor / (float)csThreads)), 1, 1);
                for (int i = 0; i < 3; i++)
                {
                    ComputeBuffer.CopyCount(lodBatchBuffers[b][i], argBuffer, (b * 15 + i * 5 + 1) * 4);
                }
                instMats[b].SetColor(SunColor, dysonSphere.sunColor);
                instMats[b].SetColor(DysonEmission, dysonSphere.emissionColor);
                mpb.SetBuffer(InstBuffer, batches[b].buffer);
                for (int j = 0; j < 3; j++)
                {
                    mpb.SetBuffer(InstIndexBuffer, lodBatchBuffers[b][j]);
                    if (shouldRender)
                    {
                        Graphics.DrawMeshInstancedIndirect(lodMeshes[b][j], 0, instMats[b],
                            new Bounds(Vector3.zero, new Vector3(300000f, 300000f, 300000f)), argBuffer,
                            (b * 15 + j * 5) * 4, mpb, ShadowCastingMode.Off, false, layer);
                    }
                }
            }
        }
    }
}