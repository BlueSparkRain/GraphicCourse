using NUnit.Framework;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public class Bone : MonoBehaviour
{
    [Header("����������")]
    public List<Joint> joints = new List<Joint>();
    public Transform root; // �����������ƶ��Ļ�����
    public Transform target; // Ŀ��λ�ã�ĩ�˹���Ӧ�����λ�ã�

    [Header("FABRIK ����")]
    public int iterations = 10; // ��������
    public float tolerance = 0.01f; // �ݲ�
    public float angleLimit = 90f; // �ؽڽǶ�����
    public float smoothing = 0.5f; // ƽ������

    private float[] boneLengths; // ��������
    private float totalLength; // �������ܳ���
    private Vector3[] positions; // ����λ�û���
    private Vector3 rootStartPosition; // ��������ʼλ��

    void Start()
    {
        InitializeFABRIK();
        rootStartPosition = root.position;
    }
    void InitializeFABRIK()
    {
        // ��ʼ������
        boneLengths = new float[joints.Count - 1];
        positions = new Vector3[joints.Count];

        // ����������Ⱥ��ܳ���
        totalLength = 0;
        for (int i = 0; i < joints.Count - 1; i++)
        {
            boneLengths[i] = Vector3.Distance(
                joints[i].transform.position,
                joints[i + 1].transform.position
            );
            totalLength += boneLengths[i];
        }
    }

    void Update()
    {
        if (target == null || root == null || joints.Count < 2) return;

        // ���¹�����
        FabrikChain();

        // ���¹�����ת
        UpdateBoneRotations();
    }

    void FabrikChain()
    {
        // 1. ���浱ǰ���й���λ�õ�����
        for (int i = 0; i < joints.Count; i++)
        {
            positions[i] = joints[i].transform.position;
        }

        // 2. ���Ŀ���Ƿ�ɴ�
        Vector3 rootToTarget = target.position - root.position;
        if (rootToTarget.magnitude > totalLength)
        {
            // Ŀ�겻�ɴ��ȫ��չ������
            for (int i = 1; i < joints.Count; i++)
            {
                Vector3 direction = rootToTarget.normalized;
                positions[i] = positions[i - 1] + direction * boneLengths[i - 1];
            }
        }
        else
        {
            // Ŀ��ɴִ��FABRIK�㷨
            Vector3 startPosition = positions[0]; // �����������ʼλ��

            // 3. ���򴫵ݣ���ĩ�˵�������
            positions[joints.Count - 1] = target.position;
            for (int i = joints.Count - 2; i >= 0; i--)
            {
                // ���㷽��Ӧ��Լ��
                Vector3 direction = (positions[i] - positions[i + 1]).normalized;
                positions[i] = positions[i + 1] + direction * boneLengths[i];
            }

            // 4. ���򴫵ݣ��Ӹ�������ĩ��
            positions[0] = root.position; // ���ø�����λ��
            for (int i = 0; i < joints.Count - 1; i++)
            {
                // ���㷽��Ӧ��Լ��
                Vector3 direction = (positions[i + 1] - positions[i]).normalized;
                positions[i + 1] = positions[i] + direction * boneLengths[i];

                // Ӧ�ýǶ�Լ��
                ApplyAngleConstraint(i);
            }

            // 5. ��ε�����߾���
            for (int iter = 0; iter < iterations; iter++)
            {
                // �ٴη��򴫵�
                positions[joints.Count - 1] = target.position;
                for (int i = joints.Count - 2; i >= 0; i--)
                {
                    Vector3 direction = (positions[i] - positions[i + 1]).normalized;
                    positions[i] = positions[i + 1] + direction * boneLengths[i];
                }

                // �ٴ����򴫵�
                positions[0] = root.position;
                for (int i = 0; i < joints.Count - 1; i++)
                {
                    Vector3 direction = (positions[i + 1] - positions[i]).normalized;
                    positions[i + 1] = positions[i] + direction * boneLengths[i];
                    ApplyAngleConstraint(i);
                }

                // ����Ƿ�ﵽ����Ҫ��
                if (Vector3.Distance(positions[joints.Count - 1], target.position) < tolerance)
                    break;
            }
        }

        // 6. Ӧ�ü�����λ��
        for (int i = 0; i < joints.Count; i++)
        {
            joints[i].transform.position = positions[i];
        }
    }

    void ApplyAngleConstraint(int boneIndex)
    {
        if (boneIndex == 0) return; // ��������Ӧ��Լ��

        Vector3 boneDirection = (positions[boneIndex + 1] - positions[boneIndex]).normalized;
        Vector3 prevBoneDirection = (positions[boneIndex] - positions[boneIndex - 1]).normalized;

        // ���㵱ǰ�Ƕ�
        float angle = Mathf.Abs( Vector3.Angle(prevBoneDirection, boneDirection));

        //if (angle > angleLimit)
        if (angle > joints[boneIndex].angleLimit)
        {
            // ������ת��
            Vector3 rotationAxis = Vector3.Cross(prevBoneDirection, boneDirection).normalized;
            if (rotationAxis.magnitude < 0.01f)
                rotationAxis = Vector3.Cross(prevBoneDirection, Vector3.up).normalized;

            // �������������
            //Quaternion maxRotation = Quaternion.AngleAxis(angleLimit, rotationAxis);
            Quaternion maxRotation = Quaternion.AngleAxis(joints[boneIndex].angleLimit, rotationAxis);
            Vector3 constrainedDirection = maxRotation * prevBoneDirection;

            // Ӧ��Լ������
            positions[boneIndex + 1] = positions[boneIndex] + constrainedDirection * boneLengths[boneIndex];
        }
    }

    void UpdateBoneRotations()
    {
        // �������й�������ת����
        for (int i = 0; i < joints.Count - 1; i++)
        {
            Vector3 direction = (joints[i + 1].transform.position - joints[i].transform.position).normalized;

            if (i > 0) // ���������⣬��������һ��������ת������
            {
                Quaternion parentRotation = joints[i - 1].transform.rotation;
                joints[i].transform.rotation = Quaternion.LookRotation(direction, parentRotation * Vector3.up);
            }
            else // ������ʹ��ȫ����������
            {
                joints[i].transform.rotation = Quaternion.LookRotation(direction);
            }
        }

        // ĩ�˹�������Ŀ�귽��

       

     if (joints.Count > 1)
     {
        int lastIndex = joints.Count - 1;
        Vector3 endDirection = (target.position - joints[lastIndex].transform.position).normalized;
        if (endDirection.magnitude > 0.01f)
        {
            joints[lastIndex].transform.rotation = Quaternion.LookRotation(endDirection);
        }
     }
        
    }

    // ���ӻ�����
    void OnDrawGizmos()
    {
        if (joints == null || joints.Count < 2) return;

        // ���ƹ�����
        Gizmos.color = Color.blue;
        for (int i = 0; i < joints.Count - 1; i++)
        {
            if (joints[i] != null && joints[i + 1] != null)
            {
                Gizmos.DrawLine(joints[i].transform.position, joints[i + 1].transform.position);
            }
        }

        // ����Ŀ��λ��
        if (target != null)
        {
            Gizmos.color = Color.green;
            Gizmos.DrawSphere(target.position, 0.1f);
            Gizmos.DrawLine(joints[joints.Count - 1].transform.position, target.position);
        }

        // ���Ƹ�����λ��
        if (root != null)
        {
            Gizmos.color = Color.red;
            Gizmos.DrawSphere(root.position, 0.15f);
        }
    }

}
