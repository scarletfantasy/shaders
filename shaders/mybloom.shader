Shader "Unlit/mybloom"
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
        half4 _MainTex_ST;
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
           
           half2 uv:TEXCOORD0;
           half2 uv1:TEXCOORD0;
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

          
           o.uv.xy=v.texcoord;
           o.uv1.xy=v.texcoord;

      

           return o;
        }

        
        fixed4 fragExtractBright(v2f i):SV_Target
        {
            fixed4 col=tex2D(_MainTex,i.uv);
            fixed val=clamp(Luminance(col)-_LuminanceThreshold,0.0,1.0);
            return col*val;
        }

       
        fixed4 fragBloom(v2fBloom i):SV_Target
        {
            return tex2D(_MainTex,i.uv.xy)+tex2D(_Bloom,i.uv1.xy);
        }

        ENDCG

        ZTest Always
        Cull Off
        ZWrite Off

       
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment fragExtractBright     
            ENDCG
        }

        
        UsePass "Unlit/mygauss/gaussrow"

        UsePass "Unlit/mygauss/gausscol"

       
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