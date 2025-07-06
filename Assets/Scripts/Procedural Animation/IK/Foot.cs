using UnityEngine;
using static UnityEngine.UI.Image;

public class Foot : MonoBehaviour
{
    public float groundCheckDistance;
    public LayerMask whatIsGround;
    public bool usGrounded;

    Transform ground;
     void GroundCheck() 
    {
        Ray ray = new Ray(transform.parent.position, Vector3.down);
        RaycastHit hit;
        if (Physics.Raycast(ray, out hit, groundCheckDistance, whatIsGround))
        {
            usGrounded = true;
            ground=hit.collider.transform;
        }
        else
        {
            ground = null;
            usGrounded = false;
        }//return Physics.Raycast(transform.position, Vector3.down, groundCheckDistance, whatIsGround);
    }

    private void OnDrawGizmos()
    {
        Gizmos.color = Color.red;
        Gizmos.DrawLine(transform.parent.position,transform.parent. position+Vector3.down*groundCheckDistance);
    }

    private void Update()
    {
        GroundCheck();
        if (usGrounded && ground)
        {
            transform.forward = Vector3.up;
            transform.position = new Vector3(transform.position.x, ground.position.y + 0.5f, transform.position.z);
        }
    }


}
