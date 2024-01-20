using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Sirenix.OdinInspector;

[RequireComponent(typeof(CharacterMovement))]
public class Player : MonoBehaviour
{
    [SerializeField] float moveSpeed = 6f;
    [SerializeField] float rotationSpeed = 500f;

    [SerializeField] Transform orientation;
    [SerializeField] CharacterMovement character;

    public float detectionCooldown = 1.0f; // Adjust this value as needed
    private bool hasInteracted = false;
    private float lastDetectionTime;

    [OnValueChanged("ChangeValue")]
    [SerializeField] int jumpAmount;
    [OnValueChanged("ChangeValue")]
    [SerializeField] float jumpForce = 5f;

    [OnValueChanged("ChangeValue")]
    [SerializeField] float gravityScale = 10;

    [OnValueChanged("ChangeValue")]
    [SerializeField] float groundDrag = 6f;
    [OnValueChanged("ChangeValue")]
    [SerializeField] float airDrag = 2f;
    [OnValueChanged("ChangeValue")]
    [SerializeField] float airMultiplier = 0.4f;

    private void ChangeValue()
    {
        character.jumpAmount = jumpAmount;
        character.jumpForce = jumpForce;

        character.gravityScale = gravityScale;

        character.groundDrag = groundDrag;
        character.airDrag = airDrag;
        character.airMultiplier = airMultiplier;
    }

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
    [SerializeField] KeyCode interactKey = KeyCode.Z;
    //[FoldoutGroup("Keybinds Control")]
    //[SerializeField] KeyCode attackKey = KeyCode.A;

    private void Update()
    {
        float horizontalMovement = Input.GetAxisRaw("Horizontal");
        float verticalMovement = Input.GetAxisRaw("Vertical");
        Vector3 moveDirection = new Vector3(horizontalMovement, 0, verticalMovement);

        if (Input.GetKeyDown(jumpKey)) { character.Jump(true); }

        character.Move(moveDirection, moveSpeed, rotationSpeed, orientation);

        if (Input.GetKeyDown(interactKey)) { Interact(); }

        BottomInteract(true);
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

    void BottomInteract(bool callOnce)
    {
        hasInteracted = (Physics.CheckSphere(character.groundCheck.position, character.groundDistance) && character.rbVelocity.y < 0 && hasInteracted == false);

        // Check if enough time has passed since the last detection
        if (Time.time - lastDetectionTime >= detectionCooldown)
        {
            Collider[] colliders = Physics.OverlapSphere(character.groundCheck.position, character.groundDistance);

            foreach (Collider c in colliders)
            {
                IPlayerTriggerable triggerable = c.GetComponent<IPlayerTriggerable>();
                if (triggerable != null)
                {
                    if (callOnce)
                    {
                        // Interaction happens only once
                        if (!hasInteracted)
                        {
                            // Perform interaction
                            triggerable.OnPlayerTriggered(this);

                            character.Jump(true);

                            // Record the time of the last detection
                            lastDetectionTime = Time.time;
                        }
                    }
                    else
                    {
                        // Perform interaction without the once-only check
                        triggerable.OnPlayerTriggered(this);
                    }

                    // Exit the loop after triggering interaction
                    break;
                }
            }
        }
    }

    public CharacterMovement Character => character;

    void OnDrawGizmos()
    {
        if (orientation != null && interactPivot != null)
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
    }
}
