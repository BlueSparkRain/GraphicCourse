using System;
using Unity.VisualScripting;
using UnityEngine;

public class Joint:MonoBehaviour
{
    LineRenderer lineRenderer;
    ///// <summary>
    ///// �ڵ�λ��
    ///// </summary>
    //public Vector3 nodePos;
    /// <summary>
    ///�ڵ�뾶
    /// </summary>
    public float radius;
    /// <summary>
    /// �ڵ����
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
    /// �ڵ��ҵ�
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
    /// �ڵ����ͣ�0��ʾ�����ڵ㣬1��ʾͷ�ڵ㣬2��ʾβ�ڵ㣩
    /// </summary>
    public int nodeType;


    public float angleLimit = 90f; // �ؽڽǶ�����

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

    // ������Ŀ��Ƶ����ɷ���
    Vector3 GenerateControlPoints()
    {
        Vector3 toFather=Vector3.zero;
        Vector3 toSon=Vector3.zero;
        // �������߼��㣺ʹ�ø��ڵ㵽��ǰ�㡢��ǰ�㵽�ӽڵ�ķ���ƽ��ֵ
        if (fatherNode!=null)
        toFather = (fatherNode.transform.position - transform.position).normalized; 
        if(sonNode!=null)
        toSon = (sonNode.transform.position - transform.position).normalized;

        // �������߷���ǰ�����ƽ��ֵ��
        Vector3 tangent = (toSon - toFather).normalized; // ע�������Ǽ���

        float prevDistance=0;
        float nextDistance=0;
        if(fatherNode != null)
        // �����߶γ��ȱ�������
        prevDistance = Vector3.Distance(fatherNode.transform.position, transform.position);

        if(sonNode != null)
        nextDistance = Vector3.Distance(transform.position, sonNode.transform.position);
        
        float lengthFactor = (prevDistance + nextDistance) * 0.25f * tension;

        // ���ɿ��Ƶ㣨�����߷���ƫ�ƣ�
        Vector3 controlPoint = transform.position + tangent * lengthFactor;

        return controlPoint;
    }

    // ����������߻��Ʒ���
    void DrawQuadraticCurve(Vector3 p0, Vector3 p1, Vector3 p2)
    {
        // ȷ��LineRenderer���㹻�Ķ���
        lineRenderer.positionCount = segmentsPerCurve + 1; // �ؼ���+1�����յ�

        for (int i = 0; i <= segmentsPerCurve; i++) // ����0�����ֵ
        {
            float t = i / (float)segmentsPerCurve;
            Vector3 currentPoint = CalculateBezierPoint(t, p0, p1, p2);
            lineRenderer.SetPosition(i, currentPoint);
        }
    }

    Vector3 CalculateBezierPoint(float t, Vector3 p0, Vector3 p1, Vector3 p2)
    {
        // ���α��������߹�ʽ: B(t) = (1-t)^2*P0 + 2*(1-t)*t*P1 + t^2*P2
        float u = 1 - t;
        return u * u * p0 + 2 * u * t * p1 + t * t * p2;
    }

    void RenderLine()
    {
        if (sonNode == null)
            return;

        Vector3 controlPoint = GenerateControlPoints();
        Vector3 p0 = transform.position;
        Vector3 p1 = controlPoint; // �Զ����ɵĿ��Ƶ�
        Vector3 p2 = sonNode.transform.position;

        // ��������
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
