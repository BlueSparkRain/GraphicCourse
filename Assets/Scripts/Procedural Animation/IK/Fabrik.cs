using NUnit.Framework;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public class Fabrik : MonoBehaviour
{
    public List<Joint> joints = new List<Joint>();
    public Transform target; // ���Ŀ��λ�ã�ĩ�˽ڵ�Ӧ�����λ�ã�

    [Header("IK Settings")]
    public int iterations = 5; // ��ӵ�������
    public float tolerance = 0.01f; // ����ݲ�
    public float angleLimit = 90f; // �Ƕ�����
    public float smoothing = 0.5f; // ƽ������

    private Vector3[] initialDirections;
    private float[] boneLengths;
    private float totalLength;

    void Start()
    {
        InitializeIK();
    }

    void InitializeIK()
    {
        // ��ʼ���������Ⱥͷ���
        boneLengths = new float[joints.Count - 1];
        initialDirections = new Vector3[joints.Count - 1];
        totalLength = 0;

        for (int i = 0; i < joints.Count - 1; i++)
        {
            boneLengths[i] = Vector3.Distance(joints[i].transform.position, joints[i + 1].transform.position);
            initialDirections[i] = (joints[i + 1].transform.position - joints[i].transform.position).normalized;
            totalLength += boneLengths[i];
        }
    }

    void Update()
    {
        if (joints.Count == 0) return;

        // ����ĩ��λ��
        joints[joints.Count - 1].transform.position = target.position;

        // ��ε�����߾���
        for (int i = 0; i < iterations; i++)
        {
            FabrikChain();

            // ����Ƿ�ﵽĿ��
            if (Vector3.Distance(joints[joints.Count - 1].transform.position, target.position) < tolerance)
                break;
        }
    }

    void FabrikChain()
    {
        // ���򴫵ݣ���ĩ�˵����ڵ�
        for (int i = joints.Count - 2; i >= 0; i--)
        {
            ApplyConstraint(joints[i], joints[i + 1], i);
        }

        // ���򴫵ݣ��Ӹ��ڵ㵽ĩ��
        for (int i = 0; i < joints.Count - 1; i++)
        {
            ApplyConstraint(joints[i], joints[i + 1], i);
        }
    }

    void ApplyConstraint(Joint parent, Joint child, int boneIndex)
    {
        Vector3 targetDir = (child.transform.position - parent.transform.position).normalized;
        Vector3 currentDir = (child.transform.position - parent.transform.position).normalized;

        // Ӧ�ýǶ�Լ��
        Vector3 constrainedDir = ApplyAngleConstraint(parent.transform, currentDir, initialDirections[boneIndex]);

        // Ӧ��ƽ������
        Vector3 finalDir = Vector3.Slerp(currentDir, constrainedDir, smoothing);

        // �����ӽڵ�λ��
        child.transform.position = parent.transform.position + finalDir * boneLengths[boneIndex];
    }

    Vector3 ApplyAngleConstraint(Transform parent, Vector3 currentDir, Vector3 initialDir)
    {
        // ���㵱ǰ�������ʼ����ļн�
        float angle = Vector3.Angle(initialDir, currentDir);

        if (angle > angleLimit)
        {
            // ������ת�ᣨ��ʼ�����뵱ǰ����Ĳ����
            Vector3 axis = Vector3.Cross(initialDir, currentDir);
            if (axis.magnitude < 0.001f) // ����������
                axis = parent.up;

            // ���������������Ƕ���
            return Vector3.RotateTowards(initialDir, currentDir, angleLimit * Mathf.Deg2Rad, 0);
        }

        return currentDir;
    }

}