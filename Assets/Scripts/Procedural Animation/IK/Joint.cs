using System;
using Unity.VisualScripting;
using UnityEngine;

public class Joint:MonoBehaviour
{
    LineRenderer lineRenderer;
    ///// <summary>
    ///// 节点位置
    ///// </summary>
    //public Vector3 nodePos;
    /// <summary>
    ///节点半径
    /// </summary>
    public float radius;
    /// <summary>
    /// 节点左点
    /// </summary>
    public Vector3 leftPoint
    {
        get
        {
            return transform.position + radius * Rota(transform.up,90, Vector3.forward);
        }
        private set { }
    }
    Vector3  Rota(Vector3 originalVector, float rotationAngle, Vector3 rotationAxis) 
    {
        Quaternion rotation = Quaternion.AngleAxis(rotationAngle, rotationAxis);
        Vector3 rotatedVector = rotation * originalVector;
        return rotatedVector.normalized;   
    }
    /// <summary>
    /// 节点右点
    /// </summary>
    public Vector3 rightPoint
    {
        get
        {
            return transform.position + radius * Rota(transform.up,90, Vector3.forward);
        }
        private set { }
    }
    /// <summary>
    /// 节点类型（0表示正常节点，1表示头节点，2表示尾节点）
    /// </summary>
    public int nodeType;


    public float angleLimit = 90f; // 关节角度限制

    void OnDrawGizmos()
    {
        Gizmos.color = Color.blue;
        Gizmos.DrawWireSphere(transform.position, radius);

      
    }

  

    public Joint fatherNode;
    public    Joint sonNode;
    [Range(0.1f, 1f)] public float tension = 0.5f;
    public int segmentsPerCurve = 20;
    public bool closeLoop = true;

    private void Start()
    {
        lineRenderer??=GetComponent<LineRenderer>();
        if(lineRenderer)
        lineRenderer.positionCount = segmentsPerCurve;
    }

    private void Update()
    {
        //UpdateScale();
        RenderLine();
    }

    // 修正后的控制点生成方法
    Vector3 GenerateControlPoints()
    {
        Vector3 toFather=Vector3.zero;
        Vector3 toSon=Vector3.zero;
        // 修正切线计算：使用父节点到当前点、当前点到子节点的方向平均值
        if (fatherNode!=null)
        toFather = (fatherNode.transform.position - transform.position).normalized; 
        if(sonNode!=null)
        toSon = (sonNode.transform.position - transform.position).normalized;

        // 计算切线方向（前后方向的平均值）
        Vector3 tangent = (toSon - toFather).normalized; // 注意这里是减法

        float prevDistance=0;
        float nextDistance=0;
        if(fatherNode != null)
        // 计算线段长度比例因子
        prevDistance = Vector3.Distance(fatherNode.transform.position, transform.position);

        if(sonNode != null)
        nextDistance = Vector3.Distance(transform.position, sonNode.transform.position);
        
        float lengthFactor = (prevDistance + nextDistance) * 0.25f * tension;

        // 生成控制点（沿切线方向偏移）
        Vector3 controlPoint = transform.position + tangent * lengthFactor;

        return controlPoint;
    }

    // 修正后的曲线绘制方法
    void DrawQuadraticCurve(Vector3 p0, Vector3 p1, Vector3 p2)
    {
        // 确保LineRenderer有足够的顶点
        lineRenderer.positionCount = segmentsPerCurve + 1; // 关键：+1包含终点

        for (int i = 0; i <= segmentsPerCurve; i++) // 包含0和最大值
        {
            float t = i / (float)segmentsPerCurve;
            Vector3 currentPoint = CalculateBezierPoint(t, p0, p1, p2);
            lineRenderer.SetPosition(i, currentPoint);
        }
    }

    Vector3 CalculateBezierPoint(float t, Vector3 p0, Vector3 p1, Vector3 p2)
    {
        // 二次贝塞尔曲线公式: B(t) = (1-t)^2*P0 + 2*(1-t)*t*P1 + t^2*P2
        float u = 1 - t;
        return u * u * p0 + 2 * u * t * p1 + t * t * p2;
    }

    void RenderLine()
    {
        if (sonNode == null)
            return;

        Vector3 controlPoint = GenerateControlPoints();
        Vector3 p0 = transform.position;
        Vector3 p1 = controlPoint; // 自动生成的控制点
        Vector3 p2 = sonNode.transform.position;

        // 绘制曲线
        DrawQuadraticCurve(p0, p1, p2);

        if(fatherNode!=null)
        lineRenderer.startWidth =fatherNode.radius;
        else
        lineRenderer.startWidth = 0.2f;

        //if(sonNode!=null)
        //lineRenderer.endWidth =sonNode.radius;
        //else
        lineRenderer.endWidth=radius;


    }
}
