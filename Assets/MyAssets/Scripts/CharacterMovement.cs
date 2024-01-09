using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Sirenix.OdinInspector;

public class CharacterMovement : MonoBehaviour
{
    #region INSPECTOR
    float playerHeight = 2f;

    [SerializeField] Transform orientation;

    [FoldoutGroup("Character Controls")]
    [BoxGroup("Character Controls/Box1", ShowLabel = false)]
    [Header("Movement")]
    [SerializeField] float moveSpeed = 6f;
    [FoldoutGroup("Character Controls")]
    [BoxGroup("Character Controls/Box1", ShowLabel = false)]
    [SerializeField] float rotationSpeed = 500f;
    [FoldoutGroup("Character Controls")]
    [BoxGroup("Character Controls/Box1", ShowLabel = false)]
    [SerializeField] float airMultiplier = 0.4f;
    float movementMultiplier = 10f;

    [FoldoutGroup("Character Controls")]
    [Header("Sprinting")]
    [SerializeField] float walkSpeed = 4f;
    [FoldoutGroup("Character Controls")]
    [SerializeField] float sprintSpeed = 6f;
    [FoldoutGroup("Character Controls")]
    [SerializeField] float acceleration = 10f;

    [FoldoutGroup("Character Controls")]
    [Header("Jumping")]
    public int jumpAmount;
    [FoldoutGroup("Character Controls")]
    public float jumpForce = 5f;
    [FoldoutGroup("Character Controls")]
    public float gravityScale = 10;

    [FoldoutGroup("Character Controls")]
    [Header("Drag")]
    [SerializeField] float groundDrag = 6f;
    [FoldoutGroup("Character Controls")]
    [SerializeField] float airDrag = 2f;

    float horizontalMovement;
    float verticalMovement;

    [FoldoutGroup("Character Controls")]
    [Header("Ground Detection")]
    [SerializeField] Transform groundCheck;
    [FoldoutGroup("Character Controls")]
    [SerializeField] LayerMask groundMask;
    [FoldoutGroup("Character Controls")]
    [SerializeField] float groundDistance = 0.2f;
    public bool isGrounded { get; private set; }

    // Interact
    [FoldoutGroup("Interact (Cube Shape)")]
    [LabelText("Pivot")]
    [SerializeField] Transform interactPivot;
    [FoldoutGroup("Interact (Cube Shape)")]
    [LabelText("Size")]
    [SerializeField] Vector3 interactableAreaSize = Vector3.one;

    [FoldoutGroup("Keybinds Control")]
    [Header("Keybinds")]
    [SerializeField] KeyCode jumpKey = KeyCode.Space;
    [FoldoutGroup("Keybinds Control")]
    [SerializeField] KeyCode sprintKey = KeyCode.LeftShift;
    [FoldoutGroup("Keybinds Control")]
    [SerializeField] KeyCode interactKey = KeyCode.Z;

    Vector3 moveDirection;
    Vector3 slopeMoveDirection;
    Rigidbody rb;
    RaycastHit slopeHit;
    public int jumpInt;
    #endregion

    private void Start()
    {
        rb = GetComponent<Rigidbody>();
        rb.freezeRotation = true;
    }

    private void Update()
    {
        // INPUT FUNCTION
        //===========================================================================================================================
        horizontalMovement = Input.GetAxisRaw("Horizontal");
        verticalMovement = Input.GetAxisRaw("Vertical");
        moveDirection = new Vector3(horizontalMovement, 0, verticalMovement);
        //===========================================================================================================================

        // GROUNDED FUNCTION
        //===========================================================================================================================
        isGrounded = Physics.CheckSphere(groundCheck.position, groundDistance, groundMask);
        //===========================================================================================================================

        // DRAG FUNCTION
        //===========================================================================================================================
        if (isGrounded)
        {
            rb.drag = groundDrag;
        }
        else
        {
            rb.drag = airDrag;
        }
        //===========================================================================================================================

        // CONTROL SPEED
        //===========================================================================================================================
        if (Input.GetKey(sprintKey) && isGrounded)
        {
            moveSpeed = Mathf.Lerp(moveSpeed, sprintSpeed, acceleration * Time.deltaTime);
        }
        else
        {
            moveSpeed = Mathf.Lerp(moveSpeed, walkSpeed, acceleration * Time.deltaTime);
        }
        //===========================================================================================================================

        // JUMP FUNCTION
        //===========================================================================================================================
        if (Input.GetKeyDown(jumpKey) && jumpInt < (jumpAmount - 1))
        {
            Jump();
            jumpInt++;
        }

        if (isGrounded) { jumpInt = 0; };
        //===========================================================================================================================

        // GRAVITY FUNCTION
        //===========================================================================================================================
        if (!isGrounded)
        {
            // Increase the downward velocity (effectively increasing gravity)
            rb.velocity += Vector3.down * gravityScale * Time.fixedDeltaTime;
        }
        //===========================================================================================================================

        // SLOPE FUNCTION
        //===========================================================================================================================
        slopeMoveDirection = Vector3.ProjectOnPlane(moveDirection, slopeHit.normal);
        //===========================================================================================================================

        // ROTATION FUNCTION
        //===========================================================================================================================
        if (moveDirection != Vector3.zero)
        {
            Quaternion toRotation = Quaternion.LookRotation(moveDirection, Vector3.up);
            orientation.transform.rotation = Quaternion.RotateTowards(orientation.transform.rotation, toRotation, rotationSpeed * Time.deltaTime);
        }
        //===========================================================================================================================

        if (Input.GetKeyDown(interactKey) || Input.GetKeyDown("joystick button 0")) { Interact(); }
    }

    private void FixedUpdate()
    {
        // MOVEMENT FUNCTION
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
        //===========================================================================================================================

        bool hasInteracted = false;

        if (Physics.CheckSphere(groundCheck.position, groundDistance) && rb.velocity.y < 0 && hasInteracted == false)
        {
            hasInteracted = true;
            BottomInteract();
        }
        else
        {
            hasInteracted = false;
        }
    }

    public void Jump()
    {
        rb.velocity = new Vector3(rb.velocity.x, 0, rb.velocity.z);
        rb.AddForce(transform.up * jumpForce, ForceMode.Impulse);
    }

    private bool OnSlope()
    {
        if (Physics.Raycast(transform.position, Vector3.down, out slopeHit, playerHeight / 2 + 0.5f))
        {
            if (slopeHit.normal != Vector3.up)
            {
                return true;
            }
            else
            {
                return false;
            }
        }
        return false;
    }

    void Interact()
    {
        Collider[] colliders = Physics.OverlapBox(interactPivot.position, interactableAreaSize);

        foreach (Collider c in colliders)
        {
            Interactable interactable = c.GetComponent<Interactable>();
            if (interactable != null)
            {
                interactable?.Interact();
                break;
            }
        }
    }

    void BottomInteract()
    {
        Collider[] colliders = Physics.OverlapSphere(groundCheck.position, groundDistance);

        //foreach (Collider c in colliders)
        //{
        //    IPlayerTriggerable triggerable = c.GetComponent<IPlayerTriggerable>();
        //    if (triggerable != null)
        //    {
        //        triggerable.OnPlayerTriggered(this);
        //        break;
        //    }
        //}

        foreach (Collider c in colliders)
        {
            Interactable interactable = c.GetComponent<Interactable>();
            if (interactable != null)
            {
                interactable?.Interact();

                Jump();
                jumpInt = jumpAmount - 1;

                break;
            }
        }
    }

    void OnDrawGizmos()
    {
        if (interactPivot != null)
        {
            // Set the color of the Gizmo
            Gizmos.color = Color.yellow;
            // Create a matrix that combines position and rotation
            Matrix4x4 cubeTransform = Matrix4x4.TRS(interactPivot.position, orientation.rotation, Vector3.one);
            // Apply the transformation matrix to the Gizmos drawing
            Gizmos.matrix = cubeTransform;
            // Draw a wireframe cube centered at (0, 0, 0)
            Gizmos.DrawWireCube(Vector3.zero, interactableAreaSize);
            // Reset the Gizmos matrix to prevent affecting other Gizmos drawings
            Gizmos.matrix = Matrix4x4.identity;
        }

        Gizmos.DrawWireSphere(groundCheck.position, groundDistance);
    }
}
