using NUnit.Framework;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public class Fabrik : MonoBehaviour
{
    public List<Joint> joints = new List<Joint>();
    public Transform target; // 添加目标位置（末端节点应到达的位置）

    [Header("IK Settings")]
    public int iterations = 5; // 添加迭代次数
    public float tolerance = 0.01f; // 添加容差
    public float angleLimit = 90f; // 角度限制
    public float smoothing = 0.5f; // 平滑过渡

    private Vector3[] initialDirections;
    private float[] boneLengths;
    private float totalLength;

    void Start()
    {
        InitializeIK();
    }

    void InitializeIK()
    {
        // 初始化骨骼长度和方向
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

        // 设置末端位置
        joints[joints.Count - 1].transform.position = target.position;

        // 多次迭代提高精度
        for (int i = 0; i < iterations; i++)
        {
            FabrikChain();

            // 检查是否达到目标
            if (Vector3.Distance(joints[joints.Count - 1].transform.position, target.position) < tolerance)
                break;
        }
    }

    void FabrikChain()
    {
        // 反向传递：从末端到根节点
        for (int i = joints.Count - 2; i >= 0; i--)
        {
            ApplyConstraint(joints[i], joints[i + 1], i);
        }

        // 正向传递：从根节点到末端
        for (int i = 0; i < joints.Count - 1; i++)
        {
            ApplyConstraint(joints[i], joints[i + 1], i);
        }
    }

    void ApplyConstraint(Joint parent, Joint child, int boneIndex)
    {
        Vector3 targetDir = (child.transform.position - parent.transform.position).normalized;
        Vector3 currentDir = (child.transform.position - parent.transform.position).normalized;

        // 应用角度约束
        Vector3 constrainedDir = ApplyAngleConstraint(parent.transform, currentDir, initialDirections[boneIndex]);

        // 应用平滑过渡
        Vector3 finalDir = Vector3.Slerp(currentDir, constrainedDir, smoothing);

        // 更新子节点位置
        child.transform.position = parent.transform.position + finalDir * boneLengths[boneIndex];
    }

    Vector3 ApplyAngleConstraint(Transform parent, Vector3 currentDir, Vector3 initialDir)
    {
        // 计算当前方向与初始方向的夹角
        float angle = Vector3.Angle(initialDir, currentDir);

        if (angle > angleLimit)
        {
            // 计算旋转轴（初始方向与当前方向的叉积）
            Vector3 axis = Vector3.Cross(initialDir, currentDir);
            if (axis.magnitude < 0.001f) // 避免零向量
                axis = parent.up;

            // 将方向限制在最大角度内
            return Vector3.RotateTowards(initialDir, currentDir, angleLimit * Mathf.Deg2Rad, 0);
        }

        return currentDir;
    }

}