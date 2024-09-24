using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Character_Movement : MonoBehaviour
{
    public Vector3 fowardVector, rightVector; 
    [SerializeField] Material FaceMaterial;
    [SerializeField] GameObject HeadCenterPoint;
    [SerializeField] Vector3 HeadCenterPointVector;

    void Start()
    {
              
    }

    

    void Update()
    {
        fowardVector = transform.forward;
        rightVector = transform.right;
        HeadCenterPointVector = HeadCenterPoint.transform.position;

        FaceMaterial.SetVector("_HeadFrontVector", new Vector4(fowardVector.x, fowardVector.y, fowardVector.z, 1));
        FaceMaterial.SetVector("_HeadRightVector", new Vector4(rightVector.x, rightVector.y, rightVector.z, 1)); 
        FaceMaterial.SetVector("_HeadCenterPoint", new Vector4(HeadCenterPoint.transform.position.x, HeadCenterPoint.transform.position.y, HeadCenterPoint.transform.position.z, 1)); 
    }
}
