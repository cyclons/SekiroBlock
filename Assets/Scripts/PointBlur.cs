using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PointBlur : MonoBehaviour {
    public Shader PointBlurShader;
    public AnimationCurve curve;
    public GameObject Spark;
    Material material;
    [Range(0, 1)]
    public float BlurStrength = 0.5f;

    private Vector2 BlurCenter = new Vector2(0.5f, 0.5f);

    private Texture2D gradTexture;
    private void Start()
    {
        //初始化振幅贴图（也就是把waveform曲线初始化到gradTexture上面）
        gradTexture = new Texture2D(2048, 1, TextureFormat.Alpha8, false);
        gradTexture.wrapMode = TextureWrapMode.Clamp;
        gradTexture.filterMode = FilterMode.Bilinear;
        for (var i = 0; i < gradTexture.width; i++)
        {
            var x = 1.0f / gradTexture.width * i;
            var a = curve.Evaluate(x);
            gradTexture.SetPixel(i, 0, new Color(a, a, a, a));
        }
        gradTexture.Apply();

        //初始化material
        material = new Material(PointBlurShader);
        material.hideFlags = HideFlags.DontSave;
        material.SetTexture("_GradTex", gradTexture);

    }
    public int downSampleFactor = 2;
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        RenderTexture rt1 = RenderTexture.GetTemporary(source.width >> downSampleFactor, source.height >> downSampleFactor, 0, source.format);
        RenderTexture rt2 = RenderTexture.GetTemporary(source.width >> downSampleFactor, source.height >> downSampleFactor, 0, source.format);
        Graphics.Blit(source, rt1);

        //使用降低分辨率的rt进行模糊:pass0
        Graphics.Blit(rt1, rt2, material, 0);

        //使用rt2和原始图像lerp:pass1
        material.SetTexture("_BlurTex", rt2);
        Graphics.Blit(source, destination, material, 1);

        //释放RT
        RenderTexture.ReleaseTemporary(rt1);
        RenderTexture.ReleaseTemporary(rt2);

    }
    float t = 1000;
    public float BlurSpeed = 1;
    public float BlurRange = 0.3f;
    public float BlurRadius = 1;
    private void Update()
    {
        material.SetFloat("_Timer", t += Time.deltaTime);
        material.SetFloat("_BlurSpeed", BlurSpeed);
        material.SetFloat("_BlurStrength", BlurStrength);
        material.SetFloat("_BlurRange", BlurRange);
        material.SetVector("_BlurCenter", new Vector4(BlurCenter.x* Camera.main.aspect, BlurCenter.y, 0, 0));
        material.SetFloat("_Aspect", Camera.main.aspect);
        material.SetFloat("_BlurCircleRadius", BlurRadius);

        if (Input.GetMouseButtonDown(0))
        {
            t = 0;
            //BlurCenter = new Vector2(Input.mousePosition.x / Screen.width, Input.mousePosition.y / Screen.height);

            RaycastHit hit;
            Ray ray = Camera.main.ScreenPointToRay(Input.mousePosition);
            if(Physics.Raycast(ray,out hit))
            {
                Instantiate(Spark, new Vector3(hit.point.x,hit.point.y,0), Quaternion.identity);
                BlurCenter = Camera.main.WorldToScreenPoint(new Vector3(hit.point.x, hit.point.y, 0));
                BlurCenter.Set(BlurCenter.x / Screen.width, BlurCenter.y / Screen.height);
            }
        }
    }
}
