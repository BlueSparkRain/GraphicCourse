using UnityEngine;
using UnityEngine.Rendering;
[ExecuteAlways]
public class ShellFurController_DrawInstancedIndirect : MonoBehaviour
{
    [Header("壳层数（动态可调）")] 
    public int shellCount = 32;

    private Mesh mesh;
    private Material material;

    private ComputeBuffer argsBuffer;
    private ComputeBuffer shellIndexBuffer;

    private int lastShellCount = -1;

    private Camera mainCam;

    void Start()
    {
        mesh = GetComponent<MeshFilter>().sharedMesh;
        material = GetComponent<MeshRenderer>().sharedMaterial;
        mainCam = Camera.main;
        InitBuffers(); // 初次初始化
    }

    void Update()
    {
        /*Camera cam = Camera.current;
        if (!Application.isPlaying && UnityEditor.SceneView.currentDrawingSceneView != null)
            cam = UnityEditor.SceneView.currentDrawingSceneView.camera;*/
        
        
        if (shellCount != lastShellCount || argsBuffer == null || shellIndexBuffer == null)
        {
            InitBuffers();
            lastShellCount = shellCount;
        }

        Graphics.DrawMeshInstancedIndirect(
            mesh,
            0,
            material,
            new Bounds(transform.position, Vector3.one * 100f),
            argsBuffer,
            0,
            null,
            ShadowCastingMode.On,
            true,
            gameObject.layer,
            mainCam,//这里绑的是Game窗口里的主相机，只会在Game窗口中渲染，场景视图中会不渲染，可以替换成上方的Scene窗口里的cam
            LightProbeUsage.Off
        );
    }


    void InitBuffers()
    {
        // 清理旧 buffer
        argsBuffer?.Release();
        shellIndexBuffer?.Release();

        // 初始化 mesh/material
        mesh ??= GetComponent<MeshFilter>().sharedMesh; 
        material ??= GetComponent<MeshRenderer>().sharedMaterial;

        // 创建 DrawMeshInstancedIndirect 参数 buffer
        uint[] args = new uint[5] {
            (uint)mesh.GetIndexCount(0),
            (uint)shellCount,
            (uint)mesh.GetIndexStart(0),
            (uint)mesh.GetBaseVertex(0),
            0
        };
        argsBuffer = new ComputeBuffer(1, args.Length * sizeof(uint), ComputeBufferType.IndirectArguments);
        argsBuffer.SetData(args);

        // 创建 shell index buffer，传给 Shader
        float[] shellIndices = new float[shellCount];
        for (int i = 0; i < shellCount; i++)
            shellIndices[i] = i;

        shellIndexBuffer = new ComputeBuffer(shellCount, sizeof(float));
        shellIndexBuffer.SetData(shellIndices);

        // 设置材质参数
        material.SetBuffer("_ShellIndexBuffer", shellIndexBuffer);
        material.SetInt("_ShellCount", shellCount);
    }

    void OnDisable()
    {
        argsBuffer?.Release();
        shellIndexBuffer?.Release();
        argsBuffer = null;
        shellIndexBuffer = null;
    }

#if UNITY_EDITOR
    void OnValidate()
    {
        lastShellCount = -1; // 强制重建 buffer
    }
#endif
}
