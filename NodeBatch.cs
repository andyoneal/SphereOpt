using System;
using UnityEngine;
using UnityMeshSimplifier;

namespace SphereOpt
{
    public class NodeBatch
    {
        public ComputeBuffer[] lodBatchBuffers;
        public Mesh[] lodMeshes;
        public Material protoMat;
        public ComputeBuffer buffer;
        public int cursor;
        public int capacity;
        public NodeSegment[] nodes;
        public bool isBatchBufferDirty;

        public void SetupMat(Material mat)
        {
            if (protoMat != null)
                return;

            protoMat = UnityEngine.Object.Instantiate(mat);
            protoMat.SetBuffer("_InstBuffer", buffer);
        }

        public void SetupMeshes(Mesh mesh)
        {
            if (lodMeshes != null)
                return;
            
            var meshSimplifier = new MeshSimplifier();
            lodMeshes = new Mesh[3];
            lodMeshes[0] = mesh;

            meshSimplifier.Initialize(mesh);
            var options = SimplificationOptions.Default;
            options.PreserveBorderEdges = true;
            options.PreserveUVFoldoverEdges = true;
            options.PreserveUVSeamEdges = false;
            options.MaxIterationCount = 1000;
            meshSimplifier.SimplificationOptions = options;
            meshSimplifier.SimplifyMesh(0.7f);
            lodMeshes[1] = meshSimplifier.ToMesh();

            meshSimplifier.Initialize(mesh);
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

        public void SyncBufferData()
        {
            if (isBatchBufferDirty && buffer != null)
                buffer.SetData(nodes);

            isBatchBufferDirty = false;
        }

        public void SetBatchBufferDirty()
        {
            isBatchBufferDirty = true;
        }

        public void SetCapacity(int newCap)
        {
            var newArray = new NodeSegment[newCap];
            if (nodes != null) Array.Copy(nodes, newArray, capacity);
            nodes = newArray;
            capacity = newCap;

            buffer?.Release();
            buffer = new ComputeBuffer(capacity, 44);
        }

        public void AddNode(NodeSegment seg)
        {
            if (capacity == 0)
                SetCapacity(32);
            else if (capacity == cursor)
                SetCapacity(capacity * 2);

            nodes[cursor] = seg;
            cursor++;
        }
    }
}