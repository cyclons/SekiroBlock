using System.Collections;
using System.Collections.Generic;
using UnityEngine;
[ExecuteInEditMode]
public class PostEffectBase : MonoBehaviour {

	// Use this for initialization
	protected void Start () {
        CheckResources();
	}
	
	// Update is called once per frame
	void Update () {
		
	}

    protected void CheckResources()
    {
        bool isSupported = CheckSupport();
    }

    protected bool CheckSupport()
    {
        if (SystemInfo.supportsImageEffects == false )
        {
            Debug.LogWarning("not support image effect");
            return false;
        }
        return true;
    }

    protected void NotSupported()
    {
        enabled = false;
    }

    protected Material CheckShaderAndCreateMaterial(Shader shader,Material material)
    {
        if (shader == null)
        {
            return null;
        }
        if (shader.isSupported && material && material.shader == shader)
        {
            return material;
        }

        if (!shader.isSupported)
        {
            return null;
        }
        else
        {
            material = new Material(shader);
            material.hideFlags = HideFlags.DontSave;

            if (material)
            {
                return material;
            }
            else
            {
                return null;
            }

        }
    }

}
