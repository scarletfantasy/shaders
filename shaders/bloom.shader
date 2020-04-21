Shader "Unlit/bloom"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Bloom("Bloom",2D)="black"{}
        _LuminanceThreshold("Luminance Threshold",Float)=0.5
        _BlurSize("Blur Size",Float)=1.0
    }
    SubShader
    {
        CGINCLUDE

        #include "UnityCG.cginc"

        sampler2D _MainTex;
        half4 _MainTex_TexelSize;
        sampler2D _Bloom;
        float _LuminanceThreshold;
        float _BlurSize;

        struct v2f
        {
           half2 uv : TEXCOORD0;
           float4 pos : SV_POSITION;
        };

        struct v2fBloom
        {
           //half4是因为这里还要存储_Bloom纹理
           half4 uv:TEXCOORD0;
           float4 pos:SV_POSITION;
        };

        v2f vert(appdata_img v)
        {
           v2f o;
           o.pos=UnityObjectToClipPos(v.vertex);
           o.uv=v.texcoord;    
           return o;
        }

        v2fBloom vertBloom(appdata_img v)
        {
           v2fBloom o;
           o.pos=UnityObjectToClipPos(v.vertex);

           //xy存储主纹理，zw存储_Bloom纹理，这样不必再申请额外空间
           o.uv.xy=v.texcoord;
           o.uv.zw=v.texcoord;

           //纹理坐标平台差异化判断，主要针对DirectX,因为DirectX与OpenGL纹理坐标原点不同(分别在左上和左下)
           //同时Unity平台对于主纹理已经进行过内部处理，因此这里只需要对_Bloom纹理进行平台检测和翻转
           //主要表现为进行y轴方向的翻转（因为y轴方向相反），对于_Bloom纹理来说也就是w
           #if UNITY_UV_STARTS_AT_TOP
           if(_MainTex_TexelSize.y<0){
                  o.uv.w=1.0-o.uv.w;
           }
           #endif

           return o;
        }

        //提取超过亮度阈值的图像
        fixed4 fragExtractBright(v2f i):SV_Target
        {
            fixed4 col=tex2D(_MainTex,i.uv);
            fixed val=clamp(Luminance(col)-_LuminanceThreshold,0.0,1.0);
            return col*val;
        }

        //对xy和zw对应的纹理采样进行混合
        fixed4 fragBloom(v2fBloom i):SV_Target
        {
            return tex2D(_MainTex,i.uv.xy)+tex2D(_Bloom,i.uv.zw);
        }

        ENDCG

        ZTest Always
        Cull Off
        ZWrite Off

        //Pass 1:提亮部
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment fragExtractBright     
            ENDCG
        }

        //Pass 2,3:高斯模糊，这里直接调用以前写的Pass
        UsePass "Unlit/mygauss/gaussrow"

        UsePass "Unlit/mygauss/gausscol"

        //Pass 4:混合原图和模糊后亮部
        Pass
        {
            CGPROGRAM
            #pragma vertex vertBloom
            #pragma fragment fragBloom
            ENDCG
        }
    }
    Fallback Off
}