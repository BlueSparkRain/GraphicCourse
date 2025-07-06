using UnityEngine;

public class MoveControl : MonoBehaviour
{
    public enum MovementPlane { XOY, YOZ, XOZ }

    [Header("Movement Settings")]
    public MovementPlane movementPlane = MovementPlane.XOY;
    public float moveSpeed = 5f;
    public float rotationSpeed = 180f;

    void Update()
    {
        HandleMovement();
        HandleRotation();
    }

    void HandleMovement()
    {
        float horizontal = Input.GetAxis("Horizontal");
        float vertical = Input.GetAxis("Vertical");

        Vector3 moveDirection = GetPlaneDirection(horizontal, vertical);
        transform.Translate(moveDirection * moveSpeed * Time.deltaTime, Space.World);
    }

    Vector3 GetPlaneDirection(float horizontal, float vertical)
    {
        switch (movementPlane)
        {
            case MovementPlane.YOZ:
                return new Vector3(0, vertical, horizontal);
            case MovementPlane.XOZ:
                return new Vector3(horizontal, 0, vertical);
            default: // XOY
                return new Vector3(horizontal, vertical, 0);
        }
    }

    void HandleRotation()
    {
        float rotateH = InputManager.Instance.rotInput.x;// Input.GetAxis("RotateHorizontal");
        float rotateV = InputManager.Instance.rotInput.x;// Input.GetAxis("RotateVertical");

        Vector3 rotation = GetPlaneRotation(rotateH, rotateV);
        transform.Rotate(rotation * rotationSpeed * Time.deltaTime);
    }

    Vector3 GetPlaneRotation(float horizontal, float vertical)
    {
        switch (movementPlane)
        {
            case MovementPlane.YOZ:
                return new Vector3(0, horizontal, vertical);
            case MovementPlane.XOZ:
                return new Vector3(vertical, horizontal, 0);
            default: // XOY
                return new Vector3(0, 0, horizontal);
        }
    }
}
