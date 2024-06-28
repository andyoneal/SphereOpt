using System;
using UnityEngine;
using UnityMeshSimplifier;

namespace SphereOpt
{
    public class FrameBatch
    {
        public FrameSegment[] segs;
        public ComputeBuffer buffer;
        public int cursor;
        public int capacity;
        public bool isBatchBufferDirty;
        public ComputeBuffer[] lodBatchBuffers;
        public Material protoMat;
        public Material protoMatLOD2;
        public Mesh[] lodMeshes;
        public MaterialPropertyBlock mpb;

        public void AddSegment(FrameSegment seg)
        {
            if (capacity == 0)
                SetCapacity(32);
            else if (capacity == cursor)
                SetCapacity(capacity * 2);

            segs[cursor] = seg;
            cursor++;
        }

        public void ClearSegments()
        {
            cursor = 0;
        }

        public void SetCapacity(int newCap)
        {
            var newArray = new FrameSegment[newCap];
            if (segs != null)
                Array.Copy(segs, newArray, capacity);
            segs = newArray;
            capacity = newCap;

            buffer?.Release();
            buffer = new ComputeBuffer(capacity, 32);
            protoMat.SetBuffer("_InstBuffer", buffer);

            for (int i = 0; i < 3; i++)
            {
                lodBatchBuffers[i]?.Release();
                lodBatchBuffers[i] = new ComputeBuffer(capacity, 4, ComputeBufferType.Append);
            }
        }

        public void SyncBufferData()
        {
            if (isBatchBufferDirty && buffer != null)
                buffer.SetData(segs);

            isBatchBufferDirty = false;
        }

        public void SetBatchBufferDirty()
        {
            isBatchBufferDirty = true;
        }

        public void Free()
        {
            if (buffer != null)
            {
                buffer.Release();
                buffer = null;
            }

            segs = null;
            cursor = capacity = 0;
        }

        public void SetupMat(Material mat)
        {
            if (protoMat != null)
                return;

            protoMat = UnityEngine.Object.Instantiate(mat);
            CustomShaderManager.ReplaceShaderIfAvailable(protoMat);
            protoMat.SetBuffer("_InstBuffer", buffer);

            protoMatLOD2 = UnityEngine.Object.Instantiate(mat);
            CustomShaderManager.ApplyCustomShaderToMaterial(mat, "instFrameLOD2");
            protoMatLOD2.SetBuffer("_InstBuffer", buffer);
        }

        public void SetupMeshes(Mesh mesh)
        {
            if (lodMeshes != null)
                return;

            lodMeshes = new Mesh[3];
            lodMeshes[0] = UnityEngine.Object.Instantiate(mesh);
            lodMeshes[1] = UnityEngine.Object.Instantiate(mesh);
            lodMeshes[2] = UnityEngine.Object.Instantiate(mesh);

            var options = SimplificationOptions.Default;
            options.PreserveBorderEdges = true;
            options.PreserveUVFoldoverEdges = true;
            options.MaxIterationCount = 1000;

            var meshSimplifier = new MeshSimplifier();
            meshSimplifier.Initialize(lodMeshes[1]);
            meshSimplifier.SimplificationOptions = options;
            meshSimplifier.SimplifyMesh(0.7f);
            lodMeshes[1] = meshSimplifier.ToMesh();

            meshSimplifier = new MeshSimplifier();
            meshSimplifier.Initialize(lodMeshes[2]);
            meshSimplifier.SimplificationOptions = options;
            meshSimplifier.SimplifyMesh(0.2f);
            lodMeshes[2] = meshSimplifier.ToMesh();
        }

        public void ResetCounters()
        {
            lodBatchBuffers[0].SetCounterValue(0u);
            lodBatchBuffers[1].SetCounterValue(0u);
            lodBatchBuffers[2].SetCounterValue(0u);
        }
    }
}