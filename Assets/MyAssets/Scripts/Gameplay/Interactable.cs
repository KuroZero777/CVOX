#region Old Interact
//using System.Collections;
//using System.Collections.Generic;
//using UnityEngine;
//using UnityEngine.Events;

//public class Interactable : MonoBehaviour
//{
//    public UnityEvent onInteract;

//    public Dialog dialog;

//    public void Interact()
//    {
//        onInteract?.Invoke();
//        Debug.Log("LOL");

//        // DialogManager.Instance.ShowDialog(dialog);
//        StartCoroutine(DialogManager.Instance.ShowDialog(dialog));
//    }
//}
#endregion

using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;

public interface Interactable
{
    void Interact();
}