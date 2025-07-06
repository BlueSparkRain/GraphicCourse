using System.Collections.Generic;
using UnityEditor.SpeedTree.Importer;
using UnityEngine;

[ExecuteAlways]
public class FinFurController_NonGpuInstancing : MonoBehaviour
{
    private Mesh _cachedHeadMesh;
    private Material mat;
    private Transform _cachedHeadTransform;

    void Start()
    {
     
        _cachedHeadMesh =GetComponent<MeshFilter>()?.sharedMesh;
        mat = GetComponent<MeshRenderer>().sharedMaterial;
        
    }
    
    void Update()
    {
       mat.SetVector("_BaseMove",transform.position);
    }

 
}
