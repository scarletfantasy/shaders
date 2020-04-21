Shader "Unlit/no"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
           
       
    }
    SubShader
    {
        CGINCLUDE

        #include "UnityCG.cginc"

        sampler2D _MainTex;
        half4 _MainTex_ST;
        sampler2D _Bloom;
        

        struct v2f
        {
           half2 uv : TEXCOORD0;
           float4 pos : SV_POSITION;
        };

        

        v2f vert(appdata_img v)
        {
           v2f o;
           o.pos=UnityObjectToClipPos(v.vertex);
           o.uv=v.texcoord;    
           return o;
        }

        

        
        fixed4 frag(v2f i):SV_Target
        {
            fixed4 col=tex2D(_MainTex,i.uv);
           
            return col;
        }

       
 

        ENDCG

        ZTest Always
        Cull Off
        ZWrite Off

       
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            ENDCG
        }

        
        
    }
    Fallback Off
}