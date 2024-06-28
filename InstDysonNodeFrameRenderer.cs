using UnityEngine;
using UnityEngine.Rendering;

namespace SphereOpt
{
    public static class InstDysonNodeFrameRenderer
    {
        private static NodeBatch[] nodeBatches;
        private static FrameBatch[] frameBatches;

        private static readonly Vector4[] layerRotations = new Vector4[11 * 3];

        private static ComputeShader frameLODShader;
        private static int frameCSKernelId;
        private static uint frameCSThreads;

        private static ComputeShader nodeLODShader;
        private static int nodeCSKernelId;
        private static uint nodeCSThreads;

        private static ComputeBuffer nodeArgBuffer;
        private static ComputeBuffer frameArgBuffer;

        private static StarData starData;
        private static GameData gameData;
        private static DysonSphere dysonSphere;
        private static DysonSphereSegmentRenderer currentDSSR;

        private static int nodeProtoCount => DysonSphereSegmentRenderer.nodeProtoCount;
        private static int frameProtoCount => DysonSphereSegmentRenderer.frameProtoCount;

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
        
        private static readonly MaterialPropertyBlock mpb = new MaterialPropertyBlock();

        public static void SetupBatches()
        {
            if (nodeBatches != null || frameBatches != null)
                return;

            nodeBatches = new NodeBatch[nodeProtoCount];
            var nodeArgArr = new uint[5 * nodeProtoCount * 3];

            for (int i = 0; i < nodeProtoCount; i++)
            {
                var batch = new NodeBatch();
                batch.lodBatchBuffers = new ComputeBuffer[3];
                batch.lodBatchBuffers[0] = new ComputeBuffer(128, 4, ComputeBufferType.Append);
                batch.lodBatchBuffers[1] = new ComputeBuffer(128, 4, ComputeBufferType.Append);
                batch.lodBatchBuffers[2] = new ComputeBuffer(128, 4, ComputeBufferType.Append);

                batch.SetupMeshes(DysonSphereSegmentRenderer.protoMeshes[i]);
                batch.SetupMat(DysonSphereSegmentRenderer.protoMats[i]);
                batch.mpb = new MaterialPropertyBlock();

                nodeBatches[i] = batch;

                for (int j = 0; j < 3; j++)
                {
                    nodeArgArr[i * 15 + j * 5] = nodeBatches[i].lodMeshes[j].GetIndexCount(0);
                    nodeArgArr[i * 15 + j * 5 + 1] = 0u;
                    nodeArgArr[i * 15 + j * 5 + 2] = nodeBatches[i].lodMeshes[j].GetIndexStart(0);
                    nodeArgArr[i * 15 + j * 5 + 3] = nodeBatches[i].lodMeshes[j].GetBaseVertex(0);
                    nodeArgArr[i * 15 + j * 5 + 4] = 0u;
                }
            }

            nodeArgBuffer?.Release();
            nodeArgBuffer = new ComputeBuffer(nodeArgArr.Length, 4, ComputeBufferType.IndirectArguments);
            nodeArgBuffer.SetData(nodeArgArr);

            frameBatches = new FrameBatch[frameProtoCount];
            var frameArgArr = new uint[5 * frameProtoCount * 3];

            for (int i = 0; i < frameProtoCount; i++)
            {
                var batch = new FrameBatch();
                batch.lodBatchBuffers = new ComputeBuffer[3];
                batch.lodBatchBuffers[0] = new ComputeBuffer(128, 4, ComputeBufferType.Append);
                batch.lodBatchBuffers[1] = new ComputeBuffer(128, 4, ComputeBufferType.Append);
                batch.lodBatchBuffers[2] = new ComputeBuffer(128, 4, ComputeBufferType.Append);

                batch.SetupMeshes(DysonSphereSegmentRenderer.protoMeshes[nodeProtoCount + i]);
                batch.SetupMat(DysonSphereSegmentRenderer.protoMats[nodeProtoCount + i]);
                batch.mpb = new MaterialPropertyBlock();

                frameBatches[i] = batch;

                for (int j = 0; j < 3; j++)
                {
                    frameArgArr[i * 15 + j * 5] = frameBatches[i].lodMeshes[j].GetIndexCount(0);
                    frameArgArr[i * 15 + j * 5 + 1] = 0u;
                    frameArgArr[i * 15 + j * 5 + 2] = frameBatches[i].lodMeshes[j].GetIndexStart(0);
                    frameArgArr[i * 15 + j * 5 + 3] = frameBatches[i].lodMeshes[j].GetBaseVertex(0);
                    frameArgArr[i * 15 + j * 5 + 4] = 0u;
                }
            }

            frameArgBuffer?.Release();
            frameArgBuffer = new ComputeBuffer(frameArgArr.Length, 4, ComputeBufferType.IndirectArguments);
            frameArgBuffer.SetData(frameArgArr);
        }

        public static void SetupLODShader()
        {
            if (frameLODShader != null || nodeLODShader != null)
                return;

            nodeLODShader = CustomShaderManager.LoadComputeShader("Node LOD");
            nodeCSKernelId = nodeLODShader.FindKernel("CSMain");
            nodeLODShader.GetKernelThreadGroupSizes(nodeCSKernelId, out nodeCSThreads, out var _, out var _);

            frameLODShader = CustomShaderManager.LoadComputeShader("Frame LOD");
            frameCSKernelId = frameLODShader.FindKernel("CSMain");
            frameLODShader.GetKernelThreadGroupSizes(frameCSKernelId, out frameCSThreads, out var _, out var _);
        }

        public static void SwitchDSSR(DysonSphereSegmentRenderer dssr)
        {
            starData = dssr.starData;
            gameData = dssr.gameData;
            dysonSphere = dssr.dysonSphere;

            currentDSSR = dssr;

            RebuildFrameModels();

            for (int i = 0; i < nodeProtoCount; i++)
            {
                nodeBatches[i].protoMat.SetColor(SunColor, dysonSphere.sunColor);
                nodeBatches[i].protoMat.SetColor(DysonEmission, dysonSphere.emissionColor);
                nodeBatches[i].SetBatchBufferDirty();
            }

            for (int i = 0; i < frameProtoCount; i++)
            {
                frameBatches[i].protoMat.SetColor(SunColor, dysonSphere.sunColor);
                frameBatches[i].protoMat.SetColor(DysonEmission, dysonSphere.emissionColor);
                frameBatches[i].SetBatchBufferDirty();
            }
        }

        public static void RebuildFrameModels()
	    {
		    for (int i = 0; i < frameProtoCount; i++)
		    {
			    frameBatches[i]?.ClearSegments();
		    }

		    for (uint layer = 1u; layer <= 10; layer++)
		    {
			    DysonSphereLayer dysonSphereLayer = dysonSphere.layersIdBased[layer];
			    if (dysonSphereLayer == null)
                    continue;

                for (int j = 1; j < dysonSphereLayer.nodeCursor; j++)
                {
                    DysonNode dysonNode = dysonSphereLayer.nodePool[j];
                    if (dysonNode == null || dysonNode.id != j)
                        continue;

                    NodeSegment seg = default(NodeSegment);
                    seg.layer = layer;
                    seg.pos0 = seg.pos1 = dysonNode.pos;
                    seg.progress0 = seg.progress1 = dysonNode.sp / (float)dysonNode.spMax;
                    seg.color = dysonNode.color;

                    uint protoId = (uint)dysonNode.protoId;
                    if (nodeBatches[protoId] != null)
                    {
                        nodeBatches[protoId].AddNode(seg);
                        //dysonNode.modelIdx = segId + 1;
                    }
                }

			    for (int k = 1; k < dysonSphereLayer.frameCursor; k++)
			    {
				    DysonFrame dysonFrame = dysonSphereLayer.framePool[k];
				    if (dysonFrame == null || dysonFrame.id != k)
                        continue;

				    Vector3 fromNodePos = dysonFrame.nodeA.pos;
				    Vector3 toNodePos = dysonFrame.nodeB.pos;
				    int segCount = dysonFrame.segCount;

				    Vector3 currentNodePos = fromNodePos;
				    for (int l = 0; l < segCount; l++)
				    {
					    float t = (l + 1f) / segCount;

                        FrameSegment seg = default(FrameSegment);
					    seg.layer = layer;
                        bool progress = Mathf.Clamp01(dysonFrame.spA / 10f - l) + Mathf.Clamp01(dysonFrame.spB / 10f - (segCount - l - 1)) > 0.01;
                        seg.progress = progress;
                        seg.color = dysonFrame.color;
					    seg.pos0 = currentNodePos;
                        seg.pos1 = dysonFrame.euler ? Maths.Elerp(fromNodePos, toNodePos, t) : Vector3.Slerp(fromNodePos, toNodePos, t);

                        uint protoId = (uint)(dysonFrame.protoId - nodeProtoCount);
                        frameBatches[protoId]?.AddSegment(seg);

                        currentNodePos = seg.pos1;
				    }
			    }
		    }

		    for (int m = 0; m < frameProtoCount; m++)
		    {
			    frameBatches[m]?.SetBatchBufferDirty();
		    }
	    }

        public static void Render(DysonSphereSegmentRenderer dssr, ERenderPlace place, int editorMask, int gameMask)
        {
            if (starData == null || gameData == null)
                return;

            if (currentDSSR == null || currentDSSR != dssr) SwitchDSSR(dssr);

            var localPlanet = gameData.localPlanet;
            var mainPlayer = gameData.mainPlayer;

            Vector3 sunPos = localPlanet == null
                ? starData.uPosition - mainPlayer.uPosition
                : Maths.QInvRotateLF(localPlanet.runtimeRotation, starData.uPosition - localPlanet.uPosition);

            Vector3 sunPosMap = place == ERenderPlace.Starmap
                ? (Vector3)((starData.uPosition - UIStarmap.viewTargetStatic) * 0.00025)
                : Vector3.zero;

            var localRot = localPlanet != null && place == ERenderPlace.Universe
                ? new Quaternion(localPlanet.runtimeRotation.x, localPlanet.runtimeRotation.y,
                    localPlanet.runtimeRotation.z, 0f - localPlanet.runtimeRotation.w)
                : Quaternion.identity;

            Shader.SetGlobalVector(GlobalDSSunPosition, sunPos);
            Shader.SetGlobalVector(GlobalDSSunPositionMap, sunPosMap);

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

            Matrix4x4 v = cam.worldToCameraMatrix;
            Matrix4x4 p = cam.projectionMatrix;

            nodeLODShader.SetVectorArray(LayerRotations, layerRotations);
            nodeLODShader.SetVector(CamPosition, cam.transform.position);
            nodeLODShader.SetFloat(Scale, scale.x);
            nodeLODShader.SetMatrix(UnityMatrixVp, p * v);
            nodeLODShader.SetFloat(FOV, cam.fieldOfView);

            mpb.SetVectorArray(LayerRotations, layerRotations);

            for (int b = 0; b < nodeProtoCount; b++)
            {
                var nodeBatch = nodeBatches[b];
                if (nodeBatch == null || nodeBatch.cursor <= 0)
                    continue;

                nodeBatch.SyncBufferData();

                nodeLODShader.SetBuffer(nodeCSKernelId, InstBuffer, nodeBatch.buffer);
                nodeLODShader.SetBuffer(nodeCSKernelId, LOD0IDBuffer, nodeBatch.lodBatchBuffers[0]);
                nodeLODShader.SetBuffer(nodeCSKernelId, LOD1IDBuffer, nodeBatch.lodBatchBuffers[1]);
                nodeLODShader.SetBuffer(nodeCSKernelId, LOD2IDBuffer, nodeBatch.lodBatchBuffers[2]);

                nodeBatch.ResetCounters();
                nodeLODShader.Dispatch(nodeCSKernelId, Mathf.Max(1, Mathf.CeilToInt(nodeBatch.cursor / (float)nodeCSThreads)), 1, 1);

                ComputeBuffer.CopyCount(nodeBatch.lodBatchBuffers[0], nodeArgBuffer, (b * 15 + 0 * 5 + 1) * 4);
                ComputeBuffer.CopyCount(nodeBatch.lodBatchBuffers[1], nodeArgBuffer, (b * 15 + 1 * 5 + 1) * 4);
                ComputeBuffer.CopyCount(nodeBatch.lodBatchBuffers[2], nodeArgBuffer, (b * 15 + 2 * 5 + 1) * 4);

                for (int i = 0; i < 3; i++)
                {
                    if (shouldRender)
                    {
                        mpb.SetBuffer(InstIndexBuffer, nodeBatch.lodBatchBuffers[i]);
                        Graphics.DrawMeshInstancedIndirect(nodeBatch.lodMeshes[i], 0, nodeBatch.protoMat,
                            new Bounds(Vector3.zero, new Vector3(300000f, 300000f, 300000f)), nodeArgBuffer,
                            (b * 15 + i * 5) * 4, mpb, ShadowCastingMode.Off, false, layer);
                    }
                }
            }

            frameLODShader.SetVectorArray(LayerRotations, layerRotations);
            frameLODShader.SetVector(CamPosition, cam.transform.position);
            frameLODShader.SetFloat(Scale, scale.x);
            frameLODShader.SetMatrix(UnityMatrixVp, p * v);
            frameLODShader.SetFloat(FOV, cam.fieldOfView);

            for (int b = 0; b < frameProtoCount; b++)
            {
                var frameBatch = frameBatches[b];
                if (frameBatch == null || frameBatch.cursor <= 0)
                    continue;

                frameBatch.SyncBufferData();

                frameLODShader.SetBuffer(frameCSKernelId, InstBuffer, frameBatch.buffer);
                frameLODShader.SetBuffer(frameCSKernelId, LOD0IDBuffer, frameBatch.lodBatchBuffers[0]);
                frameLODShader.SetBuffer(frameCSKernelId, LOD1IDBuffer, frameBatch.lodBatchBuffers[1]);
                frameLODShader.SetBuffer(frameCSKernelId, LOD2IDBuffer, frameBatch.lodBatchBuffers[2]);

                frameBatch.ResetCounters();
                frameLODShader.Dispatch(frameCSKernelId, Mathf.Max(1, Mathf.CeilToInt(frameBatch.cursor / (float)frameCSThreads)), 1, 1);

                ComputeBuffer.CopyCount(frameBatch.lodBatchBuffers[0], frameArgBuffer, (b * 15 + 0 * 5 + 1) * 4);
                ComputeBuffer.CopyCount(frameBatch.lodBatchBuffers[1], frameArgBuffer, (b * 15 + 1 * 5 + 1) * 4);
                ComputeBuffer.CopyCount(frameBatch.lodBatchBuffers[2], frameArgBuffer, (b * 15 + 2 * 5 + 1) * 4);

                for (int i = 0; i < 3; i++)
                {
                    if (shouldRender)
                    {
                        Material mat = i == 2 ? frameBatch.protoMatLOD2 : frameBatch.protoMat;
                        mpb.SetBuffer(InstIndexBuffer, frameBatch.lodBatchBuffers[i]);
                        Graphics.DrawMeshInstancedIndirect(frameBatch.lodMeshes[i], 0, mat,
                            new Bounds(Vector3.zero, new Vector3(300000f, 300000f, 300000f)), frameArgBuffer,
                            (b * 15 + i * 5) * 4, mpb, ShadowCastingMode.Off, false, layer);
                    }
                }
            }
        }
    }
}