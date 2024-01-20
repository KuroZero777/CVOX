using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Objects : MonoBehaviour, Interactable, IPlayerTriggerable
{
    public void Interact()
    {
        Debug.Log("Interact");
    }

    public void OnPlayerTriggered(Player player)
    {
        Debug.Log("InteractPlayer");
    }
}
