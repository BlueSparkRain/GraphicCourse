using NUnit.Framework;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public class Bone : MonoBehaviour
{
    [Header("骨骼链设置")]
    public List<Joint> joints = new List<Joint>();
    public Transform root; // 根骨骼（可移动的基础）
    public Transform target; // 目标位置（末端骨骼应到达的位置）

    [Header("FABRIK 参数")]
    public int iterations = 10; // 迭代次数
    public float tolerance = 0.01f; // 容差
    public float angleLimit = 90f; // 关节角度限制
    public float smoothing = 0.5f; // 平滑过渡

    private float[] boneLengths; // 骨骼长度
    private float totalLength; // 骨骼链总长度
    private Vector3[] positions; // 骨骼位置缓存
    private Vector3 rootStartPosition; // 根骨骼初始位置

    void Start()
    {
        InitializeFABRIK();
        rootStartPosition = root.position;
    }
    void InitializeFABRIK()
    {
        // 初始化数组
        boneLengths = new float[joints.Count - 1];
        positions = new Vector3[joints.Count];

        // 计算骨骼长度和总长度
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

        // 更新骨骼链
        FabrikChain();

        // 更新骨骼旋转
        UpdateBoneRotations();
    }

    void FabrikChain()
    {
        // 1. 保存当前所有骨骼位置到缓存
        for (int i = 0; i < joints.Count; i++)
        {
            positions[i] = joints[i].transform.position;
        }

        // 2. 检查目标是否可达
        Vector3 rootToTarget = target.position - root.position;
        if (rootToTarget.magnitude > totalLength)
        {
            // 目标不可达，完全伸展骨骼链
            for (int i = 1; i < joints.Count; i++)
            {
                Vector3 direction = rootToTarget.normalized;
                positions[i] = positions[i - 1] + direction * boneLengths[i - 1];
            }
        }
        else
        {
            // 目标可达，执行FABRIK算法
            Vector3 startPosition = positions[0]; // 保存根骨骼初始位置

            // 3. 反向传递：从末端到根骨骼
            positions[joints.Count - 1] = target.position;
            for (int i = joints.Count - 2; i >= 0; i--)
            {
                // 计算方向并应用约束
                Vector3 direction = (positions[i] - positions[i + 1]).normalized;
                positions[i] = positions[i + 1] + direction * boneLengths[i];
            }

            // 4. 正向传递：从根骨骼到末端
            positions[0] = root.position; // 重置根骨骼位置
            for (int i = 0; i < joints.Count - 1; i++)
            {
                // 计算方向并应用约束
                Vector3 direction = (positions[i + 1] - positions[i]).normalized;
                positions[i + 1] = positions[i] + direction * boneLengths[i];

                // 应用角度约束
                ApplyAngleConstraint(i);
            }

            // 5. 多次迭代提高精度
            for (int iter = 0; iter < iterations; iter++)
            {
                // 再次反向传递
                positions[joints.Count - 1] = target.position;
                for (int i = joints.Count - 2; i >= 0; i--)
                {
                    Vector3 direction = (positions[i] - positions[i + 1]).normalized;
                    positions[i] = positions[i + 1] + direction * boneLengths[i];
                }

                // 再次正向传递
                positions[0] = root.position;
                for (int i = 0; i < joints.Count - 1; i++)
                {
                    Vector3 direction = (positions[i + 1] - positions[i]).normalized;
                    positions[i + 1] = positions[i] + direction * boneLengths[i];
                    ApplyAngleConstraint(i);
                }

                // 检查是否达到精度要求
                if (Vector3.Distance(positions[joints.Count - 1], target.position) < tolerance)
                    break;
            }
        }

        // 6. 应用计算后的位置
        for (int i = 0; i < joints.Count; i++)
        {
            joints[i].transform.position = positions[i];
        }
    }

    void ApplyAngleConstraint(int boneIndex)
    {
        if (boneIndex == 0) return; // 根骨骼不应用约束

        Vector3 boneDirection = (positions[boneIndex + 1] - positions[boneIndex]).normalized;
        Vector3 prevBoneDirection = (positions[boneIndex] - positions[boneIndex - 1]).normalized;

        // 计算当前角度
        float angle = Mathf.Abs( Vector3.Angle(prevBoneDirection, boneDirection));

        //if (angle > angleLimit)
        if (angle > joints[boneIndex].angleLimit)
        {
            // 计算旋转轴
            Vector3 rotationAxis = Vector3.Cross(prevBoneDirection, boneDirection).normalized;
            if (rotationAxis.magnitude < 0.01f)
                rotationAxis = Vector3.Cross(prevBoneDirection, Vector3.up).normalized;

            // 计算最大允许方向
            //Quaternion maxRotation = Quaternion.AngleAxis(angleLimit, rotationAxis);
            Quaternion maxRotation = Quaternion.AngleAxis(joints[boneIndex].angleLimit, rotationAxis);
            Vector3 constrainedDirection = maxRotation * prevBoneDirection;

            // 应用约束方向
            positions[boneIndex + 1] = positions[boneIndex] + constrainedDirection * boneLengths[boneIndex];
        }
    }

    void UpdateBoneRotations()
    {
        // 更新所有骨骼的旋转方向
        for (int i = 0; i < joints.Count - 1; i++)
        {
            Vector3 direction = (joints[i + 1].transform.position - joints[i].transform.position).normalized;

            if (i > 0) // 除根骨骼外，保持与上一骨骼的旋转连续性
            {
                Quaternion parentRotation = joints[i - 1].transform.rotation;
                joints[i].transform.rotation = Quaternion.LookRotation(direction, parentRotation * Vector3.up);
            }
            else // 根骨骼使用全局向上向量
            {
                joints[i].transform.rotation = Quaternion.LookRotation(direction);
            }
        }

        // 末端骨骼朝向目标方向

       

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

    // 可视化调试
    void OnDrawGizmos()
    {
        if (joints == null || joints.Count < 2) return;

        // 绘制骨骼链
        Gizmos.color = Color.blue;
        for (int i = 0; i < joints.Count - 1; i++)
        {
            if (joints[i] != null && joints[i + 1] != null)
            {
                Gizmos.DrawLine(joints[i].transform.position, joints[i + 1].transform.position);
            }
        }

        // 绘制目标位置
        if (target != null)
        {
            Gizmos.color = Color.green;
            Gizmos.DrawSphere(target.position, 0.1f);
            Gizmos.DrawLine(joints[joints.Count - 1].transform.position, target.position);
        }

        // 绘制根骨骼位置
        if (root != null)
        {
            Gizmos.color = Color.red;
            Gizmos.DrawSphere(root.position, 0.15f);
        }
    }

}
