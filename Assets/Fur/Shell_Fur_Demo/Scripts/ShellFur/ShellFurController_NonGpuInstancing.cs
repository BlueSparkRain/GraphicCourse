using UnityEngine;
using UnityEngine.Rendering;

[RequireComponent((typeof(MeshRenderer)))]
[ExecuteAlways]
public class ShellFurController_NonGpuInstancing : MonoBehaviour
{
     Mesh mesh;
     Material material;
    public int shellCount = 16;

    private Matrix4x4[] matrices;
    private MaterialPropertyBlock[] props;

    void Start()
    {
        //不调用 .material，这会创建一个新实例，破坏 GPU Instancing
        material = GetComponent<MeshRenderer>().sharedMaterial;

        if (!material.enableInstancing)
        {
            Debug.LogWarning("Fur material must enable GPU Instancing");
        }

        mesh = GetComponent<MeshFilter>().sharedMesh;
        matrices = new Matrix4x4[shellCount];
        props = new MaterialPropertyBlock[shellCount];

        for (int i = 0; i < shellCount; i++)
        {
            matrices[i] = transform.localToWorldMatrix;
            Debug.Log(matrices[i]);
            props[i] = new MaterialPropertyBlock();
            props[i].SetFloat("_ShellIndex", i);
        }
    }

    void Update()
    {
        for (int i = 0; i < shellCount; i++)
        {
            matrices[i] = transform.localToWorldMatrix;
            props[i] = new MaterialPropertyBlock();
            props[i].SetFloat("_ShellIndex", i);
        }
        
        for (int i = 0; i < shellCount; i++)
        {
            Graphics.DrawMesh(
                mesh,
                matrices[i],
                material,           
                0,
                null,
                0,
                props[i],          
                UnityEngine.Rendering.ShadowCastingMode.Off,
                false
            );
        }
    }
}
