using System;
using System.Collections.Generic;
using Unity.VisualScripting;
using UnityEngine;

[ExecuteAlways]
public class CreatureBody : MonoBehaviour
{
    public List<Joint> body = new List<Joint>();


    private void Awake()
    {
        String.Compare("a", "Body");
        for (int i = 0; i < body.Count; i++)
        {
            if (i > 0) 
            {
                body[i].fatherNode = body[i - 1];
            }
            if(i<body.Count-1)
            {
                body[i].sonNode = body[i + 1];
            }            
        }
    }
    [Header("�Ƕ�����")]
    public float angle = 120;

    /// <summary>
    /// �������ƣ������ڵ㽫�����ڵ�����������İ뾶�����
    /// </summary>
    /// <param name="active">�����ڵ�</param>
    /// <param name="passive">�����ڵ�</param>
    void DistanceConstruct(Joint active, Joint passive)
    {
        Vector3 dir = (passive.transform.position - active.transform.position).normalized;

        if(Mathf.Abs( Vector3.Angle(active.transform.forward,dir)) <angle)
        {
            Vector3 crossProduct=Vector3.Cross(active.transform.forward,dir).normalized;
            Quaternion rot = Quaternion.AngleAxis(angle,crossProduct);

            dir=(rot*active.transform.forward).normalized;
        }
        passive.transform.position = active.transform.position + active.radius * dir;
        passive.transform.LookAt(active.transform);
    }


    void UpdateBody()
    {
        //body[0].transform.position=Input.mousePosition;
        for (int i = 0; i < body.Count; i++)
        {
            if (i +1 < body.Count)
                DistanceConstruct(body[i], body[i + 1]);
        }

    }

    private void Update()
    {
        UpdateBody();
        //RenderLine();

    }

  

    [Header("Gizoms")]
    [Range(0.1f, 1f)] public float tension = 0.5f;
    public int segmentsPerCurve = 20;
    public bool closeLoop = true;

    public AnimationCurve curve;
    void OnDrawGizmos()
    {
        if (body.Count < 2) return;

        List<Vector3> spineList= new List<Vector3>();
        for (int i = 0; i < body.Count; i++)
        {
            spineList.Add(body[i].transform.position);
        }

        Vector3[] controlPoints = GenerateControlPoints(spineList);

        for (int i = 0; i < body.Count; i++)
        {
            int nextIndex = (i + 1)% body.Count;

            if (!closeLoop && i == body.Count - 1) break;

            Vector3 p0 = body[i].transform.position;
            Vector3 p1 = controlPoints[i]; // �Զ����ɵĿ��Ƶ�
            Vector3 p2 = body[nextIndex].transform.position;

            // ��������
            DrawQuadraticCurve(p0, p1, p2);
        }
    }


    Vector3[] GenerateControlPoints(List<Vector3> pointList)
    {
        Vector3[] controlPoints = new Vector3[pointList.Count];

        for (int i = 0; i < body.Count; i++)
        {
            int prevIndex = (i - 1 + pointList.Count) % pointList.Count;
            int nextIndex = (i + 1) % pointList.Count;

            // �������߷���ǰ���������ƽ��ֵ��
            Vector3 tangent = (pointList[nextIndex] - pointList[prevIndex]).normalized;

            // �����߶γ��ȱ�������
            float prevDistance = Vector3.Distance(pointList[prevIndex], pointList[i]);
            float nextDistance = Vector3.Distance(pointList[i], pointList[nextIndex]);
            float lengthFactor = (prevDistance + nextDistance) * 0.25f * tension;

            // ���ɿ��Ƶ㣨�����߷���ƫ�ƣ�
            controlPoints[i] = pointList[i]+ tangent * lengthFactor;
        }

        return controlPoints;
    }

    void DrawQuadraticCurve(Vector3 p0, Vector3 p1, Vector3 p2)
    {
        Vector3 prevPoint = p0;

        for (int i = 1; i <= segmentsPerCurve; i++)
        {
            float t = i / (float)segmentsPerCurve;
            Vector3 currentPoint = CalculateBezierPoint(t, p0, p1, p2);

            Gizmos.DrawLine(prevPoint, currentPoint);
            prevPoint = currentPoint;
        }
    }

    Vector3 CalculateBezierPoint(float t, Vector3 p0, Vector3 p1, Vector3 p2)
    {
        // ���α��������߹�ʽ: B(t) = (1-t)^2*P0 + 2*(1-t)*t*P1 + t^2*P2
        float u = 1 - t;
        return u * u * p0 + 2 * u * t * p1 + t * t * p2;
    }


}
