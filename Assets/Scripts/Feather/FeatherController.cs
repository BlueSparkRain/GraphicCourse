using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using Random = UnityEngine.Random;

public class FeatherController : MonoBehaviour
{
     public int hairCount = 10000;
    public float sphereRadius = 5f;
    public Material hairMaterial;
    public float hairWidth = 0.02f;
    public float hairHeight = 0.5f;
    
     Mesh hairMesh;
    private Matrix4x4[] matrices;
    private Vector4[] baseColors;
    private MaterialPropertyBlock propertyBlock;

    public Transform sphere;
    Mesh CreateHairStrandMesh(float width, float height) {
        Mesh mesh = new Mesh();
    
        Vector3[] vertices = new Vector3[4] {
            new Vector3(-width/2, 0, 0),
            new Vector3(width/2, 0, 0),
            new Vector3(-width/2, height, 0),
            new Vector3(width/2, height, 0)
        };
    
        Vector2[] uv = new Vector2[4] {
            new Vector2(0, 0),
            new Vector2(1, 0),
            new Vector2(0, 1),
            new Vector2(1, 1)
        };
    
        int[] triangles = new int[6] {
            0, 2, 1,
            1, 2, 3
        };
    
        mesh.vertices = vertices;
        mesh.uv = uv;
        mesh.triangles = triangles;
        mesh.RecalculateNormals();
    
        return mesh;
    }
    
    void Start() {
        // 创建毛发网格
        hairMesh = CreateHairStrandMesh(hairWidth, hairHeight);
        
        // 生成球面点
        List<Vector3> points = GenerateSpherePoints(hairCount, sphereRadius);
        
        // 初始化矩阵和颜色
        matrices = new Matrix4x4[hairCount];
        baseColors = new Vector4[hairCount];
        propertyBlock = new MaterialPropertyBlock();
        
        // 设置毛发位置和方向
        for (int i = 0; i < hairCount; i++) {
            Vector3 position = points[i];
            Vector3 direction = position.normalized;
            
            // 计算旋转（使毛发垂直于球面）
            Quaternion rotation = Quaternion.FromToRotation(Vector3.up, direction);
            
            // 添加随机偏移使毛发更自然
            float randomScale = Random.Range(0.8f, 1.2f);
            Vector3 scale = new Vector3(1, randomScale, 1);
            
            matrices[i] = Matrix4x4.TRS(position, rotation, scale);
            
            // 随机毛发颜色
            baseColors[i] = new Color(
                Random.Range(0.7f, 1.0f),
                Random.Range(0.5f, 0.8f),
                Random.Range(0.3f, 0.6f),
                1
            );
        }
        
        // 设置材质属性块
        propertyBlock.SetVectorArray("_BaseColor", baseColors);
    }
    
    void Update() {
        // 分批次渲染（每批最多1023个实例）
        int batchCount = Mathf.CeilToInt(hairCount / 1023f);
        
        for (int i = 0; i < batchCount; i++) {
            int startIndex = i * 1023;
            int count = Mathf.Min(1023, hairCount - startIndex);
            
            Graphics.DrawMeshInstanced(
                hairMesh, 
                0, 
                hairMaterial, 
                new ArraySegment<Matrix4x4>(matrices, startIndex, count).ToArray(), 
                count, 
                propertyBlock,
                UnityEngine.Rendering.ShadowCastingMode.Off,
                false
            );
        }
    }
    
    List<Vector3> GenerateSpherePoints(int count, float radius) {
        List<Vector3> points = new List<Vector3>();
        float goldenRatio = (1 + Mathf.Sqrt(5)) / 2;
        float angleIncrement = Mathf.PI * 2 * goldenRatio;
    
        for (int i = 0; i < count; i++) {
            float y = 1 - (i / (float)(count - 1)) * 2;
            float radiusAtY = Mathf.Sqrt(1 - y * y);
        
            float theta = angleIncrement * i;
            float x = Mathf.Cos(theta) * radiusAtY;
            float z = Mathf.Sin(theta) * radiusAtY;
        
            Vector3 point = new Vector3(x, y, z) * radius + sphere.position;
            points.Add(point);
        }
    
        return points;
    }
}
