using UnityEngine;


[ExecuteInEditMode]
//屏幕后处理效果主要是针对摄像机进行操作，需要绑定摄像机
[RequireComponent(typeof(Camera))]
public class ScreenEffectBase : MonoBehaviour
{
    public Shader shader;
    public Material material;
    protected Material Material
    {
        get
        {
            material = CheckShaderAndCreatMat(shader, material);
            return material;
        }
    }

    //用于检查并创建临时材质
    private Material CheckShaderAndCreatMat(Shader shader, Material material)
    {
        Material nullMat = null;
        if (shader != null)
        {
            if (shader.isSupported)
            {
                if (material && material.shader == shader) { }
                else
                {
                    material = new Material(shader) { hideFlags = HideFlags.DontSave };
                }
                return material;
            }
        }
        return nullMat;
    }
}
public class MyBloomCtrl : ScreenEffectBase
{
    private const string _LuminanceThreshold = "_LuminanceThreshold";
    private const string _BlurSize = "_BlurSize";
    private const string _Bloom = "_Bloom";

    [Range(0, 4)]
    public int iterations = 3;
    [Range(0.2f, 3.0f)]
    public float blurSize = 0.6f;
    [Range(1, 8)]
    public int dowmSample = 2;
    [Range(0.0f, 4.0f)]
    public float luminanceThreshold = 0.6f;//控制Bloom效果的亮度阈值，因为亮度值大多数时不大于1，故该值超过1时一般无效果，但开启HDR后图像的亮度取值范围将扩大

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (Material != null)
        {
            Material.SetFloat(_LuminanceThreshold, luminanceThreshold);

            int rth = source.height / dowmSample;
            int rtw = source.width / dowmSample;

            RenderTexture buffer0 = RenderTexture.GetTemporary(rtw, rth, 0);
            buffer0.filterMode = FilterMode.Bilinear;

            //第1个Pass中提取纹理亮部，存到buffer0中，以便后面进行高斯模糊处理
            Graphics.Blit(source, buffer0, Material, 0);

            for (int i = 0; i < iterations; i++)
            {
                Material.SetFloat(_BlurSize, blurSize * i + 1.0f);

                //第2，3个Pass中对亮部分别进行纵向和横向的渲染处理（高斯模糊）
                RenderTexture buffer1 = RenderTexture.GetTemporary(rtw, rth, 0);
                Graphics.Blit(buffer0, buffer1, Material, 1);
                RenderTexture.ReleaseTemporary(buffer0);//临时创建的渲染纹理不能直接释放 x： buffer0.Release();

                buffer0 = RenderTexture.GetTemporary(rtw, rth, 0);
                Graphics.Blit(buffer1, buffer0, Material, 2);
                RenderTexture.ReleaseTemporary(buffer1);
            }

            //第4个Pass将buffer0高斯模糊后的结果传给_Bloom以进行最后的混合
            Material.SetTexture(_Bloom, buffer0);
            Graphics.Blit(source, destination, Material, 3);//注意这里用原始纹理作为源纹理而不是buffer0，因为buffer0已经作为另一个参数进行了传递，而这里还需要原始的纹理以进行混合
            RenderTexture.ReleaseTemporary(buffer0);
        }
        else
            Graphics.Blit(source, destination);
    }
}

