using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Sirenix.OdinInspector;

[RequireComponent(typeof(Rigidbody))]
public class CharacterMovement : MonoBehaviour
{
    #region INSPECTOR

    #region JUMP
    //===========================================================================================================================
    [HideInInspector] public int jumpAmount;
    [HideInInspector] public float jumpForce;
    int jumpInt;
    //===========================================================================================================================
    #endregion

    #region GRAVITY
    //===========================================================================================================================
    [HideInInspector] public float gravityScale;
    //===========================================================================================================================
    #endregion

    #region ADJUST AMOUNT ON GROUND OR AIR
    //===========================================================================================================================
    [HideInInspector] public float groundDrag;
    [HideInInspector] public float airDrag;
    [HideInInspector] public float airMultiplier;
    [HideInInspector] float movementMultiplier = 1f;
    //===========================================================================================================================
    #endregion

    #region GROUND CHECK
    //===========================================================================================================================
    [SerializeField] public Transform groundCheck;
    [SerializeField] LayerMask groundMask;
    [SerializeField] public float groundDistance = 0.2f;
    public bool isGrounded { get; private set; }
    //===========================================================================================================================
    #endregion

    #region SLOPE
    //===========================================================================================================================
    float playerHeight = 2f;
    Vector3 slopeMoveDirection;
    RaycastHit slopeHit;
    //===========================================================================================================================
    #endregion

    #region RIGIDBODY
    //===========================================================================================================================
    Rigidbody rb;
    public Vector3 rbVelocity { get; private set; }
    //===========================================================================================================================
    #endregion

    #endregion

    private void Start()
    {
        rb = GetComponent<Rigidbody>();
        rb.freezeRotation = true;

        SetPosition(transform.position);
    }

    public void SetPosition(Vector3 pos)
    {
        transform.position = pos;
    }

    public void Move(Vector3 moveDirection, float moveSpeed, float rotationSpeed, Transform orientation)
    {
        #region GROUNDED FUNCTION
        //===========================================================================================================================
        isGrounded = Physics.CheckSphere(groundCheck.position, groundDistance, groundMask);
        //===========================================================================================================================
        #endregion

        #region DRAG FUNCTION
        //===========================================================================================================================
        rb.drag = isGrounded ? groundDrag : airDrag;
        //===========================================================================================================================
        #endregion

        if (isGrounded) { jumpInt = 0; };

        #region GRAVITY FUNCTION
        //===========================================================================================================================
        if (!isGrounded)
        {
            // Increase the downward velocity (effectively increasing gravity)
            rb.velocity += Vector3.down * gravityScale * Time.fixedDeltaTime;
        }
        //===========================================================================================================================
        #endregion

        #region SLOPE FUNCTION
        //===========================================================================================================================
        slopeMoveDirection = Vector3.ProjectOnPlane(moveDirection, slopeHit.normal);
        //===========================================================================================================================
        #endregion

        #region MOVEMENT FUNCTION
        //===========================================================================================================================
        if (isGrounded && !OnSlope())
        {
            rb.useGravity = true;
            rb.AddForce(moveDirection.normalized * moveSpeed * movementMultiplier, ForceMode.Acceleration);
        }
        else if (isGrounded && OnSlope())
        {
            rb.useGravity = false;
            rb.AddForce(slopeMoveDirection.normalized * moveSpeed * movementMultiplier, ForceMode.Acceleration);
        }
        else if (!isGrounded)
        {
            rb.useGravity = true;
            rb.AddForce(moveDirection.normalized * moveSpeed * movementMultiplier * airMultiplier, ForceMode.Acceleration);
        }

        rbVelocity = rb.velocity;
        //===========================================================================================================================
        #endregion

        #region ROTATION FUNCTION
        //===========================================================================================================================
        if (moveDirection != Vector3.zero)
        {
            Quaternion toRotation = Quaternion.LookRotation(moveDirection, Vector3.up);
            orientation.transform.rotation = Quaternion.RotateTowards(orientation.transform.rotation, toRotation, rotationSpeed * Time.deltaTime);
        }
        //===========================================================================================================================
        #endregion
    }

    public void Jump(bool up)
    {
        #region JUMP FUNCTION
        //===========================================================================================================================
        rb.velocity = new Vector3(rb.velocity.x, 0, rb.velocity.z);
        rb.AddForce((up ? transform.up : -transform.up) * jumpForce, ForceMode.Impulse);
        jumpInt++;

        if (jumpInt < (jumpAmount - 1))
        {

        }
        //===========================================================================================================================
        #endregion
    }

    public void JumpMax()
    {
        jumpInt = jumpAmount - 1;
    }

    bool OnSlope()
    {
        if (Physics.Raycast(transform.position, Vector3.down, out slopeHit, playerHeight / 2 + 0.5f))
        { if (slopeHit.normal != Vector3.up) { return true; } else { return false; } } return false;
    }

    void OnDrawGizmos()
    {
        Gizmos.DrawWireSphere(groundCheck.position, groundDistance);
    }
}
